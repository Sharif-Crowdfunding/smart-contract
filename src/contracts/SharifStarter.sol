// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./Project.sol";

contract SharifStarter is ERC20 {
    using SafeMath for uint256;

    address private owner;
    Project[] private projects;
    mapping(string => Project) private symbols;

    constructor() ERC20("SharifStarter", "SHS") {
        owner=msg.sender;
        _mint(msg.sender, 10000 * 10**18);
    }

    event ProjectCreated(
        address contractAddress,
        address founder,
        string name,
        string symbol,
        string description,
        uint256 totalSupply
    );

    function createProject(
        address manager,
        string calldata name,
        string calldata symbol,
        string calldata description,
        uint256 totalSupply
    ) external {
        require(
            checkValidInput(manager, name, symbol, totalSupply),
            "INVALID_INPUT"
        );
        require(address(symbols[symbol]) == address(0x0), "DUPLICATE");

        Project newProject = new Project(
            owner,
            manager,
            msg.sender,
            name,
            symbol,
            description,
            totalSupply
        );
        projects.push(newProject);
        symbols[symbol] = newProject;
        emit ProjectCreated(
            address(newProject),
            msg.sender,
            name,
            symbol,
            description,
            totalSupply
        );
    }

    function checkValidInput(
        address manager,
        string memory name,
        string memory symbol,
        uint256 totalSupply
    ) private pure returns (bool) {
        if (
            address(manager) != address(0x0) &&
            bytes(name).length > 0 &&
            bytes(symbol).length > 0 &&
            totalSupply > 0
        ) {
            return true;
        }
        return false;
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
