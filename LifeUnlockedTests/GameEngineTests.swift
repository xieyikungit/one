import XCTest
@testable import LifeUnlocked

final class GameEngineTests: XCTestCase {
    func testBadgesShowLockedProgressAndUnlockFromSpecificRun() {
        let first = LifeEntry(kind: .run, date: Date(timeIntervalSince1970: 1_700_000_000), title: "跑步", distanceKM: 3)
        let second = LifeEntry(kind: .run, date: first.date.addingTimeInterval(86_400), title: "跑步", distanceKM: 5.2)
        let locked = GameEngine.badges(entries: [first]).first { $0.id == "run-5k" }!
        XCTAssertFalse(locked.isUnlocked)
        XCTAssertEqual(locked.progress, 3)

        let unlocked = GameEngine.badges(entries: [first, second]).first { $0.id == "run-5k" }!
        XCTAssertTrue(unlocked.isUnlocked)
        XCTAssertEqual(unlocked.source?.date, second.date)
        XCTAssertEqual(unlocked.source?.origin, "手动填写")
        XCTAssertFalse(GameEngine.badges(entries: [first]).first { $0.id == "run-5k" }!.isUnlocked)
    }

    func testRereadBadgeIsOnePerBookAndDoesNotAddBookXP() {
        let first = LifeEntry(kind: .finishedBook, date: Date(timeIntervalSince1970: 1_700_000_000), title: "活着", author: "余华")
        let repeatOne = LifeEntry(kind: .finishedBook, date: first.date.addingTimeInterval(86_400), title: "活着", author: "余华")
        let repeatTwo = LifeEntry(kind: .finishedBook, date: first.date.addingTimeInterval(172_800), title: "活着", author: "余华")
        let entries = [first, repeatOne, repeatTwo]
        let reread = GameEngine.badges(entries: entries).filter { $0.id.hasPrefix("reread-") }
        XCTAssertEqual(reread.count, 1)
        XCTAssertEqual(reread.first?.source?.date, repeatOne.date)
        XCTAssertEqual(GameEngine.xpByModule(entries)[.learning], 100)
    }

    func testStepAndTravelBadgesKeepTheirSource() {
        let firstDay = HealthStepDay(date: Date(timeIntervalSince1970: 1_700_000_000), count: 90_000)
        let secondDay = HealthStepDay(date: firstDay.date.addingTimeInterval(86_400), count: 12_000)
        let visit = LifeEntry(kind: .trip, date: firstDay.date, title: "旅行", country: "中国", city: "苏州", tripMode: .visit)
        let badges = GameEngine.badges(entries: [visit], stepDays: [firstDay, secondDay])
        XCTAssertEqual(badges.first { $0.id == "steps-100k" }?.source?.origin, "Apple 健康")
        XCTAssertEqual(badges.first { $0.id == "steps-100k" }?.source?.date, secondDay.date)
        XCTAssertEqual(badges.first { $0.id == "city-first" }?.source?.summary, visit.summary)
    }

    func testHealthStepsAddExerciseExperienceWithoutRemovingRunExperience() {
        let run = LifeEntry(kind: .run, date: .now, title: "跑步", distanceKM: 5)
        let days = [HealthStepDay(date: .now, count: 1_500), HealthStepDay(date: .now.addingTimeInterval(-86_400), count: 700)]
        XCTAssertEqual(GameEngine.totalSteps(days), 2_200)
        XCTAssertEqual(GameEngine.xpByModule([run], stepDays: days)[.exercise], 52)
    }

    func testOlderBackupWithoutHealthFieldsStillDecodes() throws {
        let olderData = try JSONEncoder().encode(LifeData())
        let restored = try JSONDecoder().decode(LifeData.self, from: olderData)
        XCTAssertNil(restored.healthStepDays)
        XCTAssertNil(restored.lastHealthStepSync)
        XCTAssertNil(restored.chapterTitles)
    }

