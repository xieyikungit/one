import Foundation

enum LifeModule: String, CaseIterable, Codable, Identifiable {
    case exercise, learning, travel, love, family, career, creation, lifeSkills, wellness, experiences, pets, challenges, relationships, assets = "living", finance

    var id: String { rawValue }
    var title: String {
        switch self {
        case .exercise: AppLanguage.localized("运动")
        case .learning: AppLanguage.localized("学习")
        case .travel: AppLanguage.localized("旅行")
        case .love: AppLanguage.localized("爱心")
        case .family: AppLanguage.localized("家庭")
        case .career: AppLanguage.localized("职业")
        case .creation: AppLanguage.localized("创作")
        case .lifeSkills: AppLanguage.localized("生活技能")
        case .wellness: AppLanguage.localized("健康")
        case .experiences: AppLanguage.localized("体验")
        case .pets: AppLanguage.localized("宠物")
        case .challenges: AppLanguage.localized("挑战")
        case .relationships: AppLanguage.localized("关系")
        case .assets: AppLanguage.localized("资产")
        case .finance: AppLanguage.localized("财务")
        }
    }
    var symbol: String {
        switch self {
        case .exercise: "figure.mixed.cardio"
        case .learning: "graduationcap.fill"
        case .travel: "globe.asia.australia.fill"
        case .love: "heart.fill"
        case .family: "figure.2.and.child.holdinghands"
        case .career: "briefcase.fill"
        case .creation: "paintpalette.fill"
        case .lifeSkills: "lightbulb.fill"
        case .wellness: "cross.case.fill"
        case .experiences: "sparkles"
        case .pets: "pawprint.fill"
        case .challenges: "flag.checkered"
        case .relationships: "person.2.fill"
        case .assets: "car.side.fill"
        case .finance: "chart.line.uptrend.xyaxis"
        }
    }
}

enum EntryKind: String, CaseIterable, Codable, Identifiable {
    case run, cycling, learnedSport, finishedBook, degree, certificate, languageMilestone, trip, kindness, bloodDonation, familyMoment, careerMilestone, creativeWork, lifeSkill, wellnessAction, lifeExperience, petMoment, completedChallenge, relationshipMoment, livingMilestone, financialMilestone, vehicleMilestone

    var id: String { rawValue }
    var title: String {
        switch self {
        case .run: AppLanguage.localized("一次跑步")
        case .cycling: AppLanguage.localized("一次骑行")
        case .learnedSport: AppLanguage.localized("学会一项运动")
        case .finishedBook: AppLanguage.localized("读完一本书")
        case .degree: AppLanguage.localized("学历")
        case .certificate: AppLanguage.localized("证书")
        case .languageMilestone: AppLanguage.localized("语言进阶")
        case .trip: AppLanguage.localized("一次旅行")
        case .kindness: AppLanguage.localized("一次善行")
        case .bloodDonation: AppLanguage.localized("一次献血")
        case .familyMoment: AppLanguage.localized("家庭经历")
        case .careerMilestone: AppLanguage.localized("职业里程碑")
        case .creativeWork: AppLanguage.localized("完成一项创作")
        case .lifeSkill: AppLanguage.localized("掌握一项生活技能")
        case .wellnessAction: AppLanguage.localized("完成一次健康行动")
        case .lifeExperience: AppLanguage.localized("记录一次生活体验")
        case .petMoment: AppLanguage.localized("记录一次宠物时刻")
        case .completedChallenge: AppLanguage.localized("完成一项个人挑战")
        case .relationshipMoment: AppLanguage.localized("记录一段关系时刻")
        case .livingMilestone: AppLanguage.localized("记录一个居住里程碑")
        case .financialMilestone: AppLanguage.localized("财务目标进度")
        case .vehicleMilestone: AppLanguage.localized("登记私人交通工具")
        }
    }
    var symbol: String {
        switch self {
        case .run: "figure.run"
        case .cycling: "bicycle"
        case .learnedSport: "figure.mixed.cardio"
        case .finishedBook: "books.vertical.fill"
        case .degree: "graduationcap.fill"
        case .certificate: "checkmark.seal.fill"
        case .languageMilestone: "character.book.closed.fill"
        case .trip: "globe.asia.australia.fill"
        case .kindness: "heart.fill"
        case .bloodDonation: "drop.fill"
        case .familyMoment: "figure.2.and.child.holdinghands"
        case .careerMilestone: "briefcase.fill"
        case .creativeWork: "paintpalette.fill"
        case .lifeSkill: "lightbulb.fill"
        case .wellnessAction: "cross.case.fill"
        case .lifeExperience: "sparkles"
        case .petMoment: "pawprint.fill"
        case .completedChallenge: "flag.checkered"
        case .relationshipMoment: "person.2.fill"
        case .livingMilestone: "house.fill"
        case .financialMilestone: "chart.line.uptrend.xyaxis"
        case .vehicleMilestone: "car.side.fill"
        }
    }
    var module: LifeModule {
        switch self {
        case .run, .cycling, .learnedSport: .exercise
        case .finishedBook, .degree, .certificate, .languageMilestone: .learning
        case .trip: .travel
        case .kindness, .bloodDonation: .love
        case .familyMoment: .family
        case .careerMilestone: .career
        case .creativeWork: .creation
        case .lifeSkill: .lifeSkills
        case .wellnessAction: .wellness
        case .lifeExperience: .experiences
        case .petMoment: .pets
        case .completedChallenge: .challenges
        case .relationshipMoment: .relationships
        case .livingMilestone, .vehicleMilestone: .assets
        case .financialMilestone: .finance
        }
    }
}

