// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "hardhat/console.sol";

contract DepayData is AccessControl {

    struct Hire {
        string organization;
        uint8 hires;
        bool flexible;
    }
    mapping(address => Hire) hire;
    Hire[] hires;
    struct Talent {
        string name;
        string occupation;
        uint8 paidWork;
    }
    mapping(address => Talent) talent;
    Talent[] talents;
    enum Interval {
        DAILY,
        WEEKLY,
        MONTHLY
    }
    struct Deal {
        string role;
        Interval interval;
        uint duration;
        uint paidCoverage;
        address token;
        uint salary;
        bool active;
        bool accepted;
        uint256 paidWork;
    }

    mapping(address => mapping(address => Deal)) deal;

    Deal[] deals;

    struct AcceptedToken {
        string symbol;
        uint128 decimals;
        address tokenAddress;
    }
    mapping(address => AcceptedToken) public acceptedTokens;

    mapping(address => bool) public isAcceptedToken;

    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");

    event NewHire(address _hire, uint _timestamp);
    event NewDeal(address _hire, address _talent, uint8 _duration, uint _pay, address _token);
    event NewTalent(address _talent, uint _salary);

    constructor() {
        // Add admin role to the contract
        _setupRole(ADMIN_ROLE, msg.sender);
        // Add manager role to the contract
        _setupRole(MANAGER_ROLE, msg.sender);
    }

    function grantManagerRole(address _manager) public onlyRole(ADMIN_ROLE) {
        _grantRole(MANAGER_ROLE, _manager);
    }

    function revokeManagerRole(address _manager) public onlyRole(ADMIN_ROLE) {
        _revokeRole(MANAGER_ROLE, _manager);
    }

    function addHire(string memory _name) public {
        Hire memory newHire = Hire(_name, 0, false);
        hires.push(newHire);
        emit NewHire(msg.sender, block.timestamp);
    }

    function addTalent(string memory _name, string memory _occupation) public onlyRole(ADMIN_ROLE) {
        Talent memory newTalent = Talent(_name, _occupation, 0);
        talents.push(newTalent);
        emit NewTalent(msg.sender, 0);
    }

    function addDeal(address _talent, uint8 _duration, uint _pay, address _token, string memory _role) external {
        require(isAcceptedToken[_token], "Token is not accepted");
        require(_talent != address(0), "Talent is not set");
        require(_duration > 0, "Duration is not set");
        require(deal[_talent][_token].active == false, "Deal is already active");
        // Add if talent exists & talen already have a deal
        Deal memory newDeal = Deal(_role, Interval.DAILY, _duration, 0, _token, _pay, false, false, 0);
        deal[msg.sender][_talent] = newDeal;
        emit NewDeal(msg.sender, _talent, _duration, _pay, _token);
    }

    function acceptDeal(address _talent) view external {
        Deal memory newDeal = deal[msg.sender][_talent];
        require(newDeal.active == false, "Already accepted");
        newDeal.active = true;
    }      

    function checkDealStatus(address _hire, address _talent) public view returns (bool) {
        Deal memory theDeal = deal[_hire][_talent];
        return theDeal.accepted;

    }

    function addAcceptedToken(string memory _symbol, uint8 _decimals, address _tokenAddress) public onlyRole(MANAGER_ROLE) {
        AcceptedToken memory newToken = AcceptedToken(_symbol, _decimals, _tokenAddress);
        acceptedTokens[_tokenAddress] = newToken;
        isAcceptedToken[_tokenAddress] = true;
    }

    function getDeal(address _hire, address _talent) external view returns (Interval, uint, uint) {
        Deal memory theDeal = deal[_hire][_talent];
        return (theDeal.interval, theDeal.duration, theDeal.salary);
    }

    function changeDealStatus(address _hire, address _talent) external returns(bool) {
        Deal memory theDeal = deal[_hire][_talent];
        theDeal.active = true;
        theDeal.paidWork = 0;
        return theDeal.active;
    }
}