    func testRewardImpactDistinguishesNewAndRepeatedExperiences() {
        let book = LifeEntry(kind: .finishedBook, date: .now, title: "活着", author: "余华")
        XCTAssertEqual(GameEngine.rewardImpact(for: book, previousEntries: []).title, "人生书架点亮《活着》")
        XCTAssertEqual(GameEngine.rewardImpact(for: book, previousEntries: [book]).title, "重读《活着》已归档")

        let visit = LifeEntry(kind: .trip, date: .now, title: "旅行", country: "中国", city: "苏州", tripMode: .visit)
        XCTAssertEqual(GameEngine.rewardImpact(for: visit, previousEntries: []).title, "旅行足迹点亮苏州 · 中国")
        XCTAssertEqual(GameEngine.rewardImpact(for: visit, previousEntries: [visit]).title, "这段旅程已归档")
    }

    func testNextExerciseMilestoneAdvancesAfterHalfMarathon() {
        let half = LifeEntry(kind: .run, date: .now, title: "跑步", distanceKM: 21.1)
        XCTAssertTrue(GameEngine.nextMilestone(for: .exercise, entries: []).contains("半马"))
        XCTAssertTrue(GameEngine.nextMilestone(for: .exercise, entries: [half]).contains("全马"))
    }

    func testHalfAndFullMarathonBonusesOnlyApplyOnce() {
        let start = Date(timeIntervalSince1970: 1_700_000_000)
        let entries = [21.1, 21.2, 42.2, 42.3].enumerated().map { index, km in
            LifeEntry(kind: .run, date: start.addingTimeInterval(Double(index) * 86_400), title: "跑步", distanceKM: km)
        }
        let xp = GameEngine.xpByModule(entries)[.exercise] ?? 0
        // 10 XP/km, first half +200, first full +500, and one new personal best.
        XCTAssertEqual(xp, 211 + 212 + 422 + 423 + 200 + 500 + 60)
        XCTAssertEqual(GameEngine.achievements(entries: entries, profile: LifeProfile()).filter { ["half", "full"].contains($0.id) }.count, 2)
    }

    func testRereadingBookDoesNotAddExperience() {
        let first = LifeEntry(kind: .finishedBook, date: .now, title: "活着", author: "余华")
        let again = LifeEntry(kind: .finishedBook, date: .now.addingTimeInterval(1), title: "活着", author: "余华")
        XCTAssertEqual(GameEngine.xpByModule([first, again])[.learning], 100)
        XCTAssertTrue(GameEngine.achievements(entries: [first, again], profile: LifeProfile()).contains { $0.id.hasPrefix("reread-") })
    }

    func testTravelTripCapAndReturnVisit() {
        let first = LifeEntry(kind: .trip, date: .now, title: "旅行", distanceKM: 5_000, country: "中国", city: "上海", tripMode: .flight)
        let repeatTrip = LifeEntry(kind: .trip, date: .now.addingTimeInterval(1), title: "旅行", distanceKM: 500, country: "中国", city: "上海", tripMode: .train)
        XCTAssertEqual(GameEngine.xpByModule([first])[.travel], 400)
        XCTAssertEqual(GameEngine.xpByModule([first, repeatTrip])[.travel], 470)
    }

    func testAddingANewModuleNeverLowersTotalLevel() {
        let starting: [LifeModule: Int] = [.exercise: 15, .learning: 1, .travel: 1]
        let expanded: [LifeModule: Int] = [.exercise: 15, .learning: 1, .travel: 2]
        XCTAssertGreaterThanOrEqual(GameEngine.totalLevel(expanded), GameEngine.totalLevel(starting))
    }

    func testRunningAndLearnedSportsContributeToOneExerciseLevel() {
        let run = LifeEntry(kind: .run, date: .now, title: "跑步", distanceKM: 5)
        let learned = LifeEntry(kind: .learnedSport, date: .now, title: "游泳")
        let xp = GameEngine.xpByModule([run, learned])
        XCTAssertEqual(xp[.exercise], 250)
        XCTAssertEqual(GameEngine.moduleLevel(for: xp[.exercise] ?? 0), 3)
    }

