// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "./Bid.sol";

enum AuctionState {
    Waitting,
    InProgress,
    Canceled,
    Expired,
    Finished
}

contract Auction {
    address payable public beneficiary;
    uint256 public endTime;
    uint256 public startTime;
    uint256 public saleTokenNum;
    uint256 public minValPerToken;

    address[] private bidders;
    Bid[] private winners;

    mapping(address => Bid) bids;
    AuctionState public state;

    event bidAdded(address bidder, uint256 amount, uint256 payload);
    event bidUpdated(address bidder, uint256 amount, uint256 payload);

    modifier checkAuctionTime() {
        if (block.timestamp > endTime) revert("ENDED_AUCTION");
        if (block.timestamp < startTime) revert("NOT_STARTED_AUCTION");
        _;
    }

    constructor(
        address payable _beneficiary,
        uint256 _saleTokenNum,
        uint256 _minValPerToken,
        uint256 _biddingTime,
        uint256 _delayedStartTime
    ) {
        beneficiary = _beneficiary;

        startTime = block.timestamp + _delayedStartTime;
        endTime = startTime + _biddingTime;

        saleTokenNum = _saleTokenNum;
        minValPerToken = _minValPerToken;

        state = AuctionState.Waitting;
    }

    function updateState() public {
        if (state == AuctionState.Waitting && block.timestamp > startTime)
            state = AuctionState.InProgress;
        if (state == AuctionState.InProgress && block.timestamp > endTime) {
            if (bidders.length == 0) state = AuctionState.Expired;
            else state = AuctionState.Finished;
        }
    }

    function bid(uint256 _payload) public payable checkAuctionTime {
        updateState();
        require(state == AuctionState.InProgress, "STATE_ERR");
        if ((msg.value / _payload) < minValPerToken) revert("LOW_BID");

        if (bids[msg.sender].bidder == address(0)) {
            bidders.push(msg.sender);
            bids[msg.sender] = Bid(msg.sender, msg.value, _payload, false);
        } else revert("DUPLICATE_BIDDER");

        if (endTime - block.timestamp < 15 * 60)
            endTime = block.timestamp + 15 * 60;
        emit bidAdded(msg.sender, msg.value, _payload);
    }

    function updateBid(uint256 _payload) public payable checkAuctionTime {
        updateState();
        require(state == AuctionState.InProgress, "STATE_ERR");
        require(bids[msg.sender].bidder == address(0), "NO_BID");
        Bid memory lastBid = bids[msg.sender];
        if (((msg.value + lastBid.totalVal) / _payload) < minValPerToken)
            revert("LOW_BID");
        bids[msg.sender] = Bid(
            msg.sender,
            msg.value + lastBid.totalVal,
            _payload,
            lastBid.sellAllOrNothing
        );

        if (endTime - block.timestamp < 15 * 60)
            endTime = block.timestamp + 15 * 60;
        emit bidUpdated(msg.sender, msg.value + lastBid.totalVal, _payload);
    }

    function selectWinners() public returns (bool) {
        updateState();
        require(state == AuctionState.Finished, "STATE_ERR");
        require(winners.length == 0);
        uint256 unsoldToken = saleTokenNum;
        for (uint256 i = 0; i < bidders.length - 1; i += 1) {
            Bid memory temp = getBestPrice();
            if (temp.bidder == address(0) || unsoldToken == 0) break;

            if (unsoldToken >= temp.reqTokenNum) {
                winners.push(temp);
                unsoldToken -= temp.reqTokenNum;
                delete bids[temp.bidder];
            } else {
                uint256 div = temp.totalVal / temp.reqTokenNum;
                uint256 unsold = temp.reqTokenNum - unsoldToken;
                temp.reqTokenNum = unsoldToken;
                temp.totalVal = temp.reqTokenNum * div;
                winners.push(temp);
                unsoldToken = 0;
                bids[temp.bidder].totalVal = unsold * div;
            }
        }
        return true;
    }

    function getBestPrice() private view returns (Bid memory) {
        Bid memory maxBid = Bid(address(0), 0, 1, false);
        for (uint256 i = 0; i < bidders.length - 1; i += 1) {
            if (bids[bidders[i]].bidder != address(0)) {
                if (
                    (bids[bidders[i]].totalVal / bids[bidders[i]].reqTokenNum) >
                    (maxBid.totalVal / maxBid.reqTokenNum)
                ) maxBid = bids[bidders[i]];
            }
        }
        return maxBid;
    }

    function returnFunds() public {
        require(winners.length > 0);
        for (uint256 i = 0; i < bidders.length - 1; i += 1) {
            if (bids[bidders[i]].bidder != address(0)) {
                transfer(
                    payable(bids[bidders[i]].bidder),
                    bids[bidders[i]].totalVal
                );
            }
        }
        withdraw();
    }

    function withdraw() private {
        uint256 balance = address(this).balance;

        (bool success, ) = beneficiary.call{value: balance}("");
        require(success, "WITHRAW_ERR");
    }

    function transfer(address payable _to, uint256 _amount) private {
        (bool success, ) = _to.call{value: _amount}("");
        require(success, "TRANSFER_ERR");
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function getWinners() public view returns (Bid[] memory) {
        return winners;
    }

    function cancel() public returns (bool) {
        updateState();
        require(state == AuctionState.Waitting, "STATE_ERR");
        state = AuctionState.Expired;
        return true;
    }

    function getTimestamp() public view returns (uint256) {
        return block.timestamp;
    }
}
