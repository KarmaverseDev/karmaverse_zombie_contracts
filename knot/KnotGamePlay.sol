//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "../common/access/GameAdmin.sol";
import "../common/base/ClaimTimer.sol";
import "./KnotSub.sol";
import "./KnotP2EPool.sol";
import "../common/base/TxIdempotent.sol";

abstract contract KnotGamePlay is GameAdmin, KnotSub, ClaimTimer, IKnotReceiver, TxIdempotent {

    using AddressUpgradeable for address;

    uint256 internal constant CLAIM_TIMEOUT = 10 minutes;
    uint256 internal constant CLAIM_COOLDOWN = 10 minutes;

    address public communityFundAccount;
    KnotP2EPool public p2ePool;

    event CommunityFuncAccountChanged(address oldAccount, address newAccount);
    event TokenProducedToStakePool(uint256 amount, uint64 txId, string reason);
    event TokenWithdrew(address account, uint256 amount, uint64 txId);
    event TokenDeposited(address account, uint256 amount);
    event RevenueClaimed(address account, uint256 amount, uint64 txId);

    error IllegalAmount();
    error ExceedTotalStake();
    error OpTimeout();
    error OpCoolingDown();
    error IllegalSignature();
    error InvalidFundAccount();

    function __KnotGamePlay_init(IKnot knotMain_, KnotP2EPool p2ePool_) internal onlyInitializing {
        __SuperAdmin_init_unchained();
        __KnotSub_init_unchained(knotMain_);
        __KnotGamePlay_init_unchained(p2ePool_);
        __GameAdmin_init_unchained();
    }

    function __KnotGamePlay_init_unchained(KnotP2EPool p2ePool_) internal onlyInitializing {
        p2ePool = p2ePool_;
    }

    function changeCommunityFundAccount(address newAccount) public onlySuperAdmin {
        emit CommunityFuncAccountChanged(communityFundAccount, newAccount);
        communityFundAccount = newAccount;
    }

    function produce(uint256 amount, uint64 timestamp, uint64 txId, string memory reason) public virtual onlyGameAdmin idempotent(txId) {
        if (amount <= 0) revert IllegalAmount();

        p2ePool.produce(amount, timestamp);
        _setClaimTs(address(0), timestamp);
        emit TokenProducedToStakePool(amount, txId, reason);
    }

    function withdraw(address account, uint256 amount, uint64 txId, uint64 timestamp, bytes memory signature) public virtual idempotent(txId) {
        if (amount <= 0) revert IllegalAmount();
        if (block.timestamp >= timestamp + CLAIM_TIMEOUT) revert OpTimeout();
        if (_getClaimTs(account) + CLAIM_COOLDOWN >= timestamp) revert OpCoolingDown();
        if (!_verifyWithdraw(account, amount, txId, timestamp, signature)) revert IllegalSignature();

        SafeERC20Upgradeable.safeTransfer(knotMain, account, amount);
        _setClaimTs(account, timestamp);
        emit TokenWithdrew(account, amount, txId);
    }

    function _verifyWithdraw(address account, uint256 amount, uint64 txId, uint64 timestamp, bytes memory signature) internal view returns (bool) {
        bytes32 hash = keccak256(abi.encode(account, amount, txId, timestamp));
        bytes32 signedHash = ECDSAUpgradeable.toEthSignedMessageHash(hash);
        return verify(signedHash, signature);
    }

    function deposit(address account, uint256 amount) public virtual {
        if (amount <= 0) revert IllegalAmount();

        SafeERC20Upgradeable.safeTransferFrom(knotMain, account, address(this), amount);
        emit TokenDeposited(account, amount);
    }

    function claimRevenue(uint256 amount, uint64 timestamp, uint64 txId) public virtual onlyGameAdmin idempotent(txId) {
        if (amount <= 0) revert IllegalAmount();
        if (communityFundAccount == address(0)) revert InvalidFundAccount();

        SafeERC20Upgradeable.safeTransfer(knotMain, communityFundAccount, amount);
        _setClaimTs(address(this), timestamp);
        emit RevenueClaimed(communityFundAccount, amount, txId);
    }

    function onKnotReceived (
        address from,
        address /*to*/,
        uint256 amount
    ) external virtual override onlyByMainContract {
        if (!from.isContract()) {
            emit TokenDeposited(from, amount);
        }
    }
}