    func testCyclingAddsThreeXPPerKilometerWithoutChangingRunMilestones() {
        let run = LifeEntry(kind: .run, date: .now, title: "跑步", distanceKM: 5)
        let ride = LifeEntry(kind: .cycling, date: .now, title: "骑行", distanceKM: 12.5)
        let xp = GameEngine.xpByModule([run, ride])
        XCTAssertEqual(xp[.exercise], 88)
        XCTAssertFalse(GameEngine.badges(entries: [ride]).first { $0.id == "run-5k" }!.isUnlocked)
        XCTAssertEqual(GameEngine.rewardImpact(for: ride, previousEntries: []).detail, "累计骑行 0.0 → 12.5 公里")
    }

    func testDriversLicenseAchievementRequiresAgeEighteenAtIssueDate() {
        let calendar = Calendar(identifier: .gregorian)
        let birth = calendar.date(from: DateComponents(year: 2000, month: 6, day: 1))!
        let before = calendar.date(from: DateComponents(year: 2018, month: 5, day: 31))!
        let after = calendar.date(from: DateComponents(year: 2018, month: 6, day: 1))!
        var profile = LifeProfile(birthDate: birth, hasDriversLicense: true, licenseDate: before)
        XCTAssertFalse(GameEngine.achievements(entries: [], profile: profile).contains { $0.id == "drivers-license" })
        profile.licenseDate = after
        XCTAssertTrue(GameEngine.achievements(entries: [], profile: profile).contains { $0.id == "drivers-license" })
    }

    func testCrossDomainBadgeUnlocksOnceWithoutBonusXP() {
        let start = Date(timeIntervalSince1970: 1_700_000_000)
        let run = LifeEntry(kind: .run, date: start, title: "跑步", distanceKM: 5)
        let trip = LifeEntry(kind: .trip, date: start.addingTimeInterval(86_400), title: "旅行", country: "中国", city: "苏州", tripMode: .visit)
        let badges = GameEngine.badges(entries: [run, trip])
        let combo = badges.first { $0.id == "combo-run-travel" }
        XCTAssertEqual(combo?.source?.date, trip.date)
        XCTAssertEqual(combo?.progress, 2)
        XCTAssertEqual(badges.filter { $0.id == "combo-run-travel" }.count, 1)
        let xp = GameEngine.xpByModule([run, trip])
        XCTAssertEqual(xp[.exercise], 50)
        XCTAssertEqual(xp[.travel], 400)
    }

    func testChaptersAndTimeEchoUseSavedExperienceDates() {
        let calendar = Calendar.current
        let anniversary = calendar.date(from: DateComponents(year: 2020, month: 10, day: 21))!
        let later = calendar.date(from: DateComponents(year: 2021, month: 3, day: 5))!
        let today = calendar.date(from: DateComponents(year: 2026, month: 10, day: 21))!
        let book = LifeEntry(kind: .finishedBook, date: anniversary, title: "活着")
        let run = LifeEntry(kind: .run, date: later, title: "跑步", distanceKM: 8)
        XCTAssertEqual(LifeStoryEngine.chapters([run, book]).map(\.year), [2021, 2020])
        XCTAssertEqual(LifeStoryEngine.timeEcho([book, run], on: today)?.id, book.id)
        XCTAssertNil(LifeStoryEngine.timeEcho([book, run], on: later))
    }

    func testPersonalRecordsPickBestRunAndTenthDistinctCity() {
        let start = Date(timeIntervalSince1970: 1_700_000_000)
        let runs = [5.0, 12.0, 8.0].enumerated().map { index, distance in
            LifeEntry(kind: .run, date: start.addingTimeInterval(Double(index) * 86_400), title: "跑步", distanceKM: distance)
        }
        let trips = (1...10).map { index in
            LifeEntry(kind: .trip, date: start.addingTimeInterval(Double(index + 10) * 86_400), title: "旅行", country: "中国", city: "城市\(index)", tripMode: .visit)
        }
        let records = LifeStoryEngine.personalRecords(runs + trips)
        XCTAssertEqual(records.first { $0.id == "longest-run" }?.value, "12.0 公里")
        XCTAssertEqual(records.first { $0.id == "tenth-city" }?.value, "城市10")
    }

