import AppKit
import BirdingCore

// Original pixel geometry: species-specific silhouettes and field marks, not tinted bulbuls.
// Common canvas/foot anchor allows safe per-species masking and landing clearance.
enum SpeciesArt {
    static func canvas(_ id: SpeciesID) -> PixelCanvas {
        var c = PixelCanvas()
        let colours: [String:UInt32]
        switch id {
        case .treeSparrow:
            colours = ["brown":0x79503AFF,"light":0xB68A59FF,"gold":0xD7B680FF,"cream":0xD9C9AAFF,"white":0xF6EBD3FF,"crest":0x9B633FFF]
        case .lightVentedBulbul:
            colours = ["brown":0x73775AFF,"light":0x99A06AFF,"gold":0xBEC48AFF,"shadow":0x505A48FF,"cream":0xE0DEC8FF,"gray":0xA4A58DFF]
        case .spottedDove:
            colours = ["brown":0x998275FF,"light":0xBAA08BFF,"gold":0xDBC3A8FF,"shadow":0x73675FFF,"cream":0xC9A6A0FF,"white":0xF2E8D9FF,"crest":0xACA7A2FF,"feet":0xCC8588FF]
        case .chineseBlackbird:
            colours = ["brown":0x36383CFF,"light":0x505157FF,"gold":0x66676CFF,"shadow":0x262A31FF,"cream":0x3B3B3FFF,"white":0x66615AFF,"gray":0x4B4946FF,"beak":0xF3B332FF]
        case .magpieRobin:
            colours = ["brown":0x273944FF,"light":0x405563FF,"gold":0x657786FF,"shadow":0x202C36FF,"cream":0xF2F1E2FF,"white":0xFFFFF3FF]
        case .longTailedShrike:
            colours = ["brown":0xB57040FF,"light":0xD39453FF,"gold":0xE9B679FF,"shadow":0x474148FF,"cream":0xEFE1BEFF,"white":0xFFF0D3FF,"crest":0xA2A5A8FF]
        case .redWhiskeredBulbul: colours = [:]
        }
        c.colours.merge(colours) { _,new in new }
        return c
    }
    static func make(_ name: String, species id: SpeciesID) -> PixelCanvas {
        if name.hasPrefix("fly"), let phase = Int(name.dropFirst(3)) { return flight(phase, species:id) }
        var c = canvas(id)
        let preen = name.hasPrefix("preen")
        let action = name.hasPrefix("idle") ? (Int(String(name.last!)) ?? 0) : -1
        let bob = name == "breathe" ? -1 : 0
        let dove = id == .spottedDove, sparrow = id == .treeSparrow, robin = id == .magpieRobin, shrike = id == .longTailedShrike
        // Tail length and carriage differ; the robin cocks its tail rather than growing a crest.
        let raised = robin && action >= 0
        let tip = raised ? (4, 15-action*3) : (sparrow ? (7,40) : (3,44))
        c.poly([(22,28),(24,32),(tip.0+5,tip.1),(tip.0,tip.1),(tip.0+2,tip.1-5)],"ink")
        c.poly([(20,30),(21,32),(tip.0+4,tip.1-1),(tip.0+2,tip.1-2)],robin || shrike ? "black" : "brown")
        if robin || id == .lightVentedBulbul {
            c.poly([(tip.0,tip.1-4),(tip.0+2,tip.1-4),(tip.0+3,tip.1),(tip.0,tip.1)],"white")
        }
        // Feet always meet the same perch anchor, including idle poses.
        c.box(26,32,2,6,"ink"); c.box(31,32,2,6,"ink")
        c.box(27,34,1,4,"feet"); c.box(32,34,1,4,"feet")
        c.box(24,38,6,1,"ink"); c.box(30,38,6,1,"ink")
        let crouch = (sparrow && action == 0) || (id == .chineseBlackbird && action == 0) ? 2 : 0
        let shoulder = (dove ? 21 : 19)+bob+crouch
        c.poly([(23,shoulder),(30,shoulder-1),(35,23+crouch),(36,28),(33,33),(27,36),(21,35),(16,31),(16,26),(19,22+crouch)],"ink")
        c.poly([(24,shoulder+1),(30,shoulder),(33,23+crouch),(34,28),(31,33),(26,34),(21,32),(19,27)],"cream")
        if shrike { c.poly([(21,27),(25,30),(27,34),(21,33),(18,30)],"light") }
        if robin { c.poly([(25,shoulder),(31,shoulder),(34,25),(32,28),(25,26)],"brown") }
        // Rounded sparrow wing, long dove primaries, dark shrike wing with white flash.
        c.poly([(21,shoulder),(27,shoulder+3),(28,27),(24,32),(sparrow ? 18:14,35),(17,28),(17,24)],shrike ? "ink":"shadow")
        c.poly([(21,shoulder+1),(25,shoulder+3),(25,27),(21,31),(17,32),(19,25)],shrike ? "black":"brown")
        c.poly([(20,shoulder+3),(23,shoulder+3),(24,26),(20,29),(18,29)],shrike ? "crest":"light")
        if sparrow || dove {
            for (x,y) in [(19,25),(22,24),(20,28),(17,30),(22,28)] {
                c.box(x,y,2,2,"shadow"); c.dot(x,y-1,"gold")
            }
        }
        if sparrow { c.poly([(18,25),(23,24),(24,25),(19,27)],"white") }
        if robin { c.poly([(20,23),(24,24),(26,26),(20,29),(17,29)],"white") }
        if shrike {
            c.box(21,26,4,2,"white")
            c.poly([(21,shoulder-1),(26,shoulder),(28,shoulder+3),(24,shoulder+3),(20,shoulder+1)],"light")
        }
        var hx = preen ? -4 : 0
        var hy = preen ? 8 + (name == "preen1" ? 1 : 0) : bob+crouch
        if action >= 0 {
            switch id {
            case .spottedDove: hx += action == 0 ? 2 : -1; hy += action == 0 ? 2 : 0
            case .chineseBlackbird: hx += action == 0 ? 2 : -1; hy += action == 0 ? 7 : 1
            case .longTailedShrike: hx += action == 0 ? -2 : 1; hy -= action == 0 ? 1 : 0
            default: break
            }
        }
        if dove {
            // Doves have a small rounded head on a slender neck, not a thrush-sized head.
            c.poly([(29+hx,18+hy),(34+hx,18+hy),(33,26),(26,25)],"cream")
        }
        head(&c, species:id, x: hx, y:hy, blink:name == "blink", flight:false)
        if name == "land0" || name == "land1" {
            let phase = name == "land0" ? 0 : 4
            wing(&c, phase:phase, species:id, transform: { $0 })
        }
        return c
    }
    static func head(_ c: inout PixelCanvas, species id: SpeciesID, x:Int,y:Int,blink:Bool,flight:Bool) {
        func pose(_ pt:(Int,Int)) -> (Int,Int) {
            let shrink = id == .spottedDove ? 0.78 : 1.0
            // Keep the bill tip forward while reducing the dove's head/neck silhouette.
            return (Int((43+Double(pt.0-43)*shrink).rounded())+x,
                    Int((22+Double(pt.1-22)*shrink).rounded())+y)
        }
        func p(_ pts:[(Int,Int)],_ colour:String) { c.poly(pts.map(pose),colour) }
        func b(_ px:Int,_ py:Int,_ w:Int,_ h:Int,_ colour:String) {
            p([(px,py),(px+w,py),(px+w,py+h),(px,py+h)],colour)
        }
        // Rounded crowns: none of the new species inherits the red-whiskered crest.
        p([(25,19),(25,13),(28,9),(33,9),(37,12),(38,16),(35,21),(30,23),(27,21)],"ink")
        switch id {
        case .treeSparrow:
            p([(26,14),(28,10),(33,10),(36,12),(36,15),(30,16)],"crest")
            p([(26,16),(29,15),(35,15),(36,18),(33,21),(28,20)],"white")
            b(28,17,3,3,"ink") // black cheek spot, separate from black throat bib
            p([(33,19),(36,18),(35,22),(32,24),(31,21)],"ink")
            p([(37,14),(43,16),(37,18)],"ink") // short conical seed bill
        case .lightVentedBulbul:
            p([(26,14),(28,10),(31,10),(30,14),(27,17),(25,17)],"white")
            p([(27,17),(30,17),(32,16),(35,17),(34,20),(29,21)],"white")
            b(29,12,3,2,"gray"); p([(37,14),(43,16),(37,17)],"ink")
        case .spottedDove:
            p([(26,14),(28,10),(33,10),(36,13),(36,17),(33,21),(28,20)],"crest")
            p([(26,18),(30,19),(32,22),(28,24),(25,21)],"ink")
            for (px,py) in [(26,19),(28,20),(30,21),(27,22)] { b(px,py,1,1,"white") }
            p([(37,14),(43,16),(37,17)],"beak")
        case .chineseBlackbird:
            p([(26,15),(28,10),(33,10),(36,13),(36,18),(32,22),(28,20)],"brown")
            p([(37,14),(44,16),(37,18)],"beak")
            b(32,12,4,4,"beak") // adult male orange-yellow orbital ring
        case .magpieRobin:
            p([(26,14),(28,10),(33,10),(36,13),(36,18),(32,23),(28,20)],"brown")
            p([(27,12),(29,10),(33,11),(31,12)],"light")
            p([(37,14),(43,16),(37,17)],"ink")
        case .longTailedShrike:
            p([(26,14),(28,10),(33,10),(36,13),(36,16),(28,17)],"crest")
            p([(27,18),(32,17),(36,17),(35,21),(30,23),(27,21)],"cream")
            p([(26,14),(36,13),(38,15),(37,17),(27,17)],"ink") // broad black eye mask
            p([(37,14),(43,15),(43,18),(41,19),(41,17),(37,17)],"ink") // hooked bill
        case .redWhiskeredBulbul: break
        }
        b(33,13,2,2,"eye")
        if !blink { b(34,13,1,1,"shine") } else { b(33,13,2,1,"light") }
    }
    static func flight(_ phase:Int, species id:SpeciesID) -> PixelCanvas {
        var c = canvas(id)
        let pitch = [0.04,0,-0.04,-0.07,-0.03,0,0.04,0.06][phase]
        let bob = [1,0,-1,-1,0,1,1,1][phase]
        func pose(_ p:(Int,Int)) -> (Int,Int) {
            let x = Double(p.0-27), y = Double(p.1-25)
            return (Int((27+x*cos(pitch)-y*sin(pitch)).rounded()),Int((25+x*sin(pitch)+y*cos(pitch)).rounded())+bob)
        }
        func p(_ pts:[(Int,Int)],_ color:String) { c.poly(pts.map(pose),color) }
        let lift = [2,10,22,36,33,27,16,7][phase]
        p([(26,25),(25,lift),(29,max(1,lift-3)),(33,lift),(35,lift+5),(31,27)],"shadow")
        let fan = [0,1,3,3,2,1,0,0][phase]
        p([(21,24),(21,30),(2,34+fan),(1,29-fan),(12,26)],"ink")
        p([(19,26),(19,29),(3,32+fan),(3,29-fan)],id == .magpieRobin || id == .longTailedShrike ? "black":"brown")
        if id == .magpieRobin || id == .spottedDove { p([(2,29-fan),(5,29-fan),(5,33+fan),(2,34+fan)],"white") }
        let bodyBack = id == .treeSparrow ? 16 : (id == .longTailedShrike ? 21 : 17)
        p([(bodyBack,25),(23,21),(31,21),(36,24),(36,28),(30,32),(22,32),(bodyBack,29)],"ink")
        p([(bodyBack+1,26),(23,22),(30,22),(35,25),(30,29),(22,30)],"brown")
        p([(22,29),(29,26),(35,25),(34,29),(29,31),(23,31)],"cream")
        if id == .magpieRobin { p([(30,22),(36,23),(36,27),(30,28)],"brown") }
        // Draw head on a separate canvas and transform it with the pitching torso.
        var h = canvas(id)
        head(&h,species:id,x:3,y:5,blink:false,flight:true)
        for y in 0..<48 { for x in 0..<48 where h.pixels[y*48+x] != 0 {
            let q = pose((x,Int((27+Double(y-27)*0.72).rounded()))); if (0..<48).contains(q.0) && (0..<48).contains(q.1) { c.pixels[q.1*48+q.0] = h.pixels[y*48+x] }
        } }
        p([(25,31),(28,32),(23,33),(22,32)],"ink")
        wing(&c,phase:phase,species:id,transform:pose)
        return c
    }
    static func wing(_ c: inout PixelCanvas, phase:Int, species id:SpeciesID, transform:((Int,Int))->(Int,Int)) {
        let wings: [[(Int,Int)]] = [
            [(28,25),(19,21),(12,12),(7,2),(11,3),(12,0),(16,3),(18,1),(21,6),(23,4),(26,13),(30,21)],
            [(28,25),(17,22),(7,17),(1,10),(6,10),(5,6),(11,9),(12,6),(18,12),(19,10),(26,17),(30,23)],
            [(29,24),(20,23),(12,23),(1,25),(4,28),(0,30),(5,31),(2,34),(9,34),(6,37),(16,34),(24,30)],
            [(28,23),(19,25),(13,32),(9,42),(13,41),(12,46),(16,44),(18,48),(21,44),(24,47),(27,39),(30,29)],
            [(28,24),(21,27),(18,33),(19,40),(22,38),(24,43),(26,39),(29,40),(31,33),(30,27)],
            [(28,24),(21,23),(16,26),(9,31),(12,33),(10,35),(17,34),(24,31),(30,28)],
            [(29,25),(21,23),(17,18),(17,11),(20,14),(22,11),(24,15),(28,17),(31,22)],
            [(28,25),(20,21),(15,14),(12,5),(15,6),(16,2),(20,6),(22,4),(24,11),(28,15),(30,22)]
        ]

        let factor: Double = id == .treeSparrow ? 0.90 : 1
        func scaled(_ p:(Int,Int),_ f:Double) -> (Int,Int) { (Int((27+Double(p.0-27)*f).rounded()),Int((25+Double(p.1-25)*f).rounded())) }
        let points = wings[phase].map { scaled($0,factor) }
        func shape(_ pts:[(Int,Int)],_ colour:String) { c.poly(pts.map(transform),colour) }
        shape(points,"ink")
        shape(points.map{scaled($0,0.87)}, id == .longTailedShrike ? "black":"brown")
        shape(points.map{scaled($0,0.60)}, id == .longTailedShrike ? "shadow":"light")
        shape(points.map{scaled($0,0.34)},"gold")
        // Feather shafts follow the extended wing. White wing bars remain visible in flight.
        for i in stride(from:2,to:points.count-1,by:2) {
            let tip = scaled(points[i],0.82), base = scaled(points[i],0.35)
            shape([base,(base.0+1,base.1),tip,(tip.0-1,tip.1)],"shadow")
        }
        if id == .magpieRobin || id == .longTailedShrike || id == .treeSparrow {
            let tip = scaled(points[points.count/2],0.56)
            shape([(25,24),(27,26),(tip.0+2,tip.1+1),(tip.0-1,tip.1-1)],"white")
        }
    }
}
