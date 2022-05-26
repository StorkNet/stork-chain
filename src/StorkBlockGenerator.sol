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

    function getBlockValidatorProof() public pure returns (bytes32) {}
}

contract ZKTransaction {
    function startPoSt(
        uint256 _key,
        uint8 _validatorsRequired,
        address[] calldata validators
    ) external {}

    function generateZKTxs(bytes32[] memory txs) external {}

    function getZkTxs() external view returns (bytes32[] memory) {}
}

contract StorkBlockGenerator is StorkBlock {
    struct TxData {
        address client;
        address[] validators;
        mapping(address => bool) validatorIsAdded;
        uint256 storkId;
        bytes stork;
        bytes storkParameter;
        string fallbackFunction;
        bool hasStork;
        bool hasParameter;
        bool hasFallback;
        bool isProposed;
    }

    struct ValidatorInfo {
        uint8 txCount;
        bool isAdded;
    }

    mapping(address => uint8) public clientCounter;

    // index input for txData
    bytes32[] public txHashes;
    mapping(bytes32 => TxData) public txData;

    uint256 public txCount;
    address[] public validators;
    uint256 key;

    mapping(address => ValidatorInfo) public validatorInfo;
    OraclePoSt public immutable PoSt;
    ZKTransaction public immutable zkTx;

    constructor(
        uint256 _blockLockDuration,
        uint256 _percentageToPass,
        address _PoStAddr,
        address _zkTxAddr
    ) {
        percentageToPass = _percentageToPass;
        setNewBlockLockDuration(_blockLockDuration);
        PoSt = OraclePoSt(_PoStAddr);
        zkTx = ZKTransaction(_zkTxAddr);
        createNullBlock();
        setOperationData();
    }

    function proposeTxForBlock(
        address _clientAddr,
        string calldata _queryName,
        uint256 _storkId,
        bytes calldata _txStork,
        bytes calldata _txStorkParameter,
        string calldata fallbackFunction,
        uint256 _key
    ) external isNotSealed {
        if (blockTxAddDuration < block.timestamp) {
            addTxToBlock();
            setNextBlockLockTime();
            createNullBlock();
        }
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
            clientCounter[_clientAddr] += queryInfo[_queryName].cost;
            txData[txHashed].isProposed = true;
            txData[txHashed].client = _clientAddr;
            txHashes.push(txHashed);
            txCount++;
        }

        if (queryInfo[_queryName].hasStork) {
            txData[txHashed].hasStork = true;
            txData[txHashed].stork = _txStork;
            txData[txHashed].storkId = _storkId;
        }
        if (queryInfo[_queryName].hasParameter) {
            txData[txHashed].hasParameter = true;
            txData[txHashed].storkParameter = _txStorkParameter;
        }
        if (queryInfo[_queryName].hasFallback) {
            txData[txHashed].hasFallback = true;
            txData[txHashed].fallbackFunction = fallbackFunction;
        }

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

    function addTxToBlock() internal isNotSealed {
        blocks[blockCount].isSealed = true;
        uint8 validationsRequired = uint8(
            (validators.length * percentageToPass) / 100
        );
        for (uint8 i = 0; i < txCount; ++i) {
            if (txData[txHashes[i]].validators.length >= validationsRequired) {
                blocks[blockCount].txHash.push(txHashes[i]);
                blocks[blockCount].contracts.push(txData[txHashes[i]].client);
                blocks[blockCount].contractsTxCounts.push(
                    clientCounter[txData[txHashes[i]].client]
                );
                blocks[blockCount].minConfirmations = validationsRequired;
            }
        }

        for (uint8 i; i < validators.length; ++i) {
            blocks[blockCount].validators.push(validators[i]);
            blocks[blockCount].validatorsTxCounts.push(
                validatorInfo[validators[i]].txCount
            );
        }

        PoSt.startPoSt(key, validationsRequired, validators);
        blocks[blockCount].validatorProof = PoSt.getBlockValidatorProof();
        PoSt.startPoSt(key, 1, validators);
        blocks[blockCount].blockMiner = PoSt.getBlockValidators()[0];

        zkTx.startPoSt(key, uint8(blocks[blockCount].txHash.length), validators);
        zkTx.generateZKTxs(blocks[blockCount].txHash);
        blocks[blockCount].txHash = zkTx.getZkTxs();

        blocks[blockCount].blockHash = keccak256(
            abi.encode(blocks[blockCount])
        );
        blockCount++;
    }
}
