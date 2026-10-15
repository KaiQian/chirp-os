import AppKit
import BirdingCore

// Rasterize anatomy directly at each species' desktop pixel density. The paths
// use logical 48-unit coordinates; outlines and feather shafts stay one pixel.
private final class BirdPainter {
    let ctx:CGContext
    let size:Int
    let unit:CGFloat
    var palette:[String:UInt32] = [
        "outline":0x303943FF,"black":0x27313AFF,"dark":0x414E59FF,"slate":0x687D8CFF,
        "gray":0x9DAEB4FF,"silver":0xCED7D5FF,"white":0xF7F7ECFF,"cream":0xE4DBBFFF,
        "brown":0x806350FF,"umber":0x574A40FF,"tan":0xAD8D66FF,"buff":0xD3B58AFF,
        "rust":0xA65537FF,"orange":0xCE8A4FFF,"blue":0x386A93FF,"navy":0x28455FFF,
        "cyan":0x61A3B5FF,"green":0x697E47FF,"olive":0x899961FF,"yellow":0xE4C951FF,
        "red":0xC74F43FF,"pink":0xCB8E87FF,"eye":0x121C25FF]
    init(size:Int){
        self.size=size;unit=48/CGFloat(size)
        ctx=CGContext(data:nil,width:size,height:size,bitsPerComponent:8,bytesPerRow:0,space:CGColorSpaceCreateDeviceRGB(),bitmapInfo:CGImageAlphaInfo.premultipliedLast.rawValue)!
        ctx.setShouldAntialias(false);ctx.translateBy(x:0,y:CGFloat(size));ctx.scaleBy(x:CGFloat(size)/48,y:-CGFloat(size)/48)
        ctx.setLineJoin(.round);ctx.setLineCap(.round)
    }
    func color(_ key:String)->CGColor {
        let p=palette[key]!
        return CGColor(red:CGFloat((p>>24)&255)/255,green:CGFloat((p>>16)&255)/255,blue:CGFloat((p>>8)&255)/255,alpha:1)
    }
    func poly(_ pts:[(Double,Double)],_ fill:String,outline:Bool=false) {
        guard let first=pts.first else{return};ctx.beginPath();ctx.move(to:CGPoint(x:first.0,y:first.1))
        for p in pts.dropFirst(){ctx.addLine(to:CGPoint(x:p.0,y:p.1))};ctx.closePath()
        ctx.setFillColor(color(fill));ctx.setStrokeColor(color("outline"));ctx.setLineWidth(unit)
        ctx.drawPath(using:outline ? .fillStroke:.fill)
    }
    func oval(_ x:Double,_ y:Double,_ w:Double,_ h:Double,_ fill:String,outline:Bool=false) {
        ctx.setFillColor(color(fill));ctx.setStrokeColor(color("outline"));ctx.setLineWidth(unit)
        ctx.addEllipse(in:CGRect(x:x,y:y,width:w,height:h));ctx.drawPath(using:outline ? .fillStroke:.fill)
    }
    func line(_ pts:[(Double,Double)],_ fill:String,width:Double?=nil) {
        guard let p=pts.first else{return};ctx.beginPath();ctx.move(to:CGPoint(x:p.0,y:p.1))
        for p in pts.dropFirst(){ctx.addLine(to:CGPoint(x:p.0,y:p.1))}
        ctx.setStrokeColor(color(fill));ctx.setLineWidth(width.map{CGFloat($0)} ?? unit);ctx.strokePath()
    }
    func curve(_ points:[(Double,Double)],_ fill:String,width:Double) {
        guard points.count == 4 else{return}
        ctx.beginPath();ctx.move(to:CGPoint(x:points[0].0,y:points[0].1))
        ctx.addCurve(to:CGPoint(x:points[3].0,y:points[3].1),control1:CGPoint(x:points[1].0,y:points[1].1),control2:CGPoint(x:points[2].0,y:points[2].1))
        ctx.setStrokeColor(color(fill));ctx.setLineWidth(width);ctx.strokePath()
    }
    var image:CGImage {ctx.makeImage()!}
}

