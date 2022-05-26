// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./PoH.sol";

contract ZKTransaction is PoH {
    address[] public blockValidators;
    uint256 public freqSum;

    struct PoSt {
        address validatorAddr;
        uint256 validatorFreq;
        uint256 validatorFreqBackup;
    }
    PoSt[] public postValidators;

    constructor() {
        initValidatorPoH();
    }

    mapping(address => uint256[]) public addressTx;
    bytes32[] zkTxs;

    function startPoSt(
        uint256 _key,
        uint8 _validatorsRequired,
        address[] calldata validators
    ) external {
        for (uint256 i = postValidators.length; i > 0; i--) {
            postValidators.pop();
        }

        for (uint256 i; i < validators.length; ++i) {
            uint256 validatorPower = poh[validators[i]].validatorFreqBackup;
            freqSum += validatorPower;
            postValidators.push(
                PoSt(validators[i], validatorPower, validatorPower)
            );
        }
        findValidators(_key, _validatorsRequired);
    }

    function findValidators(uint256 key, uint256 _size) internal {
        uint256 validatorCount = postValidators.length;
        uint256 loc = 0;
        uint256 freqCounter = 0;
        uint256 nextValidator = 0;
        for (uint256 i = 0; i < _size; i++) {
            loc =
                ((((loc + (key++ % _size)) % validatorCount) + 1) % freqSum) +
                1;
            freqCounter = 0;
            uint256 indexCounter = 0;
            while (freqCounter < loc) {
                if (
                    postValidators[
                        (nextValidator + indexCounter) % validatorCount
                    ].validatorFreq != 0
                ) {
                    freqCounter += postValidators[
                        (nextValidator + indexCounter) % validatorCount
                    ].validatorFreq;
                }
                indexCounter = ((indexCounter + 1) % validatorCount) + 1;
            }
            blockValidators.push(
                postValidators[
                    (nextValidator + indexCounter - 1) % validatorCount
                ].validatorAddr
            );
            freqSum -= postValidators[
                (nextValidator + indexCounter - 1) % validatorCount
            ].validatorFreq;
            if (
                postValidators[
                    (nextValidator + indexCounter - 1) % validatorCount
                ].validatorFreq > 0
            ) {
                postValidators[
                    (nextValidator + indexCounter - 1) % validatorCount
                ].validatorFreq--;
            }

            nextValidator = indexCounter;
        }
    }

    function generateZKTxs(bytes32[] memory txs) external {
        for (uint256 i = 0; i < txs.length; i++) {
            zkTxs.push(keccak256(abi.encode(txs[i], blockValidators[i])));
            addressTx[blockValidators[i]].push(i);
        }
    }

    function getZkTxs() external returns (bytes32[] memory) {
        for (uint8 i = 0; i < blockValidators.length; i++) {
            emit ZKTransactionList(
                blockValidators[i],
                addressTx[blockValidators[i]]
            );
        }
        return (zkTxs);
    }

    event ZKTransactionList(address indexed _addr, uint256[] _txs);
}
