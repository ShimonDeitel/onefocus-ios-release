import SwiftUI

struct HomeView: View {
    var forceScreen: String? = nil

    @EnvironmentObject var appModel: AppModel
    @EnvironmentObject var store: Store

    @State private var showSettings = false
    @State private var showPaywall = false
    @State private var showInsights = false

    var body: some View {
        NavigationStack {
            ZStack {
                QMBackground()
                VStack(spacing: 24) {
                    // Streak bar
                    HStack(spacing: 16) {
                        MetricTile(
                            value: "\(appModel.currentStreak)",
                            label: "streak"
                        )
                        MetricTile(
                            value: "\(appModel.bestStreak)",
                            label: "best"
                        )
                        Button {
                            if store.isPro {
                                showInsights = true
                            } else {
                                showPaywall = true
                            }
                        } label: {
                            VStack(spacing: 4) {
                                Text(store.isPro ? "\(appModel.completedThings.count)" : "PRO")
                                    .font(.title2.weight(.bold))
                                    .foregroundStyle(store.isPro ? .primary : Color.qmAccent)
                                    .lineLimit(1).minimumScaleFactor(0.6)
                                Text("history")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.qmCard, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 20)

                    Spacer()
                    GridView()
                    Spacer()
                }
            }
            .navigationTitle("Onefocus")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                            .foregroundStyle(Color.qmAccent)
                    }
                }
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
                    .environmentObject(store)
                    .environmentObject(appModel)
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView()
                    .environmentObject(store)
            }
            .sheet(isPresented: $showInsights) {
                InsightsView()
                    .environmentObject(appModel)
                    .environmentObject(store)
            }
            .onAppear {
                handleForceScreen()
            }
        }
    }

    private func handleForceScreen() {
        guard let screen = forceScreen else { return }
        switch screen {
        case "paywall": showPaywall = true
        case "insights": showInsights = true
        case "settings": showSettings = true
        default: break
        }
    }
}
