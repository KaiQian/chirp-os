import Foundation
import CoreGraphics

public struct PerchChoice {
    public let host:Surface
    public let edge:PerchEdge
    public let screen:CGRect
    public let scale:CGFloat
    public let range:ClosedRange<CGFloat>
    public let railID:String?
    public init(host:Surface,edge:PerchEdge,screen:CGRect,scale:CGFloat,range:ClosedRange<CGFloat>,railID:String? = nil) {
        self.host=host;self.edge=edge;self.screen=screen;self.scale=scale;self.range=range;self.railID=railID
    }
    public func fraction(at coordinate:CGFloat) -> CGFloat {
        if edge.isSide { return (coordinate-host.rect.minY-42)/(host.rect.height-84) }
        let rect=edge == .rail ? (host.rails.first{$0.id==railID}?.rect(on:host) ?? host.rect) : (edge == .bottom ? host.rect.intersection(screen) : host.rect)
        let start=Geometry.perchX(0,rect:rect),end=Geometry.perchX(1,rect:rect)
        return (coordinate-start)/(end-start)
    }
    public func foot(at coordinate:CGFloat) -> CGPoint {
        Geometry.foot(on:host,fraction:fraction(at:coordinate),edge:edge,scale:scale,screen:screen,railID:railID)
    }
}

public enum FlockPhase { case independent, gathering, dispersing }

