import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var store: Store
    @EnvironmentObject var appModel: AppModel
    @Environment(\.dismiss) private var dismiss

    @AppStorage("quickmath.theme") private var themeRaw = AppTheme.system.rawValue
    @State private var showPaywall = false
    @State private var showDeleteConfirm = false

    private var theme: AppTheme {
        get { AppTheme(rawValue: themeRaw) ?? .system }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                QMBackground()
                List {
                    // Pro section
                    Section("Onefocus Pro") {
                        if store.isPro {
                            HStack {
                                Image(systemName: "checkmark.seal.fill")
                                    .foregroundStyle(Color.qmAccent)
                                Text("Pro Active")
                                    .foregroundStyle(.primary)
                                Spacer()
                                Link("Manage", destination: URL(string: "https://apps.apple.com/account/subscriptions")!)
                                    .foregroundStyle(Color.qmAccent)
                                    .font(.subheadline)
                            }
                        } else {
                            Button {
                                showPaywall = true
                            } label: {
                                HStack {
                                    Image(systemName: "star.fill")
                                        .foregroundStyle(Color.qmAccent)
                                    Text("Upgrade to Pro")
                                        .foregroundStyle(Color.qmAccent)
                                    Spacer()
                                    Text(store.displayPrice + "/mo")
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            Button {
                                Task { await store.restore() }
                            } label: {
                                HStack {
                                    Image(systemName: "arrow.clockwise")
                                        .foregroundStyle(.secondary)
                                    Text("Restore Purchase")
                                        .foregroundStyle(.primary)
                                }
                            }
                        }

                        Link(destination: URL(string: "https://apps.apple.com/account/subscriptions")!) {
                            HStack {
                                Image(systemName: "creditcard")
                                    .foregroundStyle(.secondary)
                                Text("Manage Subscription")
                                    .foregroundStyle(.primary)
                            }
                        }
                    }

                    // Appearance
                    Section("Appearance") {
                        Picker("Theme", selection: $themeRaw) {
                            ForEach(AppTheme.allCases) { t in
                                Text(t.label).tag(t.rawValue)
                            }
                        }
                        .pickerStyle(.segmented)
                    }

                    // Legal
                    Section("Legal") {
                        Link(destination: URL(string: "https://shimondeitel.github.io/onefocus-site/privacy.html")!) {
                            Label("Privacy Policy", systemImage: "hand.raised")
                        }
                        .foregroundStyle(.primary)
                        Link(destination: URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!) {
                            Label("Terms of Use", systemImage: "doc.text")
                        }
                        .foregroundStyle(.primary)
                    }

                    // Data
                    Section("Data") {
                        Button(role: .destructive) {
                            showDeleteConfirm = true
                        } label: {
                            Label("Delete All Data", systemImage: "trash")
                        }
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(Color.qmAccent)
                }
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView()
                    .environmentObject(store)
            }
            .confirmationDialog(
                "Delete all data?",
                isPresented: $showDeleteConfirm,
                titleVisibility: .visible
            ) {
                Button("Delete Everything", role: .destructive) {
                    appModel.deleteAllData()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This removes all focuses, streaks, and history. This action cannot be undone.")
            }
        }
    }
}
