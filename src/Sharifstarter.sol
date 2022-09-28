// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./Project.sol";

contract SharifStarter is ERC20 {
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
        uint256 durationInDays,
        uint256 tokenNumber,
        uint256 pricePerToken,
        uint256 maximumTokenSale
    ) external {
        uint256 raiseUntil = block.timestamp.add(durationInDays.mul(1 days));
        Project newProject = new Project(
            payable(msg.sender),
            title,
            description,
            tokenName,
            raiseUntil,
            tokenNumber,
            pricePerToken,
            maximumTokenSale
        );
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

    function returnAllProjects() external view returns (Project[] memory) {
        return projects;
    }
}
