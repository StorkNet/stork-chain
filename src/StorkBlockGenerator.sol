// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./StorkBlock.sol";

contract StorkBlockGenerator is StorkBlock {
    struct TxData {
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

    mapping(address => uint256) public clientCounter;

    // index input for txData
    bytes32[] public txHashes;
    mapping(bytes32 => TxData) public txData;

    uint256 public txCount;
    address[] public validators;

    mapping(address => ValidatorInfo) public validatorInfo;

    constructor(uint256 _blockLockDuration) {
        setNewBlockLockDuration(_blockLockDuration);
        createNullBlock();
        setOperationData();
    }

    function proposeTxForBlock(
        address _clientAddr,
        string calldata _queryName,
        uint256 _storkId,
        bytes calldata _txStork,
        bytes calldata _txStorkParameter,
        string calldata fallbackFunction
    ) external isNotLocked(true) {
        if (blockTxAddDuration < block.timestamp) {
            blockCount++;
            addTxToBlock();
            setNextBlockLockTime();
            createNullBlock();
        }

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
            txHashes.push(txHashed);
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
        for (uint8 i; i < txHashes.length; ++i) {
            if (
                txData[txHashes[i]].validators.length >=
                (validators.length * percentageToPass) / 100
            ) {
                blocks[blockCount-1].txHash.push(txHashes[i]);
                blocks[blockCount-1].minConfirmations = uint8(
                    txData[txHashes[i]].validators.length
                );
            }
        }     
        blocks[blockCount-1].isSealed = true;
    }
}
