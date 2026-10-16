# 鸟种设计 / Bird design

鸟种参数位于 `platforms/macos/Sources/BirdingCore/Resources/species.json`，通过 `scripts/export-shared.sh` 导出给 Windows。英文名称也由此提供，新增鸟种时同步 README 中唯一的中英文列表。

Species parameters and English names live in `platforms/macos/Sources/BirdingCore/Resources/species.json`. Export shared Windows assets with `scripts/export-shared.sh`, and update the single bilingual species table in README.

## 外形与体型 / Appearance and size

成年鸟代表体长采用幂函数缩放：`scale = (length / 19) ^ (log(2.5) / log(94 / 19))`，红耳鹎为 1×，苍鹭为 2.5×，所有鸟保持体长排序；这是适合桌面观赏的比例压缩，不是精确测量图。姿势、尾长和收颈会改变屏幕上的轮廓。白鹭对应 Little Egret；乌鸦采用大嘴乌鸦。红尾水鸲、绿头鸭、白眉姬鹟、红胁蓝尾鸲等采用成年雄鸟配色；池鹭使用繁殖羽，红嘴鸥使用非繁殖羽。出现概率是可调的游戏频率，不代表全国野外数量排名。

Adult lengths use the power curve `scale = (length / 19) ^ (log(2.5) / log(94 / 19))`: a 19 cm bulbul stays at 1× and a 94 cm Grey Heron becomes 2.5×, preserving size order. This is pixel-art approximation, not a measurement plate: posture, tails and folded necks affect the visible outline. “Egret” means Little Egret and “crow” means Large-billed Crow. Several sexually dimorphic species use adult male plumage; the pond heron uses breeding plumage and the gull non-breeding plumage. Configurable arrival probabilities are game frequencies, not nationwide abundance estimates.

鸟类素材由 `PixelArt.swift`、`SpeciesArt.swift` 和 `DetailedBirdArt.swift` 绘制；由原创轮廓与分羽细节直接栅格化为像素素材，大鸟使用更高分辨率，常规大小下保持约一个屏幕点的像素密度。两个平台共用导出的图集。动作时间线分别在 Swift/C# 的 `SpeciesBehavior`，修改时应保持一致。图集帧名来自 manifest；每种鸟的原生帧尺寸记录在 `frameSizes`，逻辑画布保持 48 点。

Art uses original anatomical paths and feather details, rasterized directly at species-specific resolutions to retain approximately one pixel per screen point at normal size, in `PixelArt.swift`, `SpeciesArt.swift` and `DetailedBirdArt.swift`. Both platforms use the same exported atlas. Keep the Swift and C# `SpeciesBehavior` timelines consistent. Frame names come from the manifest rather than a fixed atlas width.

## 行为 / Behavior

