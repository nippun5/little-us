import WidgetKit
import SwiftUI

struct FridgeEntry: TimelineEntry {
    let date: Date
    let enabled: Bool
    let body: String
    let author: String
    let updatedAt: Date?
    let demo: Bool
}
struct FridgeProvider: TimelineProvider {
    func placeholder(in context: Context) -> FridgeEntry {
        FridgeEntry(date: Date(), enabled: true, body: "Saving you the window seat.", author: "Your person", updatedAt: nil, demo: false)
    }
    private func read() -> FridgeEntry {
        let group = Bundle.main.object(forInfoDictionaryKey: "LittleUsAppGroup") as? String ?? ""
        let data = UserDefaults(suiteName: group)?.dictionary(forKey: "fridge_snapshot") ?? [:]
        let milliseconds = (data["updatedAt"] as? NSNumber)?.doubleValue ?? 0
        return FridgeEntry(date: Date(), enabled: data["enabled"] as? Bool ?? false,
            body: data["body"] as? String ?? "", author: data["author"] as? String ?? "Little us",
            updatedAt: milliseconds > 0 ? Date(timeIntervalSince1970: milliseconds / 1000) : nil,
            demo: data["demo"] as? Bool ?? false)
    }
    func getSnapshot(in context: Context, completion: @escaping (FridgeEntry) -> Void) { completion(context.isPreview ? placeholder(in: context) : read()) }
    func getTimeline(in context: Context, completion: @escaping (Timeline<FridgeEntry>) -> Void) {
        completion(Timeline(entries: [read()], policy: .never))
    }
}
struct FridgeView: View {
    let entry: FridgeEntry
    @Environment(\.widgetFamily) var family
    private let paper = Color(red: 1, green: 0.94, blue: 0.74)
    private var content: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack { Text(entry.demo ? "LITTLE US · DEMO" : "LITTLE US").font(.caption2.bold()); Spacer(); Image(systemName: "heart.fill") }
                .foregroundColor(Color(red: 0.65, green: 0.29, blue: 0.36))
            Text(entry.enabled ? "A NOTE FROM \(entry.author.uppercased())" : "YOUR LITTLE FRIDGE")
                .font(.system(size: 10, weight: .medium)).lineLimit(1)
            Text(entry.enabled ? entry.body : "Open Little us → Notes to choose a note.")
                .font(.system(size: family == .systemSmall ? 16 : 20, design: .serif))
                .lineLimit(family == .systemSmall ? 4 : 5)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            if entry.enabled, let synced = entry.updatedAt {
                Text("Synced \(synced.formatted(date: .abbreviated, time: .shortened))")
                    .font(.system(size: 9)).lineLimit(1)
            } else { Text("Note sharing is off").font(.system(size: 10)) }
        }
        .foregroundColor(Color(red: 0.27, green: 0.22, blue: 0.28))
        .privacySensitive()
    }
    @ViewBuilder var body: some View {
        if #available(iOSApplicationExtension 17.0, *) {
            content.containerBackground(paper, for: .widget)
        } else { content.padding().background(paper) }
    }
}
// @main
struct LittleUsFridgeWidget: Widget {
    let kind = "LittleUsFridgeWidget"
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: FridgeProvider()) { entry in FridgeView(entry: entry) }
            .configurationDisplayName("Our fridge note")
            .description("A little note from your favorite person. Refreshes when Little us syncs.")
            .supportedFamilies([.systemSmall, .systemMedium])
    }
}
