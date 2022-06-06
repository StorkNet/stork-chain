// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./StorkBlock.sol";

contract OraclePoSt {
    function startPoSt(
        uint256 _key,
        uint8 _validatorsRequired,
        address[] calldata validators
    ) external {}

    function getBlockValidators() public view returns (address[] memory) {}

    function getBlockValidatorChallenge() public view returns (bytes32) {}
}

contract ZKTransaction {
    function startPoSt(
        uint256 _key,
        uint8 _validatorsRequired,
        address[] calldata validators
    ) external {}

    function generateZKTxs(bytes32[] memory txs) external {}

    function getZkTxs() external returns (bytes32[] memory) {}
}

contract StorkDataStore is StorkTypes {
    function createNewPhalanx(
        address _addr,
        bytes32 _phalanxName,
        bytes calldata _phalanxData
    ) public {}

    function createNewData(
        address _addr,
        bytes32 _phalanxName,
        uint8 _storkId,
        bytes calldata _storkData
    ) public {}

    function deleteData(
        address _addr,
        bytes32 _phalanxName,
        uint8 _storkId
    ) public {}
}

contract StorkBlockGenerator is StorkBlock {
    struct TxData {
        address client;
        address[] validators;
        mapping(address => bool) validatorIsAdded;
        bytes32 queryName;
        bytes32 storkName;
        uint8 storkId;
        bytes stork;
        bytes storkParameter;
        string fallbackFunction;
        bool isProposed;
    }

    mapping(bytes32 => TxData) public txData;

    OraclePoSt public immutable PoSt;
    ZKTransaction public immutable zkTx;
    StorkDataStore public immutable dataStore;

    constructor(
        uint256 _blockLockDuration,
        uint256 _percentageToPass,
        address _PoStAddr,
        address _zkTxAddr,
        address _dataStoreAddr
    ) {
        blockCount = 0;
        nextBlockLockTime = block.timestamp;
        percentageToPass = _percentageToPass;
        setNewBlockLockDuration(_blockLockDuration);
        PoSt = OraclePoSt(_PoStAddr);
        zkTx = ZKTransaction(_zkTxAddr);
        dataStore = StorkDataStore(_dataStoreAddr);
        createNullBlock();
        setOperationData();
    }

    function updateTime() public {
        currentTime = block.timestamp;
    }

    function proposeTxForBlock(
        address _clientAddr,
        bytes32 _queryName,
        bytes32 _storkName,
        uint8 _storkId,
        bytes calldata _txStork,
        bytes calldata _txStorkParameter,
        string calldata fallbackFunction,
        uint256 _key
    ) external isNotSealed blockInOperation {
        if (blockTxAddDuration <= block.timestamp) {
            addTxToBlock();
        } else {
            key = _key;
            bytes32 txHashed = keccak256(
                abi.encode(
                    _clientAddr,
                    _queryName,
                    _storkId,
                    _txStork,
                    _txStorkParameter
                )
            );

            // if the txHash doesn't exist, add it to the TxList and increase the txCount of the client
            if (!txData[txHashed].isProposed) {
                if (!clientCounter[_clientAddr].isAdded) {
                    clientCounter[_clientAddr].isAdded = true;
                    clients.push(_clientAddr);
                }
                clientCounter[_clientAddr].txCount += queryInfo[
                    queryNames[_queryName]
                ].cost;
                txData[txHashed].isProposed = true;
                txData[txHashed].client = _clientAddr;
                txHashes.push(txHashed);
                txCount++;
            }

            txData[txHashed].queryName = _queryName;
            txData[txHashed].storkName = _storkName;
            txData[txHashed].stork = _txStork;
            txData[txHashed].storkId = _storkId;
            txData[txHashed].storkParameter = _txStorkParameter;
            txData[txHashed].fallbackFunction = fallbackFunction;

            //add msg.sender to the list of proposers for the tx
            if (!txData[txHashed].validatorIsAdded[msg.sender]) {
                txData[txHashed].validators.push(msg.sender);
                validatorInfo[msg.sender].txCount += queryInfo[
                    queryNames[_queryName]
                ].cost;
            }

            // this creates the list of unique validators
            if (!validatorInfo[msg.sender].isAdded) {
                validators.push(msg.sender);
                validatorInfo[msg.sender].isAdded = true;
            }
        }
    }

    function addTxToBlock() public isNotSealed {
        blocks[blockCount].isSealed = true;
        uint8 validationsRequired = uint8(
            (validators.length * percentageToPass) / 100
        );
        for (uint8 i = 0; i < txCount; ++i) {
            if (txData[txHashes[i]].validators.length >= validationsRequired) {
                blocks[blockCount].txHash.push(txHashes[i]);
                if (isClientAddedToBlock[txData[txHashes[i]].client] == false) {
                    blocks[blockCount].contracts.push(
                        txData[txHashes[i]].client
                    );
                    blocks[blockCount].contractsTxCounts.push(
                        clientCounter[txData[txHashes[i]].client].txCount
                    );
                    isClientAddedToBlock[txData[txHashes[i]].client] = true;
                }
                blocks[blockCount].minConfirmations = validationsRequired;

                if (
                    queryNames[txData[txHashes[i]].queryName] ==
                    Queries.createPhalanxType
                ) {
                    dataStore.createNewPhalanx(
                        txData[txHashes[i]].client,
                        txData[txHashes[i]].storkName,
                        txData[txHashes[i]].stork
                    );
                } else if (
                    queryNames[txData[txHashes[i]].queryName] ==
                    Queries.createStork ||
                    queryNames[txData[txHashes[i]].queryName] ==
                    Queries.updateStorkById
                ) {
                    dataStore.createNewData(
                        txData[txHashes[i]].client,
                        txData[txHashes[i]].storkName,
                        txData[txHashes[i]].storkId,
                        txData[txHashes[i]].stork
                    );
                } else if (
                    queryNames[txData[txHashes[i]].queryName] ==
                    Queries.deleteStorkById
                ) {
                    dataStore.deleteData(
                        txData[txHashes[i]].client,
                        txData[txHashes[i]].storkName,
                        txData[txHashes[i]].storkId
                    );
                }
            }
        }

        for (uint8 i; i < validators.length; ++i) {
            blocks[blockCount].validators.push(validators[i]);
            blocks[blockCount].validatorsTxCounts.push(
                validatorInfo[validators[i]].txCount
            );
        }

        PoSt.startPoSt(key, validationsRequired, validators);
        blocks[blockCount].validatorProof = PoSt.getBlockValidatorChallenge();
        PoSt.startPoSt(key, 1, validators);
        blocks[blockCount].blockMiner = PoSt.getBlockValidators()[0];

        zkTx.startPoSt(
            key,
            uint8(blocks[blockCount].txHash.length),
            validators
        );
        zkTx.generateZKTxs(blocks[blockCount].txHash);
        blocks[blockCount].txHash = zkTx.getZkTxs();

        blockHashes[blockCount] = keccak256(abi.encode(blocks[blockCount]));

        blockCount++;
        setNextBlockLockTime();
        createNullBlock();
    }
}

// 0x364C5DA8CF1B73FB53A2BEdBcfb07190CD814d6c
// 0xd9145CCE52D386f254917e481eB44e9943F39138

// 0x05829d564d347477146e61e94a6e02209a17369b320c41bf88a63c9372a552e7
// 0x51e8ccf16b7d0bf6dbff3704faa1cc765b8473004eafd29e94bfe47167ff5e93
// 0 1 2

// 0x0000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000060000000000000000000000000000000000000000000000000000000000000001f7368616e6b617200000000000000000000000000000000000000000000000000
// 0x0000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000060000000000000000000000000000000000000000000000000000000000000001f7368616e6b617200000000000000000000000000000000000000000000000000

// test

// 17
