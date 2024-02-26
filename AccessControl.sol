// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

contract CommonAccessControl {
    address public owner;
    mapping(address => bool) admins;

    event adminAdded(address admin);
    event adminRemoved(address admin);
    event ContractOwnerShipTransferred(address owner);

    modifier only_owner() {
        require(msg.sender == owner, "Not owner");
        _;
    }
    modifier only_admin() {
        require(admins[msg.sender] || msg.sender == owner, "Not an admin");
        _;
    }

    constructor(address _owner) {
        owner = _owner;
    }

    function addAdmin(address newAddress) external virtual only_owner {
        require(
            newAddress != address(0) && !admins[newAddress],
            "Already an admin"
        );
        admins[newAddress] = true;
        emit adminAdded(newAddress);
    }

    function removeAdmin(address adminAddress) external virtual only_owner {
        require(
            adminAddress != address(0) && admins[adminAddress],
            "Not an admin"
        );
        admins[adminAddress] = false;
        emit adminRemoved(adminAddress);
    }

    function transferOwnerShip(address _newOwner) external virtual only_owner {
        require(_newOwner != address(0), "Invalid address");
        owner = _newOwner;
        emit ContractOwnerShipTransferred(_newOwner);
    }
}

contract DedicatedAccessControl is CommonAccessControl {
    mapping(address => bool) dedicatedMsgSenders;
    event ChangedDedicatedMsgSender(address contractAddr, bool value);

    modifier adminOrDedicatedSender() {
        require(
            admins[msg.sender] || dedicatedMsgSenders[msg.sender],
            "Not an admin"
        );
        _;
    }

    constructor(address _owner) CommonAccessControl(_owner) {}

    function changeDedicatedMsgSender(
        address _caller,
        bool value
    ) external virtual only_admin {
        require(_caller != address(0), "Invalid address");
        dedicatedMsgSenders[_caller] = value;
        emit ChangedDedicatedMsgSender(_caller, value);
    }
}
