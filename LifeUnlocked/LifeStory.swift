import SwiftUI

struct LifeChapter: Identifiable {
    let year: Int
    let entries: [LifeEntry]
    let leadingModule: LifeModule
    var id: Int { year }
    var moduleCount: Int { Set(entries.map { $0.kind.module }).count }
}

struct PersonalRecord: Identifiable {
    let id: String
    let title: String
    let value: String
    let date: Date
    let symbol: String
}

enum LifeStoryEngine {
    static func chapters(_ entries: [LifeEntry]) -> [LifeChapter] {
        Dictionary(grouping: entries) { Calendar.current.component(.year, from: $0.date) }
            .map { year, records in
                let ordered = records.sorted { $0.date < $1.date }
                let counts = Dictionary(grouping: records, by: { $0.kind.module }).mapValues(\.count)
                let leading = LifeModule.allCases.max {
                    let left = counts[$0] ?? 0
                    let right = counts[$1] ?? 0
                    return left == right ? LifeModule.allCases.firstIndex(of: $0)! > LifeModule.allCases.firstIndex(of: $1)! : left < right
                } ?? .exercise
                return LifeChapter(year: year, entries: ordered, leadingModule: leading)
            }
            .sorted { $0.year > $1.year }
    }

    static func timeEcho(_ entries: [LifeEntry], on today: Date = Date()) -> LifeEntry? {
        let calendar = Calendar.current
        let current = calendar.dateComponents([.year, .month, .day], from: today)
        return entries.filter {
            let components = calendar.dateComponents([.year, .month, .day], from: $0.date)
            return (components.year ?? 0) < (current.year ?? 0)
                && components.month == current.month && components.day == current.day
        }
        .sorted { $0.date > $1.date }
        .first
    }

    static func personalRecords(_ entries: [LifeEntry]) -> [PersonalRecord] {
        var result: [PersonalRecord] = []
        if let run = entries.filter({ $0.kind == .run && ($0.distanceKM ?? 0) > 0 })
            .max(by: { ($0.distanceKM ?? 0) < ($1.distanceKM ?? 0) }) {
            result.append(PersonalRecord(id: "longest-run", title: AppLanguage.localized("最远一次跑步"),
                                         value: AppLanguage.format("%.1f 公里", run.distanceKM ?? 0), date: run.date, symbol: "figure.run"))
        }
        if let ride = entries.filter({ $0.kind == .cycling && ($0.distanceKM ?? 0) > 0 })
            .max(by: { ($0.distanceKM ?? 0) < ($1.distanceKM ?? 0) }) {
            result.append(PersonalRecord(id: "longest-ride", title: AppLanguage.localized("最远一次骑行"),
                                         value: AppLanguage.format("%.1f 公里", ride.distanceKM ?? 0), date: ride.date, symbol: "bicycle"))
        }
        if let book = entries.filter({ $0.kind == .finishedBook }).min(by: { $0.date < $1.date }) {
            result.append(PersonalRecord(id: "first-book", title: AppLanguage.localized("第一本读完的书"),
                                         value: book.title, date: book.date, symbol: "books.vertical.fill"))
        }
        var seenCities = Set<String>()
        let tenthCity = entries.filter { $0.kind == .trip }
            .sorted { $0.date < $1.date }
            .filter {
                let city = GameEngine.normalized($0.city)
                return !city.isEmpty && seenCities.insert("\(GameEngine.normalized($0.country))|\(city)").inserted
            }
            .dropFirst(9).first
        if let tenthCity {
            result.append(PersonalRecord(id: "tenth-city", title: AppLanguage.localized("第十座城市"),
                                         value: tenthCity.city ?? "", date: tenthCity.date, symbol: "mappin.and.ellipse"))
        }
        if let career = entries.filter({ $0.kind == .careerMilestone }).min(by: { $0.date < $1.date }) {
            result.append(PersonalRecord(id: "first-career", title: AppLanguage.localized("第一段职业经历"),
                                         value: career.summary, date: career.date, symbol: "briefcase.fill"))
        }
        return result
    }
}

struct LifeBackfillView: View {
    @EnvironmentObject private var store: LifeStore
    @Environment(\.dismiss) private var dismiss
    @State private var selectedKind: EntryKind?

