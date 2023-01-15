// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";
import "hardhat/console.sol";

import "../extensions/VastAdminUpgradeable.sol";
import "../extensions/VastAssetsItem.sol";

contract VastAssetsV2Mock is
    Initializable,
    ERC1155Upgradeable,
    OwnableUpgradeable,
    PausableUpgradeable,
    ReentrancyGuardUpgradeable,
    UUPSUpgradeable,
    VastAdminUpgradeable,
    VastAssetsItem
{
    string public name;
    string public symbol;

    event URIUpdate(string __uri, bool __cool);

    function initialize() public initializer {
        __ERC1155_init("");
        __Ownable_init();
        __UUPSUpgradeable_init();
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyOwner
    {}

    function newFunction() public pure returns (bool) {
        return true;
    }

    function setURI(string memory newURI) external onlyOwner {
        _setURI(newURI);

        emit URIUpdate(newURI, true);
    }
}
