# 构建、签名与排错

## 1. 为什么需要 macOS

`ipa` = 编译产物 `MoodWatch.app` + `Payload/` 目录的 zip。把 Swift 源码变成 iOS 可执行文件必须用 Apple 的 SDK 与 `xcodebuild`，这套工具链只在 macOS 上运行。Windows 侧无法替代，所以本项目把编译放到 GitHub Actions 的 `macos-14` runner 上执行。

## 2. 云端构建流程（拆解）

`.github/workflows/build-ipa.yml` 做四件事：

```bash
# 1) 归档（不做代码签名）
xcodebuild archive \
  -project MoodWatch.xcodeproj -scheme MoodWatch -configuration Release \
  -destination 'generic/platform=iOS' -archivePath build/MoodWatch.xcarchive \
  CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=NO

# 2) 取 .app
#    build/MoodWatch.xcarchive/Products/Applications/MoodWatch.app

# 3) 打成 ipa 结构
mkdir -p build/Payload && cp -R .../MoodWatch.app build/Payload/
cd build && zip -qry MoodWatch.ipa Payload

# 4) 上传 artifact
```

关键点：

- `CODE_SIGNING_ALLOWED=NO` 才能在没有证书的 CI 上编译通过；
- 必须提交**共享 scheme**（`MoodWatch.xcodeproj/xcshareddata/xcschemes/MoodWatch.xcscheme`），否则 `-scheme MoodWatch` 在 CI 上会报 "scheme not found"；
- 归档产物是 arm64 真机二进制，不能装模拟器，也不能在 Windows 上运行；
- 输出的 IPA 未签名，装不上手机，必须先签名。

## 3. 签名

| 方式 | 说明 |
|---|---|
| Sideloadly / eSign / AltStore | 直接导入未签名 IPA，选自己的证书与描述文件，改 Bundle ID 后安装 |
| 自己的开发者证书 | `security cms` 重签，或 `codesign -f -s "Apple Development: ..." --entitlements Ent.plist` 后重新打 zip |
| Xcode（有 Mac） | 打开工程，Signing & Capabilities 选 Team，`./scripts/build-ipa.sh --signed` |

签名时注意：

- 免费 Apple ID 的证书 7 天过期，需要重签；开发者账号 1 年。
- 如果签名工具抱怨 Bundle ID 已被占用，把 `com.moodwatch.app` 改成 `com.你的名字.moodwatch`。
- 本项目**没有**开启任何 Capability（无 HealthKit、无 App Group、无推送），所以普通描述文件即可签名，不会因为权限不匹配失败。

## 4. 开启真实健康数据（可选）

1. Xcode → 目标 `MoodWatch` → `Signing & Capabilities` → `+ Capability` → **HealthKit**。
2. 在 `Support/HealthDataProvider.swift` 里新增 `HealthKitHealthDataProvider`：
   - 读取 `HKQuantityTypeIdentifier.heartRateVariabilitySDNN`（RMSSD 与 SDNN 不同，原 App 用 RMSSD 并自行换算）；
   - 读取 `HKQuantityTypeIdentifier.restingHeartRate`；
   - 用 `HKStatisticsCollectionQuery` 按天聚合，映射成 `[DailyStress]`；
3. 在 `MoodWatchApp.swift` 里把 `AppStore()` 改成 `AppStore(health: HealthKitHealthDataProvider())`。
4. 注意：加了 HealthKit capability 后，签名必须使用包含 HealthKit 的 App ID 与描述文件，否则安装会失败。

`Info.plist` 的 `NSHealthShareUsageDescription` / `NSHealthUpdateUsageDescription` 已在生成设置里预置（`INFOPLIST_KEY_*`）。

## 5. 工程文件是怎么来的

`project.pbxproj` 容易手写出错，所以它是**脚本生成**的：

```bash
python3 scripts/gen_project.py   # 扫描 MoodWatch/ 下所有 .swift，重建 pbxproj 与 scheme
python3 scripts/validate.py      # 校验：id 引用完整、括号平衡、资源齐全、源码文件都被引用
```

增删 Swift 文件后跑一次这两条命令即可，不用手动改工程文件。

## 6. 常见失败

| 现象 | 原因 / 处理 |
|---|---|
| `xcodebuild: error: The project does not contain a scheme named "MoodWatch"` | scheme 没进仓库（隐藏目录被网页上传忽略），用 git 推送 |
| `Actions` 页面没有 workflow | 同上，`.github/workflows/` 没上传成功 |
| `No signing certificate "iOS Development" found` | 构建参数没带 `CODE_SIGNING_ALLOWED=NO` |
| `error: invalid value ... UISupportedInterfaceOrientations` | 生成设置被改坏，重跑 `gen_project.py` |
| 安装到手机提示「无法安装」 | IPA 未签名或证书/描述文件与 Bundle ID 不匹配 |
| 图标显示为白块 | `Assets.xcassets/AppIcon.appiconset/AppIcon.png` 缺失或尺寸不是 1024×1024 |
| 打开就崩在 `AppStore.init` | 极少数情况下沙盒目录不可写，已回退到临时目录；如仍崩溃请附 Xcode 日志 |