enum TripMode: String, CaseIterable, Codable, Identifiable {
    case visit, train, flight
    var id: String { rawValue }
    var title: String {
        switch self {
        case .visit: AppLanguage.localized("到访")
        case .train: AppLanguage.localized("高铁")
        case .flight: AppLanguage.localized("飞行")
        }
    }
}

enum VehicleType: String, CaseIterable, Codable, Identifiable {
    case car, electricCar, motorcycle, electricMotorcycle, scooter, electricBicycle, bicycle, camper, boat, other
    var id: String { rawValue }
    var title: String {
        switch self {
        // Keep the legacy raw value `car` so previously saved vehicle records still decode.
        case .car: AppLanguage.localized("汽油车")
        case .electricCar: AppLanguage.localized("新能源汽车")
        case .motorcycle: AppLanguage.localized("摩托车")
        case .electricMotorcycle: AppLanguage.localized("电动摩托车")
        case .scooter: AppLanguage.localized("电动滑板车")
        case .electricBicycle: AppLanguage.localized("电动自行车")
        case .bicycle: AppLanguage.localized("自行车")
        case .camper: AppLanguage.localized("房车")
        case .boat: AppLanguage.localized("船艇")
        case .other: AppLanguage.localized("其他交通工具")
        }
    }
}

enum FinanceGoalType: String, CaseIterable, Codable, Identifiable {
    case savings, debtRepayment
    var id: String { rawValue }
    var title: String {
        switch self {
        case .savings: AppLanguage.localized("储蓄目标")
        case .debtRepayment: AppLanguage.localized("偿还债务")
        }
    }
}

enum CareerMilestoneCategory: String, CaseIterable, Identifiable {
    case starting, growth, results, learning, recognition, transition, other

    var id: String { rawValue }
    var title: String {
        switch self {
        case .starting: AppLanguage.localized("求职与入职")
        case .growth: AppLanguage.localized("岗位与成长")
        case .results: AppLanguage.localized("项目与成果")
        case .learning: AppLanguage.localized("技能与资质")
        case .recognition: AppLanguage.localized("认可与影响")
        case .transition: AppLanguage.localized("转型与阶段")
        case .other: AppLanguage.localized("其他职业经历")
        }
    }
    var choices: [CareerMilestoneChoice] {
        CareerMilestoneChoice.allCases.filter { $0.category == self }
    }
}

