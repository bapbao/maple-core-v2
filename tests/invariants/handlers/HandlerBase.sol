// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.7;

import { IHandlerEntryPoint, IInvariantTest } from "../../../contracts/interfaces/Interfaces.sol";
import { console2 }                           from "../../../contracts/Contracts.sol";
import { ProtocolActions }                    from "../../../contracts/ProtocolActions.sol";

contract HandlerBase is ProtocolActions, IHandlerEntryPoint {

    uint256 constant internal WEIGHTS_RANGE = 100;

    uint256 public numCalls;
    uint256 public totalWeight;

    bytes4[] public selectors;

    mapping(bytes4 => uint256) public weights;

    mapping(bytes32 => uint256) public numberOfCalls;

    IInvariantTest testContract;

    /**************************************************************************************************************************************/
    /*** Modifiers                                                                                                                      ***/
    /**************************************************************************************************************************************/

    modifier useTimestamps {
        vm.warp(testContract.currentTimestamp());
        _;
        testContract.setCurrentTimestamp(block.timestamp);
    }

    /**************************************************************************************************************************************/
    /*** Weighting Setters                                                                                                              ***/
    /**************************************************************************************************************************************/

    function setSelectorWeight(string memory functionSignature_, uint256 weight_) external {
        bytes4 selector_ = bytes4(keccak256(bytes(functionSignature_)));

        weights[selector_] = weight_;

        selectors.push(selector_);

        totalWeight += weight_;
    }

    /**************************************************************************************************************************************/
    /*** Entry Point                                                                                                                    ***/
    /**************************************************************************************************************************************/

    function entryPoint(uint256 seed_) external override useTimestamps {
        require(totalWeight == WEIGHTS_RANGE, "HB:INVALID_WEIGHTS");

        numCalls++;

        uint256 range_;

        uint256 value_ = uint256(keccak256(abi.encodePacked(seed_))) % WEIGHTS_RANGE + 1;  // 1 - 100

        for (uint256 i = 0; i < selectors.length; i++) {
            uint256 weight_ = weights[selectors[i]];

            range_ += weight_;
            if (value_ <= range_ && weight_ != 0) {
                ( bool success, ) = address(this).call(abi.encodeWithSelector(selectors[i], seed_));

                // TODO: Parse error from low-level call and revert with it
                require(success, "HB:CALL_FAILED");
                break;
            }
        }
    }

}
