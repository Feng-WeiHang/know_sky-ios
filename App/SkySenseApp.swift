import SwiftUI
import BackgroundTasks
import UserNotifications
import WidgetKit

/// 识天 SkySense - 应用入口
/// 对应 Android ClockWeatherApp + MainActivity
@main
struct SkySenseApp: App {

    static let refreshTaskId = "com.xiaotian.skysense.refresh"
    static let alertTaskId = "com.xiaotian.skysense.alertcheck"

    @StateObject private var viewModel = WeatherViewModel()
    @Environment(\.scenePhase) private var scenePhase

    init() {
        registerBackgroundTasks()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(viewModel)
                .task {
                    await requestNotificationPermission()
                    // 定位授权：AQI/UVI 预警直接按 GPS 实际坐标取数，前台先定位并落盘
                    LocationService.shared.requestAuthorizationAndLocate()
                    scheduleBackgroundTasks()
                }
        }
        .onChange(of: scenePhase) { _, phase in
            switch phase {
            case .active:
                Task { await viewModel.refreshIfStale() }
                // 回到前台刷新定位（后台任务定位受限，依赖前台落盘的定位点）
                LocationService.shared.requestAuthorizationAndLocate()
            case .background:
                scheduleBackgroundTasks()
                WidgetCenter.shared.reloadAllTimelines()
            default:
                break
            }
        }
    }

    // MARK: - 后台任务（对应 Android WorkManager 周期任务）

    private func registerBackgroundTasks() {
        // 天气自动刷新（对应 WidgetUpdateWorker，间隔跟随设置）
        BGTaskScheduler.shared.register(forTaskWithIdentifier: Self.refreshTaskId, using: nil) { task in
            handleRefreshTask(task as! BGAppRefreshTask)
        }
        // 预警检测（对应 AlertCheckWorker）
        BGTaskScheduler.shared.register(forTaskWithIdentifier: Self.alertTaskId, using: nil) { task in
            handleAlertTask(task as! BGAppRefreshTask)
        }
    }

    private func scheduleBackgroundTasks() {
        let settings = AppStore.shared.getSettings()

        let refresh = BGAppRefreshTaskRequest(identifier: Self.refreshTaskId)
        refresh.earliestBeginDate = Date(timeIntervalSinceNow: TimeInterval(settings.refreshIntervalMinutes * 60))
        try? BGTaskScheduler.shared.submit(refresh)

        let alert = BGAppRefreshTaskRequest(identifier: Self.alertTaskId)
        alert.earliestBeginDate = Date(timeIntervalSinceNow: 15 * 60)
        try? BGTaskScheduler.shared.submit(alert)
    }

    private func handleRefreshTask(_ task: BGAppRefreshTask) {
        scheduleBackgroundTasks() // 续订下一次
        let work = Task {
            _ = await WeatherRepository.shared.fetchAllCitiesWeather()
            WidgetCenter.shared.reloadAllTimelines()
            task.setTaskCompleted(success: true)
        }
        task.expirationHandler = { work.cancel() }
    }

    private func handleAlertTask(_ task: BGAppRefreshTask) {
        scheduleBackgroundTasks()
        let work = Task {
            await AlertService.shared.checkAllCities()
            task.setTaskCompleted(success: true)
        }
        task.expirationHandler = { work.cancel() }
    }

    private func requestNotificationPermission() async {
        _ = try? await UNUserNotificationCenter.current()
            .requestAuthorization(options: [.alert, .sound, .badge])
    }
}

/// 根视图：注入语言环境与主题
struct RootView: View {
    @EnvironmentObject var viewModel: WeatherViewModel

    var body: some View {
        HomeScreen()
            .preferredColorScheme(colorScheme)
            .tint(AppTheme.palette(viewModel.settings.themeColorIndex).primary)
    }

    private var colorScheme: ColorScheme? {
        switch viewModel.settings.themeMode {
        case .light: return .light
        case .dark: return .dark
        case .system: return nil
        }
    }
}