enum CareerMilestoneChoice: String, CaseIterable, Identifiable {
    case firstInternship, firstJob, joinedCompany, passedProbation
    case promotion, roleChange, becameManager, ledTeam
    case completedProject, launchedProduct, achievedTarget, improvedProcess
    case completedTraining, earnedQualification, masteredProfessionalSkill
    case receivedAward, recognizedAtWork, publishedWork, invitedToSpeak
    case startedBusiness, changedIndustry, becameFreelancer, returnedToWork, retired
    case other

    var id: String { rawValue }
    var category: CareerMilestoneCategory {
        switch self {
        case .firstInternship, .firstJob, .joinedCompany, .passedProbation: .starting
        case .promotion, .roleChange, .becameManager, .ledTeam: .growth
        case .completedProject, .launchedProduct, .achievedTarget, .improvedProcess: .results
        case .completedTraining, .earnedQualification, .masteredProfessionalSkill: .learning
        case .receivedAward, .recognizedAtWork, .publishedWork, .invitedToSpeak: .recognition
        case .startedBusiness, .changedIndustry, .becameFreelancer, .returnedToWork, .retired: .transition
        case .other: .other
        }
    }
    var title: String {
        switch self {
        case .firstInternship: AppLanguage.localized("完成第一次实习")
        case .firstJob: AppLanguage.localized("获得第一份工作")
        case .joinedCompany: AppLanguage.localized("加入一家新公司")
        case .passedProbation: AppLanguage.localized("通过试用期")
        case .promotion: AppLanguage.localized("获得晋升")
        case .roleChange: AppLanguage.localized("转岗或职责变化")
        case .becameManager: AppLanguage.localized("开始承担管理职责")
        case .ledTeam: AppLanguage.localized("带领团队完成目标")
        case .completedProject: AppLanguage.localized("完成重要项目")
        case .launchedProduct: AppLanguage.localized("推动产品或服务上线")
        case .achievedTarget: AppLanguage.localized("达成关键业绩目标")
        case .improvedProcess: AppLanguage.localized("改进工作流程")
        case .completedTraining: AppLanguage.localized("完成职业培训")
        case .earnedQualification: AppLanguage.localized("取得职业资格")
        case .masteredProfessionalSkill: AppLanguage.localized("掌握一项专业技能")
        case .receivedAward: AppLanguage.localized("获得行业或公司奖项")
        case .recognizedAtWork: AppLanguage.localized("获得重要认可或表彰")
        case .publishedWork: AppLanguage.localized("发表专业成果")
        case .invitedToSpeak: AppLanguage.localized("受邀分享专业经验")
        case .startedBusiness: AppLanguage.localized("开始创业")
        case .changedIndustry: AppLanguage.localized("转入新的行业")
        case .becameFreelancer: AppLanguage.localized("开始自由职业")
        case .returnedToWork: AppLanguage.localized("重返职场")
        case .retired: AppLanguage.localized("开启退休生活")
        case .other: AppLanguage.localized("其他职业经历")
        }
    }
    var detailPlaceholder: String {
        switch category {
        case .starting: AppLanguage.localized("例如：公司名称或岗位")
        case .growth: AppLanguage.localized("例如：新职位、团队或职责")
        case .results: AppLanguage.localized("例如：项目名称或达成的目标")
        case .learning: AppLanguage.localized("例如：课程、资格或技能名称")
        case .recognition: AppLanguage.localized("例如：奖项或成果名称")
        case .transition: AppLanguage.localized("例如：新行业、事业或阶段")
        case .other: AppLanguage.localized("写下这段职业经历")
        }
    }
}

struct LifeEntry: Identifiable, Codable, Equatable {
    var id = UUID()
    var kind: EntryKind
    var date: Date
    var title: String
    var distanceKM: Double? = nil
    var author: String? = nil
    var country: String? = nil
    var city: String? = nil
    var origin: String? = nil
    var tripMode: TripMode? = nil
    var note: String? = nil
    var amountML: Int? = nil
    var stage: String? = nil
    var latitude: Double? = nil
    var longitude: Double? = nil
    var financeGoalType: FinanceGoalType? = nil
    var financeTargetValue: Double? = nil
    var financeCurrentValue: Double? = nil
    var careerCompany: String? = nil
    var careerPosition: String? = nil
    var careerDetail: String? = nil
    var vehicleType: VehicleType? = nil