// A low-frequency social clock, independent of each bird's animation clock.
// Pair requests are consumed only after admission, so unavailable perches cannot spawn bursts.
public final class FlockCoordinator {
    public static let maximumPerSpecies=2
    public static func canAdmit(_ id:SpeciesID,residents:[Bird])->Bool {
        // Departing sprites count until they have actually left the desktop.
        residents.filter{$0.profile.id==id}.count<maximumPerSpecies
    }
    public func cancelCompanion() {companion=nil}
    public private(set) var phase:FlockPhase = .independent
    public private(set) var remaining:Double
    private var companion:(species:SpeciesID,group:UUID,remaining:Double)?
    private var companionDelay:Double = 0
    private var gatheringGroup:UUID?
    public var companionReady:Bool { companion != nil && companionDelay<=0 }
    public init(initialDelay:Double = 60) { remaining=initialDelay }
    public func departureCandidate(residents:[Bird], force:Bool = false, unit:Double = Double.random(in:0..<1)) -> Bird? {
        let eligible=residents.filter{!$0.isDeparting && (force || $0.visitAge >= ($0.groupID == nil ? 20:45))}
        let singles=eligible.filter{$0.groupID==nil}
        let candidates=singles.isEmpty ? eligible:singles
        guard !candidates.isEmpty else {return nil}
        return candidates[min(candidates.count-1,Int(max(0,min(1,unit))*Double(candidates.count)))]
    }
    public func prepareArrival(_ bird:Bird, residents:[Bird]) {
        if let pending=companion, residents.contains(where:{!$0.isDeparting && $0.groupID==pending.group}) {
            if bird.profile.id==pending.species {bird.groupID=pending.group}
        }
    }
    public func arrivalSpecies(default id:SpeciesID, residents:[Bird]) -> SpeciesID {
        guard let pending=companion, Self.canAdmit(pending.species,residents:residents), residents.contains(where:{!$0.isDeparting && $0.groupID==pending.group}) else {companion=nil;return id}
        companionDelay=3
        return pending.species
    }
    public func didArrive(_ bird:Bird, residents:[Bird], capacity:Int, unit:Double = Double.random(in:0..<1)) {
        if let pending=companion, bird.groupID==pending.group {companion=nil;return}
        guard residents.filter({$0.profile.id==bird.profile.id}).count<Self.maximumPerSpecies, phase != .dispersing, residents.filter({!$0.isDeparting}).count<capacity, unit<0.3 else {return}
        let group=UUID();bird.groupID=group;bird.leadsGroup=true
        companion=(bird.profile.id,group,25)
        companionDelay=3
    }
    public func tick(_ dt:Double, residents:[Bird], random:()->Double = {Double.random(in:0..<1)}) {
        let elapsed=max(0,dt)
        companionDelay-=elapsed
        if let pending=companion {
            companion=pending.remaining>elapsed && residents.contains(where:{!$0.isDeparting && $0.groupID==pending.group}) ? (pending.species,pending.group,pending.remaining-elapsed) : nil
        }
        remaining-=elapsed
        guard remaining<=0 else {return}
        let birds=residents.filter{!$0.isDeparting}
        switch phase {
        case .independent:
            phase = .gathering;remaining=30+random()*25
            // Prefer an actual same-species pair, even when other species outnumber it.
            let paired=birds.filter { candidate in birds.contains {$0 !== candidate && $0.profile.id==candidate.profile.id} }
            let mixed=paired.isEmpty && birds.count>=2 && random()<0.05
            let candidates=paired.isEmpty ? (mixed ? birds:[]) : paired
            guard !candidates.isEmpty else {phase = .independent;remaining=60+random()*60;return}
            let leader=candidates[min(candidates.count-1,Int(random()*Double(candidates.count)))]
            let group=leader.groupID ?? UUID();leader.groupID=group;leader.leadsGroup=true;gatheringGroup=group
            let followers=birds.filter{$0 !== leader && (mixed || $0.profile.id==leader.profile.id)}.sorted {
                ($0.groupID==group ? 0:($0.profile.id==leader.profile.id ? 1:2)) < ($1.groupID==group ? 0:($1.profile.id==leader.profile.id ? 1:2))
            }.prefix(1)
            for (i,bird) in followers.enumerated() {
                bird.groupID=group;bird.leadsGroup=false;bird.scheduleSocialMove(after:1+Double(i)*3+random()*2)
            }
        case .gathering:
            phase = .dispersing;remaining=20+random()*15;companion=nil
            for (i,bird) in birds.filter({$0.groupID==gatheringGroup}).enumerated() {
                bird.groupID=nil;bird.leadsGroup=false;bird.scheduleSocialMove(after:0.5+Double(i)*2+random())
            }
        case .dispersing:
            phase = .independent;remaining=60+random()*60
        }
    }
    public func choose(_ options:[PerchChoice], for bird:Bird, residents:[Bird], random:()->Double = {Double.random(in:0..<1)}) -> (choice:PerchChoice,coordinate:CGFloat)? {
        guard !options.isEmpty else {return nil}
        var choices=options
        let peers=residents.filter{$0 !== bird && !$0.isDeparting && $0.groupID==bird.groupID && $0.hostID != nil}
        if bird.groupID != nil, let peer=peers.first(where:{$0.leadsGroup}) ?? peers.first {
            let nearby=choices.filter{$0.host.id==peer.hostID && $0.edge==peer.edge && $0.railID==peer.railID}
            if !nearby.isEmpty {
                let first=nearby[0],peerScale=first.scale*peer.profile.relativeScale/bird.profile.relativeScale
                let point=Geometry.foot(on:first.host,fraction:peer.fraction,edge:peer.edge,scale:peerScale,screen:peer.bottomViewport,railID:peer.railID)
                let direction:CGFloat=random()<0.5 ? -1:1
                let desired:CGFloat=(first.edge.isSide ? point.y:point.x)+direction*(58*max(first.scale,peerScale)+24)
                let best:PerchChoice=nearby.min { a,b in
                    abs(min(a.range.upperBound,max(a.range.lowerBound,desired))-desired) < abs(min(b.range.upperBound,max(b.range.lowerBound,desired))-desired)
                }!
                let coordinate:CGFloat=min(best.range.upperBound,max(best.range.lowerBound,desired))
                return (choice:best,coordinate:coordinate)
            }
        }
        if phase == .dispersing {
            let elsewhere=choices.filter{$0.host.id != bird.hostID}
            if !elsewhere.isEmpty {choices=elsewhere}
            func count(_ id:UInt32)->Int { residents.filter{$0 !== bird && !$0.isDeparting && $0.hostID==id}.count }
            let least=choices.map{count($0.host.id)}.min()!
            choices=choices.filter{count($0.host.id)==least}
        }
        let total=choices.reduce(CGFloat.zero){$0+$1.range.upperBound-$1.range.lowerBound}
        guard total>0 else {return nil}
        var ticket=CGFloat(min(1-Double.ulpOfOne,max(0,random())))*total
        for choice in choices {
            let length=choice.range.upperBound-choice.range.lowerBound
            if ticket<length {return (choice,choice.range.lowerBound+ticket)}
            ticket-=length
        }
        return nil
    }
}
