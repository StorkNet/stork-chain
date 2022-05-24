// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./StorkBlock.sol";

contract StorkBlockGenerator is StorkBlock {
    struct TxData {
        address[] validators;
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
        if (blockCreateDuration < block.timestamp) {
            addTxToBlock();
            setNextBlockLockTime();
            blockCount++;
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
        if (!validatorInfo[msg.sender].isAdded) {
            txData[txHashed].validators.push(msg.sender);
            validatorInfo[msg.sender].txCount += queryInfo[_queryName].cost;
        }

        // this creates the list of unique validators
        if (!validatorInfo[msg.sender].isAdded) {
            validators.push(msg.sender);
        }
    }

    function addTxToBlock() internal {
        blocks[blockCount].isSealed = true;
        for (uint8 i; i < txHashes.length; ++i) {
            if (
                txData[txHashes[i]].validators.length >=
                validators.length * percentageToPass
            ) {
                blocks[blockCount].txHash.push(txHashes[i]);
            }
        }
    }
}
