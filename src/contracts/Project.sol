// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./ProjectDetails.sol";
import "./Auction.sol";

enum DevelopmentStages {
    Inception,
    Elaboration,
    Deployment,
    Canceled
}

contract Project is ERC20 {
    using SafeMath for uint256;

    DevelopmentStages public  stage = DevelopmentStages.Inception;
    ProjectDetails public projectDetails;

    bool public isApprovedForCrowdFund =false; 
    address[] public shareHolders;
    address   public tempAddress;
    Auction[] public auctions;

    modifier canCreateAuction() {
        require(stage != DevelopmentStages.Inception, "STAGE_ERR");
        if (stage == DevelopmentStages.Elaboration) {
            require(isApprovedForCrowdFund,"NOT_APPROVED");
            require(
                msg.sender == projectDetails.founder,
                "O_FOUNDER"
            );
        }
        _;
    }

    modifier isFounder() {
        require(msg.sender == projectDetails.founder, "O_FOUNDER");
        _;
    }

    constructor(
        address sharifstarter,
        address founder,
        string memory name,
        string memory symbol,
        string memory description,
        uint256 totalSupply
    ) ERC20(name, symbol) {
        projectDetails = ProjectDetails(
            founder,
            name,
            symbol,
            description,
            totalSupply
        );
        _mint(
            sharifstarter,
            (projectDetails.totalSupply / 5) * 10**uint256(decimals())
        );
        _mint(
            founder,
            ((projectDetails.totalSupply * 4) / 5) * 10**uint256(decimals())
        );
        shareHolders.push(sharifstarter);
        shareHolders.push(founder);
        tempAddress = sharifstarter;
    }

    function createAuction(
        uint256 biddingTime,
        uint256 amount,
        uint256 minimumBid
    ) public canCreateAuction returns (bool) {
        require(amount < balanceOf(msg.sender), "INSUFFICIENT_FUND");
        Auction newAuction = new Auction(
            payable(msg.sender),
            amount,
            minimumBid,
            biddingTime
        );
        auctions.push(newAuction);
        _transfer(msg.sender, tempAddress, amount);
        return true;
    }

    // function endAuction(Auction auction) public returns (bool) {
    // //         Waitting,
    // // InProgress,
    // // Canceled,
    // // Expired,
    // // Finished
    //     require(auction.beneficiary() == payable(msg.sender), "Access Denied");
        
    //     return true;
    // }

    function canelProject() public isFounder() {
        stage = DevelopmentStages.Canceled;
    }

    function fundProject() public isFounder() {
        stage = DevelopmentStages.Elaboration;
    }

    function releaseProject() public isFounder() {
        stage = DevelopmentStages.Deployment;
    }

    function approveProject() public   {
        isApprovedForCrowdFund =true;
    }

    function getAuctions() public view returns (Auction[] memory) {
        return auctions;
    }

}
