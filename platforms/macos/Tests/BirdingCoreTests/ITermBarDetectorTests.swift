import XCTest
@testable import BirdingCore

final class ITermBarDetectorTests:XCTestCase {
    let w=600,h=500
    func fixture(dark:Bool=false,titleOffset:Int=0)->[UInt8] {
        var bytes=[UInt8](repeating:0,count:w*h*4)
        func box(_ x:Int,_ y:Int,_ width:Int,_ height:Int,_ c:UInt8) {
            for yy in y..<y+height {for xx in x..<x+width {let i=(yy*w+xx)*4;bytes[i]=c;bytes[i+1]=c;bytes[i+2]=c;bytes[i+3]=255}}
        }
        box(0,0,w,h,dark ? 24:0)
        for y in [0,230] {
            box(0,y,w,22,dark ? 64:190)
            box(8,y+7,40,8,dark ? 170:55)
            box(60+titleOffset,y+7,80,8,dark ? 170:55)
        }
        return bytes
    }
    func detect(_ bytes:[UInt8],scale:CGFloat=1)->[PerchRail] {
        ITermBarDetector.detect(rgba:bytes,width:w,height:h,windowSize:CGSize(width:CGFloat(w)*scale,height:CGFloat(h)*scale))
    }
    func testLightAndDarkHeadersExposeBlankSpansAwayFromControls() {
        for dark in [false,true] {
            let rails=detect(fixture(dark:dark))
            XCTAssertEqual(rails.count,2)
            XCTAssertEqual(rails.map(\.kind),[.titlebar,.paneBar])
            XCTAssertEqual(rails[0].rect.minY,22);XCTAssertEqual(rails[1].rect.minY,230)
            XCTAssertTrue(rails.allSatisfy {$0.rect.minX>140 && $0.rect.maxX<600})
        }
    }
    func testHeaderIdentitySurvivesCaptureButChangesWhenPaneTitleChanges() {
        let a=detect(fixture()),b=detect(fixture()),changed=detect(fixture(titleOffset:20))
        XCTAssertEqual(a,b)
        XCTAssertEqual(a[0].id,changed[0].id)
        XCTAssertNotEqual(a[1].id,changed[1].id)
    }
    func testPixelToWindowCoordinatesRespectCaptureScale() {
        let a=detect(fixture()),b=detect(fixture(),scale:0.75)
        XCTAssertEqual(b.count,a.count)
        for (small,large) in zip(a,b) {XCTAssertEqual(large.rect.minY,small.rect.minY*0.75)}
    }
    func testTabSelectionReleasesRailsEvenWhenPaneHeadersHaveSameNames() {
        func tab(_ selectedX:Int)->[UInt8] {
            var bytes=fixture()
            func box(_ x:Int,_ y:Int,_ width:Int,_ height:Int,_ c:UInt8) {
                for yy in y..<y+height {for xx in x..<x+width {let i=(yy*w+xx)*4;bytes[i]=c;bytes[i+1]=c;bytes[i+2]=c;bytes[i+3]=255}}
            }
            box(0,22,w,43,150);box(selectedX,25,100,37,225)
            box(0,65,w,22,190);box(8,72,110,8,55)
            return bytes
        }
        let a=detect(tab(30)),b=detect(tab(170))
        XCTAssertFalse(a.isEmpty);XCTAssertEqual(a.count,b.count)
        XCTAssertEqual(a.map(\.rect),b.map(\.rect))
        XCTAssertTrue(zip(a,b).allSatisfy{$0.id != $1.id})
    }
    func testPlainTerminalAndUnlabelledStripeAreNotPerches() {
        XCTAssertTrue(detect([UInt8](repeating:0,count:w*h*4)).isEmpty)
        var bytes=[UInt8](repeating:0,count:w*h*4)
        for yy in 230..<252 {for x in 0..<w {let i=(yy*w+x)*4;bytes[i]=190;bytes[i+1]=190;bytes[i+2]=190;bytes[i+3]=255}}
        XCTAssertTrue(detect(bytes).isEmpty)
        XCTAssertTrue(ITermBarDetector.detect(rgba:[],width:w,height:h,windowSize:CGSize(width:w,height:h)).isEmpty)
    }
}
