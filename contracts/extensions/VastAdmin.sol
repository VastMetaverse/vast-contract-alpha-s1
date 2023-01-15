// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

contract VastAdmin is Ownable {
    address[] internal _adminList;
    mapping(address => uint256) internal _adminCreated;
    mapping(address => bool) internal _adminEnabled;

    /**
     * @dev Creates an admin.
     *
     * Requirements:
     *
     * - `__address` must be an address.
     */
    function createAdmin(address __address) public onlyOwner {
        require(__address != address(0), "Invalid address");
        require(_adminCreated[__address] == 0, "Admin already exists");

        _adminList.push(__address);
        _adminCreated[__address] = block.timestamp;
        _adminEnabled[__address] = true;
    }

    /**
     * @dev Gets an admin.
     *
     * Requirements:
     *
     * - `__address` must be an address.
     */
    function getAdmin(address __address)
        external
        view
        onlyOwner
        returns (uint256, bool)
    {
        require(_adminCreated[__address] > 0, "Admin not found");

        return (_adminCreated[__address], _adminEnabled[__address]);
    }

    /**
     * @dev Lists admins.
     */
    function listAdmins() external view onlyOwner returns (address[] memory) {
        return _adminList;
    }

    /**
     * @dev Sets `_adminEnabled` to true or false.
     *
     * Requirements:
     *
     * - `__address` must be an address.
     * - `__enabled` determines whether or not an admin is enabled.
     */
    function setAdminEnabled(address __address, bool __enabled)
        external
        onlyOwner
    {
        require(_adminCreated[__address] > 0, "Admin not found");

        _adminEnabled[__address] = __enabled;
    }

    /**
     * @dev Requires admin role.
     */
    modifier onlyAdmin() {
        require(_adminEnabled[msg.sender], "Caller is not an admin");
        _;
    }
}
