# 鸟种设计 / Bird design

鸟种参数位于 `platforms/macos/Sources/BirdingCore/Resources/species.json`，通过 `scripts/export-shared.sh` 导出给 Windows。英文名称也由此提供，新增鸟种时同步 README 中唯一的中英文列表。

Species parameters and English names live in `platforms/macos/Sources/BirdingCore/Resources/species.json`. Export shared Windows assets with `scripts/export-shared.sh`, and update the single bilingual species table in README.

## 外形与体型 / Appearance and size

成年鸟代表体长采用幂函数缩放：`scale = (length / 19) ^ (log(2.5) / log(94 / 19))`，红耳鹎为 1×，苍鹭为 2.5×，所有鸟保持体长排序；这是适合桌面观赏的比例压缩，不是精确测量图。姿势、尾长和收颈会改变屏幕上的轮廓。白鹭对应 Little Egret；乌鸦采用大嘴乌鸦。红尾水鸲、绿头鸭、白眉姬鹟、红胁蓝尾鸲等采用成年雄鸟配色；池鹭使用繁殖羽，红嘴鸥使用非繁殖羽。出现概率是可调的游戏频率，不代表全国野外数量排名。

Adult lengths use the power curve `scale = (length / 19) ^ (log(2.5) / log(94 / 19))`: a 19 cm bulbul stays at 1× and a 94 cm Grey Heron becomes 2.5×, preserving size order. This is pixel-art approximation, not a measurement plate: posture, tails and folded necks affect the visible outline. “Egret” means Little Egret and “crow” means Large-billed Crow. Several sexually dimorphic species use adult male plumage; the pond heron uses breeding plumage and the gull non-breeding plumage. Configurable arrival probabilities are game frequencies, not nationwide abundance estimates.

鸟类素材由 `PixelArt.swift`、`SpeciesArt.swift` 和 `DetailedBirdArt.swift` 绘制；由原创轮廓与分羽细节直接栅格化为像素素材，大鸟使用更高分辨率，常规大小下保持约一个屏幕点的像素密度。两个平台共用导出的图集。动作时间线分别在 Swift/C# 的 `SpeciesBehavior`，修改时应保持一致。图集帧名来自 manifest；每种鸟的原生帧尺寸记录在 `frameSizes`，逻辑画布保持 48 点。

Art uses original anatomical paths and feather details, rasterized directly at species-specific resolutions to retain approximately one pixel per screen point at normal size, in `PixelArt.swift`, `SpeciesArt.swift` and `DetailedBirdArt.swift`. Both platforms use the same exported atlas. Keep the Swift and C# `SpeciesBehavior` timelines consistent. Frame names come from the manifest rather than a fixed atlas width.

## 行为 / Behavior

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
