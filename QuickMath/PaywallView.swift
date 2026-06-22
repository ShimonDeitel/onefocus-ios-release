import SwiftUI

struct PaywallView: View {
    @EnvironmentObject var store: Store
    @Environment(\.dismiss) private var dismiss

    private let benefits: [(icon: String, text: String)] = [
        ("clock.arrow.trianglehead.counterclockwise.rotate.90", "Full history of every focus you've completed with insights"),
        ("text.quote", "Add your reason and reflection note to each day's focus"),
        ("bell.badge", "Morning set-your-focus and unfinished-focus reminders")
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                QMBackground()
                ScrollView {
                    VStack(spacing: 28) {
                        Spacer(minLength: 16)

                        // Icon + title
                        VStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .strokeBorder(Color.qmAccent, lineWidth: 2)
                                    .frame(width: 72, height: 72)
                                Circle()
                                    .fill(Color.qmAccent)
                                    .frame(width: 20, height: 20)
                            }

                            Text("Onefocus Pro")
                                .font(.title2.weight(.bold))
                                .foregroundStyle(.primary)

                            Text("\(store.displayPrice) / month. Auto-renews until you cancel.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.horizontal, 24)

                        // Benefits
                        VStack(spacing: 12) {
                            ForEach(benefits, id: \.text) { benefit in
                                HStack(alignment: .top, spacing: 14) {
                                    Image(systemName: benefit.icon)
                                        .font(.body)
                                        .foregroundStyle(Color.qmAccent)
                                        .frame(width: 22)
                                    Text(benefit.text)
                                        .font(.subheadline)
                                        .foregroundStyle(.primary)
                                        .fixedSize(horizontal: false, vertical: true)
                                    Spacer()
                                }
                                .padding(.horizontal, 20)
                            }
                        }

                        // Buttons
                        VStack(spacing: 12) {
                            Button {
                                Task { await store.purchase() }
                            } label: {
                                Group {
                                    if store.purchaseInFlight {
                                        ProgressView()
                                            .tint(.white)
                                    } else {
                                        Text("Start for \(store.displayPrice)/month")
                                    }
                                }
                                .frame(maxWidth: .infinity)
                            }
                            .prominentButton()
                            .disabled(store.purchaseInFlight)
                            .padding(.horizontal, 20)

                            Button {
                                Task { await store.restore() }
                            } label: {
                                Text("Restore purchase")
                                    .font(.subheadline)
                                    .foregroundStyle(Color.qmAccent)
                            }
                        }

                        // Disclosure
                        VStack(spacing: 8) {
                            Text("Subscription renews automatically at \(store.displayPrice)/month unless cancelled at least 24 hours before the end of the current period. Manage or cancel anytime in your Apple Account settings.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 24)

                            HStack(spacing: 16) {
                                Link("Terms of Use", destination: URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!)
                                    .font(.caption)
                                    .foregroundStyle(Color.qmAccent)
                                Link("Privacy Policy", destination: URL(string: "https://shimondeitel.github.io/onefocus-site/privacy.html")!)
                                    .font(.caption)
                                    .foregroundStyle(Color.qmAccent)
                            }
                        }

                        Spacer(minLength: 20)
                    }
                }
            }
            .navigationTitle("Go Pro")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") { dismiss() }
                        .foregroundStyle(Color.qmAccent)
                }
            }
            .onChange(of: store.isPro) { _, newValue in
                if newValue { dismiss() }
            }
        }
    }
}
