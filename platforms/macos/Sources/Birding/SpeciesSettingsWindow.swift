import AppKit
import BirdingCore

final class SettingsContentView: NSView {
    override var isFlipped: Bool { true }
    override var isOpaque: Bool { true }
    override func draw(_ dirtyRect:NSRect) { NSColor.windowBackgroundColor.setFill(); dirtyRect.intersection(bounds).fill() }
}
final class SpeciesSettingsWindow: NSWindowController, NSTextFieldDelegate {
    unowned let desktop: DesktopController
    var draft: BirdSettings
    var sliders:[NSSlider] = [], fields:[NSTextField] = [], locks:[NSButton] = []
    var detailFields:[[NSTextField]] = []
    var message: NSTextField!
    var tabs: NSTabView!
    var language: AppLanguage { desktop.language }
    func t(_ zh:String,_ en:String) -> String { language.text(zh,en) }
    init(desktop:DesktopController) {
        self.desktop = desktop; self.draft = desktop.settings
        let window = NSWindow(contentRect:NSRect(x:0,y:0,width:840,height:690),styleMask:[.titled,.closable,.miniaturizable],backing:.buffered,defer:false)
        window.isReleasedWhenClosed = false
        super.init(window:window)
        build(); window.center()
    }
    required init?(coder:NSCoder) { fatalError() }
    @discardableResult func label(_ text:String,_ rect:NSRect,in view:NSView,size:CGFloat = 13) -> NSTextField {
        let l = NSTextField(wrappingLabelWithString:text); l.font = .systemFont(ofSize:size); l.frame = rect; view.addSubview(l); return l
    }
    func button(_ title:String,_ action:Selector,_ rect:NSRect,in view:NSView) -> NSButton {
        let b = NSButton(title:title,target:self,action:action); b.bezelStyle = .rounded; b.frame = rect; view.addSubview(b); return b
    }
    func build() {
        let selected = tabs?.indexOfTabViewItem(tabs!.selectedTabViewItem!) ?? 0
        sliders=[]; fields=[]; locks=[]; detailFields=[]
        let root = SettingsContentView(frame:NSRect(x:0,y:0,width:840,height:690)); root.wantsLayer=true; window!.contentView = root
        window!.title = t("鸟种设置","Bird Settings")
        label(t("让哪些鸟来做客？","Which birds should visit?"),NSRect(x:26,y:22,width:760,height:35),in:root,size:25)
        label(t("调整入场概率；保存后影响新飞入的小鸟，已在屏幕上的鸟保持原样。","Set arrival probabilities. Saved changes affect new arrivals; existing birds keep their profiles."),NSRect(x:26,y:65,width:785,height:40),in:root)
        let probabilityButton=button(t("出现概率","Arrival probabilities"),#selector(selectPage(_:)),NSRect(x:235,y:112,width:185,height:30),in:root); probabilityButton.tag=0
        let behaviorButton=button(t("体型与动作","Size & behavior"),#selector(selectPage(_:)),NSRect(x:430,y:112,width:175,height:30),in:root); behaviorButton.tag=1
        tabs = NSTabView(frame:NSRect(x:30,y:150,width:780,height:446)); tabs.tabViewType = .noTabsNoBorder; root.addSubview(tabs)
        let probabilityView = SettingsContentView(frame:NSRect(x:0,y:0,width:774,height:445))
        let first = NSTabViewItem(identifier:"probabilities"); first.label=t("出现概率","Arrival probabilities"); first.view=probabilityView; tabs.addTabViewItem(first)
        label(t("鸟种","Species"),NSRect(x:20,y:14,width:240,height:23),in:probabilityView)
        label(t("概率（%）","Probability (%)"),NSRect(x:294,y:14,width:305,height:23),in:probabilityView)
        for (i,entry) in draft.probabilities.entries.enumerated() {
            let y = CGFloat(44+i*47)
            let icon = NSImageView(frame:NSRect(x:16,y:y,width:38,height:38))
            icon.image = NSImage(cgImage:desktop.arts[entry.id]!.frames["stand"]!,size:NSSize(width:38,height:38)); probabilityView.addSubview(icon)
            label(language.name(entry.id),NSRect(x:62,y:y+8,width:222,height:26),in:probabilityView)
            let slider = NSSlider(value:0,minValue:0,maxValue:100,target:self,action:#selector(sliderChanged(_:)))
            slider.isContinuous=true; slider.tag=i; slider.frame=NSRect(x:290,y:y+8,width:236,height:24)
            slider.setAccessibilityLabel(language.name(entry.id)+t(" 概率"," probability")); probabilityView.addSubview(slider); sliders.append(slider)
            let field = NSTextField(frame:NSRect(x:542,y:y+7,width:72,height:25)); field.tag=i; field.delegate=self; field.alignment = .right
            field.setAccessibilityLabel(language.name(entry.id)+t(" 概率百分比"," probability percentage")); probabilityView.addSubview(field); fields.append(field)
            label("%",NSRect(x:620,y:y+10,width:20,height:20),in:probabilityView)
            let lock = NSButton(checkboxWithTitle:t("锁定","Lock"),target:self,action:#selector(lockChanged(_:)))
            lock.tag=i; lock.frame=NSRect(x:657,y:y+7,width:95,height:25); probabilityView.addSubview(lock); locks.append(lock)
        }
        label(t("总计 100.00% · 锁定项不变；其他未锁定项按原比例分配，均为零时平均分配。\n默认值参考上海观测，部分鸟种为估计值。","Total 100.00% · Locked values stay fixed. Other unlocked values redistribute proportionally, or equally when all are zero. Defaults use Shanghai observations and some estimates."),NSRect(x:20,y:383,width:730,height:54),in:probabilityView,size:12)
        let detailView = SettingsContentView(frame:probabilityView.frame)
        let second = NSTabViewItem(identifier:"behavior"); second.label=t("体型与动作","Size & behavior"); second.view=detailView; tabs.addTabViewItem(second)
        let titles = [t("体长 cm","Length cm"),t("振翅 次/秒","Beats / sec"),t("飞速 倍率","Speed ×"),t("最短停留 秒","Min perch s"),t("最长停留 秒","Max perch s")]
        label(t("鸟种","Species"),NSRect(x:20,y:14,width:235,height:25),in:detailView)
        for (j,title) in titles.enumerated() { label(title,NSRect(x:270+j*97,y:14,width:95,height:30),in:detailView,size:11) }
        for (i,entry) in draft.probabilities.entries.enumerated() {
            let p=draft.catalog.profile(entry.id), y=CGFloat(52+i*45)
            label(language.name(entry.id),NSRect(x:20,y:y+3,width:238,height:30),in:detailView)
            var row:[NSTextField]=[]
            for (j,value) in [p.adultLengthCM,p.flapFPS/8,p.speed,p.perchMin,p.perchMax].enumerated() {
                let f=NSTextField(frame:NSRect(x:CGFloat(270+j*97),y:y,width:84,height:26)); f.stringValue=String(value)
                f.tag=100+i*10+j; f.delegate=self; f.alignment = .right; f.setAccessibilityLabel(language.name(entry.id)+" "+titles[j]); detailView.addSubview(f); row.append(f)
            }
            detailFields.append(row)
        }
        label(t("体长以成年鸟为参考；振翅和停留时长是动画参数，可按喜好调整。\n体长 10–40 cm · 振翅 0.5–7.5 次/秒 · 飞速 0.5–2× · 最短 2–300 秒 · 最长不超过 600 秒。","Adult body length sets relative size; animation timing is adjustable.\nLength 10–40 cm · Beats 0.5–7.5/s · Speed 0.5–2× · Minimum perch 2–300s · Maximum ≤600s."),NSRect(x:20,y:383,width:735,height:55),in:detailView,size:12)
        tabs.selectTabViewItem(at:min(selected,1))
        message=label("",NSRect(x:26,y:603,width:784,height:28),in:root,size:12)
        _=button(t("恢复默认","Restore Defaults"),#selector(resetDefaults),NSRect(x:22,y:642,width:148,height:30),in:root)
        _=button(t("取消","Cancel"),#selector(cancel),NSRect(x:562,y:642,width:100,height:30),in:root)
        let save=button(t("保存并应用","Save & Apply"),#selector(save),NSRect(x:672,y:642,width:144,height:30),in:root); save.keyEquivalent="\r"
        refresh()
    }
    @objc func selectPage(_ sender:NSButton) { window?.makeFirstResponder(nil); tabs.selectTabViewItem(at:sender.tag) }
    func refresh() {
        for (i,e) in draft.probabilities.entries.enumerated() {
            sliders[i].doubleValue=Double(e.points)/100; fields[i].stringValue=String(format:"%.2f",Double(e.points)/100)
            locks[i].state=e.locked ? .on:.off
            sliders[i].isEnabled=draft.probabilities.canAdjust(i); fields[i].isEnabled=sliders[i].isEnabled
            let tip=t("可用上限：","Available maximum: ")+String(format:"%.2f%%",Double(draft.probabilities.maximum(at:i))/100)
            sliders[i].toolTip=tip; fields[i].toolTip=tip
        }
    }
    func number(_ s:String) -> Double? {
        Double(s.trimmingCharacters(in:.whitespacesAndNewlines).replacingOccurrences(of:"%",with:"").replacingOccurrences(of:",",with:"."))
    }
    func change(_ i:Int,_ value:Double) {
        guard value.isFinite else { return }
        let requested=Int((min(100,max(0,value))*100).rounded())
        let actual=draft.probabilities.adjust(at:i,to:requested)
        message.stringValue = actual != requested || value < 0 || value > 100
            ? t("已限制到可用概率，锁定项保持不变。","Limited to the available probability; locked values were preserved.") : t("尚未保存","Unsaved changes")
        refresh()
    }
    @objc func sliderChanged(_ sender:NSSlider) { let value=sender.doubleValue; window?.makeFirstResponder(nil); change(sender.tag,value) }
    @objc func lockChanged(_ sender:NSButton) {
        let locked=sender.state == .on
        window?.makeFirstResponder(nil)
        draft.probabilities.setLocked(locked,at:sender.tag); refresh()
        message.stringValue=t("尚未保存 · 仅剩一个未锁定项时无法调整概率。","Unsaved changes · Adjustment needs at least two unlocked species.")
    }
    func controlTextDidEndEditing(_ obj:Notification) {
        guard let f=obj.object as? NSTextField else { return }
        if f.tag < 100 {
            guard let value=number(f.stringValue),value.isFinite else {
                message.stringValue=t("请输入有效的百分比数值。","Enter a valid percentage."); refresh(); return
            }
            change(f.tag,value)
        } else { message.stringValue=t("尚未保存","Unsaved changes") }
    }
    func readDetails() -> Bool {
        var catalog=draft.catalog
        for (i,entry) in draft.probabilities.entries.enumerated() {
            let row=detailFields[i], values=row.map { number($0.stringValue) }
            guard values.allSatisfy({$0?.isFinite == true}) else { return false }
            let v=values.map{$0!}
            guard (10...40).contains(v[0]), (0.5...7.5).contains(v[1]), (0.5...2).contains(v[2]), (2...300).contains(v[3]), v[4]>=v[3],v[4]<=600 else { return false }
            let index=draft.catalog.species.firstIndex{$0.id==entry.id}!
            catalog.species[index].adultLengthCM=v[0]; catalog.species[index].flapFPS=v[1]*8
            catalog.species[index].speed=v[2]; catalog.species[index].perchMin=v[3]; catalog.species[index].perchMax=v[4]
        }
        draft.catalog=catalog
        return true
    }
    @objc func save() {
        window?.makeFirstResponder(nil)
        guard readDetails() else { tabs.selectTabViewItem(at:1); message.stringValue=t("请检查体型与动作数值：最长停留不能小于最短停留。","Check size and behavior ranges; maximum perch time must not be below minimum."); return }
        do { try desktop.applySettings(draft); message.stringValue=t("已保存 · 新飞入的小鸟将使用这些设置。","Saved · New arrivals will use these settings.") }
        catch { message.stringValue=t("保存失败，请重试。当前设置未改变。","Could not save. Try again; active settings are unchanged.") }
    }
    @objc func resetDefaults() { window?.makeFirstResponder(nil); draft=BirdSettings(); build(); message.stringValue=t("已恢复默认（尚未保存，锁定已清除）。","Defaults restored (not saved; locks cleared).") }
    @objc func cancel() { window?.close() }
    func relocalize() {
        window?.makeFirstResponder(nil)
        let raw = detailFields.map { $0.map(\.stringValue) }
        build()
        for i in raw.indices { for j in raw[i].indices { detailFields[i][j].stringValue = raw[i][j] } }
    }
}
