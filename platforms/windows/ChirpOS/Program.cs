using System.Reflection;
using System.Text.Json;
using ChirpOS.Core;
namespace ChirpOS;

internal static class Program
{
    internal static readonly string DataFolder = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData), "ChirpOS");
    internal static Stream Resource(string name) => Assembly.GetExecutingAssembly().GetManifestResourceStream(name) ?? throw new FileNotFoundException(name);
    internal static readonly JsonSerializerOptions Json = new() { PropertyNameCaseInsensitive = true, WriteIndented = true };
    internal static void Log(Exception e) { try { Directory.CreateDirectory(DataFolder); File.AppendAllText(Path.Combine(DataFolder, "errors.log"), DateTimeOffset.Now + " " + e + Environment.NewLine); } catch { } }
    [STAThread]
    static void Main(string[] args)
    {
        using var mutex = new Mutex(true, "Local\\ChirpOS.Desktop", out var first); if (!first && !args.Contains("--self-test") && !args.Contains("--fixture")) return;
        Application.SetHighDpiMode(HighDpiMode.PerMonitorV2); Application.EnableVisualStyles(); Application.SetCompatibleTextRenderingDefault(false);
        Application.ThreadException += (_, e) => { Log(e.Exception); MessageBox.Show(e.Exception.Message, "ChirpOS"); Application.Exit(); };
        try { if (args.Contains("--fixture")) { DesktopVerification.Fixture(); return; } if (args.Contains("--self-test")) { DesktopVerification.Run(args); return; } Application.Run(new Desktop()); }
        catch (Exception e) { Log(e); MessageBox.Show(e.Message, "ChirpOS — 启动失败 / Startup failed"); }
    }
}
