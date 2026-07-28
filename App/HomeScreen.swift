import SwiftUI
import UniformTypeIdentifiers

/// 主页 - 识天：动态天气背景 + 时钟 + 天气（对应 Android HomeScreen）
struct HomeScreen: View {
    @EnvironmentObject var viewModel: WeatherViewModel
    @Environment(\.colorScheme) private var colorScheme

    @State private var showSettings = false
    @State private var showCitySearch = false

    var body: some View {
        let strings = viewModel.strings
        let language = viewModel.settings.language
        let weatherCode = viewModel.selectedWeather?.current?.weatherCode
        // 背景明暗决定上半部前景配色（保证对比度）
        let darkBackdrop = WeatherBackdrop.isDark(weatherCode)
        let onBackdrop: Color = darkBackdrop ? .white : Color(hex: 0xFF243447)

        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    // ===== 上半部：动态天气背景覆盖（标题区 + 城市栏 + 时钟区） =====
                    ZStack {
                        DynamicWeatherBackgroundView(weatherCode: weatherCode)

                        VStack(spacing: 8) {
                            // 标题栏：logo + 识天 + 操作按钮
                            HStack {
                                Image(systemName: "cloud.sun.fill")
                                    .symbolRenderingMode(.multicolor)
                                    .font(.system(size: 26))
                                Text(strings.appName)
                                    .font(.title3)
                                    .fontWeight(.bold)
                                    .foregroundStyle(onBackdrop)
                                Spacer()
                                Button {
                                    Task { await viewModel.refreshAll() }
                                } label: {
                                    Image(systemName: "arrow.clockwise")
                                        .foregroundStyle(onBackdrop)
                                }
                                .accessibilityLabel(strings.refresh)
                                Button {
                                    showSettings = true
                                } label: {
                                    Image(systemName: "gearshape.fill")
                                        .foregroundStyle(onBackdrop)
                                        .padding(.leading, 12)
                                }
                                .accessibilityLabel(strings.settings)
                            }
                            .padding(.horizontal, 16)
                            .padding(.top, 4)

                            // 城市选择器（长按拖动排序，松手即保存）
                            if !viewModel.cities.isEmpty {
                                CitySelectorView(
                                    cities: viewModel.cities,
                                    selectedCityId: viewModel.selectedCityId,
                                    language: language,
                                    citySettingsLabel: strings.citySettings,
                                    onSelect: { viewModel.selectCity($0) },
                                    onAddCity: { showCitySearch = true },
                                    onReorder: { viewModel.reorderCities($0) }
                                )
                            }

                            // 指针时钟（颜色随背景明暗自适配）
                            AnalogClockView(
                                size: 200,
                                primaryColor: darkBackdrop ? Color(hex: 0xFF8FD0FF)
                                    : AppTheme.palette(viewModel.settings.themeColorIndex).primary,
                                textColor: onBackdrop,
                                language: language
                            )
                            .padding(.top, 8)
                            .padding(.bottom, 24)
                        }
                    }

                    // ===== 下半部：数据卡片 =====
                    VStack(spacing: 12) {
                        // 加载指示器
                        if viewModel.isRefreshing {
                            ProgressView()
                                .progressViewStyle(.linear)
                                .padding(.horizontal, 16)
                        }

                        // 当前天气卡片（城市名取自实时城市列表，本地化名称回写后立即生效）
                        WeatherCardView(
                            current: viewModel.selectedWeather?.current,
                            cityName: viewModel.selectedCity?.displayNameFor(language) ?? strings.noCitySelected,
                            tempUnit: viewModel.settings.temperatureUnit,
                            windUnit: viewModel.settings.windSpeedUnit,
                            strings: strings,
                            language: language
                        )
                        .padding(.horizontal, 16)

                        // AQI 指示条
                        AqiBarView(airQuality: viewModel.selectedWeather?.airQuality, strings: strings)
                            .padding(.horizontal, 16)

                        // 5日预报
                        let forecasts = viewModel.selectedWeather?.dayForecasts ?? []
                        if !forecasts.isEmpty {
                            ForecastCardView(
                                forecasts: forecasts,
                                tempUnit: viewModel.settings.temperatureUnit,
                                strings: strings,
                                language: language
                            )
                            .padding(.horizontal, 16)
                        }

                        // 空状态
                        if viewModel.cities.isEmpty {
                            VStack(spacing: 12) {
                                Text(strings.noCities)
                                    .font(.body)
                                    .foregroundStyle(.secondary)
                                Button(strings.addCity) { showCitySearch = true }
                                    .buttonStyle(.borderedProminent)
                            }
                            .padding(32)
                        }
                    }
                    .padding(.top, 12)
                    .padding(.bottom, 32)
                }
            }
            .background(AppTheme.pageBackground(colorScheme, paletteIndex: viewModel.settings.themeColorIndex))
            .ignoresSafeArea(edges: .top)
            .refreshable { await viewModel.refreshAll() }
            .navigationDestination(isPresented: $showSettings) {
                SettingsScreen()
            }
            .navigationDestination(isPresented: $showCitySearch) {
                CitySearchScreen()
            }
            .toolbar(.hidden, for: .navigationBar)
        }
    }
}

