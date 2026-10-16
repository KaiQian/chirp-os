import AppKit
import BirdingCore

// Tests native image conversion and controller admission without saving terminal pixels.
final class InteriorVerification {
    static func live(to folder:URL) {
        let d=DesktopController();d.automaticPopulation=false;d.start()
        var checks:[String:Bool]=[:]
        DispatchQueue.main.asyncAfter(deadline:.now()+2.5) {
            let hosts=d.surfaces.filter{!$0.rails.isEmpty}
            checks["realITermBarsDiscovered"] = !hosts.isEmpty
            checks["nativeHeadersHaveBlankSpans"] = hosts.contains{$0.rails.contains{$0.kind == .paneBar}}
            let bird=Bird(position:.zero,fraction:0.5)
            var chosen:PerchChoice?
            for host in hosts {
                for rail in host.rails where rail.kind == .paneBar {
                    for screen in d.screenRects {
                        if let range=Geometry.railRanges(rail,on:host,surfaces:d.surfaces,screen:screen,scale:d.spriteScale(for:bird)).first {
                            chosen=PerchChoice(host:host,edge:.rail,screen:screen,scale:d.spriteScale(for:bird),range:range,railID:rail.id)
                        }
                    }
                }
            }
            if let choice=chosen {
                let x=(choice.range.lowerBound+choice.range.upperBound)/2
                bird.edge = .rail;bird.railID=choice.railID;bird.fraction=choice.fraction(at:x)
                bird.perch(on:choice.host,spriteScale:d.spriteScale(for:bird));d.birds=[bird]
                checks["realPaneBarFootMatchesNativeGeometry"] = abs(bird.position.y-choice.foot(at:x).y)<0.001
            } else {checks["realPaneBarFootMatchesNativeGeometry"]=false}
            DispatchQueue.main.asyncAfter(deadline:.now()+1.5) {
                checks["realPaneIdentitySurvivesResampling"] = bird.state == .perched && bird.edge == .rail && bird.hostID != nil
                let ids=Set((CGWindowListCopyWindowInfo([.optionOnScreenOnly,.excludeDesktopElements],kCGNullWindowID) as? [[String:Any]] ?? []).compactMap{$0[kCGWindowNumber as String] as? Int})
                checks["realPaneBirdOverlayIsOnScreen"] = d.views.contains{$0.desktopRect.intersects(d.bounds(of:bird)) && ($0.window.map{ids.contains($0.windowNumber)} ?? false)}
                let report:[String:Any] = ["passed":checks.values.allSatisfy{$0},"checks":checks,"source":d.interiorPerches.status,
                    "hosts":hosts.map{["id":$0.id,"rails":$0.rails.map{["kind":$0.kind.rawValue,"rect":NSStringFromRect($0.rect)]}]},
                    "bird":["x":bird.position.x,"y":bird.position.y,"state":bird.state.rawValue]]
                try? FileManager.default.createDirectory(at:folder,withIntermediateDirectories:true)
                saveJSON(report,to:folder.appendingPathComponent("report.json"))
                print("Live iTerm perches: \(checks.values.allSatisfy{$0} ? "PASS":"FAIL") — \(checks.count) checks")
                exit(checks.values.allSatisfy{$0} ? 0:1)
            }
        }
    }
    static func run(to folder:URL,imagePath:String?) {
        var checks:[String:Bool]=[:]
        let w=800,h=600
        let ctx=CGContext(data:nil,width:w,height:h,bitsPerComponent:8,bytesPerRow:w*4,
                          space:CGColorSpaceCreateDeviceRGB(),bitmapInfo:CGImageAlphaInfo.premultipliedLast.rawValue)!
        // Draw in top-down window coordinates.
        ctx.translateBy(x:0,y:CGFloat(h));ctx.scaleBy(x:1,y:-1)
        ctx.setFillColor(NSColor.black.cgColor);ctx.fill(CGRect(x:0,y:0,width:w,height:h))
        for y in [0,320] {
            ctx.setFillColor(NSColor(white:0.7,alpha:1).cgColor);ctx.fill(CGRect(x:0,y:y,width:w,height:22))
            ctx.setFillColor(NSColor(white:0.2,alpha:1).cgColor);ctx.fill(CGRect(x:12,y:y+6,width:110,height:10))
        }
        let rails=InteriorPerches.detect(ctx.makeImage()!,size:CGSize(width:w,height:h))
        checks["nativeImageConversionPreservesBarCoordinates"]=rails.count==2 && rails.contains{$0.kind == .titlebar && $0.rect.minY==22} && rails.contains{$0.kind == .paneBar && $0.rect.minY==320}
        let d=DesktopController();d.automaticPopulation=false
        let screen=d.screenRects[0]
        let host=Surface(id:88,rect:screen,isFocused:true,rails:rails)
        d.surfaces=[host]
        let bird=Bird(position:CGPoint(x:screen.midX,y:screen.midY),fraction:0.5)
        checks["focusedFullscreenCanChooseInteriorPerch"] = d.chooseDestination(bird) && bird.edge == .rail && bird.hostID==host.id && bird.railID != nil
        if bird.hostID != nil {
            bird.tick(bird.flightDuration);bird.tick(0.43)
            checks["interiorArrivalLandsOnDetectedBar"]=bird.state == .perched && abs(bird.position.y-(screen.minY+320))<0.001
            // Render the real sprite layer on the detected synthetic pane bar.
            // This artifact contains a test window only, never terminal content.
            d.birds=[bird]
            let view=DesktopView(frame:CGRect(x:0,y:0,width:w,height:h))
            view.controller=d;view.desktopRect=CGRect(origin:screen.origin,size:CGSize(width:w,height:h))
            view.updateSprites();view.layer?.render(in:ctx)
            try? FileManager.default.createDirectory(at:folder,withIntermediateDirectories:true)
            if let preview=ctx.makeImage() {
                try? NSBitmapImageRep(cgImage:preview).representation(using:.png,properties:[:])?.write(to:folder.appendingPathComponent("interior-perch.png"))
            }
            let before=bird.position
            let replacement=Surface(id:88,rect:screen,isFocused:true)
            bird.updateHost(surfaces:[replacement],sampleDT:0.03)
            checks["barDisappearanceReleasesControllerBird"]=bird.state == .flying && bird.hostID==nil && bird.position==before
        }
        var inspected:[[String:Any]]=[]
        if let imagePath,let image=NSImage(contentsOfFile:imagePath),let cg=image.cgImage(forProposedRect:nil,context:nil,hints:nil) {
            let factor=CGFloat(Double(argument("--interior-image-scale") ?? "1") ?? 1)
            let size=CGSize(width:CGFloat(cg.width)/factor,height:CGFloat(cg.height)/factor)
            let found=InteriorPerches.detect(cg,size:size)
            inspected=found.map {["kind":$0.kind.rawValue,"rect":NSStringFromRect($0.rect)]}
            checks["referenceImageHasUpperAndMiddleBar"]=found.contains{$0.rect.minY<100} && found.contains{$0.rect.minY>size.height*0.4 && $0.rect.minY<size.height*0.7}
        } else if imagePath != nil {checks["referenceImageReadable"]=false}
        let passed=checks.values.allSatisfy{$0} && checks.count>=4
        try? FileManager.default.createDirectory(at:folder,withIntermediateDirectories:true)
        saveJSON(["passed":passed,"checks":checks,"detectedReferenceBars":inspected,"capturePermission":CGPreflightScreenCaptureAccess()],to:folder.appendingPathComponent("report.json"))
        print("Interior perches: \(passed ? "PASS":"FAIL") — \(checks.count) checks")
        exit(passed ? 0:1)
    }
}
