pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {FundMe} from "../../src/FundMe.sol";
import {DeployFundMe} from "../../script/DeployFundMe.s.sol";

contract FundMeTest is Test {
    
    FundMe fundMe;
    address USER = makeAddr("USER");

    uint256 constant GAS_PRICE = 1;

    function setUp() public {
        DeployFundMe deployFundMe = new DeployFundMe();
        fundMe = deployFundMe.run();
        vm.deal(USER, 10 ether);
    }

    function makeFundedUser(string memory tag) public returns (address) {
        address addr = makeAddr(tag);
        deal(addr, 10 ether);
        return addr;
    }

    modifier funded() {
        vm.prank(USER);
        fundMe.fund{value: 5e18}();
        _;
    }

    function testMininimumUSDIs5() public {
        assertEq(fundMe.MINIMUM_USD(), 5e18);
    }

    function testOwnerIsDeployer() public {
        assertEq(fundMe.i_owner(), msg.sender);
    }

    function testGetsCorrectVersion() public {
        assertEq(fundMe.getVersion(), 4);
    }    

    function testFundFailsWithoutEnoutETH() public {
        vm.expectRevert();
        fundMe.fund();
    }

    function testFundSucceedsWithEnoughETH() public {
        vm.prank(USER);
        fundMe.fund{value: 55e17}();
        uint256 amountFunded = fundMe.getAddressToAmountFunded(USER);
        assertEq(amountFunded, 55e17);
    }

    function testFundersBeingAddedProperly() public {
        vm.prank(USER);
        fundMe.fund{value: 55e17}();
        address funder = fundMe.getFunder(0);
        assertEq(funder, USER);
    }

    function testOnlyOwnerCanWithdraw() public {
        vm.prank(USER);
        fundMe.fund{value: 5e18}();

        vm.expectRevert();
        fundMe.withdraw();
    }


    function testOwnerCanWithdraw() public funded {
        // Arrange
        address owner = fundMe.getOwner();
        uint256 startingOwnerBalance = owner.balance;
        uint256 startingContractBalance = address(fundMe).balance;

        // Act
        
        vm.txGasPrice(GAS_PRICE);  
        vm.prank(fundMe.getOwner());
        fundMe.withdraw();
        
        uint256 expectedAmountFunded = startingContractBalance + startingOwnerBalance;
        assertEq(owner.balance, expectedAmountFunded);
        assertEq(address(fundMe).balance, 0);
    }

    function testMultipleFunders() public {
        // Arrange
        uint256 fundingAmount = 5e18;
        address owner = fundMe.getOwner();
        uint256 startingOwnerBalance = owner.balance;
        address[] memory funders = new address[](3);
        funders[0] = makeFundedUser("USER1");
        funders[1] = makeFundedUser("USER2");
        funders[2] = makeFundedUser("USER3");
        
        // Act
        for(uint256 i = 0; i < funders.length; i++) {
            vm.prank(funders[i]);
            fundMe.fund{value: fundingAmount}();
        }

        vm.prank(owner);
        fundMe.withdraw();

        // Assert
        assertEq(fundMe.getOwner().balance, startingOwnerBalance + (fundingAmount * 3));
        assertEq(address(fundMe).balance, 0);
    }

}