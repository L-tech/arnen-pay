// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

// Import this file to use console.log
import "hardhat/console.sol";
import "./interfaces/Token.sol";
import "./interfaces/IDepayData.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";


contract Depay is AccessControl {
    IDepayData public depayData;
    enum Interval {
        DAILY,
        WEEKLY,
        MONTHLY
    }

    mapping(address => address) stakeToken;

    struct Pay {
        uint256 staked;
        address token;
        uint256 balance;
    }
    mapping(address => mapping(address => Pay)) stakePay;
    event HireStaked(address indexed _hire, address indexed _talent, address token, uint256 amount);
    event MyLog(string, uint256);

    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    constructor(address _depayData)  {
        depayData = IDepayData(_depayData);
        _setupRole(ADMIN_ROLE, msg.sender);
    }

    function stake(uint256 _amount, address _erc20Contract, address _cErc20Contract) external returns(uint256){
        Erc20 underlying = Erc20(_erc20Contract);

        // Create a reference to the corresponding cToken contract, like cDAI
        CErc20 cToken = CErc20(_cErc20Contract);

        // Amount of current exchange rate from cToken to underlying
        uint256 exchangeRateMantissa = cToken.exchangeRateCurrent();
        emit MyLog("Exchange Rate (scaled up): ", exchangeRateMantissa);

        // Amount added to you supply balance this block
        uint256 supplyRateMantissa = cToken.supplyRatePerBlock();
        emit MyLog("Supply Rate: (scaled up)", supplyRateMantissa);

        // Approve transfer on the ERC20 contract
        underlying.approve(_cErc20Contract, _amount);

        // Mint cTokens
        uint mintResult = cToken.mint(_amount);
        return mintResult;

    }

    function commenceDeal(address _talent) external {
        require(depayData.checkDealStatus(msg.sender, _talent), "Deal Not Accepted");
        (uint _pay, uint _duration, address _tokenAddress) = depayData.getDeal(msg.sender, _talent);
        Erc20 underlying = Erc20(_tokenAddress);
        uint256 funds = _pay * _duration;
        require(
            underlying.allowance(msg.sender, address(this)) >= funds,
            "Depay: Insufficient allowance"
        );
        underlying.transferFrom(msg.sender, address(this), funds);
        uint256 staked = this.stakeFund(funds, _tokenAddress, stakeToken[_tokenAddress]);
        stakePay[msg.sender][_talent] = Pay(staked, _tokenAddress, staked);
        bool dealStatus = depayData.changeDealStatus(msg.sender, _talent);
        assert(dealStatus);
        emit HireStaked(msg.sender, _talent, _tokenAddress, staked);

    }



    function stakeFund(uint256 _amount, address _erc20Contract, address _cErc20Contract) external returns(uint256){
        Erc20 underlying = Erc20(_erc20Contract);

        // Create a reference to the corresponding cToken contract, like cDAI
        CErc20 cToken = CErc20(_cErc20Contract);

        // Amount of current exchange rate from cToken to underlying
        uint256 exchangeRateMantissa = cToken.exchangeRateCurrent();
        emit MyLog("Exchange Rate (scaled up): ", exchangeRateMantissa);

        // Amount added to you supply balance this block
        uint256 supplyRateMantissa = cToken.supplyRatePerBlock();
        emit MyLog("Supply Rate: (scaled up)", supplyRateMantissa);

        // Approve transfer on the ERC20 contract
        underlying.approve(_cErc20Contract, _amount);

        // Mint cTokens
        uint mintResult = cToken.mint(_amount);
        return mintResult;

    }

    function redeemCErc20Tokens(
        uint256 amount,
        bool redeemType,
        address _cErc20Contract
    ) public returns (bool) {
        // Create a reference to the corresponding cToken contract, like cDAI
        CErc20 cToken = CErc20(_cErc20Contract);

        // `amount` is scaled up, see decimal table here:
        // https://compound.finance/docs#protocol-math

        uint256 redeemResult;

        if (redeemType == true) {
            // Retrieve your asset based on a cToken amount
            redeemResult = cToken.redeem(amount);
        } else {
            // Retrieve your asset based on an amount of the asset
            redeemResult = cToken.redeemUnderlying(amount);
        }

        // Error codes are listed here:
        // https://compound.finance/docs/ctokens#error-codes
        emit MyLog("If this is not 0, there was an error", redeemResult);

        return true;
    }

    function addCompound(address _tokenAddress, address _compoundAddress) public onlyRole(ADMIN_ROLE) returns(bool) {
        stakeToken[_tokenAddress] = _compoundAddress;
        return true;
    }

    receive() external payable {}
    
}
