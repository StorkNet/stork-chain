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
        uint8 ids;
        uint256 key;
        uint256 startTimeStamp;
        bytes32 storkName;
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
        uint8 _reqId,
        address _client,
        bytes32 _storkName,
        uint256 _key,
        uint8 _ids
    ) external {
        if (!isRequestExist[_reqId]) {
            isRequestExist[_reqId] = true;
            requests[_reqId] = Request(
                _client,
                new address[](0),
                _ids,
                _key,
                block.timestamp,
                _storkName,
                false
            );
        }

        if (
            block.timestamp < requests[_reqId].startTimeStamp + closeTimeStamp
        ) {
            require(!validatorExist[_reqId][msg.sender], "validator on job");
            validatorExist[_reqId][msg.sender] = true;
            requests[_reqId].validators.push(msg.sender);
        } else {
            completeRequest(_reqId, _client, _storkName, _ids, _key);
        }
    }

    function completeRequest(
        uint256 _reqId,
        address _client,
        bytes32 _storkName,
        uint8 _ids,
        uint256 _key
    ) internal {
        requests[_reqId].complete = true;
        bytes memory data;

        data = storkDataStore.readData(_client, _storkName, _ids);

        address electedMiner = requests[_reqId].validators[
            _key % requests[_reqId].validators.length
        ];
        emit RequestValidator(
            _reqId,
            keccak256(abi.encode(data, electedMiner)),
            electedMiner
        );
    }

    event RequestValidator(
        uint256 indexed _reqId,
        bytes32 zkChallenge,
        address miner
    );
}
