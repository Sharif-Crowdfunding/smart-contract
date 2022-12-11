// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./ProjectDetails.sol";
import "./Auction.sol";

enum DevelopmentStages {
    Inception,
    Deployment,
    Maintenance,
    Canceled
}

contract Project is ERC20 {
    using SafeMath for uint256;

    DevelopmentStages private stage = DevelopmentStages.Inception;
    ProjectDetails private projectDetails;

    mapping(address => uint256) private balanceOfShareHolder;
    address[] private shareHolders;
    Auction[] private auctions;

    modifier canCreateAuction() {
        require(stage != DevelopmentStages.Inception, "STAGE_ERR");
        if (stage == DevelopmentStages.Deployment) {
            require(msg.sender == projectDetails.founder, "O_FOUNDER");
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
        _burn(msg.sender, amount);
        return true;
    }

    function endAuction(Auction auction) public returns (bool) {
        require(auction.beneficiary() == payable(msg.sender), "DENIED");
        bool isDone = auction.endAuction();
        if (isDone && auction.state() == AuctionState.Finished)
            _mint(msg.sender, auction.amount());
        return true;
    }

    function canelProject() public isFounder {
        stage = DevelopmentStages.Canceled;
    }

    function fundProject() public isFounder {
        stage = DevelopmentStages.Deployment;
    }

    function releaseProject() public isFounder {
        stage = DevelopmentStages.Maintenance;
    }

    function getAuctions() public view returns (Auction[] memory) {
        return auctions;
    }
}
