// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

enum State {
    InProgress,
    Canceled,
    Expired,
    Finished
}

contract Auction {
    address payable public beneficiary;
    uint256 public auctionEndTime;

    // current state of the auction
    address public highestBidder;
    uint256 public highestbid;
    uint256 public minimumBid;
    bool ended;

    mapping(address => uint256) pendingReturns;

    event highestBidIncreased(address bidder, uint256 amount);
    event auctionEnded(address winner, uint256 amount);

    constructor(
        address payable _beneficiary,
        // uint256 _amount,
        uint256 _minimumBid,
        uint256 _biddingTime
    ) {
        beneficiary = _beneficiary;
        auctionEndTime = block.timestamp + _biddingTime;
        minimumBid = _minimumBid;
    }

    function bid() public payable {
        if (block.timestamp > auctionEndTime) revert("ENDED_AUCTION");

        if (msg.value <= highestbid) revert("BID_NOT_ENOUGH");

        if (highestbid != 0) {
            pendingReturns[highestBidder] += highestbid;
        }

        highestBidder = msg.sender;
        highestbid = msg.value;
        emit highestBidIncreased(msg.sender, msg.value);
    }

    //widraws bids that were overbid

    function withdraw() public payable returns (bool) {
        uint256 amount = pendingReturns[msg.sender];
        if (amount > 0) {
            pendingReturns[msg.sender] = 0;
        }

        if (!payable(msg.sender).send(amount)) {
            pendingReturns[msg.sender] = amount;
        }
        return true;
    }

    function auctionEnd() public {
        if (block.timestamp < auctionEndTime)
            revert("the auction has not ended yet!");
        if (ended) revert("the auction is already over!");

        ended = true;
        emit auctionEnded(highestBidder, highestbid);
        beneficiary.transfer(highestbid);
    }
}
