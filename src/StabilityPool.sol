//SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract StabilityPool is ReentrancyGuard, Ownable {
    IERC20 public laxdToken;
    IERC20 public collateralToken;

    mapping(address => uint256) public deposits;
    uint256 public totalDeposits;

    uint256 public totalLaxdRewards;
    uint256 public totalEthRewards;
    uint256 public totalCollateralRewards;

    struct RewardSnapshot {
        uint256 laxdRewardPerShare;
        uint256 ethRewardPerShare;
        uint256 collateralRewardPerShare;
    }

    RewardSnapshot public globalRewardSnapshot;
    mapping(address => RewardSnapshot) public userRewardSnapshots;

    event Deposited(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event Borrowed(address indexed borrower, uint256 amount);
    event LaxdRewardAdded(uint256 amount);
    event EthRewardAdded(uint256 amount);
    event CollateralRewardAdded(uint256 amount);
    event RewardsClaimed(
        address indexed user,
        uint256 laxdAmount,
        uint256 ethAmount,
        uint256 collateralAmount
    );

    constructor(
        address _laxdToken,
        address _collateralToken
    ) Ownable(msg.sender) {
        laxdToken = IERC20(_laxdToken);
        collateralToken = IERC20(_collateralToken);
    }

    function deposit(uint256 amount) external nonReentrant {
        require(amount > 0, "Deposit amount must be greater than 0");
        require(
            laxdToken.transferFrom(msg.sender, address(this), amount),
            "Transfer failed"
        );

        deposits[msg.sender] += amount;
        totalDeposits += amount;

        updateRewardSnapshot(msg.sender);

        emit Deposited(msg.sender, amount);
    }

    function withdraw(uint256 amount) external nonReentrant {
        require(amount > 0, "Withdraw amount must be greater than 0");
        require(deposits[msg.sender] >= amount, "Insufficient balance");
        //claimReward();

        deposits[msg.sender] -= amount;
        totalDeposits -= amount;

        updateRewardSnapshot(msg.sender);

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

    function addLaxdReward(uint256 amount) external nonReentrant {
        require(amount > 0, "Reward amount must be greater than 0");
        require(
            laxdToken.transferFrom(msg.sender, address(this), amount),
            "Transfer failed"
        );
        totalLaxdRewards += amount;

        if (totalDeposits > 0) {
            globalRewardSnapshot.laxdRewardPerShare +=
                (amount * 1e18) /
                totalDeposits;
        }

        emit LaxdRewardAdded(amount);
    }

    function addEthReward() external payable nonReentrant {
        require(msg.value > 0, "Reward amount must be greater than 0");
        totalEthRewards += msg.value;

        if (totalDeposits > 0) {
            globalRewardSnapshot.ethRewardPerShare +=
                (msg.value * 1e18) /
                totalDeposits;
        }

        emit EthRewardAdded(msg.value);
    }

    function addCollateralReward(uint256 amount) external nonReentrant {
        require(amount > 0, "Reward amount must be greater than 0");
        require(
            collateralToken.transferFrom(msg.sender, address(this), amount),
            "Transfer failed"
        );
        totalCollateralRewards += amount;

        if (totalDeposits > 0) {
            globalRewardSnapshot.collateralRewardPerShare +=
                (amount * 1e18) /
                totalDeposits;
        }

        emit CollateralRewardAdded(amount);
    }

    function claimRewards() public nonReentrant {
        uint256 userDeposit = deposits[msg.sender];
        require(userDeposit > 0, "No deposits");

        uint256 laxdReward = calculateReward(
            userDeposit,
            globalRewardSnapshot.laxdRewardPerShare,
            userRewardSnapshots[msg.sender].laxdRewardPerShare
        );
        uint256 ethReward = calculateReward(
            userDeposit,
            globalRewardSnapshot.ethRewardPerShare,
            userRewardSnapshots[msg.sender].ethRewardPerShare
        );
        uint256 collateralReward = calculateReward(
            userDeposit,
            globalRewardSnapshot.collateralRewardPerShare,
            userRewardSnapshots[msg.sender].collateralRewardPerShare
        );

        require(
            laxdReward > 0 || ethReward > 0 || collateralReward > 0,
            "No rewards to claim"
        );

        if (laxdReward > 0) {
            totalLaxdRewards -= laxdReward;
            require(
                laxdToken.transfer(msg.sender, laxdReward),
                "LAXD transfer failed"
            );
        }

        if (ethReward > 0) {
            totalEthRewards -= ethReward;
            (bool success, ) = msg.sender.call{value: ethReward}("");
            require(success, "ETH transfer failed");
        }

        if (collateralReward > 0) {
            totalCollateralRewards -= collateralReward;
            require(
                collateralToken.transfer(msg.sender, collateralReward),
                "Collateral transfer failed"
            );
        }

        updateRewardSnapshot(msg.sender);

        emit RewardsClaimed(
            msg.sender,
            laxdReward,
            ethReward,
            collateralReward
        );
    }

    function updateRewardSnapshot(address user) internal {
        userRewardSnapshots[user] = globalRewardSnapshot;
    }

    function calculateReward(
        uint256 userDeposit,
        uint256 globalRewardPerShare,
        uint256 userRewardPerShare
    ) internal pure returns (uint256) {
        return
            (userDeposit * (globalRewardPerShare - userRewardPerShare)) / 1e18;
    }

    function getUserShare(address user) public view returns (uint256) {
        if (totalDeposits == 0) return 0;
        return (deposits[user] * 1e18) / totalDeposits;
    }

    receive() external payable {
        // Allow contract to receive ETH
    }
}