- Chrome 支持地址栏已显示文字之后的空白段和书签栏空白处；获得输入焦点、地址过长或标签切换时撤销旧落点。飞书支持左侧头像栏及消息标题栏的空白处，并将 Electron 缩放坐标映射到真实窗口；跳过网页、聊天和列表正文，只读取顶部控件几何。/ Chrome supports blank spans after address text and in the bookmarks bar, withdrawing stale positions on address focus, insufficient space or tab replacement. Feishu supports blank avatar/sidebar and message-header spans, normalizing Electron zoom coordinates into the actual window. Page, conversation and list content are excluded; only header-control geometry is inspected.
- iTerm2 支持内部标题栏空白段、水平窗格标题栏上沿停栖；优先使用已有辅助功能权限读取原生栏位和控件坐标，跳过终端文本区域，仅测量标题标签以避让。无可用原生信息时，macOS 14+ 可使用已授权的单窗口画面后台识别作为备用；不做 OCR、不保存终端画面或内容、不改 iTerm2/tmux 配置。菜单可关闭该功能，仅用户点击启用时申请辅助功能权限。锁屏、权限或读取失败、窗口缩放、切换标签或横栏消失时撤销旧落点。聚焦允许内部栏位，但仍检查头部空间、遮挡和鸟间避让。/ Interior blank title-bar spans and horizontal pane-header edges are available in iTerm2. Existing Accessibility permission provides native bar/control geometry, skipping terminal text areas and measuring header labels only. On macOS 14+, authorized window-only capture is a fallback when native metadata is unavailable; detection runs off the animation thread. No OCR, terminal image/content storage or iTerm2/tmux configuration changes. The menu can disable the feature and requests Accessibility only on explicit activation. Locking, failed discovery/permissions, resize, tab replacement or bar removal invalidates cached rails. Focus permits interior rails; headroom, occlusion and bird spacing remain required.
- 焦点规则优先于底边停栖：聚焦窗口不提供底边落点，底部已停栖或落地中的鸟随机排序、错峰起飞；通常相隔 0.18–0.5 秒，少数多愣 0.7 秒。重复采样不重置倒计时，失焦则取消；已在飞向底边的鸟立即避让，窗口消失或快速移动也不等待。普通上沿不受影响。macOS 优先使用已有辅助功能权限读取焦点窗口，无权限时使用前台应用的窗口层级，不请求新权限；Windows 使用前台窗口句柄。/ Focus overrides bottom perches: a focused window offers no bottom destinations. Perched or landing birds react in random order, with takeoffs spaced 0.18–0.5 seconds apart and occasional extra 0.7-second hesitation. Repeated sampling preserves countdowns; blur cancels them. Incoming flights avoid the bottom immediately, as do birds whose host disappears or moves rapidly. Normal top perches remain eligible. macOS uses accessibility focus when already authorized, otherwise the foreground app's window order without prompting; Windows uses the foreground window handle.
- 全屏或铺满工作区的窗口在顶部无空间时提供底边停栖，仅最前方符合条件的窗口可用；脚直接落在可见底边，越界尾部由边缘遮挡，遵循 Dock/任务栏可用区域、弹窗遮挡及鸟间避让，恢复普通窗口后重新选路。/ A foreground window covering the work area offers bottom perches when there is no top headroom. The feet meet the visible bottom edge, with the hanging tail masked below it. Perches respect Dock/taskbar bounds, popups and bird spacing, and are replanned when the window is restored.
- 群体行为使用独立的模拟时钟：普通入场有 30% 机会邀请同种伙伴，间隔约 3 秒、最多等待 25 秒，不突破数量上限；约 60–120 秒自由活动后，优先同种一对相邻群栖 30–55 秒，不用异种补人数；没有同种伙伴时仅 5% 机会混群，群内成员再错开起飞、分散到较空的窗口 20–35 秒。鸟的眨眼、理羽及动画时钟仍然独立。/ Social behavior uses a simulation clock: an ordinary arrival has a 30% chance to invite one same-species companion after roughly 3 seconds, expiring after 25 seconds and respecting population limits. After 60–120 seconds of independent activity (60 seconds initially), conspecific pairs gather for 30–55 seconds without padding with other species; only when no conspecific pair exists is there a 5% chance of mixed gathering, then group members stagger their moves toward less occupied windows during a 20–35 second dispersal. Idle animations remain independent.
- 同种鸟在场上限为 2 只，包含仍可见的入场和离场个体；伙伴邀请不能突破上限。达到上限的鸟种临时退出抽样，其他已启用鸟种按原权重相对比例抽取，不修改概率或锁定设置；没有可入场鸟种时暂停补齐，不启用概率为 0 的鸟种。群栖最多两只。/ Each species is limited to two present sprites, including incoming and departing birds; companion invitations respect this limit. Capped species are temporarily excluded from sampling, preserving relative weights among other enabled species without changing saved probabilities or locks. Arrivals pause when none is eligible; zero-weight species remain disabled. Gatherings contain at most two birds.
- 自然离场优先选择独处且已访问至少 20 秒的鸟；新结伴鸟至少保留 45 秒访问时间，手动缩小数量上限时可提前离场。/ Natural departures prefer solo birds visiting for at least 20 seconds; new group members receive at least 45 seconds before natural departure. Reducing the population upper bound can override these minimums.
- 入场前先预留合法落点，没有位置时暂缓入场；飞行中失去所有落点则飞离，连续换路寻找最多 12 秒。后台窗口露出的上沿也可停栖：身体和脚必须可见，脚下尾部可被前台窗口自然遮挡，鸟与鸟之间仍预留完整空间。/ Arrivals reserve a valid perch before entering and wait offscreen when none is available. Birds leave if no perch remains; continuous flight searches are capped at 12 seconds across reroutes. Exposed background window edges are eligible when the body and feet are visible; foreground windows may mask the hanging tail, while full spacing between birds is retained.
- 默认停栖时间延长为原来的 3 倍，保留鸟种间的节奏差异；正常鸟群进出间隔为 30–60 秒，启动补齐及数量调整仍为 2.5–6 秒。升级时仅更新旧默认停栖范围，自定义范围保留。/ Default perch ranges are tripled while retaining species differences. Normal flock changes are spaced 30–60 seconds apart; startup filling and population corrections still use 2.5–6 seconds. Upgrades replace only former default perch ranges and preserve custom ranges.
- 夜鹭：长时间静止守望，间隔伸颈、抖毛及短暂排泄动画；不留下永久污渍。/ Night heron: prolonged watch, occasional neck stretch, feather shake and brief dropping animation; no permanent stains.
- 大斑啄木鸟：优先选择未遮挡的窗口左右边缘，面朝窗口，尾部支撑，间歇啄击。/ Woodpecker: prefers exposed vertical edges, faces the window and braces with its tail for intermittent pecking.
- 红尾水鸲、红胁蓝尾鸲、黑卷尾：短促摆尾；猛禽：较慢的巡视；丘鹬：轻微摇摆；小型林鸟：较活跃的头部动作。/ Redstarts, bluetail and drongo flick their tails; raptors scan slowly, woodcock rocks gently and small woodland birds move more actively.
- 悬停识别只读取鼠标位置，命中可见非透明像素后连续计时 1 秒；遮挡、离开或换鸟都会重置。/ Hover identification samples pointer position, requires 1 second on visible opaque bird pixels, and resets on exit, occlusion or a different bird.

