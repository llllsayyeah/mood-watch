# Investigation report

_No brief was recorded for this investigation._

## What we looked at

- Stress.app (directory)
- StressWatch 2.ipa (zip)

## What we found

### Stress.app 是一个 1953 文件的 iOS App bundle：209 个二进制、906 个二进制 plist、27 个 Mach-O（含 1 个 fat）、169 个 PNG、488 个 JSON（Lottie 动画）、41 个嵌套 zip（40 个 .watchface 表盘包），并带 3 个 App Extension（PhoneWidgetExtension / WaterNotificationExtension / widgetExtension）。

- **Confidence:** Seen it (observed)
- **Evidence:**
  - `ev_005d4f183d6a5b97b9c5fd80114e65a8907338718e24aff1f2c9e0b6c127954f` — Stress.app (directory) holds 1953 files in 2074 entries; 40 nested container(s). (path=C:\Users\96454\Documents\deepseek-harness\default-workspace\stresswatch-ipa\Payload\Stress.app)

### 桌面上的 StressWatch 2.ipa 是一个 354 MB 的 ZIP（ipa 容器），sha256 a508afb6…；其 Payload 根目录为 Stress.app，因此复刻分析应在解包后的 app bundle 上进行，而不是直接对 .ipa 做字符串检索。

- **Confidence:** Seen it (observed)
- **Evidence:**
  - `ev_5e3c7b26a1ffebce5f7262fc67cb1e947abf05e6307909607f132be9ba7929a1` — StressWatch 2.ipa is a ZIP archive.

## Open questions

_None outstanding._

## How this was done

