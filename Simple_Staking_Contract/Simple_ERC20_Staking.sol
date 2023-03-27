pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract StakingContract is Ownable {
    IERC20 public token;
    uint256 public rewardRate = 1; 
    uint256 public totalStakedBalance;
    mapping(address => uint256) public stakedBalance;
    mapping(address => uint256) public lastClaimedTime;

    constructor(IERC20 _token) {
        token = _token;
    }

    function stake(uint256 amount) public {
        require(amount > 0, "Amount must be greater than zero");
        require(token.balanceOf(address(msg.sender)) >= amount, "check amount or allowance");
        token.transferFrom(msg.sender, address(this), amount);
        stakedBalance[msg.sender] += amount;
        totalStakedBalance += amount;
        if (lastClaimedTime[msg.sender] == 0) {
            lastClaimedTime[msg.sender] = block.timestamp;
        }
    }

    function unstake(uint256 amount) external {
        require(amount > 0, "Amount must be greater than zero");
        require(stakedBalance[msg.sender] >= amount, "Insufficient staked balance");
        uint256 reward = calculateReward(msg.sender);
        if (reward > 0) {
            token.transfer(msg.sender, reward);
        }
        stakedBalance[msg.sender] -= amount;
        totalStakedBalance -= amount;
        token.transfer(msg.sender, amount);
        if (stakedBalance[msg.sender] == 0) {
            lastClaimedTime[msg.sender] = 0;
        }
    }

    function claimReward() external {
        uint256 reward = calculateReward(msg.sender);
        require(reward > 0, "No reward to claim");
        require(reward <= token.balanceOf(address(this)));
        totalStakedBalance -= reward;
        token.transfer(msg.sender, reward);
        lastClaimedTime[msg.sender] = block.timestamp;
    }

    function calculateReward(address staker) public view returns (uint256) {
        uint256 timeSinceLastClaim = block.timestamp - lastClaimedTime[staker];
        uint256 stakedAmount = stakedBalance[staker];
        uint256 reward = stakedAmount * rewardRate * timeSinceLastClaim / (1 days * 100 * 10 ** 18);
        return reward;
    }
    function updatetokenaddr(address _newTokenAddr) public onlyOwner {
        token = IERC20(_newTokenAddr);
    }
     function setrewardRate(uint256 percent) public onlyOwner{
        require(percent <= 100 * 10 ** 18, "Reward percentage cannot be more than 100.");
        rewardRate = percent;
    }
     function withdrawTokens(address to, uint256 amount) public onlyOwner {
        require(amount <= token.balanceOf(address(this)), "Insufficient balance");
        totalStakedBalance -= amount;
        token.transfer(to, amount);
    }
    function updateTotalStakedBalance() public {
        uint256 contractBalance = token.balanceOf(address(this));
        uint256 unaccountedTokens = contractBalance - totalStakedBalance;
        totalStakedBalance += unaccountedTokens;
    }
}
