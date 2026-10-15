using ChirpOS.Core;
namespace ChirpOS;
internal sealed class NewSpeciesPrompt:Form {
    public int Choice {get;private set;}=-1;
    public NewSpeciesPrompt(Desktop d,int count) {
        Text=d.T($"发现 {count} 种新鸟",$"{count} new bird species");ClientSize=new(650,330);FormBorderStyle=FormBorderStyle.FixedDialog;MaximizeBox=false;MinimizeBox=false;StartPosition=FormStartPosition.CenterScreen;
        var share=100d*count/d.Species.Length;
        var text=new Label{Location=new(20,20),Size=new(610,195),Text=d.T(
            $"如何分配出现概率？\n\n恢复默认：重置所有概率并解除锁定，保留体型与动作设置。\n\n按数量分配：新鸟获得 {share:F2}%，内部按默认比例分配；旧鸟等比缩放（包括锁定项，锁定状态保留）。\n\n手动设置：保留旧概率，新鸟为 0%，定位到第一种新鸟。",
            $"Choose arrival probabilities.\n\nDefaults: reset probabilities and unlock them; keep size and behavior.\n\nBy count: new birds share {share:F2}% using defaults. Scale existing values, including locked ones, keeping locks.\n\nManual: keep existing values, new birds at 0%, and jump to the first new bird.")};Controls.Add(text);
        var labels=new[]{d.T("所有概率恢复默认","Restore default probabilities"),d.T("按鸟种数量分配","Allocate by species count"),d.T("手动设置…","Set manually…")};
        for(var i=0;i<3;i++){var index=i;var button=new Button{Text=labels[i],Location=new(20+i*210,245),Size=new(195,58)};button.Click+=(_,_)=>{Choice=index;DialogResult=DialogResult.OK;Close();};Controls.Add(button);}
    }
}
