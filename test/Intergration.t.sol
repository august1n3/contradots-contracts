// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import "forge-std/Test.sol";
import "../src/MemberRegistry.sol";
import "../src/RewardToken.sol";
import "../src/Badges.sol";
import "../src/Activities.sol";

contract IntegrationTest is Test {
    MemberRegistry registry;
    RewardToken token;
    Badges badges;
    Activities activities;
    
    address root = address(0xA11CE);
    address clubAdmin = address(0xB0B);
    address member = address(0xC0C);
    
    function setUp() public {
        // Deploy all contracts
        registry = new MemberRegistry(root);
        token = new RewardToken(1000000 * 10**18, root);
        badges = new Badges(root);
        activities = new Activities(
            root,
            address(registry),
            address(token),
            address(badges)
        );
        
        // Grant minting permissions
        vm.startPrank(root);
        token.setMinter(address(activities));
        badges.setMinter(address(activities));
        
        // Create club
        registry.createClub("TestClub", clubAdmin);
        vm.stopPrank();
        
        // Add member
        vm.prank(clubAdmin);
        registry.addMember(0, member);
    }
    
    function testFullFlow() public {
        // Create activity
        vm.prank(clubAdmin);
        uint256 activityId = activities.createActivity(
            0,                  // clubId
            type(uint256).max,  // very easy difficulty
            100 * 10**18,       // 100 tokens reward
            0,                  // start now
            0,                  // no end
            10,                 // max 10 actions
            1                   // badge ID 1 on first action
        );
        
        // Member submits action
        bytes memory payload = "hello";
        uint256 nonce = 12345; // In reality, this needs to be mined
        
        vm.prank(member);
        activities.submitAction(activityId, payload, nonce);
        
        // Verify rewards
        assertEq(token.balanceOf(member), 100 * 10**18);
        assertEq(badges.balanceOf(1, member), 1);
        assertEq(activities.remainingActions(activityId, member), 9);
    }
}