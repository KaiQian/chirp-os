import AppKit
import BirdingCore

// Exercise admission and departure through the real controller with a fixed scene.
enum PerchingVerification {
    static func run(to folder:URL) {
        let d=DesktopController()
        var checks:[String:Bool]=[:]
        d.settings.probabilities.adjust(at:0,to:10_000)
        d.bringInBird()
        checks["noPerchDoesNotSpawnCirclingBirds"]=d.birds.isEmpty && d.arrivalCount==0
        let screen=d.screenRects[0]
        let host=Surface(id:1,rect:CGRect(x:screen.minX+60,y:screen.minY+180,width:min(600,screen.width-120),height:250))
        // A short foreground panel leaves only a 3-point strip of the rear window.
        let front=Surface(id:2,rect:CGRect(x:host.rect.minX,y:host.rect.minY+3,width:host.rect.width,height:80))
        d.surfaces=[front,host]
        d.bringInBird()
        checks["backgroundStripReservesPerchBeforeArrival"]=d.birds.count==1 && d.birds.first?.hostID==host.id && d.arrivalCount==1
        if let bird=d.birds.first {
            checks["arrivalStillStartsOutsideDisplays"] = !d.displayRects.contains{$0.intersects(d.bounds(of:bird))}
            bird.tick(bird.flightDuration);bird.tick(0.43)
            checks["backgroundArrivalLandsBehindForeground"]=bird.state == .perched && bird.depthID==host.id && bird.blockers(in:d.surfaces)==[front.rect]
            d.surfaces=[Surface(id:2,rect:CGRect(x:host.rect.minX,y:host.rect.minY,width:host.rect.width,height:80)),host]
            let position=bird.position
            bird.perchDuration=0
            d.updateBirds(0)
            checks["noRemainingPerchDepartsWithoutTeleporting"]=bird.isDeparting && bird.position==position && !bird.needsDestination
        }
        let searching=Bird(position:CGPoint(x:screen.midX,y:screen.midY),fraction:0.5)
        searching.fly(to:searching.position,host:nil,duration:2)
        searching.tick(12)
        let position=searching.position
        d.birds=[searching];d.surfaces=[host]
        d.updateBirds(0)
        checks["searchTimeoutDepartsEvenWhenPerchesRemain"]=searching.isDeparting && searching.position==position
        d.updateBirds(searching.flightDuration)
        checks["timedOutBirdFinishesOffscreen"]=d.birds.isEmpty && searching.departureFinished
        d.surfaces=[]
        for _ in 0..<20 {d.bringInBird()}
        checks["repeatedFailedArrivalsDoNotChangePopulation"]=d.birds.isEmpty && d.arrivalCount==1
        let full=Surface(id:3,rect:screen)
        d.surfaces=[full];d.bringInBird()
        checks["fullscreenArrivalChoosesBottom"]=d.birds.count==1 && d.birds.first?.edge == .bottom && d.birds.first?.hostID==full.id
        if let leader=d.birds.first {
            leader.tick(leader.flightDuration);leader.tick(0.43)
            let visible=Geometry.visiblePieces(Geometry.landingFootprint(at:leader.position,scale:d.spriteScale(for:leader)),blockers:leader.blockers(in:d.surfaces))
            checks["fullscreenBottomFeetMeetEdgeWithTailMasked"]=abs(leader.position.y-screen.maxY)<0.001 && !visible.isEmpty && visible.allSatisfy {screen.contains($0)}
            leader.groupID=nil
            d.flock.didArrive(leader,residents:d.birds,capacity:d.population.range.upper,unit:0)
            d.bringInBird()
            if d.birds.count==2 {
                let mate=d.birds[1];mate.tick(mate.flightDuration);mate.tick(0.43)
                checks["pairedArrivalSharesSpeciesAndGroup"]=mate.profile.id==leader.profile.id && mate.groupID==leader.groupID && mate.groupID != nil
                checks["pairedArrivalUsesNearbyNonoverlappingPerch"]=abs(mate.position.x-leader.position.x)<150 && !d.bounds(of:mate).intersects(d.bounds(of:leader))
                d.population.setRange(PopulationRange(lower:1,upper:2)!)
                d.bringInBird()
                checks["companionsCannotExceedPopulationLimit"]=d.birds.count==2
                d.population.setRange(PopulationRange(lower:1,upper:5)!)
                for _ in 0..<20 {d.bringInBird()}
                checks["sameSpeciesNeverAdmitsThirdEvenBelowTotalLimit"]=d.birds.count==2
                d.flock.tick(60,residents:d.birds,random:{0})
                d.updateBirds(1)
                checks["gatheringMovesFollowerWhileLeaderStays"]=leader.state == .perched && mate.state == .flying && mate.hostID==full.id
                var focused=full;focused.isFocused=true;d.surfaces=[focused]
                d.flock.prepareFocusReactions(residents:d.birds,surfaces:d.surfaces,random:{0.5})
                for bird in d.birds {bird.updateHost(surfaces:d.surfaces,sampleDT:0.03)}
                checks["focusWaitsForPerchedBirdButAvoidsIncomingImmediately"]=leader.state == .perched && leader.focusReactionDelay != nil && mate.state == .flying && mate.hostID==nil
                for bird in d.birds {bird.tick(1.3)}
                checks["focusEvictsBothPerchedAndIncomingBottomBirds"]=d.birds.allSatisfy{$0.state == .flying && $0.hostID==nil}
                checks["focusedBottomCannotBeChosenAgain"] = !d.chooseDestination(leader)
            }
        }
        let passed=checks.count==18 && checks.values.allSatisfy{$0}
        try? FileManager.default.createDirectory(at:folder,withIntermediateDirectories:true)
        saveJSON(["passed":passed,"checks":checks],to:folder.appendingPathComponent("report.json"))
        print("Perching controller: \(passed ? "PASS":"FAIL") — \(checks.count) checks")
        exit(passed ? 0:1)
    }
}
