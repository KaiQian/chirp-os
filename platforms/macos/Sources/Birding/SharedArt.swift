import AppKit
import BirdingCore

extension BirdArt {
    static func exportShared(to folder:URL) throws {
        try FileManager.default.createDirectory(at:folder.appendingPathComponent("art"),withIntermediateDirectories:true)
        let catalog = SpeciesCatalog.standard
        try JSONEncoder().encode(catalog).write(to:folder.appendingPathComponent("species.json"))
        for profile in catalog.species {
            let art = BirdArt(species:profile.id)
            let ctx = CGContext(data:nil,width:48*names.count,height:48,bitsPerComponent:8,bytesPerRow:0,
                                space:CGColorSpaceCreateDeviceRGB(),bitmapInfo:CGImageAlphaInfo.premultipliedLast.rawValue)!
            ctx.interpolationQuality = .none
            for (i,name) in names.enumerated() { ctx.draw(art.frames[name]!,in:CGRect(x:i*48,y:0,width:48,height:48)) }
            let rep = NSBitmapImageRep(cgImage:ctx.makeImage()!)
            try rep.representation(using:.png,properties:[:])!.write(to:folder.appendingPathComponent("art/\(profile.id.rawValue).png"))
        }
        let metadata:[String:Any] = ["schemaVersion":1,"frameSize":48,"footAnchor":[29,39],"frames":names,
                                    "source":"platforms/macos/Sources/Birding/{PixelArt,SpeciesArt}.swift"]
        try JSONSerialization.data(withJSONObject:metadata,options:[.prettyPrinted,.sortedKeys]).write(to:folder.appendingPathComponent("art/manifest.json"))
    }
}
