// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./Project.sol";

contract SharifStarter is ERC20 {
    using SafeMath for uint256;

    Project[] private projects;
    mapping(string => Project) private symbols;

    constructor() ERC20("SharifStarter", "SHS") {
        _mint(msg.sender, 10000 * 10**18);
    }

    event ProjectCreated(
        address contractAddress,
        address projectStarter,
        string name,
        string symbol,
        string description,
        uint256 totalSupply
    );

    function createProject(
        address sharifstarter,
        string calldata name,
        string calldata symbol,
        string calldata description,
        uint256 totalSupply
    ) external {
        Project newProject = new Project(
            sharifstarter,
            msg.sender,
            name,
            symbol,
            description,
            totalSupply
        );
        projects.push(newProject);
        emit ProjectCreated(
            address(newProject),
            msg.sender,
            name,
            symbol,
            description,
            totalSupply
        );
    }

    function getProjects() external view returns (Project[] memory) {
        return projects;
    }

    function getProjectBySymbol(string memory symbol)
        public
        view
        returns (Project)
    {
        return symbols[symbol];
    }
}
