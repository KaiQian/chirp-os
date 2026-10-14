import AppKit

func argument(_ flag:String) -> String? {
    guard let i = CommandLine.arguments.firstIndex(of:flag),i+1<CommandLine.arguments.count else { return nil }
    return CommandLine.arguments[i+1]
}
let app = NSApplication.shared
app.setActivationPolicy(.accessory)
if let path = argument("--export-art") {
    do { try BirdArt().export(to:URL(fileURLWithPath:path)); exit(0) }
    catch { fputs("Art export failed: \(error)\n",stderr); exit(1) }
}
if let path = argument("--export-species") {
    do { try BirdArt.exportSpecies(to:URL(fileURLWithPath:path)); exit(0) }
    catch { fputs("Species export failed: \(error)\n",stderr); exit(1) }
}
final class AppDelegate: NSObject, NSApplicationDelegate {
    var desktop: DesktopController?
    var fixture: FixtureController?
    var populationCheck: PopulationVerification?
    func applicationDidFinishLaunching(_ notification:Notification) {
        if let path = argument("--verify-settings") { SettingsVerification.run(to:URL(fileURLWithPath:path)); return }
        if let path = argument("--fixture") {
            fixture = FixtureController(folder:URL(fileURLWithPath:path)); fixture?.start()
        } else {
            let d = DesktopController(); desktop = d
            d.diagnosticPath = argument("--diagnostics"); d.start()
            if let path = argument("--verify-population") {
                populationCheck = PopulationVerification(desktop:d,path:path); populationCheck?.start()
            }
            if let path = argument("--integration") {
                let check = IntegrationCheck(desktop:d,folder:URL(fileURLWithPath:path))
                d.integration = check; check.start()
            }
        }
    }
    func applicationShouldTerminateAfterLastWindowClosed(_ sender:NSApplication) -> Bool { false }
}
let delegate = AppDelegate()
app.delegate = delegate
app.run()
