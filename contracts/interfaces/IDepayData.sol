// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

interface IDepayData {

    function addTalent(string memory _name, string memory _occupation, uint8 _paidWork) external;
    
    function addDeal(address _talent, uint8 _duration, uint _pay, address _token, string memory _role) external;

    function acceptDeal(address _talent) external;

    function checkDealStatus(address _hire, address _talent) external returns (bool);

    function getDeal(address _hire, address _talent) external view returns (uint, uint, address);

    function changeDealStatus(address _hire, address _talent) external returns(bool);

}