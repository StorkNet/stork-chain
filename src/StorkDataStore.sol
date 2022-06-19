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

    address internal storkBlockGeneratorAddress;
    mapping(address => mapping(bytes32 => mapping(uint8 => bytes)))
        internal dataStore;
    mapping(address => mapping(bytes32 => bytes)) public phalanx;

    function setStorkBlockGeneratorAddress(address _storkBlockGeneratorAddress)
        external
    {
        require(
            storkBlockGeneratorAddress == address(0),
            "stork block generator already set"
        );
        storkBlockGeneratorAddress = _storkBlockGeneratorAddress;
    }

    function createNewPhalanx(
        address _addr,
        bytes32 _phalanxName,
        bytes calldata _phalanxData
    ) external IsOnlyStorkBlockGenerator {
        phalanx[_addr][_phalanxName] = _phalanxData;
    }

    function createNewData(
        address _addr,
        bytes32 _phalanxName,
        uint8 _storkId,
        bytes calldata _storkData
    ) external IsOnlyStorkBlockGenerator {
        dataStore[_addr][_phalanxName][_storkId] = _storkData;
    }

    function readData(
        address _addr,
        bytes32 _phalanxName,
        uint8 _storkId
    ) external view returns (bytes memory) {
        return (
            abi.decode(dataStore[_addr][_phalanxName][_storkId], (Stork))._data
        );
    }

    function deleteData(
        address _addr,
        bytes32 _phalanxName,
        uint8 _storkId
    ) external IsOnlyStorkBlockGenerator {
        delete dataStore[_addr][_phalanxName][_storkId];
    }
}
