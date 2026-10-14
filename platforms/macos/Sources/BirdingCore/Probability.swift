import Foundation

// Integer hundredths of a percent keep displayed and stored totals exactly 100.00%.
public struct ProbabilityEntry: Codable, Equatable {
    public let id: SpeciesID
    public var points: Int
    public var locked: Bool
}
public struct ProbabilityDistribution: Codable, Equatable {
    public private(set) var entries: [ProbabilityEntry]
    public init(catalog: SpeciesCatalog) {
        let values = Self.apportion(10_000, amounts:catalog.species.map(\.weight))
        entries = zip(catalog.species,values).map { ProbabilityEntry(id:$0.0.id,points:$0.1,locked:false) }
    }
    public var isValid: Bool {
        entries.count == SpeciesID.allCases.count && Set(entries.map(\.id)) == Set(SpeciesID.allCases) &&
        entries.allSatisfy { (0...10_000).contains($0.points) } && entries.reduce(0) { $0+$1.points } == 10_000
    }
    public mutating func setLocked(_ locked:Bool, at index:Int) { entries[index].locked = locked }
    public func maximum(at index:Int) -> Int {
        10_000 - entries.enumerated().filter { $0.offset != index && $0.element.locked }.reduce(0) { $0+$1.element.points }
    }
    public func canAdjust(_ index:Int) -> Bool {
        !entries[index].locked && entries.indices.contains { $0 != index && !entries[$0].locked }
    }
    @discardableResult public mutating func adjust(at index:Int, to requested:Int) -> Int {
        guard canAdjust(index) else { return entries[index].points }
        let value = min(maximum(at:index),max(0,requested))
        let peers = entries.indices.filter { $0 != index && !entries[$0].locked }
        let remainder = maximum(at:index)-value
        let amounts = Self.apportion(remainder,amounts:peers.map { Double(entries[$0].points) })
        entries[index].points = value
        for (peer,amount) in zip(peers,amounts) { entries[peer].points = amount }
        return value
    }
    // Preserve proportions; distribute equally when every eligible peer is zero.
    // Largest remainders receive rounding units, with stable index tie breaking.
    private static func apportion(_ total:Int, amounts:[Double]) -> [Int] {
        guard !amounts.isEmpty else { return [] }
        let sum = amounts.reduce(0,+)
        let exact = amounts.map { sum > 0 ? Double(total)*$0/sum : Double(total)/Double(amounts.count) }
        var result = exact.map { Int($0.rounded(.down)) }
        let order = exact.indices.sorted {
            let a = exact[$0]-Double(result[$0]), b = exact[$1]-Double(result[$1])
            return a == b ? $0 < $1 : a > b
        }
        for i in order.prefix(max(0,total-result.reduce(0,+))) { result[i] += 1 }
        return result
    }
    public func choose(unit:Double = Double.random(in:0..<1)) -> SpeciesID {
        var ticket = Int(min(1-Double.ulpOfOne,max(0,unit.isFinite ? unit : 0))*10_000)
        for entry in entries where entry.points > 0 {
            if ticket < entry.points { return entry.id }; ticket -= entry.points
        }
        return entries.last(where: { $0.points > 0 })!.id
    }
}
public struct BirdSettings: Codable {
    public var catalog: SpeciesCatalog
    public var probabilities: ProbabilityDistribution
    public init(catalog:SpeciesCatalog = .standard) {
        self.catalog = catalog; probabilities = ProbabilityDistribution(catalog:catalog)
    }
    public static func decode(_ data:Data) throws -> BirdSettings {
        let value = try JSONDecoder().decode(Self.self,from:data)
        _ = try SpeciesCatalog.decode(JSONEncoder().encode(value.catalog))
        guard value.probabilities.isValid else { throw NSError(domain:"BirdSettings",code:1) }
        return value
    }
    public func save(to url:URL) throws {
        let encoder = JSONEncoder(); encoder.outputFormatting = [.prettyPrinted,.sortedKeys]
        let data = try encoder.encode(self)
        _ = try Self.decode(data)
        try FileManager.default.createDirectory(at:url.deletingLastPathComponent(),withIntermediateDirectories:true)
        try data.write(to:url,options:.atomic)
    }
    public static func load(from url:URL, legacyURL:URL) throws -> BirdSettings {
        if FileManager.default.fileExists(atPath:url.path) { return try decode(Data(contentsOf:url)) }
        if FileManager.default.fileExists(atPath:legacyURL.path) {
            return BirdSettings(catalog:try SpeciesCatalog.decode(Data(contentsOf:legacyURL)))
        }
        return BirdSettings()
    }
}
