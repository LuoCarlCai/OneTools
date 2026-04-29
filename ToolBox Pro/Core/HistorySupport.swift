import Foundation
import SwiftUI

struct TaggedHistoryRecord: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var text: String
    var tag: String = ""
    var createdAt: Date = Date()
}

enum HistoryTagRules {
    static let maxLength = 16
}

enum HistoryStorage {
    static func loadRecords(from rawValue: String) -> [TaggedHistoryRecord] {
        guard !rawValue.isEmpty else { return [] }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        if let data = rawValue.data(using: .utf8),
           let decoded = try? decoder.decode([TaggedHistoryRecord].self, from: data) {
            return decoded
        }

        return rawValue
            .split(separator: "\n")
            .map(String.init)
            .filter { !$0.isEmpty }
            .map { TaggedHistoryRecord(text: $0) }
    }

    static func saveRecords(_ records: [TaggedHistoryRecord]) -> String {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        guard let data = try? encoder.encode(records),
              let string = String(data: data, encoding: .utf8) else {
            return ""
        }
        return string
    }
}

enum RecentToolStorage {
    static func loadToolIDs(from rawValue: String) -> [String] {
        guard !rawValue.isEmpty else { return [] }
        guard let data = rawValue.data(using: .utf8),
              let decoded = try? JSONDecoder().decode([String].self, from: data) else {
            return rawValue
                .split(separator: ",")
                .map(String.init)
                .filter { !$0.isEmpty }
        }
        return decoded
    }

    static func saveToolIDs(_ ids: [String]) -> String {
        guard let data = try? JSONEncoder().encode(ids),
              let string = String(data: data, encoding: .utf8) else {
            return ""
        }
        return string
    }

    static func register(_ id: String, in rawValue: String, limit: Int = 6) -> String {
        var ids = loadToolIDs(from: rawValue)
        ids.removeAll { $0 == id }
        ids.insert(id, at: 0)
        return saveToolIDs(Array(ids.prefix(limit)))
    }
}

struct TaggedHistoryRow: View {
    @Binding var record: TaggedHistoryRecord
    let tint: Color
    var onDelete: (() -> Void)? = nil
    @State private var isEditorPresented = false
    @State private var draftTag = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(record.text)
                        .appFont(size: 15, weight: .medium)
                        .foregroundColor(AppColor.primaryText)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    if !record.tag.isEmpty {
                        Text(record.tag)
                            .appFont(size: 12, weight: .bold)
                            .foregroundColor(tint)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(tint.opacity(0.14))
                            .clipShape(Capsule())
                    }
                }

                Menu {
                    Button(AppLocalizer.string("Add tag")) {
                        AppFeedback.selection()
                        draftTag = record.tag
                        isEditorPresented = true
                    }

                    if let onDelete {
                        Button(role: .destructive) {
                            AppFeedback.warning()
                            onDelete()
                        } label: {
                            Text(AppLocalizer.string("Delete"))
                        }
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(AppColor.secondaryText)
                        .frame(width: 32, height: 32)
                        .background(AppColor.background)
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(16)
        .background(AppColor.surface)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(AppColor.border, lineWidth: 1)
        )
        .sheet(isPresented: $isEditorPresented) {
            VStack(alignment: .leading, spacing: 18) {
                HStack {
                    Button(AppLocalizer.string("Cancel")) {
                        AppFeedback.selection()
                        isEditorPresented = false
                    }
                    .foregroundColor(AppColor.secondaryText)

                    Spacer()

                    Button(AppLocalizer.string("Done")) {
                        AppFeedback.success()
                        record.tag = draftTag.trimmingCharacters(in: .whitespacesAndNewlines)
                        isEditorPresented = false
                    }
                    .foregroundColor(tint)
                }

                Text(AppLocalizer.string("Add tag"))
                    .appFont(size: 22, weight: .bold)
                    .foregroundColor(AppColor.primaryText)

                TextField(AppLocalizer.string("Type a tag"), text: $draftTag)
                    .padding(14)
                    .background(AppColor.background)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(AppColor.border, lineWidth: 1)
                    )

                VStack(alignment: .leading, spacing: 10) {
                    Text(AppLocalizer.string("Suggested tags"))
                        .appFont(size: 14, weight: .bold)
                        .foregroundColor(AppColor.secondaryText)

                    FlowTagWrap(tags: [
                        AppLocalizer.string("Work"),
                        AppLocalizer.string("Study"),
                        AppLocalizer.string("Personal")
                    ], tint: tint) { selected in
                        AppFeedback.selection()
                        draftTag = selected
                    }
                }

                Spacer()
            }
            .padding(20)
            .background(AppColor.background.ignoresSafeArea())
        }
        .onAppear {
            draftTag = record.tag
        }
        .onChange(of: draftTag) { value in
            if value.count > HistoryTagRules.maxLength {
                draftTag = String(value.prefix(HistoryTagRules.maxLength))
            }
        }
    }
}

private struct FlowTagWrap: View {
    let tags: [String]
    let tint: Color
    let onSelect: (String) -> Void

    var body: some View {
        HStack(spacing: 8) {
            ForEach(tags, id: \.self) { tag in
                Button(tag) {
                    onSelect(tag)
                }
                .appFont(size: 12, weight: .bold)
                .foregroundColor(tint)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(tint.opacity(0.14))
                .clipShape(Capsule())
            }
            Spacer(minLength: 0)
        }
    }
}
