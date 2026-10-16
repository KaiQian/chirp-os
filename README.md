# 啾啾 ChirpOS

**下载 / Download**

| 平台 / Platform | 最新版本 / Latest release |
| --- | --- |
| Windows · Intel / AMD 64-bit | [下载 ZIP · v0.4.0](https://github.com/billtt/chirp-os/releases/download/v0.4.0/ChirpOS-0.4.0-win-x64.zip) |
| Windows · ARM64 / UTM | [下载 ZIP · v0.4.0](https://github.com/billtt/chirp-os/releases/download/v0.4.0/ChirpOS-0.4.0-win-arm64.zip) |
| macOS · Apple Silicon | [下载 ZIP · v0.4.0](https://github.com/billtt/chirp-os/releases/download/v0.4.0/ChirpOS-0.4.0-macOS-arm64.zip) |

[所有版本 / All releases](https://github.com/billtt/chirp-os/releases) · [简体中文](#中文) · [English](#english)

![啾啾桌面运行预览 / ChirpOS desktop preview](preview.gif)

**让你的桌面，时不时来只鸟。 / A little birdlife on your desktop.**


## 中文

啾啾是一款 macOS 和 Windows 桌面观鸟应用。像素小鸟从屏幕外飞来，在窗口顶沿歇脚、眨眼、理羽，陪你工作。它们不抢焦点，也不会挡住鼠标操作。

### 有什么好玩的

- 多种小鸟，各有鲜明外形和习性动作，详见下方[鸟种列表](#鸟种--bird-species)。
- 小鸟随窗口缓慢移动，快速拖动时可能受惊飞走；前方窗口会遮住后方停留的小鸟。
- 鸟群随机飞入、飞出，可设置数量范围，例如 3–5、8–12 或 15–20 只；同种最多两只，以同种一对群栖为主。
- 自由调整每种鸟的出现概率并锁定；也可设置体长、振翅频率、飞速和停留时间。
- 鼠标停在小鸟身上约 1 秒，头顶就会显示名字；点击仍会穿透。
- 夜鹭会长时间守望、伸颈、抖毛，偶尔“挤洗手液”；大斑啄木鸟会沿窗口侧边停靠、啄击。
- 菜单中的“鸟种测试”打开白底动画图鉴，网格展示全部鸟种与循环动作。
- macOS 上可停在 iTerm2 标题栏和分屏栏、Chrome 地址栏与书签栏空白处、飞书侧栏和消息标题空白区，随布局移动并避开控件。
- 支持中英文切换、暂停动画和随系统启动。

### 鸟种 / Bird species

| 中文 | English |
| --- | --- |
| 红耳鹎 | Red-whiskered Bulbul |
| 麻雀 | Eurasian Tree Sparrow |
| 白头鹎 | Light-vented Bulbul |
| 珠颈斑鸠 | Spotted Dove |
| 乌鸫 | Chinese Blackbird |
| 鹊鸲 | Oriental Magpie-Robin |
| 棕背伯劳 | Long-tailed Shrike |
| 夜鹭 | Black-crowned Night Heron |
| 红尾水鸲 | Plumbeous Water Redstart |
| 白鹭 | Little Egret |
| 苍鹭 | Grey Heron |
| 红隼 | Common Kestrel |
| 游隼 | Peregrine Falcon |
| 黑鸢 | Black Kite |
| 普通鵟 | Common Buzzard |
| 喜鹊 | Oriental Magpie |
| 灰喜鹊 | Azure-winged Magpie |
| 大嘴乌鸦 | Large-billed Crow |
| 戴胜 | Eurasian Hoopoe |
| 家燕 | Barn Swallow |
| 绿头鸭 | Mallard |
| 噪鹃 | Asian Koel |
| 暗绿绣眼鸟 | Swinhoe’s White-eye |
| 红嘴鸥 | Black-headed Gull |
| 中杓鹬 | Whimbrel |
| 斑鱼狗 | Pied Kingfisher |
| 丘鹬 | Eurasian Woodcock |
| 黑卷尾 | Black Drongo |
| 池鹭 | Chinese Pond Heron |
| 白眉姬鹟 | Yellow-rumped Flycatcher |
| 黄眉柳莺 | Yellow-browed Warbler |
| 大山雀 | Great Tit |
| 黑水鸡 | Common Moorhen |
| 大斑啄木鸟 | Great Spotted Woodpecker |
| 棕头鸦雀 | Vinous-throated Parrotbill |
| 黑翅长脚鹬 | Black-winged Stilt |
| 白骨顶 | Eurasian Coot |
| 红嘴相思鸟 | Red-billed Leiothrix |
| 黑领椋鸟 | Black-collared Starling |
| 普通翠鸟 | Common Kingfisher |
| 金眶鸻 | Little Ringed Plover |
| 黑尾蜡嘴雀 | Yellow-billed Grosbeak |
| 红胁蓝尾鸲 | Red-flanked Bluetail |

### 开始观鸟

**Windows：** 下载对应架构的 ZIP，解压后运行 ChirpOS.exe，无需安装 .NET。支持 Windows 10/11 x64 和 Windows 11 ARM64。

**macOS：** 下载并解压 ZIP，将 `ChirpOS.app` 拖入“应用程序”后打开。下载版适用于 macOS 13 及以上的 Apple Silicon Mac。

启动后稍等片刻，小鸟就会陆续飞入。点击 macOS 菜单栏或右键点击 Windows 系统托盘中的小鸟图标，即可调整设置或退出。Windows 图标可能位于托盘的隐藏图标区域。更新前请先退出正在运行的版本。

启动时发现新增鸟种，会询问是恢复所有默认概率、按新旧鸟种数量比例分配，还是保留原概率并手动设置。手动模式会直接定位到第一种新鸟；按数量分配会缩放锁定项，但保留锁定状态。体型按成年鸟代表体长进行非线性缩放（红耳鹎 1×、苍鹭 2.5×），部分配色采用雄鸟或繁殖羽；动作经过像素化简化。

macOS 版本使用 Developer ID 签名并经过 Apple 公证。Windows 版本尚未使用发布者证书签名，首次打开可能遇到系统安全提示。

如需应用内部停栖，在 macOS 菜单中点击“启用应用内部停栖…”，并在系统设置中允许啾啾使用辅助功能。已有权限时会自动识别，也可通过同一菜单关闭；顶部空间不足的位置不会提供落点，编辑 Chrome 地址栏时鸟会让开。同种两只上限优先于总数下限，仅启用一种鸟时最多显示两只。

### 隐私与反馈

啾啾在本机运行，不上传数据。常规停栖读取窗口位置、前后顺序和用于悬停识别的鼠标位置。应用内部停栖在获得权限后，还会读取栏位、控件及标题标签用于避让，并在内存中测量 Chrome 地址栏文字宽度；不遍历网页和聊天内容，不保存网址或消息。iTerm2 原生信息不可用时，macOS 14+ 可在已有屏幕录制权限下于内存中分析单窗口画面，不做 OCR，不保存终端画面或内容。窗口遮挡按矩形估算，透明窗口、圆角和特殊系统界面的效果可能有所不同。

遇到问题或有新点子，欢迎提交 [Issue](https://github.com/billtt/chirp-os/issues)。想自己构建或贡献代码，请看[开发指南](docs/DEVELOPMENT.md)。

## English

ChirpOS brings pixel-art birds to your macOS or Windows desktop. They fly in from offscreen, perch on window edges, blink, and preen while you work—without taking focus or intercepting mouse clicks.

### Features

- Distinctive bird species, each with its own appearance and behavior. See the [Chinese–English species list](#鸟种--bird-species).
- Birds follow gently moved windows and may startle when dragged quickly. Foreground windows hide birds perched behind them.
- Birds arrive and leave at random, with configurable population ranges such as 3–5, 8–12, or 15–20. Each species is limited to two birds, with social gatherings favoring conspecific pairs.
- Adjust and lock arrival probabilities, and customize size, wingbeat rate, speed, and perch duration.
- Hover over a bird for about 1 second to see its name, with clicks still passing through.
- Night herons watch, stretch, shake and occasionally leave a fleeting dropping; woodpeckers cling to and peck window sides.
- Open “Bird test” from the menu for a white-background grid of all species cycling through their animations.
- Perch on blank iTerm2 title/pane bars, Chrome address/bookmark bars, and Feishu sidebar/message headers on macOS, following layout changes and avoiding controls.
- Chinese and English menus, animation pause, and launch at login.

### Get started

**Windows:** Download the ZIP for your architecture, extract it, and run ChirpOS.exe. No separate .NET installation is needed. Supports Windows 10/11 x64 and Windows 11 ARM64.

**macOS:** Extract the ZIP, move `ChirpOS.app` to Applications, and open it. The download supports Apple Silicon Macs running macOS 13 or later.

Birds begin arriving shortly after launch. Use the macOS menu bar icon or right-click the Windows tray icon for settings and quit. The Windows icon may be in the hidden-icons area. Quit the running version before updating.

When new species are detected at startup, choose default probabilities, allocation by species count, or manual configuration. Manual mode jumps to the first new species. Count-based allocation scales locked values but retains their lock state. Sizes use compressed adult-length ratios (bulbul 1×, Grey Heron 2.5×); some designs show males or breeding plumage, with stylized pixel animation.

The macOS app is Developer ID-signed and notarized by Apple. Windows builds are not publisher-signed, so a system security prompt may appear on first launch.

For interior app perches, select “Enable perching inside apps…” from the macOS menu and grant ChirpOS Accessibility access in System Settings. Discovery is automatic when permission already exists; the same menu can disable it. Positions without enough headroom remain unavailable, and birds leave the Chrome address bar while it is being edited. The two-per-species limit takes precedence over the population minimum; enabling only one species allows at most two birds.

### Privacy & feedback

ChirpOS runs locally and uploads no data. Ordinary perches use window geometry, stacking order and pointer position for hover identification. With permission, interior perches read bar/control geometry and header labels, and measure Chrome address text width in memory. Web pages and conversations are excluded from traversal; URLs and messages are not stored. When native iTerm2 metadata is unavailable, macOS 14+ can analyze an authorized window-only capture in memory; no OCR or terminal image/content storage. Occlusion uses rectangular bounds; transparent windows, rounded corners, and special system views may look different.

Report a bug or suggest an idea in [Issues](https://github.com/billtt/chirp-os/issues). For building and contributing, see the [development guide](docs/DEVELOPMENT.md).

---

[MIT License](LICENSE)
