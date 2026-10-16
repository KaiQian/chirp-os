import XCTest
@testable import BirdingCore

final class PerchRailTests:XCTestCase {
    let screen=CGRect(x:-1200,y:-900,width:1200,height:900)
    let rail=PerchRail(id:"pane-a",kind:.paneBar,rect:CGRect(x:150,y:350,width:800,height:1))
    func host(_ rails:[PerchRail]) -> Surface {Surface(id:1,rect:screen,isFocused:true,rails:rails)}
    func testFocusedWindowInteriorPerchesHaveCorrectFootAndFraction() {
        let h=host([rail]),ranges=Geometry.railRanges(rail,on:h,surfaces:[h],screen:screen,scale:1)
        XCTAssertFalse(ranges.isEmpty)
        let option=PerchChoice(host:h,edge:.rail,screen:screen,scale:1,range:ranges[0],railID:rail.id)
        let p=option.foot(at:-600)
        XCTAssertEqual(p.x,-600,accuracy:0.001);XCTAssertEqual(p.y,-550,accuracy:0.001)
        let b=Bird(position:.zero,fraction:option.fraction(at:p.x));b.edge = .rail;b.railID=rail.id;b.perch(on:h)
        b.updateHost(surfaces:[h],sampleDT:0.03)
        XCTAssertEqual(b.position,p);XCTAssertEqual(b.state,.perched)
        XCTAssertTrue(Geometry.bottomRanges(on:h,surfaces:[h],screen:screen,scale:1).isEmpty)
    }
    func testInteriorRespectsHeadroomHostBoundsForegroundAndBirdReservations() {
        let h=host([rail]),p=CGPoint(x:-600,y:-550)
        let front=Surface(id:2,rect:CGRect(x:-900,y:-650,width:150,height:150))
        let reserved=Geometry.landingFootprint(at:p,scale:1).insetBy(dx:-8,dy:-8)
        let ranges=Geometry.railRanges(rail,on:h,surfaces:[front,h],screen:screen,scale:1,occupied:[reserved])
        XCTAssertFalse(ranges.isEmpty)
        for r in ranges {
            let foot=CGPoint(x:(r.lowerBound+r.upperBound)/2,y:p.y)
            XCTAssertFalse(Geometry.landingFootprint(at:foot,scale:1).intersects(front.rect))
            XCTAssertFalse(Geometry.landingFootprint(at:foot,scale:1).intersects(reserved))
        }
        let top=PerchRail(id:"title",kind:.titlebar,rect:CGRect(x:100,y:22,width:800,height:1))
        XCTAssertTrue(Geometry.railRanges(top,on:host([top]),surfaces:[host([top])],screen:screen,scale:1).isEmpty)
        let outside=PerchRail(id:"bad",kind:.paneBar,rect:CGRect(x:100,y:910,width:800,height:1))
        XCTAssertTrue(Geometry.railRanges(outside,on:host([outside]),surfaces:[host([outside])],screen:screen,scale:1).isEmpty)
    }
    func testBirdFollowsWindowAndSplitBarThenFliesWhenPaneDisappears() {
        let h=host([rail]),b=Bird(position:.zero,fraction:0.5);b.edge = .rail;b.railID=rail.id;b.perch(on:h)
        let old=b.position
        var moved=h;moved.rect=moved.rect.offsetBy(dx:3,dy:2)
        moved.rails=[PerchRail(id:rail.id,kind:rail.kind,rect:rail.rect.offsetBy(dx:0,dy:40))]
        b.updateHost(surfaces:[moved],sampleDT:0.03)
        XCTAssertEqual(b.position,CGPoint(x:old.x+3,y:old.y+42));XCTAssertEqual(b.startledCount,0)
        moved.rails=[];let before=b.position;b.updateHost(surfaces:[moved],sampleDT:0.03)
        XCTAssertEqual(b.position,before);XCTAssertEqual(b.state,.flying);XCTAssertNil(b.hostID)
    }
    func testNewOccluderReleasesPerchedInteriorBirdWithoutTeleport() {
        let h=host([rail]),b=Bird(position:.zero,fraction:0.5);b.edge = .rail;b.railID=rail.id;b.perch(on:h)
        let p=b.position,front=Surface(id:2,rect:Geometry.landingFootprint(at:b.position,scale:1))
        b.updateHost(surfaces:[front,h],sampleDT:0.03)
        XCTAssertEqual(b.position,p);XCTAssertTrue(b.needsDestination);XCTAssertNil(b.hostID)
    }
    func testGroupFollowerChoosesSameInteriorBar() {
        let other=PerchRail(id:"pane-b",kind:.paneBar,rect:rail.rect.offsetBy(dx:0,dy:200)),h=host([rail,other])
        let leader=Bird(position:.zero,fraction:0.5),follower=Bird(position:.zero,fraction:0.1)
        leader.edge = .rail;leader.railID=rail.id;leader.groupID=UUID();leader.leadsGroup=true;leader.perch(on:h)
        follower.groupID=leader.groupID
        let options=[other,rail].map {PerchChoice(host:h,edge:.rail,screen:screen,scale:1,range:-1000 ... -300,railID:$0.id)}
        let selected=FlockCoordinator().choose(options,for:follower,residents:[leader,follower],random:{0.5})!
        XCTAssertEqual(selected.choice.railID,rail.id)
        XCTAssertLessThan(abs(selected.choice.foot(at:selected.coordinate).x-leader.position.x),120)
    }
}
