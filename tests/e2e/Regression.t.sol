// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.7;

import { TestBaseWithAssertions } from "../../contracts/utilities/TestBaseWithAssertions.sol";

import { Address, console } from "../../modules/contract-test-utils/contracts/test.sol";

import { Refinancer }        from "../../modules/loan-v401/contracts/Refinancer.sol";
import { MapleLoan as Loan } from "../../modules/loan-v401/contracts/MapleLoan.sol";

import { BaseInvariants }                           from "../invariants/BaseInvariants.t.sol";
import { LoanHandlerWithImpairment } from "../invariants/actors/LoanHandlerWithImpairment.sol";
import { LpHandler }                                from "../invariants/actors/LpHandler.sol";

contract RegressionTest is BaseInvariants {

    uint256 constant public NUM_BORROWERS = 5;
    uint256 constant public NUM_LPS       = 10;
    uint256 constant public MAX_NUM_LOANS = 50;

    LoanHandlerWithImpairment loanHandlerWithImpairment;

    function setUp() public override {
        super.setUp();

        currentTimestamp = block.timestamp;

        setupFees({
            delegateOriginationFee:     500e6,  // TODO: Remove as not used
            delegateServiceFee:         300e6,  // TODO: Remove as not used
            delegateManagementFeeRate:  0.02e6,
            platformOriginationFeeRate: 0.001e6,
            platformServiceFeeRate:     0.005e6,  // 10k after 1m seconds
            platformManagementFeeRate:  0.08e6
        });

        loanHandlerWithImpairment = new LoanHandlerWithImpairment({
            collateralAsset_: address(collateralAsset),
            feeManager_:      address(feeManager),
            fundsAsset_:      address(fundsAsset),
            globals_:         address(globals),
            governor_:        governor,
            loanFactory_:     loanFactory,
            poolManager_:     address(poolManager),
            testContract_:    address(this),
            numBorrowers_:    NUM_BORROWERS,
            maxLoans_:        MAX_NUM_LOANS
        });

        lpHandler = new LpHandler(address(pool), address(this), NUM_LPS);

    }

    function test_regression_invariantUnderflow_1() external {
        // Call sequence from Invariant failure
        lpHandler.mint(115792089237316195423570985008687907853269984665640564039457584007913129639932, 2);
        loanHandlerWithImpairment.impairLoan(44350351663014801330081);
        lpHandler.requestRedeem(397033724884604987223658894746, 6507598289383296464921439);
        loanHandlerWithImpairment.createLoanAndFund(114796939126572464485669432463848173248608720792236492753059967819167245740652, [uint256(106907381517790884880754690905), 2349278223969267532769107923, 640260884040502728162154478835097111543629976135387], [uint256(785537843850272561316681354178), 46630547469820653808839429456, 6619188922239243199420517207], [uint256(543512311206629033446932892234), 8847567179, 146140300526861301476772940662, 3644914473], [uint256(17929445818943082332735174), 1010502134406903469363153124845]);
        loanHandlerWithImpairment.impairLoan(115792089237316195423570985008687907853269984665640564039457584007913129639932);
        loanHandlerWithImpairment.makePayment(75851697028000881919958643764, 413238542605307835987129885330);
        lpHandler.transfer(101522286204020, 1406799742659732262559566395877, 157860500191220028281410144271);
        loanHandlerWithImpairment.createLoanAndFund(8401699694758306166653255626255935736101, [0, 115792089237316195423570985008687907853269984665640564039457584007913129639935, 1], [115792089237316195423570985008687907853269984665640564039457584007913129639932, 115792089237316195423570985008687907853269984665640564039457584007913129639932, 115792089237316195423570985008687907853269984665640564039457584007913129639933], [66224125536546043854264473798591027590597146, 0, 1, 115792089237316195423570985008687907853269984665640564039457584007913129639935], [uint256(244472613489577), 27]);
        lpHandler.transfer(6691986, 770652846330056877154171392421, 2642565738627942491066117723);
        lpHandler.redeem(801956298525841076504167206429, 559778913040469462420269575404);
        loanHandlerWithImpairment.createLoanAndFund(1616936573489501314788725176, [1426583892562177740896706784061819031185270371534, 75123127377546475004515100404757465150498283020140544356401496015277451063157, 10409847734573492600588489031], [uint256(18614), 306968548690421679171432204225, 287847789275927479339299340710], [uint256(12384652803191552714120351268), 81469846573946462217443268057, 160985925644006886282423007177, 74528947924075142970262211758], [uint256(384519959837479436951743569748), 1273298547451317291572698717349]);
        loanHandlerWithImpairment.impairLoan(1005105495959509108520132480928);
        loanHandlerWithImpairment.createLoanAndFund(3078851091351306631025252178023937503094418893714472455783587368, [115792089237316195423570985008687907853269984665640564039457584007913129639934, 115792089237316195423570985008687907853269984665640564039457584007913129639932, 37470383297173158269311465048562582574146287266770473882774584], [uint256(3), 27137747056578965031106417544857149570927707359, 2121896], [15087539978231971997469108481822816171264733010343234119931716740851, 0, 115792089237316195423570985008687907853269984665640564039457584007913129639934, 53075600036485587846636], [115792089237316195423570985008687907853269984665640564039457584007913129639933, 24818499538512579947190404110636926196293867]);
        loanHandlerWithImpairment.impairLoan(2);
        loanHandlerWithImpairment.warp(38230389647743939495244325858905447309147223230622238983375993497123197918336);
        lpHandler.deposit(60472578317871498138980335157, 30608509082820004819302880341);
        lpHandler.mint(115792089237316195423570985008687907853269984665640564039457584007913129639933, 3);
        loanHandlerWithImpairment.impairLoan(10396018190718698675883155684);
        lpHandler.mint(1312310263258426918020350935948244410934178351589179290084759123105293191086, 20879356919057808771226889809326150633184843464752023369069);
        lpHandler.mint(115792089237316195423570985008687907853269984665640564039457584007913129639935, 115792089237316195423570985008687907853269984665640564039457584007913129639935);
        loanHandlerWithImpairment.impairLoan(763435360601035026748909735004334569728838918957571330132245425851315113);
        loanHandlerWithImpairment.impairLoan(0);
        loanHandlerWithImpairment.warp(264520782934852711004161109391);
        lpHandler.transfer(115792089237316195423570985008687907853269984665640564039457584007913129639934, 1, 115792089237316195423570985008687907853269984665640564039457584007913129639935);
        lpHandler.mint(0, 0);
        lpHandler.transfer(0, 0, 0);
        loanHandlerWithImpairment.createLoanAndFund(3201258693855430109322278499069099483410482522251631909434912979231980337, [115792089237316195423570985008687907853269984665640564039457584007913129639935, 2, 11119437186627302269542335164011202973696706792986950147327192944577555455628], [75560293597358723689248735902386325496025215419059693779346812052617142, 50626669882430801443810771473712233310477096667727127105991506212935, 115792089237316195423570985008687907853269984665640564039457584007913129639932], [4090842471, 57732611698, 1212014757167175835646212778855113, 115792089237316195423570985008687907853269984665640564039457584007913129639934], [9393837659778366403130741252202526045708337, 115792089237316195423570985008687907853269984665640564039457584007913129639932]);
        loanHandlerWithImpairment.makePayment(2, 0);
        loanHandlerWithImpairment.warp(1557825080171877650201218222749);
        loanHandlerWithImpairment.createLoanAndFund(788592980324803080751255351140, [uint256(28134015396116571027250105), 97850179565457559011930271133, 1113486003762598216082904519], [uint256(336786157425117845501880146651), 506739823344146914956252635695418881286715103369101, 627010024452506538216978768683], [uint256(1611323228910564887461018648), 668059610415072165964683749066, 464497679135098940082235618429, 12189897980170934158766169], [uint256(508917316068556479399763905687685117595384984403244523373617604), 5161782274077736604314202533538158]);
        loanHandlerWithImpairment.impairLoan(4002118946038890892442752730697480903907904188935791738581151146733639664673);
        lpHandler.requestRedeem(1244733120523767964540156319984354925254217630574713562, 1021);
        lpHandler.requestRedeem(52062757973702150888997066765, 1880948440793063069841194253);
        lpHandler.transfer(0, 287480662, 114893317515056911963118225676);
        lpHandler.transfer(453090904671981049585174892398, 1778151024016158662369726920388264771781698238855204170475354, 1365057401027503964254452883357);
        lpHandler.removeShares(305145567, 389916450018548770961817517);
        loanHandlerWithImpairment.warp(424735860549742279189702447486069367);
        loanHandlerWithImpairment.warp(1);
        loanHandlerWithImpairment.createLoanAndFund(39715497062526812955446983375365149964368962365979435337702127050175164337533, [uint256(660463361211145834626675618185), 1913066884651983527011775809, 43628874986724479358036289267593548183891987517188362244978840174607], [uint256(21403733298735987145886620241), 14303046159769395381932, 589840824607043786861518174323], [uint256(264797360571991983775069784649), 1481766516, 1200216556866036506887449079444, 205426420718391987701697242224], [uint256(787778062241400479289956550), 391699183545274408452281082999]);
        lpHandler.removeShares(15573715860040936000439, 2);
        loanHandlerWithImpairment.warp(115792089237316195423570985008687907853269984665640564039457584007913129639932);
        lpHandler.transfer(1181469158600395853667832859, 113506073960462886799830623156515562873419723020245133871356187445333788015197, 165696425670485307126876209);
        lpHandler.deposit(1172886258762695558424956821928, 65844049007684249298844961503963021575099462606924819885672276700140488684176);
        loanHandlerWithImpairment.warp(115792089237316195423570985008687907853269984665640564039457584007913129639933);
        loanHandlerWithImpairment.impairLoan(193806711104);
        loanHandlerWithImpairment.impairLoan(4906195103158551126666561575);
        lpHandler.mint(28227851, 56020533713132815315);
        lpHandler.mint(623164679258853562191706936523, 5368462128642067058116891939425511478380543830019745);
        lpHandler.transfer(32376791915107311, 2, 115792089237316195423570985008687907853269984665640564039457584007913129639935);
        lpHandler.removeShares(115792089237316195423570985008687907853269984665640564039457584007913129639935, 3735942818781804275196814781648037421624177928936583043830415654101305);
        loanHandlerWithImpairment.warp(6360589863266553022220795709);
        lpHandler.redeem(50362594992404224659247000418, 100009953944915);
        loanHandlerWithImpairment.createLoanAndFund(65049353376588800041895846039880725895065656577440390396272591927778111111038, [uint256(486047086533972246082505983), 4733834772743390966619575213, 4581848171215498944215088223297965843531271776837304332], [uint256(565422351562284440031357319945), 165675193499335214749540834076, 483250944604236571738831412677], [uint256(375129413480216946799086651249), 131791003964600062377497980235916771328, 9220856832, 1154544869362910424771916186896], [uint256(217346999725153912548040338791), 260492094358060539101739854868]);
        lpHandler.deposit(204126060533652724500508477932743, 115792089237316195423570985008687907853269984665640564039457584007913129639932);
        loanHandlerWithImpairment.impairLoan(115792089237316195423570985008687907853269984665640564039457584007913129639932);
        lpHandler.requestRedeem(0, 3);
        loanHandlerWithImpairment.warp(2);
        loanHandlerWithImpairment.impairLoan(33112808169);

        assertEq(loanManager.unrealizedLosses(),      139450885821902738470407880330);
        assertEq(loanManager.assetsUnderManagement(), 139450885821902738470407880329);

        assertEq(loanManager.unrealizedLosses() - loanManager.assetsUnderManagement(), 1);  // UL > AUM due to rounding

        // Assert that although the original invariant failed, the protocol still works. The values will be constrained in the handler contracts.
        lpHandler.deposit(1000, 1000);
        lpHandler.mint(1000, 1000);
        lpHandler.transfer(1000, 1000, 1000);
        lpHandler.requestRedeem(1000, 1000);
        lpHandler.redeem(100000, 10000);

        loanHandlerWithImpairment.createLoanAndFund(1000, [uint256(1000), 1000, 1000], [uint256(1000), 1000, 1000], [uint256(1000), 1000, 1000, 1000], [uint256(1000), 1000]);
        loanHandlerWithImpairment.warp(1000);
        loanHandlerWithImpairment.impairLoan(1000);
    }

    function test_regression_underflow2() external {
        lpHandler.mint(121838261951089380215547565303729234958, 115792089237316195423570985008687907853269984665640564039457584007913129639935);
        loanHandlerWithImpairment.createLoanAndFund(896776239666333492431586679157, [4557798137397015975907906, 16542156070856104877473802, 6454832996886620737873970694037360158899904474920970105017937911343088582753], [uint256(1667414772), 3434058491145964023503656966, 100002759582545], [uint256(48866884150231999654595849481), 139792119181071602200323479497, 415129636892161998806559967910, 1656584743134208794389126861], [uint256(68327923734417779661693573203), 509761881123912834613275]);
        loanHandlerWithImpairment.makePayment(483626557707884274122798, 65805031878336944615044480024992957857293824463886179101583484089525436474940);
        loanHandlerWithImpairment.makePayment(848, 115792089237316195423570985008687907853269984665640564039457584007913129639934);
        loanHandlerWithImpairment.makePayment(1111, 474338258119626896441359);
        loanHandlerWithImpairment.makePayment(426772335029754455320848189591, 13221438902330927429603117846);
        loanHandlerWithImpairment.makePayment(17430926492810124255667041264946103296832205200642653, 267347193274796);
        loanHandlerWithImpairment.makePayment(316026304788606201183582063716226831225606165017843, 115792089237316195423570985008687907853269984665640564039457584007913129639933);
        loanHandlerWithImpairment.createLoanAndFund(3, [uint256(541220796261473347811267), 29901528888589310214148616759055262568964590297662927217832440, 3], [115792089237316195423570985008687907853269984665640564039457584007913129639933, 115792089237316195423570985008687907853269984665640564039457584007913129639933, 822583268045672114894046729658589545022868998644272253480], [115792089237316195423570985008687907853269984665640564039457584007913129639934, 2, 20457458496082445500133896731672913651509439402733551039208295196511712068934, 3], [uint256(32325), 2]);
        loanHandlerWithImpairment.createLoanAndFund(72943621497990131634298404377, [25694479508388077690274118050, 1736828794743523193450770285, 12725644067334519070040997637695595976766274030791034012598638153413753085393], [uint256(61695887020382181049510959416), 808133762822708602831688696975, 14230], [uint256(461216776285003288936521), 5981621652570900753613480569, 371237394156497555006582277471, 179652938817026041483727651853620424347523301292185], [uint256(601336444214399314373446157242), 2585387828467545761950496394]);
        loanHandlerWithImpairment.makePayment(1421938304070402358908639594, 565973829683412785824358904669);
        loanHandlerWithImpairment.createLoanAndFund(1738315138071257402962925932, [uint256(413241060428249615442146225573), 15224214476295252281677546821, 46520643], [uint256(1656769910696788454632793175), 19533117, 2431396686212869193065657880], [uint256(205052484980644097483406137486), 204970664959681830894678376682, 830236923878623119205480695517, 242788103001397206935667200909247452787754433732], [34170977247686416822467088051880290695680822575989497396828503448155158868316, 27378466299536656276735562]);
        loanHandlerWithImpairment.createLoanAndFund(3, [uint256(2), 141424047949857230174315389584867, 3], [uint256(641242095932693211275001410498197147289571133552794), 3, 91481084366644038899988354493851717760022412626783301495308569], [2, 0, 0, 115792089237316195423570985008687907853269984665640564039457584007913129639932], [115792089237316195423570985008687907853269984665640564039457584007913129639932, 115792089237316195423570985008687907853269984665640564039457584007913129639935]);
        loanHandlerWithImpairment.makePayment(92524436346921752630298954195, 72364562514567063401492553328245147363616522575244447997730);
        loanHandlerWithImpairment.makePayment(13604846026965250860146222, 0);
        lpHandler.deposit(20295370167418815534695844421768922213469054236944172355, 1119135088831215387354594343839907001917275);
        loanHandlerWithImpairment.createLoanAndFund(16828772737812715011724510133989, [uint256(306237411167863383746114847045551655821173), 0, 311479431759230255429156815958013682383993134806314671596670059592886], [1, 115792089237316195423570985008687907853269984665640564039457584007913129639935, 1905072922423050977], [uint256(1), 6562548586428702585020114165080855972271300788397584566394759814055, 3, 3], [66887870113236313931822545351931011569955847415128602145, 115792089237316195423570985008687907853269984665640564039457584007913129639934]);
        loanHandlerWithImpairment.createLoanAndFund(5857147262372755521516422665261234045635086257594348, [467783336498, 115792089237316195423570985008687907853269984665640564039457584007913129639934, 115792089237316195423570985008687907853269984665640564039457584007913129639933], [29652764965982585220573, 115792089237316195423570985008687907853269984665640564039457584007913129639935, 3], [uint256(1561192221934505882405654232035882512891), 1968824077451323276769609355883486402853569472295402705700237307, 3459856965792973544923678750660977084886062, 2], [uint256(212659573247540668940101601164141562), 2]);
        loanHandlerWithImpairment.makePayment(129942033201381223467186855815082409984, 209695452810815543590503693768);
        lpHandler.mint(58502164484065680351715057338, 501762700218849577076948074298);
        loanHandlerWithImpairment.makePayment(0, 7406444051055);
        loanHandlerWithImpairment.createLoanAndFund(17301945842897, [1302682092321495272129095, 115792089237316195423570985008687907853269984665640564039457584007913129639933, 3], [80919068825168760790734780407381286460947601577708092214606373953053993173960, 3, 3], [uint256(24924894465466298478578508423453448181152590399693), 77204935837022097904950501125006591, 22324021323567884867482368967837484534117444040391254271498532084424297, 0], [15431466049519042058978381364085886309057753626008781257065965119631667996, 115792089237316195423570985008687907853269984665640564039457584007913129639935]);
        lpHandler.deposit(222048586891060505425831839615, 10217087);
        loanHandlerWithImpairment.createLoanAndFund(23215713781434580815318658, [uint256(481972535191811241745424), 306416113652730532925263227214, 370860412986979442423391335768], [uint256(1831919314805890171564940823), 99543267561419508398351584475, 313763698171330705070588732673], [uint256(164491332160908561), 186316413753600533895609938978, 2626224697523962362091311280, 269594893014173952201603337], [uint256(88541465254282896339595928952), 331849893736933401408421283356]);
        loanHandlerWithImpairment.createLoanAndFund(3, [115792089237316195423570985008687907853269984665640564039457584007913129639932, 115792089237316195423570985008687907853269984665640564039457584007913129639933, 25843185456779417484974616797552114438708620711754471265305], [115792089237316195423570985008687907853269984665640564039457584007913129639935, 115792089237316195423570985008687907853269984665640564039457584007913129639934, 115792089237316195423570985008687907853269984665640564039457584007913129639932], [2875563459333993215, 223960552842907171657650271247814634925484127246498805050434942921987518, 3, 115792089237316195423570985008687907853269984665640564039457584007913129639935], [797578469001925837121132689250582660873132980053392708847914312406085333079, 9496475886926583005112088182921018185450560945322584129029761166320009]);
        loanHandlerWithImpairment.createLoanAndFund(115792089237316195423570985008687907853269984665640564039457584007913129639932, [uint256(1), 5466579298623795287229691519545761721053170649569285933046, 412856567291333466889744375726369357791294312521321], [uint256(1), 55844226953854, 7126883783754175], [uint256(22076417314153649354904358810419620159475113399266361199242305), 2422943200250814378435207350382, 2, 5893554655151720582215984854657000383920175486237880568], [115792089237316195423570985008687907853269984665640564039457584007913129639934, 115792089237316195423570985008687907853269984665640564039457584007913129639935]);
        loanHandlerWithImpairment.makePayment(989519892877098063113648278037, 27838084188683458132924051274);
        lpHandler.mint(650422613940759198852385698440, 466);
        loanHandlerWithImpairment.createLoanAndFund(2489917141458929705670015166725346385080682302437890, [uint256(3425281766), 3, 0], [uint256(664772838318730216471119109877110363901204206497960), 3939026052627053309845728191437947777870228069704, 3], [5396215173444437273124347272477588342711969537477083843085, 115792089237316195423570985008687907853269984665640564039457584007913129639932, 0, 115792089237316195423570985008687907853269984665640564039457584007913129639933], [uint256(27414), 3]);
        loanHandlerWithImpairment.makePayment(115792089237316195423570985008687907853269984665640564039457584007913129639935, 155825352346852663993097960853824700);

        for (uint256 i; i < loanHandlerWithImpairment.numLoans(); ++i) {
            address loan = loanHandlerWithImpairment.activeLoans(i);

            assert_loan_invariant_A(loan);
            assert_loan_invariant_B(loan);
            assert_loan_invariant_C(loan);

            ( , , uint256 startDate, uint256 paymentDueDate, , uint256 refinanceInterest , ) = loanManager.payments(loanManager.paymentIdOf(loan));

            assert_loanManager_invariant_L(loan, refinanceInterest);
            assert_loanManager_invariant_M(loan, paymentDueDate);
            assert_loanManager_invariant_N(loan, startDate);
        }
    }

    function test_regression_underflow3() external {
        loanHandlerWithImpairment.makePayment(743646812859835848430768922517295040013969662, 115792089237316195423570985008687907853269984665640564039457584007913129639935);
		lpHandler.transfer(1131, 11288, 19169);
		loanHandlerWithImpairment.createLoanAndFund(2, [uint256(3), 9425050422020609474106964271301115788250, 115792089237316195423570985008687907853269984665640564039457584007913129639932], [uint256(6897646334545256553680), 115792089237316195423570985008687907853269984665640564039457584007913129639933, 115792089237316195423570985008687907853269984665640564039457584007913129639933], [uint256(0), 197476233015507978841968418441388684146, 115792089237316195423570985008687907853269984665640564039457584007913129639934, 115792089237316195423570985008687907853269984665640564039457584007913129639932], [uint256(4464827924835), 0]);
		loanHandlerWithImpairment.makePayment(390300937, 2);
		lpHandler.requestRedeem(129094228743638370577674743858866923024742868425531245394962097629244052764, 4615033898065362502355438);
		lpHandler.redeem(4177, 65180);
		lpHandler.deposit(115792089237316195423570985008687907853269984665640564039457584007913129639935, 9436618517611669069677594670805433241924321307);
		loanHandlerWithImpairment.createLoanAndFund(13510274079423568736810645, [uint256(115792089237316195423570985008687907853269984665640564039457584007913129639933), 342793910838282865179729558388758921679767080072038208494, 1486087295129268318886290588024414042534625664201336404013025657043326143], [uint256(526099300604025271720384813449249919197182), 115792089237316195423570985008687907853269984665640564039457584007913129639932, 3], [uint256(2), 50141977628729621528642888035897190326442945115614784303365, 28837638635033499341898, 17629746641309972010635900553554635923131763], [uint256(29907665864306377116429978128782650009373), 115792089237316195423570985008687907853269984665640564039457584007913129639934]);
		lpHandler.redeem(5454, 101600);
		loanHandlerWithImpairment.makePayment(19874, 6932);
		loanHandlerWithImpairment.warp(115792089237316195423570985008687907853269984665640564039457584007913129639932);
		loanHandlerWithImpairment.warp(806354819669886131126267883238970879003039517948390570148671238208);
		lpHandler.redeem(115792089237316195423570985008687907853269984665640564039457584007913129639934, 10247512081416866110);
		loanHandlerWithImpairment.makePayment(2897552052, 14358);
		lpHandler.mint(1, 96733610);
		lpHandler.deposit(1, 2);
		loanHandlerWithImpairment.createLoanAndFund(1862, [uint256(5249), 6241, 39234382498221177315049533437815633639825897596738470885587685301422298582511], [uint256(22425), 116043824989765189472178496499843289689, 5303], [uint256(6473), 7152, 20993, 3317], [uint256(36321580509521243975229404103069517533313258004404530098070081419104730742784), 22753]);
		loanHandlerWithImpairment.warp(3677);
		loanHandlerWithImpairment.warp(115792089237316195423570985008687907853269984665640564039457584007913129639932);
		loanHandlerWithImpairment.makePayment(2882821332906775788286463366154594802630757110, 115792089237316195423570985008687907853269984665640564039457584007913129639934);
		lpHandler.redeem(0, 84470331310);
		loanHandlerWithImpairment.warp(16673);
		lpHandler.requestRedeem(2, 0);
		lpHandler.redeem(517661843983663681880736, 39467031452071981429731168901736328838636305103963448373304740);
		lpHandler.redeem(9574, 34620);
		loanHandlerWithImpairment.createLoanAndFund(1330264679821902443563971064431517023814097042107914420550140361697, [uint256(115792089237316195423570985008687907853269984665640564039457584007913129639934), 993666903432274494204839022078344740438721501533941592777059696335736, 115792089237316195423570985008687907853269984665640564039457584007913129639934], [uint256(1), 115792089237316195423570985008687907853269984665640564039457584007913129639932, 2], [uint256(4548438944970640545396914421820060512069408760906316895087388501225), 2, 2097048, 115792089237316195423570985008687907853269984665640564039457584007913129639935], [uint256(115792089237316195423570985008687907853269984665640564039457584007913129639932), 8892511859138737911970468726879165]);
		loanHandlerWithImpairment.createLoanAndFund(115792089237316195423570985008687907853269984665640564039457584007913129639934, [uint256(1), 68276106102490, 2], [uint256(2028299078842337902687372599707956687712836216587047741584213337794070), 0, 1], [uint256(115792089237316195423570985008687907853269984665640564039457584007913129639933), 115792089237316195423570985008687907853269984665640564039457584007913129639934, 115792089237316195423570985008687907853269984665640564039457584007913129639932, 66721553775517768949765655895606430712661218554806700879946850894863014480], [uint256(3), 115792089237316195423570985008687907853269984665640564039457584007913129639934]);
		lpHandler.removeShares(1007759639082287987841, 1);
		loanHandlerWithImpairment.createLoanAndFund(115792089237316195423570985008687907853269984665640564039457584007913129639935, [uint256(1454210939745055477471566830130013549181180809156725697372), 1, 1], [uint256(0), 2, 3], [uint256(1), 115792089237316195423570985008687907853269984665640564039457584007913129639934, 65033927031397325522443130852210005382839067577337784596497, 5609913963901587351320755745716022772369], [uint256(115792089237316195423570985008687907853269984665640564039457584007913129639934), 2481370682866478358746294271907390146]);
		lpHandler.requestRedeem(766163937715552760914806183663483027137670994984536833840018837654, 2);
		loanHandlerWithImpairment.warp(3);
		loanHandlerWithImpairment.makePayment(1074000717, 200625764329100582753334285633529769);
		loanHandlerWithImpairment.warp(365021384006522884661030760204825436);
		loanHandlerWithImpairment.createLoanAndFund(115792089237316195423570985008687907853269984665640564039457584007913129639935, [uint256(115792089237316195423570985008687907853269984665640564039457584007913129639934), 1, 115792089237316195423570985008687907853269984665640564039457584007913129639935], [uint256(3), 978597795567350355607418586702211, 12997071406797500869968453779723951008875677011633879], [uint256(576237782325), 8098951, 115792089237316195423570985008687907853269984665640564039457584007913129639935, 13236407030566367500245277044145863723594799806443029099909003518490], [uint256(48048861179516440), 353188904313347183711012492074128362960534202354266897390227009835549]);
		lpHandler.redeem(22122, 77190);
		lpHandler.mint(7847, 8036160740340245636560242756797959954043051125681287875985600636259920158289);
		lpHandler.mint(34434007073211460821667480, 1693);
		loanHandlerWithImpairment.makePayment(7124, 1196);
		lpHandler.requestRedeem(3, 2082454);
		loanHandlerWithImpairment.makePayment(45234926489751146521428401526917096967120359168260412853609686158838616134247, 3362);
		loanHandlerWithImpairment.makePayment(7987, 16157);
		loanHandlerWithImpairment.makePayment(352666677180178810290602, 0);
		loanHandlerWithImpairment.makePayment(76, 2880);
		loanHandlerWithImpairment.createLoanAndFund(3, [uint256(115792089237316195423570985008687907853269984665640564039457584007913129639935), 13270421874, 115792089237316195423570985008687907853269984665640564039457584007913129639935], [uint256(115792089237316195423570985008687907853269984665640564039457584007913129639934), 234586, 115792089237316195423570985008687907853269984665640564039457584007913129639935], [uint256(2071435538426665810480219591730089), 1, 917054757715651457252, 1283035341366674984823016476707004098096864872008048954722451974274696217440], [uint256(3), 48670453177720764173095]);
		lpHandler.mint(2, 27);
		lpHandler.transfer(22612, 495221350231076755210251, 24344);
		lpHandler.removeShares(552353741609728913858679534533273025980, 11276749948604902135813260822303526516385440652961547834366);
		lpHandler.deposit(602381618443284938507524400989084047, 0);
		loanHandlerWithImpairment.createLoanAndFund(515289046018046552691705398284236288845865390896, [uint256(92), 272645630226425663672076, 7409941055], [uint256(312483604455006548659914439012322646975606526476434611492793955680), 165040248460837835407951186195582452696588013600290496951559, 3], [uint256(46610022365862155921047786052016615776306270788514605916847), 42058285965642630967666064341839442, 391116230346265993834616902891077218038029364972202000864872207121797, 1], [uint256(3), 1518300768234821830579141195959009679014]);
		lpHandler.mint(13486, 20730);
		lpHandler.mint(115792089237316195423570985008687907853269984665640564039457584007913129639932, 0);
		loanHandlerWithImpairment.makePayment(17066606, 3);
		lpHandler.transfer(18284351249848140832449493417, 118138452627312805445255008612994897940864523021440954461374241862833568145, 3);
		lpHandler.mint(115792089237316195423570985008687907853269984665640564039457584007913129639934, 41290845584301590349455682870919512);
		lpHandler.requestRedeem(854, 1661703230728415016410326510808618652652373);
		lpHandler.requestRedeem(2, 115792089237316195423570985008687907853269984665640564039457584007913129639932);
		loanHandlerWithImpairment.makePayment(3, 8927842529154249057687);
		loanHandlerWithImpairment.createLoanAndFund(5047, [uint256(13944), 316413702, 90], [uint256(3851138617), 599290589, 86401], [uint256(105984227844678480413163694278809071361422200722516674544991333176942893510574), 443, 2581, 17277], [uint256(931), 2860]);
		loanHandlerWithImpairment.warp(115792089237316195423570985008687907853269984665640564039457584007913129639934);
		loanHandlerWithImpairment.createLoanAndFund(15232, [uint256(57251764531313921754142497428907475411085471079145049835121353048634594522609), 1285, 1133], [uint256(3880), 8454, 29102676481673041902632991033461445430619272659676223336789171408008386403023], [uint256(972750918076587648267694791), 4793, 2150, 581], [uint256(16939), 452857328472]);
		lpHandler.deposit(13558, 19637);
		loanHandlerWithImpairment.warp(3793);
		lpHandler.transfer(61371302306873804402335051337794214248714548, 632, 9153699026283051252064474083614165427784);
		lpHandler.deposit(2882821332906775788286463366154594802630757110, 130027664700667343949455421455271934090441163396988);
		lpHandler.mint(6367, 100000000);
		loanHandlerWithImpairment.warp(3533);
		loanHandlerWithImpairment.createLoanAndFund(5521063635675409793191391028921137466327707262060652747963, [uint256(2), 64454297088954276064573100215610921562, 42355447381061135307682436936470338352904905099795417709983316217474447738], [uint256(115792089237316195423570985008687907853269984665640564039457584007913129639933), 0, 13576117966964187034037968773827653868933613898345048], [uint256(144507098661730859236992081304489158360724), 28782849997326445753, 0, 39565530628170205093984580884926708367975261555401562527745646526410466550], [uint256(115792089237316195423570985008687907853269984665640564039457584007913129639933), 32588626216088058341109463368500542170522226230889238]);
		lpHandler.redeem(115792089237316195423570985008687907853269984665640564039457584007913129639932, 30);
		lpHandler.redeem(1, 30);
		lpHandler.redeem(115792089237316195423570985008687907853269984665640564039457584007913129639933, 20);
		lpHandler.transfer(115339776388732929035197660848497720713218148788040405586178452820382218977280, 24358, 2118);
		lpHandler.transfer(115792089237316195423570985008687907853269984665640564039457584007913129639935, 1809335769045495578490707345421894094160259333325205, 0);
		loanHandlerWithImpairment.makePayment(11322333834259702214009779540, 115792089237316195423570985008687907853269984665640564039457584007913129639932);
		lpHandler.transfer(498094287012179681, 390739962744079159929858967111783201226126174716232801219366055646951308332, 6726936422692937724809021603680497636651016897313405);
		lpHandler.requestRedeem(20694567183800415280465627143037372331, 115792089237316195423570985008687907853269984665640564039457584007913129639935);
		loanHandlerWithImpairment.warp(3588);
		loanHandlerWithImpairment.warp(16889);
		lpHandler.requestRedeem(3, 147358529441035783203474616082684865155400693072302239596782984115304);
		lpHandler.removeShares(3580, 457546703721091236364288);
		loanHandlerWithImpairment.warp(115792089237316195423570985008687907853269984665640564039457584007913129639935);
		lpHandler.deposit(4046396351, 16114);
		loanHandlerWithImpairment.makePayment(836, 22074);
		loanHandlerWithImpairment.warp(49);
		loanHandlerWithImpairment.warp(10093443991121590);
		loanHandlerWithImpairment.makePayment(884, 2440);
		loanHandlerWithImpairment.makePayment(241, 23234);

        for (uint256 i; i < loanHandlerWithImpairment.numLoans(); ++i) {
            address loan = loanHandlerWithImpairment.activeLoans(i);

            assert_loan_invariant_A(loan);
            assert_loan_invariant_B(loan);
            assert_loan_invariant_C(loan);

            ( , , uint256 startDate, uint256 paymentDueDate, , uint256 refinanceInterest , ) = loanManager.payments(loanManager.paymentIdOf(loan));

            assert_loanManager_invariant_L(loan, refinanceInterest);
            assert_loanManager_invariant_M(loan, paymentDueDate);
            assert_loanManager_invariant_N(loan, startDate);
        }
    }

}