    var financeProgress: Double? {
        guard let target = financeTargetValue, target > 0,
              let current = financeCurrentValue, current >= 0 else { return nil }
        return min(current / target, 1)
    }

    var summary: String {
        switch kind {
        case .run, .cycling: return String(format: AppLanguage.isEnglish ? "%.1f km" : "%.1f 公里", distanceKM ?? 0)
        case .learnedSport:
            return AppLanguage.format("学会了 %@", title)
        case .finishedBook:
            return AppLanguage.format("《%@》 · %@", title, author ?? AppLanguage.localized("未知作者"))
        case .degree:
            return AppLanguage.format("取得学历：%@", title)
        case .certificate:
            return AppLanguage.format("取得证书：%@", title)
        case .languageMilestone:
            return AppLanguage.format("%@ · %@", title, stage ?? "")
        case .trip:
            let location = [city, country].compactMap { $0 }.filter { !$0.isEmpty }.joined(separator: " · ")
            let mode = tripMode?.title ?? AppLanguage.localized("到访")
            let distance = distanceKM.map { String(format: AppLanguage.isEnglish ? " · %.0f km" : " · %.0f 公里", $0) } ?? ""
            return "\(mode) · \(location)\(distance)"
        case .kindness:
            return AppLanguage.format("善行：%@", title)
        case .bloodDonation:
            return AppLanguage.format("献血 · %d 毫升", amountML ?? 0)
        case .familyMoment:
            return title
        case .careerMilestone:
            let companyAndPosition = [careerCompany, careerPosition]
                .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
                .joined(separator: " · ")
            return companyAndPosition.isEmpty ? title : AppLanguage.format("%@ · %@", title, companyAndPosition)
        case .vehicleMilestone:
            return AppLanguage.format("%@ · %@", vehicleType?.title ?? AppLanguage.localized("私人交通工具"), title)
        case .creativeWork, .lifeSkill, .wellnessAction, .lifeExperience, .petMoment, .completedChallenge, .relationshipMoment, .livingMilestone, .financialMilestone:
            if kind == .financialMilestone, let progress = financeProgress {
                return AppLanguage.format("%@ · %.0f%%", title, progress * 100)
            }
            if kind == .petMoment, let petName = stage, !petName.isEmpty {
                return AppLanguage.format("%@ · %@", petName, title)
            }
            return title
        }
    }
}

enum GoalMetric: String, CaseIterable, Codable, Identifiable {
    case runningKM, books, cities, countries, sports, trips, kindness
    var id: String { rawValue }
    var title: String {
        switch self {
        case .runningKM: "累计跑步公里"
        case .books: "读完书籍"
        case .cities: "解锁城市"
        case .countries: "解锁国家"
        case .sports: "学会运动"
        case .trips: "高铁或飞行次数"
        case .kindness: AppLanguage.localized("爱心行动次数")
        }
    }
    var unit: String { self == .runningKM ? AppLanguage.localized("公里") : AppLanguage.localized("次") }
}

struct PersonalGoal: Identifiable, Codable, Equatable {
    var id = UUID()
    var title: String
    var metric: GoalMetric
    var target: Double
    var createdAt = Date()
}

struct LifeProfile: Codable, Equatable {
    var nickname = "探索者"
    var birthDate: Date? = nil
    var education: String = ""
    var graduationDate: Date? = nil
    var hasDriversLicense = false
    var licenseDate: Date? = nil
}

struct HealthStepDay: Codable, Equatable {
    var date: Date
    var count: Int
}

struct LifeData: Codable {
    var schemaVersion = 1
    var joinedAt: Date? = Date()
    var entries: [LifeEntry] = []
    var goals: [PersonalGoal] = []
    var profile = LifeProfile()
    // Optional fields keep JSON backups created before HealthKit support readable.
    var healthStepDays: [HealthStepDay]? = nil
    var lastHealthStepSync: Date? = nil
    var chapterTitles: [String: String]? = nil
}

struct Achievement: Identifiable, Equatable {
    var id: String
    var title: String
    var detail: String
    var symbol: String
    var date: Date
}
