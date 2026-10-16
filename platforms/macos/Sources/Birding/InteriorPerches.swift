import AppKit
import ScreenCaptureKit
import BirdingCore

// Application-specific, optional discovery. Never requests permissions or changes iTerm settings.
// Captures stay in memory; the cache holds only bar coordinates and expires on failure/resize.
final class InteriorPerches {
    private struct Snapshot {let size:CGSize;let rails:[PerchRail];let time:Double}
    private var cache:[UInt32:Snapshot]=[:]
    private var lastSample:Double = -.infinity
    private var capturing=false
    private(set) var status="idle"
    func rails(for host:Surface)->[PerchRail] {
        guard let sample=cache[host.id],sample.size==host.rect.size,
              ProcessInfo.processInfo.systemUptime-sample.time<2.5 else {return []}
        return sample.rails
    }
    func refresh(surfaces:[Surface],enabled:Bool = true) {
        guard enabled else {cache.removeAll();status="disabled";return}
        let now=ProcessInfo.processInfo.systemUptime
        guard !capturing,now-lastSample>=0.75 else {return}
        lastSample=now
        let session=CGSessionCopyCurrentDictionary() as? [String:Any] ?? [:]
        if (session["CGSSessionScreenIsLocked"] as? Bool)==true {cache.removeAll();status="locked";return}
        let itermPIDs=Set(NSRunningApplication.runningApplications(withBundleIdentifier:"com.googlecode.iterm2").map(\.processIdentifier))
        let headerPIDs=Set(["com.google.Chrome","com.electron.lark"].flatMap{NSRunningApplication.runningApplications(withBundleIdentifier:$0).map(\.processIdentifier)})
        let pids=itermPIDs.union(headerPIDs)
        let targets=surfaces.filter{pids.contains($0.pid) && $0.layer==0 && $0.rect.width>=180 && $0.rect.height>=100}
        let ids=Set(targets.map(\.id));cache=cache.filter{ids.contains($0.key)}
        guard !targets.isEmpty else {status="no-supported-window";return}
        capturing=true
        Task { @MainActor [weak self] in
            guard let self else {return}
            defer {self.capturing=false}
            do {
                let native=await Task.detached(priority:.utility) {
                    ITermAccessibility.discover(targets.filter{itermPIDs.contains($0.pid)}).merging(
                        AppHeaderAccessibility.discover(targets.filter{headerPIDs.contains($0.pid)}),uniquingKeysWith:{$1})
                }.value
                for host in targets {
                    if let rails=native[host.id] {self.cache[host.id]=Snapshot(size:host.rect.size,rails:rails,time:ProcessInfo.processInfo.systemUptime)}
                }
                let fallback=targets.filter{native[$0.id]==nil && itermPIDs.contains($0.pid)}
                guard !fallback.isEmpty else {self.status=native.isEmpty ? (AXIsProcessTrusted() ? "layout-unavailable":"permission-required"):"ready-accessibility";return}
                guard CGPreflightScreenCaptureAccess() else {self.status=AXIsProcessTrusted() ? "layout-unavailable":"permission-required";return}
                guard #available(macOS 14.0,*) else {self.status="accessibility-required";return}
                let content=try await SCShareableContent.excludingDesktopWindows(true,onScreenWindowsOnly:true)
                for host in fallback {
                    guard let window=content.windows.first(where:{$0.windowID==host.id}),window.frame.size==host.rect.size else {
                        self.cache[host.id]=nil;continue
                    }
                    let config=SCStreamConfiguration()
                    config.width=max(1,min(640,Int(host.rect.width)))
                    config.height=max(1,Int(host.rect.height));config.showsCursor=false
                    config.ignoreShadowsSingleWindow=true
                    let image=try await SCScreenshotManager.captureImage(contentFilter:SCContentFilter(desktopIndependentWindow:window),configuration:config)
                    let size=host.rect.size
                    let rails=await Task.detached(priority:.utility) {Self.detect(image,size:size)}.value
                    self.cache[host.id]=Snapshot(size:host.rect.size,rails:rails,time:ProcessInfo.processInfo.systemUptime)
                }
                self.status="ready-window-capture"
            } catch {
                self.cache.removeAll();self.status="capture-unavailable"
            }
        }
    }
    static func detect(_ image:CGImage,size:CGSize)->[PerchRail] {
        let w=image.width,h=image.height
        var rgba=[UInt8](repeating:0,count:w*h*4)
        let rendered=rgba.withUnsafeMutableBytes { bytes -> Bool in
            guard let context=CGContext(data:bytes.baseAddress,width:w,height:h,bitsPerComponent:8,bytesPerRow:w*4,
                                        space:CGColorSpaceCreateDeviceRGB(),bitmapInfo:CGImageAlphaInfo.premultipliedLast.rawValue) else {return false}
            context.draw(image,in:CGRect(x:0,y:0,width:w,height:h));return true
        }
        return rendered ? ITermBarDetector.detect(rgba:rgba,width:w,height:h,windowSize:size):[]
    }

}
