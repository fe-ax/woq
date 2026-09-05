import SwiftUI

/// Main screen skeleton (M1): paper background, custom header, search field and the empty state.
/// No NavigationStack and no system toolbar, so Liquid Glass never appears (PLAN.md pitfall 7).
struct MainScreen: View {
    @State private var searchText = ""
    @State private var showAddSheet = false

    var body: some View {
        ZStack {
            Tokens.paper
                .ignoresSafeArea()

            VStack(spacing: 0) {
                header
                    .padding(.horizontal, 16)
                    .padding(.top, 4)
                    .padding(.bottom, 12)

                SearchField(text: $searchText)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 12)

                ScrollView {
                    emptyState
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, 16)
                        .padding(.top, 120)
                        .padding(.bottom, 24)
                }
                .scrollDismissesKeyboard(.interactively)
                .scrollEdgeEffectStyle(.hard, for: .top)
            }
        }
        .sheet(isPresented: $showAddSheet) {
            addPlaceholderSheet
        }
    }

    private var header: some View {
        HStack(alignment: .center, spacing: 12) {
            Text(String(localized: "Workout Queue"))
                .font(Tokens.titleFont)
                .foregroundStyle(Tokens.ink)
                .accessibilityAddTraits(.isHeader)

            Spacer(minLength: 8)

            PunchedPlusButton {
                showAddSheet = true
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 6) {
            Text(String(localized: "No exercises yet"))
                .font(.title3)
                .foregroundStyle(Tokens.ink)
            Text(String(localized: "Tap + to add your first exercise"))
                .font(.subheadline)
                .foregroundStyle(Tokens.muted)
        }
        .multilineTextAlignment(.center)
    }

    private var addPlaceholderSheet: some View {
        ZStack {
            Tokens.paper
                .ignoresSafeArea()

            VStack(spacing: 20) {
                Text(String(localized: "Coming soon"))
                    .font(.title3)
                    .foregroundStyle(Tokens.ink)

                Button {
                    showAddSheet = false
                } label: {
                    Text(String(localized: "Close"))
                        .font(.body)
                        .foregroundStyle(Tokens.ink)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .overlay(
                            RoundedRectangle(cornerRadius: Tokens.radius, style: .continuous)
                                .strokeBorder(Tokens.ink, lineWidth: Tokens.line)
                        )
                }
                .buttonStyle(.plain)
            }
        }
    }
}

#Preview {
    MainScreen()
        .preferredColorScheme(.light)
}
