import AppKit
import BirdingCore

enum AppHeaderVerification {
    static func run(to folder:URL) {
        let d=DesktopController();d.automaticPopulation=false;d.start()
        var checks:[String:Bool]=[:]
        DispatchQueue.main.asyncAfter(deadline:.now()+3) {
            func hosts(_ bundle:String)->[Surface] {d.surfaces.filter{NSRunningApplication(processIdentifier:$0.pid)?.bundleIdentifier==bundle}}
            let chrome=hosts("com.google.Chrome"),lark=hosts("com.electron.lark")
            let chromeRails=chrome.flatMap(\.rails),larkRails=lark.flatMap(\.rails)
            checks["chromeAddressBlankSpanDiscovered"]=chromeRails.contains{$0.kind == .addressBar}
            checks["chromeBookmarkBlankSpanDiscovered"]=chromeRails.contains{$0.kind == .toolbar}
            checks["larkSidebarBlankSpanDiscovered"]=larkRails.contains{$0.kind == .sidebarHeader}
            checks["larkMessageHeaderBlankSpanDiscovered"]=larkRails.contains{$0.kind == .sectionHeader}
            for (name,targets,kind) in [("chrome",chrome,PerchRail.Kind.addressBar),("lark",lark,PerchRail.Kind.sidebarHeader)] {
                let bird=Bird(position:.zero,fraction:0.5)
                var choice:PerchChoice?
                for host in targets {for rail in host.rails where rail.kind==kind {for screen in d.screenRects {
                    if let range=Geometry.railRanges(rail,on:host,surfaces:d.surfaces,screen:screen,scale:d.spriteScale(for:bird)).first {
                        choice=PerchChoice(host:host,edge:.rail,screen:screen,scale:d.spriteScale(for:bird),range:range,railID:rail.id)
                    }
                }}}
                checks[name+"HeaderOffersVisibleLanding"]=choice != nil
                if let choice {
                    bird.edge = .rail;bird.railID=choice.railID;bird.fraction=choice.fraction(at:(choice.range.lowerBound+choice.range.upperBound)/2)
                    bird.perch(on:choice.host,spriteScale:d.spriteScale(for:bird));d.birds.append(bird)
                }
            }
            DispatchQueue.main.asyncAfter(deadline:.now()+1.8) {
                checks["bothRealHeaderBirdsStayPerchedAfterResampling"]=d.birds.count==2 && d.birds.allSatisfy{$0.edge == .rail && $0.state == .perched && $0.hostID != nil}
                let passed=checks.values.allSatisfy{$0}
                try? FileManager.default.createDirectory(at:folder,withIntermediateDirectories:true)
                saveJSON(["passed":passed,"checks":checks,"source":d.interiorPerches.status,
                    "chrome":chromeRails.map{["kind":$0.kind.rawValue,"rect":NSStringFromRect($0.rect)]},
                    "lark":larkRails.map{["kind":$0.kind.rawValue,"rect":NSStringFromRect($0.rect)]}],to:folder.appendingPathComponent("report.json"))
                print("Live app headers:",passed ? "PASS":"FAIL","—",checks.count,"checks")
                exit(passed ? 0:1)
            }
        }
    }
}
