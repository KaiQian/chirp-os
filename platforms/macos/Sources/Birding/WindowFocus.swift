import AppKit
import ApplicationServices
import BirdingCore

final class WindowFocus {
    private var sampled:Double = 0
    private var previousPID:Int32?
    private var cachedID:UInt32?
    func windowID(in info:[[String:Any]]) -> UInt32? {
        let pid=NSWorkspace.shared.frontmostApplication?.processIdentifier
        let now=ProcessInfo.processInfo.systemUptime
        let windows:[Surface]=info.compactMap { row in
            guard let id=row[kCGWindowNumber as String] as? UInt32,
                  let owner=row[kCGWindowOwnerPID as String] as? Int32,owner==pid,
                  let layer=row[kCGWindowLayer as String] as? Int,layer>=0,layer<=NSWindow.Level.floating.rawValue,
                  let alpha=row[kCGWindowAlpha as String] as? Double,alpha>0.05,
                  let raw=row[kCGWindowBounds as String] as? [String:Any],
                  let rect=CGRect(dictionaryRepresentation:raw as CFDictionary),rect.width>1,rect.height>1 else {return nil}
            return Surface(id:id,pid:owner,rect:rect,layer:layer)
        }
        if pid != previousPID || now-sampled>=0.2 || !windows.contains(where:{$0.id==cachedID}) {
            previousPID=pid;sampled=now
            cachedID=WindowFocusPolicy.windowID(in:windows,frontPID:pid,focusedBounds:pid.flatMap{focusedBounds($0)})
        }
        return cachedID
    }
    private func focusedBounds(_ pid:Int32) -> CGRect? {
        // Never request a new permission just to determine focus.
        guard AXIsProcessTrusted() else {return nil}
        let app=AXUIElementCreateApplication(pid)
        AXUIElementSetMessagingTimeout(app,0.05)
        var value:CFTypeRef?
        guard AXUIElementCopyAttributeValue(app,kAXFocusedWindowAttribute as CFString,&value) == .success,
              let value,CFGetTypeID(value)==AXUIElementGetTypeID() else {return nil}
        let window=value as! AXUIElement
        var position:CFTypeRef?,size:CFTypeRef?
        guard AXUIElementCopyAttributeValue(window,kAXPositionAttribute as CFString,&position) == .success,
              AXUIElementCopyAttributeValue(window,kAXSizeAttribute as CFString,&size) == .success,
              let position,let size,CFGetTypeID(position)==AXValueGetTypeID(),CFGetTypeID(size)==AXValueGetTypeID() else {return nil}
        var point=CGPoint.zero,extent=CGSize.zero
        guard AXValueGetValue(position as! AXValue,.cgPoint,&point),AXValueGetValue(size as! AXValue,.cgSize,&extent) else {return nil}
        return CGRect(origin:point,size:extent)
    }
}