## 参考资料 / References

- [香港观鸟会：香港鸟类志 / HKBWS Avifauna](https://avifauna.hkbws.org.hk/) — species identification and plumage references.
- [夜鹭 / Black-crowned Night Heron](https://avifauna.hkbws.org.hk/species/0170/022700) and [白鹭 / Little Egret](https://avifauna.hkbws.org.hk/species/0170/023500).
- [央视网 / 科普中国：鸟中顶流夜师傅](https://kepu.cctv.cn/2026/02/26/ARTI4qPfpplKbXnyEvvRLW3k260226.shtml) — quiet lookout posture, folded neck, adult field marks and Chinese community nicknames.
- [Bilibili：夜鹭洗手液](https://www.bilibili.com/video/BV19fNkz6Eux/) — community animation inspiration, not a biological frequency estimate.
- [中国科学院昆明动物研究所：红尾水鸲](https://datacenter.kiz.ac.cn/DataBase/BirdDetail/741) — male blue-gray body and chestnut tail, approximately 13 cm.
- [RSPB: Great Spotted Woodpecker](https://www.rspb.org.uk/birds-and-wildlife/great-spotted-woodpecker) and [Grey Heron](https://www.rspb.org.uk/birds-and-wildlife/grey-heron) — characteristic shapes and adult size reference.

素材不复制参考网站图片。动作周期是适合桌面观赏的设计值，并非野外行为频率。

Artwork does not copy source photographs. Animation timings are designed for desktop viewing rather than field-measured behavior frequencies.

- [Heron Conservation: Little Egret](https://heronconservation.org/herons-of-the-world/list/little-egret/) and [Grey Heron](https://heronconservation.org/herons-of-the-world/list/grey-heron/) — slender necks, leg proportions and flight plumage.
