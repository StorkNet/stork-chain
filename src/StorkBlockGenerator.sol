// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./StorkBlock.sol";

contract OraclePoSt {
    function startPoSt(
        uint256 _key,
        uint8 _validatorsRequired,
        address[] calldata validators
    ) external {}

    function getBlockValidators() external view returns (address[] memory) {}

    function getBlockValidatorChallenge() external view returns (bytes32) {}
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
    function setStorkBlockGeneratorAddress(address _storkBlockGeneratorAddress)
        external
    {}

    function createNewPhalanx(
        address _addr,
        bytes32 _phalanxName,
        bytes calldata _phalanxData
    ) external {}

    function createNewData(
        address _addr,
        bytes32 _phalanxName,
        uint8 _storkId,
        bytes calldata _storkData
    ) external {}

    function deleteData(
        address _addr,
        bytes32 _phalanxName,
        uint8 _storkId
    ) external {}
}

contract StorkBlockGenerator is StorkBlock {
    struct TxData {
        address client;
        address[] validators;
        mapping(address => bool) validatorIsAdded;
        bytes32 queryName;
        bytes32 phalanxName;
        uint8 storkId;
        bytes stork;
        bytes storkParameter;
        string _fallbackFunction;
        bool isProposed;
    }

    mapping(bytes32 => TxData) internal txData;

    OraclePoSt internal immutable PoSt;
    ZKTransaction internal immutable zkTx;
    StorkDataStore internal immutable dataStore;

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

    function proposeTxForBlock(
        address _clientAddr,
        string calldata _queryName,
        bytes32 _phalanxName,
        uint8 _storkId,
        bytes calldata _txStork,
        bytes calldata _txStorkParameter,
        string calldata _fallbackFunction,
        uint256 _key
    ) external isNotSealed blockInOperation {
        if (blockTxAddDuration <= block.timestamp) {
            addTxToBlock();
        } else {
            key += _key;
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
                clientCounter[_clientAddr].txCount += queryInfo[_queryName]
                    .cost;
                txData[txHashed].isProposed = true;
                txData[txHashed].client = _clientAddr;
                txHashes.push(txHashed);
                txCount++;
            }

            txData[txHashed].queryName = keccak256(abi.encode(_queryName));
            txData[txHashed].phalanxName = _phalanxName;
            txData[txHashed].stork = _txStork;
            txData[txHashed].storkId = _storkId;
            txData[txHashed].storkParameter = _txStorkParameter;
            txData[txHashed]._fallbackFunction = _fallbackFunction;

            //add msg.sender to the list of proposers for the tx
            if (!txData[txHashed].validatorIsAdded[msg.sender]) {
                txData[txHashed].validators.push(msg.sender);
                validatorInfo[msg.sender].txCount += queryInfo[_queryName].cost;
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
                    txData[txHashes[i]].queryName ==
                    queryInfo["createPhalanxType"].queryHash
                ) {
                    dataStore.createNewPhalanx(
                        txData[txHashes[i]].client,
                        txData[txHashes[i]].phalanxName,
                        txData[txHashes[i]].stork
                    );
                } else if (
                    txData[txHashes[i]].queryName ==
                    queryInfo["createStork"].queryHash ||
                    txData[txHashes[i]].queryName ==
                    queryInfo["updateStorkById"].queryHash
                ) {
                    dataStore.createNewData(
                        txData[txHashes[i]].client,
                        txData[txHashes[i]].phalanxName,
                        txData[txHashes[i]].storkId,
                        txData[txHashes[i]].stork
                    );
                } else if (
                    txData[txHashes[i]].queryName ==
                    queryInfo["deleteStorkById"].queryHash
                ) {
                    dataStore.deleteData(
                        txData[txHashes[i]].client,
                        txData[txHashes[i]].phalanxName,
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

        blockHashes[blockCount] = keccak256(
            abi.encode(
                blocks[blockCount].blockMiner,
                abi.encode(blocks[blockCount])
            )
        );

        announceNewBlock(blockCount);
        blockCount++;
        setNextBlockLockTime();
        createNullBlock();
    }
}
