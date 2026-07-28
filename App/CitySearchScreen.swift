import SwiftUI

/// 城市设置页面：搜索添加 + 已添加城市拖动排序 + 删除（对应 Android CitySearchScreen）
struct CitySearchScreen: View {
    @EnvironmentObject var viewModel: WeatherViewModel

    @State private var searchQuery = ""
    @State private var searchTask: Task<Void, Never>?

    var body: some View {
        let strings = viewModel.strings
        let language = viewModel.settings.language

        VStack(spacing: 0) {
            // 搜索框
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                TextField(strings.searchCityHint, text: $searchQuery)
                    .textFieldStyle(.plain)
                    .autocorrectionDisabled()
                if !searchQuery.isEmpty {
                    Button {
                        searchQuery = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                    .accessibilityLabel(strings.close)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 11)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .padding(.horizontal, 16)
            .padding(.vertical, 8)

            if viewModel.isSearching {
                ProgressView()
                    .progressViewStyle(.linear)
                    .padding(.horizontal, 16)
            }

            if !viewModel.searchResults.isEmpty {
                // 搜索结果列表
                Text(strings.searchResults)
                    .font(.subheadline)
                    .foregroundStyle(.tint)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                List(viewModel.searchResults) { result in
                    SearchResultRow(
                        result: result,
                        isAlreadyAdded: viewModel.isCityAdded(result),
                        alreadyAddedLabel: strings.alreadyAdded,
                        onAdd: { viewModel.addCity(result) }
                    )
                }
                .listStyle(.plain)
            } else if !searchQuery.isEmpty && !viewModel.isSearching {
                // 无结果空态
                Spacer()
                VStack(spacing: 8) {
                    Image(systemName: "magnifyingglass.circle")
                        .font(.system(size: 44))
                        .foregroundStyle(.quaternary)
                    Text(strings.noSearchResults)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            } else if !viewModel.cities.isEmpty {
                // 已添加城市（拖动排序 + 左滑删除）
                HStack(spacing: 8) {
                    Text(strings.addedCities)
                        .font(.subheadline)
                        .foregroundStyle(.tint)
                    Text(strings.dragHint)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)

                List {
                    ForEach(viewModel.cities) { city in
                        AddedCityRow(
                            city: city,
                            language: language,
                            deleteLabel: strings.delete,
                            onRemove: { viewModel.removeCity(city.id) }
                        )
                    }
                    .onMove { indices, newOffset in
                        var newOrder = viewModel.cities
                        newOrder.move(fromOffsets: indices, toOffset: newOffset)
                        viewModel.reorderCities(newOrder)
                    }
                    .onDelete { indices in
                        for index in indices {
                            viewModel.removeCity(viewModel.cities[index].id)
                        }
                    }
                }
                .listStyle(.plain)
                .environment(\.editMode, .constant(.active)) // 常显拖动手柄，长按/拖动即可排序
            } else {
                Spacer()
                Text(strings.noCities)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer()
            }
        }
        .navigationTitle(strings.citySettings)
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: searchQuery) { _, query in
            // 300ms 防抖搜索
            searchTask?.cancel()
            searchTask = Task {
                try? await Task.sleep(nanoseconds: 300_000_000)
                guard !Task.isCancelled else { return }
                await viewModel.searchCities(query)
            }
        }
    }
}

/// 搜索结果行
private struct SearchResultRow: View {
    let result: GeocodingResult
    let isAlreadyAdded: Bool
    let alreadyAddedLabel: String
    let onAdd: () -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(result.name)
                    .font(.body)
                let parts = [result.admin1, result.country].compactMap { $0 }
                if !parts.isEmpty {
                    Text(parts.joined(separator: " · "))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            if isAlreadyAdded {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.tint)
                    .opacity(0.5)
                    .accessibilityLabel(alreadyAddedLabel)
            } else {
                Button(action: onAdd) {
                    Image(systemName: "plus.circle")
                        .font(.system(size: 20))
                        .foregroundStyle(.tint)
                }
                .buttonStyle(.plain)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            if !isAlreadyAdded { onAdd() }
        }
    }
}

/// 已添加城市行（拖动手柄由 List 编辑模式提供）
private struct AddedCityRow: View {
    let city: CityInfo
    let language: AppLanguage
    let deleteLabel: String
    let onRemove: () -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(city.nameFor(language))
                    .font(.body)
                Text(city.displayNameFor(language))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Button(action: onRemove) {
                Image(systemName: "trash")
                    .foregroundStyle(.red)
                    .opacity(0.7)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(deleteLabel)
        }
    }
}
