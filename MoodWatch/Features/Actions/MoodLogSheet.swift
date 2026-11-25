import SwiftUI

struct MoodLogSheet: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.dismiss) private var dismiss

    @State private var valence: MoodValence = .neutral
    @State private var kind: MoodState.Kind = .emotional
    @State private var selectedState: MoodState = MoodCatalog.states.first { $0.name == "平静" }!
    @State private var selectedTags: Set<String> = []
    @State private var note: String = ""
    @FocusState private var noteFocused: Bool

    private var faces: [MoodValence] { [.veryPositive, .positive, .neutral, .negative, .veryNegative] }

    private var visibleStates: [MoodState] {
        MoodCatalog.states.filter { $0.kind == kind }
    }

    private var tagColumns: [GridItem] {
        [GridItem(.adaptive(minimum: 86), spacing: 8)]
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                header

                Text("你此刻的感受如何？")
                    .font(.cardTitle)
                    .foregroundStyle(Theme.ink)

                HStack(spacing: 8) {
                    ForEach(faces) { face in
                        Button {
                            valence = face
                            if let match = visibleStates.first(where: { $0.valence == face }) {
                                selectedState = match
                            }
                        } label: {
                            Text(face.face)
                                .font(.system(size: 28))
                                .frame(maxWidth: .infinity)
                                .frame(height: 58)
                                .background(
                                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                                        .fill(valence == face ? face.color.opacity(0.18) : Theme.surfaceAlt)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                                        .stroke(valence == face ? face.color : .clear, lineWidth: 2)
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }

                Picker("类型", selection: $kind) {
                    Text("情绪").tag(MoodState.Kind.emotional)
                    Text("身体").tag(MoodState.Kind.physical)
                }
                .pickerStyle(.segmented)

                LazyVGrid(columns: [GridItem(.adaptive(minimum: 84), spacing: 8)], spacing: 8) {
                    ForEach(visibleStates) { state in
                        Button {
                            selectedState = state
                            valence = state.valence
                        } label: {
                            Text(state.name)
                                .font(.system(size: 13, weight: selectedState == state ? .bold : .medium, design: .rounded))
                                .foregroundStyle(selectedState == state ? .white : Theme.ink)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .fill(selectedState == state ? state.valence.color : Theme.surfaceAlt)
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }

                VStack(alignment: .leading, spacing: 10) {
                    Text("影响因素")
                        .font(.cardTitle)
                        .foregroundStyle(Theme.ink)
                    LazyVGrid(columns: tagColumns, spacing: 8) {
                        ForEach(MoodCatalog.tags, id: \.self) { tag in
                            Button {
                                if selectedTags.contains(tag) {
                                    selectedTags.remove(tag)
                                } else {
                                    selectedTags.insert(tag)
                                }
                            } label: {
                                Text(tag)
                                    .font(.tagText)
                                    .foregroundStyle(selectedTags.contains(tag) ? .white : Theme.inkSecondary)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 8)
                                    .background(
                                        Capsule().fill(selectedTags.contains(tag) ? Theme.mint : Theme.surfaceAlt)
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("补一句")
                        .font(.cardTitle)
                        .foregroundStyle(Theme.ink)
                    TextField("与你状态感受相关的事物……", text: $note, axis: .vertical)
                        .focused($noteFocused)
                        .font(.bodyText)
                        .lineLimit(3...5)
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(Theme.surfaceAlt)
                        )
                }

                Button {
                    store.addMood(
                        MoodEntry(
                            date: Date(),
                            stateName: selectedState.name,
                            valence: valence,
                            tags: Array(selectedTags),
                            note: note.trimmingCharacters(in: .whitespacesAndNewlines)
                        )
                    )
                    dismiss()
                } label: {
                    Text("保存记录")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 15)
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(Theme.mint)
                        )
                }
                .buttonStyle(.plain)
                .padding(.top, 4)
            }
            .padding(.horizontal, Theme.pagePadding)
            .padding(.top, 22)
            .padding(.bottom, 30)
        }
        .background(Theme.bg.ignoresSafeArea())
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }

    private var header: some View {
        HStack {
            Button("取消") { dismiss() }
                .font(.captionText)
                .foregroundStyle(Theme.inkTertiary)
            Spacer()
            Text("记录感受")
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundStyle(Theme.ink)
            Spacer()
            Text(Fmt.hourMinute.string(from: Date()))
                .font(.captionText)
                .monospacedDigit()
                .foregroundStyle(Theme.inkTertiary)
        }
    }
}
