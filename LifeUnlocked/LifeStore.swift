import Foundation
import CoreLocation
import UniformTypeIdentifiers
import SwiftUI

struct Reward: Identifiable {
    let id = UUID()
    let title: String
    let module: LifeModule
    let impact: RewardImpact
    let xpGained: Int
    let oldModuleXP: Int
    let newModuleXP: Int
    let oldModuleLevel: Int
    let newModuleLevel: Int
    let oldTotalLevel: Int
    let newTotalLevel: Int
    let newBadges: [LifeBadge]
    let nextMilestone: String
}

struct BackupDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.json] }
    var contents: Data

    init(contents: Data) { self.contents = contents }
    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents else {
            throw CocoaError(.fileReadCorruptFile)
        }
        contents = data
    }
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: contents)
    }
}

struct ExperienceCSVDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.commaSeparatedText] }
    let contents: Data

    init(entries: [LifeEntry]) {
        let headers = ["CSV字段_日期", "CSV字段_成长领域", "CSV字段_记录类型", "CSV字段_经历名称", "CSV字段_记录摘要", "CSV字段_作者", "CSV字段_国家或地区", "CSV字段_城市", "CSV字段_出发地", "CSV字段_出行方式", "CSV字段_距离公里", "CSV字段_献血量毫升", "CSV字段_阶段", "CSV字段_公司", "CSV字段_职位", "CSV字段_补充内容"]
            .map { Self.csvField(AppLanguage.localized($0)) }
            .joined(separator: ",")
        let rows: [String] = entries.sorted { $0.date < $1.date }.map { entry in
            [
                AppDate.yearMonthDay(entry.date), entry.kind.module.title, entry.kind.title,
                entry.title, entry.summary, entry.author ?? "", entry.country ?? "", entry.city ?? "",
                entry.origin ?? "", entry.tripMode?.title ?? "", entry.distanceKM.map { String($0) } ?? "",
                entry.amountML.map { String($0) } ?? "", entry.stage ?? "", entry.careerCompany ?? "",
                entry.careerPosition ?? "", entry.note ?? ""
            ].map(Self.csvField).joined(separator: ",")
        }
        contents = ([headers] + rows).joined(separator: "\r\n").data(using: .utf8) ?? Data()
    }

    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents else { throw CocoaError(.fileReadCorruptFile) }
        contents = data
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: contents)
    }

    private static func csvField(_ value: String) -> String {
        "\"\(value.replacingOccurrences(of: "\"", with: "\"\""))\""
    }
}

@MainActor
final class LifeStore: ObservableObject {
    @Published private(set) var data: LifeData
    @Published var recentReward: Reward?
    @Published var errorMessage: String?
    @Published var pendingImport: BackupImportPreview?

    private struct StepCache: Codable {
        let days: [HealthStepDay]
        let lastSync: Date?
    }

    private static var supportURL: URL {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
    }
    // Manual records receive the normal iOS device backup treatment.
    private static var dataURL: URL { supportURL.appendingPathComponent("life-data.json") }
    // This directory also holds older local data and pre-import snapshots.
    private static var privateURL: URL { supportURL.appendingPathComponent("LifeUnlocked", isDirectory: true) }
    private static var legacyDataURL: URL { privateURL.appendingPathComponent("life-data.json") }
    private static var stepCacheURL: URL { privateURL.appendingPathComponent("health-steps.json") }

    init() {
        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("-uiTesting-reset") {
            try? FileManager.default.removeItem(at: Self.dataURL)
            try? FileManager.default.removeItem(at: Self.privateURL)
            UserDefaults.standard.removeObject(forKey: "lifeBackfillSeen")
        }
        #endif
        let hasCurrentFile = FileManager.default.fileExists(atPath: Self.dataURL.path)
        let sourceURL = hasCurrentFile ? Self.dataURL : Self.legacyDataURL
        if let file = try? Data(contentsOf: sourceURL),
           let decoded = try? JSONDecoder().decode(LifeData.self, from: file) {
            data = decoded
        } else {
            data = LifeData()
        }
        if let file = try? Data(contentsOf: Self.stepCacheURL),
           let cache = try? JSONDecoder().decode(StepCache.self, from: file) {
            data.healthStepDays = cache.days
            data.lastHealthStepSync = cache.lastSync
        }
        if FileManager.default.fileExists(atPath: Self.privateURL.path) {
            do { try markExcludedFromBackup(Self.privateURL) }
            catch { errorMessage = "无法保护本机健康缓存：\(error.localizedDescription)" }
        }
        if !hasCurrentFile && FileManager.default.fileExists(atPath: Self.legacyDataURL.path) {
            do {
                if data.healthStepDays != nil || data.lastHealthStepSync != nil {
                    try persistStepCache(days: data.healthStepDays ?? [], lastSync: data.lastHealthStepSync)
                }
                try persistManualData(data)
            } catch {
                errorMessage = "旧数据迁移失败，原始文件仍保留：\(error.localizedDescription)"
            }
        }
    }

