// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.7;

import { IFixedTermLoan, ILoanLike, ILoanManagerLike } from "../../contracts/interfaces/Interfaces.sol";

import { Address } from "../../contracts/Contracts.sol";

import { TestBaseWithAssertions } from "../TestBaseWithAssertions.sol";

contract FundTests is TestBaseWithAssertions {

    address borrower1;
    address borrower2;
    address loanManager;
    address loan1;
    address loan2;
    address lp;

    function setUp() public override {
        super.setUp();

        borrower1 = address(new Address());
        borrower2 = address(new Address());
        lp        = address(new Address());

        depositLiquidity(lp, 1_500_000e6);

        vm.prank(governor);
        globals.setValidBorrower(borrower1, true);

        setupFees({
            delegateOriginationFee:     500e6,
            delegateServiceFee:         300e6,
            delegateManagementFeeRate:  0.02e6,     // 150,000 * 0.02 = 3,000
            platformOriginationFeeRate: 0.001e6,    // 1,500,000 * 0.001   * 3,000,000 seconds / 365 days = 136.986301
            platformServiceFeeRate:     0.31536e6,  // 1,500,000 * 0.31536 * 1,000,000 seconds / 365 days = 15,000
            platformManagementFeeRate:  0.08e6      // 150,000 * 0.08 = 12,000
        });

        loanManager = poolManager.loanManagerList(0);

        loan1 = createLoan({
            borrower:    borrower1,
            termDetails: [uint256(5_000), uint256(1_000_000), uint256(3)],
            amounts:     [uint256(0), uint256(1_500_000e6), uint256(1_500_000e6)],
            rates:       [uint256(3.1536e18), uint256(0), uint256(0), uint256(0)],
            loanManager: loanManager
        });

        loan2 = createLoan({
            borrower:    borrower2,
            termDetails: [uint256(5_000), uint256(1_000_000), uint256(3)],
            amounts:     [uint256(0), uint256(750_000e6), uint256(750_000e6)],
            rates:       [uint256(6.3072e18), uint256(0), uint256(0), uint256(0)],
            loanManager: loanManager
        });
    }

    function test_fund_failIfProtocolIsPaused() external {
        vm.prank(globals.securityAdmin());
        globals.setProtocolPause(true);

        vm.prank(poolDelegate);
        vm.expectRevert("PM:PROTOCOL_PAUSED");
        poolManager.fund(uint256(1_500_000e6), loan1, loanManager);
    }

    function test_fund_failIfNotPoolDelegate() external {
        vm.expectRevert("PM:VAFL:NOT_PD");
        poolManager.fund(uint256(1_500_000e6), loan1, loanManager);
    }

    function test_fund_failIfInvalidLoanManager() external {
        vm.prank(poolDelegate);
        vm.expectRevert("PM:VAFL:INVALID_LOAN_MANAGER");
        poolManager.fund(uint256(1_500_000e6), loan1, address(1));
    }

    function test_fund_failIfInvalidBorrower() external {
        vm.prank(governor);
        globals.setValidBorrower(borrower1, false);

        vm.prank(poolDelegate);
        vm.expectRevert("PM:VAFL:INVALID_BORROWER");
        poolManager.fund(uint256(1_500_000e6), loan1, loanManager);
    }

    function test_fund_failIfTotalSupplyIsZero() external {
        // Burn the supply
        vm.startPrank(lp);
        pool.requestRedeem(1_500_000e6, lp);

        vm.warp(start + 2 weeks);

        pool.redeem(1_500_000e6, address(lp), address(lp));
        vm.stopPrank();

        vm.prank(poolDelegate);
        vm.expectRevert("PM:VAFL:ZERO_SUPPLY");
        poolManager.fund(uint256(1_500_000e6), loan1, loanManager);
    }

    function test_fund_failIfInsufficientCover() external {
        vm.prank(governor);
        globals.setMinCoverAmount(address(poolManager), 1e6);

        fundsAsset.mint(address(poolManager.poolDelegateCover()), 1e6 - 1);

        vm.prank(poolDelegate);
        vm.expectRevert("PM:VAFL:INSUFFICIENT_COVER");
        poolManager.fund(uint256(1_500_000e6), loan1, loanManager);
    }

    function test_fund_failIfPrincipalIsGreaterThanAssetBalance() external {
        vm.prank(poolDelegate);
        vm.expectRevert("PM:VAFL:TRANSFER_FAIL");
        poolManager.fund(uint256(1_500_000e6 + 1), loan1, loanManager);
    }

    function test_fund_failIfPoolDoesNotApprovePM() external {
        // It's impossible to happen with current contracts, but testing here for completeness
        vm.prank(address(pool));
        fundsAsset.approve(address(poolManager), 0);

        vm.prank(poolDelegate);
        vm.expectRevert("PM:VAFL:TRANSFER_FAIL");
        poolManager.fund(uint256(1_000_000e6), loan1, loanManager);
    }

    function test_fund_failIfAmountGreaterThanLockedLiquidity() external {
        address loan = createLoan({
            borrower:    borrower1,
            termDetails: [uint256(5_000), uint256(1_000_000), uint256(3)],
            amounts:     [uint256(0), uint256(1_000_000e6), uint256(1_000_000e6)],
            rates:       [uint256(3.1536e18), uint256(0), uint256(0), uint256(0)],
            loanManager: loanManager
        });

        // Lock the liquidity
        vm.prank(lp);
        pool.requestRedeem(500_000e6 + 1, lp);

        vm.warp(start + 2 weeks);

        vm.prank(poolDelegate);
        vm.expectRevert("PM:VAFL:LOCKED_LIQUIDITY");
        poolManager.fund(uint256(1_000_000e6), loan, loanManager);

        vm.prank(lp);
        pool.removeShares(1, lp);  // Remove so exactly 500k is locked.

        vm.warp(start + 4 weeks);

        vm.prank(poolDelegate);
        poolManager.fund(uint256(1_000_000e6), loan, loanManager);
    }

    function test_fund_failIfNotPoolManager() external {
        vm.expectRevert("LM:F:NOT_PM");
        ILoanManagerLike(loanManager).fund(loan1);
    }

    function test_fund_failIfLoanActive() external {
        depositLiquidity(lp, 1_500_000e6);  // Deposit again

        vm.prank(poolDelegate);
        poolManager.fund(uint256(1_500_000e6), loan1, loanManager);

        vm.prank(poolDelegate);
        vm.expectRevert("ML:FL:LOAN_ACTIVE");
        poolManager.fund(uint256(1_500_000e6), loan1, loanManager);
    }

    function test_fund_failWithExcessFunds() external {
        depositLiquidity(lp, 1);  // Deposit again

        vm.prank(poolDelegate);
        vm.expectRevert("ML:FL:UNEXPECTED_FUNDS");
        poolManager.fund(uint256(1_500_000e6 + 1), loan1, loanManager);
    }

    function test_fund_failWithLessFundsThanRequested() external {
        vm.prank(poolDelegate);
        vm.expectRevert(ARITHMETIC_ERROR);
        poolManager.fund(uint256(1_500_000e6 - 1), loan1, loanManager);
    }

    function test_fund_unaccountedFunds() external {
        ILoanManagerLike loanManager_ = ILoanManagerLike(loanManager);

        // Add unaccounted funds.
        fundsAsset.mint(loan1, 13_500e6);

        assertEq(loanManager_.accountedInterest(),          0);
        assertEq(loanManager_.domainEnd(),                  0);
        assertEq(loanManager_.domainStart(),                0);
        assertEq(loanManager_.issuanceRate(),               0);
        assertEq(loanManager_.paymentCounter(),             0);
        assertEq(loanManager_.paymentIdOf(loan1),           0);
        assertEq(loanManager_.paymentWithEarliestDueDate(), 0);
        assertEq(loanManager_.principalOut(),               0);

        {
            (
                uint256 platformManagementFeeRate,
                uint256 delegateManagementFeeRate,
                uint256 startDate,
                uint256 paymentDueDate,
                uint256 incomingNetInterest,
                uint256 refinanceInterest,
                uint256 issuanceRate
            ) = loanManager_.payments(1);

            assertEq(delegateManagementFeeRate, 0);
            assertEq(incomingNetInterest,       0);
            assertEq(issuanceRate,              0);
            assertEq(paymentDueDate,            0);
            assertEq(platformManagementFeeRate, 0);
            assertEq(refinanceInterest,         0);
            assertEq(startDate,                 0);
        }

        {
            ( uint256 previous, uint256 next, uint256 sortedPaymentDueDate ) = loanManager_.sortedPayments(1);

            assertEq(previous,             0);
            assertEq(next,                 0);
            assertEq(sortedPaymentDueDate, 0);
        }

        assertEq(feeManager.platformServiceFee(loan1), 0);

        assertEq(IFixedTermLoan(loan1).drawableFunds(),      0);
        assertEq(ILoanLike(loan1).lender(),                  loanManager);
        assertEq(IFixedTermLoan(loan1).nextPaymentDueDate(), 0);
        assertEq(ILoanLike(loan1).principal(),               0);

        assertEq(fundsAsset.balanceOf(loan1),                 13_500e6);
        assertEq(fundsAsset.balanceOf(address(pool)),         1_500_000e6);
        assertEq(fundsAsset.balanceOf(address(poolDelegate)), 0);
        assertEq(fundsAsset.balanceOf(address(treasury)),     0);

        assertEq(fundsAsset.allowance(loan1, address(feeManager)), 0);

        // Fund the loan1.
        vm.prank(poolDelegate);
        poolManager.fund(uint256(1_500_000e6), loan1, loanManager);

        assertEq(loanManager_.accountedInterest(),          0);
        assertEq(loanManager_.domainEnd(),                  start + 1_000_000);
        assertEq(loanManager_.domainStart(),                start);
        assertEq(loanManager_.issuanceRate(),               (150_000e6 - 3_000e6 - 12_000e6) * 1e30 / 1_000_000);
        assertEq(loanManager_.paymentCounter(),             1);
        assertEq(loanManager_.paymentIdOf(loan1),           1);
        assertEq(loanManager_.paymentWithEarliestDueDate(), 1);
        assertEq(loanManager_.principalOut(),               1_500_000e6);

        {
            (
                uint256 platformManagementFeeRate,
                uint256 delegateManagementFeeRate,
                uint256 startDate,
                uint256 paymentDueDate,
                uint256 incomingNetInterest,
                uint256 refinanceInterest,
                uint256 issuanceRate
            ) = loanManager_.payments(1);

            assertEq(delegateManagementFeeRate, 0.02e6);
            assertEq(incomingNetInterest,       150_000e6 - 3_000e6 - 12_000e6);
            assertEq(issuanceRate,              (150_000e6 - 3_000e6 - 12_000e6) * 1e30 / 1_000_000);
            assertEq(paymentDueDate,            start + 1_000_000);
            assertEq(platformManagementFeeRate, 0.08e6);
            assertEq(refinanceInterest,         0);
            assertEq(startDate,                 start);
        }

        {
            ( uint256 previous, uint256 next, uint256 sortedPaymentDueDate ) = loanManager_.sortedPayments(1);

            assertEq(previous,             0);
            assertEq(next,                 0);
            assertEq(sortedPaymentDueDate, start + 1_000_000);
        }

        assertEq(feeManager.platformServiceFee(loan1), 15_000e6);

        assertEq(IFixedTermLoan(loan1).drawableFunds(),      1_500_000e6 - 500e6 - 142.694063e6);
        assertEq(ILoanLike(loan1).lender(),                  loanManager);
        assertEq(IFixedTermLoan(loan1).nextPaymentDueDate(), start + 1_000_000);
        assertEq(ILoanLike(loan1).principal(),               1_500_000e6);

        assertEq(fundsAsset.balanceOf(loan1),                 1_500_000e6 - 500e6 - 142.694063e6);
        assertEq(fundsAsset.balanceOf(address(pool)),         13_500e6);  // Unaccounted amount is skimmed to the pool.
        assertEq(fundsAsset.balanceOf(address(poolDelegate)), 500e6);
        assertEq(fundsAsset.balanceOf(address(treasury)),     142.694063e6);

        assertEq(fundsAsset.allowance(loan1, address(feeManager)), type(uint256).max);
    }

    function test_fund_oneLoan() external {
        ILoanManagerLike loanManager_ = ILoanManagerLike(loanManager);

        assertEq(loanManager_.accountedInterest(),          0);
        assertEq(loanManager_.domainEnd(),                  0);
        assertEq(loanManager_.domainStart(),                0);
        assertEq(loanManager_.issuanceRate(),               0);
        assertEq(loanManager_.paymentCounter(),             0);
        assertEq(loanManager_.paymentIdOf(loan1),           0);
        assertEq(loanManager_.paymentWithEarliestDueDate(), 0);
        assertEq(loanManager_.principalOut(),               0);

        {
            (
                uint256 platformManagementFeeRate,
                uint256 delegateManagementFeeRate,
                uint256 startDate,
                uint256 paymentDueDate,
                uint256 incomingNetInterest,
                uint256 refinanceInterest,
                uint256 issuanceRate
            ) = loanManager_.payments(1);

            assertEq(delegateManagementFeeRate, 0);
            assertEq(incomingNetInterest,       0);
            assertEq(issuanceRate,              0);
            assertEq(paymentDueDate,            0);
            assertEq(platformManagementFeeRate, 0);
            assertEq(refinanceInterest,         0);
            assertEq(startDate,                 0);
        }

        {
            ( uint256 previous, uint256 next, uint256 sortedPaymentDueDate ) = loanManager_.sortedPayments(1);

            assertEq(previous,             0);
            assertEq(next,                 0);
            assertEq(sortedPaymentDueDate, 0);
        }

        assertEq(feeManager.platformServiceFee(loan1), 0);

        assertEq(IFixedTermLoan(loan1).drawableFunds(),      0);
        assertEq(ILoanLike(loan1).lender(),                  loanManager);
        assertEq(IFixedTermLoan(loan1).nextPaymentDueDate(), 0);
        assertEq(ILoanLike(loan1).principal(),               0);

        assertEq(fundsAsset.balanceOf(loan1),                 0);
        assertEq(fundsAsset.balanceOf(address(pool)),         1_500_000e6);
        assertEq(fundsAsset.balanceOf(address(poolDelegate)), 0);
        assertEq(fundsAsset.balanceOf(address(treasury)),     0);

        assertEq(fundsAsset.allowance(loan1, address(feeManager)), 0);

        // Fund the loan1.
        vm.prank(poolDelegate);
        poolManager.fund(uint256(1_500_000e6), loan1, loanManager);

        assertEq(loanManager_.accountedInterest(),          0);
        assertEq(loanManager_.domainEnd(),                  start + 1_000_000);
        assertEq(loanManager_.domainStart(),                start);
        assertEq(loanManager_.issuanceRate(),               (150_000e6 - 3_000e6 - 12_000e6) * 1e30 / 1_000_000);
        assertEq(loanManager_.paymentCounter(),             1);
        assertEq(loanManager_.paymentIdOf(loan1),           1);
        assertEq(loanManager_.paymentWithEarliestDueDate(), 1);
        assertEq(loanManager_.principalOut(),               1_500_000e6);

        {
            (
                uint256 platformManagementFeeRate,
                uint256 delegateManagementFeeRate,
                uint256 startDate,
                uint256 paymentDueDate,
                uint256 incomingNetInterest,
                uint256 refinanceInterest,
                uint256 issuanceRate
            ) = loanManager_.payments(1);

            assertEq(delegateManagementFeeRate, 0.02e6);
            assertEq(incomingNetInterest,       150_000e6 - 3_000e6 - 12_000e6);
            assertEq(issuanceRate,              (150_000e6 - 3_000e6 - 12_000e6) * 1e30 / 1_000_000);
            assertEq(paymentDueDate,            start + 1_000_000);
            assertEq(platformManagementFeeRate, 0.08e6);
            assertEq(refinanceInterest,         0);
            assertEq(startDate,                 start);
        }

        {
            ( uint256 previous, uint256 next, uint256 sortedPaymentDueDate ) = loanManager_.sortedPayments(1);

            assertEq(previous,             0);
            assertEq(next,                 0);
            assertEq(sortedPaymentDueDate, start + 1_000_000);
        }

        assertEq(feeManager.platformServiceFee(loan1), 15_000e6);

        assertEq(IFixedTermLoan(loan1).drawableFunds(),      1_500_000e6 - 500e6 - 142.694063e6);
        assertEq(ILoanLike(loan1).lender(),                  loanManager);
        assertEq(IFixedTermLoan(loan1).nextPaymentDueDate(), start + 1_000_000);
        assertEq(ILoanLike(loan1).principal(),               1_500_000e6);

        assertEq(fundsAsset.balanceOf(loan1),                 1_500_000e6 - 500e6 - 142.694063e6);
        assertEq(fundsAsset.balanceOf(address(pool)),         0);
        assertEq(fundsAsset.balanceOf(address(poolDelegate)), 500e6);
        assertEq(fundsAsset.balanceOf(address(treasury)),     142.694063e6);

        assertEq(fundsAsset.allowance(loan1, address(feeManager)), type(uint256).max);
    }

    function test_fund_twoLoans() external {
        ILoanManagerLike loanManager_ = ILoanManagerLike(loanManager);

        // Fund the first loan1.
        vm.prank(poolDelegate);
        poolManager.fund(uint256(1_500_000e6), loan1, loanManager);

        assertEq(loanManager_.paymentIdOf(loan1),           1);
        assertEq(loanManager_.accountedInterest(),          0);
        assertEq(loanManager_.domainEnd(),                  start + 1_000_000);
        assertEq(loanManager_.domainStart(),                start);
        assertEq(loanManager_.issuanceRate(),               (150_000e6 - 3_000e6 - 12_000e6) * 1e30 / 1_000_000);
        assertEq(loanManager_.paymentCounter(),             1);
        assertEq(loanManager_.paymentWithEarliestDueDate(), 1);
        assertEq(loanManager_.principalOut(),               1_500_000e6);

        {
            (
                uint256 platformManagementFeeRate,
                uint256 delegateManagementFeeRate,
                uint256 startDate,
                uint256 paymentDueDate,
                uint256 incomingNetInterest,
                uint256 refinanceInterest,
                uint256 issuanceRate
            ) = loanManager_.payments(1);

            assertEq(delegateManagementFeeRate, 0.02e6);
            assertEq(incomingNetInterest,       150_000e6 - 3_000e6 - 12_000e6);
            assertEq(issuanceRate,              (150_000e6 - 3_000e6 - 12_000e6) * 1e30 / 1_000_000);
            assertEq(paymentDueDate,            start + 1_000_000);
            assertEq(platformManagementFeeRate, 0.08e6);
            assertEq(refinanceInterest,         0);
            assertEq(startDate,                 start);
        }

        {
            ( uint256 previous, uint256 next, uint256 sortedPaymentDueDate ) = loanManager_.sortedPayments(1);

            assertEq(previous,             0);
            assertEq(next,                 0);
            assertEq(sortedPaymentDueDate, start + 1_000_000);
        }

        assertEq(feeManager.platformServiceFee(loan1), 15_000e6);

        assertEq(IFixedTermLoan(loan1).drawableFunds(),      1_500_000e6 - 500e6 - 142.694063e6);
        assertEq(ILoanLike(loan1).lender(),                  loanManager);
        assertEq(IFixedTermLoan(loan1).nextPaymentDueDate(), start + 1_000_000);
        assertEq(ILoanLike(loan1).principal(),               1_500_000e6);

        assertEq(fundsAsset.balanceOf(loan1),                 1_500_000e6 - 500e6 - 142.694063e6);
        assertEq(fundsAsset.balanceOf(address(pool)),         0);
        assertEq(fundsAsset.balanceOf(address(poolDelegate)), 500e6);
        assertEq(fundsAsset.balanceOf(address(treasury)),     142.694063e6);

        assertEq(fundsAsset.allowance(loan1, address(feeManager)), type(uint256).max);

        // Mint the extra funds needed to fund the second loan1.
        fundsAsset.mint(address(pool), 750_000e6);

        // Fund the second loan1 after some time passes.
        vm.warp(start + 1_000);
        vm.prank(poolDelegate);
        poolManager.fund(uint256(750_000e6), loan2, loanManager);

        assertEq(loanManager_.paymentIdOf(loan1), 1);
        assertEq(loanManager_.paymentIdOf(loan2), 2);

        assertEq(loanManager_.accountedInterest(),          135e6);
        assertEq(loanManager_.domainEnd(),                  start + 1_000_000);
        assertEq(loanManager_.domainStart(),                start + 1_000);
        assertEq(loanManager_.issuanceRate(),               2 * (150_000e6 - 3000e6 - 12_000e6) * 1e30 / 1_000_000);
        assertEq(loanManager_.paymentCounter(),             2);
        assertEq(loanManager_.paymentWithEarliestDueDate(), 1);
        assertEq(loanManager_.principalOut(),               2_250_000e6);

        {
            (
                uint256 platformManagementFeeRate,
                uint256 delegateManagementFeeRate,
                uint256 startDate,
                uint256 paymentDueDate,
                uint256 incomingNetInterest,
                uint256 refinanceInterest,
                uint256 issuanceRate
            ) = loanManager_.payments(1);

            assertEq(delegateManagementFeeRate, 0.02e6);
            assertEq(incomingNetInterest,       150_000e6 - 3_000e6 - 12_000e6);
            assertEq(issuanceRate,              (150_000e6 - 3_000e6 - 12_000e6) * 1e30 / 1_000_000);
            assertEq(paymentDueDate,            start + 1_000_000);
            assertEq(platformManagementFeeRate, 0.08e6);
            assertEq(refinanceInterest,         0);
            assertEq(startDate,                 start);
        }

        {
            (
                uint256 platformManagementFeeRate,
                uint256 delegateManagementFeeRate,
                uint256 startDate,
                uint256 paymentDueDate,
                uint256 incomingNetInterest,
                uint256 refinanceInterest,
                uint256 issuanceRate
            ) = loanManager_.payments(2);

            assertEq(delegateManagementFeeRate, 0.02e6);
            assertEq(incomingNetInterest,       150_000e6 - 3_000e6 - 12_000e6);
            assertEq(issuanceRate,              (150_000e6 - 3_000e6 - 12_000e6) * 1e30 / 1_000_000);
            assertEq(paymentDueDate,            start + 1_000 + 1_000_000);
            assertEq(platformManagementFeeRate, 0.08e6);
            assertEq(refinanceInterest,         0);
            assertEq(startDate,                 start + 1_000);
        }

        {
            ( uint256 previous, uint256 next, uint256 sortedPaymentDueDate ) = loanManager_.sortedPayments(1);

            assertEq(previous,             0);
            assertEq(next,                 2);
            assertEq(sortedPaymentDueDate, start + 1_000_000);
        }

        {
            ( uint256 previous, uint256 next, uint256 sortedPaymentDueDate ) = loanManager_.sortedPayments(2);

            assertEq(previous,             1);
            assertEq(next,                 0);
            assertEq(sortedPaymentDueDate, start + 1_000 + 1_000_000);
        }

        assertEq(feeManager.platformServiceFee(loan1), 15_000e6);
        assertEq(feeManager.platformServiceFee(loan2), 7_500e6);

        assertEq(IFixedTermLoan(loan1).drawableFunds(),      1_500_000e6 - 500e6 - 142.694063e6);
        assertEq(ILoanLike(loan1).lender(),                  loanManager);
        assertEq(IFixedTermLoan(loan1).nextPaymentDueDate(), start + 1_000_000);
        assertEq(ILoanLike(loan1).principal(),               1_500_000e6);

        assertEq(IFixedTermLoan(loan2).drawableFunds(),      750_000e6 - 500e6 - 71.347031e6);
        assertEq(ILoanLike(loan2).lender(),                  loanManager);
        assertEq(IFixedTermLoan(loan2).nextPaymentDueDate(), start + 1_000 + 1_000_000);
        assertEq(ILoanLike(loan2).principal(),               750_000e6);

        assertEq(fundsAsset.balanceOf(loan1),                 1_500_000e6 - 500e6 - 142.694063e6);
        assertEq(fundsAsset.balanceOf(loan2),                 750_000e6   - 500e6 - 71.347031e6);
        assertEq(fundsAsset.balanceOf(address(pool)),         0);
        assertEq(fundsAsset.balanceOf(address(poolDelegate)), 500e6 + 500e6);
        assertEq(fundsAsset.balanceOf(address(treasury)),     142.694063e6 + 71.347031e6);

        assertEq(fundsAsset.allowance(loan1, address(feeManager)), type(uint256).max);
        assertEq(fundsAsset.allowance(loan2, address(feeManager)), type(uint256).max);
    }

}
