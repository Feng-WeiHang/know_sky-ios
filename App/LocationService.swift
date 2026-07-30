import Foundation
import CoreLocation

/// GPS 定位服务：获取最近一次已知位置，并在已添加城市中匹配最近的"当前城市"
/// （AQI/UVI 预警仅针对当前城市推送），对应 Android LocationHelper
final class LocationService: NSObject, CLLocationManagerDelegate {

    static let shared = LocationService()

    private let manager = CLLocationManager()
    private var lastLocation: CLLocation?

    private override init() {
        super.init()
        manager.delegate = self
        // 城市级匹配无需高精度，公里级足够且省电
        manager.desiredAccuracy = kCLLocationAccuracyKilometer
    }

    /// 请求定位授权并发起一次定位（App 启动时调用）
    func requestAuthorizationAndLocate() {
        switch manager.authorizationStatus {
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways:
            manager.requestLocation()
        default:
            break
        }
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        if manager.authorizationStatus == .authorizedWhenInUse ||
            manager.authorizationStatus == .authorizedAlways {
            manager.requestLocation()
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        lastLocation = locations.last
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        // 定位失败静默，预警链路自动回退列表首城
    }

    /// 最近一次已知位置（本次会话无新定位时回退系统缓存位置）
    var currentLocation: CLLocation? { lastLocation ?? manager.location }

    /// 在已添加城市中找距 GPS 位置最近的城市作为"当前城市"；
    /// 定位不可用（未授权/无历史位置）时回退列表首城，保证预警不中断
    func resolveCurrentCity(from cities: [CityInfo]) -> CityInfo? {
        guard !cities.isEmpty else { return nil }
        guard let loc = currentLocation else { return cities.first }
        return cities.min { lhs, rhs in
            loc.distance(from: CLLocation(latitude: lhs.latitude, longitude: lhs.longitude)) <
                loc.distance(from: CLLocation(latitude: rhs.latitude, longitude: rhs.longitude))
        }
    }
}
