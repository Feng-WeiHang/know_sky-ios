import Foundation

/// 地表防灾预报所需的三类数据源（均为免费公开接口，无需 API Key）
/// 对应 Android data/api/GeoApiService.kt。Overpass 与高程接口响应慢，用更长超时的独立会话。
enum GeoAPI {

    /// 灾害推理专用逐小时要素（土壤湿度/积雪/冻结高度等，默认预报接口不含）
    static let hourlyFields =
        "temperature_2m,relative_humidity_2m,precipitation,rain,snowfall,snow_depth," +
        "precipitation_probability,wind_speed_10m,wind_gusts_10m,wind_direction_10m," +
        "visibility,surface_pressure,soil_moisture_0_to_1cm,soil_moisture_3_to_9cm," +
        "soil_moisture_27_to_81cm,soil_temperature_0cm,freezing_level_height,cape,weather_code"

    private static let session: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 20
        config.timeoutIntervalForResource = 35
        // Overpass 要求带可识别的 User-Agent，否则可能被限流
        config.httpAdditionalHeaders = ["User-Agent": "SkySense/1.0 (personal weather app)"]
        return URLSession(configuration: config)
    }()

    private static func fetch<T: Decodable>(_ type: T.Type, url: URL) async throws -> T {
        let (data, response) = try await session.data(from: url)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }
        return try JSONDecoder().decode(T.self, from: data)
    }

    private static func makeURL(base: String, path: String, query: [String: String]) -> URL {
        var comp = URLComponents(string: base + path)!
        comp.queryItems = query.map { URLQueryItem(name: $0.key, value: $0.value) }
        return comp.url!
    }

    // MARK: - 灾害要素预报

    static func getHazardForecast(latitude: Double, longitude: Double) async throws -> HazardForecastResponse {
        let url = makeURL(base: "https://api.open-meteo.com/", path: "v1/forecast", query: [
            "latitude": String(latitude),
            "longitude": String(longitude),
            "current": "temperature_2m",
            "hourly": hourlyFields,
            "timezone": "auto",
            "forecast_days": "3"
        ])
        return try await fetch(HazardForecastResponse.self, url: url)
    }

    // MARK: - 数字高程（单次最多 100 个坐标，返回等长海拔数组，单位米）

    static func getElevations(latitudes: String, longitudes: String) async throws -> ElevationResponse {
        let url = makeURL(base: "https://api.open-meteo.com/", path: "v1/elevation", query: [
            "latitude": latitudes,
            "longitude": longitudes
        ])
        return try await fetch(ElevationResponse.self, url: url)
    }

    // MARK: - OSM Overpass 具名地理要素（村镇/街区/高速/河流/水库/海岸线/山峰）

    static func queryOverpass(_ data: String) async throws -> OverpassResponse {
        let url = makeURL(base: "https://overpass-api.de/", path: "api/interpreter", query: ["data": data])
        return try await fetch(OverpassResponse.self, url: url)
    }

    /// 构造周边要素查询语句（半径 radiusM 米）
    static func buildOverpassQuery(lat: Double, lon: Double, radiusM: Int = 15000) -> String {
        let la = String(format: "%.4f", locale: Locale(identifier: "en_US_POSIX"), lat)
        let lo = String(format: "%.4f", locale: Locale(identifier: "en_US_POSIX"), lon)
        let r = String(radiusM)
        var q = "[out:json][timeout:25];("
        q += "node[\"place\"~\"^(town|suburb|village|hamlet|neighbourhood|quarter)$\"](around:\(r),\(la),\(lo));"
        q += "node[\"natural\"=\"peak\"][\"name\"](around:\(r),\(la),\(lo));"
        q += "way[\"highway\"~\"^(motorway|trunk|primary)$\"][\"name\"](around:\(r),\(la),\(lo));"
        q += "way[\"waterway\"~\"^(river|stream|canal)$\"][\"name\"](around:\(r),\(la),\(lo));"
        q += "way[\"natural\"=\"coastline\"](around:\(r),\(la),\(lo));"
        q += "way[\"water\"~\"^(reservoir|lake)$\"][\"name\"](around:\(r),\(la),\(lo));"
        q += ");out center 300;"
        return q
    }
}