- **Mode:** Deep (the original's code and files could be read)
- **Engines:** builtin
- **Limitations:**
  - Disk images (DMG), installers (PKG/MSI) and compressed tarballs are listed as single files, not opened.
  - the kind is detected from the first bytes and, to break ties, the file name

## Evidence ledger

- `ev_5e3c7b26a1ffebce5f7262fc67cb1e947abf05e6307909607f132be9ba7929a1` **core_target_triage** — StressWatch 2.ipa is a ZIP archive. (Best guess)
- `ev_005d4f183d6a5b97b9c5fd80114e65a8907338718e24aff1f2c9e0b6c127954f` **core_archive_show** — Stress.app (directory) holds 1953 files in 2074 entries; 40 nested container(s). (Seen it)

---

# 附：净室复刻依据（人工读取资源，非 craft 引擎产出）

上文的证据账本只覆盖「这个包是什么」。以下是复刻设计真正依赖的结构还原，全部来自解包后的 `Payload/Stress.app`，读取方式为 plist / strings / JSON 直读，**没有反编译、没有复制任何资源**。

## 1. 应用元信息

| 项 | 值 |
|---|---|
| 显示名 / 可执行名 | StressWatch / `Stress` |
| Bundle ID | `com.ideation.Stress` |
| 版本 | 3.4.8 (build 111) |
| 最低系统 | iOS 16.0 |
| URL Scheme | `stresswatch`、小红书 `xhs9b3f…` |
| 二进制标记 | Info.plist 含 `IPAPatch Tool` 键（该包是打过补丁的副本，非 App Store 原始包） |
| 技术栈 | SwiftUI/UIKit 混合 + The Composable Architecture（`ComposableArchitecture.bundle`）+ Swift Sharing + Alamofire + DGCharts + Lottie |
| 第三方 SDK | Adjust / AdjustSig / AppsFlyer / 阿里云 OSS / Facebook SDK |
| 扩展 | `widgetExtension`、`PhoneWidgetExtension`、`WaterNotificationExtension` |

## 2. 信息架构（5 个 Tab）

从 `zh-Hans.lproj/Localizable.strings` 的 `tab.*` 键还原：

| Tab | 键 | 承载内容 |
|---|---|---|
| 今日 | `tab.today` | 综合压力状态、实时 HRV、昨日回顾、关键行动、付费墙卡 |
| 趋势 | `tab.trend` | 14/60 天压力与 HRV 趋势、等级分布 |
| 行动 | `tab.actions` | 心情记录（行动-感受）、习惯打卡、行动与压力趋势对比 |
| 健康 | `tab.health` | 身体年龄、睡眠、身体测量（体重/体脂/去脂体重）、经期 |
| 设置 | `tab.settings` | 等级名称自定义、通知、目标、隐私、关于 |

按模块拆分的文案文件共 60+ 个（`onboarding` / `insight` / `physio` / `sleep` / `water` / `menstruation` / `paywall` / `StressShare` …），说明每个 Tab 背后都是独立特性域；本项目只还原了主线的 5 Tab。

## 3. 四级压力状态模型

`Localizable.strings` 中 `level1..level4`、`levelNa`、`levelOver` 键给出完整语义（原文摘录，用于理解，不复制到产品文案）：

| 等级 | 原名 | 原语义 | 本项目取值 |
|---|---|---|---|
| 1 | 压力过载 | HRV 低于日常水平，身体疲惫/压力大 | 同名，重写解读 |
| 2 | 注意压力 | HRV 略低于日常水平 | 同名 |
| 3 | 状态正常 | HRV 处于日常水平，压力可控 | 同名 |
| 4 | 状态优秀 | HRV 高于日常水平，身心放松 | 同名 |
| na | 暂无今日数据 | 佩戴不足/无 HRV | 同名 |
| over | 无定义 | HRV > 180 ms 不纳入均值 | 同名 |

配套证据：`level.N*.description` 明确 30 天基线不足时解读会偏差；`levels.status.explain.answer1/2` 说明综合状态同时用 30 天 HRV 与静息心率。→ 本项目 `StressMath.index()` 采用「30 天 HRV 基线 + z 分数映射 0–100」即由此而来。

## 4. 心情与标签体系

- `SOMStates.json`：35 个状态，5 档效价（veryPositive / positive / neutral / negative / veryNegative），分 `emotional`（21 个）与 `physical`（14 个）两类。
- `SOMTags.json`：22 个影响因素标签（工作、运动、咖啡因、睡眠、金钱、家庭……），带 `association` 字段与性别过滤。
- 本项目在 `Models/MoodState.swift` 中重建了同一套状态与标签（换成自己的 emoji 映射），并作为「行动 - 感受」记录的数据字典。

## 5. 习惯清单

`insight.menu.*` 键列出原 App 认定的习惯维度：睡够 7 小时 / 睡眠质量 80+ / 20 分钟运动 / 晨间晒太阳 20 分钟 / 喝够 2000 ml / 咖啡因 < 100 mg / 冥想 / 高噪音 / 10000 步 等，用于「行动 v.s. 压力趋势」对比。→ 本项目今天页与行动页的 4–5 个习惯由此收敛而来。

## 6. 视觉线索

- AppIcon：薄荷绿环形 + 内部表情/图形，米白底，圆润极简。
- `Sora-*.ttf`（8 个字重）为原 App 正文字体；本项目**未打包**该字体，改用系统 SF Rounded。
- `Assets.car` 133 MB、`*.watchface` 40 个表盘、Lottie 488 个动画：均未复制，本项目用 SwiftUI `Path` / `Circle().trim` 重画图表。

## 7. 复刻映射

| 原 App | Mood Watch | 说明 |
|---|---|---|
| `tab.today` 今日仪表盘 | `Features/Today/TodayView.swift` | 270° 环 + 压力指数 + 等级色 + 解读展开 |
| `hrvTrend.*` 今日 HRV 趋势 | `HRVTrendCard` | 平滑曲线 + 0–180 ms 轴 |
| `journal.*` 心情记录 | `MoodLogSheet` | 效价 5 档 + 状态网格 + 标签 + 备注 |
| `insight.menu.*` 习惯 | `Habit` + `HabitGridCard` | 打卡与进度 |
| `physio.*` 身体年龄 | `HealthView` BioAgeCard | 实际年龄对比 + 衰老速度 |
| `sleep.*` 睡眠 | `SleepCard` | 时长 + 质量 + 阶段条 |
| `level.N*.name` 可改名 | 设置内自定义四档名称 | 改名即时同步仪表盘 |
| watchOS 表盘 / Widget / AI 洞察 / 订阅 | 未实现 | 见 README「没有做」 |

## 8. 方法与合规

- 只读取文件内容与文案语义；不反编译 `Stress` 主二进制（27 个 Mach-O 未做反汇编）。
- 不复制任何图片、字体、音频、Lottie、storyboard/nib。
- 原 App 商标与美术资产版权归其作者；本项目为结构研究与自有实现。


