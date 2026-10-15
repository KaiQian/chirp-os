import Foundation

public enum SpeciesBehavior {
    // A quiet lookout occupies most of a heron's visit; the brief actions are
    // spaced apart, rather than looping a comic gesture every few seconds.
    public static func frame(_ id:SpeciesID, age:Double, side:Bool = false) -> String? {
        if id == .greatSpottedWoodpecker && side {
            let t=age.truncatingRemainder(dividingBy:12)
            return t > 4 && t < 5.6 ? "peck\(Int(t*12)%2)" : "cling0"
        }
        if id == .nightHeron {
            let t=age.truncatingRemainder(dividingBy:53)
            if t > 31 && t < 32 { return "poop\(Int((t-31)*6)%2)" }
            if t > 20 && t < 22 { return "stretch" }
            if t > 40 && t < 41 { return Int(t*8)%2 == 0 ? "shake":"stand" }
            return t.truncatingRemainder(dividingBy:7) > 6.8 ? "blink":"stand"
        }
        if [.greyHeron,.littleEgret,.chinesePondHeron].contains(id) {
            let t=age.truncatingRemainder(dividingBy:23)
            return t > 16 && t < 18 ? "idle\(Int(t)%2)" : (t > 20 && t < 21 ? "preen0":"stand")
        }
        let interval:Double,rate:Double
        switch id {
        case .plumbeousWaterRedstart,.redFlankedBluetail,.blackDrongo: interval=5;rate=4
        case .commonKestrel,.peregrineFalcon,.blackKite,.commonBuzzard: interval=14;rate=1
        case .eurasianWoodcock: interval=6;rate=3
        case .swinhoesWhiteEye,.yellowBrowedWarbler,.vinousThroatedParrotbill,.greatTit: interval=5;rate=5
        case .mallard,.commonMoorhen,.eurasianCoot: interval=12;rate=2
        case .hoopoe,.commonKingfisher,.piedKingfisher,.littleRingedPlover,.whimbrel,.blackWingedStilt,
             .orientalMagpie,.azureWingedMagpie,.largeBilledCrow,.barnSwallow,.asianKoel,.blackHeadedGull,
             .yellowRumpedFlycatcher,.greatSpottedWoodpecker,.redBilledLeiothrix,.blackCollaredStarling,.yellowBilledGrosbeak: interval=9;rate=2
        default: return nil
        }
        let t=age.truncatingRemainder(dividingBy:interval)
        if t > 2 && t < 4 { return "idle\(Int(t*rate)%2)" }
        if t > interval-1.4 && t < interval-0.4 { return "preen\(Int(t*4)%2)" }
        return t < 0.15 ? "blink" : (Int(age*1.2)%2 == 0 ? "stand":"breathe")
    }
}
