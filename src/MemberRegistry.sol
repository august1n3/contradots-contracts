// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

/**
 * @title MemberRegistry
 * @notice Root creates clubs; club admin manages membership.
 */
contract MemberRegistry {
    struct Club {
        address admin;
        string name;
        bool active;
    }

    address public root;
    uint256 public nextClubId;
    mapping(uint256 => Club) public clubs;
    mapping(uint256 => mapping(address => bool)) public isMember;

    event ClubCreated(uint256 indexed clubId, address indexed admin, string name);
    event MemberAdded(uint256 indexed clubId, address indexed member);
    event MemberRemoved(uint256 indexed clubId, address indexed member);
    event ClubAdminTransferred(uint256 indexed clubId, address indexed newAdmin);

    modifier onlyRoot() {
        require(msg.sender == root, "Not root");
        _;
    }

    modifier onlyClubAdmin(uint256 clubId) {
        require(clubs[clubId].active, "Inactive club");
        require(clubs[clubId].admin == msg.sender, "Not club admin");
        _;
    }

    constructor(address _root) {
        root = _root;
    }

    function createClub(string calldata name, address admin) external onlyRoot returns (uint256) {
        require(admin != address(0), "Zero admin");
        uint256 id = nextClubId;
        clubs[id] = Club({admin: admin, name: name, active: true});
        isMember[id][admin] = true;
        nextClubId++;
        emit ClubCreated(id, admin, name);
        return id;
    }

    function addMember(uint256 clubId, address member) external onlyClubAdmin(clubId) {
        require(!isMember[clubId][member], "Already member");
        isMember[clubId][member] = true;
        emit MemberAdded(clubId, member);
    }

    function removeMember(uint256 clubId, address member) external onlyClubAdmin(clubId) {
        require(isMember[clubId][member], "Not member");
        isMember[clubId][member] = false;
        emit MemberRemoved(clubId, member);
    }

    function transferAdmin(uint256 clubId, address newAdmin) external onlyClubAdmin(clubId) {
        require(newAdmin != address(0), "Zero addr");
        clubs[clubId].admin = newAdmin;
        isMember[clubId][newAdmin] = true;
        emit ClubAdminTransferred(clubId, newAdmin);
    }

    // View helpers for cross-contract use
    function isClubAdmin(uint256 clubId, address who) external view returns (bool) {
        Club memory c = clubs[clubId];
        return c.active && c.admin == who;
    }

    function isClubMember(uint256 clubId, address who) external view returns (bool) {
        return isMember[clubId][who];
    }
}