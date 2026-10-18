import Foundation

struct RewardImpact {
    let title: String
    let detail: String
}

enum GameEngine {
    static let scoringVersion = "试行规则 1.0"
    static let financeMilestoneThresholds: [Double] = [0.25, 0.5, 0.75, 1]

    static func normalized(_ value: String?) -> String {
        (value ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
    }

    static func totalSteps(_ days: [HealthStepDay]) -> Int {
        days.reduce(0) { $0 + max(0, $1.count) }
    }

    static func financeGoalKey(for entry: LifeEntry) -> String? {
        guard entry.kind == .financialMilestone else { return nil }
        let title = normalized(entry.title)
        guard !title.isEmpty else { return nil }
        let targetKey = entry.financeTargetValue.map { String($0.bitPattern) } ?? "legacy"
        return "\(entry.financeGoalType?.rawValue ?? "legacy")|\(title)|\(targetKey)"
    }

    static func careerMilestoneKey(for entry: LifeEntry) -> String? {
        guard entry.kind == .careerMilestone else { return nil }
        let title = normalized(entry.title)
        guard !title.isEmpty else { return nil }
        guard let choice = CareerMilestoneChoice(rawValue: entry.stage ?? "") else { return title }
        let company = normalized(entry.careerCompany)
        let position = normalized(entry.careerPosition)
        if choice == .other {
            return "other|\(company)|\(position)|\(title)"
        }
        return "\(choice.rawValue)|\(company)|\(position)|\(normalized(entry.careerDetail))"
    }

    static func assetMilestoneKey(for entry: LifeEntry) -> String? {
        let title = normalized(entry.title)
        guard !title.isEmpty else { return nil }
        switch entry.kind {
        case .livingMilestone:
            return "living|\(title)"
        case .vehicleMilestone:
            return "vehicle|\(entry.vehicleType?.rawValue ?? VehicleType.other.rawValue)|\(title)"
        default:
            return nil
        }
    }

    static func assetMilestoneCount(_ entries: [LifeEntry]) -> Int {
        Set(entries.compactMap(assetMilestoneKey(for:))).count
    }

    static func financeProgressByGoal(_ entries: [LifeEntry]) -> [String: Double] {
        var result: [String: Double] = [:]
        for entry in entries where entry.kind == .financialMilestone {
            guard let key = financeGoalKey(for: entry), let progress = entry.financeProgress else { continue }
            result[key] = max(result[key] ?? 0, progress)
        }
        return result
    }

    static func financeGoalCount(_ entries: [LifeEntry]) -> Int {
        Set(entries.compactMap(financeGoalKey(for:))).count
    }

    static func financeProgressMilestoneCount(_ entries: [LifeEntry]) -> Int {
        financeProgressByGoal(entries).values.reduce(0) { count, progress in
            count + financeMilestoneThresholds.filter { progress >= $0 }.count
        }
    }

    static func xpByModule(_ entries: [LifeEntry], stepDays: [HealthStepDay] = []) -> [LifeModule: Int] {
        var result = Dictionary(uniqueKeysWithValues: LifeModule.allCases.map { ($0, 0) })
        var sawHalf = false
        var sawFull = false
        var longestRun = 0.0
        var books = Set<String>()
        var sports = Set<String>()
        var cities = Set<String>()
        var countries = Set<String>()
        var degrees = Set<String>()
        var certificates = Set<String>()
        var languages = Set<String>()
        var careerMilestones = Set<String>()
        var creativeWorks = Set<String>()
        var lifeSkills = Set<String>()
        var completedChallenges = Set<String>()
        var assetMilestones = Set<String>()
        var financeProgressByGoal: [String: Double] = [:]
        var legacyFinancialMilestones = Set<String>()

        for entry in entries.sorted(by: { $0.date < $1.date }) {
            switch entry.kind {
            case .run:
                let km = max(0, entry.distanceKM ?? 0)
                var xp = Int((km * 10).rounded())
                if km >= 21.0975 && !sawHalf { xp += 200; sawHalf = true }
                if km >= 42.195 && !sawFull { xp += 500; sawFull = true }
                if longestRun >= 5 && km >= longestRun + 1 { xp += 60 }
                longestRun = max(longestRun, km)
                result[.exercise, default: 0] += xp
            case .cycling:
                result[.exercise, default: 0] += Int((max(0, entry.distanceKM ?? 0) * 3).rounded())
            case .learnedSport:
                let key = normalized(entry.title)
                if !key.isEmpty && sports.insert(key).inserted {
                    result[.exercise, default: 0] += 200
                }
            case .finishedBook:
                let key = normalized(entry.title) + "|" + normalized(entry.author)
                if !normalized(entry.title).isEmpty && books.insert(key).inserted {
                    result[.learning, default: 0] += 100
                }
            case .degree:
                let key = normalized(entry.title)
                if !key.isEmpty && degrees.insert(key).inserted {
                    result[.learning, default: 0] += 200
                }
            case .certificate:
                let key = normalized(entry.title)
                if !key.isEmpty && certificates.insert(key).inserted {
                    result[.learning, default: 0] += 100
                }
            case .languageMilestone:
                let key = normalized(entry.title) + "|" + normalized(entry.stage)
                if !normalized(entry.title).isEmpty && !normalized(entry.stage).isEmpty && languages.insert(key).inserted {
                    result[.learning, default: 0] += 100
                }
            case .trip:
                var xp = 0
                let city = normalized(entry.city)
                let country = normalized(entry.country)
                if !city.isEmpty && cities.insert(country + "|" + city).inserted { xp += 120 }
                if !country.isEmpty && countries.insert(country).inserted { xp += 300 }
                if entry.tripMode == .train || entry.tripMode == .flight {
                    let km = max(0, entry.distanceKM ?? 0)
                    let rate = entry.tripMode == .train ? 0.1 : 0.03
                    xp += 20 + Int((km * rate).rounded())
                }
                result[.travel, default: 0] += min(xp, 400)
            case .kindness:
                if !entry.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    result[.love, default: 0] += 50
                }
            case .bloodDonation:
                if (entry.amountML ?? 0) > 0 { result[.love, default: 0] += 50 }
            case .familyMoment:
                if !entry.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    result[.family, default: 0] += 50
                }
            case .careerMilestone:
                let key = careerMilestoneKey(for: entry) ?? ""
                if !key.isEmpty && careerMilestones.insert(key).inserted {
                    result[.career, default: 0] += 50
                }
            case .creativeWork:
                let key = normalized(entry.title)
                if !key.isEmpty && creativeWorks.insert(key).inserted {
                    result[.creation, default: 0] += 100
                }
            case .lifeSkill:
                let key = normalized(entry.title)
                if !key.isEmpty && lifeSkills.insert(key).inserted {
                    result[.lifeSkills, default: 0] += 100
                }
            case .wellnessAction:
                if !entry.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    result[.wellness, default: 0] += 50
                }
            case .lifeExperience:
                if !entry.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    result[.experiences, default: 0] += 50
                }
            case .petMoment:
                if !entry.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    result[.pets, default: 0] += 50
                }
            case .completedChallenge:
                let key = normalized(entry.title)
                if !key.isEmpty && completedChallenges.insert(key).inserted {
                    result[.challenges, default: 0] += 100
                }
            case .relationshipMoment:
                if !entry.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    result[.relationships, default: 0] += 50
                }
            case .livingMilestone:
                let key = assetMilestoneKey(for: entry) ?? ""
                if !key.isEmpty && assetMilestones.insert(key).inserted {
                    result[.assets, default: 0] += 100
                }
            case .vehicleMilestone:
                let key = assetMilestoneKey(for: entry) ?? ""
                if !key.isEmpty && assetMilestones.insert(key).inserted {
                    result[.assets, default: 0] += 100
                }
            case .financialMilestone:
                guard let key = financeGoalKey(for: entry), !normalized(entry.title).isEmpty else { break }
                if let progress = entry.financeProgress, entry.financeGoalType != nil {
                    financeProgressByGoal[key] = max(financeProgressByGoal[key] ?? 0, progress)
                } else if legacyFinancialMilestones.insert(key).inserted {
                    result[.finance, default: 0] += 100
                }
            }
        }
        let reachedFinanceMilestones = financeProgressByGoal.values.reduce(0) { count, progress in
            count + financeMilestoneThresholds.filter { progress >= $0 }.count
        }
        result[.finance, default: 0] += reachedFinanceMilestones * 50
        result[.exercise, default: 0] += totalSteps(stepDays) / 1_000
        return result
    }

    static func threshold(for level: Int) -> Int {
        guard level > 1 else { return 0 }
        return Int((50 * pow(Double(level - 1), 1.6)).rounded())
    }

    static func moduleLevel(for xp: Int) -> Int {
        var level = 1
        while threshold(for: level + 1) <= xp { level += 1 }
        return level
    }

    static func totalLevel(_ moduleLevels: [LifeModule: Int]) -> Int {
        let weightedScore = LifeModule.allCases.reduce(0.0) {
            $0 + sqrt(Double(max(0, (moduleLevels[$1] ?? 1) - 1)))
        }
        return 1 + Int(floor(weightedScore))
    }

    static func totalProgress(_ moduleLevels: [LifeModule: Int]) -> Double {
        let score = LifeModule.allCases.reduce(0.0) {
            $0 + sqrt(Double(max(0, (moduleLevels[$1] ?? 1) - 1)))
        }
        return score - floor(score)
    }

    static func uniqueBooks(_ entries: [LifeEntry]) -> [LifeEntry] {
        var seen = Set<String>()
        return entries.filter { $0.kind == .finishedBook }
            .sorted { $0.date < $1.date }
            .filter { seen.insert(normalized($0.title) + "|" + normalized($0.author)).inserted }
    }

    static func rewardImpact(for entry: LifeEntry, previousEntries: [LifeEntry]) -> RewardImpact {
        switch entry.kind {
        case .run:
            let before = previousEntries.filter { $0.kind == .run }
                .reduce(0.0) { $0 + max(0, $1.distanceKM ?? 0) }
            let after = before + max(0, entry.distanceKM ?? 0)
            return RewardImpact(
                title: AppLanguage.localized("跑步里程继续延伸"),
                detail: AppLanguage.format("累计跑步 %.1f → %.1f 公里", before, after)
            )
        case .cycling:
            let before = previousEntries.filter { $0.kind == .cycling }
                .reduce(0.0) { $0 + max(0, $1.distanceKM ?? 0) }
            let after = before + max(0, entry.distanceKM ?? 0)
            return RewardImpact(
                title: AppLanguage.localized("骑行里程继续延伸"),
                detail: AppLanguage.format("累计骑行 %.1f → %.1f 公里", before, after)
            )
        case .learnedSport:
            let repeated = previousEntries.contains {
                $0.kind == .learnedSport && normalized($0.title) == normalized(entry.title)
            }
            return RewardImpact(
                title: repeated ? AppLanguage.localized("运动经历已归档") : AppLanguage.format("运动图鉴点亮「%@」", entry.title),
                detail: AppLanguage.localized(repeated ? "这项运动已经获得过首次学会奖励" : "学会一项新运动")
            )
        case .finishedBook:
            let repeated = previousEntries.contains {
                $0.kind == .finishedBook && normalized($0.title) == normalized(entry.title)
                    && normalized($0.author) == normalized(entry.author)
            }
            return RewardImpact(
                title: repeated ? AppLanguage.format("重读《%@》已归档", entry.title) : AppLanguage.format("人生书架点亮《%@》", entry.title),
                detail: AppLanguage.localized(repeated ? "重读会留下记录和徽章，不重复获得书籍经验" : "一本新书进入你的人生书架")
            )
        case .degree:
            return RewardImpact(title: AppLanguage.format("学历已记录：%@", entry.title), detail: AppLanguage.localized("取得学历日期已加入学习档案"))
        case .certificate:
            return RewardImpact(title: AppLanguage.format("证书已记录：%@", entry.title), detail: AppLanguage.localized("证书及取得日期已加入学习档案"))
        case .languageMilestone:
            return RewardImpact(
                title: AppLanguage.format("语言进阶：%@", entry.title),
                detail: AppLanguage.format("达到 %@ 水平，已加入学习档案", entry.stage ?? "")
            )
        case .trip:
            let city = normalized(entry.city)
            let country = normalized(entry.country)
            let newCity = !city.isEmpty && !previousEntries.contains {
                $0.kind == .trip && normalized($0.city) == city && normalized($0.country) == country
            }
            let newCountry = !country.isEmpty && !previousEntries.contains {
                $0.kind == .trip && normalized($0.country) == country
            }
            let places = [newCity ? entry.city : nil, newCountry ? entry.country : nil]
                .compactMap { $0 }.joined(separator: " · ")
            if !places.isEmpty {
                return RewardImpact(title: AppLanguage.format("旅行足迹点亮%@", places), detail: AppLanguage.localized("新的到访地点已加入人生档案"))
            }
            return RewardImpact(title: AppLanguage.localized("这段旅程已归档"), detail: AppLanguage.localized("重访会保留行程，地点不重复解锁"))
        case .kindness:
            return RewardImpact(title: AppLanguage.localized("善意已记录"), detail: AppLanguage.format("%@成为你的人生印记", entry.title))
        case .bloodDonation:
            let amount = entry.amountML ?? 0
            let before = previousEntries.filter { $0.kind == .bloodDonation }.count
            return RewardImpact(
                title: AppLanguage.localized("献血经历已记录"),
                detail: AppLanguage.format("本次 %d 毫升 · 累计第 %d 次", amount, before + 1)
            )
        case .familyMoment:
            return RewardImpact(title: AppLanguage.localized("家庭经历已记录"), detail: AppLanguage.format("%@成为你的人生印记", entry.title))
        case .careerMilestone:
            let repeated = previousEntries.contains {
                careerMilestoneKey(for: $0) == careerMilestoneKey(for: entry)
            }
            return RewardImpact(
                title: AppLanguage.localized(repeated ? "职业里程碑已归档" : "职业里程碑已记录"),
                detail: AppLanguage.localized(repeated ? "相同里程碑会保留记录，不重复获得经验" : "职业中的重要节点已加入人生档案")
            )
        case .creativeWork:
            let repeated = previousEntries.contains { $0.kind == .creativeWork && normalized($0.title) == normalized(entry.title) }
            return RewardImpact(
                title: AppLanguage.localized(repeated ? "作品已归档" : "创作已记录"),
                detail: AppLanguage.localized(repeated ? "相同作品会保留记录，不重复获得经验" : "一项新的创作已加入人生作品集")
            )
        case .lifeSkill:
            let repeated = previousEntries.contains { $0.kind == .lifeSkill && normalized($0.title) == normalized(entry.title) }
            return RewardImpact(
                title: AppLanguage.localized(repeated ? "技能记录已归档" : "新技能已记录"),
                detail: AppLanguage.localized(repeated ? "相同技能会保留记录，不重复获得经验" : "你已掌握一项新的生活技能")
            )
        case .wellnessAction:
            return RewardImpact(title: AppLanguage.localized("健康行动已记录"), detail: AppLanguage.localized("一次健康维护行动已加入个人档案"))
        case .lifeExperience:
            return RewardImpact(title: AppLanguage.localized("体验已记录"), detail: AppLanguage.format("%@成为你的人生印记", entry.title))
        case .petMoment:
            let subject = entry.stage?.isEmpty == false ? entry.stage! : AppLanguage.localized("宠物")
            return RewardImpact(title: AppLanguage.localized("宠物时刻已记录"), detail: AppLanguage.format("%@：%@", subject, entry.title))
        case .completedChallenge:
            let repeated = previousEntries.contains { $0.kind == .completedChallenge && normalized($0.title) == normalized(entry.title) }
            return RewardImpact(
                title: AppLanguage.localized(repeated ? "挑战已归档" : "挑战完成"),
                detail: AppLanguage.localized(repeated ? "相同挑战保留记录，不重复获得经验" : "一次个人挑战已完成并加入人生档案")
            )
        case .relationshipMoment:
            return RewardImpact(title: AppLanguage.localized("关系时刻已记录"), detail: AppLanguage.localized("一段珍贵的人际经历已加入人生印记"))
        case .livingMilestone:
            let repeated = previousEntries.contains { $0.kind == .livingMilestone && normalized($0.title) == normalized(entry.title) }
            return RewardImpact(title: AppLanguage.localized(repeated ? "居住节点已归档" : "居住里程碑已记录"), detail: AppLanguage.localized(repeated ? "相同居住里程碑保留记录，不重复获得经验" : "生活空间与居住阶段的变化已记录"))
        case .vehicleMilestone:
            let key = assetMilestoneKey(for: entry)
            let repeated = previousEntries.contains { assetMilestoneKey(for: $0) == key }
            return RewardImpact(
                title: AppLanguage.localized(repeated ? "交通工具已归档" : "私人交通工具已登记"),
                detail: AppLanguage.localized(repeated ? "相同交通工具保留记录，不重复获得经验" : "一项新的私人交通工具资产已加入档案")
            )
        case .financialMilestone:
            guard let current = entry.financeProgress, let key = financeGoalKey(for: entry) else {
                let repeated = previousEntries.contains { $0.kind == .financialMilestone && normalized($0.title) == normalized(entry.title) }
                return RewardImpact(title: AppLanguage.localized(repeated ? "财务节点已归档" : "财务里程碑已记录"), detail: AppLanguage.localized(repeated ? "相同财务里程碑保留记录，不重复获得经验" : "个人财务进展已记录，不需要填写金额"))
            }
            let before = financeProgressByGoal(previousEntries)[key] ?? 0
            let after = max(before, current)
            let crossed = financeMilestoneThresholds.filter { $0 > before && $0 <= after }.count
            let progressText = "\(Int((after * 100).rounded()))%"
            let detail = crossed > 0
                ? AppLanguage.format("目标当前进度 %@，本次跨过 %d 个阶段", progressText, crossed)
                : AppLanguage.format("目标当前进度 %@；同一阶段不会重复计分", progressText)
            return RewardImpact(title: AppLanguage.localized("财务目标进度已更新"), detail: detail)
        }
    }

    static func nextMilestone(for module: LifeModule, entries: [LifeEntry]) -> String {
        switch module {
        case .exercise:
            let runs = entries.filter { $0.kind == .run }.map { $0.distanceKM ?? 0 }
            if !runs.contains(where: { $0 >= 21.0975 }) { return AppLanguage.localized("单次跑步达到半马距离，解锁半马成就") }
            if !runs.contains(where: { $0 >= 42.195 }) { return AppLanguage.localized("单次跑步达到全马距离，解锁全马成就") }
            return AppLanguage.localized("继续跑步、骑行，或学会一项新的运动")
        case .learning:
            return AppLanguage.localized("继续阅读，或记录新的学历与证书")
        case .travel:
            return AppLanguage.localized("到访一座新城市或一个新国家，点亮旅行足迹")
        case .love:
            let donations = entries.filter { $0.kind == .bloodDonation }.count
            if donations == 0 { return AppLanguage.localized("记录第一次献血，点亮献血徽章") }
            if donations < 10 { return AppLanguage.format("再记录 %d 次献血，解锁十次献血徽章", 10 - donations) }
            let acts = entries.filter { $0.kind == .kindness }.count
            return AppLanguage.format("记录善行达到 %d 次，解锁爱心徽章", max(1, 10 - acts))
        case .family:
            return AppLanguage.localized("记录一次珍贵的家庭纪念日或共同经历")
        case .career:
            let milestones = Set(entries.compactMap(careerMilestoneKey)).count
            if milestones < 10 {
                return AppLanguage.format("再记录 %d 个不同的职业里程碑，解锁十次徽章", 10 - milestones)
            }
            return AppLanguage.localized("继续记录新的职业节点，丰富你的人生履历")
        case .creation:
            let count = Set(entries.filter { $0.kind == .creativeWork }.map { normalized($0.title) }.filter { !$0.isEmpty }).count
            return count < 10 ? AppLanguage.format("再完成 %d 项不同的创作，解锁创作徽章", 10 - count) : AppLanguage.localized("继续完成让你自豪的作品，丰富人生作品集")
        case .lifeSkills:
            let count = Set(entries.filter { $0.kind == .lifeSkill }.map { normalized($0.title) }.filter { !$0.isEmpty }).count
            return count < 10 ? AppLanguage.format("再掌握 %d 项不同的生活技能，解锁技能徽章", 10 - count) : AppLanguage.localized("继续学习实用技能，让生活能力不断升级")
        case .wellness:
            let count = entries.filter { $0.kind == .wellnessAction }.count
            return count < 10 ? AppLanguage.format("再记录 %d 次健康行动，解锁健康徽章", 10 - count) : AppLanguage.localized("继续照顾好自己，记录值得记住的健康进步")
        case .experiences:
            let count = entries.filter { $0.kind == .lifeExperience }.count
            return count < 10 ? AppLanguage.format("再记录 %d 次生活体验，解锁体验徽章", 10 - count) : AppLanguage.localized("继续走进展览、演出和新的生活现场")
        case .pets:
            let count = entries.filter { $0.kind == .petMoment }.count
            return count < 10 ? AppLanguage.format("再记录 %d 段宠物时光，解锁陪伴徽章", 10 - count) : AppLanguage.localized("继续收藏与你的宠物共同度过的时光")
        case .challenges:
            let count = Set(entries.filter { $0.kind == .completedChallenge }.map { normalized($0.title) }.filter { !$0.isEmpty }).count
            return count < 10 ? AppLanguage.format("再完成 %d 项不同挑战，解锁挑战徽章", 10 - count) : AppLanguage.localized("继续完成自己设定的挑战")
        case .relationships:
            let count = entries.filter { $0.kind == .relationshipMoment }.count
            return count < 10 ? AppLanguage.format("再记录 %d 段关系时刻，解锁关系徽章", 10 - count) : AppLanguage.localized("继续珍藏与重要的人共同经历的时刻")
        case .assets:
            let count = assetMilestoneCount(entries)
            return count < 10 ? AppLanguage.format("再记录 %d 项不同资产，解锁资产徽章", 10 - count) : AppLanguage.localized("继续记录居住经历和私人交通工具")
        case .finance:
            let goals = Dictionary(grouping: entries.filter { $0.kind == .financialMilestone && $0.financeProgress != nil }, by: { financeGoalKey(for: $0) ?? "" })
                .compactMap { key, values -> (String, Double)? in
                    guard !key.isEmpty, let title = values.first?.title else { return nil }
                    return (title, values.compactMap(\.financeProgress).max() ?? 0)
                }
                .sorted { $0.1 > $1.1 }
            if let (title, progress) = goals.first(where: { $0.1 < 1 }) {
                let next = financeMilestoneThresholds.first(where: { $0 > progress }) ?? 1
                return AppLanguage.format("继续记录「%@」进度，当前 %@，下一档 %@", title, "\(Int(progress * 100))%", "\(Int(next * 100))%")
            }
            return AppLanguage.localized(goals.isEmpty ? "新建一个储蓄或还债目标，记录目标金额与当前进度" : "设定下一个储蓄或还债目标，继续记录阶段进展")
        }
    }

    static func goalProgress(_ goal: PersonalGoal, entries: [LifeEntry]) -> Double {
        switch goal.metric {
        case .runningKM:
            return entries.filter { $0.kind == .run }.reduce(0) { $0 + max(0, $1.distanceKM ?? 0) }
        case .books:
            return Double(uniqueBooks(entries).count)
        case .cities:
            return Double(Set(entries.filter { $0.kind == .trip && !normalized($0.city).isEmpty }
                .map { normalized($0.country) + "|" + normalized($0.city) }).count)
        case .countries:
            return Double(Set(entries.filter { $0.kind == .trip }.map { normalized($0.country) }.filter { !$0.isEmpty }).count)
        case .sports:
            return Double(Set(entries.filter { $0.kind == .learnedSport }.map { normalized($0.title) }.filter { !$0.isEmpty }).count)
        case .trips:
            return Double(entries.filter { $0.kind == .trip && ($0.tripMode == .train || $0.tripMode == .flight) }.count)
        case .kindness:
            return Double(entries.filter { $0.kind == .kindness }.count)
        }
    }

    static func achievements(entries: [LifeEntry], profile: LifeProfile, goals: [PersonalGoal] = []) -> [Achievement] {
        let ordered = entries.sorted { $0.date < $1.date }
        var result: [Achievement] = []
        var half = false
        var full = false
        var seenBooks = Set<String>()
        var authorCounts: [String: Int] = [:]
        var sports = Set<String>()
        var cities = Set<String>()
        var countries = Set<String>()
        var kindnessCount = 0

        for entry in ordered {
            switch entry.kind {
            case .run:
                let km = entry.distanceKM ?? 0
                if km >= 21.0975 && !half {
                    result.append(Achievement(id: "half", title: AppLanguage.localized("半马解锁"), detail: AppLanguage.localized("单次跑步达到半马距离"), symbol: "figure.run.circle.fill", date: entry.date))
                    half = true
                }
                if km >= 42.195 && !full {
                    result.append(Achievement(id: "full", title: AppLanguage.localized("全马解锁"), detail: AppLanguage.localized("单次跑步达到全马距离"), symbol: "medal.fill", date: entry.date))
                    full = true
                }
            case .cycling:
                break
            case .learnedSport:
                let key = normalized(entry.title)
                if !key.isEmpty && sports.insert(key).inserted {
                    result.append(Achievement(id: "sport-\(key)", title: AppLanguage.format("解锁 %@", entry.title), detail: AppLanguage.localized("掌握一项新运动"), symbol: "figure.mixed.cardio", date: entry.date))
                }
            case .finishedBook:
                let key = normalized(entry.title) + "|" + normalized(entry.author)
                guard seenBooks.insert(key).inserted else {
                    result.append(Achievement(id: "reread-\(entry.id)", title: AppLanguage.format("重读《%@》", entry.title), detail: AppLanguage.localized("再读一次，也有新的收获"), symbol: "arrow.triangle.2.circlepath", date: entry.date))
                    continue
                }
                result.append(Achievement(id: "book-\(key)", title: AppLanguage.format("读完《%@》", entry.title), detail: AppLanguage.localized("一本书进入人生书架"), symbol: "books.vertical.fill", date: entry.date))
                let author = normalized(entry.author)
                if !author.isEmpty {
                    authorCounts[author, default: 0] += 1
                    let count = authorCounts[author, default: 0]
                    if [1, 3, 5].contains(count) {
                        result.append(Achievement(id: "author-\(author)-\(count)", title: AppLanguage.format("%@探索者 · %d", entry.author ?? AppLanguage.localized("作者"), count), detail: AppLanguage.format("读完同一作者的 %d 本书", count), symbol: "person.crop.square.filled.and.at.rectangle", date: entry.date))
                    }
                }
            case .degree:
                result.append(Achievement(
                    id: "degree-\(entry.id)",
                    title: AppLanguage.format("取得%@", entry.title),
                    detail: AppLanguage.localized("学历里程碑"),
                    symbol: "graduationcap.fill",
                    date: entry.date
                ))
            case .certificate:
                result.append(Achievement(
                    id: "certificate-\(entry.id)",
                    title: AppLanguage.format("取得证书：%@", entry.title),
                    detail: AppLanguage.localized("证书里程碑"),
                    symbol: "checkmark.seal.fill",
                    date: entry.date
                ))
            case .languageMilestone:
                result.append(Achievement(
                    id: "language-\(entry.id)",
                    title: AppLanguage.format("%@ · %@", entry.title, entry.stage ?? ""),
                    detail: AppLanguage.localized("语言学习里程碑"),
                    symbol: "character.book.closed.fill",
                    date: entry.date
                ))
            case .trip:
                let city = normalized(entry.city)
                let country = normalized(entry.country)
                if !city.isEmpty && cities.insert(country + "|" + city).inserted {
                    result.append(Achievement(id: "city-\(country)-\(city)", title: AppLanguage.format("解锁 %@", entry.city ?? AppLanguage.localized("城市")), detail: AppLanguage.localized("实际到达一座新城市"), symbol: "mappin.and.ellipse", date: entry.date))
                }
                if !country.isEmpty && countries.insert(country).inserted {
                    result.append(Achievement(id: "country-\(country)", title: AppLanguage.format("解锁 %@", entry.country ?? AppLanguage.localized("国家")), detail: AppLanguage.localized("实际到达一个新国家"), symbol: "globe.asia.australia.fill", date: entry.date))
                }
            case .kindness:
                kindnessCount += 1
                if kindnessCount == 1 || kindnessCount == 10 {
                    result.append(Achievement(
                        id: "kindness-\(kindnessCount)",
                        title: AppLanguage.format("善意行动 · %d 次", kindnessCount),
                        detail: AppLanguage.localized("持续为他人带来帮助"),
                        symbol: "heart.fill",
                        date: entry.date
                    ))
                }
            case .bloodDonation:
                result.append(Achievement(
                    id: "blood-donation-\(entry.id)",
                    title: AppLanguage.format("献血 · %d 毫升", entry.amountML ?? 0),
                    detail: AppLanguage.localized("记录一次献血经历"),
                    symbol: "drop.fill",
                    date: entry.date
                ))
            case .familyMoment:
                result.append(Achievement(
                    id: "family-\(entry.id)",
                    title: AppLanguage.format("家庭：%@", entry.title),
                    detail: AppLanguage.localized("家庭纪念日与共同经历"),
                    symbol: "figure.2.and.child.holdinghands",
                    date: entry.date
                ))
            case .careerMilestone:
                result.append(Achievement(
                    id: "career-\(entry.id)",
                    title: AppLanguage.format("职业里程碑：%@", entry.title),
                    detail: AppLanguage.localized("职业中的重要节点已记录"),
                    symbol: "briefcase.fill",
                    date: entry.date
                ))
            case .creativeWork:
                result.append(Achievement(
                    id: "creation-\(entry.id)",
                    title: AppLanguage.format("创作：%@", entry.title),
                    detail: AppLanguage.localized("完成一项创作并加入人生作品集"),
                    symbol: "paintpalette.fill",
                    date: entry.date
                ))
            case .lifeSkill:
                result.append(Achievement(
                    id: "life-skill-\(entry.id)",
                    title: AppLanguage.format("掌握技能：%@", entry.title),
                    detail: AppLanguage.localized("已掌握一项新的生活技能"),
                    symbol: "lightbulb.fill",
                    date: entry.date
                ))
            case .wellnessAction:
                result.append(Achievement(id: "wellness-\(entry.id)", title: AppLanguage.format("健康行动：%@", entry.title), detail: AppLanguage.localized("记录一次健康维护行动"), symbol: "cross.case.fill", date: entry.date))
            case .lifeExperience:
                result.append(Achievement(id: "experience-\(entry.id)", title: AppLanguage.format("体验：%@", entry.title), detail: AppLanguage.localized("一次生活体验已加入人生印记"), symbol: "sparkles", date: entry.date))
            case .petMoment:
                let subject = entry.stage?.isEmpty == false ? entry.stage! : AppLanguage.localized("宠物")
                result.append(Achievement(id: "pet-\(entry.id)", title: AppLanguage.format("%@：%@", subject, entry.title), detail: AppLanguage.localized("与你的宠物共同度过的时刻"), symbol: "pawprint.fill", date: entry.date))
            case .completedChallenge:
                result.append(Achievement(id: "challenge-\(entry.id)", title: AppLanguage.format("挑战完成：%@", entry.title), detail: AppLanguage.localized("一次个人挑战已完成"), symbol: "flag.checkered", date: entry.date))
            case .relationshipMoment:
                result.append(Achievement(id: "relationship-\(entry.id)", title: AppLanguage.format("关系：%@", entry.title), detail: AppLanguage.localized("一段珍贵的人际经历已记录"), symbol: "person.2.fill", date: entry.date))
            case .livingMilestone:
                result.append(Achievement(id: "living-\(entry.id)", title: AppLanguage.format("居住：%@", entry.title), detail: AppLanguage.localized("生活空间与居住阶段的变化"), symbol: "house.fill", date: entry.date))
            case .vehicleMilestone:
                let vehicle = entry.vehicleType?.title ?? AppLanguage.localized("私人交通工具")
                result.append(Achievement(id: "vehicle-\(entry.id)", title: AppLanguage.format("%@：%@", vehicle, entry.title), detail: AppLanguage.localized("私人交通工具已加入资产档案"), symbol: "car.side.fill", date: entry.date))
            case .financialMilestone:
                result.append(Achievement(id: "finance-\(entry.id)", title: AppLanguage.format("财务：%@", entry.title), detail: AppLanguage.localized("个人财务里程碑已记录"), symbol: "chart.line.uptrend.xyaxis", date: entry.date))
            }
        }
        if !profile.education.isEmpty, let date = profile.graduationDate {
            result.append(Achievement(id: "education", title: AppLanguage.format("%@里程碑", profile.education), detail: AppLanguage.localized("人生履历"), symbol: "graduationcap.fill", date: date))
        }
        if let birthDate = profile.birthDate {
            for age in [18, 20, 30, 40, 50, 60, 70, 80, 90, 100] {
                if let date = Calendar.current.date(byAdding: .year, value: age, to: birthDate), date <= Date() {
                    result.append(Achievement(id: "age-\(age)", title: AppLanguage.format("%d 岁人生里程碑", age), detail: AppLanguage.localized("继续解锁新的篇章"), symbol: "birthday.cake.fill", date: date))
                }
            }
        }
        if profile.hasDriversLicense,
           let date = profile.licenseDate,
           let birthDate = profile.birthDate,
           (Calendar.current.dateComponents([.year], from: birthDate, to: date).year ?? 0) >= 18 {
            result.append(Achievement(id: "drivers-license", title: AppLanguage.localized("取得驾照"), detail: AppLanguage.localized("解锁新的出行方式"), symbol: "car.fill", date: date))
        }
        for goal in goals {
            if let firstCompletedIndex = ordered.indices.first(where: {
                goalProgress(goal, entries: Array(ordered.prefix($0 + 1))) >= goal.target
            }) {
                result.append(Achievement(
                    id: "goal-\(goal.id)",
                    title: AppLanguage.format("目标达成：%@", goal.title),
                    detail: AppLanguage.localized("完成自己设定的人生目标"),
                    symbol: "target",
                    date: max(goal.createdAt, ordered[firstCompletedIndex].date)
                ))
            }
        }
        return result.sorted { $0.date > $1.date }
    }
}
