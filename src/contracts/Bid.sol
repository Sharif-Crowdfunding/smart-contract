// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;
struct Bid {
    address bidder;
    uint256 totalVal;
    uint256 reqTokenNum;
    bool sellAllOrNothing;
}
