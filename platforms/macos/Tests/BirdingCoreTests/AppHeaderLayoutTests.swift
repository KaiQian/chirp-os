import XCTest
@testable import BirdingCore

final class AppHeaderLayoutTests:XCTestCase {
    let host=Surface(id:1,rect:CGRect(x:0,y:0,width:1200,height:900),isFocused:true)
    func chrome(focused:Bool=false,width:CGFloat=300)->[HeaderElement] {
        [HeaderElement(id:"nav",role:"AXToolbar",rect:CGRect(x:0,y:40,width:1200,height:46)),
         HeaderElement(id:"omni",role:"AXGroup",rect:CGRect(x:120,y:46,width:900,height:34),parent:"nav"),
         HeaderElement(id:"url",role:"AXTextField",rect:CGRect(x:156,y:51,width:820,height:24),parent:"omni",occupiedWidth:width,focused:focused),
         HeaderElement(id:"bookmarks",role:"AXToolbar",rect:CGRect(x:0,y:86,width:1200,height:34)),
         HeaderElement(id:"bookmark-a",role:"AXButton",rect:CGRect(x:8,y:88,width:600,height:28),parent:"bookmarks"),
         HeaderElement(id:"all-bookmarks",role:"AXPopUpButton",rect:CGRect(x:1100,y:88,width:90,height:28),parent:"bookmarks")]
    }
    func testChromeBlankAddressAndBookmarkSpansAvoidTextAndButtons() {
        let rails=AppHeaderLayout.rails(profile:.chrome,host:host,elements:chrome(),selection:"one")
        XCTAssertEqual(Set(rails.map(\.kind)),[.addressBar,.toolbar])
        let url=rails.first{$0.kind == .addressBar}!,bookmarks=rails.first{$0.kind == .toolbar}!
        XCTAssertGreaterThan(url.rect.minX,456);XCTAssertLessThan(url.rect.maxX,976)
        XCTAssertEqual(url.rect.minY,80);XCTAssertEqual(bookmarks.rect.minY,120)
        XCTAssertGreaterThan(bookmarks.rect.minX,608);XCTAssertLessThan(bookmarks.rect.maxX,1100)
    }
    func testAddressTypingAndLongAddressesRemoveUnsafePerches() {
        XCTAssertFalse(AppHeaderLayout.rails(profile:.chrome,host:host,elements:chrome(focused:true),selection:"one").contains{$0.kind == .addressBar})
        XCTAssertFalse(AppHeaderLayout.rails(profile:.chrome,host:host,elements:chrome(width:900),selection:"one").contains{$0.kind == .addressBar})
        let old=AppHeaderLayout.rails(profile:.chrome,host:host,elements:chrome(),selection:"one")
        let new=AppHeaderLayout.rails(profile:.chrome,host:host,elements:chrome(),selection:"two")
        XCTAssertTrue(Set(old.map(\.id)).isDisjoint(with:Set(new.map(\.id))))
    }
    func testLarkAvatarAndMessageHeadersHaveBlankRanges() {
        let elements=[HeaderElement(id:"sidebar",role:"AXGroup",rect:CGRect(x:0,y:50,width:222,height:34)),
            HeaderElement(id:"avatar",role:"AXButton",rect:CGRect(x:10,y:50,width:60,height:34),parent:"sidebar"),
            HeaderElement(id:"add",role:"AXButton",rect:CGRect(x:186,y:55,width:24,height:24),parent:"sidebar"),
            HeaderElement(id:"messages",role:"AXGroup",rect:CGRect(x:222,y:0,width:300,height:48)),
            HeaderElement(id:"toggle",role:"AXButton",rect:CGRect(x:232,y:10,width:25,height:25),parent:"messages"),
            HeaderElement(id:"label",role:"AXStaticText",rect:CGRect(x:260,y:12,width:33,height:20),parent:"messages")]
        let rails=AppHeaderLayout.rails(profile:.lark,host:host,elements:elements,selection:"window")
        XCTAssertEqual(Set(rails.map(\.kind)),[.sidebarHeader,.sectionHeader])
        let sidebar=rails.first{$0.kind == .sidebarHeader}!
        XCTAssertGreaterThanOrEqual(sidebar.rect.minX,78);XCTAssertLessThanOrEqual(sidebar.rect.maxX,178)
        XCTAssertEqual(sidebar.rect.minY,84)
        let screen=host.rect
        let ranges=Geometry.railRanges(sidebar,on:Surface(id:1,rect:screen,rails:rails),surfaces:[Surface(id:1,rect:screen,rails:rails)],screen:screen,scale:1)
        XCTAssertFalse(ranges.isEmpty)
        XCTAssertTrue(ranges.allSatisfy{$0.lowerBound-29>=sidebar.rect.minX && $0.upperBound+29<=sidebar.rect.maxX})
    }
    func testElectronZoomCoordinatesAreMappedIntoActualWindow() {
        let window=CGRect(x:0,y:33,width:1728,height:1023),content=CGRect(x:0,y:37,width:1920,height:1137)
        let actual=AppHeaderLayout.normalize(CGRect(x:78,y:81,width:100,height:34),from:content,to:window)
        XCTAssertEqual(actual.minX,70.2,accuracy:0.01)
        XCTAssertEqual(actual.minY,72.59,accuracy:0.02)
        XCTAssertEqual(actual.width,90,accuracy:0.01)
    }
}
