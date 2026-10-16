import Foundation
import CoreGraphics

public struct HeaderElement {
    public let id:String,role:String
    public let rect:CGRect
    public let parent:String?
    public let occupiedWidth:CGFloat?
    public let focused:Bool
    public init(id:String,role:String,rect:CGRect,parent:String? = nil,occupiedWidth:CGFloat? = nil,focused:Bool = false) {
        self.id=id;self.role=role;self.rect=rect;self.parent=parent;self.occupiedWidth=occupiedWidth;self.focused=focused
    }
}

public enum AppHeaderLayout {
    public enum Profile {case chrome,lark}
    public static func rails(profile:Profile,host:Surface,elements:[HeaderElement],selection:String)->[PerchRail] {
        var result:[PerchRail]=[]
        let interactive:Set<String>=["AXButton","AXPopUpButton","AXTextField","AXComboBox","AXCheckBox","AXRadioButton","AXLink","AXStaticText","AXSplitter"]
        func descendants(of id:String)->[HeaderElement] {
            var ids:Set<String>=[id],found:[HeaderElement]=[]
            for _ in 0..<24 {
                let children=elements.filter{!ids.contains($0.id) && $0.parent.map{ids.contains($0)}==true}
                if children.isEmpty {break}
                children.forEach{ids.insert($0.id)};found+=children
            }
            return found
        }
        func add(_ rect:CGRect,_ kind:PerchRail.Kind,_ id:String,_ controls:[CGRect]) {
            guard rect.width>12 else {return}
            var ranges=[rect.minX+6 ... rect.maxX-6]
            for r in controls {
                let a=r.minX-8,b=r.maxX+8
                ranges=ranges.flatMap {r -> [ClosedRange<CGFloat>] in
                    if b<=r.lowerBound || a>=r.upperBound {return [r]}
                    var pieces:[ClosedRange<CGFloat>]=[]
                    if a>r.lowerBound {pieces.append(r.lowerBound...min(a,r.upperBound))}
                    if b<r.upperBound {pieces.append(max(b,r.lowerBound)...r.upperBound)}
                    return pieces
                }
            }
            for (i,r) in ranges.filter({$0.upperBound-$0.lowerBound>=64}).enumerated() {
                result.append(PerchRail(id:"header-\(id)-\(selection)-\(i)",kind:kind,
                    rect:CGRect(x:r.lowerBound-host.rect.minX,y:rect.maxY-host.rect.minY,width:r.upperBound-r.lowerBound,height:1)))
            }
        }
        let zone=host.rect.minY+150
        switch profile {
        case .chrome:
            let toolbars=elements.filter{$0.role=="AXToolbar" && $0.rect.width>host.rect.width*0.6 && $0.rect.minY<zone && $0.rect.height<=60}
            for toolbar in toolbars {
                let children=descendants(of:toolbar.id)
                let fields=children.filter{$0.role=="AXTextField" && $0.rect.width>host.rect.width*0.3}
                if !fields.isEmpty {
                    for field in fields where !field.focused {
                        guard let width=field.occupiedWidth,let parent=elements.first(where:{$0.id==field.parent}),parent.rect.height<=48 else {continue}
                        let x=field.rect.minX+width+12,end=field.rect.maxX-6
                        guard end-x>=64 else {continue}
                        // The rounded omnibox's lower edge is the real foot line.
                        add(CGRect(x:x,y:parent.rect.minY,width:end-x,height:parent.rect.height),.addressBar,"address-\(field.id)-\(Int(ceil(width)))",[])
                    }
                } else {
                    let controls=children.filter{interactive.contains($0.role) && $0.rect.intersects(toolbar.rect)}.map(\.rect)
                    add(toolbar.rect,.toolbar,"toolbar-\(toolbar.id)",controls)
                }
            }
        case .lark:
            for group in elements where group.role=="AXGroup" && (150...500).contains(group.rect.width) && (30...70).contains(group.rect.height) && group.rect.minY<host.rect.minY+100 {
                let children=descendants(of:group.id)
                let controls=children.filter{interactive.contains($0.role) && $0.rect.intersects(group.rect)}
                let isSidebar=abs(group.rect.minX-host.rect.minX)<12 && controls.filter{$0.role=="AXButton"}.count>=2
                let isSection=group.rect.minX>host.rect.minX+120 && controls.contains{$0.role=="AXStaticText"} && controls.contains{$0.role=="AXButton"}
                guard isSidebar || isSection else {continue}
                add(group.rect,isSidebar ? .sidebarHeader:.sectionHeader,group.id,controls.map(\.rect))
            }
        }
        return result
    }
    public static func normalize(_ rect:CGRect,from content:CGRect,to window:CGRect)->CGRect {
        CGRect(x:window.minX+(rect.minX-content.minX)*window.width/content.width,
               y:window.minY+(rect.minY-content.minY)*window.height/content.height,
               width:rect.width*window.width/content.width,height:rect.height*window.height/content.height)
    }
}
