// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
enum State {
    InProgress,
    Canceled,
    Expired,
    Finished
}

contract Project is ERC20 {
    using SafeMath for uint256;

    struct ProjectToken {
        string name;
        uint256 totalSupply;
        uint256 pricePerToken;
        uint256 maximumTokenSale;
    }

    address payable public creator;
    uint256 public completeAt;
    uint256 public currentBalance;
    uint256 public raiseBy;
    string public title;
    string public description;
    State public state = State.InProgress;
    ProjectToken public projectToken;

    mapping(address => uint256) public contributions;

    event FundingReceived(
        address contributor,
        uint256 amount,
        uint256 currentTotal
    );
    event CreatorPaid(address recipient);

    modifier inState(State _state) {
        require(state == _state);
        _;
    }

    modifier isCreator() {
        require(msg.sender == creator);
        _;
    }

    modifier canContribute() {
        require(msg.value + currentBalance <= getGoalAmount());
        _;
    }

    constructor(
        address payable projectStarter,
        string memory projectTitle,
        string memory projectDesc,
        string memory tokenName,
        uint256 fundRaisingDeadline,
        uint256 tokenNumber,
        uint256 pricePerToken,
        uint256 maximumTokenSale
    ) ERC20(tokenName, projectTitle) {
        creator = projectStarter;
        title = projectTitle;
        description = projectDesc;
        raiseBy = fundRaisingDeadline;
        currentBalance = 0;
        projectToken = ProjectToken(
            tokenName,
            tokenNumber,
            pricePerToken,
            maximumTokenSale
        );
        _mint(msg.sender, 100 * 10**uint256(decimals()));
    }

    function getGoalAmount() public view returns (uint256) {
        return projectToken.totalSupply * projectToken.pricePerToken;
    }

    function contribute()
        external
        payable
        inState(State.InProgress)
        canContribute
    {
        require(msg.sender != creator);
        contributions[msg.sender] = contributions[msg.sender].add(msg.value);
        currentBalance = currentBalance.add(msg.value);
        emit FundingReceived(msg.sender, msg.value, currentBalance);
        checkIfFundingFinishedOrCanceled();
    }

    function checkIfFundingFinishedOrCanceled() public {
        if (currentBalance >= getGoalAmount()) {
            state = State.Finished;
            payOut();
        } else if (block.timestamp > raiseBy) {
            state = State.Expired;
        }
        completeAt = block.timestamp;
    }

    function payOut() internal inState(State.Finished) returns (bool) {
        uint256 totalRaised = currentBalance;
        currentBalance = 0;

        if (creator.send(totalRaised)) {
            emit CreatorPaid(creator);
            return true;
        } else {
            currentBalance = totalRaised;
            state = State.Finished;
        }

        return false;
    }

    function getRefund() public inState(State.Canceled) returns (bool) {
        require(contributions[msg.sender] > 0);

        uint256 amountToRefund = contributions[msg.sender];
        contributions[msg.sender] = 0;

        if (!payable(msg.sender).send(amountToRefund)) {
            contributions[msg.sender] = amountToRefund;
            return false;
        } else {
            currentBalance = currentBalance.sub(amountToRefund);
        }

        return true;
    }

    function canelProject() public isCreator {
        state = State.Canceled;
    }

    function getDetails()
        public
        view
        returns (
            address payable projectStarter,
            string memory projectTitle,
            string memory projectDesc,
            uint256 deadline,
            State currentState,
            uint256 currentAmount,
            uint256 goalAmount
        )
    {
        projectStarter = creator;
        projectTitle = title;
        projectDesc = description;
        deadline = raiseBy;
        currentState = state;
        currentAmount = currentBalance;
        goalAmount = getGoalAmount();
    }
}
