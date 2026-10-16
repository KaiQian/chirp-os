import AppKit
import ApplicationServices
import BirdingCore

// Only window chrome and pane headers are inspected. Terminal AXTextArea children
// and values are never traversed. Existing Accessibility permission is sufficient.
enum ITermAccessibility {
    private struct Node {let element:AXUIElement;let role:String;let rect:CGRect;let children:[Node]}
    private static func value(_ element:AXUIElement,_ key:String)->CFTypeRef? {
        var result:CFTypeRef?
        return AXUIElementCopyAttributeValue(element,key as CFString,&result) == .success ? result:nil
    }
    private static func bounds(_ element:AXUIElement)->CGRect? {
        guard let p=value(element,kAXPositionAttribute),CFGetTypeID(p)==AXValueGetTypeID(),
              let s=value(element,kAXSizeAttribute),CFGetTypeID(s)==AXValueGetTypeID() else {return nil}
        var origin=CGPoint.zero,size=CGSize.zero
        guard AXValueGetValue(p as! AXValue,.cgPoint,&origin),AXValueGetValue(s as! AXValue,.cgSize,&size),size.width>0,size.height>0 else {return nil}
        return CGRect(origin:origin,size:size)
    }
    private static func read(_ element:AXUIElement,depth:Int,budget:inout Int)->Node? {
        guard depth<=8,budget>0,let role=value(element,kAXRoleAttribute) as? String,
              role != kAXTextAreaRole,role != kAXScrollBarRole,let rect=bounds(element) else {return nil}
        budget-=1
        let children:[Node]
        if role == kAXScrollAreaRole {children=[]}
        else {children=(value(element,kAXChildrenAttribute) as? [AXUIElement] ?? []).compactMap{read($0,depth:depth+1,budget:&budget)}}
        return Node(element:element,role:role,rect:rect,children:children)
    }
    static func discover(_ hosts:[Surface])->[UInt32:[PerchRail]] {
        guard AXIsProcessTrusted() else {return [:]}
        var result:[UInt32:[PerchRail]]=[:]
        for pid in Set(hosts.map(\.pid)) {
            let app=AXUIElementCreateApplication(pid);AXUIElementSetMessagingTimeout(app,0.08)
            let windows=value(app,kAXWindowsAttribute) as? [AXUIElement] ?? []
            for window in windows {
                guard let rect=bounds(window),let host=hosts.first(where:{
                    $0.pid==pid && abs($0.rect.minX-rect.minX)<2 && abs($0.rect.minY-rect.minY)<2 &&
                    abs($0.rect.width-rect.width)<2 && abs($0.rect.height-rect.height)<2
                }) else {continue}
                var budget=140
                guard let root=read(window,depth:0,budget:&budget),root.role==kAXWindowRole else {continue}
                var selected="single"
                for tabs in root.children where tabs.role==kAXTabGroupRole {
                    if let tab=tabs.children.first(where:{(value($0.element,kAXValueAttribute) as? NSNumber)?.boolValue==true}) {
                        selected=String(CFHash(tab.element))
                    }
                }
                var rails:[PerchRail]=[]
                func addBar(_ rect:CGRect,kind:PerchRail.Kind,key:String,controls:[Node]) {
                    var ranges=[(rect.minX+6,rect.maxX-6)]
                    for node in controls where node.rect.intersects(rect) {
                        var obstacle=node.rect
                        if node.role==kAXStaticTextRole && obstacle.width>rect.width/2 {
                            // Pane-title AX frames include their blank trailing area.
                            // Measure the header label only, not terminal content.
                            let text=(value(node.element,kAXValueAttribute) as? String) ?? (value(node.element,kAXTitleAttribute) as? String) ?? ""
                            guard !text.isEmpty else {return}
                            let measured=(text as NSString).size(withAttributes:[.font:NSFont.systemFont(ofSize:14)]).width*1.15+8
                            obstacle.size.width=min(obstacle.width,measured)
                        }
                        let lo=obstacle.minX-8,hi=obstacle.maxX+8
                        ranges=ranges.flatMap { a,b -> [(CGFloat,CGFloat)] in
                            if hi<=a || lo>=b {return [(a,b)]}
                            return [(a,min(b,lo)),(max(a,hi),b)].filter{$0.1>$0.0}
                        }
                    }
                    for (index,range) in ranges.filter({$0.1-$0.0>=100}).enumerated() {
                        let y=kind == .titlebar ? rect.maxY:rect.minY
                        rails.append(PerchRail(id:"ax-\(key)-\(selected)-\(index)",kind:kind,
                            rect:CGRect(x:range.0-host.rect.minX,y:y-host.rect.minY,width:range.1-range.0,height:1)))
                    }
                }
                let contentTop=root.children.filter{$0.role==kAXGroupRole || $0.role==kAXTabGroupRole}.map(\.rect.minY).filter{$0>rect.minY}.min()
                if let y=contentTop,(12...40).contains(y-rect.minY) {
                    addBar(CGRect(x:rect.minX,y:rect.minY,width:rect.width,height:y-rect.minY),kind:.titlebar,key:"title",controls:root.children.filter{$0.role==kAXButtonRole || $0.role==kAXStaticTextRole})
                }
                func panes(_ parent:Node) {
                    if parent.role==kAXSplitGroupRole {
                        let edges=[parent.rect.minY]+parent.children.filter{$0.role==kAXSplitterRole && $0.rect.width>$0.rect.height}.map(\.rect.maxY)
                        for pane in parent.children where pane.role==kAXScrollAreaRole {
                            guard let y=edges.filter({(12...36).contains(pane.rect.minY-$0)}).max() else {continue}
                            let bar=CGRect(x:pane.rect.minX,y:y,width:pane.rect.width,height:pane.rect.minY-y)
                            let controls=parent.children.filter{($0.role==kAXButtonRole || $0.role==kAXStaticTextRole) && $0.rect.intersects(bar)}
                            guard controls.contains(where:{$0.role==kAXStaticTextRole}) else {continue}
                            addBar(bar,kind:.paneBar,key:String(CFHash(pane.element)),controls:controls)
                        }
                    }
                    for child in parent.children {panes(child)}
                }
                panes(root);result[host.id]=rails
            }
        }
        return result
    }
}
