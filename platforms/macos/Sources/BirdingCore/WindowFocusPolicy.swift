import Foundation

public enum WindowFocusPolicy {
    // Use accessibility bounds when available; otherwise use the foreground
    // application's foremost normal window. Other windows of that app remain eligible.
    public static func windowID(in surfaces:[Surface], frontPID:Int32?, focusedBounds:CGRect? = nil) -> UInt32? {
        guard let pid=frontPID else {return nil}
        let candidates=surfaces.filter{$0.pid==pid}
        if let bounds=focusedBounds, let match=candidates.first(where:{
            abs($0.rect.minX-bounds.minX)<3 && abs($0.rect.minY-bounds.minY)<3 &&
            abs($0.rect.width-bounds.width)<3 && abs($0.rect.height-bounds.height)<3
        }) {return match.id}
        return candidates.first(where:{$0.layer==0})?.id
    }
}
