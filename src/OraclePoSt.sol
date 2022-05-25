// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract OraclePoSt {
    struct PoSt {
        uint256 validatorAddr;
        uint256 validatorFreq;
        uint256 validatorFreqBackup;
    }

    uint256[] private jobMiners;
    uint256 public sum;
    PoSt[] public postValidators;

    constructor() {
        validatorPoH(4, 2);
        validatorPoH(3, 1);
        validatorPoH(8, 3);
        validatorPoH(12, 1);
        validatorPoH(2, 2);
        validatorPoH(6, 3);
        validatorPoH(10, 3);
        validatorPoH(11, 1);
        validatorPoH(1, 2);
        validatorPoH(9, 1);
    }

    function getMinerFrequency(uint256 _miner)
        public
        view
        returns (PoSt memory)
    {
        return postValidators[_miner];
    }

    function validatorPoH(uint256 _address, uint256 _freq) internal {
        postValidators.push(PoSt(_address, _freq, _freq));
        sum += _freq;
    }

    function findMiner(uint256 key, uint256 _size) public {
        uint256 validatorCount = postValidators.length;
        uint256 loc = 0;
        uint256 freqCounter = 0;
        uint256 nextValidator = 0;
        for (uint256 i = 0; i < _size; i++) {
            loc = (((loc + (key++ % _size)) % validatorCount) + 1) % sum;
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
                indexCounter++;
            }
            jobMiners.push(
                postValidators[
                    (nextValidator + indexCounter - 1) % validatorCount
                ].validatorAddr
            );
            sum -= postValidators[
                (nextValidator + indexCounter - 1) % validatorCount
            ].validatorFreq;
            postValidators[(nextValidator + indexCounter - 1) % validatorCount]
                .validatorFreq = 0;
            nextValidator = indexCounter;
        }
    }

    function retMiners() public view returns (uint256[] memory) {
        return jobMiners;
    }
}
