//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.4;

import "../../knot/KnotGamePlay.sol";


contract KZKnot is KnotGamePlay {

    function initialize(IKnot knotMain_, KnotP2EPool p2ePool_) external initializer {
        __KnotGamePlay_init(knotMain_, p2ePool_);
    }
}