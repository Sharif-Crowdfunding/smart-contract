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
    address public highestBidder;
    uint256 public highestbid;
    AuctionState public state;

    mapping(address => uint256) pendingReturns;

    event highestBidIncreased(address bidder, uint256 amount);
    event auctionEnded(address winner, uint256 amount);

    constructor(
        address payable _beneficiary,
        uint256 _amount,
        uint256 _minimumBid,
        uint256 _biddingTime
    ) {
        beneficiary = _beneficiary;

        auctionStartTime = block.timestamp + 60 * 60 * 24;
        auctionEndTime = auctionStartTime + _biddingTime;

        amount = _amount;
        minimumBid = _minimumBid;

        state = AuctionState.Waitting;
    }

    function bid() public payable {
        if (block.timestamp > auctionEndTime) revert("ENDED_AUCTION");
        if (block.timestamp < auctionStartTime) revert("NOT_STARTED_AUCTION");

        if (msg.value >= minimumBid) revert("LOW_BID");
        if (msg.value <= highestbid) revert("LOW_BID");

        if (highestbid != 0) {
            pendingReturns[highestBidder] += highestbid;
        }

        highestBidder = msg.sender;
        highestbid = msg.value;
        auctionEndTime += 15 * 60;
        emit highestBidIncreased(msg.sender, msg.value);
    }

    function withdraw() public payable returns (bool) {
        uint256 payment = pendingReturns[msg.sender];
        if (payment > 0) {
            pendingReturns[msg.sender] = 0;
        }

        if (!payable(msg.sender).send(payment)) {
            pendingReturns[msg.sender] = payment;
        }
        return true;
    }

    function endAuction() public returns (bool) {
        if (state == AuctionState.Waitting) revert("NOT_STARTED_AUCTION");
        if (state != AuctionState.InProgress) revert("FINISHED_AUCTION");

        emit auctionEnded(highestBidder, highestbid);
        beneficiary.transfer(highestbid);
        return true;
    }
}
