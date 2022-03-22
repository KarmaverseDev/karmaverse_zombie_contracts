//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.4;

import "./SuperAdmin.sol";

abstract contract WhiteList is SuperAdmin {

    struct RoleData {
        mapping(address => bool) members;
    }

    mapping(bytes32 => RoleData) private _roles;

    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    error InvalidWhiteListOperator();

    modifier whiteList(bytes32 role) {
        if (!hasRole(role, msg.sender)) revert InvalidWhiteListOperator();
        _;
    }

    function hasRole(bytes32 role, address account) public view virtual returns (bool) {
        return _roles[role].members[account];
    }

    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }

    function _updateRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _revokeRole(role, account);
        } else {
            _grantRole(role, account);
        }
    }
}