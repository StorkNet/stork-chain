// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./StorkBlock.sol";

contract StorkBlockGenerator is StorkBlock {
    struct TxData {
        address[] validators;
        uint256 storkId;
        Stork stork;
        StorkParameter storkParameter;
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
    mapping(bytes32 => TxData) public txData;
    bytes32[] public txHashes;

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
        Stork calldata _txStork,
        StorkParameter calldata _txStorkParameter,
        string calldata fallbackFunction
    ) external isNotLocked(true) {
        bytes32 txHashed = keccak256(
            abi.encode(
                _clientAddr,
                _queryName,
                _storkId,
                _txStork,
                _txStorkParameter
            )
        );
        txHashes.push(txHashed);
        // if the txHash doesn't exist, add it to the TxList and increase the txCount of the client
        if (!txData[txHashed].isProposed) {
            clientCounter[_clientAddr] += queryInfo[_queryName].cost;
            txData[txHashed].isProposed = true;
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
        //store the tx data
        // txData[txHashed].stork = _txStork;
        // txData[txHashed].stork = _txStork;

        // this creates the list of unique validators
        if (!validatorInfo[msg.sender].isAdded) {
            validators.push(msg.sender);
        }
    }
}

// 0x364C5DA8CF1B73FB53A2BEdBcfb07190CD814d6c
// createStork
// 0
// [0,0,"0x7368616e6b6172000000000000000000000000000000000000000000000000"]
// [1,1,"hi"]
// deeznuts
