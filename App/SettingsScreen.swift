import SwiftUI
import WidgetKit

/// 设置页面（对应 Android SettingsScreen；开机自启/钉上去为 Android 系统专属，iOS 无对应能力）
struct SettingsScreen: View {
    @EnvironmentObject var viewModel: WeatherViewModel

    // 透明度滑杆暂存：松手才持久化并刷新小组件
    @State private var clockOpacity: Double = 100
    @State private var weatherOpacity: Double = 100

    // 当前 GPS 定位展示（AQI/UVI 预警依据），nil 表示尚未取到有效定位
    @State private var currentLocationName: String? = nil

    var body: some View {
        let strings = viewModel.strings
        let settings = viewModel.settings

        Form {
            // ========== 外观设置 ==========
            Section(strings.settingsAppearance) {
                // 显示模式
                Picker(selection: Binding(
                    get: { settings.themeMode },
                    set: { value in updated { $0.themeMode = value } }
                )) {
                    ForEach(Array(ThemeMode.allCases.enumerated()), id: \.element) { index, mode in
                        Text(strings.themeModes.indices.contains(index) ? strings.themeModes[index] : mode.rawValue)
                            .tag(mode)
                    }
                } label: {
                    SettingLabel(icon: "moon.circle.fill", title: strings.displayMode)
                }

                // 主题颜色
                VStack(alignment: .leading, spacing: 10) {
                    SettingLabel(icon: "paintpalette.fill", title: strings.themeColor,
                                 subtitle: AppTheme.palette(settings.themeColorIndex).name)
                    HStack(spacing: 10) {
                        ForEach(Array(AppTheme.palettes.enumerated()), id: \.offset) { index, palette in
                            let isSelected = index == settings.themeColorIndex
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill(palette.surface)
                                .frame(width: 34, height: 34)
                                .overlay {
                                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                                        .strokeBorder(isSelected ? palette.primary : Color.secondary.opacity(0.25),
                                                      lineWidth: isSelected ? 2 : 1)
                                }
                                .overlay {
                                    if isSelected {
                                        Image(systemName: "checkmark")
                                            .font(.system(size: 13, weight: .bold))
                                            .foregroundStyle(palette.primary)
                                    }
                                }
                                .onTapGesture { updated { $0.themeColorIndex = index } }
                        }
                    }
                }
                .padding(.vertical, 4)
            }

            // ========== 组件设置 ==========
            Section(strings.settingsWidgets) {
                // 时钟组件底板透明度（松手才持久化并刷新组件）
                VStack(alignment: .leading, spacing: 6) {
                    SettingLabel(icon: "clock.fill", title: strings.clockWidgetOpacity,
                                 subtitle: "\(Int(clockOpacity))%")
                    Slider(value: $clockOpacity, in: 20...100, step: 1) { editing in
                        if !editing { updated { $0.clockWidgetOpacity = Int(clockOpacity) } }
                    }
                }
                .padding(.vertical, 4)

                // 气象组件底板透明度
                VStack(alignment: .leading, spacing: 6) {
                    SettingLabel(icon: "sun.max.fill", title: strings.weatherWidgetOpacity,
                                 subtitle: "\(Int(weatherOpacity))%")
                    Slider(value: $weatherOpacity, in: 20...100, step: 1) { editing in
                        if !editing { updated { $0.weatherWidgetOpacity = Int(weatherOpacity) } }
                    }
                }
                .padding(.vertical, 4)

                // 组件主题颜色：动态（随天气/时段）或 5 种固定配色
                VStack(alignment: .leading, spacing: 10) {
                    SettingLabel(icon: "paintpalette.fill", title: strings.widgetThemeColor,
                                 subtitle: strings.widgetThemeNames.indices.contains(settings.widgetThemeIndex)
                                    ? strings.widgetThemeNames[settings.widgetThemeIndex] : "")
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(Array(strings.widgetThemeNames.enumerated()), id: \.offset) { index, name in
                                FilterChip(label: name, selected: index == settings.widgetThemeIndex) {
                                    updated { $0.widgetThemeIndex = index }
                                }
                            }
                        }
                    }
                }
                .padding(.vertical, 4)
            }

            // ========== 单位设置 ==========
            Section(strings.settingsUnits) {
                // 温度单位
                HStack {
                    SettingLabel(icon: "thermometer.medium", title: strings.tempUnit,
                                 subtitle: strings.tempUnitNames.indices.contains(unitIndex(settings.temperatureUnit))
                                    ? strings.tempUnitNames[unitIndex(settings.temperatureUnit)] : "")
                    Spacer()
                    ForEach(TemperatureUnit.allCases) { unit in
                        FilterChip(label: unit.symbol, selected: unit == settings.temperatureUnit) {
                            updated { $0.temperatureUnit = unit }
                        }
                    }
                }

                // 风速单位
                HStack {
                    SettingLabel(icon: "wind", title: strings.windUnit,
                                 subtitle: strings.windUnitNames.indices.contains(windIndex(settings.windSpeedUnit))
                                    ? strings.windUnitNames[windIndex(settings.windSpeedUnit)] : "")
                    Spacer()
                    ForEach(WindSpeedUnit.allCases) { unit in
                        FilterChip(label: unit.symbol, selected: unit == settings.windSpeedUnit) {
                            updated { $0.windSpeedUnit = unit }
                        }
                    }
                }
            }

