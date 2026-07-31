import Foundation

/// open-meteo API 客户端（URLSession async/await，与 Android ApiFactory 对应）
enum WeatherAPI {

    private static let session: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 15
        config.timeoutIntervalForResource = 30
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

    // MARK: - 天气预报（与 Android ForecastApi.getForecast 参数一致）

    static func getForecast(
        latitude: Double, longitude: Double,
        hourly: String = "temperature_2m,precipitation,weather_code,wind_speed_10m,visibility,cape,freezing_level_height",
        // 逐日字段：体感高低温与日出日落供预报详情展示；指定 models 时应传最小集合（模型不一定支持全部变量）
        daily: String = "weather_code,temperature_2m_max,temperature_2m_min,precipitation_sum,precipitation_probability_max,apparent_temperature_max,apparent_temperature_min,sunrise,sunset",
        models: String? = nil  // 指定数值模型（如 cma_grapes_global = 中国气象局 GRAPES），nil 时用默认最优模型
    ) async throws -> WeatherResponse {
        var query: [String: String] = [
            "latitude": String(latitude),
            "longitude": String(longitude),
            "current": "temperature_2m,relative_humidity_2m,apparent_temperature,weather_code,wind_speed_10m,wind_direction_10m,surface_pressure,visibility,dew_point_2m",
            "hourly": hourly,
            "daily": daily,
            "timezone": "auto",
            "forecast_days": "6"
        ]
        if let models { query["models"] = models }
        let url = makeURL(base: "https://api.open-meteo.com/", path: "v1/forecast", query: query)
        return try await fetch(WeatherResponse.self, url: url)
    }

    // MARK: - 空气质量

    static func getAirQuality(
        latitude: Double, longitude: Double,
        hourly: String? = nil  // 逐小时字段（如 us_aqi,uv_index），仅预警链路需要
    ) async throws -> AirQualityResponse {
        var query: [String: String] = [
            "latitude": String(latitude),
            "longitude": String(longitude),
            "current": "us_aqi,pm10,pm2_5,uv_index",
            // timezone=auto 保证小时时间戳为当地时间（与 forecast 接口对齐）
            "timezone": "auto"
        ]
        if let hourly { query["hourly"] = hourly }
        let url = makeURL(base: "https://air-quality-api.open-meteo.com/", path: "v1/air-quality", query: query)
        return try await fetch(AirQualityResponse.self, url: url)
    }

    // MARK: - 城市搜索（geocoding）

    static func searchCity(name: String, count: Int = 10, language: String = "zh") async throws -> [GeocodingResult] {
        let url = makeURL(base: "https://geocoding-api.open-meteo.com/", path: "v1/search", query: [
            "name": name,
            "count": String(count),
            "language": language
        ])
        let resp = try await fetch(GeocodingResponse.self, url: url)
        return resp.results ?? []
    }

    /// 按地点 ID 取指定语言的名称（search 接口不支持跨语言检索，get 接口可以）
    static func getCityById(id: Int, language: String = "en") async throws -> GeocodingResult {
        let url = makeURL(base: "https://geocoding-api.open-meteo.com/", path: "v1/get", query: [
            "id": String(id),
            "language": language
        ])
        return try await fetch(GeocodingResult.self, url: url)
    }
}
