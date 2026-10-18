import SwiftUI

private struct AnnualMetric: Identifiable {
    let title: String
    let value: String
    let symbol: String
    var id: String { title }
}

struct AnnualRecapView: View {
    @EnvironmentObject private var store: LifeStore
    @State private var selectedYear = Calendar.current.component(.year, from: Date())

    private var availableYears: [Int] {
        let entryYears = store.data.entries.map { Calendar.current.component(.year, from: $0.date) }
        let stepYears = (store.data.healthStepDays ?? []).map { Calendar.current.component(.year, from: $0.date) }
        return Set(entryYears + stepYears + [Calendar.current.component(.year, from: Date())]).sorted(by: >)
    }

    private var interval: DateInterval {
        let calendar = Calendar.current
        let start = calendar.date(from: DateComponents(year: selectedYear, month: 1, day: 1)) ?? Date()
        let end = calendar.date(byAdding: .year, value: 1, to: start) ?? start
        return DateInterval(start: start, end: end)
    }

    private var annualEntries: [LifeEntry] {
        store.data.entries.filter { $0.date >= interval.start && $0.date < interval.end }
    }

    private var annualStepDays: [HealthStepDay] {
        (store.data.healthStepDays ?? []).filter { $0.date >= interval.start && $0.date < interval.end }
    }

    private var annualXP: [LifeModule: Int] {
        let beforeEntries = store.data.entries.filter { $0.date < interval.start }
        let beforeSteps = (store.data.healthStepDays ?? []).filter { $0.date < interval.start }
        let throughEntries = store.data.entries.filter { $0.date < interval.end }
        let throughSteps = (store.data.healthStepDays ?? []).filter { $0.date < interval.end }
        let before = GameEngine.xpByModule(beforeEntries, stepDays: beforeSteps)
        let through = GameEngine.xpByModule(throughEntries, stepDays: throughSteps)
        return Dictionary(uniqueKeysWithValues: LifeModule.allCases.map {
            ($0, max(0, (through[$0] ?? 0) - (before[$0] ?? 0)))
        })
    }

    private var annualAchievements: [Achievement] {
        store.achievements.filter { $0.date >= interval.start && $0.date < interval.end }
            .sorted { $0.date > $1.date }
    }

    private var totalXP: Int { annualXP.values.reduce(0, +) }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                yearPicker
                heroCard

                VStack(alignment: .leading, spacing: 12) {
                    Text("这一年的成长").font(.title3.weight(.semibold))
                    LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                        ForEach(LifeModule.allCases) { module in
                            moduleCard(module)
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("今年点亮").font(.title3.weight(.semibold))
                        Spacer()
                        Text(AppLanguage.format("%d 个印记", annualAchievements.count)).font(.caption).foregroundStyle(Palette.secondary)
                    }
                    if annualAchievements.isEmpty {
                        EmptyState(symbol: "sparkles", title: "新的印记正在等待点亮", detail: "完成一次经历，它就会留在你的人生年鉴里")
                    } else {
                        ForEach(annualAchievements.prefix(8)) { achievement in
                            AchievementRow(achievement: achievement)
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 30)
        }
        .background(Palette.background)
        .navigationTitle(AppLanguage.localized("人生年鉴"))
        .navigationBarTitleDisplayMode(.large)
        .onChange(of: availableYears) { _, years in
            if !years.contains(selectedYear), let first = years.first { selectedYear = first }
        }
    }

    private var yearPicker: some View {
        HStack {
            Text("选择年份").font(.subheadline).foregroundStyle(Palette.secondary)
            Spacer()
            Picker("选择年份", selection: $selectedYear) {
                ForEach(availableYears, id: \.self) { year in
                    Text(AppLanguage.format("%d 年", year)).tag(year)
                }
            }
            .pickerStyle(.menu)
            .font(.headline)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Palette.card, in: RoundedRectangle(cornerRadius: 14))
    }

