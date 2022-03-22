//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.4;

import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "../common/access/SuperAdmin.sol";
import "../common/access/WhiteList.sol";
import "./KnotSub.sol";

contract KnotAllocate is SuperAdmin, WhiteList, KnotSub {

    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");
    uint32 public constant ALLOC_PART_NUM = 10;
    uint32 public constant ALLOC_MONTH_NUM = 60;
    uint32 public constant MAX_ALLOC_ACCOUNT_NUM_OF_PART = 100;
    uint32 public constant MAX_ALLOC_ACCOUNT_STOCK = 1000000;

    enum AllocPart { PlayToEarn, StakingRewards, PublicSale, SeedRound, PrivateSale, Community, Team, Advisors, EcosystemFund, Liquidity }

    struct AllocRule {
        uint256 tgeAmount;
        uint256[ALLOC_MONTH_NUM] monthReleaseAmount;
    }

    struct AllocObjective {
        address[] accounts;
        uint256[] stocks;
        uint256 totalStock;
    }

    mapping(AllocPart => AllocRule) public rules;
    mapping(AllocPart => AllocObjective) public objectives;
    uint256 public tgeTimestamp;
    uint256 public monthReleaseTimestamp;
    uint32 public releasedMonthNum;

    event AllocSetUp();
    event TGE();
    event MonthRelease();

    error TGEDone();
    error MonthReleaseDone();
    error ReleaseTimeNotReady();
    error InvalidSetUpParam();
    error DuplicateSetUp();
    error SetUpNotReady();
    error InvalidTGETime();

    function initialize(IKnot knotMain_) external initializer {
        __SuperAdmin_init_unchained();
        __KnotSub_init_unchained(knotMain_);
        __KnotAllocate_init_unchained();
    }

    function __KnotAllocate_init_unchained() internal onlyInitializing {
        _initAllocRule(AllocPart.PlayToEarn, 0, [
            uint256(420000), 420000, 420000, 420000, 420000, 420000, 420000, 420000, 420000, 2100000, 2100000, 2100000,
            2100000, 2100000, 2100000, 2100000, 2100000, 2100000, 2100000, 2100000, 2100000, 1260000, 1260000, 1260000,
            1260000, 1260000, 1260000, 1260000, 1260000, 1260000, 1260000, 1260000, 1260000, 840000, 840000, 840000,
            840000, 840000, 840000, 840000, 840000, 840000, 840000, 840000, 840000, 525000, 525000, 525000,
            525000, 420000, 420000, 420000, 420000, 420000, 420000, 420000, 420000, 420000, 420000, 420000
            ]);
        _initAllocRule(AllocPart.StakingRewards, 0, [
            uint256(352800), 352800, 352800, 1764000, 1764000, 1764000, 1764000, 1764000, 1764000, 1587600, 1587600, 1587600,
            1587600, 1587600, 1587600, 1455300, 1455300, 1455300, 1455300, 1455300, 1455300, 1190700, 1190700, 1190700,
            1190700, 1190700, 1190700, 970200, 970200, 970200, 970200, 970200, 970200, 793800, 793800, 793800,
            793800, 793800, 793800, 485100, 485100, 485100, 485100, 485100, 485100, 396900, 396900, 396900,
            396900, 396900, 396900, 0, 0, 0, 0, 0, 0, 0, 0, 0
            ]);
        _initAllocRule(AllocPart.PublicSale, 1155000, [
            uint256(1155000), 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
            ]);
        _initAllocRule(AllocPart.SeedRound, 819000, [
            uint256(0), 0, 0, 0, 0, 0, 1296750, 1296750, 1296750, 1296750, 1296750, 1296750,
            1296750, 1296750, 1296750, 1296750, 1296750, 1296750, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
            ]);
        _initAllocRule(AllocPart.PrivateSale, 1228500, [
            uint256(0), 0, 0, 1945125, 1945125, 1945125, 1945125, 1945125, 1945125, 1945125, 1945125, 1945125,
            1945125, 1945125, 1945125, 0, 0, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
            ]);
        _initAllocRule(AllocPart.Community, 0, [
            uint256(420000), 420000, 420000, 420000, 315000, 315000, 315000, 315000, 315000, 315000, 315000, 315000,
            210000, 210000, 210000, 210000, 210000, 210000, 210000, 210000, 210000, 210000, 210000, 210000,
            105000, 105000, 105000, 105000, 105000, 105000, 105000, 105000, 105000, 105000, 105000, 105000,
            0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
            ]);
        _initAllocRule(AllocPart.Team, 0, [
            uint256(0), 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
            1750000, 1750000, 1750000, 1750000, 1750000, 1750000, 1750000, 1750000, 1750000, 1750000, 1750000, 1750000,
            0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
            ]);
        _initAllocRule(AllocPart.Advisors, 315000, [
            uint256(0), 0, 332500, 332500, 332500, 332500, 332500, 332500, 332500, 332500, 332500, 332500,
            332500, 332500, 332500, 332500, 332500, 332500, 332500, 332500, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
            ]);
        _initAllocRule(AllocPart.EcosystemFund, 1071000, [
            uint256(337167), 337166, 337167, 337167, 337166, 337167, 337167, 337166, 337167, 337167, 337166, 337167,
            337167, 337166, 337167, 337167, 337166, 337167, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
            ]);
        _initAllocRule(AllocPart.Liquidity, 1050000, [
            uint256(1050000), 1050000, 1050000, 1050000, 1050000, 1050000, 1050000, 1050000, 1050000, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
            ]);
    }

    function _initAllocRule(AllocPart part, uint256 tgeAmount, uint256[ALLOC_MONTH_NUM] memory monthReleaseAmount) internal onlyInitializing {
        rules[part] = AllocRule({tgeAmount: tgeAmount, monthReleaseAmount: monthReleaseAmount});
    }

    function getAllocRule(AllocPart part) external view returns (uint256, uint256[ALLOC_MONTH_NUM] memory) {
        AllocRule storage rule = rules[part];
        return (rule.tgeAmount, rule.monthReleaseAmount);
    }

    function getAllocObjective(AllocPart part) external view returns (address[] memory, uint256[] memory, uint256) {
        AllocObjective storage objective = objectives[part];
        return (objective.accounts, objective.stocks, objective.totalStock);
    }

    function setUpAllocObjective(AllocPart part, address[] calldata accounts, uint256[] calldata stocks) external onlySuperAdmin {
        if (_isTgeDone()) revert TGEDone();
        if (accounts.length != stocks.length) revert InvalidSetUpParam();
        if (accounts.length == 0 || accounts.length > MAX_ALLOC_ACCOUNT_NUM_OF_PART) revert InvalidSetUpParam();
        if (objectives[part].accounts.length > 0) revert DuplicateSetUp();

        uint256 totalStock = 0;
        for (uint32 i = 0; i < accounts.length; i++) {
            if (stocks[i] <= 0 || stocks[i] > MAX_ALLOC_ACCOUNT_STOCK) revert InvalidSetUpParam();
            totalStock += stocks[i];
        }

        objectives[part] = AllocObjective({accounts: accounts, stocks: stocks, totalStock: totalStock});
        emit AllocSetUp();
    }

    function isSetUpReady() public view returns (bool) {
        for (uint i = 0; i < ALLOC_PART_NUM; i++) {
            if (objectives[AllocPart(i)].accounts.length == 0) return false;
        }
        return true;
    }

    function tge(uint256 tgeTimestamp_) external onlySuperAdmin {
        if (_isTgeDone()) revert TGEDone();
        if (!isSetUpReady()) revert SetUpNotReady();
        if (tgeTimestamp_ == 0) revert InvalidTGETime();

        for (uint i = 0; i < ALLOC_PART_NUM; i++) {
            AllocPart part = AllocPart(i);
            uint256 amount = rules[part].tgeAmount;
            _releaseToObjective(part, amount);
        }
        tgeTimestamp = tgeTimestamp_;
        monthReleaseTimestamp = tgeTimestamp + _releasePeriod();

        emit TGE();
    }

    function _isTgeDone() internal view returns (bool) {
        return tgeTimestamp > 0;
    }

    function _releasePeriod() internal view returns (uint256) {
        if (releasedMonthNum % 12 == 11) {
            return 35 days;
        } else {
            return 30 days;
        }
    }

    function updateOperatorRole(address account) external onlySuperAdmin {
        _updateRole(OPERATOR_ROLE, account);
    }

    function monthRelease() external whiteList(OPERATOR_ROLE) {
        if (!_isTgeDone()) revert ReleaseTimeNotReady();
        if (block.timestamp < monthReleaseTimestamp) revert ReleaseTimeNotReady();
        if (releasedMonthNum >= ALLOC_MONTH_NUM) revert MonthReleaseDone();

        for (uint i = 0; i < ALLOC_PART_NUM; i++) {
            AllocPart part = AllocPart(i);
            uint256 amount = rules[part].monthReleaseAmount[releasedMonthNum];
            _releaseToObjective(part, amount);
        }
        monthReleaseTimestamp += _releasePeriod();
        releasedMonthNum++;

        emit MonthRelease();
    }

    function _releaseToObjective(AllocPart part, uint256 totalAmount) internal {
        if (totalAmount == 0) return;
        AllocObjective storage obj = objectives[part];
        uint256 num = obj.accounts.length;
        for (uint32 i = 0; i < num; i++) {
            uint256 amount = 1e18 * totalAmount * obj.stocks[i] / obj.totalStock;
            SafeERC20Upgradeable.safeTransfer(knotMain, obj.accounts[i], amount);
        }
    }
}