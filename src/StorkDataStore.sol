// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./StorkTypes.sol";

contract StorkDataStore is StorkTypes {
    modifier IsOnlyStorkBlockGenerator() {
        require(
            msg.sender == storkBlockGeneratorAddress,
            "is not stork block generator"
        );
        _;
    }

    address storkBlockGeneratorAddress;
    mapping(address => mapping(bytes32 => mapping(uint8 => bytes)))
        public dataStore;
    mapping(address => mapping(bytes32 => bytes)) public phalanx;

    constructor(address _storkBlockGeneratorAddress) {
        storkBlockGeneratorAddress = _storkBlockGeneratorAddress;
    }

    function createNewPhalanx(
        address _addr,
        bytes32 _phalanxName,
        bytes calldata _phalanxData
    ) public {
        phalanx[_addr][_phalanxName] = _phalanxData;
    }

    function createNewData(
        address _addr,
        bytes32 _phalanxName,
        uint8 _storkId,
        bytes calldata _storkData
    ) public {
        dataStore[_addr][_phalanxName][_storkId] = _storkData;
    }

    function readData(
        address _addr,
        bytes32 _phalanxName,
        uint8 _storkId
    ) public view returns (bytes memory) {
        return (dataStore[_addr][_phalanxName][_storkId]);
    }

    function deleteData(
        address _addr,
        bytes32 _phalanxName,
        uint8 _storkId
    ) public {
        delete dataStore[_addr][_phalanxName][_storkId];
    }
}
