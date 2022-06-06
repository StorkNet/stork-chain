// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./StorkTypes.sol";

contract StorkBlock is StorkTypes {
    struct Block {
        uint32 blockNumber;
        bytes32 validatorProof;
        address blockMiner;
        bytes32[] txHash;
        address[] contracts;
        address[] validators;
        uint8[] contractsTxCounts;
        uint8[] validatorsTxCounts;
        uint8 minConfirmations;
        uint256 blockLockTime;
        bool isSealed;
    }

    struct QueryInfo {
        uint8 cost;
        bool hasStork;
        bool hasParameter;
        bool hasFallback;
    }

    struct AddressInfo {
        uint8 txCount;
        bool isAdded;
    }

    enum Queries {
        createPhalanxType,
        createStork,
        updateStorkById,
        deleteStorkById,
        requestStorkById
    }

    modifier blockInOperation() {
        if (blockHasStarted == false) {
            blockHasStarted = true;
            setNextBlockLockTime();
        }
        _;
    }

    modifier isNotSealed() {
        require(blocks[blockCount].isSealed == false, "block sealed");
        if (nextBlockLockTime < block.timestamp) {
            createNullBlock();
            blockCount++;
        }
        _;
    }

    mapping(uint32 => Block) public blocks;
    mapping(uint32 => bytes32) public blockHashes;

    uint32 public blockCount;

    mapping(Queries => QueryInfo) public queryInfo;
    mapping(bytes32 => Queries) public queryNames;

    uint256 public blockLockDuration;
    uint256 public blockTxAddDuration;
    uint256 public blockCreateTime = 40 seconds;
    uint256 public nextBlockLockTime = block.timestamp;
    uint256 public percentageToPass;
    bool public blockHasStarted;
    uint256 public currentTime;

    bytes32[] public txHashes;
    address[] public validators;
    address[] public clients;

    uint256 public txCount;
    uint256 public key;

    mapping(address => AddressInfo) public clientCounter;
    mapping(address => AddressInfo) public validatorInfo;
    mapping(address => bool) public isClientAddedToBlock;

    function setNextBlockLockTime() public {
        nextBlockLockTime += blockLockDuration;
        blockTxAddDuration = nextBlockLockTime - blockCreateTime;
    }

    function setNewBlockLockDuration(uint256 _blockLockDuration) public {
        blockLockDuration = _blockLockDuration * 1 seconds;
        setNextBlockLockTime();
    }

    function setPercentageToPass(uint256 _percentageToPass) external {
        percentageToPass = _percentageToPass;
    }

    function returnTimeLockStart() public view returns (uint256) {
        return blockTxAddDuration;
    }

    function returnBlockTimeStamp() public view returns (uint256) {
        return (block.timestamp);
    }

    function timeLeftForTx() public view returns (uint256) {
        return (blockTxAddDuration - block.timestamp);
    }

    function timeLeftForBlockComlpetion() public view returns (uint256) {
        return (blockCreateTime + blockTxAddDuration - block.timestamp);
    }

    function setOperationData() internal {
        queryInfo[Queries.createPhalanxType] = QueryInfo(
            1,
            false,
            false,
            false
        );
        queryNames[keccak256(abi.encode("createPhalanxType"))] = Queries
            .createPhalanxType;

        queryInfo[Queries.createStork] = QueryInfo(1, true, false, false);
        queryNames[keccak256(abi.encode("createStork"))] = Queries.createStork;

        queryInfo[Queries.updateStorkById] = QueryInfo(1, true, true, false);
        queryNames[keccak256(abi.encode("updateStorkById"))] = Queries
            .updateStorkById;

        queryInfo[Queries.deleteStorkById] = QueryInfo(1, false, false, false);
        queryNames[keccak256(abi.encode("deleteStorkById"))] = Queries
            .deleteStorkById;

        queryInfo[Queries.requestStorkById] = QueryInfo(3, false, false, true);
        queryNames[keccak256(abi.encode("requestStorkById"))] = Queries
            .requestStorkById;
    }

    function createNullBlock() internal {
        resetVariables();
        blocks[blockCount] = Block({
            blockNumber: uint32(blockCount),
            validatorProof: bytes32(0),
            blockMiner: address(0),
            txHash: new bytes32[](0),
            contracts: new address[](0),
            validators: new address[](0),
            contractsTxCounts: new uint8[](0),
            validatorsTxCounts: new uint8[](0),
            minConfirmations: 0,
            blockLockTime: block.timestamp + blockLockDuration,
            isSealed: false
        });
    }

    function resetVariables() internal {
        blockHasStarted = false;

        for (uint256 i; i < clients.length; i++) {
            clientCounter[clients[i]] = AddressInfo(0, false);
            isClientAddedToBlock[clients[i]] = false;
        }

        for (uint256 i; i < validators.length; i++) {
            validatorInfo[validators[i]] = AddressInfo(0, false);
        }

        for (uint256 i = txHashes.length; i > 0; i--) {
            txHashes.pop();
        }

        for (uint256 i = validators.length; i > 0; i--) {
            validators.pop();
        }

        for (uint256 i = clients.length; i > 0; i--) {
            clients.pop();
        }

        txCount = 0;
    }

    function returnBlock(uint32 _blockNumber) public returns (bytes memory) {
        emit NewBlock(
            _blockNumber,
            blockHashes[_blockNumber],
            abi.encode(blocks[_blockNumber])
        );
        return (abi.encode(blocks[_blockNumber]));
    }

    event NewBlock(
        uint256 indexed _blockNumber,
        bytes32 indexed _blockHash,
        bytes _blockData
    );
}
