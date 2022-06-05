// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract StorkDataStore {
    mapping(address => mapping(string => mapping(uint256 => bytes)))
        public dataStore;

    function createNewData(
        address _addr,
        string calldata _storkType,
        uint256 _storkId,
        bytes calldata _storkData
    ) public {
        dataStore[_addr][_storkType][_storkId] = _storkData;
    }

    function readData(
        address _addr,
        string calldata _storkType,
        uint256 _storkId
    ) public view returns (bytes memory) {
        return (dataStore[_addr][_storkType][_storkId]);
    }

    function deleteData(
        address _addr,
        string calldata _storkType,
        uint256 _storkId
    ) public {
        delete dataStore[_addr][_storkType][_storkId];
    }
}
