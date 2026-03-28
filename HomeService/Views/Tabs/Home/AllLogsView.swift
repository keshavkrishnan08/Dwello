import SwiftUI

/// Lightweight all-logs list pushed from the Home dashboard.
/// Unlike TimelineTabView, this does NOT wrap in its own NavigationStack.
struct AllLogsView: View {
    @Environment(AppStore.self) private var appStore
    @State private var selectedCategory: HomeCategory? = nil

    private var filtered: [LogEntry] {
        let base = selectedCategory == nil
            ? appStore.logs
            : appStore.logs.filter { $0.category == selectedCategory }
        return base.sorted { $0.date > $1.date }
    }

    var body: some View {
        ZStack {
            GradientBackground()

            VStack(spacing: 0) {
                CategoryChipBar(selected: $selectedCategory)
                    .padding(.vertical, HBSpacing.sm)

                ScrollView(showsIndicators: false) {
                    LazyVStack(spacing: HBSpacing.sm) {
                        ForEach(filtered) { entry in
                            NavigationLink {
                                LogDetailView(entry: entry)
                            } label: {
                                TimelineCard(entry: entry)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, HBSpacing.lg)
                    .padding(.bottom, HBSpacing.xxl)
                }
            }
        }
        .navigationTitle("All Activity")
        .navigationBarTitleDisplayMode(.large)
    }
}