    private var heroCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label(AppLanguage.format("%d 年回顾", selectedYear), systemImage: "sparkles")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white.opacity(0.85))
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text("\(totalXP)").font(.system(size: 42, weight: .bold, design: .rounded))
                Text("XP").font(.headline)
                Spacer()
                Text(AppLanguage.format("%d 段经历", annualEntries.count))
                    .font(.subheadline.weight(.medium))
            }
            .foregroundStyle(.white)
            Text(AppLanguage.localized("这一年，你把真实生活变成了自己的成长记录。"))
                .font(.subheadline).foregroundStyle(.white.opacity(0.88))
            if annualEntries.isEmpty && annualStepDays.isEmpty {
                Text(AppLanguage.localized("从记录一段经历开始，点亮属于这一年的回忆。"))
                    .font(.caption).foregroundStyle(.white.opacity(0.78))
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(colors: [Palette.accent, Color.indigo], startPoint: .topLeading, endPoint: .bottomTrailing),
            in: RoundedRectangle(cornerRadius: 22)
        )
    }

    private func moduleCard(_ module: LifeModule) -> some View {
        let metrics = metrics(for: module)
        let tint = Palette.tint(for: module)
        return VStack(alignment: .leading, spacing: 11) {
            HStack(spacing: 8) {
                Image(systemName: module.symbol).foregroundStyle(tint)
                Text(module.title).font(.subheadline.weight(.semibold))
                Spacer(minLength: 2)
                Text("+\(annualXP[module] ?? 0) XP")
                    .font(.caption2.weight(.semibold)).foregroundStyle(tint)
                    .lineLimit(1).minimumScaleFactor(0.75)
            }
            if metrics.isEmpty {
                Text(AppLanguage.localized("本年暂无记录")).font(.caption).foregroundStyle(Palette.secondary)
            } else {
                ForEach(metrics) { metric in
                    HStack(spacing: 7) {
                        Image(systemName: metric.symbol).font(.caption).foregroundStyle(Palette.secondary).frame(width: 15)
                        Text(metric.title).font(.caption).foregroundStyle(Palette.secondary)
                        Spacer(minLength: 4)
                        Text(metric.value).font(.caption.weight(.semibold)).lineLimit(1).minimumScaleFactor(0.75)
                    }
                }
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, minHeight: 112, alignment: .topLeading)
        .background(Palette.card, in: RoundedRectangle(cornerRadius: 17))
    }

    private func metrics(for module: LifeModule) -> [AnnualMetric] {
        let entries = annualEntries.filter { $0.kind.module == module }
        switch module {
        case .exercise:
            let runs = entries.filter { $0.kind == .run }
            let rides = entries.filter { $0.kind == .cycling }
            let sports = Set(entries.filter { $0.kind == .learnedSport }.map { GameEngine.normalized($0.title) }.filter { !$0.isEmpty }).count
            let distance = runs.reduce(0.0) { $0 + max(0, $1.distanceKM ?? 0) }
            let rideDistance = rides.reduce(0.0) { $0 + max(0, $1.distanceKM ?? 0) }
            return [
                metric("跑步", value: AppLanguage.format("%.1f 公里", distance), symbol: "figure.run", include: !runs.isEmpty),
                metric("骑行", value: AppLanguage.format("%.1f 公里", rideDistance), symbol: "bicycle", include: !rides.isEmpty),
                metric("步数", value: AppLanguage.format("%d 步", GameEngine.totalSteps(annualStepDays)), symbol: "figure.walk", include: !annualStepDays.isEmpty),
                metric("学会运动", value: AppLanguage.format("%d 项", sports), symbol: "star", include: sports > 0)
            ].compactMap { $0 }
        case .learning:
            let books = GameEngine.uniqueBooks(entries).count
            let languages = Set(entries.filter { $0.kind == .languageMilestone }
                .map { GameEngine.normalized($0.title) + "|" + GameEngine.normalized($0.stage) }.filter { !$0.hasSuffix("|") }).count
            let degrees = entries.filter { $0.kind == .degree }.count
            let certificates = entries.filter { $0.kind == .certificate }.count
            return [
                metric("读完书籍", value: AppLanguage.format("%d 本", books), symbol: "books.vertical", include: books > 0),
                metric("语言进阶", value: AppLanguage.format("%d 项", languages), symbol: "character.book.closed", include: languages > 0),
                metric("学历", value: AppLanguage.format("%d 个", degrees), symbol: "graduationcap", include: degrees > 0),
                metric("证书", value: AppLanguage.format("%d 张", certificates), symbol: "checkmark.seal", include: certificates > 0)
            ].compactMap { $0 }
        case .travel:
            let trips = entries.filter { $0.kind == .trip }
            let cities = Set(trips.map { GameEngine.normalized($0.country) + "|" + GameEngine.normalized($0.city) }
                .filter { !$0.hasSuffix("|") }).count
            let countries = Set(trips.map { GameEngine.normalized($0.country) }.filter { !$0.isEmpty }).count
            let trains = trips.filter { $0.tripMode == .train }.count
            let flights = trips.filter { $0.tripMode == .flight }.count
            return [
                metric("到访城市", value: AppLanguage.format("%d 座", cities), symbol: "mappin", include: cities > 0),
                metric("到访国家或地区", value: AppLanguage.format("%d 个", countries), symbol: "globe", include: countries > 0),
                metric("高铁 / 飞行", value: AppLanguage.format("%d / %d 次", trains, flights), symbol: "tram.fill", include: trains + flights > 0)
            ].compactMap { $0 }
        case .love:
            let kindness = entries.filter { $0.kind == .kindness }.count
            let donations = entries.filter { $0.kind == .bloodDonation }
            let totalML = donations.reduce(0) { $0 + max(0, $1.amountML ?? 0) }
            return [
                metric("善行", value: AppLanguage.format("%d 次", kindness), symbol: "heart.fill", include: kindness > 0),
                metric("献血", value: AppLanguage.format("%d 次 · %d 毫升", donations.count, totalML), symbol: "drop.fill", include: !donations.isEmpty)
            ].compactMap { $0 }
        case .family:
            let moments = entries.filter { $0.kind == .familyMoment }.count
            return [metric("家庭纪念与共同经历", value: AppLanguage.format("%d 段", moments), symbol: "figure.2.and.child.holdinghands", include: moments > 0)].compactMap { $0 }
        case .career:
            let milestones = Set(entries.compactMap(GameEngine.careerMilestoneKey)).count
            return [metric("职业里程碑", value: AppLanguage.format("%d 项", milestones), symbol: "briefcase.fill", include: milestones > 0)].compactMap { $0 }
        case .creation:
            let works = Set(entries.filter { $0.kind == .creativeWork }.map { GameEngine.normalized($0.title) }.filter { !$0.isEmpty }).count
            return [metric("完成作品", value: AppLanguage.format("%d 项", works), symbol: "paintpalette.fill", include: works > 0)].compactMap { $0 }
        case .lifeSkills:
            let skills = Set(entries.filter { $0.kind == .lifeSkill }.map { GameEngine.normalized($0.title) }.filter { !$0.isEmpty }).count
            return [metric("掌握生活技能", value: AppLanguage.format("%d 项", skills), symbol: "lightbulb.fill", include: skills > 0)].compactMap { $0 }
        case .wellness:
            let actions = entries.filter { $0.kind == .wellnessAction }.count
            return [metric("健康行动", value: AppLanguage.format("%d 次", actions), symbol: "cross.case.fill", include: actions > 0)].compactMap { $0 }
        case .experiences:
            let count = entries.filter { $0.kind == .lifeExperience }.count
            return [metric("生活体验", value: AppLanguage.format("%d 次", count), symbol: "sparkles", include: count > 0)].compactMap { $0 }
        case .pets:
            let count = entries.filter { $0.kind == .petMoment }.count
            let pets = Set(entries.filter { $0.kind == .petMoment }.map { GameEngine.normalized($0.stage) }.filter { !$0.isEmpty }).count
            return [
                metric("宠物时光", value: AppLanguage.format("%d 段", count), symbol: "pawprint.fill", include: count > 0),
                metric("记录宠物", value: AppLanguage.format("%d 只", pets), symbol: "heart.fill", include: pets > 0)
            ].compactMap { $0 }
        case .challenges:
            let count = Set(entries.filter { $0.kind == .completedChallenge }.map { GameEngine.normalized($0.title) }.filter { !$0.isEmpty }).count
            return [metric("完成挑战", value: AppLanguage.format("%d 项", count), symbol: "flag.checkered", include: count > 0)].compactMap { $0 }
        case .relationships:
            let count = entries.filter { $0.kind == .relationshipMoment }.count
            return [metric("关系时刻", value: AppLanguage.format("%d 段", count), symbol: "person.2.fill", include: count > 0)].compactMap { $0 }
        case .assets:
            let homes = Set(entries.filter { $0.kind == .livingMilestone }.compactMap { GameEngine.assetMilestoneKey(for: $0) }).count
            let vehicles = Set(entries.filter { $0.kind == .vehicleMilestone }.compactMap { GameEngine.assetMilestoneKey(for: $0) }).count
            return [
                metric("居住经历", value: AppLanguage.format("%d 项", homes), symbol: "house.fill", include: homes > 0),
                metric("私人交通工具", value: AppLanguage.format("%d 件", vehicles), symbol: "car.side.fill", include: vehicles > 0)
            ].compactMap { $0 }
        case .finance:
            let count = GameEngine.financeGoalCount(entries)
            let milestones = GameEngine.financeProgressMilestoneCount(entries)
            return [
                metric("财务目标", value: AppLanguage.format("%d 项", count), symbol: "chart.line.uptrend.xyaxis", include: count > 0),
                metric("跨过进度节点", value: AppLanguage.format("%d 个", milestones), symbol: "chart.bar.fill", include: milestones > 0)
            ].compactMap { $0 }
        }
    }

    private func metric(_ title: String, value: String, symbol: String, include: Bool) -> AnnualMetric? {
        include ? AnnualMetric(title: AppLanguage.localized(title), value: value, symbol: symbol) : nil
    }
}
