import XCTest
@testable import BirdingCore

final class ProbabilityTests: XCTestCase {
    func testDefaultsSumExactlyAndSampleZeroExcluded() {
        var d=ProbabilityDistribution(catalog:.standard)
        XCTAssertTrue(d.isValid)
        XCTAssertEqual(d.entries.reduce(0){$0+$1.points},10_000)
        d.adjust(at:0,to:0)
        for i in 0..<10_000 { XCTAssertNotEqual(d.choose(unit:Double(i)/10_000),d.entries[0].id) }
        d.adjust(at:3,to:10_000)
        XCTAssertEqual(d.choose(unit:0),d.entries[3].id)
        XCTAssertEqual(d.choose(unit:1),d.entries[3].id)
    }
    func testLockedEntriesStayFixedAndClampToAvailable() {
        var d=ProbabilityDistribution(catalog:.standard)
        d.setLocked(true,at:1); d.setLocked(true,at:3)
        let a=d.entries[1], b=d.entries[3]
        let maximum=10_000-a.points-b.points
        XCTAssertEqual(d.adjust(at:0,to:20_000),maximum)
        XCTAssertEqual(d.entries[1],a); XCTAssertEqual(d.entries[3],b)
        XCTAssertEqual(d.entries[2].points,0)
        XCTAssertTrue(d.isValid)
        d.adjust(at:0,to:maximum-1001)
        let peers=d.entries.indices.filter{![0,1,3].contains($0)}.map{d.entries[$0].points}
        XCTAssertEqual(peers.reduce(0,+),1001)
        XCTAssertLessThanOrEqual(peers.max()!-peers.min()!,1)
    }
    func testAllLockedAndOnlyOneUnlockedCannotChange() {
        var d=ProbabilityDistribution(catalog:.standard)
        for i in d.entries.indices { d.setLocked(true,at:i) }
        let old=d
        for i in d.entries.indices { XCTAssertFalse(d.canAdjust(i)); d.adjust(at:i,to:0) }
        XCTAssertEqual(d,old)
        d.setLocked(false,at:0); let v=d.entries[0].points
        XCTAssertFalse(d.canAdjust(0)); XCTAssertEqual(d.adjust(at:0,to:9000),v)
    }
    func testPeerProportionsAndRounding() {
        var d=ProbabilityDistribution(catalog:.standard)
        let before=d.entries
        d.adjust(at:0,to:4000)
        let sum=Double(before.dropFirst().reduce(0){$0+$1.points})
        for i in 1..<d.entries.count { XCTAssertEqual(Double(d.entries[i].points),6000*Double(before[i].points)/sum,accuracy:1) }
        XCTAssertTrue(d.isValid)
    }
    func testLongRandomEditSequenceRetainsExactTotalAndLocks() {
        var d=ProbabilityDistribution(catalog:.standard)
        var seed:UInt64=53
        for _ in 0..<10_000 {
            seed=seed &* 6364136223846793005 &+ 1
            let i=Int(seed%UInt64(d.entries.count))
            if seed%5==0 { d.setLocked(!d.entries[i].locked,at:i) }
            let locked=d.entries.filter(\.locked)
            d.adjust(at:i,to:Int((seed>>8)%12000)-1000)
            XCTAssertTrue(d.isValid)
            XCTAssertEqual(d.entries.filter(\.locked),locked)
        }
    }
    func testSaveLoadAndLegacyMigrationPreserveProfilesAndLocks() throws {
        let dir=FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at:dir,withIntermediateDirectories:true)
        defer { try? FileManager.default.removeItem(at:dir) }
        let url=dir.appendingPathComponent("settings.json"),legacy=dir.appendingPathComponent("species.json")
        var catalog=SpeciesCatalog.standard; catalog.species[0].speed=1.5
        try JSONEncoder().encode(catalog).write(to:legacy)
        var s=try BirdSettings.load(from:url,legacyURL:legacy)
        XCTAssertEqual(s.catalog.profile(.redWhiskeredBulbul).speed,1.5)
        s.probabilities.adjust(at:0,to:1234);s.probabilities.setLocked(true,at:0)
        try s.save(to:url)
        let restored=try BirdSettings.load(from:url,legacyURL:legacy)
        XCTAssertEqual(restored.probabilities,s.probabilities)
        XCTAssertEqual(restored.catalog.species,s.catalog.species)
    }
    func testRejectInvalidSavedDistributionAndProfile() throws {
        let original=try JSONSerialization.jsonObject(with:JSONEncoder().encode(BirdSettings())) as! [String:Any]
        var obj=original
        var dist=obj["probabilities"] as! [String:Any]
        var entries=dist["entries"] as! [[String:Any]];entries[0]["points"] = -100
        dist["entries"]=entries;obj["probabilities"]=dist
        XCTAssertThrowsError(try BirdSettings.decode(JSONSerialization.data(withJSONObject:obj)))
        entries.removeLast();dist["entries"]=entries;obj["probabilities"]=dist
        XCTAssertThrowsError(try BirdSettings.decode(JSONSerialization.data(withJSONObject:obj)))
        var settings=BirdSettings();settings.catalog.species[0].speed = -1
        XCTAssertThrowsError(try BirdSettings.decode(JSONEncoder().encode(settings)))
    }
}