    func testBackupPreviewMergesWithoutDuplicatingOrOverwritingLocalRecords() {
        let day = Date(timeIntervalSince1970: 1_700_000_000)
        let localRun = LifeEntry(kind: .run, date: day, title: "跑步", distanceKM: 5)
        var sameContentNewID = localRun
        sameContentNewID.id = UUID()
        var sameIDDifferentContent = localRun
        sameIDDifferentContent.distanceKM = 10
        let newBook = LifeEntry(kind: .finishedBook, date: day, title: "活着", author: "余华")
        let goal = PersonalGoal(title: "读完十本书", metric: .books, target: 10)

        var local = LifeData()
        local.entries = [localRun]
        local.goals = [goal]
        local.healthStepDays = [HealthStepDay(date: day, count: 4_000)]
        local.profile.nickname = "本机昵称"
        local.chapterTitles = ["2023": "本机章节"]

        var incoming = LifeData()
        incoming.entries = [sameContentNewID, sameIDDifferentContent, newBook]
        incoming.goals = [goal, PersonalGoal(title: "跑满百公里", metric: .runningKM, target: 100)]
        incoming.healthStepDays = [HealthStepDay(date: day, count: 3_000),
                                   HealthStepDay(date: day.addingTimeInterval(86_400), count: 5_000)]
        incoming.profile.nickname = "备份昵称"
        incoming.profile.education = "本科"
        incoming.chapterTitles = ["2023": "备份章节", "2024": "新增章节"]

        let preview = BackupImporter.preview(current: local, incoming: incoming, filename: "backup.json")
        XCTAssertEqual(preview.summary.addedEntries, 1)
        XCTAssertEqual(preview.summary.skippedEntries, 2)
        XCTAssertEqual(preview.summary.conflictingEntries, 1)
        XCTAssertEqual(preview.summary.addedGoals, 1)
        XCTAssertNil(preview.incoming.healthStepDays)
        XCTAssertEqual(preview.merged.entries.count, 2)
        XCTAssertEqual(preview.merged.entries.first?.distanceKM, 5)
        XCTAssertEqual(preview.merged.healthStepDays?.map(\.count), [4_000])
        XCTAssertEqual(preview.merged.profile.nickname, "本机昵称")
        XCTAssertEqual(preview.merged.profile.education, "本科")
        XCTAssertEqual(preview.merged.chapterTitles?["2023"], "本机章节")
        XCTAssertEqual(preview.merged.chapterTitles?["2024"], "新增章节")

        let again = BackupImporter.preview(current: preview.merged, incoming: incoming, filename: "backup.json")
        XCTAssertEqual(again.summary.addedEntries, 0)
        XCTAssertEqual(again.summary.addedGoals, 0)
        XCTAssertEqual(again.merged.healthStepDays?.map(\.count), [4_000])
    }

    func testWeeklyRecapCountsOnlyExperiencesAndBadgesFromSelectedWeek() {
        let calendar = Calendar(identifier: .gregorian)
        let selected = calendar.date(from: DateComponents(year: 2026, month: 10, day: 21))!
        let week = calendar.dateInterval(of: .weekOfYear, for: selected)!
        let earlier = LifeEntry(kind: .run, date: week.start.addingTimeInterval(-86_400), title: "跑步", distanceKM: 5)
        let book = LifeEntry(kind: .finishedBook, date: week.start.addingTimeInterval(86_400), title: "活着", author: "余华")
        let trip = LifeEntry(kind: .trip, date: week.end.addingTimeInterval(86_400), title: "旅行", country: "中国", city: "苏州")
        let day = HealthStepDay(date: week.start.addingTimeInterval(172_800), count: 2_500)
        let recap = WeeklyRecapEngine.recap(for: selected, entries: [earlier, book, trip], stepDays: [day], calendar: calendar)

        XCTAssertEqual(recap.entries.map(\.id), [book.id])
        XCTAssertEqual(recap.stepCount, 2_500)
        XCTAssertEqual(recap.moduleCount, 2)
        XCTAssertEqual(recap.xpGained, 102)
        XCTAssertTrue(recap.newBadges.allSatisfy { ($0.source?.date ?? .distantPast) >= week.start && ($0.source?.date ?? .distantFuture) < week.end })
        XCTAssertFalse(recap.newBadges.contains { $0.id == "run-5k" })

        let empty = WeeklyRecapEngine.recap(for: week.start.addingTimeInterval(-86_400 * 7), entries: [book], stepDays: [], calendar: calendar)
        XCTAssertTrue(empty.isEmpty)
        XCTAssertEqual(empty.xpGained, 0)
    }

