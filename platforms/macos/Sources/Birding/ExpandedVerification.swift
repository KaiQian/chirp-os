import AppKit
import BirdingCore

enum ExpandedVerification {
    static func run(to folder:URL) {
        do {
            try FileManager.default.createDirectory(at:folder,withIntermediateDirectories:true)
            let d=DesktopController()
            let host=Surface(id:1,rect:CGRect(x:120,y:300,width:620,height:330))
            d.surfaces=[host]
            let specs:[(SpeciesID,CGFloat,Double)]=[(.nightHeron,230,12),(.plumbeousWaterRedstart,430,2.3),(.littleEgret,620,0)]
            for (id,x,age) in specs {
                let b=Bird(position:.zero,fraction:0.5,profile:d.catalog.profile(id));b.perch(on:host);b.position.x=x;b.tick(age);d.birds.append(b)
            }
            let wood=Bird(position:.zero,fraction:0.5,profile:d.catalog.profile(.greatSpottedWoodpecker))
            wood.edge = .left;wood.perch(on:host);wood.tick(4.2);d.birds.append(wood)
            let window=OverlayPanel(contentRect:CGRect(x:200,y:150,width:840,height:690),styleMask:[.borderless,.nonactivatingPanel],backing:.buffered,defer:false)
            window.ignoresMouseEvents=true;window.isOpaque=false;window.backgroundColor = .clear
            let view=DesktopView(frame:CGRect(x:0,y:0,width:840,height:690));view.controller=d;view.desktopRect=view.bounds
            window.contentView=view;window.orderFrontRegardless()
            var checks:[String:Bool]=[:]
            let bird=d.birds[0],s=d.spriteScale(for:d.birds[0]),art=d.arts[.nightHeron]!
            let opaque=(0..<48*48).first{art.contains(frame:bird.frameName,x:$0%48,y:$0/48)}!
            let point=CGPoint(x:bird.position.x+(CGFloat(opaque%48)+0.5-29)*s,y:bird.position.y+(CGFloat(opaque/48)+0.5-39)*s)
            d.updateHover(now:0,at:point);d.updateHover(now:0.99,at:point);checks["delayedHover"]=d.hoveredBird == nil
            d.updateHover(now:1,at:point);checks["visiblePixelName"]=d.hoveredBird === bird
            view.updateSprites();try SettingsVerification.snapshot(window,to:folder.appendingPathComponent("birds-and-hover.png"))
            d.surfaces.insert(Surface(id:2,rect:CGRect(x:point.x-2,y:point.y-2,width:4,height:4)),at:0)
            d.updateHover(now:4,at:point);checks["occludedPixelResetsHover"]=d.hoveredBird == nil
            d.surfaces=[host]
            d.updateHover(now:8,at:CGPoint(x:bird.position.x-29*s+0.1,y:bird.position.y-39*s+0.1))
            checks["transparentPixelNotHit"]=d.hoveredBird == nil
            checks["overlayPassesInput"]=window.ignoresMouseEvents && !window.canBecomeKey && !window.canBecomeMain
            d.birds[0].tick(19.4);checks["nightHeronDropping"]=d.birds[0].frameName.hasPrefix("poop")
            view.updateSprites();try SettingsVerification.snapshot(window,to:folder.appendingPathComponent("night-heron-action.png"))
            window.orderOut(nil)
            saveJSON(["passed":checks.values.allSatisfy{$0},"checks":checks],to:folder.appendingPathComponent("report.json"))
            print("Expanded bird UI: \(checks.values.allSatisfy{$0} ? "PASS":"FAIL") — \(checks.count) checks")
            exit(checks.values.allSatisfy{$0} ? 0:1)
        } catch {print(error);exit(1)}
    }
}
