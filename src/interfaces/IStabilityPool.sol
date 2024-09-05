// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface IStabilityPool {
    function canBorrow(
        address user,
        uint256 amount
    ) external view returns (bool);

    function borrow(address recipient, uint256 amount) external;

    function repay(address user, uint256 amount) external;
}