    func testManualBackupExcludesAppleHealthStepHistory() throws {
        var source = LifeData()
        source.entries = [LifeEntry(kind: .finishedBook, date: .now, title: "活着")]
        source.healthStepDays = [HealthStepDay(date: .now, count: 10_000)]
        source.lastHealthStepSync = .now

        let backup = try JSONDecoder().decode(LifeData.self, from: JSONEncoder().encode(BackupImporter.exportableData(source)))
        XCTAssertEqual(backup.entries.count, 1)
        XCTAssertNil(backup.healthStepDays)
        XCTAssertNil(backup.lastHealthStepSync)
    }

    @MainActor
    func testStoredHealthCacheIsSeparateFromBackedUpRecords() throws {
        let store = LifeStore()
        store.deleteAllLocalData()
        defer { store.deleteAllLocalData() }
        store.add(LifeEntry(kind: .finishedBook, date: .now, title: "活着"))
        store.replaceHealthStepDays([HealthStepDay(date: .now, count: 8_000)])

        let support = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        let manualURL = support.appendingPathComponent("life-data.json")
        let privateURL = support.appendingPathComponent("LifeUnlocked", isDirectory: true)
        let manual = try JSONDecoder().decode(LifeData.self, from: Data(contentsOf: manualURL))
        XCTAssertEqual(manual.entries.count, 1)
        XCTAssertNil(manual.healthStepDays)
        XCTAssertNil(manual.lastHealthStepSync)
        XCTAssertTrue(FileManager.default.fileExists(atPath: privateURL.appendingPathComponent("health-steps.json").path))
        XCTAssertEqual(try privateURL.resourceValues(forKeys: [.isExcludedFromBackupKey]).isExcludedFromBackup, true)
        XCTAssertNotEqual(try manualURL.resourceValues(forKeys: [.isExcludedFromBackupKey]).isExcludedFromBackup, true)
    }

    @MainActor
    func testLegacyCombinedFileMigratesWithoutBackingUpSteps() throws {
        let store = LifeStore()
        store.deleteAllLocalData()
        defer { store.deleteAllLocalData() }
        let support = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        let privateURL = support.appendingPathComponent("LifeUnlocked", isDirectory: true)
        try FileManager.default.createDirectory(at: privateURL, withIntermediateDirectories: true)
        var legacy = LifeData()
        legacy.entries = [LifeEntry(kind: .finishedBook, date: .now, title: "活着")]
        legacy.healthStepDays = [HealthStepDay(date: .now, count: 9_000)]
        try JSONEncoder().encode(legacy).write(to: privateURL.appendingPathComponent("life-data.json"))

        let migrated = LifeStore()
        XCTAssertEqual(migrated.data.entries.count, 1)
        XCTAssertEqual(migrated.totalHealthSteps, 9_000)
        let backedUp = try JSONDecoder().decode(LifeData.self, from: Data(contentsOf: support.appendingPathComponent("life-data.json")))
        XCTAssertNil(backedUp.healthStepDays)
        XCTAssertEqual(try privateURL.resourceValues(forKeys: [.isExcludedFromBackupKey]).isExcludedFromBackup, true)
    }
}
