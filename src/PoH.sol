// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract PoH {

    struct ValidatorPoH {
        uint256 validatorFreq;
        uint256 validatorFreqBackup;
    }

    mapping(address => ValidatorPoH) public poh;

    function initValidatorPoH() public {
        poh[0x073b53769a3CdbdD9C6cE24fEb87EB366e8C607C]=ValidatorPoH(3,3);
        poh[0x39F1Bde194d7ef4b4F4c1C1dFcD6a9295225437B]=ValidatorPoH(1,1);
        poh[0x35B272Ae597d0e02dde458ae0dDbACcc07e7F8d2]=ValidatorPoH(1,1);
        poh[0x1A8376C671543FFE5ed0c86F4E71C710ADaD1988]=ValidatorPoH(2,2);
        poh[0x7129Fc802deee39747a1571C88Ad51169EB60798]=ValidatorPoH(1,1);
        poh[0xA42eaA8fA6c3123E464E1D74e1629FDB49e03412]=ValidatorPoH(3,3);
        poh[0xefa10aa4CcE623616D398cc468B313e7a548bCd2]=ValidatorPoH(1,1);
        poh[0x53B07e381c519B31c96E716F552cDe72CDfD3c2c]=ValidatorPoH(1,1);
        poh[0x8fB056B94c69179a3759f54e071E2666Fbe3F8E5]=ValidatorPoH(2,2);
        poh[0xb9ffd4980F02358605f78F33929458f55a1d4A73]=ValidatorPoH(2,2);
    }
}
