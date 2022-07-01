// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract PoH {
    function getValidatorPoH(address _validator)
        external
        view
        returns (uint256)
    {}
}

contract ZKTransaction {
    struct TxData {
        address client;
        address[] validators;
        mapping(address => bool) validatorIsAdded;
        bytes32 queryName;
        bytes32 phalanxName;
        uint8 storkId;
        bytes stork;
        bytes storkParameter;
        string _fallbackFunction;
        bool isProposed;
    }

    struct PoSt {
        address validatorAddr;
        uint256 validatorFreq;
        uint256 validatorFreqBackup;
    }

    PoSt[] private postValidators;
    address[] private blockValidators;

    PoH private immutable pohContract;
    address private storkBlockGenerator;

    constructor(address _pohAddr) {
        pohContract = PoH(_pohAddr);
    }

    function setStorkBlockGeneratorAddress(address _storkBlockGeneratorAddress)
        external
    {
        require(storkBlockGenerator == address(0), "ZKTx- SBG addr set");
        storkBlockGenerator = _storkBlockGeneratorAddress;
    }

    mapping(address => bytes32[]) private addressTx;
    bytes32[] private zkTxs;

    function startPoSt(
        uint256 _key,
        uint8 _validatorsRequired,
        address[] calldata validators
    ) external {
        for (uint256 i = blockValidators.length; i > 0; i--) {
            blockValidators.pop();
        }

        for (uint256 i = postValidators.length; i > 0; i--) {
            postValidators.pop();
        }

        uint256 scaleUp = 1 + _validatorsRequired / validators.length;
        for (uint256 i; i < validators.length; ++i) {
            uint256 validatorPower = pohContract.getValidatorPoH(validators[i]);
            postValidators.push(
                PoSt(
                    validators[i],
                    validatorPower * scaleUp,
                    validatorPower * scaleUp
                )
            );
        }
        findValidators(_key % validators.length, _validatorsRequired);
    }

    function findValidators(uint256 key, uint256 _size) internal {
        uint256 validatorCount = postValidators.length;
        uint256 loc = 0;
        uint256 freqCounter = 0;
        uint256 nextValidator = 0;
        for (uint256 i = 0; i < _size; i++) {
            loc = ((((loc + (key++ % _size)) % validatorCount) + 1));
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

            if (
                postValidators[
                    (nextValidator + indexCounter - 1) % validatorCount
                ].validatorFreq > 0
            ) {
                postValidators[
                    (nextValidator + indexCounter - 1) % validatorCount
                ].validatorFreq--;
            }

            nextValidator = indexCounter % validatorCount;
        }
    }

    function generateZKTxs(bytes32[] memory txs) external {
        for (uint256 i = 0; i < txs.length; i++) {
            zkTxs.push(keccak256(abi.encode(txs[i], blockValidators[i])));
            addressTx[blockValidators[i]].push(txs[i]);
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

    event ZKTransactionList(address indexed _addr, bytes32[] _txs);
}
