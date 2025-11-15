// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import "forge-std/Test.sol";
import "../src/MemberRegistry.sol";

contract MemberRegistryTest is Test {
    MemberRegistry registry;
    address root = address(0xA11CE);
    address clubAdmin = address(0xB0B);
    address user1 = address(0xC0C);
    address user2 = address(0xD0D);

    function setUp() public {
        registry = new MemberRegistry(root);
        vm.prank(root);
        registry.createClub("DevClub", clubAdmin);
    }

    function testCreateClubRootOnly() public {
        vm.expectRevert("Not root");
        registry.createClub("FailClub", user1);
    }

    function testAddMember() public {
        vm.prank(clubAdmin);
        registry.addMember(0, user1);
        assertTrue(registry.isClubMember(0, user1));
    }

    function testRemoveMember() public {
        vm.startPrank(clubAdmin);
        registry.addMember(0, user1);
        registry.removeMember(0, user1);
        vm.stopPrank();
        assertFalse(registry.isClubMember(0, user1));
    }

    function testTransferAdmin() public {
        vm.prank(clubAdmin);
        registry.transferAdmin(0, user1);
        assertTrue(registry.isClubAdmin(0, user1));
        assertTrue(registry.isClubMember(0, user1));
    }

    function testNonAdminAddMemberRevert() public {
        vm.expectRevert("Not club admin");
        registry.addMember(0, user2);
    }
}