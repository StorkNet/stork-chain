// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./StorkTypes.sol";

contract StorkBlock is StorkTypes {
    struct Block {
        bytes32 parentHash;
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
        bytes32 queryHash;
        bool hasStork;
        bool hasParameter;
        bool hasFallback;
    }

    struct AddressInfo {
        uint8 txCount;
        bool isAdded;
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

    mapping(string => QueryInfo) internal queryInfo;

    uint256 internal blockLockDuration;
    uint256 internal blockTxAddDuration;
    uint256 internal blockCreateTime = 40 seconds;
    uint256 internal nextBlockLockTime = block.timestamp;
    uint256 internal percentageToPass;
    bool internal blockHasStarted;
    uint256 internal currentTime;

    bytes32[] internal txHashes;
    address[] public validators;
    address[] internal clients;

    uint256 public txCount;
    uint256 internal key;

    mapping(address => AddressInfo) internal clientCounter;
    mapping(address => AddressInfo) internal validatorInfo;
    mapping(address => bool) internal isClientAddedToBlock;

    function setNextBlockLockTime() internal {
        nextBlockLockTime += blockLockDuration;
        blockTxAddDuration = nextBlockLockTime - blockCreateTime;
    }

    function setNewBlockLockDuration(uint256 _blockLockDuration) internal {
        blockLockDuration = _blockLockDuration * 1 seconds;
        setNextBlockLockTime();
    }

    function setPercentageToPass(uint256 _percentageToPass) internal {
        percentageToPass = _percentageToPass;
    }

    function setOperationData() internal {
        queryInfo["createPhalanxType"] = QueryInfo(
            1,
            keccak256(abi.encode("createPhalanxType")),
            false,
            false,
            false
        );

        queryInfo["createStork"] = QueryInfo(
            1,
            keccak256(abi.encode("createStork")),
            true,
            false,
            false
        );

        queryInfo["updateStorkById"] = QueryInfo(
            1,
            keccak256(abi.encode("updateStorkById")),
            true,
            true,
            false
        );

        queryInfo["deleteStorkById"] = QueryInfo(
            1,
            keccak256(abi.encode("deleteStorkById")),
            false,
            false,
            false
        );

        queryInfo["requestStorkById"] = QueryInfo(
            3,
            keccak256(abi.encode("requestStorkById")),
            false,
            false,
            true
        );
    }

    function addOperationData(
        string calldata _queryName,
        uint8 _cost,
        bool _hasStork,
        bool _hasParameter,
        bool _hasFallback
    ) public {
        queryInfo[_queryName] = QueryInfo(
            _cost,
            keccak256(abi.encode(_queryName)),
            _hasStork,
            _hasParameter,
            _hasFallback
        );
    }

    function createNullBlock() internal {
        resetVariables();
        blocks[blockCount] = Block({
            parentHash: blockHashes[blockCount - 1],
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

    function announceNewBlock(uint32 _blockNumber) public {
        emit NewBlock(
            _blockNumber,
            blockHashes[_blockNumber],
            blocks[_blockNumber].blockMiner,
            blocks[_blockNumber].validators,
            abi.encode(blocks[_blockNumber])
        );
    }

    event NewBlock(
        uint256 indexed _blockNumber,
        bytes32 indexed _blockHash,
        address _blockMiner,
        address[] _validators,
        bytes _blockData
    );
}
