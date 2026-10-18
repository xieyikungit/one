import Foundation

struct BadgeSource: Equatable {
    let date: Date
    let summary: String
    let origin: String
}

struct LifeBadge: Identifiable, Equatable {
    let id: String
    let module: LifeModule
    let title: String
    let symbol: String
    let rule: String
    let repeatRule: String
    let progress: Double
    let target: Double
    let unit: String
    let source: BadgeSource?

    var isUnlocked: Bool { source != nil }
    var fraction: Double { min(progress / max(target, 1), 1) }
    var progressText: String {
        let digits = unit == "公里" ? 1 : 0
        let localizedUnit = AppLanguage.localized(unit)
        return "\(progress.formatted(.number.precision(.fractionLength(0...digits)))) / \(target.formatted(.number.precision(.fractionLength(0...digits)))) \(localizedUnit)"
    }
}

extension GameEngine {
    static func badges(entries: [LifeEntry], stepDays: [HealthStepDay] = []) -> [LifeBadge] {
        let ordered = entries.sorted {
            $0.date == $1.date ? $0.id.uuidString < $1.id.uuidString : $0.date < $1.date
        }
        var triggers: [String: BadgeSource] = [:]
        var runTotal = 0.0
        var longestRun = 0.0
        var books = Set<String>()
        var rereadBooks: [String: LifeEntry] = [:]
        var sports = Set<String>()
        var cities = Set<String>()
        var countries = Set<String>()
        var kindnessCount = 0
        var donationCount = 0
        var familyMomentCount = 0
        var careerMilestones = Set<String>()
        var creativeWorks = Set<String>()
        var masteredLifeSkills = Set<String>()
        var wellnessCount = 0
        var experienceCount = 0
        var petMomentCount = 0
        var completedChallenges = Set<String>()
        var relationshipCount = 0
        var assetMilestones = Set<String>()
        var financialMilestones = Set<String>()
        var financeProgressByGoal: [String: Double] = [:]

        func trigger(_ id: String, entry: LifeEntry) {
            if triggers[id] == nil {
                triggers[id] = BadgeSource(date: entry.date, summary: entry.summary, origin: AppLanguage.localized("手动填写"))
            }
        }

        for entry in ordered {
            switch entry.kind {
            case .run:
                let distance = max(0, entry.distanceKM ?? 0)
                runTotal += distance
                longestRun = max(longestRun, distance)
                if distance >= 5 { trigger("run-5k", entry: entry) }
                if distance >= 21.0975 { trigger("run-half", entry: entry) }
                if distance >= 42.195 { trigger("run-full", entry: entry) }
                if runTotal >= 100 { trigger("run-100k", entry: entry) }
            case .cycling:
                break
            case .learnedSport:
                let key = normalized(entry.title)
                if !key.isEmpty && sports.insert(key).inserted && sports.count >= 3 {
                    trigger("sport-three", entry: entry)
                }
            case .finishedBook:
                let key = normalized(entry.title) + "|" + normalized(entry.author)
                guard !normalized(entry.title).isEmpty else { continue }
                if books.insert(key).inserted {
                    trigger("book-first", entry: entry)
                    if books.count >= 10 { trigger("book-ten", entry: entry) }
                } else if rereadBooks[key] == nil {
                    rereadBooks[key] = entry
                    trigger("reread-\(key)", entry: entry)
                }
            case .degree, .certificate, .languageMilestone:
                break
            case .trip:
                let city = normalized(entry.city)
                let country = normalized(entry.country)
                if !city.isEmpty && cities.insert(country + "|" + city).inserted {
                    trigger("city-first", entry: entry)
                    if cities.count >= 5 { trigger("city-five", entry: entry) }
                }
                if !country.isEmpty && countries.insert(country).inserted && countries.count >= 3 {
                    trigger("country-three", entry: entry)
                }
            case .kindness:
                kindnessCount += 1
                if kindnessCount == 1 { trigger("kindness-first", entry: entry) }
                if kindnessCount >= 10 { trigger("kindness-ten", entry: entry) }
            case .bloodDonation:
                donationCount += 1
                if donationCount == 1 { trigger("donation-first", entry: entry) }
                if donationCount >= 10 { trigger("donation-ten", entry: entry) }
            case .familyMoment:
                familyMomentCount += 1
                if familyMomentCount == 1 { trigger("family-first", entry: entry) }
                if familyMomentCount >= 10 { trigger("family-ten", entry: entry) }
            case .careerMilestone:
                let key = GameEngine.careerMilestoneKey(for: entry) ?? ""
                if !key.isEmpty && careerMilestones.insert(key).inserted {
                    if careerMilestones.count == 1 { trigger("career-first", entry: entry) }
                    if careerMilestones.count >= 10 { trigger("career-ten", entry: entry) }
                }
            case .creativeWork:
                let key = normalized(entry.title)
                if !key.isEmpty && creativeWorks.insert(key).inserted {
                    if creativeWorks.count == 1 { trigger("creation-first", entry: entry) }
                    if creativeWorks.count >= 10 { trigger("creation-ten", entry: entry) }
                }
            case .lifeSkill:
                let key = normalized(entry.title)
                if !key.isEmpty && masteredLifeSkills.insert(key).inserted {
                    if masteredLifeSkills.count == 1 { trigger("life-skill-first", entry: entry) }
                    if masteredLifeSkills.count >= 10 { trigger("life-skill-ten", entry: entry) }
                }
            case .wellnessAction:
                wellnessCount += 1
                if wellnessCount == 1 { trigger("wellness-first", entry: entry) }
                if wellnessCount >= 10 { trigger("wellness-ten", entry: entry) }
            case .lifeExperience:
                experienceCount += 1
                if experienceCount == 1 { trigger("experience-first", entry: entry) }
                if experienceCount >= 10 { trigger("experience-ten", entry: entry) }
            case .petMoment:
                petMomentCount += 1
                if petMomentCount == 1 { trigger("pet-first", entry: entry) }
                if petMomentCount >= 10 { trigger("pet-ten", entry: entry) }
            case .completedChallenge:
                let key = normalized(entry.title)
                if !key.isEmpty && completedChallenges.insert(key).inserted {
                    if completedChallenges.count == 1 { trigger("challenge-first", entry: entry) }
                    if completedChallenges.count >= 10 { trigger("challenge-ten", entry: entry) }
                }
            case .relationshipMoment:
                relationshipCount += 1
                if relationshipCount == 1 { trigger("relationship-first", entry: entry) }
                if relationshipCount >= 10 { trigger("relationship-ten", entry: entry) }
            case .livingMilestone:
                let key = GameEngine.assetMilestoneKey(for: entry) ?? ""
                if !key.isEmpty && assetMilestones.insert(key).inserted {
                    if assetMilestones.count == 1 { trigger("living-first", entry: entry) }
                    if assetMilestones.count >= 10 { trigger("living-ten", entry: entry) }
                }
            case .vehicleMilestone:
                let key = GameEngine.assetMilestoneKey(for: entry) ?? ""
                if !key.isEmpty && assetMilestones.insert(key).inserted {
                    if assetMilestones.count == 1 { trigger("living-first", entry: entry) }
                    if assetMilestones.count >= 10 { trigger("living-ten", entry: entry) }
                }
            case .financialMilestone:
                guard let key = GameEngine.financeGoalKey(for: entry) else { continue }
                let isNewGoal = financialMilestones.insert(key).inserted
                if isNewGoal {
                    if financialMilestones.count == 1 { trigger("finance-first", entry: entry) }
                    if financialMilestones.count >= 10 { trigger("finance-ten", entry: entry) }
                }
                if let progress = entry.financeProgress, entry.financeGoalType != nil {
                    let before = financeProgressByGoal[key] ?? 0
                    let after = max(before, progress)
                    financeProgressByGoal[key] = after
                    if before < 0.25 && after >= 0.25 { trigger("finance-quarter", entry: entry) }
                    if before < 1 && after >= 1 { trigger("finance-complete", entry: entry) }
                }
            }
        }

        var stepTotal = 0
        for day in stepDays.sorted(by: { $0.date < $1.date }) {
            stepTotal += max(0, day.count)
            if stepTotal >= 100_000 && triggers["steps-100k"] == nil {
                triggers["steps-100k"] = BadgeSource(
                    date: day.date,
                    summary: AppLanguage.localized("累计步数达到 100,000 步"),
                    origin: AppLanguage.localized("Apple 健康")
                )
            }
        }

        func badge(
            _ id: String, module: LifeModule, title: String, symbol: String,
            rule: String, progress: Double, target: Double, unit: String,
            repeatRule: String = "仅首次达到条件时解锁一次"
        ) -> LifeBadge {
            LifeBadge(
                id: id, module: module, title: AppLanguage.localized(title), symbol: symbol,
                rule: AppLanguage.localized(rule), repeatRule: AppLanguage.localized(repeatRule), progress: progress,
                target: target, unit: unit, source: triggers[id]
            )
        }

        var result: [LifeBadge] = [
            badge("run-5k", module: .exercise, title: "第一段五公里", symbol: "figure.run",
                  rule: "单次跑步达到 5 公里", progress: longestRun, target: 5, unit: "公里"),
            badge("run-half", module: .exercise, title: "半马里程碑", symbol: "figure.run.circle.fill",
                  rule: "单次跑步达到 21.0975 公里", progress: longestRun, target: 21.0975, unit: "公里"),
            badge("run-full", module: .exercise, title: "全马里程碑", symbol: "medal.fill",
                  rule: "单次跑步达到 42.195 公里", progress: longestRun, target: 42.195, unit: "公里"),
            badge("run-100k", module: .exercise, title: "百公里足迹", symbol: "point.topleft.down.curvedto.point.bottomright.up",
                  rule: "累计跑步达到 100 公里", progress: runTotal, target: 100, unit: "公里"),
            badge("sport-three", module: .exercise, title: "运动多面手", symbol: "figure.mixed.cardio",
                  rule: "学会 3 项不同的运动", progress: Double(sports.count), target: 3, unit: "项"),
            badge("steps-100k", module: .exercise, title: "十万步足迹", symbol: "figure.walk",
                  rule: "Apple 健康累计步数达到 100,000 步", progress: Double(stepTotal), target: 100_000, unit: "步"),
            badge("book-first", module: .learning, title: "人生书架起点", symbol: "book.closed.fill",
                  rule: "读完第一本书", progress: Double(books.count), target: 1, unit: "本"),
            badge("book-ten", module: .learning, title: "十本书的旅程", symbol: "books.vertical.fill",
                  rule: "读完 10 本不同的书；重读不重复计数", progress: Double(books.count), target: 10, unit: "本"),
            badge("city-first", module: .travel, title: "第一座城市", symbol: "mappin.and.ellipse",
                  rule: "实际到访第一座城市", progress: Double(cities.count), target: 1, unit: "座"),
            badge("city-five", module: .travel, title: "五城足迹", symbol: "map.fill",
                  rule: "实际到访 5 座不同的城市", progress: Double(cities.count), target: 5, unit: "座"),
            badge("country-three", module: .travel, title: "跨越三国", symbol: "globe.asia.australia.fill",
                  rule: "实际到访 3 个不同的国家或地区", progress: Double(countries.count), target: 3, unit: "个"),
            badge("kindness-first", module: .love, title: "第一份善意", symbol: "heart.fill",
                  rule: "记录第一次帮助他人或参与志愿服务", progress: Double(kindnessCount), target: 1, unit: "次"),
            badge("kindness-ten", module: .love, title: "十次善意行动", symbol: "hands.sparkles.fill",
                  rule: "累计记录 10 次善意行动", progress: Double(kindnessCount), target: 10, unit: "次"),
            badge("donation-first", module: .love, title: "第一次献血", symbol: "drop.fill",
                  rule: "记录第一次献血", progress: Double(donationCount), target: 1, unit: "次"),
            badge("donation-ten", module: .love, title: "十次献血", symbol: "cross.case.fill",
                  rule: "累计记录 10 次献血", progress: Double(donationCount), target: 10, unit: "次"),
            badge("family-first", module: .family, title: "家庭记忆起点", symbol: "figure.2.and.child.holdinghands",
                  rule: "记录第一段家庭经历", progress: Double(familyMomentCount), target: 1, unit: "条"),
            badge("family-ten", module: .family, title: "十段家庭记忆", symbol: "house.fill",
                  rule: "累计记录 10 段家庭经历", progress: Double(familyMomentCount), target: 10, unit: "条"),
            badge("career-first", module: .career, title: "职业旅程起点", symbol: "briefcase.fill",
                  rule: "记录第一个不同的职业里程碑", progress: Double(careerMilestones.count), target: 1, unit: "项"),
            badge("career-ten", module: .career, title: "十个职业里程碑", symbol: "medal.fill",
                  rule: "累计记录 10 个不同的职业里程碑", progress: Double(careerMilestones.count), target: 10, unit: "项"),
            badge("creation-first", module: .creation, title: "第一件作品", symbol: "paintpalette.fill",
                  rule: "完成并记录第一项创作", progress: Double(creativeWorks.count), target: 1, unit: "项"),
            badge("creation-ten", module: .creation, title: "十件作品集", symbol: "sparkles.rectangle.stack.fill",
                  rule: "累计完成 10 项不同的创作", progress: Double(creativeWorks.count), target: 10, unit: "项"),
            badge("life-skill-first", module: .lifeSkills, title: "生活能手", symbol: "lightbulb.fill",
                  rule: "记录掌握的第一项生活技能", progress: Double(masteredLifeSkills.count), target: 1, unit: "项"),
            badge("life-skill-ten", module: .lifeSkills, title: "十项生活技能", symbol: "checkmark.seal.fill",
                  rule: "累计掌握 10 项不同的生活技能", progress: Double(masteredLifeSkills.count), target: 10, unit: "项"),
            badge("wellness-first", module: .wellness, title: "照顾自己的第一步", symbol: "cross.case.fill",
                  rule: "记录第一次健康维护行动", progress: Double(wellnessCount), target: 1, unit: "次"),
            badge("wellness-ten", module: .wellness, title: "十次健康行动", symbol: "heart.fill",
                  rule: "累计记录 10 次健康维护行动", progress: Double(wellnessCount), target: 10, unit: "次"),
            badge("experience-first", module: .experiences, title: "生活初体验", symbol: "sparkles",
                  rule: "记录第一次特别的生活体验", progress: Double(experienceCount), target: 1, unit: "次"),
            badge("experience-ten", module: .experiences, title: "十段体验记忆", symbol: "ticket.fill",
                  rule: "累计记录 10 次生活体验", progress: Double(experienceCount), target: 10, unit: "次"),
            badge("pet-first", module: .pets, title: "相伴的开始", symbol: "pawprint.fill",
                  rule: "记录第一段宠物时光", progress: Double(petMomentCount), target: 1, unit: "次"),
            badge("pet-ten", module: .pets, title: "十段相伴时光", symbol: "heart.text.square.fill",
                  rule: "累计记录 10 段宠物时光", progress: Double(petMomentCount), target: 10, unit: "次"),
            badge("challenge-first", module: .challenges, title: "挑战者", symbol: "flag.checkered",
                  rule: "完成并记录第一项个人挑战", progress: Double(completedChallenges.count), target: 1, unit: "项"),
            badge("challenge-ten", module: .challenges, title: "十项挑战达成", symbol: "medal.fill",
                  rule: "完成 10 项不同的个人挑战", progress: Double(completedChallenges.count), target: 10, unit: "项"),
            badge("relationship-first", module: .relationships, title: "重要关系的开始", symbol: "person.2.fill",
                  rule: "记录第一段珍贵的人际时刻", progress: Double(relationshipCount), target: 1, unit: "段"),
            badge("relationship-ten", module: .relationships, title: "十段关系记忆", symbol: "heart.fill",
                  rule: "累计记录 10 段人际时刻", progress: Double(relationshipCount), target: 10, unit: "段"),
            badge("living-first", module: .assets, title: "第一项人生资产", symbol: "house.fill",
                  rule: "记录第一个不同的居住或交通工具资产", progress: Double(assetMilestones.count), target: 1, unit: "项"),
            badge("living-ten", module: .assets, title: "十项人生资产", symbol: "key.fill",
                  rule: "记录 10 项不同的居住或私人交通工具资产", progress: Double(assetMilestones.count), target: 10, unit: "项"),
            badge("finance-first", module: .finance, title: "财务目标起点", symbol: "chart.line.uptrend.xyaxis",
                  rule: "创建第一个储蓄或还债目标", progress: Double(financialMilestones.count), target: 1, unit: "项"),
            badge("finance-ten", module: .finance, title: "十个财务目标", symbol: "medal.fill",
                  rule: "记录 10 个不同的储蓄或还债目标", progress: Double(financialMilestones.count), target: 10, unit: "项"),
            badge("finance-quarter", module: .finance, title: "目标走过四分之一", symbol: "chart.bar.fill",
                  rule: "任一财务目标达到 25%", progress: financeProgressByGoal.values.max().map { $0 * 100 } ?? 0, target: 25, unit: "%"),
            badge("finance-complete", module: .finance, title: "财务目标达成", symbol: "checkmark.seal.fill",
                  rule: "完成任一储蓄或还债目标", progress: financeProgressByGoal.values.max().map { $0 * 100 } ?? 0, target: 100, unit: "%")
        ]

        for (key, entry) in rereadBooks.sorted(by: { $0.value.date < $1.value.date }) {
            result.append(badge(
                "reread-\(key)", module: .learning, title: AppLanguage.format("旧书新读 · %@", entry.title),
                symbol: "arrow.triangle.2.circlepath", rule: AppLanguage.format("再次读完《%@》", entry.title),
                progress: 1, target: 1, unit: "次",
                repeatRule: "同一本书首次重读解锁一次；重读不增加书籍 XP"
            ))
        }
        return result
    }
}
