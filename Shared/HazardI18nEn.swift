import Foundation

/// 地表防灾预报文案 —— 英语 / 日语（以 HazardI18n 扩展提供，由 HazardI18n.of 分派）
extension HazardI18n {

    static let hazardEn = HazardStrings(
        cardTitle: "Surface Hazard Outlook",
        cardLoading: "Fusing terrain and weather data…",
        cardEmpty: "No significant surface hazard risk in the next 48 hours",
        cardDisclaimer: "Generated on-device by a multi-factor model from elevation grids, soil and weather variables. Indicative only — always follow official geological and weather warnings.",
        chainLabel: "Knock-on effects",
        factorLabel: "Key factors",
        levels: ["Emergency", "Important", "General"],
        siteWords: [
            "hillside area", "low-lying area", "main road section", "riverbank",
            "coastal stretch", "reservoir area", "farmland block"
        ],
        metricLabels: [
            "Grid slope", "Rain total", "Rain rate", "Topsoil moisture", "Deep soil moisture", "Gust",
            "Snow depth", "New snow", "Min temp", "Max temp", "Freeze-thaw", "Visibility",
            "Humidity", "Min pressure", "Relief", "Lowland share", "CAPE", "Max wind"
        ],
        knownLocTemplate: "Near {name} (about {km} km {dir} of the city)",
        fallbackLocTemplate: "{site} about {km} km {dir} of the city",
        nearCityTemplate: "{site} in and around the city",
        timeWindowTemplate: "Next {t} h",
        countTemplate: "{n} items",
        hazards: [
            HazardText(
                "Debris flow",
                "Rainfall may total {a} in the next {t} h; saturated loose deposits upstream can mobilise into a debris flow along the gully and destroy roads and houses at its outlet.",
                "A debris flow can dam the gully and burst later, causing a second surge downstream; its sediment also clogs urban drains and worsens flooding."
            ),
            HazardText(
                "Landslide",
                "{a} of rain over {t} h plus deep soil moisture of {b} lowers slope shear strength, so the hillside may fail as a whole.",
                "The slide can cut roads and pipelines below; debris entering the river raises the bed and increases downstream levee overflow risk."
            ),
            HazardText(
                "Rockfall",
                "Rain and freeze-thaw widen rock joints, so rockfall is likely on steep sections within {t} h. Grid-scale slope here is about {a} — avoid roads and parking at the toe.",
                "Fallen blocks can close a lane, and sudden avoidance by following vehicles easily triggers secondary crashes."
            ),
            HazardText(
                "Embankment slope failure",
                "Road embankments have been soaked; {a} of rain in {t} h may cause shoulder collapse and slope slumping, leaving single-lane or fully closed traffic.",
                "Debris blocking the drainage ditch lets surface water rise fast, scouring the subgrade further into a sinkhole."
            ),
            HazardText(
                "Flash flood",
                "Intense rain ({a} in {t} h, peak hourly {b}) concentrates quickly in mountain catchments; creek levels can surge and make riverbeds and campsites dangerous.",
                "Floating debris blocks culverts and backwater floods upstream village roads; the flood peak then adds to urban drainage and lifts downstream river levels."
            ),
            HazardText(
                "Road ponding",
                "Rainfall of {a} in {t} h exceeds drainage capacity; ponding on low-lying roads may rise to about {b}, with a high risk of small cars stalling.",
                "Water over manholes can lift covers into hidden pits; flooded basements and switchgear also cause power cuts and lift outages."
            ),
            HazardText(
                "Underpass flooding",
                "Underpasses and railway culverts are the lowest collection points; backflow may pond about {a} within {t} h — over 0.3 m the passage must be closed.",
                "Stranded vehicles force long pumping operations that occupy lanes, causing chain congestion on the surrounding network."
            ),
            HazardText(
                "River overflow",
                "Basin rainfall of {a} in {t} h should raise the river level by about {b}; low levee sections and riverside walkways may be overtopped.",
                "The rising river backs up tributaries and storm outfalls, so riverside districts drain poorly and flood recession takes hours longer."
            ),
            HazardText(
                "Reservoir release",
                "Inflow of {a} over {t} h in the catchment may force a gate release to free flood storage, briefly raising downstream discharge.",
                "When release coincides with the rain peak, downstream riverbed worksites and low-water bridges must be evacuated in advance."
            ),
            HazardText(
                "Farmland waterlogging",
                "Farmland receives {a} in {t} h with topsoil moisture at {b}; poorly drained plots will waterlog and roots will suffer oxygen deficit.",
                "Waterlogging beyond two days triggers root rot and lodging, and the hot humid recession period worsens pest and disease outbreaks."
            ),
            HazardText(
                "Storm surge",
                "Coastal pressure falls to {a} with strong onshore wind; the coastline water level may rise about {b}, overtopping low shores at astronomical high tide.",
                "The surge backs up river mouths and lifts estuary levels; seawater intrusion also salinises coastal farmland and buried pipe networks."
            ),
            HazardText(
                "High waves",
                "With gusts of {a}, nearshore significant wave height may reach {b}; reefs, breakwaters and wave-watching platforms risk sweeping people away.",
                "Once armour stones are dislodged, continued tides scour the toe of the seawall and the shoreline retreats."
            ),
            HazardText(
                "Tidal backflow",
                "High tide backs up {a} of upstream inflow over {t} h; drainage in the tidal reach is blocked and low-lying banks may flood.",
                "Saline backflow enters the drainage network, and post-ebb silting and corrosion reduce future pumping capacity."
            ),
            HazardText(
                "Road icing",
                "A minimum temperature of {a} with a liquid film on the pavement makes road icing likely within {t} h, multiplying braking distance.",
                "A rear-end crash on ice blocks rescue vehicles, and traffic diverted from the closed section overloads secondary roads."
            ),
            HazardText(
                "Black ice on bridges",
                "Bridge and viaduct decks lose heat from both faces and cool faster than normal pavement, so black ice is possible within {t} h at {a}.",
                "Loss of control against the parapet damages expansion joints, forcing long-term speed limits and reduced capacity."
            ),
            HazardText(
                "Snow load",
                "New snow of {a} and a snow depth of {b} push light canopies, wide-span steel roofs and greenhouses toward their load limits.",
                "A roof collapse can sever service cables, and during melt sliding snow blocks threaten pedestrians below the eaves."
            ),
            HazardText(
                "Avalanche",
                "Alpine snow depth of {a} with {b} of fresh snow leaves weak layers unstable; avalanches are possible on steep lee slopes.",
                "Avalanche deposits block valley roads and streams, and after warming the meltwater release forms snowmelt floods."
            ),
            HazardText(
                "Snowmelt flood",
                "Temperature rising to {a} puts {b} of snowpack into rapid melt; melt runoff plus rain will lift river levels within {t} h.",
                "Infiltrating meltwater saturates slopes, so landslide and subgrade frost-boiling probabilities rise together."
            ),
            HazardText(
                "Frost boiling",
                "About {a} freeze-thaw cycles are expected in {t} h; a wet subgrade swells and shrinks repeatedly, producing boiling, cracks and potholes.",
                "Water in potholes refreezes at night into local ice pits, sharply raising skid risk for two-wheelers."
            ),
            HazardText(
                "Wind damage",
                "Gusts may reach {a} (about force {b}); billboards, site hoardings, street trees and temporary structures risk collapse or being torn off.",
                "Broken branches on power lines cause outages, and falling objects block footpaths — keep away from street-facing balconies and scaffolding."
            ),
            HazardText(
                "Patchy fog on highways",
                "Under humid, calm conditions visibility may drop to {a} m; patchy fog forms on motorways and river bridges with abrupt visibility changes.",
                "Any collision inside patchy fog is amplified because following vehicles cannot brake in time, and closure becomes likely."
            ),
            HazardText(
                "Blowing dust",
                "Dry ground (humidity as low as {b}%) with gusts of {a} raises dust from bare soil and construction sites, briefly cutting visibility.",
                "Dust degrades air quality fast and worsens symptoms for sensitive groups; grit on the pavement also lowers tyre grip."
            ),
            HazardText(
                "Wildfire risk",
                "Prolonged dry weather, humidity down to {b}% and a maximum temperature of {a} leave forest and grass fuels dry, so fire danger is elevated.",
                "Fire spreads fast upslope, and once vegetation binding is lost the next rainfall easily triggers erosion and debris flow."
            ),
            HazardText(
                "Soil cracking",
                "Rainfall has been scarce over the past {t} h and topsoil moisture has fallen to {a}; farmland surfaces shrink and crack, stressing crops.",
                "Cracks accelerate deep moisture loss, and later heavy rain infiltrating along them actually raises the chance of slope farmland failure."
            ),
            HazardText(
                "Pavement collapse",
                "Rain scour plus pipe leakage means {a} of rain in {t} h may hollow the subgrade into a sinkhole; abnormal sagging or a whirlpool in ponded water is the warning sign.",
                "A sinkhole damaging buried utilities can cause gas leaks or water supply loss, and repair closures reshape local traffic."
            ),
            HazardText(
                "Soil erosion",
                "Bare slopes under {a} of rain in {t} h suffer sheet and rill erosion, and sediment enters downstream channels with the runoff.",
                "Sediment raises riverbeds and ditch inverts, so the overflow threshold drops for the same rainfall and flood risk rises."
            )
        ]
    )

