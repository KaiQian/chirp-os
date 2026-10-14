import AppKit

extension BirdArt {
    /// Reuses the in-app bulbul geometry so the icon and desktop bird stay recognizable.
    func exportAppIcon(to folder: URL, macOSMask: Bool = false) throws {
        try FileManager.default.createDirectory(at:folder,withIntermediateDirectories:true)
        let rep = NSBitmapImageRep(bitmapDataPlanes:nil,pixelsWide:1024,pixelsHigh:1024,
                                  bitsPerSample:8,samplesPerPixel:4,hasAlpha:true,
                                  isPlanar:false,colorSpaceName:.deviceRGB,bytesPerRow:0,bitsPerPixel:0)!
        let graphics = NSGraphicsContext(bitmapImageRep:rep)!
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = graphics
        // Flat source artwork stays square. Only the legacy ICNS build receives a mask.
        let tile = macOSMask
            ? NSBezierPath(roundedRect:NSRect(x:64,y:64,width:896,height:896),xRadius:200,yRadius:200)
            : NSBezierPath(rect:NSRect(x:0,y:0,width:1024,height:1024))
        NSColor(calibratedRed:0.92,green:0.92,blue:0.91,alpha:1).setFill()
        tile.fill()
        graphics.saveGraphicsState()
        tile.addClip()
        NSGradient(starting:NSColor(calibratedRed:0.86,green:0.87,blue:0.88,alpha:1),
                   ending:NSColor(calibratedRed:0.97,green:0.97,blue:0.96,alpha:1))!.draw(in:tile,angle:90)
        let ctx = graphics.cgContext
        ctx.translateBy(x:0,y:1024); ctx.scaleBy(x:1,y:-1)
        // A restrained window edge makes the desktop habitat visible at icon size.
        ctx.setFillColor(NSColor(calibratedRed:0.73,green:0.74,blue:0.75,alpha:1).cgColor)
        ctx.fill(CGRect(x:400,y:754,width:624,height:286))
        ctx.setFillColor(NSColor(calibratedRed:0.99,green:0.99,blue:0.98,alpha:1).cgColor)
        ctx.fill(CGRect(x:400,y:738,width:624,height:32))
        ctx.setFillColor(NSColor(calibratedRed:0.82,green:0.83,blue:0.84,alpha:1).cgColor)
        ctx.fill(CGRect(x:432,y:802,width:592,height:222))
        // 16× integer scaling preserves crisp pixels, including the scarlet cheek.
        draw(name:"stand",at:CGPoint(x:592,y:738),scale:16,right:true,context:ctx)
        graphics.restoreGraphicsState()
        NSGraphicsContext.restoreGraphicsState()
        try rep.representation(using:.png,properties:[:])!.write(to:folder.appendingPathComponent("AppIcon.png"))
    }
}
