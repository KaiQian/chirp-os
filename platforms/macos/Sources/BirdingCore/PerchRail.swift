import Foundation
import CoreGraphics

// Interior edges belong to a real WindowServer host; coordinates are local to it.
// IDs identify the visible bar and blank span, so replacing a pane invalidates its birds.
public struct PerchRail: Equatable {
    public enum Kind: String { case titlebar, paneBar, addressBar, toolbar, sidebarHeader, sectionHeader }
    public let id: String
    public let kind: Kind
    public let rect: CGRect
    public init(id:String,kind:Kind,rect:CGRect) {self.id=id;self.kind=kind;self.rect=rect}
    public func rect(on host:Surface) -> CGRect {rect.offsetBy(dx:host.rect.minX,dy:host.rect.minY)}
}

public extension Geometry {
    static func railRanges(_ rail:PerchRail,on host:Surface,surfaces:[Surface],screen:CGRect,
                           scale:CGFloat,occupied:[CGRect] = []) -> [ClosedRange<CGFloat>] {
        let rect=rail.rect(on:host)
        guard host.rect.contains(rect) else {return []}
        return horizontalRanges(on:host,rect:rect,y:rect.minY,surfaces:surfaces,screen:screen,
                                scale:scale,occupied:occupied,allowTailMask:true).compactMap { range in
            let lo=max(range.lowerBound,rect.minX+29*scale),hi=min(range.upperBound,rect.maxX-29*scale)
            return hi-lo>0.01 ? lo...hi:nil
        }
    }
}
