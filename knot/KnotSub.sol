//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.4;

import "./Knot.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

abstract contract KnotSub is Initializable {

    IKnot public knotMain;

    function __KnotSub_init_unchained(IKnot knotMain_) internal onlyInitializing {
        require(address(knotMain_) != address(0), "address must be non-zero");
        knotMain = knotMain_;
    }

    error InvalidMainContractCaller();

    modifier onlyByMainContract() {
        if (msg.sender != address(knotMain)) revert InvalidMainContractCaller();
        _;
    }
}