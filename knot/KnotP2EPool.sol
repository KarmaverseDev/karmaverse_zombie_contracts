//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "../common/access/SuperAdmin.sol";
import "./KnotSub.sol";


contract KnotP2EPool is KnotSub, SuperAdmin, IKnotReceiver {

    using AddressUpgradeable for address;

    uint256 internal constant BUDGET_TIME_UNIT = 30 days;
    uint256 internal constant PRODUCE_TIME_OUT = 10 minutes;

    struct BudgetData {
        uint256 amountPerMonth;
        uint256 cumulativeAmount;
        uint256 settleTs;
    }

    mapping(address => BudgetData) private _budgets;

    event GamePlayProduceBudgetChanged(address contractAddress, uint256 amountPerMonth, uint256 cumulativeAmount, uint256 startTs);

    error InvalidContractAddress();
    error InvalidTs();
    error InvalidCaller();
    error ExceedProduceLimit();

    function initialize(IKnot knotMain_) public initializer {
        __SuperAdmin_init_unchained();
        __KnotSub_init_unchained(knotMain_);
    }

    function applyGamePlayBudget(address contractAddress, uint256 amountPerMonth, uint256 cumulativeAmount, uint256 startTs) public virtual onlySuperAdmin {
        if (!contractAddress.isContract()) revert InvalidContractAddress();
        if (amountPerMonth > 0 && startTs < block.timestamp - BUDGET_TIME_UNIT) revert InvalidTs();

        _budgets[contractAddress] = BudgetData({
            amountPerMonth: amountPerMonth,
            cumulativeAmount: cumulativeAmount,
            settleTs: startTs
        });
        emit GamePlayProduceBudgetChanged(contractAddress, amountPerMonth, cumulativeAmount, startTs);
    }

    function produce(uint256 amount, uint64 timestamp) public virtual {
        if (timestamp > block.timestamp + PRODUCE_TIME_OUT || block.timestamp > timestamp + PRODUCE_TIME_OUT) revert InvalidTs();

        uint256 limit = _calcCumulativeAmount(msg.sender, timestamp);
        if (limit == 0) revert InvalidCaller();
        if (limit < amount) revert ExceedProduceLimit();
        SafeERC20Upgradeable.safeTransfer(knotMain, msg.sender, amount);
        _budgets[msg.sender].cumulativeAmount -= amount;
    }

    function _calcCumulativeAmount(address contractAddress, uint256 ts) internal returns (uint256) {
        BudgetData storage data =  _budgets[contractAddress];
        if (data.amountPerMonth == 0 && data.cumulativeAmount == 0) {
            return 0;
        }
        if (data.amountPerMonth > 0 && data.settleTs < ts) {
            data.cumulativeAmount += (ts - data.settleTs) * data.amountPerMonth / BUDGET_TIME_UNIT;
            data.settleTs = ts;
        }
        return data.cumulativeAmount;
    }

    function onKnotReceived (
        address from,
        address to,
        uint256 amount
    ) external virtual override onlyByMainContract {
    }
}