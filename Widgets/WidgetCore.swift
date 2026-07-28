import WidgetKit
import SwiftUI
import AppIntents

/// 小组件包入口：时钟 + 气象
@main
struct SkySenseWidgetBundle: WidgetBundle {
    var body: some Widget {
        ClockWidget()
        WeatherWidget()
    }
}

// MARK: - 城市选择（对应 Android WeatherWidgetConfigActivity：每个组件实例独立绑定城市）

/// 城市实体：来源于主应用已添加的城市列表（App Group 共享）
struct CityEntity: AppEntity {
    static var typeDisplayRepresentation: TypeDisplayRepresentation = "城市"
    static var defaultQuery = CityEntityQuery()

    var id: String
    var name: String

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(name)")
    }
}

struct CityEntityQuery: EntityQuery {
    func entities(for identifiers: [String]) async throws -> [CityEntity] {
        AppStore.shared.getCities()
            .filter { identifiers.contains($0.id) }
            .map { CityEntity(id: $0.id, name: $0.name) }
    }

    func suggestedEntities() async throws -> [CityEntity] {
        AppStore.shared.getCities().map { CityEntity(id: $0.id, name: $0.name) }
    }

    /// 默认跟随主应用"当前城市"
    func defaultResult() async -> CityEntity? {
        let store = AppStore.shared
        let cities = store.getCities()
        let selected = store.getSelectedCityId()
        let city = cities.first { $0.id == selected } ?? cities.first
        return city.map { CityEntity(id: $0.id, name: $0.name) }
    }
}

/// 气象小组件配置意图：长按小组件 -> 编辑 -> 选择城市
struct SelectCityIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "选择城市"
    static var description = IntentDescription("为此小组件选择展示天气的城市")

    @Parameter(title: "城市")
    var city: CityEntity?
}

// MARK: - 小组件公共工具

enum WidgetHelper {

    /// 解析组件实例绑定的城市：意图配置优先，未配置则跟随主应用当前城市
    static func resolveCity(_ intent: SelectCityIntent) -> CityInfo? {
        let store = AppStore.shared
        let cities = store.getCities()
        guard !cities.isEmpty else { return nil }
        if let boundId = intent.city?.id, let bound = cities.first(where: { $0.id == boundId }) {
            return bound
        }
        let selected = store.getSelectedCityId()
        return cities.first { $0.id == selected } ?? cities.first
    }

    /// 底板渐变（叠加用户自定义透明度 20~100%）
    static func background(style: WidgetStyle, opacityPercent: Int) -> some View {
        let alpha = Double(min(max(opacityPercent, 20), 100)) / 100.0
        return LinearGradient(colors: style.gradient.map { $0.opacity(alpha) },
                              startPoint: .top, endPoint: .bottom)
    }
}
