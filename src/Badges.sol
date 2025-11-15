// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

/**
 * @title Badges
 * @notice Minimal ERC1155-like badge contract. Activities contract mints badges to members.
 * NOTE: This is NOT a fully compliant ERC1155 (no safeTransfer hooks). Fine for internal tracking & events.
 */
contract Badges {
    address public owner;
    address public minter;

    mapping(uint256 => mapping(address => uint256)) public balanceOf; // badgeId => account => amount

    event TransferSingle(address indexed operator, address indexed to, uint256 id, uint256 amount);
    event MinterSet(address indexed minter);

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }
    modifier onlyMinter() {
        require(msg.sender == minter, "Not minter");
        _;
    }

    constructor(address _owner) {
        owner = _owner;
    }

    function setMinter(address _minter) external onlyOwner {
        minter = _minter;
        emit MinterSet(_minter);
    }

    function mint(address to, uint256 id, uint256 amount) external onlyMinter {
        require(to != address(0), "Zero addr");
        balanceOf[id][to] += amount;
        emit TransferSingle(msg.sender, to, id, amount);
    }

    // Simple view helper
    function hasBadge(address account, uint256 id) external view returns (bool) {
        return balanceOf[id][account] > 0;
    }
}