    private let choices: [EntryKind] = [.run, .finishedBook, .trip, .careerMilestone, .familyMoment, .certificate]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("从过去的经历开始升级").font(.title2.bold())
                        Text("选几件你记得的重要经历，日期可以填写过去的年月日。补录也会计入等级与徽章。")
                            .font(.subheadline).foregroundStyle(Palette.secondary)
                    }
                    .padding(.bottom, 4)

                    HStack(spacing: 12) {
                        MiniStat(value: "\(store.data.entries.count)", label: "段经历", symbol: "calendar")
                        MiniStat(value: "Lv.\(store.totalLevel)", label: "当前等级", symbol: "sparkles")
                    }
                    Text(AppLanguage.format("已解锁 %d/%d", store.badges.filter(\.isUnlocked).count, store.badges.count))
                        .font(.caption).foregroundStyle(Palette.secondary)

                    ForEach(choices) { kind in
                        Button { selectedKind = kind } label: {
                            HStack(spacing: 14) {
                                Image(systemName: kind.symbol)
                                    .font(.title3)
                                    .foregroundStyle(Palette.tint(for: kind.module))
                                    .frame(width: 40, height: 40)
                                    .background(Palette.tint(for: kind.module).opacity(0.1), in: RoundedRectangle(cornerRadius: 11))
                                Text(kind.title).font(.subheadline.weight(.semibold)).foregroundStyle(.primary)
                                Spacer()
                                Image(systemName: "plus.circle.fill").foregroundStyle(Palette.accent)
                            }
                            .padding(14)
                            .background(Palette.card, in: RoundedRectangle(cornerRadius: 15))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(20)
            }
            .background(Palette.background)
            .navigationTitle("回填人生起点")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("完成") { dismiss() } } }
            .sheet(item: $selectedKind) { EntryFormView(initialKind: $0) }
        }
    }
}

struct LifeChaptersView: View {
    @EnvironmentObject private var store: LifeStore
    @State private var editingYear: Int?
    @State private var draftTitle = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if store.data.entries.isEmpty {
                    EmptyState(symbol: "book.closed", title: "章节等待开启", detail: "记录经历后，成长故事会自动出现在这里")
                } else {
                    Text("按年份把经历串成故事，标题可以由你来定。")
                        .font(.subheadline).foregroundStyle(Palette.secondary)
                    ForEach(LifeStoryEngine.chapters(store.data.entries)) { chapter in
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: chapter.leadingModule.symbol)
                                    .foregroundStyle(Palette.tint(for: chapter.leadingModule))
                                Text(store.chapterTitle(for: chapter.year) ?? AppLanguage.format("%d · %@之年", chapter.year, chapter.leadingModule.title))
                                    .font(.headline)
                                Spacer()
                                Button("重命名", systemImage: "pencil") {
                                    draftTitle = store.chapterTitle(for: chapter.year) ?? ""
                                    editingYear = chapter.year
                                }
                                .labelStyle(.iconOnly)
                            }
                            Text(AppLanguage.format("%d 段经历 · %d 个领域", chapter.entries.count, chapter.moduleCount))
                                .font(.caption).foregroundStyle(Palette.secondary)
                            if let first = chapter.entries.first, let last = chapter.entries.last {
                                Text(first.id == last.id ? first.summary : AppLanguage.format("从 %@ 开始，走到 %@", first.summary, last.summary))
                                    .font(.subheadline).lineLimit(3)
                                Text(AppLanguage.format("%@ — %@", AppDate.yearMonthDay(first.date), AppDate.yearMonthDay(last.date)))
                                    .font(.caption).foregroundStyle(Palette.secondary)
                            }
                        }
                        .padding(18)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Palette.card, in: RoundedRectangle(cornerRadius: 18))
                    }
                }
            }
            .padding(20)
        }
        .background(Palette.background)
        .navigationTitle("人生章节")
        .alert("重命名章节", isPresented: Binding(get: { editingYear != nil }, set: { if !$0 { editingYear = nil } })) {
            TextField("章节标题", text: $draftTitle)
            Button("保存") {
                if let year = editingYear { store.setChapterTitle(draftTitle, for: year) }
                editingYear = nil
            }
            Button("取消", role: .cancel) { editingYear = nil }
        } message: { Text("留空会恢复自动标题") }
    }
}

struct PersonalRecordsView: View {
    @EnvironmentObject private var store: LifeStore

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                let records = LifeStoryEngine.personalRecords(store.data.entries)
                if records.isEmpty {
                    EmptyState(symbol: "list.star", title: "纪录册等待开启", detail: "记录跑步、骑行、阅读或旅行后，这里会留下你的第一次和最好一次")
                } else {
                    ForEach(records) { record in
                        HStack(spacing: 14) {
                            Image(systemName: record.symbol)
                                .font(.title3).foregroundStyle(Palette.accent)
                                .frame(width: 44, height: 44)
                                .background(Palette.accent.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
                            VStack(alignment: .leading, spacing: 4) {
                                Text(record.title).font(.caption).foregroundStyle(Palette.secondary)
                                Text(record.value).font(.headline)
                                Text(AppDate.yearMonthDay(record.date)).font(.caption).foregroundStyle(Palette.secondary)
                            }
                            Spacer()
                        }
                        .padding(16)
                        .background(Palette.card, in: RoundedRectangle(cornerRadius: 17))
                    }
                }
            }
            .padding(20)
        }
        .background(Palette.background)
        .navigationTitle("个人纪录册")
    }
}
