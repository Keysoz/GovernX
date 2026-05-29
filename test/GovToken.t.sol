// SPDX-License-Identifier: MIT
pragma solidity 0.8.35;

import {Test, console} from "forge-std/Test.sol";
import {GovernX} from "../src/GovToken.sol";
import {DeployGovernX} from "../script/GovToken.s.sol";

contract TestGovernX is Test {
    GovernX public governor;
    DeployGovernX public deployer;

    // Deploy fresh contract before each test
    function setUp() public {
        deployer = new DeployGovernX();
        governor = deployer.run();
    }

    // =========================
    // Functional Tests
    // =========================

    function test_InitialSupply() public view {
        uint256 expectedSupply = 1000000 ether;
        uint256 actualSupply = governor.totalSupply();

        assertEq(expectedSupply, actualSupply, "Error in initial supply");
    }

    function test_Transfer() public {
        address alice = makeAddr("alice");
        address bob = makeAddr("bob");

        uint256 transferAmount = 100 ether;

        // Give Alice tokens
        deal(address(governor), alice, transferAmount);

        uint256 aliceBalanceBefore = governor.balanceOf(alice);
        uint256 bobBalanceBefore = governor.balanceOf(bob);

        // Transfer tokens as Alice
        vm.prank(alice);
        bool success = governor.transfer(bob, transferAmount);

        assertTrue(success);

        // Verify balances updated correctly
        assertEq(governor.balanceOf(alice), aliceBalanceBefore - transferAmount, "alice balance incorrect");

        assertEq(governor.balanceOf(bob), bobBalanceBefore + transferAmount, "bob balance incorrect");
    }

    function test_TransferRevertsIfInsufficientBalance() public {
        address alice = makeAddr("Alice");
        address bob = makeAddr("Bob");

        uint256 transferAmount = 100;

        // Expect revert because Alice owns no tokens
        vm.expectRevert();

        vm.prank(alice);
        governor.transfer(bob, transferAmount);
    }

    function test_ApproveAndTransferFrom() public {
        address alice = makeAddr("Alice");
        address bob = makeAddr("Bob");

        uint256 balance = 1000 ether;
        uint256 allowedBalance = 500 ether;

        // Give Alice tokens
        deal(address(governor), alice, balance);

        // Alice approves Bob to spend tokens
        vm.prank(alice);
        governor.approve(bob, allowedBalance);

        // Bob transfers approved tokens
        vm.prank(bob);
        bool success = governor.transferFrom(alice, bob, allowedBalance);

        assertTrue(success);

        // Verify balances updated correctly
        assertEq(governor.balanceOf(alice), balance - allowedBalance, "Incorrect Balance Of Alice");

        assertEq(governor.balanceOf(bob), allowedBalance, "Incorrect Balance of Bob");

        // Verify allowance was consumed
        assertEq(governor.allowance(alice, bob), 0, "Allowance was not decremented correctly");
    }

    // =========================
    // Governance / Security Tests
    // =========================

    function test_VotingPowerIsZeroWithoutDelegation() public {
        address alice = makeAddr("Alice");

        uint256 balanceAmount = 500000 ether;

        deal(address(governor), alice, balanceAmount);

        // Balance exists
        assertEq(governor.balanceOf(alice), balanceAmount, "Balance Error");

        // Votes should remain zero until delegation
        assertEq(governor.getVotes(alice), 0, "Delegation Error");
    }

    function test_SelfDelegation() public {
        address alice = makeAddr("Alice");

        uint256 balanceAmount = 500000 ether;

        deal(address(governor), alice, balanceAmount);

        // Votes are zero before delegation
        assertEq(governor.getVotes(alice), 0);

        // Self delegate
        vm.prank(alice);
        governor.delegate(alice);

        // Votes should equal token balance
        assertEq(governor.getVotes(alice), balanceAmount, "Error in Delegation");
    }

    function test_DelegateToOther() public {
        address alice = makeAddr("Alice");
        address bob = makeAddr("Bob");

        uint256 balanceAmount = 500000 ether;

        deal(address(governor), alice, balanceAmount);

        // Initial state
        assertEq(governor.balanceOf(alice), balanceAmount);
        assertEq(governor.balanceOf(bob), 0);

        assertEq(governor.getVotes(alice), 0);
        assertEq(governor.getVotes(bob), 0);

        // Delegate voting power to Bob
        vm.prank(alice);
        governor.delegate(bob);

        // Balances should not change
        assertEq(governor.balanceOf(alice), balanceAmount);
        assertEq(governor.balanceOf(bob), 0);

        // Votes should move to Bob
        assertEq(governor.getVotes(alice), 0);
        assertEq(governor.getVotes(bob), balanceAmount);
    }

    function test_UndelegateByRedelegating() public {
        address alice = makeAddr("Alice");
        address bob = makeAddr("Bob");

        uint256 balanceAmount = 500000 ether;

        deal(address(governor), alice, balanceAmount);

        // Initial state
        assertEq(governor.getVotes(alice), 0);
        assertEq(governor.getVotes(bob), 0);

        // Delegate to Bob
        vm.prank(alice);
        governor.delegate(bob);

        assertEq(governor.getVotes(alice), 0);
        assertEq(governor.getVotes(bob), balanceAmount);

        // Re-delegate back to Alice
        vm.prank(alice);
        governor.delegate(alice);

        // Votes restored to Alice
        assertEq(governor.balanceOf(alice), balanceAmount);
        assertEq(governor.balanceOf(bob), 0);

        assertEq(governor.getVotes(alice), balanceAmount);
        assertEq(governor.getVotes(bob), 0);
    }

    function test_SnapshotPreventsFlashLoanAttack() public {
        address alice = makeAddr("Alice");
        address bob = makeAddr("Bob");

        uint256 balanceAmount = 500000 ether;

        deal(address(governor), alice, balanceAmount);

        // Initial state
        assertEq(governor.getVotes(alice), 0);
        assertEq(governor.getVotes(bob), 0);

        // Alice self-delegates to activate voting power
        vm.prank(alice);
        governor.delegate(alice);

        assertEq(governor.getVotes(alice), balanceAmount);
        assertEq(governor.getVotes(bob), 0);

        // Move forward so snapshot becomes historical
        vm.roll(block.number + 1);

        uint256 snapshotBlock = block.number - 1;

        // Alice transfers all tokens to Bob
        vm.prank(alice);
        bool success = governor.transfer(bob, balanceAmount);

        assertTrue(success);

        // Bob delegates received tokens to himself
        vm.prank(bob);
        governor.delegate(bob);

        // Historical voting power should remain unchanged
        assertEq(governor.getPastVotes(alice, snapshotBlock), balanceAmount);

        assertEq(governor.getPastVotes(bob, snapshotBlock), 0);
    }

    function test_nonces() public {
        address alice = makeAddr("alice");
        address bob = makeAddr("bob");

        uint256 transferAmount = 100 ether;

        // Give Alice tokens
        deal(address(governor), alice, transferAmount);

        vm.prank(alice);
        uint256 aliceNoncesBefore = governor.nonces(alice);
        assertEq(aliceNoncesBefore, 0, "Error in nonces Before");

        // Transfer tokens as Alice
        vm.prank(alice);
        bool success = governor.transfer(bob, transferAmount);
        assertTrue(success);

        vm.prank(alice);
        uint256 aliceNoncesAfter = governor.nonces(alice);
        assertEq(aliceNoncesAfter, 0, "Error in nonces After");
    }
}