/// 城市切换选择器 - 质感实体化 Chip（阴影 + 渐变 + 描边），
/// 长按 Chip 拖动到其他 Chip 上即可自定义排序（对应 Android CitySelector）
struct CitySelectorView: View {
    let cities: [CityInfo]
    let selectedCityId: String?
    let language: AppLanguage
    let citySettingsLabel: String
    let onSelect: (String) -> Void
    let onAddCity: () -> Void
    let onReorder: ([CityInfo]) -> Void

    @State private var draggingId: String?

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(cities) { city in
                    CityChipView(
                        text: city.nameFor(language),
                        selected: city.id == selectedCityId,
                        dragging: draggingId == city.id
                    )
                    .onTapGesture { onSelect(city.id) }
                    .onDrag {
                        draggingId = city.id
                        return NSItemProvider(object: city.id as NSString)
                    }
                    .onDrop(of: [UTType.text], delegate: CityDropDelegate(
                        targetId: city.id,
                        cities: cities,
                        draggingId: $draggingId,
                        onReorder: onReorder
                    ))
                }

                // 城市设置入口（搜索添加 / 拖动排序 / 删除）
                Button(action: onAddCity) {
                    HStack(spacing: 6) {
                        Image(systemName: "gearshape")
                            .font(.system(size: 13))
                        Text(citySettingsLabel)
                            .font(.footnote)
                            .fontWeight(.medium)
                    }
                    .foregroundStyle(.tint)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 9)
                    .background(.regularMaterial, in: Capsule())
                    .overlay(Capsule().strokeBorder(Color.accentColor.opacity(0.5), lineWidth: 1))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
    }
}

/// 拖放排序委托：拖入目标 Chip 时实时交换位置，松手提交
private struct CityDropDelegate: DropDelegate {
    let targetId: String
    let cities: [CityInfo]
    @Binding var draggingId: String?
    let onReorder: ([CityInfo]) -> Void

    func dropEntered(info: DropInfo) {
        guard let dragId = draggingId, dragId != targetId,
              let from = cities.firstIndex(where: { $0.id == dragId }),
              let to = cities.firstIndex(where: { $0.id == targetId }) else { return }
        var newOrder = cities
        let item = newOrder.remove(at: from)
        newOrder.insert(item, at: to)
        onReorder(newOrder)
    }

    func dropUpdated(info: DropInfo) -> DropProposal? { DropProposal(operation: .move) }

    func performDrop(info: DropInfo) -> Bool {
        draggingId = nil
        return true
    }
}

/// 质感城市 Chip：立体阴影 + 垂直渐变填充 + 高亮描边；拖动中强化提示
private struct CityChipView: View {
    let text: String
    let selected: Bool
    let dragging: Bool

    var body: some View {
        Text(text)
            .font(.footnote)
            .fontWeight(selected ? .bold : .medium)
            .foregroundStyle(selected ? .white : .primary)
            .padding(.horizontal, 16)
            .padding(.vertical, 9)
            .background {
                if selected {
                    Capsule().fill(
                        LinearGradient(colors: [Color.accentColor, Color.accentColor.opacity(0.82)],
                                       startPoint: .top, endPoint: .bottom))
                } else {
                    Capsule().fill(.regularMaterial)
                }
            }
            .overlay {
                Capsule().strokeBorder(
                    dragging ? Color.orange
                        : selected ? Color.white.opacity(0.55) : Color.secondary.opacity(0.35),
                    lineWidth: dragging || selected ? 1.5 : 1)
            }
            .shadow(color: .black.opacity(dragging ? 0.25 : selected ? 0.15 : 0.08),
                    radius: dragging ? 10 : selected ? 5 : 3, y: 2)
            .scaleEffect(dragging ? 1.06 : 1)
            .animation(.snappy(duration: 0.18), value: dragging)
            .animation(.snappy(duration: 0.18), value: selected)
    }
}
