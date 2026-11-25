# Mood Watch

StressWatch 的净室复刻练习：一个 SwiftUI 写的 iOS 压力 / 心情记录 App。
界面结构参考原 App，代码、配色、图标与素材全部新写，不含原 App 的任何二进制、图片、字体或 Lottie 资源。

- Bundle ID：`com.moodwatch.app`（可改，见下）
- 显示名：`Mood Watch`
- 最低系统：iOS 16.0，iPhone / iPad
- 依赖：无（纯 SwiftUI + Foundation）

---

## 30 秒拿到 IPA（不需要 Mac）

你有 GitHub 账号，用免费的 macOS runner 编译即可：

1. 在 GitHub 网页上新建一个仓库（可以是私有仓库）。
2. 打开仓库 → `Add file` → `Upload files`，把**本文件夹里的全部内容**拖进去（注意要包含隐藏目录 `.github/workflows/build-ipa.yml`；用 GitHub Desktop 或 `git` 推送也行）。
   网页上传有时会忽略以 `.` 开头的目录，若 `Actions` 里看不到 workflow，改用「上传 zip 后解压」或用 git 推送。
3. 进入仓库的 `Actions` 标签页 → 左侧 `Build unsigned IPA` → 右侧 `Run workflow` → 再点绿色的 `Run workflow`。
4. 等 2–4 分钟，进这次运行的页面，底部 `Artifacts` → 下载 **`MoodWatch-unsigned-ipa`**，解压得到 `MoodWatch.ipa`。

> 这个 IPA 是**未签名**的。你说过自己签名，直接用你的签名工具（Sideloadly / eSign / AltStore / 自建证书）签完装到 iPhone 即可。签名时如果提示 Bundle ID 冲突，把 ID 改成你自己的（见下方「改 Bundle ID」）。

### 想顺便改 Bundle ID / 版本

`Run workflow` 时有输入框 `bundle_id` 与 `marketing_version`，填了就用填的值，不填用默认。

---

## 本地构建（有 Mac 时）

```bash
./scripts/build-ipa.sh                  # 未签名，产出 build/MoodWatch.ipa
TEAM_ID=ABCDE12345 ./scripts/build-ipa.sh --signed   # 用你的开发者团队签名
```

也可以在 Xcode 里直接打开 `MoodWatch.xcodeproj`，选好自己的 Team 后 Run / Archive。

---

## 目录结构

```
moodwatch/
├─ .github/workflows/build-ipa.yml   # 云端 macOS 编译 + 打包未签名 IPA
├─ MoodWatch.xcodeproj/              # 工程文件（含共享 scheme，CI 依赖它）
├─ MoodWatch/
│  ├─ MoodWatchApp.swift
│  ├─ Assets.xcassets/               # AppIcon（原创绘制，1024 单尺寸）＋ AccentColor
│  ├─ Models/                        # StressLevel / MoodState / Habit
│  ├─ Support/                       # Theme 设计 token、组件、AppStore、演示数据、健康数据接缝
│  └─ Features/
│     ├─ RootView.swift              # TabView + 页面骨架
│     ├─ Today/    # 压力仪表盘、今日 HRV、心情、关键行动
│     ├─ Trend/    # 14/60 天柱状趋势、等级分布、HRV/RHR 指标
│     ├─ Actions/  # 心情时间线、习惯打卡、记录弹层
│     ├─ Health/   # 身体年龄、影响因素、睡眠
│     ├─ Settings/ # 状态改名、目标、通知、隐私、关于
│     └─ Onboarding/
├─ docs/
│  ├─ DESIGN.md                      # 设计规范（配色/字阶/信息架构/状态模型）
│  └─ BUILD.md                       # 构建、签名、CI 排错、HealthKit 接入
├─ scripts/
│  ├─ build-ipa.sh                   # 本机 macOS 构建
│  ├─ gen_project.py                 # 从源码目录重新生成 xcodeproj
│  └─ validate.py                    # 工程结构与源码括号自检
└─ web/index.html                    # 浏览器预览版（验收界面用，不是交付 App）
```

---

## 实现了什么

| 模块 | 内容 |
|---|---|
| 压力模型 | 四级状态（压力过载 / 注意压力 / 状态正常 / 状态优秀）＋ 无数据态；用近 30 天 HRV 均值与标准差算 z 分数，映射成 0–100 压力指数 |
| 今日 | 270° 环形仪表盘（动画、等级配色、HRV 绝对值、最近测量时间）、今日 HRV 平滑曲线、心情五点快记、关键行动进度、昨日入口 |
| 趋势 | 14/60 天切换、按等级着色的柱状图＋均值虚线、等级分布、平均 HRV 与静息心率迷你趋势 |
| 行动 | 心情时间线（状态 + 标签 + 备注，可删除）、2×2 习惯打卡、习惯与压力洞察入口 |
| 健康 | 身体年龄主卡（实际年龄对比、衰老速度）、6 项影响因素、睡眠时长与阶段条 |
| 设置 | 四档状态自定义改名（实时同步到仪表盘）、每日目标、通知开关、复制 JSON、重置/清空数据、重看引导 |
| 其它 | 4 页新手引导、深色模式自适应、本地 JSON 持久化、无网络权限 |

## 没有做（明确的边界）

- **Watch App 与表盘**：原 App 有 `watchExtension`、`*.watchface` 等；本项目只做 iPhone 端。
- **真实健康数据**：默认注入确定性演示数据（界面会如实标注「数据更新于 …」）。健康数据接缝在 `Support/HealthDataProvider.swift`，打开方式见 `docs/BUILD.md`。
- **AI 洞察、订阅、分享卡片、经期追踪、喝水/咖啡因完整流程**：原 App 体量很大（1600+ 条文案、133 MB 资源），本项目聚焦「压力 + 心情」主线，其余留作后续。
- **原 App 的任何素材**：一张图、一个字体、一段 Lottie 都没有复制。

---

## 改 Bundle ID

```bash
# 云端：Run workflow 时填 bundle_id
# 本地：
BUNDLE_ID=com.yourname.moodwatch ./scripts/build-ipa.sh
```

或直接改 `MoodWatch.xcodeproj` 的 Build Settings → `PRODUCT_BUNDLE_IDENTIFIER`，再跑 `python3 scripts/gen_project.py` 会把默认值同步回生成脚本。

## 自检

```bash
python3 scripts/validate.py   # 检查 pbxproj 引用完整性、括号平衡、资源是否齐全
```

---

## 复刻边界与合规

- 仅用于研究与你拥有合法授权的软件；原 App 的商标、美术资源、代码版权归其作者所有。
- 本项目是「看懂结构后重写一遍」的净室产物：文案取自产品语义并重新组织，视觉与图标为原创。
- Mood Watch 不是医疗设备，输出内容不构成医学建议。
