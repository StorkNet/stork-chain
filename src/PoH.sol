// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract PoH {

    struct ValidatorPoH {
        uint256 validatorFreq;
        uint256 validatorFreqBackup;
    }

    mapping(address => ValidatorPoH) public poh;

    function initValidatorPoH() public {
        poh[0x5B38Da6a701c568545dCfcB03FcB875f56beddC4]=ValidatorPoH(3,3);
        poh[0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2]=ValidatorPoH(1,1);
        poh[0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db]=ValidatorPoH(1,1);
        poh[0x78731D3Ca6b7E34aC0F824c42a7cC18A495cabaB]=ValidatorPoH(2,2);
        poh[0x617F2E2fD72FD9D5503197092aC168c91465E7f2]=ValidatorPoH(1,1);
        poh[0x17F6AD8Ef982297579C203069C1DbfFE4348c372]=ValidatorPoH(3,3);
        poh[0x5c6B0f7Bf3E7ce046039Bd8FABdfD3f9F5021678]=ValidatorPoH(1,1);
        poh[0x03C6FcED478cBbC9a4FAB34eF9f40767739D1Ff7]=ValidatorPoH(1,1);
        poh[0x1aE0EA34a72D944a8C7603FfB3eC30a6669E454C]=ValidatorPoH(2,2);
        poh[0x0A098Eda01Ce92ff4A4CCb7A4fFFb5A43EBC70DC]=ValidatorPoH(2,2);
        poh[0xCA35b7d915458EF540aDe6068dFe2F44E8fa733c]=ValidatorPoH(1,1);
        poh[0x14723A09ACff6D2A60DcdF7aA4AFf308FDDC160C]=ValidatorPoH(1,1);
    }
}
