import AppKit
import ApplicationServices
import BirdingCore

// Chrome web pages and Lark conversation views are excluded from traversal.
// An omnibox value is measured in memory only; URLs and messages are never retained.
enum AppHeaderAccessibility {
    private static func value(_ e:AXUIElement,_ key:String)->CFTypeRef? {
        var v:CFTypeRef?;return AXUIElementCopyAttributeValue(e,key as CFString,&v) == .success ? v:nil
    }
    private static func bounds(_ e:AXUIElement)->CGRect? {
        guard let p=value(e,kAXPositionAttribute),let s=value(e,kAXSizeAttribute),CFGetTypeID(p)==AXValueGetTypeID(),CFGetTypeID(s)==AXValueGetTypeID() else {return nil}
        var point=CGPoint.zero,size=CGSize.zero
        guard AXValueGetValue(p as! AXValue,.cgPoint,&point),AXValueGetValue(s as! AXValue,.cgSize,&size),size.width>0,size.height>0 else{return nil}
        return CGRect(origin:point,size:size)
    }
    static func discover(_ hosts:[Surface])->[UInt32:[PerchRail]] {
        guard AXIsProcessTrusted() else {return [:]}
        var result:[UInt32:[PerchRail]]=[:]
        for pid in Set(hosts.map(\.pid)) {
            let profile:AppHeaderLayout.Profile=NSRunningApplication(processIdentifier:pid)?.bundleIdentifier=="com.google.Chrome" ? .chrome:.lark
            let app=AXUIElementCreateApplication(pid);AXUIElementSetMessagingTimeout(app,0.06)
            for win in value(app,kAXWindowsAttribute) as? [AXUIElement] ?? [] {
                guard let frame=bounds(win),let host=hosts.first(where:{$0.pid==pid && abs($0.rect.minX-frame.minX)<2 && abs($0.rect.minY-frame.minY)<2 && abs($0.rect.width-frame.width)<2 && abs($0.rect.height-frame.height)<2}) else {continue}
                var elements:[HeaderElement]=[],budget=350,selection="window"
                func visit(_ e:AXUIElement,parent:String?,depth:Int,content:CGRect? = nil) {
                    guard depth<=25,budget>0,let role=value(e,kAXRoleAttribute) as? String,
                          !["AXTextArea","AXList","AXTable","AXOutline","AXRow","AXScrollBar","AXScrollArea"].contains(role),let raw=bounds(e) else{return}
                    var normalization=content
                    if profile == .lark && depth==1 && role=="AXGroup" {
                        let sx=frame.width/raw.width,sy=frame.height/raw.height
                        if abs(sx-sy)<0.03,abs(sx-1)>0.02 {normalization=raw}
                    }
                    let rect=normalization.map{AppHeaderLayout.normalize(raw,from:$0,to:frame)} ?? raw
                    guard rect.minY<frame.minY+150 else {return}
                    if role=="AXWebArea" && (profile == .chrome || rect.width>frame.width*0.6) {return}
                    if profile == .lark && role=="AXGroup" && rect.height>120 && rect.minY>frame.minY+40 {return}
                    budget-=1
                    let id=String(CFHash(e))
                    var occupied:CGFloat?
                    let focused=(value(e,kAXFocusedAttribute) as? NSNumber)?.boolValue ?? false
                    if profile == .chrome && role=="AXTextField" && rect.width>frame.width*0.3 {
                        if let text=(value(e,kAXValueAttribute) as? String) ?? (value(e,"AXPlaceholderValue") as? String) {
                            occupied=(text as NSString).size(withAttributes:[.font:NSFont.systemFont(ofSize:14)]).width*1.08+8
                        }
                    }
                    if role=="AXRadioButton",elements.first(where:{$0.id==parent})?.role=="AXTabGroup",(value(e,kAXValueAttribute) as? NSNumber)?.boolValue==true {selection=id}
                    elements.append(HeaderElement(id:id,role:role,rect:rect,parent:parent,occupiedWidth:occupied,focused:focused))
                    for child in value(e,kAXChildrenAttribute) as? [AXUIElement] ?? [] {visit(child,parent:id,depth:depth+1,content:normalization)}
                }
                visit(win,parent:nil,depth:0)
                let rails=AppHeaderLayout.rails(profile:profile,host:host,elements:elements,selection:selection)
                if result[host.id]==nil || !rails.isEmpty {result[host.id]=rails}
            }
        }
        return result
    }
}
