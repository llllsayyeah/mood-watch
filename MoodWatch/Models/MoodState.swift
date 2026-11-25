import SwiftUI

// MARK: - Mood vocabulary
// Rebuilt from the app's state-of-mind taxonomy: 5 valences, emotional + physical states,
// and a tag list describing what a feeling is attached to.

enum MoodValence: Int, Codable, CaseIterable, Identifiable {
    case veryNegative = -2
    case negative = -1
    case neutral = 0
    case positive = 1
    case veryPositive = 2

    var id: Int { rawValue }

    var color: Color {
        switch self {
        case .veryNegative: return Theme.overload
        case .negative: return Theme.warn
        case .neutral: return Theme.muted
        case .positive: return Theme.normal
        case .veryPositive: return Theme.great
        }
    }

    /// Coarse 5-dot face used on the Today card.
    var face: String {
        switch self {
        case .veryNegative: return "😣"
        case .negative: return "😕"
        case .neutral: return "😐"
        case .positive: return "🙂"
        case .veryPositive: return "😄"
        }
    }
}

struct MoodState: Identifiable, Hashable {
    enum Kind: String { case emotional, physical }

    let id: Int
    let name: String
    let valence: MoodValence
    let kind: Kind

    var emoji: String {
        switch name {
        case "惊喜": return "🤩"
        case "兴奋": return "🤗"
        case "感恩": return "🥹"
        case "愉悦": return "😊"
        case "满足": return "😌"
        case "希望": return "🌱"
        case "有趣": return "😄"
        case "心动": return "💓"
        case "松弛": return "🫧"
        case "平静": return "😐"
        case "惊讶": return "😲"
        case "无感": return "😑"
        case "压力": return "😖"
        case "不安": return "😟"
        case "害怕": return "😨"
        case "嫉妒": return "😒"
        case "羞愧": return "😳"
        case "无聊": return "🥱"
        case "悲伤": return "😢"
        case "绝望": return "😞"
        case "愤怒": return "😠"
        case "元气满满": return "⚡️"
        case "放松": return "🌿"
        case "充满力量": return "💪"
        case "健康": return "🍀"
        case "胃口很好": return "🍚"
        case "舒适": return "🛋️"
        case "正常": return "👌"
        case "还行": return "🙂"
        case "被掏空": return "🫠"
        case "太热": return "🥵"
        case "太冷": return "🥶"
        case "虚弱": return "🪫"
        case "疼痛": return "🤕"
        case "生病": return "🤒"
        default: return "🙂"
        }
    }
}

enum MoodCatalog {
    static let states: [MoodState] = [
        MoodState(id: 1, name: "惊喜", valence: .veryPositive, kind: .emotional),
        MoodState(id: 2, name: "兴奋", valence: .veryPositive, kind: .emotional),
        MoodState(id: 3, name: "感恩", valence: .veryPositive, kind: .emotional),
        MoodState(id: 4, name: "愉悦", valence: .positive, kind: .emotional),
        MoodState(id: 5, name: "满足", valence: .positive, kind: .emotional),
        MoodState(id: 6, name: "希望", valence: .positive, kind: .emotional),
        MoodState(id: 7, name: "有趣", valence: .positive, kind: .emotional),
        MoodState(id: 8, name: "心动", valence: .positive, kind: .emotional),
        MoodState(id: 9, name: "松弛", valence: .positive, kind: .emotional),
        MoodState(id: 10, name: "平静", valence: .neutral, kind: .emotional),
        MoodState(id: 11, name: "惊讶", valence: .neutral, kind: .emotional),
        MoodState(id: 12, name: "无感", valence: .neutral, kind: .emotional),
        MoodState(id: 13, name: "压力", valence: .negative, kind: .emotional),
        MoodState(id: 14, name: "不安", valence: .negative, kind: .emotional),
        MoodState(id: 15, name: "害怕", valence: .negative, kind: .emotional),
        MoodState(id: 16, name: "嫉妒", valence: .negative, kind: .emotional),
        MoodState(id: 17, name: "羞愧", valence: .negative, kind: .emotional),
        MoodState(id: 18, name: "无聊", valence: .negative, kind: .emotional),
        MoodState(id: 19, name: "悲伤", valence: .veryNegative, kind: .emotional),
        MoodState(id: 20, name: "绝望", valence: .veryNegative, kind: .emotional),
        MoodState(id: 21, name: "愤怒", valence: .veryNegative, kind: .emotional),
        MoodState(id: 22, name: "元气满满", valence: .veryPositive, kind: .physical),
        MoodState(id: 23, name: "放松", valence: .veryPositive, kind: .physical),
        MoodState(id: 24, name: "充满力量", valence: .veryPositive, kind: .physical),
        MoodState(id: 25, name: "健康", valence: .positive, kind: .physical),
        MoodState(id: 26, name: "胃口很好", valence: .positive, kind: .physical),
        MoodState(id: 27, name: "舒适", valence: .positive, kind: .physical),
        MoodState(id: 28, name: "正常", valence: .neutral, kind: .physical),
        MoodState(id: 29, name: "还行", valence: .neutral, kind: .physical),
        MoodState(id: 30, name: "被掏空", valence: .negative, kind: .physical),
        MoodState(id: 31, name: "太热", valence: .negative, kind: .physical),
        MoodState(id: 32, name: "太冷", valence: .negative, kind: .physical),
        MoodState(id: 33, name: "虚弱", valence: .veryNegative, kind: .physical),
        MoodState(id: 34, name: "疼痛", valence: .veryNegative, kind: .physical),
        MoodState(id: 35, name: "生病", valence: .veryNegative, kind: .physical),
    ]

    static let tags: [String] = [
        "🧑‍💻 工作", "🏋️ 运动", "🍽️ 食物", "🍷 酒精", "☕️ 咖啡因", "✈️ 旅行",
        "☀️ 天气", "🧘 冥想", "💰 金钱", "💑 约会", "🏠 家庭", "👫 朋友",
        "🏘️ 社群", "📰 时事", "🎓 教育", "🌿 健康", "🫶 爱好", "🛌 睡眠",
    ]

    static func state(named name: String) -> MoodState? {
        states.first { $0.name == name }
    }
}

struct MoodEntry: Identifiable, Codable, Equatable {
    var id = UUID()
    var date: Date
    var stateName: String
    var valenceRaw: Int
    var tags: [String]
    var note: String

    var valence: MoodValence { MoodValence(rawValue: valenceRaw) ?? .neutral }
    var state: MoodState? { MoodCatalog.state(named: stateName) }
    var emoji: String { state?.emoji ?? "🙂" }

    init(date: Date, stateName: String, valence: MoodValence, tags: [String], note: String) {
        self.date = date
        self.stateName = stateName
        self.valenceRaw = valence.rawValue
        self.tags = tags
        self.note = note
    }
}
