// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./StorkTypes.sol";

contract StorkBlock is StorkTypes {
    struct Block {
        uint32 blockNumber;
        bytes32 validatorProof;
        address blockMiner;
        bytes32 blockHash;
        bytes32[] txHash;
        address[] contracts;
        address[] validators;
        uint8[] contractsTxCounts;
        uint8[] validatorsTxCounts;
        uint8 minConfirmations;
        string cid;
        uint256 blockLockTime;
        bool isSealed;
    }

    struct QueryInfo {
        uint8 cost;
        bool hasStork;
        bool hasParameter;
        bool hasFallback;
    }

    modifier isNotLocked(bool _expectedVal) {
        require(
            (block.timestamp < nextBlockLockTime) == _expectedVal,
            "block not locked"
        );
        _;
    }

    modifier isNotSealed() {
        require(blocks[blockCount - 1].isSealed == false, "block not sealed");
        _;
    }

    mapping(uint32 => Block) public blocks;
    uint32 public blockCount;

    mapping(string => QueryInfo) public queryInfo;

    uint256 public blockLockDuration;
    uint256 public nextBlockLockTime = block.timestamp;
    uint256 public percentageToPass;

    function setNextBlockLockTime() public {
        nextBlockLockTime += blockLockDuration;
    }

    function setNewBlockLockDuration(uint256 _blockLockDuration) public {
        blockLockDuration = _blockLockDuration * 1 minutes;
        setNextBlockLockTime();
    }

    function setPercentageToPass(uint256 _percentageToPass) external {
        percentageToPass = _percentageToPass;
    }

    function setOperationData() internal {
        queryInfo["createPhalanxType"] = QueryInfo(1, false, false, false);
        queryInfo["createStork"] = QueryInfo(1, true, false, false);
        queryInfo["updateStorkById"] = QueryInfo(1, true, true, false);
        queryInfo["deleteStorkById"] = QueryInfo(1, false, false, false);
        queryInfo["requestStorkById"] = QueryInfo(1, false, false, true);
    }

    function createNullBlock() internal {
        blocks[blockCount] = Block({
            blockNumber: uint32(blockCount),
            validatorProof: bytes32(0),
            blockMiner: address(0),
            blockHash: bytes32(0),
            txHash: new bytes32[](0),
            contracts: new address[](0),
            validators: new address[](0),
            contractsTxCounts: new uint8[](0),
            validatorsTxCounts: new uint8[](0),
            minConfirmations: 0,
            cid: "",
            blockLockTime: block.timestamp + blockLockDuration,
            isSealed: false
        });
    }
}