    var xp: [LifeModule: Int] { GameEngine.xpByModule(data.entries, stepDays: data.healthStepDays ?? []) }
    var totalHealthSteps: Int { GameEngine.totalSteps(data.healthStepDays ?? []) }
    var todayHealthSteps: Int {
        (data.healthStepDays ?? []).first {
            Calendar.current.isDateInToday($0.date)
        }?.count ?? 0
    }
    var levels: [LifeModule: Int] {
        Dictionary(uniqueKeysWithValues: LifeModule.allCases.map { ($0, GameEngine.moduleLevel(for: xp[$0] ?? 0)) })
    }
    var totalLevel: Int { GameEngine.totalLevel(levels) }
    var totalProgress: Double { GameEngine.totalProgress(levels) }
    var achievements: [Achievement] { GameEngine.achievements(entries: data.entries, profile: data.profile, goals: data.goals) }
    var badges: [LifeBadge] { GameEngine.badges(entries: data.entries, stepDays: data.healthStepDays ?? []) }
    var sortedEntries: [LifeEntry] { data.entries.sorted { $0.date > $1.date } }

    func chapterTitle(for year: Int) -> String? { data.chapterTitles?[String(year)] }

    func setChapterTitle(_ title: String, for year: Int) {
        let cleaned = title.trimmingCharacters(in: .whitespacesAndNewlines)
        var titles = data.chapterTitles ?? [:]
        if cleaned.isEmpty { titles.removeValue(forKey: String(year)) }
        else { titles[String(year)] = cleaned }
        data.chapterTitles = titles
        save()
    }

    func add(_ entry: LifeEntry) {
        let previousEntries = data.entries
        let oldXP = xp[entry.kind.module] ?? 0
        let oldModuleLevel = levels[entry.kind.module] ?? 1
        let oldTotalLevel = totalLevel
        let oldBadgeIDs = Set(badges.filter(\.isUnlocked).map(\.id))
        data.entries.append(entry)
        save()
        let unlockedBadges = badges.filter { $0.isUnlocked && !oldBadgeIDs.contains($0.id) }
        if entry.date >= Calendar.current.startOfDay(for: data.joinedAt ?? Date()) {
            recentReward = Reward(
                title: entry.summary,
                module: entry.kind.module,
                impact: GameEngine.rewardImpact(for: entry, previousEntries: previousEntries),
                xpGained: max(0, (xp[entry.kind.module] ?? 0) - oldXP),
                oldModuleXP: oldXP,
                newModuleXP: xp[entry.kind.module] ?? 0,
                oldModuleLevel: oldModuleLevel,
                newModuleLevel: levels[entry.kind.module] ?? 1,
                oldTotalLevel: oldTotalLevel,
                newTotalLevel: totalLevel,
                newBadges: unlockedBadges,
                nextMilestone: GameEngine.nextMilestone(for: entry.kind.module, entries: data.entries)
            )
        }
        if entry.kind == .trip && entry.latitude == nil && entry.longitude == nil,
           let city = entry.city, !city.isEmpty {
            resolveCoordinate(for: entry.id, city: city, country: entry.country ?? "")
        }
    }

    func delete(_ entry: LifeEntry) {
        data.entries.removeAll { $0.id == entry.id }
        save()
    }

    func update(_ entry: LifeEntry) {
        guard let index = data.entries.firstIndex(where: { $0.id == entry.id }) else { return }
        data.entries[index] = entry
        save()
        if entry.kind == .trip && entry.latitude == nil && entry.longitude == nil,
           let city = entry.city, !city.isEmpty {
            resolveCoordinate(for: entry.id, city: city, country: entry.country ?? "")
        }
    }

    func updateProfile(_ profile: LifeProfile) {
        data.profile = profile
        save()
    }

    func replaceHealthStepDays(_ days: [HealthStepDay]) {
        do {
            let now = Date()
            try persistStepCache(days: days, lastSync: now)
            data.healthStepDays = days
            data.lastHealthStepSync = now
        } catch {
            errorMessage = "步数保存失败：\(error.localizedDescription)"
        }
    }

    func addGoal(_ goal: PersonalGoal) {
        data.goals.append(goal)
        save()
    }

    func deleteGoal(_ goal: PersonalGoal) {
        data.goals.removeAll { $0.id == goal.id }
        save()
    }

