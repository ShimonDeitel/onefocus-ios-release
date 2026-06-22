import SwiftUI

struct GridView: View {
    @EnvironmentObject var appModel: AppModel
    @EnvironmentObject var store: Store

    @State private var inputTitle: String = ""
    @State private var inputWhy: String = ""
    @State private var isEditing: Bool = false
    @State private var showWhyField: Bool = false
    @FocusState private var titleFocused: Bool
    @FocusState private var whyFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            if let thing = appModel.todayThing {
                existingThingView(thing)
            } else {
                setThingView
            }
        }
        .padding(.horizontal, 20)
    }

    // MARK: - Already set a thing today

    private func existingThingView(_ thing: OneThing) -> some View {
        VStack(spacing: 20) {
            Text("Today's one thing")
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)

            VStack(alignment: .leading, spacing: 12) {
                Text(thing.title)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .fixedSize(horizontal: false, vertical: true)

                if !thing.why.isEmpty && store.isPro {
                    Text(thing.why)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .fixedSize(horizontal: false, vertical: true)
                }

                if thing.done, let doneAt = thing.doneAt {
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(Color.qmCorrect)
                        Text("Done at \(doneAt, format: .dateTime.hour().minute())")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .qmCard()

            if !thing.done {
                Button {
                    appModel.markDone()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark")
                        Text("Mark Done")
                    }
                    .frame(maxWidth: .infinity)
                }
                .prominentButton()

                Button {
                    inputTitle = thing.title
                    inputWhy = thing.why
                    isEditing = true
                } label: {
                    Text("Change focus")
                        .frame(maxWidth: .infinity)
                }
                .softButton()
            } else {
                VStack(spacing: 12) {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(Color.qmCorrect)
                            .font(.title3)
                        Text("Focus complete.")
                            .font(.headline)
                            .foregroundStyle(.primary)
                    }
                    Text("Tomorrow's focus starts fresh.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .qmCard()
            }

            if isEditing {
                editingView
            }
        }
    }

    // MARK: - No thing set yet

    private var setThingView: some View {
        VStack(spacing: 20) {
            VStack(alignment: .leading, spacing: 6) {
                Text("What's your one thing today?")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.primary)
                Text("One task. Fully done before anything else.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            VStack(spacing: 12) {
                TextField("My one thing is…", text: $inputTitle, axis: .vertical)
                    .font(.body)
                    .lineLimit(3, reservesSpace: false)
                    .padding(14)
                    .background(Color.qmField, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .focused($titleFocused)

                if store.isPro {
                    if showWhyField {
                        TextField("Why does this matter? (optional)", text: $inputWhy, axis: .vertical)
                            .font(.body)
                            .lineLimit(3, reservesSpace: false)
                            .padding(14)
                            .background(Color.qmField, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                            .focused($whyFocused)
                    } else {
                        Button {
                            showWhyField = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                whyFocused = true
                            }
                        } label: {
                            Text("+ Add why (optional)")
                                .font(.subheadline)
                                .foregroundStyle(Color.qmAccent)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }

            Button {
                let trimmed = inputTitle.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !trimmed.isEmpty else { return }
                appModel.setTodayThing(title: trimmed, why: inputWhy.trimmingCharacters(in: .whitespacesAndNewlines))
                inputTitle = ""
                inputWhy = ""
                showWhyField = false
                titleFocused = false
            } label: {
                Text("Set My Focus")
                    .frame(maxWidth: .infinity)
            }
            .prominentButton()
            .disabled(inputTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            .opacity(inputTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.5 : 1)
        }
    }

    // MARK: - Editing overlay

    private var editingView: some View {
        VStack(spacing: 12) {
            Divider()
            Text("Change your focus")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.secondary)

            TextField("New focus…", text: $inputTitle, axis: .vertical)
                .font(.body)
                .lineLimit(3, reservesSpace: false)
                .padding(14)
                .background(Color.qmField, in: RoundedRectangle(cornerRadius: 14, style: .continuous))

            if store.isPro {
                TextField("Why? (optional)", text: $inputWhy, axis: .vertical)
                    .font(.body)
                    .lineLimit(2, reservesSpace: false)
                    .padding(14)
                    .background(Color.qmField, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            }

            HStack(spacing: 12) {
                Button {
                    isEditing = false
                    inputTitle = ""
                    inputWhy = ""
                } label: {
                    Text("Cancel")
                        .frame(maxWidth: .infinity)
                }
                .softButton()

                Button {
                    let trimmed = inputTitle.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !trimmed.isEmpty else { return }
                    appModel.setTodayThing(title: trimmed, why: inputWhy.trimmingCharacters(in: .whitespacesAndNewlines))
                    inputTitle = ""
                    inputWhy = ""
                    isEditing = false
                } label: {
                    Text("Update")
                        .frame(maxWidth: .infinity)
                }
                .prominentButton()
                .disabled(inputTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
    }
}
