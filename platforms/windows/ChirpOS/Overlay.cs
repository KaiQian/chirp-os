using System.Drawing.Drawing2D;
using System.Drawing.Imaging;
using ChirpOS.Core;
namespace ChirpOS;
// One small layered window per bird keeps alpha compositing cheap even on 4K screens.
internal sealed class Overlay : Form
{
    protected override bool ShowWithoutActivation => true;
    protected override CreateParams CreateParams { get { var c = base.CreateParams; c.ExStyle |= 0x80000 | 0x20 | 0x80 | 0x8000000; return c; } }
    public Overlay() { FormBorderStyle = FormBorderStyle.None; ShowInTaskbar = false; StartPosition = FormStartPosition.Manual; AutoScaleMode = AutoScaleMode.None; Size = new(1, 1); }
    protected override void WndProc(ref Message m) { if (m.Msg == 0x21) { m.Result = (nint)3; return; } if (m.Msg == 0x84) { m.Result = (nint)(-1); return; } base.WndProc(ref m); }
    public void Render(Bird bird, Bitmap atlas, int frame, double scale, IReadOnlyList<Surface> surfaces)
    {
        var size = Math.Max(1, (int)Math.Ceiling(48 * scale)); var x = (int)Math.Round(bird.Position.X - (bird.Right ? 29 : 19) * scale); var y = (int)Math.Round(bird.Position.Y + (bird.Hop - 39) * scale);
        using var bitmap = new Bitmap(size, size, PixelFormat.Format32bppPArgb);
        using (var g = Graphics.FromImage(bitmap))
        {
            g.CompositingMode = CompositingMode.SourceCopy; g.Clear(Color.Transparent); g.InterpolationMode = InterpolationMode.NearestNeighbor; g.PixelOffsetMode = PixelOffsetMode.Half;
            using var region = new Region(new Rectangle(0, 0, size, size));
            foreach (var r in bird.Blockers(surfaces)) region.Exclude(new RectangleF((float)(r.X - x), (float)(r.Y - y), (float)r.W, (float)r.H));
            g.SetClip(region, CombineMode.Replace);
            if (!bird.Right) { g.TranslateTransform(size, 0); g.ScaleTransform(-1, 1); }
            g.DrawImage(atlas, new Rectangle(0, 0, size, size), new Rectangle(frame * atlas.Height, 0, atlas.Height, atlas.Height), GraphicsUnit.Pixel);
        }
        Present(bitmap,x,y);
    }
    public void RenderName(string name,V foot,double scale,int topPixel) {
        using var font=new Font("Segoe UI",10);
        var measured=TextRenderer.MeasureText(name,font);
        var screen=Screen.FromPoint(new((int)foot.X,(int)foot.Y)).WorkingArea;
        var width=Math.Min(screen.Width,measured.Width+20);var height=measured.Height+8;
        using var bitmap=new Bitmap(width,height,PixelFormat.Format32bppPArgb);
        using(var g=Graphics.FromImage(bitmap)) {
            g.Clear(Color.FromArgb(220,25,27,31));
            g.TextRenderingHint=System.Drawing.Text.TextRenderingHint.AntiAliasGridFit;
            g.DrawString(name,font,Brushes.White,8,3);
        }
        Present(bitmap,Math.Clamp((int)foot.X-width/2,screen.Left,screen.Right-width),Math.Max(screen.Top,(int)(foot.Y+(topPixel-39)*scale)-height-5));
    }
    void Present(Bitmap bitmap,int x,int y) {
        var screenDc = Native.GetDC(0); var memoryDc = Native.CreateCompatibleDC(screenDc); var hb = bitmap.GetHbitmap(Color.FromArgb(0)); var old = Native.SelectObject(memoryDc, hb);
        try
        {
            var location = new Native.Point(x, y); var dimensions = new Native.Size(bitmap.Width, bitmap.Height); var source = new Native.Point(0, 0); var blend = new Native.Blend { Alpha = 255, Format = 1 };
            if (!Native.UpdateLayeredWindow(Handle, screenDc, ref location, ref dimensions, memoryDc, ref source, 0, ref blend, 2)) throw new System.ComponentModel.Win32Exception();
            if (!Visible) Show();
            Native.SetWindowPos(Handle, (nint)(-1), 0, 0, 0, 0, 0x1 | 0x2 | 0x10 | 0x40);
        }
        finally { Native.SelectObject(memoryDc, old); Native.DeleteObject(hb); Native.DeleteDC(memoryDc); Native.ReleaseDC(0, screenDc); }
    }
}
