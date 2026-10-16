import XCTest
import CoreGraphics
@testable import BirdingCore

final class LandingRangeTests: XCTestCase {
    let screen = CGRect(x: 0, y: 0, width: 1200, height: 900)
    let host = Surface(id: 1, rect: CGRect(x: 0, y: 300, width: 1000, height: 400))
    func testBackgroundWindowStripAllowsLandingAndNaturallyMasksTail() {
        // A rear title bar exposed above the foreground browser, including
        // strips thinner than the hanging tail. Keep the host's background depth.
        for scale:CGFloat in [1,2.5] {
            for gap:CGFloat in [3,30] {
                let front=Surface(id:2,rect:CGRect(x:0,y:300+gap,width:1000,height:400))
                let surfaces=[front,host]
                let ranges=Geometry.landingRanges(on:host,surfaces:surfaces,screen:screen,scale:scale)
                XCTAssertTrue(ranges.contains{$0.contains(500)})
                let end=CGPoint(x:500,y:300)
                XCTAssertTrue(Geometry.isLandingVisible(on:host.id,at:end,surfaces:surfaces,scale:scale))
                let bird=Bird(position:CGPoint(x:500,y:500),fraction:0.5)
                bird.fly(to:end,host:host,duration:2)
                bird.updateHost(surfaces:surfaces,sampleDT:0.03,spriteScale:scale)
                XCTAssertFalse(bird.needsDestination)
                bird.tick(1);bird.tick(0.43)
                XCTAssertEqual(bird.state,.perched)
                XCTAssertEqual(bird.depthID,host.id)
                XCTAssertEqual(bird.blockers(in:surfaces),[front.rect])
                let area=Geometry.landingFootprint(at:end,scale:scale)
                let pieces=Geometry.visiblePieces(area,blockers:bird.blockers(in:surfaces))
                XCTAssertFalse(pieces.isEmpty)
                XCTAssertTrue(pieces.allSatisfy{!$0.intersects(front.rect)})
            }
        }
    }
    func testBackgroundStripStillRequiresExposedFeetAndAvoidsBirdOverlap() {
        let cover=Surface(id:2,rect:CGRect(x:0,y:300,width:1000,height:400))
        XCTAssertTrue(Geometry.landingRanges(on:host,surfaces:[cover,host],screen:screen,scale:1).isEmpty)
        XCTAssertFalse(Geometry.isLandingVisible(on:host.id,at:CGPoint(x:500,y:300),surfaces:[cover,host],scale:1))
        let reserved=CGRect(x:0,y:303,width:1000,height:20)
        XCTAssertTrue(Geometry.landingRanges(on:host,surfaces:[host],screen:screen,scale:1,occupied:[reserved]).isEmpty)
    }
    func testPartlyCoveredEdgeOffersContinuousPositions() {
        for blocker in [CGRect(x: 0, y: 100, width: 620, height: 300), CGRect(x: 380, y: 100, width: 620, height: 300)] {
            let surfaces = [Surface(id: 2, rect: blocker), host]
            let ranges = Geometry.landingRanges(on: host, surfaces: surfaces, screen: screen, scale: 1)
            XCTAssertEqual(ranges.count, 1)
            let range = ranges[0]
            XCTAssertGreaterThan(range.upperBound-range.lowerBound, 250)
            for i in 1...99 {
                let x = range.lowerBound + (range.upperBound-range.lowerBound)*CGFloat(i)/100
                XCTAssertTrue(Geometry.isLandingVisible(on: host.id, at: CGPoint(x: x,y:300), surfaces: surfaces, scale:1))
            }
        }
    }
    func testReservedArrivalAndStandingSpaceCannotBeSelectedAgain() {
        let reserved = Geometry.landingFootprint(at: CGPoint(x: 500,y:300),scale:1.6).insetBy(dx:-8,dy:-8)
        let ranges = Geometry.landingRanges(on:host,surfaces:[host],screen:screen,scale:1,occupied:[reserved])
        XCTAssertEqual(ranges.count,2)
        for range in ranges {
            let x = (range.lowerBound+range.upperBound)/2
            XCTAssertFalse(Geometry.landingFootprint(at:CGPoint(x:x,y:300),scale:1).intersects(reserved))
        }
        XCTAssertFalse(ranges.contains { $0.contains(500) })
    }
    func testFullEdgeAndOffscreenClipping() {
        XCTAssertTrue(Geometry.landingRanges(on:host,surfaces:[host],screen:screen,scale:1,occupied:[host.rect.insetBy(dx:0,dy:-80)]).isEmpty)
        let negative = Surface(id:3,rect:CGRect(x:-1000,y:300,width:1500,height:400))
        let ranges = Geometry.landingRanges(on:negative,surfaces:[negative],screen:screen,scale:1)
        XCTAssertEqual(ranges.first?.lowerBound,29)
        XCTAssertEqual(ranges.first?.upperBound,458)
    }
}
