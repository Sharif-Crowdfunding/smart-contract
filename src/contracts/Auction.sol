// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

enum AuctionState {
    Waitting,
    InProgress,
    Canceled,
    Expired,
    Finished
}

contract Auction {
    address payable public beneficiary;
    uint256 public auctionEndTime;
    uint256 public auctionStartTime;
    uint256 public amount;
    uint256 public minimumBid;

    // current state of the auction
    struct Bid {
        address bidder;
        uint256 bidValue;
        uint256 amount;
    }

    Bid[] private bidders;
    AuctionState public state;

    uint256 public currentBalance;

    event bidAdded(address bidder, uint256 amount, uint256 payload);
    event auctionEnded(address winner, uint256 amount);

    modifier inState(AuctionState _state) {
        if (
            _state == AuctionState.Waitting &&
            block.timestamp > auctionStartTime
        ) state = AuctionState.InProgress;
        if (
            _state == AuctionState.InProgress &&
            block.timestamp > auctionEndTime
        ) {}
        require(state == _state, "Auction is not in correct state");
        _;
    }

    modifier checkAuctionTime() {
        if (block.timestamp > auctionEndTime) revert("ENDED_AUCTION");
        if (block.timestamp < auctionStartTime) revert("NOT_STARTED_AUCTION");
        _;
    }

    constructor(
        address payable _beneficiary,
        uint256 _amount,
        uint256 _minimumBid,
        uint256 _biddingTime
    ) {
        beneficiary = _beneficiary;

        auctionStartTime = block.timestamp + 60 * 60 * 24;
        auctionEndTime = auctionStartTime + _biddingTime;

        currentBalance = 0;
        amount = _amount;
        minimumBid = _minimumBid;

        state = AuctionState.Waitting;
    }

    function bid(uint256 payload)
        public
        payable
        inState(AuctionState.InProgress)
        checkAuctionTime
    {
        if ((msg.value / payload) < minimumBid) revert("LOW_BID");

        currentBalance += msg.value;
        bidders.push(Bid(msg.sender, msg.value, payload));

        auctionEndTime += 15 * 60;
        emit bidAdded(msg.sender, msg.value, payload);
    }

    function withdraw() public payable returns (bool) {
        return true;
    }

    function start() public inState(AuctionState.Waitting) returns (bool) {
        if (block.timestamp < auctionStartTime) revert("NOT_STARTED_AUCTION");
        state = AuctionState.InProgress;
        return true;
    }

    function cancel() public inState(AuctionState.Waitting) returns (bool) {
        state = AuctionState.InProgress;
        return true;
    }
}
