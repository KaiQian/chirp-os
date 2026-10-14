import AppKit
import ImageIO
import BirdingCore

extension BirdArt {
    static func exportSpecies(to folder:URL) throws {
        try FileManager.default.createDirectory(at:folder,withIntermediateDirectories:true)
        let profiles = SpeciesCatalog.standard.species
        let arts = profiles.map { BirdArt(species:$0.id) }
        for (i,p) in profiles.enumerated() { try arts[i].export(to:folder.appendingPathComponent(p.id.rawValue)) }
        func render(time:Double?, detail:Bool = false) -> NSBitmapImageRep {
            let width = 1260, height = 560
            let rep = NSBitmapImageRep(bitmapDataPlanes:nil,pixelsWide:width,pixelsHigh:height,bitsPerSample:8,samplesPerPixel:4,hasAlpha:true,isPlanar:false,colorSpaceName:.deviceRGB,bytesPerRow:0,bitsPerPixel:0)!
            let graphics = NSGraphicsContext(bitmapImageRep:rep)!
            NSGraphicsContext.saveGraphicsState(); NSGraphicsContext.current = graphics
            let ctx = graphics.cgContext
            ctx.setFillColor(NSColor(calibratedRed:0.09,green:0.13,blue:0.16,alpha:1).cgColor)
            ctx.fill(CGRect(x:0,y:0,width:width,height:height))
            ctx.translateBy(x:0,y:CGFloat(height)); ctx.scaleBy(x:1,y:-1)
            func label(_ text:String,x:Double,y:Double,size:CGFloat = 16) {
                ctx.saveGState(); ctx.translateBy(x:x,y:y); ctx.scaleBy(x:1,y:-1)
                (text as NSString).draw(at:.zero,withAttributes:[.font:NSFont.systemFont(ofSize:size,weight:.medium),.foregroundColor:NSColor.white]); ctx.restoreGState()
            }
            label("上海窗边的鸟 · 成年体长比例",x:24,y:40,size:23)
            label("上：站立 / 习性动作    下：飞行    展示为桌面默认尺寸的 2 倍",x:24,y:72,size:14)
            for (i,p) in profiles.enumerated() {
                let x = Double(i*180)+102, scale = p.relativeScale*2
                let bird = Bird(position:.zero,fraction:0.5,profile:p)
                bird.perch(on:Surface(id:1,rect:CGRect(x:0,y:0,width:300,height:200)))
                if let time { bird.tick(time) }
                arts[i].draw(name:time == nil ? "stand":bird.frameName,at:CGPoint(x:x,y:232+bird.hopOffset*scale),scale:scale,right:true,context:ctx)
                ctx.setStrokeColor(NSColor(calibratedWhite:0.5,alpha:0.4).cgColor); ctx.setLineWidth(1)
                ctx.move(to:CGPoint(x:Double(i*180)+15,y:233)); ctx.addLine(to:CGPoint(x:Double(i*180)+165,y:233)); ctx.strokePath()
                let phase = time.map { Int($0*p.flapFPS)%8 } ?? 2
                arts[i].draw(name:"fly\(phase)",at:CGPoint(x:x,y:444),scale:scale,right:true,context:ctx)
                label(p.name,x:Double(i*180)+28,y:496)
                label(String(format:"%.1f cm · %.2f×",p.adultLengthCM,p.relativeScale),x:Double(i*180)+28,y:523,size:13)
            }
            NSGraphicsContext.restoreGraphicsState()
            return rep
        }
        try render(time:nil).representation(using:.png,properties:[:])!.write(to:folder.appendingPathComponent("species-lineup.png"))
        let url = folder.appendingPathComponent("species-animations.gif")
        guard let dest = CGImageDestinationCreateWithURL(url as CFURL,"com.compuserve.gif" as CFString,180,nil) else { throw NSError(domain:"Preview",code:1) }
        CGImageDestinationSetProperties(dest,[kCGImagePropertyGIFDictionary:[kCGImagePropertyGIFLoopCount:0]] as CFDictionary)
        for f in 0..<180 {
            CGImageDestinationAddImage(dest,render(time:Double(f)*0.05).cgImage!,[kCGImagePropertyGIFDictionary:[kCGImagePropertyGIFDelayTime:0.05,kCGImagePropertyGIFUnclampedDelayTime:0.05]] as CFDictionary)
        }
        guard CGImageDestinationFinalize(dest) else { throw NSError(domain:"Preview",code:2) }
        // Checks actual RGBA images, not just the drawing definitions.
        var hashes = Set<Data>()
        for art in arts {
            let stand = art.frames["stand"]!.dataProvider!.data! as Data
            guard hashes.insert(stand).inserted else { throw NSError(domain:"Preview",code:3) }
            let flight = Set((0..<8).map { art.frames["fly\($0)"]!.dataProvider!.data! as Data })
            guard flight.count == 8 else { throw NSError(domain:"Preview",code:4) }
            for image in art.frames.values {
                let bytes = [UInt8](image.dataProvider!.data! as Data)
                guard stride(from:3,to:bytes.count,by:4).filter({ bytes[$0] > 0 }).count > 100 else { throw NSError(domain:"Preview",code:5) }
            }
        }
        print("Species art: PASS — 7 distinct birds, 126 nonempty frames, 56 distinct flight poses")
    }
}
