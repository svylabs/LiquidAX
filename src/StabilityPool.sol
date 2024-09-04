// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract StabilityPool is ReentrancyGuard, Ownable {
    IERC20 public laxdToken;

    mapping(address => uint256) public deposits;
    uint256 public totalDeposits;
    uint256 public totalRewards;

    event Deposited(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event Borrowed(address indexed borrower, uint256 amount);
    event RewardAdded(uint256 amount);
    event RewardClaimed(address indexed user, uint256 amount);

    constructor(address _laxdToken) Ownable(msg.sender) {
        laxdToken = IERC20(_laxdToken);
    }

    function deposit(uint256 amount) external nonReentrant {
        require(amount > 0, "Deposit amount must be greater than 0");
        require(
            laxdToken.transferFrom(msg.sender, address(this), amount),
            "Transfer failed"
        );

        deposits[msg.sender] += amount;
        totalDeposits += amount;

        emit Deposited(msg.sender, amount);
    }

    function withdraw(uint256 amount) external nonReentrant {
        require(amount > 0, "Withdraw amount must be greater than 0");
        require(deposits[msg.sender] >= amount, "Insufficient balance");
        //claimReward();

        deposits[msg.sender] -= amount;
        totalDeposits -= amount;

        require(laxdToken.transfer(msg.sender, amount), "Transfer failed");

        emit Withdrawn(msg.sender, amount);
    }

    function borrow(
        address borrower,
        uint256 amount
    ) external onlyOwner nonReentrant {
        require(amount <= totalDeposits, "Insufficient funds in pool");
        require(laxdToken.transfer(borrower, amount), "Transfer failed");

        emit Borrowed(borrower, amount);
    }

    function addReward(uint256 amount) external nonReentrant {
        require(amount > 0, "Reward amount must be greater than 0");
        require(
            laxdToken.transferFrom(msg.sender, address(this), amount),
            "Transfer failed"
        );

        totalRewards += amount;

        emit RewardAdded(amount);
    }

    function claimReward() public nonReentrant {
        uint256 userDeposit = deposits[msg.sender];
        require(userDeposit > 0, "No deposits");

        uint256 reward = (userDeposit * totalRewards) / totalDeposits;
        require(reward > 0, "No rewards to claim");

        totalRewards -= reward;
        require(laxdToken.transfer(msg.sender, reward), "Transfer failed");

        emit RewardClaimed(msg.sender, reward);
    }

    function getUserShare(address user) public view returns (uint256) {
        if (totalDeposits == 0) return 0;
        return (deposits[user] * 1e18) / totalDeposits;
    }
}
