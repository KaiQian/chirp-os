import Foundation
import CoreGraphics

// Examines only long, neutral, contrasting horizontal bands in an iTerm window.
// No OCR, terminal strings or images are retained. Unsupported/ambiguous bands yield no rails.
public enum ITermBarDetector {
    private struct Color: Equatable {
        let r:Int,g:Int,b:Int
        var neutral:Bool {max(r,g,b)-min(r,g,b)<=28}
        func distance(_ other:Color)->Int {max(abs(r-other.r),abs(g-other.g),abs(b-other.b))}
        var key:Int {(r/16)<<8 | (g/16)<<4 | b/16}
    }
    private struct Row {let color:Color;let flat:Double}
    public static func detect(rgba:[UInt8],width:Int,height:Int,windowSize:CGSize)->[PerchRail] {
        guard width>=120,height>=80,rgba.count==width*height*4,windowSize.width>0,windowSize.height>0 else {return []}
        func color(_ x:Int,_ y:Int)->Color {
            let i=(y*width+x)*4
            return Color(r:Int(rgba[i]),g:Int(rgba[i+1]),b:Int(rgba[i+2]))
        }
        let step=max(1,width/120)
        let rows:[Row]=(0..<height).map {y in
            var buckets:[Int:(count:Int,r:Int,g:Int,b:Int)]=[:]
            for x in stride(from:4,to:width-4,by:step) {
                let c=color(x,y),v=buckets[c.key] ?? (0,0,0,0)
                buckets[c.key]=(v.count+1,v.r+c.r,v.g+c.g,v.b+c.b)
            }
            let best=buckets.values.max{$0.count<$1.count}!
            return Row(color:Color(r:best.r/best.count,g:best.g/best.count,b:best.b/best.count),
                       flat:Double(best.count)/Double((width-8+step-1)/step))
        }
        // The prevailing terminal background must not itself become a perch.
        var frequencies:[Int:Int]=[:]
        for row in rows {frequencies[row.color.key,default:0]+=1}
        let backgroundKey=frequencies.max{$0.value<$1.value}!.key
        let background=rows.first{$0.color.key==backgroundKey}!.color
        let sx=windowSize.width/CGFloat(width),sy=windowSize.height/CGFloat(height)
        var rails:[PerchRail]=[],y=0,barIndex=0
        while y<height {
            let start=y,base=rows[y].color
            guard rows[y].flat>=0.72,base.neutral,base.distance(background)>=12 else {y+=1;continue}
            y+=1
            while y<height,rows[y].flat>=0.72,rows[y].color.neutral,rows[y].color.distance(base)<=12 {y+=1}
            let barHeight=CGFloat(y-start)*sy
            guard barHeight>=12,barHeight<=36 else {continue}
            let isTitle=CGFloat(start)*sy<=12
            // Uniform separators without labels/buttons cannot be distinguished from terminal output.
            var blocked=[Bool](repeating:false,count:width)
            for x in 3..<width-3 {
                var contrasts=0
                for yy in (start+2)..<max(start+2,y-2) {
                    if color(x,yy).distance(rows[yy].color)>28 {contrasts+=1}
                }
                blocked[x]=contrasts>=2
            }
            guard blocked.filter({$0}).count>=3 else {continue}
            var fingerprint:UInt64=14695981039346656037
            if !isTitle {
                for yy in stride(from:start+2,to:y-2,by:2) {
                    for x in stride(from:4,to:min(width-4,220),by:2) {
                        fingerprint=(fingerprint ^ UInt64(color(x,yy).key)) &* 1099511628211
                    }
                }
            }
            let kind:PerchRail.Kind=isTitle ? .titlebar:.paneBar
            let key=isTitle ? "titlebar":"pane-\(barIndex)-\(String(fingerprint,radix:16))"
            barIndex+=1
            var x=4,span=0
            while x<width-4 {
                while x<width-4 && blocked[x] {x+=1}
                let left=x
                while x<width-4 && !blocked[x] {x+=1}
                // The blank interval includes room on both sides for the bird's body.
                let lo=CGFloat(left)*sx+6,hi=CGFloat(x)*sx-6
                guard hi-lo>=100 else {continue}
                let footY=CGFloat(isTitle ? y:start)*sy
                rails.append(PerchRail(id:"\(key)-\(span)",kind:kind,rect:CGRect(x:lo,y:footY,width:hi-lo,height:1)))
                span+=1
            }
        }
        // When a tab strip is visible between the title bar and first pane header,
        // track its selection appearance separately from terminal output. Switching
        // otherwise identical panes must still release birds from the previous tab.
        if let title=rails.first(where:{$0.kind == .titlebar}),
           let first=rails.first(where:{$0.kind == .paneBar}),
           (15...48).contains(first.rect.minY-title.rect.minY) {
            let top=max(0,Int(title.rect.minY/sy)),bottom=min(height,Int(first.rect.minY/sy))
            var token:UInt64=14695981039346656037
            for yy in stride(from:top,to:bottom,by:2) {
                for x in stride(from:4,to:width-4,by:step) {token=(token ^ UInt64(color(x,yy).key)) &* 1099511628211}
            }
            rails=rails.map{PerchRail(id:$0.id+"-tab-"+String(token,radix:16),kind:$0.kind,rect:$0.rect)}
        }
        return rails
    }
}
