import SwiftUI

/// 地表防灾预报卡片（对应 Android ui/components/HazardCard.kt）
///
/// 预测条目已在引擎侧按「紧急 → 重要 → 一般」再按评分降序排好，这里按序展示；
/// 条目较多时列表限高 420 pt 并在卡片内部纵向滚动（带滚动指示条），不撑破外层页面。
struct HazardCardView: View {
    let state: HazardUiState
    let strings: Strings
    let language: AppLanguage

    private static let listMaxHeight: CGFloat = 420

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        let s = HazardI18n.of(language)
        let isLight = colorScheme != .dark

        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                Text(s.cardTitle)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Spacer()
                if !state.predictions.isEmpty {
                    Text(HazardI18n.renderCount(state.predictions.count, s))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 16)

            if state.predictions.isEmpty {
                Text(hintText(s))
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 16)
            } else {
                ScrollView(.vertical) {
                    VStack(alignment: .leading, spacing: 10) {
                        ForEach(Array(state.predictions.enumerated()), id: \.offset) { index, p in
                            if index > 0 { Divider() }
                            HazardItemView(
                                prediction: p,
                                s: s,
                                windDirs: strings.windDirs,
                                isLight: isLight
                            )
                        }
                    }
                    .padding(.horizontal, 16)
                }
                .frame(maxHeight: Self.listMaxHeight)
            }

            Text(s.cardDisclaimer)
                .font(.caption2)
                .foregroundStyle(.tertiary)
                .padding(.horizontal, 16)
        }
        .padding(.vertical, 16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: .black.opacity(0.06), radius: 8, y: 2)
    }

    /// 尚未推演完成时提示加载，推演过但无结果才显示「无风险」
    private func hintText(_ s: HazardStrings) -> String {
        if state.isLoading { return s.cardLoading }
        return state.analyzed ? s.cardEmpty : s.cardLoading
    }
}

/// 单条预测：等级色条 + 等级标签 + 灾害名 + 时效 + 地点 + 说明 + 关键因子 + 连锁影响
private struct HazardItemView: View {
    let prediction: HazardPrediction
    let s: HazardStrings
    let windDirs: [String]
    let isLight: Bool

    var body: some View {
        let p = prediction
        let levelColor = Color(hex: isLight ? p.level.deepColorHex : p.level.colorHex)
        let levelText = p.level.rawValue < s.levels.count ? s.levels[p.level.rawValue] : ""
        let text = p.type.rawValue < s.hazards.count ? s.hazards[p.type.rawValue] : nil

        HStack(alignment: .top, spacing: 10) {
            RoundedRectangle(cornerRadius: 2, style: .continuous)
                .fill(levelColor)
                .frame(width: 3)

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(levelText)
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundStyle(levelColor)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(levelColor.opacity(0.14), in: RoundedRectangle(cornerRadius: 4, style: .continuous))
                    Text(text?.name ?? "")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    Spacer(minLength: 4)
                    Text(HazardI18n.renderWindow(p, s))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

                Text(HazardI18n.renderLocation(p, s, windDirs))
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(levelColor)

                Text(HazardI18n.renderDesc(p, s))
                    .font(.footnote)
                    .foregroundStyle(.primary.opacity(0.85))
                    .fixedSize(horizontal: false, vertical: true)

                let metricText = p.metrics.map { m -> String in
                    let label = m.labelIndex < s.metricLabels.count ? s.metricLabels[m.labelIndex] : ""
                    return label.isEmpty ? m.text : "\(label) \(m.text)"
                }.joined(separator: "   ")
                if !metricText.isEmpty {
                    Text("\(s.factorLabel)：\(metricText)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                if let chain = text?.chain, !chain.isEmpty {
                    Text("\(s.chainLabel)：\(chain)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }
}
