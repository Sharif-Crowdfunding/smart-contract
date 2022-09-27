// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";


contract SharifStarter {
    using SafeMath for uint256;

    Project[] private projects;

    event ProjectStarted(
        address contractAddress,
        address projectStarter,
        string projectTitle,
        string projectDesc,
        uint256 deadline,
        uint256 goalAmount
    );

    function startProject(
        string calldata title,
        string calldata description,
        string calldata tokenName,
        uint durationInDays,
        uint tokenNumber,
        uint pricePerToken,
        uint maximumTokenSale
    ) external {
        uint raiseUntil = block.timestamp.add(durationInDays.mul(1 days));
        Project newProject = new Project(payable(msg.sender), title, description,tokenName, raiseUntil,tokenNumber,pricePerToken,maximumTokenSale);
        projects.push(newProject);
        emit ProjectStarted(
            address(newProject),
            msg.sender,
            title,
            description,
            raiseUntil,
            tokenNumber.mul(pricePerToken)
        );
    }                                                                                                                                   


    function returnAllProjects() external view returns(Project[] memory){
        return projects;
    }
}


contract Project {
    using SafeMath for uint256;
    
    enum State {
        InProgress,
        Canceled,
        Expired,
        Finished
    }

    struct ProjectToken{
       string  name;
       uint totalSupply;
       uint pricePerToken;
       uint maximumTokenSale;
    }

    address payable public creator; 
    uint public completeAt;
    uint256 public currentBalance;
    uint public raiseBy;
    string public title;
    string public description;
    State public state = State.InProgress;
    ProjectToken public projectToken;

    mapping (address => uint) public contributions;

    event FundingReceived(address contributor, uint amount, uint currentTotal);
    event CreatorPaid(address recipient);

    modifier inState(State _state) {
        require(state == _state);
        _;
    }

    modifier isCreator() {
        require(msg.sender == creator);
        _;
    }

    modifier canContribute(){
        require(msg.value + currentBalance <= getGoalAmount());
        _;
    }
    constructor (
        address payable projectStarter,
        string memory projectTitle,
        string memory projectDesc,
        string memory tokenName,
        uint fundRaisingDeadline,
        uint tokenNumber,
        uint pricePerToken,
        uint maximumTokenSale
    )  {
        creator = projectStarter;
        title = projectTitle;
        description = projectDesc;
        raiseBy = fundRaisingDeadline;
        currentBalance = 0;
        projectToken = ProjectToken(tokenName,tokenNumber,pricePerToken,maximumTokenSale);
    }

    function getGoalAmount() public view returns (uint){
        return projectToken.totalSupply * projectToken.pricePerToken;
    }

    function contribute() external inState(State.InProgress) canContribute() payable {
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
        } else if (block.timestamp > raiseBy)  {
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

        uint amountToRefund = contributions[msg.sender];
        contributions[msg.sender] = 0;

        if (!payable(msg.sender).send(amountToRefund)) {
            contributions[msg.sender] = amountToRefund;
            return false;
        } else {
            currentBalance = currentBalance.sub(amountToRefund);
        }

        return true;
    }

    function canelProject() public isCreator() {
        state=State.Canceled;
    }
    
    function getDetails() public view returns 
    (
        address payable projectStarter,
        string memory projectTitle,
        string memory projectDesc,
        uint256 deadline,
        State currentState,
        uint256 currentAmount,
        uint256 goalAmount
    ) {
        projectStarter = creator;
        projectTitle = title;
        projectDesc = description;
        deadline = raiseBy;
        currentState = state;
        currentAmount = currentBalance;
        goalAmount = getGoalAmount();
    }
}