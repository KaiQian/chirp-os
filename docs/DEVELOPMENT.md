# 开发指南 / Development

## 项目结构 / Layout

| 目录 / Directory | 内容 / Contents |
| --- | --- |
| `platforms/macos/` | Swift / AppKit 应用与测试 / App and tests |
| `platforms/windows/` | C# / WinForms / Win32 应用与测试 / App and tests |
| `shared/` | 鸟种定义、像素图集和图标 / Species, atlases, and icon |
| `Assets/` | 文档图片与图标源图 / Documentation images and icon source |
| `scripts/` | 构建与验证脚本 / Build and verification scripts |
| `dist/` | 本地构建输出，不提交 / Local build outputs, ignored by Git |

## macOS

需要 macOS 13+ 和 Swift Command Line Tools。构建使用本机架构。
Requires macOS 13+ and Swift Command Line Tools. Builds target the host architecture.

```bash
./scripts/build.sh
./scripts/run.sh
./scripts/test.sh
```

应用 / App: `dist/ChirpOS.app`

桌面检查需要已登录的图形会话 / Desktop checks require an unlocked graphical session:

```bash
./scripts/verify-desktop.sh
./scripts/verify-population.sh
./scripts/verify-settings.sh
```

## Windows

需要 .NET 10 SDK。可在 Windows、macOS 或 Linux 上构建。
Requires .NET 10 SDK. Builds can run on Windows, macOS, or Linux.

```powershell
# Windows PowerShell
./scripts/build-windows.ps1 -Runtime win-x64
# Windows ARM64
./scripts/build-windows.ps1 -Runtime win-arm64
```

```bash
# macOS / Linux
./scripts/build-windows.sh win-arm64 win-x64
```

输出 / Outputs: `dist/windows/<runtime>/ChirpOS.exe` and `dist/releases/*.zip`.

Mac 上的 ARM64 构建还会复制到 `~/Downloads/share/ChirpOS.exe`；可用 `CHIRPOS_SHARE_DIR` 指定其他目录。
On Mac, ARM64 builds also copy to `~/Downloads/share/ChirpOS.exe`; override with `CHIRPOS_SHARE_DIR`.

核心测试 / Core tests:

```bash
dotnet run --project platforms/windows/ChirpOS.Tests -c Release
```

Windows 桌面检查 / Windows desktop checks: run `ChirpOS.exe --self-test`, or double-click `Verify-Windows.cmd` in the build directory. Results are saved to `%LOCALAPPDATA%\ChirpOS\self-test.json`.

## 美术 / Artwork

像素绘制定义位于 `platforms/macos/Sources/Birding/PixelArt.swift` 和 `SpeciesArt.swift`。修改后在 Mac 上导出共用资源，并提交 `shared/` 的变化。
Artwork is defined in `platforms/macos/Sources/Birding/PixelArt.swift` and `SpeciesArt.swift`. Export on Mac after editing, and commit the updated `shared/` assets.

```bash
./scripts/export-shared.sh
./scripts/preview-species.sh
```

## 本地数据 / Local data

- macOS: `~/Library/Application Support/Birding/settings.json`
- Windows: `%LOCALAPPDATA%\ChirpOS\settings.json`; diagnostics and errors are stored alongside it.

设置与构建缓存分开存储，清理缓存不会重置偏好。
Settings are separate from build caches; removing caches does not reset preferences.

## Signed macOS releases

Set `CHIRPOS_SIGNING_IDENTITY` to the full Developer ID Application identity, then run
`bash scripts/build.sh` and `bash scripts/notarize-macos.sh`. The latter uses the
`chirpos-notary` keychain profile (override with `CHIRPOS_NOTARY_PROFILE`), requires
an Accepted notarization result, staples and validates the app, then creates the release ZIP.
Local builds without a signing identity remain ad-hoc signed.

GitHub Actions requires repository variable `MACOS_SIGNING_IDENTITY` and secrets:
`MACOS_CERTIFICATE_P12_BASE64` (certificate plus private key),
`MACOS_CERTIFICATE_PASSWORD`, `APPLE_API_KEY_P8`, `APPLE_API_KEY_ID`,
and `APPLE_API_ISSUER_ID`. Missing credentials stop the release.
Never commit signing material. Configure these before using the release workflow.

Windows release assets are always ZIP archives containing ChirpOS.exe, LICENSE.txt,
README.md, and Verify-Windows.cmd. Both shell and PowerShell builds read the version
from ChirpOS.csproj. Extract the archive before launching the executable.
