import Foundation
import CoreGraphics

public struct Surface: Equatable {
    public let id: UInt32
    public let pid: Int32
    public var rect: CGRect // Quartz desktop coordinates: y grows downward.
    public let layer: Int
    public var rails: [PerchRail]
    public var isFocused: Bool
    public init(id: UInt32, pid: Int32 = 0, rect: CGRect, layer: Int = 0, isFocused: Bool = false, rails:[PerchRail] = []) {
        self.id = id; self.pid = pid; self.rect = rect; self.layer = layer; self.isFocused=isFocused;self.rails=rails
    }
}

public enum Geometry {
    // Sequential subtraction, not even-odd clipping: overlapping occluders stay opaque.
    public static func subtract(_ rect: CGRect, _ blocker: CGRect) -> [CGRect] {
        let cut = rect.intersection(blocker)
        guard !cut.isNull, !cut.isEmpty else { return [rect] }
        return [CGRect(x: rect.minX, y: rect.minY, width: rect.width, height: cut.minY - rect.minY),
                CGRect(x: rect.minX, y: cut.maxY, width: rect.width, height: rect.maxY - cut.maxY),
                CGRect(x: rect.minX, y: cut.minY, width: cut.minX - rect.minX, height: cut.height),
                CGRect(x: cut.maxX, y: cut.minY, width: rect.maxX - cut.maxX, height: cut.height)]
            .filter { $0.width > 0 && $0.height > 0 }
    }
    public static func visiblePieces(_ rect: CGRect, blockers: [CGRect]) -> [CGRect] {
        blockers.reduce([rect]) { pieces, blocker in pieces.flatMap { subtract($0, blocker) } }
    }
    // Reserve the whole sprite between birds, including the tail and either facing direction.
    public static func landingFootprint(at foot: CGPoint, scale: CGFloat) -> CGRect {
        CGRect(x: foot.x - 29*scale, y: foot.y - 39*scale, width: 58*scale, height: 48*scale)
    }
    // Background window strips need room for the body and feet. The tail below
    // the edge may be naturally masked by a foreground window after landing.
    public static func landingClearance(at foot: CGPoint, scale: CGFloat) -> CGRect {
        CGRect(x: foot.x - 29*scale, y: foot.y - 39*scale, width: 58*scale, height: 39*scale + 1)
    }
    public static func isLandingVisible(on hostID: UInt32, at foot: CGPoint,
                                        surfaces: [Surface], scale: CGFloat, edge: PerchEdge = .top) -> Bool {
        guard let depth = surfaces.firstIndex(where: { $0.id == hostID }) else { return false }
        let area = !edge.isSide ? landingClearance(at: foot, scale: scale) : landingFootprint(at: foot, scale: scale)
        return !surfaces.prefix(depth).contains {
            !$0.rect.intersection(area).isEmpty && !$0.rect.intersection(area).isNull
        }
    }
    // Continuous foot-position intervals, clipped by screens, occluders and reservations.
    public static func landingRanges(on host: Surface, surfaces: [Surface], screen: CGRect,
                                     scale: CGFloat, occupied: [CGRect] = []) -> [ClosedRange<CGFloat>] {
        horizontalRanges(on:host,rect:host.rect,y:host.rect.minY,surfaces:surfaces,screen:screen,scale:scale,occupied:occupied,allowTailMask:true)
    }
    // The frontmost window covering the work area gets a virtual bottom perch
    // when its real top edge has no headroom. Popups still mask the bird normally.
    public static func isBottomHost(_ host:Surface, surfaces:[Surface], screen:CGRect, scale:CGFloat) -> Bool {
        guard !host.isFocused else {return false}
        let front=surfaces.first { s in
            s.layer == 0 && s.rect.minX <= screen.minX+8 && s.rect.maxX >= screen.maxX-8 &&
            s.rect.minY <= screen.minY+8 && s.rect.maxY >= screen.maxY-8
        }
        return front?.id == host.id && host.rect.minY-39*scale < screen.minY
    }
    public static func bottomRanges(on host:Surface, surfaces:[Surface], screen:CGRect,
                                    scale:CGFloat, occupied:[CGRect] = []) -> [ClosedRange<CGFloat>] {
        guard isBottomHost(host,surfaces:surfaces,screen:screen,scale:scale) else { return [] }
        let rect=host.rect.intersection(screen)
        let y=foot(on:host,fraction:0.5,edge:.bottom,scale:scale,screen:screen).y
        return horizontalRanges(on:host,rect:rect,y:y,surfaces:surfaces,screen:screen,scale:scale,occupied:occupied,allowTailMask:true,clipTailAtBoundary:true)
    }
    static func horizontalRanges(on host:Surface, rect:CGRect, y:CGFloat, surfaces:[Surface], screen:CGRect,
                                         scale:CGFloat, occupied:[CGRect], allowTailMask:Bool, clipTailAtBoundary:Bool = false) -> [ClosedRange<CGFloat>] {
        guard let depth = surfaces.firstIndex(where: { $0.id == host.id }) else { return [] }
        let half = 29 * scale
        guard y - 39 * scale >= screen.minY, y + (clipTailAtBoundary ? 0 : 9 * scale) <= screen.maxY else { return [] }
        let lo = max(perchX(0, rect: rect), screen.minX + half)
        let hi = min(perchX(1, rect: rect), screen.maxX - half)
        guard hi > lo else { return [] }
        var ranges = [lo...hi]
        let blockers = surfaces.prefix(depth).map { ($0.rect, y + (allowTailMask ? 1 : 9*scale)) } + occupied.map { ($0, y + 9*scale) }
        for (rect, bottom) in blockers {
            guard rect.maxY > y - 39 * scale, rect.minY < bottom else { continue }
            let left = rect.minX - half, right = rect.maxX + half
            ranges = ranges.flatMap { range -> [ClosedRange<CGFloat>] in
                if right <= range.lowerBound || left >= range.upperBound { return [range] }
                var result: [ClosedRange<CGFloat>] = []
                if left > range.lowerBound { result.append(range.lowerBound...left) }
                if right < range.upperBound { result.append(right...range.upperBound) }
                return result
            }
        }
        return ranges.filter { $0.upperBound - $0.lowerBound > 0.01 }
    }
    public static func foot(on host:Surface, fraction:CGFloat, edge:PerchEdge, scale:CGFloat = 1, screen:CGRect? = nil, railID:String? = nil) -> CGPoint {
        if edge == .rail, let rail=host.rails.first(where:{$0.id==railID}) {
            let rect=rail.rect(on:host)
            return CGPoint(x:perchX(fraction,rect:rect),y:rect.minY)
        }
        if edge == .top { return CGPoint(x:perchX(fraction,rect:host.rect),y:host.rect.minY) }
        if edge == .bottom {
            let rect=screen.map{host.rect.intersection($0)} ?? host.rect
            return CGPoint(x:perchX(fraction,rect:rect),y:rect.maxY)
        }
        return CGPoint(x:edge == .left ? host.rect.minX:host.rect.maxX,
                       y:host.rect.minY+42+max(0,host.rect.height-84)*min(1,max(0,fraction)))
    }
    public static func sideRanges(on host:Surface, edge:PerchEdge, surfaces:[Surface], screen:CGRect,
                                  scale:CGFloat, occupied:[CGRect]) -> [ClosedRange<CGFloat>] {
        guard let depth=surfaces.firstIndex(where:{$0.id==host.id}) else { return [] }
        let x=edge == .left ? host.rect.minX:host.rect.maxX
        guard x-29*scale >= screen.minX, x+29*scale <= screen.maxX else { return [] }
        let lo=max(host.rect.minY+42,screen.minY+39*scale)
        let hi=min(host.rect.maxY-42,screen.maxY-9*scale)
        guard hi>lo else { return [] }
        var ranges=[lo...hi]
        for r in surfaces.prefix(depth).map(\.rect)+occupied {
            guard r.maxX>x-29*scale, r.minX<x+29*scale else {continue}
            let a=r.minY-9*scale,b=r.maxY+39*scale
            ranges=ranges.flatMap { q -> [ClosedRange<CGFloat>] in
                if b<=q.lowerBound || a>=q.upperBound {return [q]}
                var result:[ClosedRange<CGFloat>]=[]
                if a>q.lowerBound {result.append(q.lowerBound...a)}
                if b<q.upperBound {result.append(b...q.upperBound)}
                return result
            }
        }
        return ranges.filter{$0.upperBound-$0.lowerBound>0.01}
    }
    public static func quartz(_ cocoa: CGRect, primaryHeight: CGFloat) -> CGRect {
        CGRect(x: cocoa.minX, y: primaryHeight - cocoa.maxY, width: cocoa.width, height: cocoa.height)
    }
    public static func distance(_ a: CGPoint, _ b: CGPoint) -> CGFloat { hypot(a.x-b.x, a.y-b.y) }
    public static func perchX(_ fraction: CGFloat, rect: CGRect) -> CGFloat {
        let margin = min(42, rect.width / 3)
        return rect.minX + margin + max(0, rect.width - margin * 2) * min(1, max(0, fraction))
    }
}

