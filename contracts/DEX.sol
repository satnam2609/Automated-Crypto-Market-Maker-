// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface IDEX {
    function tokenA_address(address token) external view returns (address);

    function tokenB_address(address token) external view returns (address);

    function getTradePrice(
        address from,
        address to,
        uint256 amount
    ) external view returns (uint256);

    function swap(address from, address to, uint256 amount) external;
}
