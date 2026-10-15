import Foundation

public struct HoverTracker<ID:Equatable> {
    public private(set) var target:ID?
    private var started:Double = 0
    public init() {}
    public mutating func update(_ hit:ID?, now:Double) -> ID? {
        guard let hit else {target=nil;return nil}
        if target != hit {target=hit;started=now}
        return now-started >= 1 ? hit:nil
    }
}