public enum PerchEdge {
    case top, bottom, left, right, rail
    public var isSide: Bool { self == .left || self == .right }
}

public enum BirdState: String { case flying, landing, perched }
public final class Bird {
    public static let flightSpeedMultiplier: Double = 2
    public static let maximumSearchDuration: Double = 12
    public private(set) var searchTime: Double = 0
    public private(set) var visitAge: Double = 0
    public var searchExpired: Bool { !isDeparting && state == .flying && searchTime >= Self.maximumSearchDuration }
    public private(set) var isDeparting = false
    public var edge: PerchEdge = .top
    public var bottomViewport: CGRect?
    public var railID: String?
    public var groupID: UUID?
    public var leadsGroup = false
    public private(set) var socialMoveDelay: Double?
    private var socialMoveRequested = false
    public let profile: SpeciesProfile
    public var position: CGPoint
    public var state: BirdState = .flying
    public var hostID: UInt32?
    public var depthID: UInt32?
    public var fraction: CGFloat
    public var facingRight = true
    public private(set) var stateTime: Double = 0
    public var flightDuration: Double = 1.5
    public var perchDuration: Double = 15
    public private(set) var startledCount = 0
    public private(set) var landedCount = 0
    public private(set) var followedDistance: CGFloat = 0
    private var previousHost: CGRect?
    private var origin: CGPoint
    private var target: CGPoint
    private var arc: CGFloat = 90
    private var flightAge: Double = 0
    private var destinationInvalidated = false
    public init(position: CGPoint, fraction: CGFloat, profile: SpeciesProfile = SpeciesCatalog.standard.profile(.redWhiskeredBulbul)) {
        self.profile = profile
        self.perchDuration = Double.random(in: profile.perchMin...profile.perchMax)
        self.position = position; self.origin = position; self.target = position; self.fraction = fraction
    }
    // Duration is the original route timing; the multiplier halves travel time only.
    // Landing and idle clocks keep their natural timing.
    public func fly(to point: CGPoint, host: Surface?, duration: Double = 3, arc: CGFloat = 90) {
        isDeparting = false
        origin = position; target = point; hostID = host?.id; depthID = nil
        previousHost = nil; flightDuration = max(0.3, duration) / (Self.flightSpeedMultiplier * profile.speed); self.arc = arc
        flightAge = 0; stateTime = 0; state = .flying; destinationInvalidated = false
        socialMoveRequested = false; socialMoveDelay = nil
    }
    public func depart(to point: CGPoint, duration: Double) {
        fly(to: point, host: nil, duration: duration, arc: 30)
        isDeparting = true
    }
    public var departureFinished: Bool { isDeparting && flightAge >= flightDuration }
    public func perch(on host: Surface, spriteScale:CGFloat = 1) {
        hostID = host.id; depthID = host.id; previousHost = host.rect
        position = Geometry.foot(on:host,fraction:fraction,edge:edge,scale:spriteScale,screen:bottomViewport,railID:railID)
        state = .perched; stateTime = 0; searchTime = 0; destinationInvalidated = false
        socialMoveRequested = false; socialMoveDelay = nil
        if edge.isSide { facingRight = edge == .left }
    }
    public func invalidateDestination() {
        hostID = nil; depthID = nil; previousHost = nil
        if state != .flying { state = .flying; stateTime = 0 }
        destinationInvalidated = true
    }
    public func scheduleSocialMove(after delay:Double) { socialMoveRequested=false; socialMoveDelay = max(0,delay) }
    public func flee() {
        startledCount += 1
        fly(to: CGPoint(x: position.x + (facingRight ? 210 : -210), y: position.y - 100), host: nil, duration: 1.25, arc: 45)
    }
    // Called at the actual metadata sampling interval, independent of animation frames.
    public func updateHost(surfaces: [Surface], sampleDT: Double, spriteScale: CGFloat = 1) {
        guard let id = hostID else { return }
        guard let host = surfaces.first(where: { $0.id == id }) else { flee(); return }
        if edge == .rail {
            guard host.rails.contains(where:{$0.id==railID}) else {flee();return}
        }
        if edge == .bottom {
            if host.isFocused {flee();return}
            guard let viewport=bottomViewport,
                  Geometry.isBottomHost(host,surfaces:surfaces,screen:viewport,scale:spriteScale) else { invalidateDestination(); return }
        }
        let point = Geometry.foot(on:host,fraction:fraction,edge:edge,scale:spriteScale,screen:bottomViewport,railID:railID)
        if (state == .flying || edge == .rail) && !Geometry.isLandingVisible(on: id, at: point, surfaces: surfaces, scale: spriteScale, edge: edge) {
            // Stay exactly where we are until the controller chooses a new route.
            // This is a blocked destination, not a startle or an instantaneous landing.
            invalidateDestination()
            return
        }
        if state != .flying {
            if let old = previousHost {
                let delta = Geometry.distance(host.rect.origin, old.origin)
                // Ignore long sampling gaps (sleep/Space transitions) when estimating velocity.
                if sampleDT < 0.20 && delta > 8 && delta / max(0.016, sampleDT) > 950 {
                    flee(); return
                }
                followedDistance += Geometry.distance(position, point)
            }
            position = point
        } else { target = point }
        previousHost = host.rect
    }
    public func tick(_ dt: Double) {
        if !isDeparting { visitAge+=max(0,dt) }
        if state == .perched, let delay=socialMoveDelay {
            socialMoveDelay=max(0,delay-max(0,dt))
            if socialMoveDelay == 0 { socialMoveDelay=nil; socialMoveRequested=true }
        }
        // Rerouting (even a blocked destination) must not restart the search budget.
        if state == .flying && !isDeparting { searchTime += max(0, dt) }
        guard !destinationInvalidated else { return }
        stateTime += dt
        if state == .flying {
            flightAge += dt
            let t = min(1, flightAge / flightDuration)
            let smooth = t*t*(3-2*t)
            let next = CGPoint(x: origin.x + (target.x-origin.x)*smooth,
                               y: origin.y + (target.y-origin.y)*smooth - sin(t * .pi)*arc)
            if abs(next.x-position.x) > 0.05 { facingRight = next.x > position.x }
            position = next
            if t >= 1 && hostID != nil {
                // Only adopt the host's depth once the feet have reached its top edge.
                depthID = hostID
                state = .landing; stateTime = 0; searchTime = 0; landedCount += 1
                if edge.isSide { facingRight = edge == .left }
            }
        } else if state == .landing && stateTime > 0.42 {
            state = .perched; stateTime = 0
        }
    }
    public var needsDestination: Bool {
        !isDeparting && (socialMoveRequested || destinationInvalidated || (state == .flying && flightAge >= flightDuration && hostID == nil) ||
        (state == .perched && stateTime >= perchDuration))
    }
    public func blockers(in surfaces: [Surface]) -> [CGRect] {
        var result: [CGRect]
        if let depthID, let index = surfaces.firstIndex(where: { $0.id == depthID }) {
            result = surfaces.prefix(index).map(\.rect)
        } else {
            // Every flight is above normal windows; menus / utility panels still cover it.
            result = surfaces.filter { $0.layer > 0 }.map(\.rect)
        }
        // Feet meet the lower edge; the hanging tail disappears behind that edge.
        // Reuse the render/hover occlusion mask so Dock/taskbar pixels stay clear.
        if edge == .bottom, state != .flying, let viewport=bottomViewport {
            result.append(CGRect(x:viewport.minX,y:position.y,width:viewport.width,height:viewport.height))
        }
        return result
    }
    public var hopOffset: CGFloat {
        guard state == .perched, profile.id == .treeSparrow else { return 0 }
        let cycle = stateTime.truncatingRemainder(dividingBy: 9)
        guard cycle > 1, cycle < 2 else { return 0 }
        return -CGFloat(abs(sin((cycle-1)*Double.pi*2))) * 3
    }
    public var frameName: String {
        switch state {
        case .flying: return "fly\(Int(stateTime * profile.flapFPS) % 8)"
        case .landing: if edge.isSide { return "cling0" }; return "land\(min(2, Int(stateTime / 0.14)))"
        case .perched:
            if let frame=SpeciesBehavior.frame(profile.id,age:stateTime,side:edge.isSide) { return frame }
            let cycle = stateTime.truncatingRemainder(dividingBy: 9)
            switch profile.id {
            case .treeSparrow:
                if cycle > 1 && cycle < 2 { return "idle\(Int(cycle*6)%2)" }
            case .spottedDove:
                if cycle > 2 && cycle < 4 { return "idle\(Int(cycle*2.5)%2)" }
            case .chineseBlackbird:
                if cycle > 2 && cycle < 3.2 { return "idle\(Int(cycle*3)%2)" }
            case .magpieRobin:
                if cycle > 1 && cycle < 3.6 { return "idle\(Int(cycle*3.5)%2)" }
            case .longTailedShrike:
                if cycle > 2 && cycle < 5 { return "idle\(Int(cycle*1.2)%2)" }
            default: break
            }
            if cycle > 6.2 && cycle < 7.3 { return "preen\(Int((cycle-6.2)*6) % 2)" }
            if cycle > 3.0 && cycle < 3.18 { return "blink" }
            return Int(stateTime * 1.8) % 2 == 0 ? "stand" : "breathe"
        }
    }
}