    static let hazardJa = HazardStrings(
        cardTitle: "地表防災予報",
        cardLoading: "地形と気象データを統合して推論中…",
        cardEmpty: "今後 48 時間、顕著な地表災害リスクは見られません",
        cardDisclaimer: "本モジュールは標高グリッド・土壌・気象要素から端末内の多因子モデルで推論した参考情報です。実際の判断は公式の地質・気象警報に従ってください。",
        chainLabel: "連鎖的影響",
        factorLabel: "主要因子",
        levels: ["緊急", "重要", "一般"],
        siteWords: [
            "山斜面一帯", "低地一帯", "主要道路区間", "河川沿岸",
            "海岸区間", "ダム周辺", "農地区画"
        ],
        metricLabels: [
            "格子傾斜", "累積雨量", "時間雨量", "表層土壌水分", "深層土壌水分", "突風",
            "積雪深", "新規降雪", "最低気温", "最高気温", "凍結融解", "視程",
            "相対湿度", "最低気圧", "起伏量", "低地比率", "対流有効位置エネルギー", "最大風速"
        ],
        knownLocTemplate: "{name} 付近（市街地の{dir}約 {km} km）",
        fallbackLocTemplate: "市街地の{dir}約 {km} km の{site}",
        nearCityTemplate: "市街地および近郊の{site}",
        timeWindowTemplate: "今後 {t} 時間",
        countTemplate: "{n} 件",
        hazards: [
            HazardText(
                "土石流",
                "今後{t}時間の累積雨量が {a} に達する見込みで、渓流上流の不安定な堆積物が飽和し、土石流となって流下して出口の道路や家屋を破壊するおそれがあります。",
                "土石流が渓流を塞いで天然ダムを形成し、決壊すれば下流で二次的な増水を招きます。土砂は都市の排水口も詰まらせ内水氾濫を悪化させます。"
            ),
            HazardText(
                "地すべり",
                "{t}時間雨量 {a} に深層土壌水分 {b} が重なり、斜面のせん断強度が低下して斜面全体が滑動するおそれがあります。",
                "崩落土塊は斜面下の道路や管路を断絶し、河川に流入すると河床が上昇して下流の越流危険が高まります。"
            ),
            HazardText(
                "落石・崩落",
                "降雨と凍結融解で岩盤の亀裂が拡大し、今後{t}時間は急斜面区間で落石・崩落が発生しやすくなります。当地点の格子傾斜は約 {a} で、斜面下の道路や駐車区域は避けてください。",
                "落石の堆積で片側車線が不通となり、後続車の急な回避が二次事故を招きやすくなります。"
            ),
            HazardText(
                "路盤法面崩壊",
                "路盤法面が長時間浸水しており、今後{t}時間の {a} の降雨で路肩崩壊や法面の滑落が生じ、片側通行や通行止めとなるおそれがあります。",
                "崩土が側溝を塞ぐと路面水位が急上昇し、路盤をさらに洗掘して陥没坑を形成します。"
            ),
            HazardText(
                "鉄砲水",
                "短時間強雨（{t}時間 {a}、最大時間雨量 {b}）が山地で急速に集水し、渓流の水位が急上昇して河原やキャンプ地が危険になります。",
                "流木や転石が橋やカルバートを塞ぎ、背水で上流の集落道が浸水します。洪水波は下流で都市排水と重なり水位をさらに押し上げます。"
            ),
            HazardText(
                "路面浸水",
                "今後{t}時間の降雨 {a} が排水能力を超え、低地の道路では約 {b} の浸水が想定されます。小型車のエンストリスクが高い状況です。",
                "マンホールが水没すると蓋が押し上げられ見えない穴になります。地下駐車場や配電盤の浸水は停電やエレベーター停止も招きます。"
            ),
            HazardText(
                "アンダーパス浸水",
                "アンダーパスや鉄道カルバートは集水の最低点で、今後{t}時間に約 {a} の逆流浸水が想定されます。0.3 m を超えれば通行禁止としてください。",
                "車両滞留後の排水作業が長時間車線を占用し、周辺道路網で連鎖的な渋滞が発生します。"
            ),
            HazardText(
                "河川増水・越流",
                "流域{t}時間の面雨量 {a} により河川水位は約 {b} 上昇する見込みで、低い堤防区間や河畔遊歩道が越水するおそれがあります。",
                "本流の増水が支流や雨水吐口を押し戻すため、沿川地区の排水が滞り内水の引きが数時間遅れます。"
            ),
            HazardText(
                "ダム放流",
                "集水域の{t}時間流入量が {a} となり、洪水調節容量を確保するためゲート放流の可能性があります。下流流量が短時間で増加します。",
                "放流と降雨のピークが重なる場合、下流の河原の作業場や潜水橋は事前に退避が必要です。"
            ),
            HazardText(
                "農地浸水",
                "農地の{t}時間雨量が {a}、表層土壌水分は {b} に達しており、排水不良の圃場では滞水し根が酸素不足になります。",
                "滞水が 2 日を超えると根腐れや倒伏を誘発し、排水後の高温多湿は病害虫の蔓延も助長します。"
            ),
            HazardText(
                "高潮",
                "沿岸気圧が {a} まで低下し強い向岸風を伴うため、海岸線の水位は約 {b} 上昇する見込みです。天文潮位の高い時刻に低い海岸が越波します。",
                "高潮が河口を押し戻して河口部の水位も同時に上昇します。海水の逆流は沿岸農地や地下管網の塩害も引き起こします。"
            ),
            HazardText(
                "沿岸高波",
                "突風 {a} により沿岸の有効波高は {b} に達する見込みで、磯場・防波堤・観波デッキでは波にさらわれる危険があります。",
                "高波で被覆ブロックが崩れると、その後の潮汐が堤脚を洗掘し続け海岸線が後退します。"
            ),
            HazardText(
                "潮位による逆流",
                "高潮位の押し戻しに上流{t}時間の流入 {a} が重なり、感潮区間の排水が阻害されて沿岸低地で逆流のおそれがあります。",
                "逆流した塩水が排水管網に入り、引き潮後の堆積と腐食が進んで排水能力が低下します。"
            ),
            HazardText(
                "路面凍結",
                "最低気温 {a} で路面に水膜が残るため、今後{t}時間は路面凍結が生じやすく制動距離が数倍に伸びます。",
                "凍結区間での追突事故は救援車両の通行を妨げ、通行止め区間の迂回交通が補助幹線に集中します。"
            ),
            HazardText(
                "橋面のブラックアイス",
                "橋梁や高架は上下面から放熱するため通常路面より早く冷え、最低気温 {a} では{t}時間以内にブラックアイスが生じるおそれがあります。",
                "制御を失った車両が防護柵に衝突し、伸縮装置が損傷すると速度規制が長期化して交通容量が低下します。"
            ),
            HazardText(
                "積雪荷重",
                "新規降雪 {a}、積雪深 {b} により、簡易テントや大スパンの折板屋根、温室では荷重が限界を超えるおそれがあります。",
                "屋根の崩落は引込線を切断するおそれがあり、融雪期の落雪は軒下通路の歩行者も脅かします。"
            ),
            HazardText(
                "雪崩",
                "高山の積雪深 {a} に新雪 {b} が重なり弱層が不安定で、風下側の急斜面で雪崩が発生するおそれがあります。",
                "雪崩の堆積が谷の道路や渓流を塞ぎ、気温上昇後の融雪水が融雪洪水を引き起こします。"
            ),
            HazardText(
                "融雪洪水",
                "気温が {a} まで上昇し積雪 {b} が急速な融解期に入るため、今後{t}時間は融雪流出と降雨が重なり河川水位が上昇します。",
                "浸透した融雪水が斜面を飽和させ、地すべりや路盤の軟弱化の確率も同時に高まります。"
            ),
            HazardText(
                "凍上・軟弱化",
                "今後{t}時間で約 {a} 回の凍結融解が予想され、含水路盤が膨張収縮を繰り返して軟弱化・亀裂・ポットホールが生じます。",
                "ポットホールの水が夜間に再凍結して局所的な氷穴となり、二輪車のスリップ危険が大きく高まります。"
            ),
            HazardText(
                "強風被害",
                "突風は {a}（およそ風力 {b}）に達し、看板・工事用仮囲い・街路樹・仮設物の倒壊や飛散のおそれがあります。",
                "折れた枝が電線に覆いかぶさり停電を招きます。落下物が歩道を塞ぐため、通りに面したバルコニーや足場は避けてください。"
            ),
            HazardText(
                "高速道の局所霧",
                "高湿・弱風の条件で視程が {a} m まで低下する可能性があり、高速道路や河川橋では局所霧が発生して視程が急変します。",
                "局所霧内で衝突が起きると後続車が減速しきれず事故が拡大し、区間閉鎖の可能性が高まります。"
            ),
            HazardText(
                "砂じん・飛砂",
                "地表の乾燥（相対湿度 {b}% まで低下）に突風 {a} が重なり、裸地や工事現場から砂じんが舞い上がって視程が一時的に低下します。",
                "砂じんで大気質が急速に悪化し呼吸器の弱い方の症状が重くなります。路面の砂粒はタイヤの摩擦も低下させます。"
            ),
            HazardText(
                "山林火災危険",
                "少雨が続き相対湿度は {b}%、最高気温 {a} で林地や草地の可燃物含水率が低く、火災危険度が高まっています。",
                "山火事は斜面を上方に速く広がり、植生の緊縛を失った斜面は次の降雨で土壌流出や土石流を招きやすくなります。"
            ),
            HazardText(
                "土壌の乾燥亀裂",
                "直近{t}時間の降水が少なく表層土壌水分が {a} まで低下し、農地表層が収縮して亀裂が生じ作物が乾燥ストレスを受けます。",
                "亀裂は深層の水分損失を加速させ、その後の強雨が亀裂沿いに浸透して傾斜農地の崩落可能性を高めます。"
            ),
            HazardText(
                "路面陥没",
                "強雨の洗掘と管網の漏水が重なり、今後{t}時間の雨量 {a} で路盤が空洞化し陥没するおそれがあります。異常な沈下や水たまりの渦は前兆です。",
                "陥没坑が地下埋設管を損傷するとガス漏れや断水を招き、復旧のための通行止めが周辺の交通体系を変えます。"
            ),
            HazardText(
                "土壌侵食",
                "裸地の斜面が{t}時間 {a} の降雨で面状侵食やリル侵食を受け、土砂が流出して下流の水路に流入します。",
                "土砂の堆積で河床や側溝底が上がり、同じ雨量でも越流しやすくなって内水氾濫や越堤の危険が高まります。"
            )
        ]
    )
}