    func backup() -> BackupDocument? {
        // Apple Health data stays on this device and can be synced again after restore.
        do { return BackupDocument(contents: try JSONEncoder().encode(BackupImporter.exportableData(data))) }
        catch { errorMessage = "无法生成备份：\(error.localizedDescription)"; return nil }
    }

    func exportExperiencesCSV() -> ExperienceCSVDocument {
        ExperienceCSVDocument(entries: data.entries)
    }

    func prepareImport(from url: URL) {
        pendingImport = nil
        let accessing = url.startAccessingSecurityScopedResource()
        defer { if accessing { url.stopAccessingSecurityScopedResource() } }
        do {
            let incoming = try JSONDecoder().decode(LifeData.self, from: Data(contentsOf: url))
            guard incoming.schemaVersion == 1 else {
                errorMessage = "备份版本与当前原型不兼容。"
                return
            }
            guard Set(incoming.entries.map(\.id)).count == incoming.entries.count,
                  Set(incoming.goals.map(\.id)).count == incoming.goals.count else {
                errorMessage = "备份中有重复记录标识，无法安全导入。"
                return
            }
            pendingImport = BackupImporter.preview(current: data, incoming: incoming, filename: url.lastPathComponent)
        } catch {
            errorMessage = "导入失败：\(error.localizedDescription)"
        }
    }

    func applyPendingImport(_ mode: BackupImportMode) {
        guard let preview = pendingImport else { return }
        do {
            try savePreImportSnapshot()
            var result = mode == .merge ? preview.merged : preview.incoming
            result.healthStepDays = data.healthStepDays
            result.lastHealthStepSync = data.lastHealthStepSync
            try persistManualData(result)
            data = result
            pendingImport = nil
        } catch {
            errorMessage = "导入失败，原有数据未改变：\(error.localizedDescription)"
        }
    }

    var preImportSnapshots: [URL] {
        let directory = Self.privateURL
        return ((try? FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)) ?? [])
            .filter { $0.lastPathComponent.hasPrefix("life-data-before-import-") && $0.pathExtension == "json" }
            .sorted { $0.lastPathComponent > $1.lastPathComponent }
    }

    func deleteAllLocalData() {
        do {
            if FileManager.default.fileExists(atPath: Self.dataURL.path) {
                try FileManager.default.removeItem(at: Self.dataURL)
            }
            if FileManager.default.fileExists(atPath: Self.privateURL.path) {
                try FileManager.default.removeItem(at: Self.privateURL)
            }
            data = LifeData()
            pendingImport = nil
            recentReward = nil
            UserDefaults.standard.removeObject(forKey: "lifeBackfillSeen")
            UserDefaults.standard.removeObject(forKey: HealthSteps.accessRequestKey)
        } catch {
            errorMessage = "清除失败：\(error.localizedDescription)"
        }
    }

    private func savePreImportSnapshot() throws {
        let directory = Self.privateURL
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try markExcludedFromBackup(directory)
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyyMMdd-HHmmss-SSS"
        let filename = "life-data-before-import-\(formatter.string(from: Date())).json"
        let snapshotURL = directory.appendingPathComponent(filename)
        try JSONEncoder().encode(BackupImporter.exportableData(data)).write(to: snapshotURL, options: .atomic)
        for old in preImportSnapshots.dropFirst(5) { try? FileManager.default.removeItem(at: old) }
    }

    private func persistManualData(_ value: LifeData) throws {
        let url = Self.dataURL
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try JSONEncoder().encode(BackupImporter.exportableData(value)).write(to: url, options: .atomic)
    }

    private func persistStepCache(days: [HealthStepDay], lastSync: Date?) throws {
        try FileManager.default.createDirectory(at: Self.privateURL, withIntermediateDirectories: true)
        try markExcludedFromBackup(Self.privateURL)
        try JSONEncoder().encode(StepCache(days: days, lastSync: lastSync))
            .write(to: Self.stepCacheURL, options: .atomic)
    }

    private func markExcludedFromBackup(_ target: URL) throws {
        var url = target
        var values = URLResourceValues()
        values.isExcludedFromBackup = true
        try url.setResourceValues(values)
    }

    private func save() {
        do {
            try persistManualData(data)
        } catch {
            errorMessage = "保存失败：\(error.localizedDescription)"
        }
    }

    private func resolveCoordinate(for id: UUID, city: String, country: String) {
        Task {
            do {
                let placemarks = try await CLGeocoder().geocodeAddressString("\(city), \(country)")
                guard let coordinate = placemarks.first?.location?.coordinate,
                      let index = data.entries.firstIndex(where: { $0.id == id }) else { return }
                data.entries[index].latitude = coordinate.latitude
                data.entries[index].longitude = coordinate.longitude
                save()
            } catch {
                // The visit remains recorded even when the map service is unavailable.
            }
        }
    }
}
