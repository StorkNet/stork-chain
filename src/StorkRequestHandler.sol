// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract StorkDataStore {
    function readData(
        address _addr,
        bytes32 _phalanxName,
        uint8 _storkId
    ) external view returns (bytes memory) {}
}

contract StorkRequestHandler {
    struct Request {
        address client;
        address[] validators;
        address miner;
        uint8[] ids;
        uint256 key;
        string fallbackFunction;
        uint256 startTimeStamp;
        bytes32 phalanxName;
        bool complete;
    }

    uint256 public closeTimeStamp;

    StorkDataStore public immutable storkDataStore;
    mapping(uint256 => Request) public requests;
    mapping(uint256 => mapping(address => bool)) public validatorExist;
    mapping(uint256 => bool) public isRequestExist;

    constructor(uint256 _closeTime, address _storkDataStore) {
        closeTimeStamp = _closeTime;
        storkDataStore = StorkDataStore(_storkDataStore);
    }

    function startPoStForRequest(
        uint256 _reqId,
        address _client,
        bytes32 _phalanxName,
        uint256 _key,
        string calldata _fallbackFunction,
        uint8[] calldata _ids
    ) external {
        if (!isRequestExist[_reqId]) {
            isRequestExist[_reqId] = true;
            requests[_reqId] = Request(
                _client,
                new address[](0),
                address(0),
                _ids,
                _key,
                _fallbackFunction,
                block.timestamp,
                _phalanxName,
                false
            );
        }

        if (
            block.timestamp < requests[_reqId].startTimeStamp + closeTimeStamp
        ) {
            require(
                !validatorExist[_reqId][msg.sender],
                "ReqHandler- validator on job"
            );
            validatorExist[_reqId][msg.sender] = true;
            requests[_reqId].validators.push(msg.sender);
            requests[_reqId].key += _key;
        } else {
            completeRequest(_reqId);
        }
    }

    function completeRequest(uint256 _reqId) public {
        requests[_reqId].complete = true;
        address _client = requests[_reqId].client;
        bytes32 _phalanxName = requests[_reqId].phalanxName;
        uint8[] memory _ids = requests[_reqId].ids;
        uint256 _key = requests[_reqId].key;

        bytes memory data;

        data = storkDataStore.readData(_client, _phalanxName, _ids[0]);
        requests[_reqId].miner = requests[_reqId].validators[
            _key % requests[_reqId].validators.length
        ];
        emit RequestValidator(
            _reqId,
            requests[_reqId].miner,
            requests[_reqId].fallbackFunction,
            keccak256(abi.encode(data, _key, requests[_reqId].miner)),
            data
        );
    }

    function exposeKeyToElectedMiner(uint256 _reqId) external {
        require(
            msg.sender == requests[_reqId].miner,
            "ReqHandler- wrong account"
        );
        emit KeyExposed(_reqId, requests[_reqId].key);
    }

    event RequestValidator(
        uint256 indexed _reqId,
        address miner,
        string _fallbackFunction,
        bytes32 zkChallenge,
        bytes data
    );

    event KeyExposed(uint256 indexed _reqId, uint256 key);
}