enum DetailedBirdArt {
    private static let herons:Set<SpeciesID>=[.nightHeron,.littleEgret,.greyHeron,.chinesePondHeron]
    private static let raptors:Set<SpeciesID>=[.commonKestrel,.peregrineFalcon,.blackKite,.commonBuzzard]
    private static let waders:Set<SpeciesID>=[.whimbrel,.eurasianWoodcock,.blackWingedStilt,.littleRingedPlover]
    private static let water:Set<SpeciesID>=[.mallard,.commonMoorhen,.eurasianCoot,.blackHeadedGull]
    private static let corvids:Set<SpeciesID>=[.orientalMagpie,.azureWingedMagpie,.largeBilledCrow,.asianKoel,.blackDrongo]
    static func make(_ frame:String,species id:SpeciesID)->CGImage {
        let density=SpeciesCatalog.standard.profile(id).relativeScale
        let c=BirdPainter(size:max(48,Int((48*density).rounded())))
        let phase=Int(String(frame.last!)) ?? 0
        let flying=frame.hasPrefix("fly"),landing=frame.hasPrefix("land")
        let bob=frame == "breathe" ? -0.4:0.0
        if herons.contains(id) {heron(c,id,frame,phase,flying,landing);return c.image}
        if id == .greatSpottedWoodpecker && (frame.hasPrefix("cling") || frame.hasPrefix("peck")) {woodpecker(c,frame);return c.image}
        let style=colours(id)
        let longTail=corvids.contains(id) || id == .barnSwallow || id == .vinousThroatedParrotbill || id == .longTailedShrike
        let shortTail=waders.contains(id) || water.contains(id) || id == .commonKingfisher || id == .piedKingfisher
        let waterBird=water.contains(id),wader=waders.contains(id),raptor=raptors.contains(id)
        if flying {
            c.ctx.saveGState();c.ctx.translateBy(x:27,y:24)
            c.ctx.rotate(by:CGFloat([0.03,0,-0.04,-0.06,-0.03,0.01,0.04,0.06][phase%8]))
            c.ctx.translateBy(x:-27,y:-24+CGFloat([0,-0.3,-0.5,0,0.3,0.5,0,-0.2][phase%8]))
            wing(c,phase:phase,fill:style.1,light:style.0,pointed:id == .barnSwallow || id == .peregrineFalcon || id == .commonKestrel,far:true,bar:wingBar(id))
        }
        let tailTip=flying ? (2.0,27.0):(longTail ? (3.0,43.0):(shortTail ? (12.0,31.0):(10.0,42.0)))
        let tailFill=id == .plumbeousWaterRedstart ? "rust":(id == .azureWingedMagpie ? "cyan":style.1)
        var tip=tailTip
        if frame.hasPrefix("idle") && [.plumbeousWaterRedstart,.redFlankedBluetail,.blackDrongo,.magpieRobin].contains(id) {tip.1-=Double(phase+1)*5}
        c.poly([(21,27),(24,31),(tip.0+4,tip.1+1),(tip.0,tip.1)],tailFill,outline:true)
        c.line([(21,29),(tip.0+1,tip.1)],style.0)
        if [.barnSwallow,.blackDrongo,.blackKite].contains(id) {
            c.poly([(18,27),(tip.0,tip.1-3),(tip.0+6,tip.1),(tip.0,tip.1+4),(22,31)],tailFill,outline:true)
        }
        if !flying {
            let legTop=wader ? (id == .blackWingedStilt ? 25.0:(id == .eurasianWoodcock ? 35.0:29.0)):33.0
            let leg=id == .blackWingedStilt ? "pink":(raptor || id == .commonMoorhen ? "yellow":"brown")
            for x in [27.0,31.0] {c.line([(x-1,legTop),(x,35),(x-0.5,38.5)],leg,width:id == .blackWingedStilt ? 0.7:1);c.line([(x-2,39),(x,38.5),(x+2,39)],leg)}
            if id == .mallard {c.poly([(27,35),(29,39),(24,39)],"orange");c.poly([(31,35),(35,39),(29,39)],"orange")}
        } else if wader || waterBird {c.line([(20,27),(5,29),(3,28)],id == .blackWingedStilt ? "pink":"brown");c.line([(20,28),(4,31),(2,30)],"brown")}
        let bodyY=flying ? 21.0 : (wader ? (id == .blackWingedStilt ? 19.0:(id == .eurasianWoodcock ? 25.0:23.0)):(waterBird ? 26.0:22.0))+bob
        let bodyH=flying ? 8.0:(wader ? (id == .eurasianWoodcock ? 11.0:8.0):(waterBird ? 10.0:(raptor ? 14.0:12.0)))
        let bodyX=waterBird ? 10.0:16.0,bodyW=waterBird ? 25.0:(wader ? (id == .eurasianWoodcock ? 20.0:17.0):18.0)
        c.oval(bodyX,bodyY,bodyW,bodyH,style.0,outline:true)
        c.oval(bodyX+bodyW*0.48,bodyY+2,bodyW*0.52-1,bodyH-2,style.3)
        var hx=flying ? 33.0:30.0,hy=flying ? 18.0:15.0+bob
        var headW=8.0,headH=7.0
        if waterBird {hx=31;hy=flying ? 18:19;headW=8;headH=7}
        if wader {hx=28;hy=id == .blackWingedStilt ? 10:17;headW=6.5;headH=5.5;if id == .eurasianWoodcock {hy=21;headW=7.5;headH=6.5};if flying {hx=34;hy=19}}
        if raptor {hx=29;hy=flying ? 18:13;headW=8.5;headH=7}
        if id == .plumbeousWaterRedstart {headW=8.5;headH=7.5;hy+=1}
        if id == .commonKingfisher || id == .piedKingfisher {hx=flying ? 32:28;headW=flying ? 9:10;headH=7;hy=flying ? 18:14}
        if frame.hasPrefix("idle") {hx+=phase == 0 ? -0.6:0.7;hy+=phase == 0 ? 0.5:-0.3}
        if frame.hasPrefix("preen") {hx-=7;hy+=9+Double(phase)*0.5}
        if wader || waterBird {
            c.curve([(29,bodyY+4),(34,bodyY),(29,hy+6),(hx+3,hy+4)],style.3,width:waterBird ? 4:2.4)
        } else {c.poly([(26,24),(hx+1,hy+4),(hx+headW-1,hy+5),(33,29)],style.3)}
        if !flying {
            c.poly([(19,bodyY+1),(24,bodyY+1),(29,bodyY+4),(27,bodyY+8),(18,bodyY+bodyH-1),(16,bodyY+bodyH-1),(18,bodyY+5)],style.1,outline:true)
            c.poly([(20,bodyY+2),(24,bodyY+2),(26,bodyY+4),(23,bodyY+7),(18,bodyY+8)],style.0)
            for n in 0..<5 {let x=18+Double(n)*1.6;c.line([(x+4,bodyY+4),(x,bodyY+bodyH-1)],n%2 == 0 ? style.0:"dark")}
            if let bar=wingBar(id) {c.line([(19,bodyY+4),(25,bodyY+5)],bar,width:1.2)}
        }
        c.oval(hx,hy,headW,headH,style.2,outline:true)
        marks(c,id,hx,hy,headW,bodyY,flying)
        let billX=hx+headW-0.5,billY=hy+headH*0.5
        let billFill:[SpeciesID:String]=[.mallard:"yellow",.blackHeadedGull:"red",.commonMoorhen:"red",.eurasianCoot:"white",.redBilledLeiothrix:"red",.yellowBilledGrosbeak:"yellow",.chineseBlackbird:"yellow"]
        if id == .whimbrel || id == .hoopoe {
            c.curve([(billX,billY),(43,billY+0.4),(46,billY+3),(45,billY+7)],"dark",width:0.9)
        } else if id == .eurasianWoodcock || id == .commonKingfisher || id == .piedKingfisher {
            c.poly([(billX,billY-0.7),(47,billY+0.4),(billX,billY+1)],"dark")
            c.line([(billX,billY-0.5),(45,billY)],"slate")
        } else if raptor || id == .longTailedShrike {
            c.poly([(billX,billY-1),(billX+3,billY),(billX+3,billY+2),(billX+1.5,billY+3),(billX+1.8,billY+1),(billX,billY+1)],"dark")
            c.oval(billX-0.5,billY-1,1.5,2,"yellow")
        } else if id == .yellowBilledGrosbeak || id == .vinousThroatedParrotbill {
            c.poly([(billX,billY-1.4),(billX+4,billY+0.3),(billX+0.4,billY+2)],id == .vinousThroatedParrotbill ? "cream":"yellow",outline:true)
        } else {
            let length=id == .largeBilledCrow ? 6.0:4.0
            c.poly([(billX,billY-0.7),(billX+length,billY+0.5),(billX+length-1,billY+1.2),(billX,billY+1.3)],billFill[id] ?? "dark")
        }
        let eyeX=hx+headW*0.72,eyeY=hy+headH*0.38
        if id == .swinhoesWhiteEye {c.oval(eyeX-1.1,eyeY-1.1,2.9,2.9,"white")}
        if id == .littleRingedPlover || id == .chineseBlackbird {c.oval(eyeX-0.8,eyeY-0.8,2.3,2.3,"yellow")}
        if id == .asianKoel {c.oval(eyeX-0.7,eyeY-0.7,2.1,2.1,"red")}
        if frame == "blink" {c.line([(eyeX-0.4,eyeY+0.5),(eyeX+1,eyeY+0.5)],"eye")}
        else {c.oval(eyeX,eyeY,1,1.1,"eye");c.oval(eyeX+0.4,eyeY,0.45,0.45,"white")}
        if flying || landing {wing(c,phase:flying ? phase:[4,6,7][min(2,phase)],fill:style.1,light:style.0,pointed:[.barnSwallow,.peregrineFalcon,.commonKestrel,.blackHeadedGull].contains(id),far:false,bar:wingBar(id))}
        if flying {c.ctx.restoreGState()}
        return c.image
    }
    // Anatomical wing: shoulder -> elbow -> wrist -> fanned primaries. Each
    // primary has its own tapered tip; no translated rectangular slab.
    private static func wing(_ c:BirdPainter,phase:Int,fill:String,light:String,pointed:Bool=false,far:Bool=false,bar:String?=nil) {
        let angles=[-2.0,-2.4,-2.95,2.8,2.2,1.8,2.55,-2.7]
        let angle=angles[phase%8]+(far ? 0.23:0)
        let extent=far ? 0.78:1.0
        func p(_ x:Double,_ y:Double)->(Double,Double) {
            (26+x*cos(angle)*extent-y*sin(angle),24+x*sin(angle)*extent+y*cos(angle))
        }
        let leading:[(Double,Double)]=[(0,0),(5,-3),(11,-3.8),(17,-2.7),(23,-0.8),(pointed ? 25:24,0)]
        let trailing:[(Double,Double)] = pointed ? [(19,2),(12,5),(6,5.5),(0,3)] : [(23,2.2),(21.8,1.7),(22.1,3.9),(20.4,3),(20,5.6),(18.5,4.6),(17.2,6.8),(15.6,5.7),(13.8,7),(11.7,6),(9,6.1),(5,4.6),(0,3)]
        c.poly((leading+trailing).map{p($0.0,$0.1)},far ? "slate":fill,outline:true)
        c.poly([(0,0),(5,-2.5),(11,-3),(16,-1.8),(12,2.5),(6,3.4),(0,2.6)].map{p($0.0,$0.1)},far ? fill:light)
        for n in 0..<7 {
            let t=Double(n),start=9+t*1.1,end=14+t*1.45
            c.line([p(start,0.4),p(end,pointed ? 2.2:5.5-t*0.65)],far ? fill:"dark")
        }
        for n in 0..<5 {let x=3+Double(n)*2;c.line([p(x,-1.4),p(x+1.2,1.4)],far ? light:fill)}
        if let bar {c.line([p(5,1.6),p(10,1),p(14,0)],bar,width:1.2)}
    }
    private static func heron(_ c:BirdPainter,_ id:SpeciesID,_ frame:String,_ phase:Int,_ flying:Bool,_ landing:Bool) {
        let night=id == .nightHeron,egret=id == .littleEgret,pond=id == .chinesePondHeron
        let back=egret ? "white":(night ? "navy":(pond ? "rust":"gray"))
        let wingFill=egret || pond ? "white":"gray"
        let light=egret || pond ? "silver":"slate"
        let neck=pond ? "rust":"white"
        let action=frame.hasPrefix("preen"),stretch=frame == "stretch"
        let breathe=frame == "breathe" ? -0.25:0.0
        if flying {
            c.ctx.saveGState();c.ctx.translateBy(x:0,y:CGFloat([0,-0.3,-0.5,0,0.4,0.6,0.2,-0.2][phase%8]))
            wing(c,phase:phase,fill:wingFill,light:light,far:true)
            c.line([(23,25),(12,27),(2,28),(0.8,27)],egret ? "dark":"tan",width:0.65)
            c.line([(22,26),(10,29),(1,30)],egret ? "dark":"tan",width:0.65)
            c.poly([(20,23),(14,25),(17,27),(23,27)],wingFill,outline:true)
            c.oval(19,20,15,8,back,outline:true);c.oval(25,23,9,4,"silver")
            // Neck folded in flight, with a visible forward bulge below the head.
            c.curve([(30,24),(37,31),(38,25),(35,23)],neck,width:3.3)
            c.curve([(35,23),(32,21),(35,19),(38,20)],neck,width:2.5)
            headHeron(c,id,x:35,y:17.5,frame:frame)
            wing(c,phase:phase,fill:wingFill,light:egret ? "white":(pond ? "silver":"gray"),bar:egret ? nil:"slate")
            c.ctx.restoreGState();return
        }
        let base=night ? 32.0:(pond ? 30.0:26.0)
        let legs=egret ? "dark":(night || pond ? "tan":"brown")
        for x in [27.0,31.0] {c.line([(x-1,base),(x,base+4),(x-0.5,38.7)],legs,width:0.7);c.line([(x-2,39),(x,38.6),(x+2,39)],egret ? "yellow":legs,width:0.7)}
        let by=night ? 20.5:(pond ? 22.0:19.0)
        c.poly([(17,by+4),(14,base-1),(18,base),(23,base-2)],wingFill,outline:true)
        c.oval(17,by+breathe,16,base-by,back,outline:true)
        c.oval(27,by+2,7,base-by-1,neck)
        var hx=32.0,hy=night ? 15.5:(pond ? 13.5:5.0)
        if id == .greyHeron {hx=33;hy=6.5}
        if stretch {hy-=night ? 7:1}
        if frame.hasPrefix("idle") {hx+=phase == 0 ? -0.6:1;hy+=phase == 0 ? 0.5:-0.5}
        if action {hx=23;hy=22+Double(phase)*0.7}
        if frame.hasPrefix("poop") {hy+=2}
        if night && !stretch && !action {
            c.oval(25.5,19.5,9.5,11.5,"white")
            c.curve([(30,29),(36,27),(34,23),(35,20)],"silver",width:5)
            c.curve([(31,29),(36,27),(34,23),(35,20)],"white",width:3.5)
        } else {
            // Narrow S-shaped neck: shoulder, forward knee, tucked middle, head.
            c.curve([(30,base-2),(36,base-6),(32,hy+13),(30,hy+10)],egret ? "silver":"gray",width:3.2)
            c.curve([(30,hy+10),(27,hy+6),(31,hy+4),(hx+2,hy+3)],egret ? "silver":"gray",width:3.2)
            c.curve([(30.6,base-2),(36,base-6),(33,hy+13),(30.7,hy+10)],neck,width:2.1)
            c.curve([(30.7,hy+10),(28,hy+6),(31,hy+4),(hx+2,hy+3)],neck,width:2.1)
        }
        c.poly([(19,by+1),(25,by+0.5),(29,by+3),(26,base-1),(17,base),(18,by+5)],wingFill,outline:true)
        c.poly([(20,by+1.4),(24,by+1),(27,by+3),(23,base-2),(19,base-2)],egret ? "white":"silver")
        for n in 0..<6 {let x=18+Double(n)*1.4;c.line([(x+4,by+3),(x,base-0.5)],egret ? "silver":"slate")}
        if egret {for n in 0..<4 {c.curve([(23,by+3),(23,base),(20,base+1),(17-Double(n),base+1+Double(n)*0.5)],"white",width:0.5)}}
        if id == .greyHeron {c.line([(31,19),(30,21)],"dark");c.line([(32,21),(31,23)],"dark");c.line([(32,24),(31.5,25)],"dark")}
        headHeron(c,id,x:hx,y:hy,frame:frame)
        if landing {wing(c,phase:[4,6,7][min(2,phase)],fill:wingFill,light:light)}
        if frame == "shake" {for n in 0..<5 {let y=by+Double(n);c.line([(18,y),(16.5,y+1.5)],wingFill)}}
        if night && frame.hasPrefix("poop") {c.curve([(18,31),(14,34),(16,39),(12+Double(phase),44)],"white",width:1.2);c.line([(13,42),(12,46)],"silver",width:0.7)}
    }
    private static func headHeron(_ c:BirdPainter,_ id:SpeciesID,x:Double,y:Double,frame:String) {
        let night=id == .nightHeron,egret=id == .littleEgret,pond=id == .chinesePondHeron
        let w=night ? 7.5:6.5,h=night ? 5.5:4.1
        c.oval(x,y,w,h,pond ? "rust":"white",outline:true)
        if night {c.poly([(x,y+2),(x+1,y),(x+5,y-0.3),(x+w,y+1.3),(x+w,y+2.3),(x+2,y+2.2)],"navy")}
        if id == .greyHeron {c.line([(x+0.2,y+1.5),(x+4.7,y+1.6)],"black",width:1.1);c.line([(x+1,y+1.3),(x-3,y+3.5)],"black",width:0.7)}
        if night || egret {c.curve([(x+0.5,y+1),(x-2,y+1),(x-2,y+4),(x-6,y+5)],"white",width:0.55);c.curve([(x,y+1),(x-3,y+1),(x-3,y+3),(x-7,y+3.5)],"silver",width:0.5)}
        let bill=egret || night ? "dark":"yellow",by=y+h*0.55
        c.poly([(x+w-0.5,by-0.8),(min(47,x+w+8),by+0.2),(x+w-0.5,by+1)],bill)
        c.line([(x+w,by-0.5),(min(46,x+w+6),by)],egret ? "slate":(night ? "slate":"buff"))
        let ex=x+w-2.2,ey=y+1.6
        c.oval(ex-0.5,ey-0.4,1.8,1.8,night ? "red":"yellow")
        if frame == "blink" {c.line([(ex-0.2,ey+0.5),(ex+0.7,ey+0.5)],"dark")}
        else {c.oval(ex,ey,0.8,0.9,"eye");c.oval(ex+0.35,ey,0.35,0.35,"white")}
    }
    private static func colours(_ id:SpeciesID)->(String,String,String,String) {
        switch id {
        case .commonKestrel:return ("orange","rust","gray","cream")
        case .peregrineFalcon:return ("slate","navy","navy","cream")
        case .blackKite:return ("brown","umber","tan","brown")
        case .commonBuzzard:return ("umber","brown","brown","cream")
        case .orientalMagpie:return ("black","navy","black","white")
        case .azureWingedMagpie:return ("gray","cyan","black","cream")
        case .largeBilledCrow,.asianKoel,.blackDrongo:return ("dark","black","black","dark")
        case .mallard:return ("gray","brown","green","silver")
        case .commonMoorhen,.eurasianCoot:return ("dark","slate","black","dark")
        case .blackHeadedGull:return ("white","silver","white","white")
        case .plumbeousWaterRedstart:return ("blue","slate","blue","blue")
        case .commonKingfisher:return ("cyan","blue","blue","orange")
        case .piedKingfisher,.greatSpottedWoodpecker:return ("silver","black","black","white")
        case .yellowRumpedFlycatcher:return ("black","black","black","yellow")
        case .redFlankedBluetail:return ("blue","navy","blue","white")
        case .swinhoesWhiteEye:return ("olive","green","olive","cream")
        case .yellowBrowedWarbler:return ("olive","green","olive","cream")
        case .greatTit:return ("green","slate","black","yellow")
        case .redBilledLeiothrix:return ("olive","green","olive","yellow")
        case .blackCollaredStarling:return ("brown","dark","cream","cream")
        case .yellowBilledGrosbeak:return ("gray","black","gray","cream")
        case .barnSwallow:return ("navy","blue","navy","cream")
        case .blackWingedStilt:return ("white","black","white","white")
        case .hoopoe:return ("orange","black","orange","buff")
        case .eurasianWoodcock:return ("tan","brown","tan","buff")
        case .vinousThroatedParrotbill:return ("tan","brown","orange","pink")
        case .chineseBlackbird:return ("dark","black","black","dark")
        case .spottedDove:return ("tan","brown","gray","pink")
        case .longTailedShrike:return ("orange","dark","gray","cream")
        default:return ("tan","brown","tan","cream")
        }
    }
    private static func wingBar(_ id:SpeciesID)->String? {
        switch id {
        case .hoopoe,.orientalMagpie,.greatTit,.yellowRumpedFlycatcher,.greatSpottedWoodpecker,.piedKingfisher,.yellowBilledGrosbeak,.blackCollaredStarling:return "white"
        case .yellowBrowedWarbler:return "cream"
        case .redBilledLeiothrix:return "red"
        default:return nil
        }
    }
    private static func marks(_ c:BirdPainter,_ id:SpeciesID,_ x:Double,_ y:Double,_ w:Double,_ bodyY:Double,_ flying:Bool) {
        switch id {
        case .commonKestrel,.peregrineFalcon:
            c.poly([(x+1,y+4),(x+w-1,y+3.5),(x+w-1,y+6.5),(x+3,y+7)],"cream")
            c.poly([(x+w-3,y+3),(x+w-1.5,y+3.5),(x+w-2,y+7),(x+w-3.5,y+6)],"black")
            for row in 0..<5 {let yy=bodyY+4+Double(row)*1.6;for col in 0..<3 {let xx=28+Double(col)*1.7;c.line([(xx,yy),(xx+0.7,yy+0.3)],id == .commonKestrel ? "rust":"slate")}}
            if id == .commonKestrel && !flying {for i in 0..<7 {let xx=19+Double(i%3)*2,yy=bodyY+3+Double(i/3)*2;c.line([(xx,yy),(xx+0.6,yy+1)],"umber")}}
        case .commonBuzzard:
            c.poly([(29,bodyY+4),(32,bodyY+3),(33,bodyY+7),(29,bodyY+8),(27,bodyY+6)],"brown")
            for i in 0..<4 {c.line([(28,bodyY+9+Double(i)),(31,bodyY+9+Double(i))],"tan")}
        case .blackKite:
            for i in 0..<4 {c.line([(x+1+Double(i),y+2),(x+1.5+Double(i),y+4.5)],"brown")}
            c.line([(30,bodyY+3),(29,bodyY+7)],"tan")
        case .largeBilledCrow,.asianKoel:
            c.line([(x+1,y+2),(x+4,y+1)],"dark")
            if !flying {for i in 0..<3 {c.line([(27+Double(i),bodyY+4),(28+Double(i),bodyY+6)],"slate")}}
        case .blackDrongo:c.poly([(x+0.5,y+1),(x+1,y-1),(x+4,y),(x+6,y+1)],"black");c.line([(x+1,y+2),(x+3,y+1)],"slate")
        case .azureWingedMagpie:c.poly([(x+1,y+4),(x+w-1,y+4),(x+w-1,y+6),(x+2,y+7)],"cream")
        case .mallard:
            c.line([(x+0.5,y+6),(x+4,y+7),(x+7,y+6)],"white",width:1)
            c.poly([(30,bodyY),(34,bodyY+1),(34,bodyY+5),(30,bodyY+6)],"rust")
            if !flying {c.poly([(16,bodyY+2),(23,bodyY+2),(24,bodyY+5),(17,bodyY+5)],"navy");c.line([(16,bodyY+1.6),(23,bodyY+1.6)],"white");c.line([(17,bodyY+5.5),(24,bodyY+5.5)],"white")}
            c.oval(x+2,y+1,4,2,"olive")
        case .commonMoorhen:c.oval(x+w-2,y+1,2,3.5,"red");c.line([(16,bodyY+7),(24,bodyY+8)],"white")
        case .eurasianCoot:c.oval(x+w-2,y+0.3,2,4,"white")
        case .blackHeadedGull:c.oval(x+1,y+2.6,1.4,2,"dark")
        case .swinhoesWhiteEye:c.poly([(x+3,y+5),(x+w,y+4),(x+w-1,y+7),(x+4,y+7)],"yellow")
        case .yellowBrowedWarbler:
            c.line([(x+0.5,y+2),(x+w-0.5,y+1.7)],"cream",width:0.8)
            c.line([(x+2,y+3),(x+w,y+2.7)],"brown")
            if !flying {c.line([(19,bodyY+7),(24,bodyY+8)],"cream")}
        case .yellowRumpedFlycatcher:c.line([(x+0.5,y+1.5),(x+w-1,y+1)],"white",width:0.8);c.poly([(17,bodyY+9),(21,bodyY+8),(22,bodyY+11),(18,bodyY+12)],"yellow")
        case .greatTit:
            c.poly([(x+1,y+4),(x+5,y+3),(x+w-1,y+4),(x+w-1,y+6),(x+3,y+7)],"white")
            c.line([(x+4,y+6.5),(31,bodyY+4),(30,bodyY+11)],"black",width:1.4)
        case .redFlankedBluetail:
            c.poly([(30,bodyY+4),(33,bodyY+3),(33,bodyY+9),(30,bodyY+10)],"orange")
            c.poly([(x+3,y+5),(x+w,y+4.5),(x+w-1,y+7),(x+4,y+7)],"white")
            c.line([(x+1,y+1.5),(x+5,y+1)],"cyan")
        case .redBilledLeiothrix:c.poly([(x+2,y+4),(x+w,y+4),(x+w-1,y+7),(x+3,y+6)],"orange");c.line([(x+1,y+1.5),(x+w-1,y+1)],"yellow");if !flying {c.line([(18,bodyY+7),(24,bodyY+8)],"yellow")}
        case .blackCollaredStarling:c.poly([(x,y+6),(x+4,y+7),(x+w,y+6),(x+w-0.5,y+8),(x+3,y+9),(x,y+8)],"black")
        case .yellowBilledGrosbeak:c.poly([(x+w-3,y+2),(x+w,y+2),(x+w,y+5),(x+w-2,y+5)],"black")
        case .barnSwallow:c.poly([(x+3,y+4),(x+w,y+4),(x+w-1,y+7),(x+3,y+6)],"rust");c.line([(x+3,y+0.5),(x+6,y+1)],"rust");c.line([(x+2,y+7),(x+6,y+8)],"navy",width:1.2)
        case .hoopoe:
            for i in 0..<6 {
                let a = -2.7+Double(i)*0.29,tip=(x+3+cos(a)*9,y+3+sin(a)*9)
                c.line([(x+3,y+2),tip],"orange",width:1.2)
                c.line([tip,(tip.0-cos(a)*1.6,tip.1-sin(a)*1.6)],"black",width:1.2)
            }
            if !flying {
                // Separate bands follow the tapered folded wing; do not stack
                // them over the generic wing bar or spill onto the buff breast.
                let edge:[(Double,Double)]=[(19,bodyY+1),(24,bodyY+1),(29,bodyY+4),(27,bodyY+8),(18,bodyY+11),(16,bodyY+11),(18,bodyY+5)]
                c.poly(edge,"black",outline:true)
                c.ctx.saveGState()
                c.ctx.beginPath();c.ctx.move(to:CGPoint(x:edge[0].0,y:edge[0].1))
                for p in edge.dropFirst(){c.ctx.addLine(to:CGPoint(x:p.0,y:p.1))}
                c.ctx.closePath();c.ctx.clip()
                for i in 0..<3 {
                    let yy=bodyY+2.5+Double(i)*3.2
                    c.line([(16,yy),(21,yy+0.5),(28,yy+2)],"white",width:0.85)
                }
                c.ctx.restoreGState()
            }
        case .piedKingfisher:
            c.poly([(x,y+2),(x-1,y),(x+2,y+0.5),(x+2,y-1.4),(x+5,y+0.4),(x+7,y)],"black")
            c.poly([(x+1,y+4),(x+5,y+3.5),(x+w-1,y+4),(x+w-2,y+6),(x+2,y+6)],"white")
            c.line([(28,bodyY+2),(33,bodyY+3)],"black",width:1.5)
            c.line([(29,bodyY+5),(33,bodyY+6)],"black")
            if !flying {for i in 0..<9 {c.oval(18+Double(i%3)*2,bodyY+2+Double(i/3)*2,0.8,0.8,"white")}}
        case .commonKingfisher:
            c.poly([(x+1,y+4),(x+4,y+3.5),(x+5,y+5),(x+3,y+6)],"orange")
            c.poly([(x+4,y+5),(x+8,y+4.5),(x+8,y+6),(x+5,y+7)],"white")
            c.line([(19,bodyY+1),(18,bodyY+8)],"cyan",width:1.4)
            for i in 0..<5 {c.oval(x+1+Double(i)*1.3,y+1.3,0.5,0.5,"cyan")}
        case .greatSpottedWoodpecker:
            c.poly([(x+1,y+3.5),(x+w-1,y+3),(x+w-1,y+5.5),(x+3,y+6.5)],"white")
            c.line([(x+1,y+1),(x,y+3)],"red",width:1.3)
            c.poly([(27,bodyY+8),(33,bodyY+8),(31,bodyY+12),(26,bodyY+11)],"red")
            if !flying {c.oval(20,bodyY+2,5,3.5,"white");for i in 0..<3 {c.oval(18+Double(i),bodyY+7+Double(i),0.8,0.8,"white")}}
        case .whimbrel:
            c.line([(x+0.4,y+1),(x+w-1,y+0.7)],"cream")
            c.line([(x+1,y+2.4),(x+w-1,y+2)],"umber")
            for i in 0..<12 {let xx=18+Double(i%4)*2.3,yy=bodyY+1+Double(i/4)*2;c.line([(xx,yy),(xx+1,yy+0.7)],"buff")}
        case .eurasianWoodcock:
            for i in 0..<3 {c.line([(x+0.5,y+Double(i)*1.5),(x+3,y+Double(i)*1.5+0.5)],"umber",width:1)}
            for i in 0..<18 {let xx=17+Double(i%5)*2.8,yy=bodyY+1+Double(i/5)*1.8;c.line([(xx,yy),(xx+1.5,yy+0.5)],i%2 == 0 ? "buff":"umber")}
        case .vinousThroatedParrotbill:c.poly([(x+1,y+4),(x+w-1,y+3.5),(x+w-1,y+6),(x+3,y+7)],"pink")
        case .blackWingedStilt:c.poly([(x,y+1),(x+2,y),(x+4,y+0.5),(x+4,y+2),(x,y+3)],"black")
        case .littleRingedPlover:
            c.line([(x,y+2),(x+w-1,y+2)],"black",width:1)
            c.line([(x+1,y+5),(x+4,y+6),(x+w,y+5)],"white",width:1.2)
            c.line([(x+1,y+7),(x+4,y+8),(x+w,y+7)],"black",width:1.4)
        case .spottedDove:
            c.poly([(x,y+4),(x+4,y+5),(x+4,y+8),(x,y+7)],"black")
            for (xx,yy) in [(x+0.7,y+5),(x+2,y+5.8),(x+3,y+6.7),(x+1,y+6.5)] {c.oval(xx,yy,0.7,0.7,"white")}
            if !flying {for i in 0..<10 {let xx=19+Double(i%3)*2,yy=bodyY+2+Double(i/3)*1.8;c.line([(xx,yy),(xx+1,yy-0.4),(xx+1.5,yy+0.5)],"buff")}}
        case .longTailedShrike:c.poly([(x,y+2),(x+w,y+2),(x+w,y+3.7),(x+1,y+4)],"black");c.poly([(x+2,y+4),(x+w,y+4),(x+w-1,y+6.5),(x+3,y+7)],"cream")
        default:break
        }
    }
    private static func woodpecker(_ c:BirdPainter,_ frame:String) {
        let reach=frame == "peck1" ? 2.0:0.0
        c.poly([(18,28),(23,30),(27,43),(25,44),(20,37),(16,32)],"black",outline:true)
        c.line([(20,31),(25,42)],"slate")
        c.oval(13,18,12,18,"black",outline:true)
        c.oval(20,20,6,13,"white")
        c.poly([(15,18),(21,20),(22,27),(17,33),(13,30)],"black")
        c.oval(16,21,4,5,"white")
        for i in 0..<4 {c.line([(15+Double(i),28),(14+Double(i),31)],i%2 == 0 ? "white":"slate")}
        c.poly([(20,31),(25,31),(23,36),(19,34)],"red")
        c.curve([(22,22),(25,19),(22+reach,17),(23+reach,15)],"white",width:3)
        c.oval(20+reach,10,8,7,"black",outline:true)
        c.poly([(20+reach,13),(26+reach,13),(27+reach,15),(22+reach,17)],"white")
        c.line([(20+reach,11),(20+reach,13)],"red",width:1.1)
        c.poly([(27+reach,12.5),(35+reach,13.7),(27+reach,14.3)],"dark")
        c.oval(25+reach,12,1,1,"eye");c.oval(25.4+reach,12,0.4,0.4,"white")
        c.line([(23,29),(25,33),(29,33),(28,34)],"brown",width:0.8)
        c.line([(23,34),(26,38),(29,38),(29,39)],"brown",width:0.8)
    }
}
