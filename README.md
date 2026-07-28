# 识天 SkySense — iOS (arm64) 版

由 Android 版（v260728.2.5.20）完整移植的 iPhone 原生应用，SwiftUI + WidgetKit 实现，功能一一对应且 UI 按 iOS 平台规范精细化重制（SF Symbols 多彩图标、毛玻璃卡片、连续圆角、rounded 数字字体、原生拖拽排序等）。

## 工程结构

```
apple_arm/
├── project.yml                 # XcodeGen 工程描述（两个 target，均 arm64）
├── App/                        # 主应用 target: SkySense
│   ├── SkySenseApp.swift       # 入口 + 后台刷新/预警 BGTaskScheduler 注册
│   ├── WeatherViewModel.swift  # 状态管理（城市/设置/天气/搜索）
│   ├── HomeScreen.swift        # 主页：动态天气背景 + 表盘时钟 + 城市胶囊(可拖拽排序)
│   ├── WeatherCards.swift      # 当前天气卡 / AQI 空气质量条 / 7日预报(可展开详情)
│   ├── Components.swift        # 动态天气背景(云雨雪沙雷暴粒子) + 指针时钟
│   ├── CitySearchScreen.swift  # 城市搜索(300ms防抖) + 已添加城市管理(排序/删除)
│   ├── SettingsScreen.swift    # 外观/组件/单位/预警/数据/语言/关于
│   ├── AlertService.swift      # 气象预警检测 + 本地通知(等级过滤/去重)
│   └── Theme.swift             # 8 套主题色板 + 深浅色模式
├── Shared/                     # 主应用与小组件共享（App Group 数据互通）
│   ├── Models.swift            # 全部数据模型（与 Android 字段一致）
│   ├── WeatherAPI.swift        # Open-Meteo 天气/空气质量/地理编码 API
│   ├── WeatherRepository.swift # 数据仓库（拉取+缓存）
│   ├── AppStore.swift          # UserDefaults(App Group) 持久化
│   ├── I18n.swift              # 六语言文案（中/英/日/韩/法/德）
│   └── Formatting.swift        # 单位换算/时间格式/天气 SF Symbol 映射/小组件主题
└── Widgets/                    # 小组件 target: SkySenseWidget
    ├── WidgetCore.swift        # WidgetBundle 入口 + AppIntent 选城
    ├── ClockWidget.swift       # 时钟小组件（质感表盘，small/medium）
    └── WeatherWidget.swift     # 气象小组件（三档信息层级，small/medium/large）
```

## 在 macOS 上构建（iOS 无法在 Windows 编译）

1. 安装 Xcode 15+ 与 XcodeGen：
   ```bash
   brew install xcodegen
   ```
2. 在本目录生成工程并打开：
   ```bash
   cd apple_arm
   xcodegen generate
   open SkySense.xcodeproj
   ```
3. 在 Xcode 中为 `SkySense` 与 `SkySenseWidget` 两个 target 设置你的开发者签名（Team），
   并确认 App Group `group.com.xiaotian.skysense` 已在开发者账号中启用。
4. 选择真机（iPhone，arm64）运行；小组件在桌面长按 → 添加小组件 → 识天。

- 版本号：260728.2.5.20（对应 Android v260728.2.5.20）
- 最低系统：iOS 17.0；架构：arm64
- Bundle ID：`com.xiaotian.skysense` / `com.xiaotian.skysense.widgets`

## 功能对照表（Android → iOS，零遗漏）

| Android 功能 | iOS 实现 |
|---|---|
| 主页动态天气背景（云/雨/雪/沙/雷暴粒子，昼夜配色） | Components.swift · TimelineView+Canvas 逐帧粒子，色值一致 |
| 指针时钟 + 数字时间 + 本地化日期 | Components.swift · AnalogClockView |
| 城市胶囊选择 + 长按拖动排序 | HomeScreen.swift · onDrag/onDrop 实时换位 |
| 背景明暗自适配前景色 | WeatherBackdrop.isDark 同逻辑 |
| 当前天气卡（温度/体感/风/湿度/气压/能见度） | WeatherCards.swift · WeatherCardView |
| AQI 空气质量条（等级色/PM2.5/PM10） | WeatherCards.swift · AqiBarView |
| 7 日预报（温度条 + 点击展开当日详情） | WeatherCards.swift · ForecastCardView |
| 下拉刷新 | .refreshable |
| 城市搜索（Open-Meteo 地理编码，防抖） | CitySearchScreen.swift（300ms 防抖） |
| 城市管理（排序/删除，跨语言城市名） | List onMove/onDelete + CityInfo.nameFor |
| 设置：深浅色/8 色主题 | SettingsScreen + Theme.swift |
| 设置：小组件透明度（时钟/气象各 20~100%）与主题（动态+5 固定） | SettingsScreen 两条 Slider + 主题 Chip |
| 设置：温度/风速单位 | °C/°F、km/h/m/s/mph 全量换算 |
| 设置：预警开关 + 最低等级 | SettingsScreen + AlertService |
| 设置：刷新间隔 15/30/60 分钟 | 同步驱动 BGTask 与小组件时间线 |
| 设置：六语言即时切换 | I18n.swift 全量文案 |
| 气象预警通知（等级过滤/去重） | AlertService + UNUserNotification |
| 后台定时刷新（WorkManager） | BGTaskScheduler（refresh + alert 两个任务） |
| 时钟小组件（质感表盘） | ClockWidget.swift（分钟级时间线，数字时间系统实时驱动） |
| 气象小组件三档尺寸（精简/网格/含 5 日预报） | systemSmall/Medium/Large 三档映射 |
| 小组件每实例独立选城（配置 Activity） | AppIntent：长按小组件 → 编辑 → 选择城市 |
| 小组件主题 + 透明度 | WidgetTheme.resolve + 渐变透明叠加 |
| 点击小组件打开主应用 | widgetURL(skysense://open) |
| 数据缓存离线展示 | AppStore 缓存，拉取失败回退 |

**平台差异说明**：Android 的「开机自启（BootReceiver）」与「钉在桌面（PinnedService 悬浮窗）」为 Android 系统专属能力，iOS 平台不存在对应机制（iOS 小组件常驻桌面本身即等效体验），其余功能全部移植。