            // ========== 预警设置 ==========
            Section(strings.settingsAlerts) {
                Toggle(isOn: Binding(
                    get: { settings.alertEnabled },
                    set: { value in updated { $0.alertEnabled = value } }
                )) {
                    SettingLabel(icon: "exclamationmark.triangle.fill", title: strings.alertEnable,
                                 subtitle: settings.alertEnabled ? strings.alertOnDesc : strings.alertOffDesc)
                }

                if settings.alertEnabled {
                    // 当前定位：空气质量/紫外线预警直接按该定位坐标取数，展示供用户核对
                    SettingLabel(icon: "location.fill", title: strings.currentLocationLabel,
                                 subtitle: currentLocationName ?? strings.currentLocationUnknown)

                    HStack {
                        SettingLabel(icon: "line.3.horizontal.decrease.circle.fill",
                                     title: strings.alertMinSeverity)
                        Spacer()
                        ForEach(Array(AlertSeverity.allCases.enumerated()), id: \.element) { index, severity in
                            FilterChip(
                                label: strings.severityNames.indices.contains(index) ? strings.severityNames[index] : severity.rawValue,
                                selected: severity == settings.alertMinSeverity
                            ) {
                                updated { $0.alertMinSeverity = severity }
                            }
                        }
                    }
                }
            }

            // ========== 数据刷新 ==========
            Section(strings.settingsData) {
                HStack {
                    SettingLabel(icon: "arrow.clockwise.circle.fill", title: strings.refreshInterval,
                                 subtitle: "\(settings.refreshIntervalMinutes) \(strings.minutesUnit)")
                    Spacer()
                    ForEach([15, 30, 60], id: \.self) { minutes in
                        FilterChip(label: "\(minutes)\(strings.minutesUnit)",
                                   selected: minutes == settings.refreshIntervalMinutes) {
                            updated { $0.refreshIntervalMinutes = minutes }
                        }
                    }
                }
            }

            // ========== 系统 ==========
            Section(strings.settingsSystem) {
                // 语言选择（选定即生效，同步刷新界面与小组件）
                Picker(selection: Binding(
                    get: { settings.language },
                    set: { value in updated { $0.language = value } }
                )) {
                    ForEach(AppLanguage.allCases) { lang in
                        Text(lang.displayName).tag(lang)
                    }
                } label: {
                    SettingLabel(icon: "globe", title: strings.languageLabel)
                }
            }

            // ========== 关于 ==========
            Section(strings.settingsAbout) {
                SettingLabel(icon: "info.circle.fill", title: strings.version, subtitle: appVersion)
                SettingLabel(icon: "chevron.left.forwardslash.chevron.right",
                             title: strings.dataSource, subtitle: "open-meteo.com")
            }
        }
        .navigationTitle(strings.settings)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            clockOpacity = Double(settings.clockWidgetOpacity)
            weatherOpacity = Double(settings.weatherWidgetOpacity)
        }
        .task {
            // 进入设置页先回显缓存定位，再尝试刷新一次，避免空白等待
            if let cached = AppStore.shared.getCurrentLocation(), cached.isValid {
                currentLocationName = displayName(cached, strings)
            }
            if let point = await LocationService.shared.refreshCurrentLocation() {
                currentLocationName = displayName(point, strings)
            }
        }
    }

    /// 安装包真实版本号（读 Info.plist，避免手写字符串与构建配置脱节）
    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
        return version.isEmpty ? "-" : "v\(version)"
    }

    /// 定位地名：逆查失败时回退为“当前位置”
    private func displayName(_ point: CurrentLocationPoint, _ strings: Strings) -> String {
        point.name.isEmpty ? strings.currentLocationFallbackName : point.name
    }

    /// 修改设置并持久化（内部会同步刷新小组件时间线）
    private func updated(_ mutate: (inout AppSettings) -> Void) {
        var newSettings = viewModel.settings
        mutate(&newSettings)
        viewModel.updateSettings(newSettings)
    }

    private func unitIndex(_ unit: TemperatureUnit) -> Int {
        TemperatureUnit.allCases.firstIndex(of: unit) ?? 0
    }

    private func windIndex(_ unit: WindSpeedUnit) -> Int {
        WindSpeedUnit.allCases.firstIndex(of: unit) ?? 0
    }
}

/// 设置项标签（图标 + 标题 + 副标题）
private struct SettingLabel: View {
    let icon: String
    let title: String
    var subtitle: String?

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundStyle(.tint)
                .opacity(0.75)
                .frame(width: 26)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.body)
                if let subtitle, !subtitle.isEmpty {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}

/// 单选筛选 Chip（对应 Android FilterChip）
private struct FilterChip: View {
    let label: String
    let selected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            Text(label)
                .font(.footnote)
                .fontWeight(selected ? .semibold : .regular)
                .foregroundStyle(selected ? Color.white : .primary)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(selected ? Color.accentColor : Color.secondary.opacity(0.12), in: Capsule())
        }
        .buttonStyle(.plain)
    }
}
