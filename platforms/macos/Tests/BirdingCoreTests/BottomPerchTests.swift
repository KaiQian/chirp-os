import XCTest
@testable import BirdingCore

final class BottomPerchTests:XCTestCase {
    let screen=CGRect(x:-1920,y:-1080,width:1920,height:1080)
    func testFullscreenFeetMeetEdgeAndTailIsMaskedForEverySpecies() {
        let host=Surface(id:1,rect:screen)
        let work=CGRect(x:screen.minX+70,y:screen.minY+33,width:1850,height:977)
        for p in SpeciesCatalog.standard.species {
            let scale=CGFloat(p.relativeScale)*1.5
            XCTAssertTrue(Geometry.landingRanges(on:host,surfaces:[host],screen:work,scale:scale).isEmpty)
            let ranges=Geometry.bottomRanges(on:host,surfaces:[host],screen:work,scale:scale)
            XCTAssertFalse(ranges.isEmpty,p.id.rawValue)
            for r in ranges {
                let choice=PerchChoice(host:host,edge:.bottom,screen:work,scale:scale,range:r)
                let foot=choice.foot(at:(r.lowerBound+r.upperBound)/2)
                XCTAssertEqual(foot.y,work.maxY,accuracy:0.001)
                let bird=Bird(position:.zero,fraction:choice.fraction(at:foot.x),profile:p)
                bird.edge = .bottom;bird.bottomViewport=work;bird.perch(on:host,spriteScale:scale)
                let pieces=Geometry.visiblePieces(Geometry.landingFootprint(at:foot,scale:scale),blockers:bird.blockers(in:[host]))
                XCTAssertFalse(pieces.isEmpty)
                XCTAssertTrue(pieces.allSatisfy {work.contains($0)})
                XCTAssertEqual(pieces.map(\.maxY).max()!,foot.y,accuracy:0.001)
            }
        }
    }
    func testOnlyForemostCoveringWindowGetsBottomPerches() {
        let front=Surface(id:1,rect:screen),back=Surface(id:2,rect:screen)
        XCTAssertFalse(Geometry.bottomRanges(on:front,surfaces:[front,back],screen:screen,scale:1).isEmpty)
        XCTAssertTrue(Geometry.bottomRanges(on:back,surfaces:[front,back],screen:screen,scale:1).isEmpty)
        let ordinary=Surface(id:3,rect:screen.insetBy(dx:100,dy:100))
        XCTAssertTrue(Geometry.bottomRanges(on:ordinary,surfaces:[ordinary],screen:screen,scale:1).isEmpty)
    }
    func testPopupAndOtherBirdsReserveBottomSpace() {
        let host=Surface(id:1,rect:screen)
        let front=Surface(id:2,rect:CGRect(x:-1200,y:-200,width:300,height:200))
        let reserved=Geometry.landingFootprint(at:CGPoint(x:-500,y:0),scale:1).insetBy(dx:-8,dy:-8)
        let ranges=Geometry.bottomRanges(on:host,surfaces:[front,host],screen:screen,scale:1,occupied:[reserved])
        XCTAssertGreaterThanOrEqual(ranges.count,2)
        for r in ranges {
            let foot=CGPoint(x:(r.lowerBound+r.upperBound)/2,y:0)
            XCTAssertFalse(Geometry.landingFootprint(at:foot,scale:1).intersects(front.rect))
            XCTAssertFalse(Geometry.landingFootprint(at:foot,scale:1).intersects(reserved))
        }
        let bird=Bird(position:.zero,fraction:0.5);bird.edge = .bottom;bird.bottomViewport=screen
        bird.perch(on:host)
        XCTAssertEqual(bird.blockers(in:[front,host]).first,front.rect)
    }
    func testBottomTailOcclusionStartsOnlyAfterLandingAndStopsOnTakeoff() {
        let host=Surface(id:1,rect:screen),bird=Bird(position:.zero,fraction:0.5)
        bird.edge = .bottom;bird.bottomViewport=screen
        bird.fly(to:Geometry.foot(on:host,fraction:0.5,edge:.bottom,screen:screen),host:host,duration:1)
        XCTAssertTrue(bird.blockers(in:[host]).isEmpty)
        bird.tick(0.5)
        XCTAssertEqual(bird.state,.landing)
        XCTAssertEqual(bird.blockers(in:[host]).first!.minY,screen.maxY,accuracy:0.001)
        bird.flee()
        XCTAssertTrue(bird.blockers(in:[host]).isEmpty)
    }
    func testExitFullscreenReplansWithoutTeleportOrStartle() {
        let full=Surface(id:1,rect:screen),normal=Surface(id:1,rect:screen.insetBy(dx:100,dy:100))
        let bird=Bird(position:.zero,fraction:0.5);bird.edge = .bottom;bird.bottomViewport=screen;bird.perch(on:full)
        let position=bird.position
        bird.updateHost(surfaces:[normal],sampleDT:0.03)
        XCTAssertEqual(bird.position,position)
        XCTAssertNil(bird.hostID);XCTAssertTrue(bird.needsDestination)
        XCTAssertEqual(bird.startledCount,0)
        bird.edge = .top;bird.fly(to:Geometry.foot(on:normal,fraction:0.5,edge:.top),host:normal,duration:1)
        bird.tick(0.5);bird.tick(0.43)
        XCTAssertEqual(bird.state,.perched)
        XCTAssertEqual(bird.position.y,normal.rect.minY)
    }
    func testDockChangesAndBottomLandingUseStandingAnimation() {
        let host=Surface(id:1,rect:screen)
        let bird=Bird(position:.zero,fraction:0.5);bird.edge = .bottom;bird.bottomViewport=screen
        bird.fly(to:Geometry.foot(on:host,fraction:0.5,edge:.bottom,screen:screen),host:host,duration:1)
        bird.tick(0.5);XCTAssertEqual(bird.frameName,"land0")
        bird.tick(0.43)
        let previous=bird.position
        let work=CGRect(x:screen.minX,y:screen.minY,width:screen.width,height:screen.height-70)
        bird.bottomViewport=work;bird.updateHost(surfaces:[host],sampleDT:0.03)
        XCTAssertEqual(bird.state,.perched);XCTAssertEqual(bird.position.y,previous.y-70,accuracy:0.001)
        XCTAssertEqual(bird.startledCount,0)
        XCTAssertEqual(bird.position.y,work.maxY,accuracy:0.001)
    }
    func testFocusedWindowHasNoBottomPerchAndFocusStartlesExistingBird() {
        let host=Surface(id:1,rect:screen),focused=Surface(id:1,rect:screen,isFocused:true)
        let bird=Bird(position:.zero,fraction:0.5);bird.edge = .bottom;bird.bottomViewport=screen;bird.perch(on:host)
        let point=bird.position
        bird.updateHost(surfaces:[focused],sampleDT:0.03)
        XCTAssertEqual(bird.position,point);XCTAssertEqual(bird.state,.flying)
        XCTAssertNil(bird.hostID);XCTAssertEqual(bird.startledCount,1)
        XCTAssertTrue(Geometry.bottomRanges(on:focused,surfaces:[focused],screen:screen,scale:1).isEmpty)
        let rear=Surface(id:2,rect:screen)
        XCTAssertTrue(Geometry.bottomRanges(on:rear,surfaces:[focused,rear],screen:screen,scale:1).isEmpty)
        let normal=Surface(id:3,rect:screen.insetBy(dx:100,dy:100),isFocused:true)
        XCTAssertFalse(Geometry.landingRanges(on:normal,surfaces:[normal],screen:screen,scale:1).isEmpty)
    }
    func testFocusedWindowSelectionDoesNotExcludeAllWindowsOfSameApp() {
        let other=Surface(id:1,pid:7,rect:screen)
        let a=Surface(id:2,pid:8,rect:screen.insetBy(dx:10,dy:10))
        let b=Surface(id:3,pid:8,rect:screen.insetBy(dx:20,dy:20))
        XCTAssertEqual(WindowFocusPolicy.windowID(in:[other,a,b],frontPID:8),a.id)
        XCTAssertEqual(WindowFocusPolicy.windowID(in:[other,a,b],frontPID:8,focusedBounds:b.rect),b.id)
        XCTAssertNil(WindowFocusPolicy.windowID(in:[other,a,b],frontPID:nil))
    }
}
