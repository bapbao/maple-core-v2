// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.7;

import { Address } from "../../modules/contract-test-utils/contracts/test.sol";

import { SimulationBase } from "./SimulationBase.sol";

import { IMapleLoanLike } from "./Interfaces.sol";

contract LoanUpgradeTest is SimulationBase {

    struct Loan3Storage {
        address _borrower;
        address _lender;
        address _pendingBorrower;
        address _pendingLender;
        address _collateralAsset;
        address _fundsAsset;
        uint256 _gracePeriod;
        uint256 _paymentInterval;
        uint256 _interestRate;
        uint256 _earlyFeeRate;
        uint256 _lateFeeRate;
        uint256 _lateInterestPremium;
        uint256 _collateralRequired;
        uint256 _principalRequested;
        uint256 _endingPrincipal;
        uint256 _drawableFunds;
        uint256 _claimableFunds;
        uint256 _collateral;
        uint256 _nextPaymentDueDate;
        uint256 _paymentsRemaining;
        uint256 _principal;
        bytes32 _refinanceCommitment;
        uint256 _refinanceInterest;
        uint256 _delegateFee;
        uint256 _treasuryFee;
    }

    mapping(address => Loan3Storage) internal loan3Storage;

    function test_loanUpgrade() external {
        // Pre-Deployment Requirements
        setPoolAdminsToMigrationMultisig();  // LMP #1
        zeroInvestorFeeAndTreasuryFee();     // LMP #2
        payAndClaimAllUpcomingLoans();       // LMP #3

        snapshotLoanState300(mavenWethLoans);
        snapshotLoanState300(mavenUsdcLoans);
        snapshotLoanState300(mavenPermissionedLoans);
        snapshotLoanState300(orthogonalLoans);
        snapshotLoanState300(icebreakerLoans);

        upgradeAllLoansToV301();  // LMP #4

        assertAllLoans(mavenWethLoans,         301);
        assertAllLoans(mavenUsdcLoans,         301);
        assertAllLoans(mavenPermissionedLoans, 301);
        assertAllLoans(orthogonalLoans,        301);
        assertAllLoans(icebreakerLoans,        301);

        deployProtocol();  // LMP #5

        tempGovernorAcceptsV2Governorship();  // LMP #6

        migrationMultisigAcceptsMigrationAdministratorship();  // LMP #7

        setupExistingFactories();  // LMP #8

        upgradeAllDebtLockersToV400();  // LMP #9
        claimAllLoans();                // LMP #10
        upgradeAllLoansToV302();        // LMP #11
        lockAllPoolV1Deposits();        // LMP #12
        createAllMigrationLoans();      // LMP #13

        // Migration Loan Funding
        // NOTE: Technically, each loan is funded and their DebtLockers are upgraded per pool before moving onto the next
        fundAllMigrationLoans();               // LMP #14
        upgradeAllMigrationLoanDebtLockers();  // LMP #15

        upgradeAllMigrationLoansToV302();  // LMP #16

        pauseV1Protocol();  // LMP #17

        deployAllPoolV2s();  // LMP #18

        addLoansToAllLoanManagers();  // LMP #19

        // Prepare for Airdrops
        activateAllPoolManagers();  // LMP #20
        openOrAllowOnAllPoolV2s();  // LMP #21

        airdropTokensForAllPools();  // LMP #22
        assertAllPoolAccounting();

        // Transfer Loans
        // TODO: Do we really need all these repetitive assertions? Especially that we have validation script now.
        setAllPendingLenders();      // LMP #23
        assertAllPoolAccounting();
        takeAllOwnershipsOfLoans();  // LMP #24
        assertAllPoolAccounting();
        upgradeAllLoanManagers();    // LMP #25
        assertAllPrincipalOuts();
        assertAllTotalSupplies();
        assertAllPoolAccounting();
        setAllCoverParameters();
        assertAllPoolAccounting();
        upgradeAllLoansToV400();        // LMP #26

        // Close Migration Loans
        setGlobalsOfLoanFactoryToV2();  // LMP #27
        closeAllMigrationLoans();       // LMP #28

        assertAllLoans(mavenWethLoans,         400);
        assertAllLoans(mavenUsdcLoans,         400);
        assertAllLoans(mavenPermissionedLoans, 400);
        assertAllLoans(orthogonalLoans,        400);
        assertAllLoans(icebreakerLoans,        400);

        tempGovernorTransfersV2Governorship();  // LMP #39

        governorAcceptsV2Governorship();  // LMP #40

        deployLoan401();  // LMP #42

        setupLoanFactoryFor401();  // LMP #43

        upgradeAllLoansToV401();  // LMP #44

        assertAllLoans(mavenWethLoans,         401);
        assertAllLoans(mavenUsdcLoans,         401);
        assertAllLoans(mavenPermissionedLoans, 401);
        assertAllLoans(orthogonalLoans,        401);
        assertAllLoans(icebreakerLoans,        401);
    }

    function assertAllLoans(IMapleLoanLike[] memory loans, uint256 version) internal {
        for (uint256 i; i < loans.length; ++i) {
            if (version == 301)                   assertLoanState301(loans[i]);
            if (version == 401 || version == 400) assertLoanState401(loans[i]);
        }
    }

    function assertLoanState301(IMapleLoanLike loan) internal {
        Loan3Storage storage loanSnapshot = loan3Storage[address(loan)];

        assertEq(loan.borrower(),            loanSnapshot._borrower);
        assertEq(loan.lender(),              loanSnapshot._lender);
        assertEq(loan.pendingBorrower(),     loanSnapshot._pendingBorrower);
        assertEq(loan.pendingLender(),       loanSnapshot._pendingLender);
        assertEq(loan.collateralAsset(),     loanSnapshot._collateralAsset);
        assertEq(loan.fundsAsset(),          loanSnapshot._fundsAsset);
        assertEq(loan.gracePeriod(),         loanSnapshot._gracePeriod);
        assertEq(loan.paymentInterval(),     loanSnapshot._paymentInterval);
        assertEq(loan.interestRate(),        loanSnapshot._interestRate);
        assertEq(loan.earlyFeeRate(),        loanSnapshot._earlyFeeRate);
        assertEq(loan.lateFeeRate(),         loanSnapshot._lateFeeRate);
        assertEq(loan.lateInterestPremium(), loanSnapshot._lateInterestPremium);
        assertEq(loan.collateralRequired(),  loanSnapshot._collateralRequired);
        assertEq(loan.principalRequested(),  loanSnapshot._principalRequested);
        assertEq(loan.endingPrincipal(),     loanSnapshot._endingPrincipal);
        assertEq(loan.drawableFunds(),       loanSnapshot._drawableFunds);
        assertEq(loan.claimableFunds(),      loanSnapshot._claimableFunds);
        assertEq(loan.collateral(),          loanSnapshot._collateral);
        assertEq(loan.nextPaymentDueDate(),  loanSnapshot._nextPaymentDueDate);
        assertEq(loan.paymentsRemaining(),   loanSnapshot._paymentsRemaining);
        assertEq(loan.principal(),           loanSnapshot._principal);
        assertEq(loan.refinanceCommitment(), loanSnapshot._refinanceCommitment);
        assertEq(loan.delegateFee(),         loanSnapshot._delegateFee);
        assertEq(loan.treasuryFee(),         loanSnapshot._treasuryFee);
    }

    // The lender has changed in V4.01, and a few storage slots were deprecated.
    function assertLoanState401(IMapleLoanLike loan) internal {
        Loan3Storage storage loanSnapshot = loan3Storage[address(loan)];

        assertEq(loan.borrower(),            loanSnapshot._borrower);
        assertEq(loan.pendingBorrower(),     loanSnapshot._pendingBorrower);
        assertEq(loan.pendingLender(),       loanSnapshot._pendingLender);
        assertEq(loan.collateralAsset(),     loanSnapshot._collateralAsset);
        assertEq(loan.fundsAsset(),          loanSnapshot._fundsAsset);
        assertEq(loan.gracePeriod(),         loanSnapshot._gracePeriod);
        assertEq(loan.paymentInterval(),     loanSnapshot._paymentInterval);
        assertEq(loan.interestRate(),        loanSnapshot._interestRate);
        assertEq(loan.lateFeeRate(),         loanSnapshot._lateFeeRate);
        assertEq(loan.lateInterestPremium(), loanSnapshot._lateInterestPremium);
        assertEq(loan.collateralRequired(),  loanSnapshot._collateralRequired);
        assertEq(loan.principalRequested(),  loanSnapshot._principalRequested);
        assertEq(loan.endingPrincipal(),     loanSnapshot._endingPrincipal);
        assertEq(loan.drawableFunds(),       loanSnapshot._drawableFunds);
        assertEq(loan.collateral(),          loanSnapshot._collateral);
        assertEq(loan.nextPaymentDueDate(),  loanSnapshot._nextPaymentDueDate);
        assertEq(loan.paymentsRemaining(),   loanSnapshot._paymentsRemaining);
        assertEq(loan.principal(),           loanSnapshot._principal);
        assertEq(loan.refinanceCommitment(), loanSnapshot._refinanceCommitment);

        // V4 specific assertion
        assertEq(loan.feeManager(), address(feeManager));
    }

    function snapshotLoanState300(IMapleLoanLike[] storage loans) internal {
        for (uint256 i = 0; i < loans.length; i++) {
            IMapleLoanLike loan = loans[i];

            // Not possible to initialize at once due to stack limit.
            loan3Storage[address(loan)]._borrower            = loan.borrower();
            loan3Storage[address(loan)]._lender              = loan.lender();
            loan3Storage[address(loan)]._pendingBorrower     = loan.pendingBorrower();
            loan3Storage[address(loan)]._pendingLender       = loan.pendingLender();
            loan3Storage[address(loan)]._collateralAsset     = loan.collateralAsset();
            loan3Storage[address(loan)]._fundsAsset          = loan.fundsAsset();
            loan3Storage[address(loan)]._gracePeriod         = loan.gracePeriod();
            loan3Storage[address(loan)]._paymentInterval     = loan.paymentInterval();
            loan3Storage[address(loan)]._interestRate        = loan.interestRate();
            loan3Storage[address(loan)]._earlyFeeRate        = loan.earlyFeeRate();
            loan3Storage[address(loan)]._lateFeeRate         = loan.lateFeeRate();
            loan3Storage[address(loan)]._lateInterestPremium = loan.lateInterestPremium();
            loan3Storage[address(loan)]._collateralRequired  = loan.collateralRequired();
            loan3Storage[address(loan)]._principalRequested  = loan.principalRequested();
            loan3Storage[address(loan)]._endingPrincipal     = loan.endingPrincipal();
            loan3Storage[address(loan)]._drawableFunds       = loan.drawableFunds();
            loan3Storage[address(loan)]._claimableFunds      = loan.claimableFunds();
            loan3Storage[address(loan)]._collateral          = loan.collateral();
            loan3Storage[address(loan)]._nextPaymentDueDate  = loan.nextPaymentDueDate();
            loan3Storage[address(loan)]._paymentsRemaining   = loan.paymentsRemaining();
            loan3Storage[address(loan)]._principal           = loan.principal();
            loan3Storage[address(loan)]._refinanceCommitment = loan.refinanceCommitment();
            loan3Storage[address(loan)]._delegateFee         = loan.delegateFee();
            loan3Storage[address(loan)]._treasuryFee         = loan.treasuryFee();
        }
    }

}