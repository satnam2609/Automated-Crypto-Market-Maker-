// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "hardhat/console.sol";
import "./DEX.sol";

contract Pool is IDEX {
    using SafeMath for uint256;
    Token public tokenA;
    Token public tokenB;
    uint256 public totalShares;

    uint256 public reserveA;
    uint256 public reserveB;

    // X,Y=real tokens + virtual tokens and virtual tokens are the reserved tokens

    function priceForTokentoToken(
        uint256 token0,
        uint256 token1
    ) public pure returns (uint256) {
        return token0 / token1;
    }

    constructor(address _tokenA, address _tokenB) {
        tokenA = Token(_tokenA);
        tokenB = Token(_tokenB);
    }

    modifier checkForLiquidityAvailable(uint256 _dx, uint256 _dy) {
        require(_dy > 0 && _dx > 0, "Cannot add liquidity");
        uint256 X = tokenA.balanceOf(address(this));
        uint256 Y = tokenB.balanceOf(address(this));

        require(
            _dy == (Y * _dx) / X, // Y,X
            "Cannot add liquidity both the tokens are not satisfiying the equation"
        );
        _;
    }

    mapping(address => uint) public balanceOf;

    function _mint(address _to, uint256 _amount) private {
        balanceOf[_to] += _amount;
        totalShares += _amount;
    }

    function _burn(address _to, uint256 _amount) private {
        balanceOf[_to] -= _amount;
        totalShares -= _amount;
    }

    function _update(uint256 resA, uint256 resB) private {
        reserveA = resA;
        reserveB = resB;
    }

    // adding liquidity
    function addLiquidity(
        uint256 _dx,
        uint256 _dy
    ) external checkForLiquidityAvailable(_dx, _dy) returns (uint256 shares) {
        // transfering the tokens to the pool

        tokenA.transferFrom(msg.sender, address(this), _dx);
        tokenB.transferFrom(msg.sender, address(this), _dy);

        uint256 X = tokenA.balanceOf(address(this));
        uint256 Y = tokenB.balanceOf(address(this));

        if (totalShares > 0) {
            shares = priceForTokentoToken(_dx, X) * totalShares;
            _mint(msg.sender, shares);
        } else {
            shares = _dx + _dy;
        }

        require(shares > 0, "shares = 0");
        _mint(msg.sender, shares);

        _update(X, Y);

        console.log("Tokens dx and dy are added to the Pool");
    }

    // removing liquidity
    function removeLiquidity(
        uint256 _shares
    ) external returns (uint256, uint256) {
        require(_shares > 0);
        uint256 X = tokenA.balanceOf(address(this));
        uint256 Y = tokenB.balanceOf(address(this));

        uint256 _dx;
        _dx = priceForTokentoToken(X, totalShares) * _shares;

        uint256 _dy;
        _dy = priceForTokentoToken(Y, totalShares) * _shares;

        _burn(msg.sender, _shares);

        if (_dx > 0 && _dy > 0) {
            tokenA.transfer(msg.sender, _dx);
            tokenB.transfer(msg.sender, _dy);
        }
        _update(X, Y);
        return (_dx, _dy);
    }

    function tokenA_address(address token) external pure returns (address) {
        return token;
    }

    function tokenB_address(address token) external pure returns (address) {
        return token;
    }

    function getTradePrice(
        address from,
        address to,
        uint256 amount
    ) public view returns (uint256) {
        uint256 X = Token(from).balanceOf(address(this));
        uint256 Y = Token(to).balanceOf(address(this));

        return (priceForTokentoToken(Y * 1e18, X + amount) * amount) / 1e18;
    }

    function swap(address from, address to, uint256 amount) external {
        require(amount > 0, "amount =0");
        Token(from).transferFrom(msg.sender, address(this), amount);
        //  approve

        Token(to).transfer(msg.sender, getTradePrice(from, to, amount));
    }
}
