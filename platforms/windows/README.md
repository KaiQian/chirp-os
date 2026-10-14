# 啾啾 ChirpOS — Windows

## 中文

Windows 原生桌面观鸟应用。下载对应架构的 `.exe` 后直接运行；不需要微软商店、管理员权限或额外安装 .NET。托盘小鸟图标提供暂停、鸟群数量、七种鸟的概率滑块和输入、锁定、中英文切换、随系统启动及退出。

- `win-arm64`：Windows 11 ARM64，包括 Apple Silicon 上的 UTM 虚拟机。
- `win-x64`：Intel / AMD 64 位 Windows 10/11。
- 每次启动从零只开始，随后随机飞入、飞出。尺寸随鸟种体长和显示器 DPI 缩放。
- 飞行期间不采用目的窗口的遮挡深度；抵达后才切换。窗口顶沿必须有足够无遮挡空间才能着陆。
- 设置保存于 `%LOCALAPPDATA%\ChirpOS\settings.json`，错误日志为 `errors.log`，运行诊断为 `diagnostics.json`。
- 随系统启动使用当前用户的 Windows 登录启动项，不需要管理员权限；启用前将程序移到固定位置。
- 当前使用矩形估算遮挡；窗口圆角、透明内容和系统安全桌面有局限。设置中的「体型与动作」页可修改每种鸟的体长、振翅频率、飞速和停留时长；保存后用于新飞入的小鸟，旧版概率与锁定设置会保留。

开发：安装 .NET 10 SDK，在项目根目录执行 `./scripts/build-windows.ps1 -Runtime win-arm64`（或 `win-x64`）。Mac 可执行 `./scripts/build-windows.sh win-arm64 win-x64`。输出位于 `dist/windows/`，用于发布的 `.exe` 在 `dist/releases/`；Mac 构建 ARM64 后还会复制到 `~/Downloads/share/ChirpOS.exe`。仓库中包含共享素材，无需在 Windows 上运行 Swift。

核心测试：`dotnet run --project platforms/windows/ChirpOS.Tests -c Release`，可在 Mac 或 Windows 执行。
桌面验证：本机构建目录中可双击 `Verify-Windows.cmd` 查看自检结果，或在已登录的 Windows 桌面运行 `ChirpOS.exe --self-test`，会短暂打开并移动专用测试窗口，结果在 `%LOCALAPPDATA%\ChirpOS\self-test.json`；不移动用户窗口，不改动登录项。

## English

A native Windows desktop birdwatching app. Download and run the `.exe` for your architecture. No Microsoft Store, administrator access, or separately installed .NET runtime is required. The tray menu offers pause, population presets, seven species with sliders/numeric probabilities and locks, language switching, Launch at Login, and quit.

Use `win-arm64` for Windows 11 ARM64 (including UTM on Apple Silicon), or `win-x64` for Intel/AMD Windows 10/11. Birds arrive from outside the screen, perch on exposed window edges, follow slow movement, and startle on fast drags. Flight depth changes only on arrival. Bird sizes follow adult species proportions and monitor DPI.

Settings and diagnostics live in `%LOCALAPPDATA%\ChirpOS`. Login startup is per-user; keep the executable in a stable location before enabling it. Occlusion approximates rectangular windows; rounded corners, transparency, and secure system desktops have limitations. The Size & behavior tab edits each species’ length, wingbeat rate, speed, and perch duration. Saved values apply to future arrivals; existing probabilities and locks are preserved.

Build with .NET 10 SDK: `./scripts/build-windows.ps1 -Runtime win-arm64` or `win-x64` from the repo root. On macOS: `./scripts/build-windows.sh win-arm64 win-x64`. Outputs: `dist/windows/` and `dist/releases/`. Shared assets are included in the repository; Windows development does not require Swift.

Core tests: `dotnet run --project platforms/windows/ChirpOS.Tests -c Release`. Desktop checks: in the local build directory, double-click `Verify-Windows.cmd` to view the report, or run `ChirpOS.exe --self-test` in an unlocked Windows session. It creates and moves dedicated test windows, writes `%LOCALAPPDATA%\ChirpOS\self-test.json`, and leaves user windows and login settings untouched.

## 验证状态 / Validation status

2026-10-14：用户已确认 0.3.0 在 UTM Windows ARM64 中可运行并显示小鸟。0.3.1 增加体型与动作设置，过滤透明拖动辅助窗口，并保留窗口类别、边界和样式诊断（不读取标题或内容）。新版 ARM64 / x64 在 Mac 上交叉构建；自动核心回归检查覆盖遮挡过滤、参数保存与生效。用户随后确认 0.3.1 在虚拟机中测试正常，包括本轮问题修复；x64 已构建，尚未在 x64 Windows 上实测。

2026-10-14: The user confirmed that 0.3.0 runs and displays birds in UTM Windows ARM64. Version 0.3.1 adds size/behavior settings, filters transparent drag helpers, and records window classes, bounds, and styles locally (no titles or content). ARM64/x64 are cross-built on Mac; core regression checks cover filtering and behavior persistence/application. The user subsequently confirmed that 0.3.1 works correctly in the ARM64 VM after testing the changes. The x64 build has not been tested on an x64 Windows desktop.
