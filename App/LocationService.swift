import Foundation
import CoreLocation

/// GPS 定位服务：主动定位一次、反查地名、把定位点落盘缓存
///
/// AQI/UVI 预警直接使用定位坐标向接口取数（不再套用已添加城市的坐标），
/// 因此定位点必须真实且新鲜：15 分钟内视为新鲜（不重复定位），
/// 超过 12 小时视为失效（不用于预警判定）。对应 Android LocationHelper。
final class LocationService: NSObject, CLLocationManagerDelegate {

    static let shared = LocationService()

    /// 单次定位超时；超时后回退系统缓存位置
    private static let locateTimeout: TimeInterval = 12
    /// 离线索引条目距定位点超过该距离视为不可信，改用系统逆地理编码
    private static let maxReverseDistanceKm: Double = 150

    private let manager = CLLocationManager()
    private let lock = NSLock()
    private var pending: [CheckedContinuation<CLLocation?, Never>] = []

    private override init() {
        super.init()
        manager.delegate = self
        // 城市级判定无需高精度，公里级足够且省电
        manager.desiredAccuracy = kCLLocationAccuracyKilometer
    }

    private var isAuthorized: Bool {
        let status = manager.authorizationStatus
        return status == .authorizedWhenInUse || status == .authorizedAlways
    }

    /// 请求定位授权并刷新定位（App 启动 / 回到前台 / 进入设置页时调用）
    func requestAuthorizationAndLocate() {
        if manager.authorizationStatus == .notDetermined {
            manager.requestWhenInUseAuthorization()
            return
        }
        Task { _ = await refreshCurrentLocation() }
    }

    /// 前台调用：必要时主动定位一次，反查地名后落盘。
    /// 缓存点仍新鲜（15 分钟内）且未强制刷新时直接复用，避免频繁唤醒 GPS
    @discardableResult
    func refreshCurrentLocation(force: Bool = false) async -> CurrentLocationPoint? {
        guard isAuthorized else {
            if manager.authorizationStatus == .notDetermined {
                manager.requestWhenInUseAuthorization()
            }
            return nil
        }

        let cached = AppStore.shared.getCurrentLocation()
        if !force, let cached, cached.isFresh { return cached }

        guard let location = await requestSingleLocation() ?? manager.location else { return cached }

        let name = await reverseGeocodeName(
            latitude: location.coordinate.latitude,
            longitude: location.coordinate.longitude
        ) ?? ""
        let point = CurrentLocationPoint(
            latitude: location.coordinate.latitude,
            longitude: location.coordinate.longitude,
            name: name,
            timestamp: location.timestamp
        )
        AppStore.shared.saveCurrentLocation(point)
        return point
    }

    /// 预警链路调用：返回 12 小时有效期内的定位点，超期或无定位返回 nil
    /// （后台任务中定位常被系统拒绝，此时自动回退前台落盘的缓存点）
    func currentPointForAlert() async -> CurrentLocationPoint? {
        guard isAuthorized else { return nil }
        let point = await refreshCurrentLocation() ?? AppStore.shared.getCurrentLocation()
        guard let point, point.isValid else { return nil }
        return point
    }

    /// 地名反查：中国境内用内置离线区县索引，海外用系统逆地理编码
    func reverseGeocodeName(latitude: Double, longitude: Double) async -> String? {
        if ClimatePlausibility.isInChina(latitude: latitude, longitude: longitude),
           let hit = ChinaRegionIndex.nearest(latitude: latitude, longitude: longitude),
           hit.distanceKm <= Self.maxReverseDistanceKm {
            return hit.name
        }
        let placemark = try? await CLGeocoder().reverseGeocodeLocation(
            CLLocation(latitude: latitude, longitude: longitude)
        ).first
        guard let placemark else { return nil }
        return placemark.locality
            ?? placemark.subAdministrativeArea
            ?? placemark.administrativeArea
            ?? placemark.country
    }

    // MARK: - 单次定位（超时保护）

    private func requestSingleLocation() async -> CLLocation? {
        await withCheckedContinuation { (continuation: CheckedContinuation<CLLocation?, Never>) in
            lock.lock()
            pending.append(continuation)
            let isFirst = pending.count == 1
            lock.unlock()

            guard isFirst else { return }
            DispatchQueue.main.async { self.manager.requestLocation() }
            DispatchQueue.main.asyncAfter(deadline: .now() + Self.locateTimeout) { [weak self] in
                self?.deliver(nil)
            }
        }
    }

    /// 唤醒所有等待中的定位请求；已唤醒过则为空操作，避免重复 resume
    private func deliver(_ location: CLLocation?) {
        lock.lock()
        let waiters = pending
        pending.removeAll()
        lock.unlock()
        for waiter in waiters { waiter.resume(returning: location) }
    }

    // MARK: - CLLocationManagerDelegate

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        if isAuthorized {
            Task { _ = await refreshCurrentLocation(force: true) }
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        deliver(locations.last)
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        // 定位失败：回退系统缓存位置，若无有效定位则跳过 AQI/UVI 预警（不误报其他城市）
        deliver(nil)
    }
}
