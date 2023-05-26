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

    event AuctionCreated(address contractAddress, address creator);

    DevelopmentStages public stage = DevelopmentStages.Inception;
    ProjectDetails public projectDetails;

    address private sharifstarter;
    address public manager;

    bool public isApprovedForCrowdFund = false;
    Auction[] public auctions;

    modifier canCreateAuction() {
        require(
            stage != DevelopmentStages.Inception &&
                stage != DevelopmentStages.Canceled,
            "STAGE_ERR"
        );
        if (stage == DevelopmentStages.Elaboration) {
            require(isApprovedForCrowdFund, "NOT_APPROVED");
            require(msg.sender == projectDetails.founder, "O_FOUNDER");
        }
        _;
    }

    modifier isFounder() {
        require(msg.sender == projectDetails.founder, "O_FOUNDER");
        _;
    }

    modifier isManager() {
        require(msg.sender == manager, "DENIED");
        _;
    }

    modifier inStage(DevelopmentStages _stage) {
        require(stage == _stage, "STAGE_ERR");
        _;
    }

    constructor(
        address _sharifstarter,
        address _manager,
        address _founder,
        string memory name,
        string memory symbol,
        string memory description,
        uint256 totalSupply
    ) ERC20(name, symbol) {
        projectDetails = ProjectDetails(
            _founder,
            name,
            symbol,
            description,
            totalSupply
        );
        _mint(_sharifstarter, (projectDetails.totalSupply / 5));
        _mint(_founder, ((projectDetails.totalSupply * 4) / 5));

        sharifstarter = _sharifstarter;
        manager = _manager;
    }

    function createAuction(
        uint256 _saleTokenNum,
        uint256 _minValPerToken,
        uint256 _biddingTime,
        uint256 _delayedStartTime
    ) public canCreateAuction returns (bool) {
        require(_saleTokenNum < balanceOf(msg.sender), "INSUFFICIENT_FUND");
        Auction newAuction = new Auction(
            payable(msg.sender),
            _saleTokenNum,
            _minValPerToken,
            _biddingTime,
            _delayedStartTime
        );
        auctions.push(newAuction);
        _transfer(msg.sender, sharifstarter, _saleTokenNum);
        emit AuctionCreated(address(newAuction), msg.sender);
        return true;
    }

    function calcAuctionResult(address _address) public {
        require(_address != address(0), "INALID_INPUT");
        Auction _auction = Auction(_address);
        require(msg.sender == _auction.beneficiary(), "DENIED");

        bool hasWinner = _auction.selectWinners();
        _auction.returnFunds();

        if (hasWinner) {
            Bid[] memory bids = _auction.getWinners();
            for (uint256 i = 0; i < bids.length; i += 1) {
                _transfer(sharifstarter, bids[i].bidder, bids[i].reqTokenNum);
            }
        } else {
            _transfer(
                sharifstarter,
                _auction.beneficiary(),
                _auction.saleTokenNum()
            );
        }
    }

    function cancelAuction(address _address) public {
        require(_address != address(0), "INALID_INPUT");
        Auction _auction = Auction(_address);
        require(msg.sender == _auction.beneficiary(), "DENIED");

        _auction.returnFunds();
        _auction.cancel();

        _transfer(
            _auction.beneficiary(),
            sharifstarter,
            _auction.saleTokenNum()
        );
    }

    function canelProject()
        public
        isFounder
        inStage(DevelopmentStages.Inception)
    {
        stage = DevelopmentStages.Canceled;
    }

    function fundProject()
        public
        isFounder
        inStage(DevelopmentStages.Inception)
    {
        stage = DevelopmentStages.Elaboration;
    }

    function releaseProject()
        public
        isFounder
        inStage(DevelopmentStages.Elaboration)
    {
        require(isApprovedForCrowdFund, "NOT_APPROVED");
        stage = DevelopmentStages.Deployment;
    }

    function approveProject() public isManager {
        isApprovedForCrowdFund = true;
    }

    function getAuctions() public view returns (Auction[] memory) {
        return auctions;
    }
}
