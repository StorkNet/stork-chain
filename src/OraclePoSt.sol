// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract PoH {
    function getValidatorPoH(address _validator) external returns (uint256) {}
}

contract OraclePoSt {
    address[] private blockValidators;
    uint256 public freqSum;

    struct PoSt {
        address validatorAddr;
        uint256 validatorFreq;
        uint256 validatorFreqBackup;
    }
    PoSt[] public postValidators;

    PoH public immutable pohContract;

    constructor(address _pohAddr) {
        pohContract = PoH(_pohAddr);
    }

    function startPoSt(
        uint256 _key,
        uint8 _validatorsRequired,
        address[] calldata validators
    ) external {
        for (uint256 i = blockValidators.length; i > 0; i--) {
            blockValidators.pop();
        }

        for (uint256 i; i < validators.length; ++i) {
            uint256 validatorPower = pohContract.getValidatorPoH(validators[i]);
            freqSum += validatorPower;
            postValidators.push(
                PoSt(validators[i], validatorPower, validatorPower)
            );
        }
        findMiner(_key, _validatorsRequired);
    }

    function findMiner(uint256 key, uint256 _size) internal {
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
                indexCounter++;
            }
            blockValidators.push(
                postValidators[
                    (nextValidator + indexCounter - 1) % validatorCount
                ].validatorAddr
            );
            freqSum -= postValidators[
                (nextValidator + indexCounter - 1) % validatorCount
            ].validatorFreq;
            postValidators[(nextValidator + indexCounter - 1) % validatorCount]
                .validatorFreq = 0;
            nextValidator = indexCounter;
        }
    }

    function getBlockValidators() public view returns (address[] memory) {
        return blockValidators;
    }

    function getBlockValidatorChallenge() public view returns (bytes32) {
        bytes32 validatorChallenge;
        for (uint8 i; i < blockValidators.length; ++i) {
            validatorChallenge ^= keccak256(abi.encode(blockValidators[i]));
        }
        return (validatorChallenge);
    }
}
