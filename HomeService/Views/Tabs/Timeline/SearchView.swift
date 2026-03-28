import SwiftUI

struct SearchView: View {
    @Environment(AppStore.self) private var appStore
    @State private var searchText = ""
    @State private var selectedCategory: HomeCategory? = nil
    @State private var startDate: Date = Calendar.current.date(byAdding: .year, value: -1, to: Date()) ?? Date()
    @State private var endDate: Date = Date()
    @State private var showFilters = false

    private var results: [LogEntry] {
        guard !searchText.isEmpty || selectedCategory != nil else { return [] }
        var logs = appStore.logs

        if !searchText.isEmpty {
            logs = logs.filter {
                $0.title.localizedCaseInsensitiveContains(searchText) ||
                ($0.notes?.localizedCaseInsensitiveContains(searchText) ?? false)
            }
        }

        if let cat = selectedCategory {
            logs = logs.filter { $0.category == cat }
        }

        logs = logs.filter { $0.date >= startDate && $0.date <= endDate }

        return logs.sorted { $0.date > $1.date }
    }

    var body: some View {
        ZStack {
            GradientBackground()

            VStack(spacing: 0) {
                // Search bar
                HStack(spacing: HBSpacing.sm) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.hbTextSecondary)
                    TextField("Search all logs...", text: $searchText)
                        .font(HBTypography.body)
                    if !searchText.isEmpty {
                        Button(action: { searchText = "" }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.hbTextSecondary)
                        }
                    }
                    Button(action: { withAnimation { showFilters.toggle() } }) {
                        Image(systemName: "line.3.horizontal.decrease.circle\(showFilters ? ".fill" : "")")
                            .foregroundColor(.hbPrimary)
                    }
                }
                .padding(HBSpacing.sm + 4)
                .background(Color.hbSurface)
                .cornerRadius(HBRadii.input)
                .padding(.horizontal, HBSpacing.lg)
                .padding(.top, HBSpacing.sm)

                // Filters
                if showFilters {
                    VStack(spacing: HBSpacing.sm) {
                        CategoryChipBar(selected: $selectedCategory)

                        HStack(spacing: HBSpacing.md) {
                            VStack(alignment: .leading) {
                                Text("From")
                                    .font(HBTypography.caption)
                                    .foregroundColor(.hbTextSecondary)
                                DatePicker("", selection: $startDate, displayedComponents: .date)
                                    .labelsHidden()
                                    .tint(.hbPrimary)
                            }
                            VStack(alignment: .leading) {
                                Text("To")
                                    .font(HBTypography.caption)
                                    .foregroundColor(.hbTextSecondary)
                                DatePicker("", selection: $endDate, displayedComponents: .date)
                                    .labelsHidden()
                                    .tint(.hbPrimary)
                            }
                        }
                        .padding(.horizontal, HBSpacing.lg)
                    }
                    .padding(.vertical, HBSpacing.sm)
                    .transition(.move(edge: .top).combined(with: .opacity))
                }

                // Results
                if results.isEmpty && !searchText.isEmpty {
                    Spacer()
                    EmptyStateView(
                        icon: "magnifyingglass",
                        title: "No results",
                        subtitle: "Try different keywords or filters"
                    )
                    Spacer()
                } else if results.isEmpty {
                    Spacer()
                    VStack(spacing: HBSpacing.md) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 40))
                            .foregroundColor(.hbBorder)
                        Text("Search your maintenance history")
                            .font(HBTypography.body)
                            .foregroundColor(.hbTextSecondary)
                    }
                    Spacer()
                } else {
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: HBSpacing.sm) {
                            Text("\(results.count) result\(results.count == 1 ? "" : "s")")
                                .font(HBTypography.caption)
                                .foregroundColor(.hbTextSecondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, HBSpacing.xs)

                            ForEach(results) { entry in
                                NavigationLink {
                                    LogDetailView(entry: entry)
                                } label: {
                                    TimelineCard(entry: entry)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, HBSpacing.lg)
                        .padding(.bottom, 100)
                    }
                }
            }
        }
        .navigationTitle("Search")
    }
}
