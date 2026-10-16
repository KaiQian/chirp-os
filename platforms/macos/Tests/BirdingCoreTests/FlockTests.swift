import XCTest
@testable import BirdingCore

final class FlockTests:XCTestCase {
    let host=Surface(id:1,rect:CGRect(x:0,y:300,width:1200,height:400))
    func bird(_ id:SpeciesID = .redWhiskeredBulbul)->Bird {
        let b=Bird(position:.zero,fraction:0.5,profile:SpeciesCatalog.standard.profile(id));b.perch(on:host);return b
    }
    func testSpeciesLimitIncludesBirdsStillDepartingAndRejectsThirdCompanion() {
        let a=bird(),b=bird(),f=FlockCoordinator()
        XCTAssertTrue(FlockCoordinator.canAdmit(a.profile.id,residents:[a]))
        XCTAssertFalse(FlockCoordinator.canAdmit(a.profile.id,residents:[a,b]))
        b.depart(to:.zero,duration:1)
        XCTAssertFalse(FlockCoordinator.canAdmit(a.profile.id,residents:[a,b]))
        XCTAssertTrue(FlockCoordinator.canAdmit(.treeSparrow,residents:[a,b]))
        f.didArrive(a,residents:[a],capacity:5,unit:0)
        XCTAssertEqual(f.arrivalSpecies(default:.treeSparrow,residents:[a,b]),.treeSparrow)
        XCTAssertFalse(f.companionReady)
    }
    func testCompanionArrivesLaterWithSameSpeciesAndGroup() {
        let f=FlockCoordinator(),a=bird()
        f.didArrive(a,residents:[a],capacity:5,unit:0)
        XCTAssertNotNil(a.groupID);XCTAssertFalse(f.companionReady)
        f.tick(3,residents:[a],random:{0.5});XCTAssertTrue(f.companionReady)
        XCTAssertEqual(f.arrivalSpecies(default:.treeSparrow,residents:[a]),a.profile.id)
        XCTAssertFalse(f.companionReady)
        let b=bird(f.arrivalSpecies(default:.treeSparrow,residents:[a]))
        f.prepareArrival(b,residents:[a]);XCTAssertEqual(b.groupID,a.groupID)
        f.didArrive(b,residents:[a,b],capacity:5,unit:0)
        XCTAssertEqual(f.arrivalSpecies(default:.treeSparrow,residents:[a,b]),.treeSparrow)
    }
    func testCompanionRespectsCapacityExpiryAndDeparture() {
        let full=FlockCoordinator(),a=bird()
        full.didArrive(a,residents:[a],capacity:1,unit:0)
        XCTAssertNil(a.groupID)
        XCTAssertEqual(full.arrivalSpecies(default:.treeSparrow,residents:[a]),.treeSparrow)
        let f=FlockCoordinator();f.didArrive(a,residents:[a],capacity:5,unit:0)
        f.tick(26,residents:[a],random:{0.5})
        XCTAssertEqual(f.arrivalSpecies(default:.treeSparrow,residents:[a]),.treeSparrow)
        f.didArrive(a,residents:[a],capacity:5,unit:0)
        a.depart(to:.zero,duration:1);f.tick(3,residents:[a],random:{0.5})
        XCTAssertFalse(f.companionReady)
    }
    func testGatheringSchedulesSmallGroupThenStaggeredDispersal() {
        let f=FlockCoordinator(initialDelay:1),birds=[bird(),bird(),bird(),bird(.nightHeron)]
        f.tick(1,residents:birds,random:{0})
        XCTAssertEqual(f.phase,.gathering)
        XCTAssertEqual(birds.filter{$0.groupID==birds[0].groupID}.count,2)
        XCTAssertNil(birds[0].socialMoveDelay)
        XCTAssertEqual(birds[1].socialMoveDelay,1);XCTAssertNil(birds[2].socialMoveDelay)
        birds[1].tick(1);birds[2].tick(1)
        XCTAssertTrue(birds[1].needsDestination);XCTAssertFalse(birds[2].needsDestination)
        f.tick(30,residents:birds,random:{0})
        XCTAssertEqual(f.phase,.dispersing)
        XCTAssertTrue(birds.allSatisfy{$0.groupID==nil})
        XCTAssertEqual(birds.compactMap(\.socialMoveDelay),[0.5,2.5])
        f.tick(20,residents:birds,random:{0})
        XCTAssertEqual(f.phase,.independent)
    }
    func testGatheringSelectsSameSpeciesPairAndDoesNotPadWithOtherSpecies() {
        let f=FlockCoordinator(initialDelay:0)
        let birds=[bird(.nightHeron),bird(.treeSparrow),bird(),bird()]
        f.tick(0,residents:birds,random:{0})
        XCTAssertEqual(f.phase,.gathering)
        XCTAssertNil(birds[0].groupID);XCTAssertNil(birds[1].groupID)
        XCTAssertNotNil(birds[2].groupID);XCTAssertEqual(birds[2].groupID,birds[3].groupID)
        f.tick(30,residents:birds,random:{0})
        XCTAssertNil(birds[0].socialMoveDelay);XCTAssertNil(birds[1].socialMoveDelay)
    }
    func testUniqueSpeciesUsuallyStayIndependentAndOnlyRarelyMix() {
        var mixed=0
        for ticket in 0..<100 {
            let f=FlockCoordinator(initialDelay:0),birds=[bird(),bird(.treeSparrow),bird(.nightHeron)]
            f.tick(0,residents:birds,random:{Double(ticket)/100})
            if f.phase == .gathering {mixed+=1}
            else {
                XCTAssertEqual(f.phase,.independent)
                XCTAssertTrue(birds.allSatisfy {$0.groupID==nil && $0.socialMoveDelay==nil})
                XCTAssertGreaterThanOrEqual(f.remaining,60)
            }
        }
        XCTAssertEqual(mixed,5)
    }
    func testCompanionsChooseNearbyFreeRangeAndFallbackWhenFull() {
        let f=FlockCoordinator(),a=bird(),b=bird()
        a.groupID=UUID();b.groupID=a.groupID
        let screen=CGRect(x:0,y:0,width:1200,height:900)
        let occupied=Geometry.landingFootprint(at:a.position,scale:1).insetBy(dx:-8,dy:-8)
        let choices=Geometry.landingRanges(on:host,surfaces:[host],screen:screen,scale:1,occupied:[occupied])
            .map{PerchChoice(host:host,edge:.top,screen:screen,scale:1,range:$0)}
        let selected=f.choose(choices,for:b,residents:[a],random:{1})!
        let foot=selected.choice.foot(at:selected.coordinate)
        XCTAssertEqual(selected.choice.host.id,host.id)
        XCTAssertLessThan(abs(foot.x-a.position.x),120)
        XCTAssertFalse(Geometry.landingFootprint(at:foot,scale:1).intersects(occupied))
        let other=Surface(id:2,rect:host.rect.offsetBy(dx:0,dy:200))
        let fallback=PerchChoice(host:other,edge:.top,screen:screen,scale:1,range:100...500)
        XCTAssertEqual(f.choose([fallback],for:b,residents:[a],random:{0.5})?.choice.host.id,2)
    }
    func testDispersalUsesAnotherLessOccupiedWindow() {
        let f=FlockCoordinator(initialDelay:0),a=bird(),b=bird(),c=bird()
        f.tick(0,residents:[a,b,c],random:{0});f.tick(30,residents:[a,b,c],random:{0})
        let screen=CGRect(x:0,y:0,width:1200,height:900)
        let other=Surface(id:2,rect:host.rect.offsetBy(dx:0,dy:200))
        let options=[host,other].map{PerchChoice(host:$0,edge:.top,screen:screen,scale:1,range:100...500)}
        XCTAssertEqual(f.choose(options,for:a,residents:[a,b,c],random:{0})?.choice.host.id,2)
    }
    func testSocialMoveWaitsForPerchingAndKeepsAnimationClocksIndependent() {
        let a=bird(),b=bird()
        a.fly(to:a.position,host:host,duration:4)
        a.scheduleSocialMove(after:2)
        a.tick(1);XCTAssertEqual(a.socialMoveDelay,2)
        a.tick(1);a.tick(0.43);a.tick(1)
        XCTAssertEqual(a.socialMoveDelay,1);XCTAssertFalse(a.needsDestination)
        a.tick(1);XCTAssertTrue(a.needsDestination)
        XCTAssertEqual(b.stateTime,0)
        XCTAssertFalse(b.needsDestination)
    }
    func testNaturalDeparturesPreserveNewPairsButRangeReductionStillWorks() {
        let f=FlockCoordinator(),a=bird(),b=bird(),single=bird()
        a.groupID=UUID();b.groupID=a.groupID
        a.tick(20);b.tick(20);single.tick(20)
        XCTAssertTrue(f.departureCandidate(residents:[a,b,single],unit:0) === single)
        XCTAssertNil(f.departureCandidate(residents:[a,b],unit:0))
        XCTAssertTrue(f.departureCandidate(residents:[a,b],force:true,unit:0) === a)
        a.tick(25);b.tick(25)
        XCTAssertTrue(f.departureCandidate(residents:[a,b],unit:0) === a)
    }
    func testFollowersUseLeaderRatherThanAnotherWaitingFollower() {
        let f=FlockCoordinator(initialDelay:0),birds=[bird(),bird(),bird(),bird()]
        let other=Surface(id:2,rect:host.rect.offsetBy(dx:0,dy:200))
        birds[3].perch(on:other)
        var draws=[0.0,0.75,0,0,0].makeIterator()
        f.tick(0,residents:birds,random:{draws.next() ?? 0})
        XCTAssertTrue(birds[3].leadsGroup)
        let screen=CGRect(x:0,y:0,width:1200,height:900)
        let options=[host,other].map{PerchChoice(host:$0,edge:.top,screen:screen,scale:1,range:100...1100)}
        XCTAssertEqual(f.choose(options,for:birds[0],residents:birds,random:{0.5})?.choice.host.id,other.id)
    }
    func testExistingPairRemainsExactlyTwo() {
        let f=FlockCoordinator(initialDelay:0),birds=[bird(),bird(),bird(),bird()]
        birds[0].groupID=UUID();birds[3].groupID=birds[0].groupID
        f.tick(0,residents:birds,random:{0})
        XCTAssertEqual(birds.filter{$0.groupID==birds[0].groupID}.count,2)
        XCTAssertEqual(birds[3].groupID,birds[0].groupID)
        XCTAssertNotNil(birds[3].socialMoveDelay)
    }
}
