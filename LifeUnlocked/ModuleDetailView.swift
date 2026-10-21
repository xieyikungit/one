import SwiftUI

struct ModuleDetailView: View {
    @EnvironmentObject private var store: LifeStore
    let module: LifeModule
    @State private var addingKind: EntryKind?
    @State private var editingEntry: LifeEntry?

    private var entries: [LifeEntry] {
        store.sortedEntries.filter { $0.kind.module == module }
    }

    private var tint: Color { Palette.tint(for: module) }
    private var addTitle: String {
        switch module {
        case .exercise: AppLanguage.localized("新增运动经历")
        case .learning: AppLanguage.localized("新增学习记录")
        case .travel: AppLanguage.localized("新增旅行经历")
        case .love: AppLanguage.localized("记录爱心经历")
        case .family: AppLanguage.localized("记录家庭经历")
        case .career: AppLanguage.localized("记录一次职业经历")
        case .creation: AppLanguage.localized("记录一项创作")
        case .lifeSkills: AppLanguage.localized("记录一项生活技能")
        case .wellness: AppLanguage.localized("记录一次健康行动")
        case .experiences: AppLanguage.localized("记录一次生活体验")
        case .pets: AppLanguage.localized("记录一次宠物时刻")
        case .challenges: AppLanguage.localized("记录一项个人挑战")
        case .relationships: AppLanguage.localized("记录一段关系时刻")
        case .assets: AppLanguage.localized("新增资产记录")
        case .finance: AppLanguage.localized("新增或更新财务目标")
        }
    }
    private var levelTitle: String {
        switch module {
        case .exercise: AppLanguage.localized("运动等级")
        case .learning: AppLanguage.localized("学习等级")
        case .travel: AppLanguage.localized("旅行等级")
        case .love: AppLanguage.localized("爱心等级")
        case .family: AppLanguage.localized("家庭等级")
        case .career: AppLanguage.localized("职业等级")
        case .creation: AppLanguage.localized("创作等级")
        case .lifeSkills: AppLanguage.localized("生活技能等级")
        case .wellness: AppLanguage.localized("健康等级")
        case .experiences: AppLanguage.localized("体验等级")
        case .pets: AppLanguage.localized("宠物等级")
        case .challenges: AppLanguage.localized("挑战等级")
        case .relationships: AppLanguage.localized("关系等级")
        case .assets: AppLanguage.localized("资产等级")
        case .finance: AppLanguage.localized("财务等级")
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                levelCard
                statistics
                if module == .learning {
                    addAction
                    VStack(spacing: 10) {
                        readingSubmoduleLink
                        learningRecordLink(kind: .languageMilestone, countTitle: "已记录 %d 项语言进阶")
                        learningRecordLink(kind: .degree, countTitle: "已记录 %d 个学历")
                        learningRecordLink(kind: .certificate, countTitle: "已记录 %d 张证书")
                    }
                    BadgeShelf(title: "学习徽章", badges: store.badges.filter { $0.module == .learning }, showsPreview: true)
                    collection
                    entryHistory
                } else {
                    addAction
                    if module == .exercise {
                        cyclingCard
                        StepCountCard()
                    }
                    BadgeShelf(title: AppLanguage.format("%@徽章", module.title), badges: store.badges.filter { $0.module == module }, showsPreview: true)
                    collection
                    entryHistory
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 30)
        }
        .background(Palette.background)
        .navigationTitle(module.title)
        .navigationBarTitleDisplayMode(.large)
        .sheet(item: $addingKind) { kind in EntryFormView(initialKind: kind) }
        .sheet(item: $editingEntry) { entry in EntryFormView(existing: entry) }
    }

    private var entryHistory: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("经历记录").font(.title3.weight(.semibold))
                Spacer()
                Text("\(entries.count) 条").font(.subheadline).foregroundStyle(Palette.secondary)
            }
            if entries.isEmpty {
                EmptyState(symbol: module.symbol, title: "还没有\(module.title)记录", detail: "记录一次已经完成的真实经历")
            } else {
                LazyVStack(spacing: 10) {
                    ForEach(entries) { entry in
                        Button { editingEntry = entry } label: {
                            HStack(spacing: 12) {
                                Image(systemName: entry.kind.symbol)
                                    .foregroundStyle(tint)
                                    .frame(width: 36, height: 36)
                                    .background(tint.opacity(0.10), in: RoundedRectangle(cornerRadius: 10))
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(entry.kind.title).font(.caption).foregroundStyle(Palette.secondary)
                                    Text(entry.summary).font(.subheadline.weight(.semibold)).foregroundStyle(.primary)
                                        .multilineTextAlignment(.leading)
                                }
                                Spacer(minLength: 4)
                                Text(entry.date, format: .dateTime.month().day())
                                    .font(.caption).foregroundStyle(Palette.secondary)
                            }
                            .padding(14)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Palette.card, in: RoundedRectangle(cornerRadius: 16))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private var readingSubmoduleLink: some View {
        let readingEntries = entries.filter { $0.kind == .finishedBook }
        let books = GameEngine.uniqueBooks(readingEntries).count
        return NavigationLink {
            ReadingSubmoduleView()
        } label: {
            HStack(spacing: 14) {
                Image(systemName: "books.vertical.fill")
                    .font(.title3)
                    .foregroundStyle(tint)
                    .frame(width: 48, height: 48)
                    .background(tint.opacity(0.11), in: RoundedRectangle(cornerRadius: 14))
                VStack(alignment: .leading, spacing: 4) {
                    Text("阅读").font(.headline).foregroundStyle(.primary)
                    Text(AppLanguage.format("已读 %d 本 · 共 %d 条记录", books, readingEntries.count))
                        .font(.caption).foregroundStyle(Palette.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right").font(.caption.weight(.semibold)).foregroundStyle(Palette.secondary)
            }
            .padding(16)
            .background(Palette.card, in: RoundedRectangle(cornerRadius: 18))
        }
        .buttonStyle(.plain)
    }

    private func learningRecordLink(kind: EntryKind, countTitle: String) -> some View {
        let records = entries.filter { $0.kind == kind }
        return NavigationLink {
            EntryRecordSubmoduleView(kind: kind)
        } label: {
            HStack(spacing: 14) {
                Image(systemName: kind.symbol)
                    .font(.title3)
                    .foregroundStyle(tint)
                    .frame(width: 48, height: 48)
                    .background(tint.opacity(0.11), in: RoundedRectangle(cornerRadius: 14))
                VStack(alignment: .leading, spacing: 4) {
                    Text(kind.title).font(.headline).foregroundStyle(.primary)
                    Text(AppLanguage.format(countTitle, records.count))
                        .font(.caption).foregroundStyle(Palette.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right").font(.caption.weight(.semibold)).foregroundStyle(Palette.secondary)
            }
            .padding(16)
            .background(Palette.card, in: RoundedRectangle(cornerRadius: 18))
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var addAction: some View {
        if module == .exercise {
            Menu {
                Button("记录跑步", systemImage: "figure.run") { addingKind = .run }
                Button("记录骑行", systemImage: "bicycle") { addingKind = .cycling }
                Button("记录学会的运动", systemImage: "figure.mixed.cardio") { addingKind = .learnedSport }
            } label: {
                addActionLabel
            }
            .accessibilityLabel(addTitle)
        } else if module == .love {
            Menu {
                Button("记录善行", systemImage: "heart.fill") { addingKind = .kindness }
                Button("记录献血", systemImage: "drop.fill") { addingKind = .bloodDonation }
            } label: {
                addActionLabel
            }
            .accessibilityLabel(addTitle)
        } else if module == .family {
            Button { addingKind = .familyMoment } label: { addActionLabel }
                .accessibilityLabel(addTitle)
        } else if module == .career {
            Button { addingKind = .careerMilestone } label: { addActionLabel }
                .accessibilityLabel(addTitle)
        } else if module == .learning {
            Button { addingKind = .finishedBook } label: { addActionLabel }
                .accessibilityLabel(addTitle)
        } else if module == .creation {
            Button { addingKind = .creativeWork } label: { addActionLabel }
                .accessibilityLabel(addTitle)
        } else if module == .lifeSkills {
            Button { addingKind = .lifeSkill } label: { addActionLabel }
                .accessibilityLabel(addTitle)
        } else if module == .wellness {
            Button { addingKind = .wellnessAction } label: { addActionLabel }
                .accessibilityLabel(addTitle)
        } else if module == .experiences {
            Button { addingKind = .lifeExperience } label: { addActionLabel }
                .accessibilityLabel(addTitle)
        } else if module == .pets {
            Button { addingKind = .petMoment } label: { addActionLabel }
                .accessibilityLabel(addTitle)
        } else if module == .challenges {
            Button { addingKind = .completedChallenge } label: { addActionLabel }
                .accessibilityLabel(addTitle)
        } else if module == .relationships {
            Button { addingKind = .relationshipMoment } label: { addActionLabel }
                .accessibilityLabel(addTitle)
        } else if module == .assets {
            Button { addingKind = .livingMilestone } label: { addActionLabel }
                .accessibilityLabel(addTitle)
        } else if module == .finance {
            Button { addingKind = .financialMilestone } label: { addActionLabel }
                .accessibilityLabel(addTitle)
        } else {
            Button {
                switch module {
                case .learning: addingKind = .finishedBook
                case .travel: addingKind = .trip
                case .love: addingKind = .kindness
                case .family: addingKind = .familyMoment
                case .career: addingKind = .careerMilestone
                case .creation: addingKind = .creativeWork
                case .lifeSkills: addingKind = .lifeSkill
                case .wellness: addingKind = .wellnessAction
                case .experiences: addingKind = .lifeExperience
                case .pets: addingKind = .petMoment
                case .challenges: addingKind = .completedChallenge
                case .relationships: addingKind = .relationshipMoment
                case .assets: addingKind = .livingMilestone
                case .finance: addingKind = .financialMilestone
                case .exercise: break
                }
            } label: {
                addActionLabel
            }
            .accessibilityLabel(addTitle)
        }
    }

    private var addActionLabel: some View {
        HStack {
            Label(addTitle, systemImage: "plus")
            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
        }
        .font(.subheadline.weight(.semibold))
        .foregroundStyle(tint)
        .padding(16)
        .background(tint.opacity(0.10), in: RoundedRectangle(cornerRadius: 16))
    }

    private var collection: some View {
        let items = collectionEntries
        return VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("人生图鉴").font(.title3.weight(.semibold))
                Spacer()
                Text("已点亮 \(items.count)").font(.subheadline).foregroundStyle(Palette.secondary)
            }
            Text(GameEngine.nextMilestone(for: module, entries: store.data.entries))
                .font(.caption).foregroundStyle(Palette.secondary)

            if items.isEmpty {
                HStack(spacing: 12) {
                    Image(systemName: module.symbol)
                        .font(.title3).foregroundStyle(tint.opacity(0.55))
                        .frame(width: 48, height: 48)
                        .background(tint.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
                    Text("记录第一段\(module.title)经历，点亮你的图鉴")
                        .font(.subheadline).foregroundStyle(Palette.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(16)
                .background(Palette.card, in: RoundedRectangle(cornerRadius: 16))
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(items.prefix(12)) { entry in
                            collectionTile(for: entry)
                        }
                        if items.count > 12 {
                            Text("还有 \(items.count - 12) 项")
                                .font(.caption.weight(.medium))
                                .foregroundStyle(Palette.secondary)
                                .frame(width: 94, height: 110)
                                .background(Palette.card, in: RoundedRectangle(cornerRadius: 16))
                        }
                    }
                    .padding(.vertical, 2)
                }
            }
        }
    }

    private var collectionEntries: [LifeEntry] {
        switch module {
        case .exercise:
            var sports = Set<String>()
            return store.sortedEntries.filter { entry in
                if entry.kind == .run || entry.kind == .cycling { return true }
                guard entry.kind == .learnedSport else { return false }
                return sports.insert(GameEngine.normalized(entry.title)).inserted
            }
        case .learning:
            return store.sortedEntries.filter { $0.kind == .degree || $0.kind == .certificate || $0.kind == .languageMilestone }
        case .travel:
            var places = Set<String>()
            return store.sortedEntries.filter { entry in
                guard entry.kind == .trip else { return false }
                let key = GameEngine.normalized(entry.country) + "|" + GameEngine.normalized(entry.city)
                return places.insert(key).inserted
            }
        case .love:
            return store.sortedEntries.filter { $0.kind == .kindness || $0.kind == .bloodDonation }
        case .family:
            return store.sortedEntries.filter { $0.kind == .familyMoment }
        case .career:
            return store.sortedEntries.filter { $0.kind == .careerMilestone }
        case .creation:
            return store.sortedEntries.filter { $0.kind == .creativeWork }
        case .lifeSkills:
            return store.sortedEntries.filter { $0.kind == .lifeSkill }
        case .wellness:
            return store.sortedEntries.filter { $0.kind == .wellnessAction }
        case .experiences:
            return store.sortedEntries.filter { $0.kind == .lifeExperience }
        case .pets:
            return store.sortedEntries.filter { $0.kind == .petMoment }
        case .challenges:
            var seen = Set<String>()
            return store.sortedEntries.filter { $0.kind == .completedChallenge }
                .filter { seen.insert(GameEngine.normalized($0.title)).inserted }
        case .relationships:
            return store.sortedEntries.filter { $0.kind == .relationshipMoment }
        case .assets:
            var seen = Set<String>()
            return store.sortedEntries.filter { entry in
                guard let key = GameEngine.assetMilestoneKey(for: entry) else { return false }
                return seen.insert(key).inserted
            }
        case .finance:
            var seen = Set<String>()
            return store.sortedEntries.filter { $0.kind == .financialMilestone }
                .filter { seen.insert(GameEngine.financeGoalKey(for: $0) ?? GameEngine.normalized($0.title)).inserted }
        }
    }

    private func collectionTile(for entry: LifeEntry) -> some View {
        let title: String
        let detail: String
        switch entry.kind {
        case .run:
            title = "\((entry.distanceKM ?? 0).formatted(.number.precision(.fractionLength(0...1)))) \(AppLanguage.localized("公里"))"
            detail = entry.date.formatted(.dateTime.month().day())
        case .cycling:
            title = "\((entry.distanceKM ?? 0).formatted(.number.precision(.fractionLength(0...1)))) \(AppLanguage.localized("公里"))"
            detail = entry.date.formatted(.dateTime.month().day())
        case .learnedSport:
            title = entry.title
            detail = "已学会"
        case .finishedBook:
            title = entry.title
            detail = entry.author.flatMap { $0.isEmpty ? nil : $0 } ?? "读完"
        case .languageMilestone:
            title = entry.title
            detail = entry.stage ?? ""
        case .degree:
            title = entry.title
            detail = AppDate.yearMonthDay(entry.date)
        case .certificate:
            title = entry.title
            detail = AppDate.yearMonthDay(entry.date)
        case .trip:
            title = entry.city.flatMap { $0.isEmpty ? nil : $0 } ?? (entry.country ?? "旅行")
            detail = entry.country ?? "已到访"
        case .kindness:
            title = entry.title
            detail = AppLanguage.localized("善行记录")
        case .bloodDonation:
            title = AppLanguage.format("%d 毫升", entry.amountML ?? 0)
            detail = AppLanguage.localized("献血记录")
        case .familyMoment:
            title = entry.title
            detail = AppLanguage.localized("家庭经历")
        case .careerMilestone:
            title = entry.title
            detail = CareerMilestoneChoice(rawValue: entry.stage ?? "")?.category.title ?? AppLanguage.localized("职业经历")
        case .creativeWork:
            title = entry.title
            detail = AppLanguage.localized("创作记录")
        case .lifeSkill:
            title = entry.title
            detail = AppLanguage.localized("已掌握")
        case .wellnessAction:
            title = entry.title
            detail = AppLanguage.localized("健康行动")
        case .lifeExperience:
            title = entry.title
            detail = AppLanguage.localized("生活体验")
        case .petMoment:
            title = entry.title
            detail = entry.stage.flatMap { $0.isEmpty ? nil : $0 } ?? AppLanguage.localized("宠物时光")
        case .completedChallenge:
            title = entry.title
            detail = AppLanguage.localized("挑战完成")
        case .relationshipMoment:
            title = entry.title
            detail = AppLanguage.localized("关系时刻")
        case .livingMilestone:
            title = entry.title
            detail = AppLanguage.localized("居住经历")
        case .vehicleMilestone:
            title = entry.title
            detail = entry.vehicleType?.title ?? AppLanguage.localized("私人交通工具")
        case .financialMilestone:
            title = entry.title
            if entry.financeProgress != nil {
                let type = entry.financeGoalType?.title ?? AppLanguage.localized("财务目标")
                detail = type
            } else {
                detail = AppLanguage.localized("历史财务记录")
            }
        }
        return VStack(alignment: .leading, spacing: 7) {
            Image(systemName: entry.kind.symbol)
                .font(.title3)
                .foregroundStyle(tint)
                .frame(width: 36, height: 36)
                .background(tint.opacity(0.11), in: RoundedRectangle(cornerRadius: 10))
            if let progress = entry.financeProgress {
                ProgressView(value: progress).tint(tint)
                Text(AppLanguage.format("%.0f%% 已完成", progress * 100))
                    .font(.caption2.weight(.medium)).foregroundStyle(tint)
            }
            Spacer(minLength: 0)
            Text(title).font(.subheadline.weight(.semibold)).foregroundStyle(.primary)
                .lineLimit(2).minimumScaleFactor(0.8)
            Text(detail).font(.caption2).foregroundStyle(Palette.secondary).lineLimit(1)
        }
        .frame(width: 108, height: 108, alignment: .leading)
        .padding(12)
        .background(Palette.card, in: RoundedRectangle(cornerRadius: 16))
        .accessibilityElement(children: .combine)
    }

    private var levelCard: some View {
        let xp = store.xp[module] ?? 0
        let level = store.levels[module] ?? 1
        let current = GameEngine.threshold(for: level)
        let next = GameEngine.threshold(for: level + 1)
        let progress = Double(xp - current) / Double(max(1, next - current))

        return VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 14) {
                Image(systemName: module.symbol)
                    .font(.title2)
                    .foregroundStyle(tint)
                    .frame(width: 52, height: 52)
                    .background(tint.opacity(0.11), in: RoundedRectangle(cornerRadius: 15))
                VStack(alignment: .leading, spacing: 3) {
                    Text(levelTitle).font(.subheadline).foregroundStyle(Palette.secondary)
                    Text("Lv.\(level)").font(.system(size: 34, weight: .semibold, design: .rounded)).foregroundStyle(tint)
                }
                Spacer()
            }
            ProgressView(value: progress).tint(tint)
            HStack {
                Text("已获得 \(xp) XP")
                Spacer()
                Text("下一级 \(next) XP")
            }
            .font(.caption)
            .foregroundStyle(Palette.secondary)
        }
        .padding(20)
        .background(Palette.card, in: RoundedRectangle(cornerRadius: 20))
    }

    private var cyclingCard: some View {
        let rides = entries.filter { $0.kind == .cycling }
        let kilometers = rides.reduce(0.0) { $0 + max(0, $1.distanceKM ?? 0) }
        return VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: "bicycle")
                    .foregroundStyle(tint)
                    .frame(width: 36, height: 36)
                    .background(tint.opacity(0.11), in: RoundedRectangle(cornerRadius: 10))
                Text("骑行").font(.title3.weight(.semibold))
                Spacer()
                Text("每公里 3 XP").font(.caption).foregroundStyle(Palette.secondary)
            }
            HStack(alignment: .firstTextBaseline, spacing: 5) {
                Text(kilometers.formatted(.number.precision(.fractionLength(0...1))))
                    .font(.title2.weight(.semibold))
                Text("公里").font(.subheadline).foregroundStyle(Palette.secondary)
                Spacer()
                Text(AppLanguage.isEnglish ? "\(rides.count) rides" : "\(rides.count) 次骑行")
                    .font(.caption).foregroundStyle(Palette.secondary)
            }
            Button("记录骑行") { addingKind = .cycling }
                .buttonStyle(.bordered)
                .tint(tint)
        }
        .padding(18)
        .background(Palette.card, in: RoundedRectangle(cornerRadius: 18))
    }

    @ViewBuilder
    private var statistics: some View {
        switch module {
        case .exercise:
            let runs = entries.filter { $0.kind == .run }
            let runDistance = runs.reduce(0.0) { $0 + ($1.distanceKM ?? 0) }
            let learned = Set(entries.filter { $0.kind == .learnedSport }
                .map { GameEngine.normalized($0.title) }.filter { !$0.isEmpty }).count
            HStack(spacing: 12) {
                statistic("累计跑步", value: "\(runDistance.formatted(.number.precision(.fractionLength(0...1)))) 公里", symbol: "figure.run")
                statistic("学会运动", value: "\(learned) 项", symbol: "star")
            }
        case .learning:
            let books = GameEngine.uniqueBooks(entries).count
            let languages = Set(entries.filter { $0.kind == .languageMilestone }
                .map { GameEngine.normalized($0.title) + "|" + GameEngine.normalized($0.stage) }).count
            let degrees = entries.filter { $0.kind == .degree }.count
            let certificates = entries.filter { $0.kind == .certificate }.count
            HStack(spacing: 12) {
                statistic("读完的书", value: "\(books) 本", symbol: "books.vertical")
                statistic("语言进阶", value: "\(languages) 项", symbol: "character.book.closed")
            }
            HStack(spacing: 12) {
                statistic("证书记录", value: "\(certificates) 张", symbol: "checkmark.seal")
                statistic("学历记录", value: "\(degrees) 个", symbol: "graduationcap")
            }
        case .travel:
            let cities = Set(entries.map { GameEngine.normalized($0.country) + "|" + GameEngine.normalized($0.city) }
                .filter { !$0.hasSuffix("|") }).count
            let countries = Set(entries.map { GameEngine.normalized($0.country) }.filter { !$0.isEmpty }).count
            HStack(spacing: 12) {
                statistic("解锁城市", value: "\(cities) 座", symbol: "mappin")
                statistic("解锁国家", value: "\(countries) 个", symbol: "globe")
            }
            let train = entries.filter { $0.tripMode == .train }
            let flight = entries.filter { $0.tripMode == .flight }
            HStack(spacing: 12) {
                statistic("高铁", value: "\(train.count) 次 · \(Int(train.reduce(0) { $0 + ($1.distanceKM ?? 0) })) 公里", symbol: "tram.fill")
                statistic("飞行", value: "\(flight.count) 次 · \(Int(flight.reduce(0) { $0 + ($1.distanceKM ?? 0) })) 公里", symbol: "airplane")
            }
        case .love:
            let actions = entries.filter { $0.kind == .kindness }.count
            let donations = entries.filter { $0.kind == .bloodDonation }
            let totalML = donations.reduce(0) { $0 + max(0, $1.amountML ?? 0) }
            HStack(spacing: 12) {
                statistic("善行记录", value: "\(actions) 次", symbol: "heart.fill")
                statistic("献血次数", value: "\(donations.count) 次", symbol: "drop.fill")
            }
            HStack(spacing: 12) {
                statistic("累计献血量", value: "\(totalML) 毫升", symbol: "cross.case.fill")
                statistic("获得爱心 XP", value: "\((actions + donations.count) * 50) XP", symbol: "sparkles")
            }
        case .family:
            let moments = entries.filter { $0.kind == .familyMoment }.count
            HStack(spacing: 12) {
                statistic("家庭经历", value: "\(moments) 条", symbol: "figure.2.and.child.holdinghands")
                statistic("获得家庭 XP", value: "\(moments * 50) XP", symbol: "sparkles")
            }
        case .career:
            let milestones = Set(entries.compactMap { GameEngine.careerMilestoneKey(for: $0) }).count
            HStack(spacing: 12) {
                statistic("不同职业节点", value: "\(milestones) 项", symbol: "briefcase.fill")
                statistic("获得职业 XP", value: "\(store.xp[.career] ?? 0) XP", symbol: "sparkles")
            }
        case .creation:
            let works = Set(entries.map { GameEngine.normalized($0.title) }.filter { !$0.isEmpty }).count
            HStack(spacing: 12) {
                statistic("完成作品", value: "\(works) 项", symbol: "paintpalette.fill")
                statistic("获得创作 XP", value: "\(store.xp[.creation] ?? 0) XP", symbol: "sparkles")
            }
        case .lifeSkills:
            let skills = Set(entries.map { GameEngine.normalized($0.title) }.filter { !$0.isEmpty }).count
            HStack(spacing: 12) {
                statistic("掌握技能", value: "\(skills) 项", symbol: "lightbulb.fill")
                statistic("获得生活技能 XP", value: "\(store.xp[.lifeSkills] ?? 0) XP", symbol: "sparkles")
            }
        case .wellness:
            let count = entries.filter { $0.kind == .wellnessAction }.count
            HStack(spacing: 12) {
                statistic("健康行动", value: "\(count) 次", symbol: "cross.case.fill")
                statistic("获得健康 XP", value: "\(store.xp[.wellness] ?? 0) XP", symbol: "sparkles")
            }
        case .experiences:
            let count = entries.filter { $0.kind == .lifeExperience }.count
            HStack(spacing: 12) {
                statistic("生活体验", value: "\(count) 次", symbol: "sparkles")
                statistic("获得体验 XP", value: "\(store.xp[.experiences] ?? 0) XP", symbol: "sparkles")
            }
        case .pets:
            let count = entries.filter { $0.kind == .petMoment }.count
            let petNames = Set(entries.filter { $0.kind == .petMoment }.map { GameEngine.normalized($0.stage) }.filter { !$0.isEmpty }).count
            HStack(spacing: 12) {
                statistic("宠物时光", value: "\(count) 段", symbol: "pawprint.fill")
                statistic("记录宠物", value: "\(petNames) 只", symbol: "heart.fill")
            }
        case .challenges:
            let count = Set(entries.filter { $0.kind == .completedChallenge }.map { GameEngine.normalized($0.title) }.filter { !$0.isEmpty }).count
            HStack(spacing: 12) {
                statistic("已完成挑战", value: "\(count) 项", symbol: "flag.checkered")
                statistic("获得挑战 XP", value: "\(store.xp[.challenges] ?? 0) XP", symbol: "sparkles")
            }
        case .relationships:
            let count = entries.filter { $0.kind == .relationshipMoment }.count
            HStack(spacing: 12) {
                statistic("关系时刻", value: "\(count) 段", symbol: "person.2.fill")
                statistic("获得关系 XP", value: "\(store.xp[.relationships] ?? 0) XP", symbol: "sparkles")
            }
        case .assets:
            let homes = Set(entries.filter { $0.kind == .livingMilestone }.map { GameEngine.assetMilestoneKey(for: $0) }.compactMap { $0 }).count
            let vehicles = Set(entries.filter { $0.kind == .vehicleMilestone }.map { GameEngine.assetMilestoneKey(for: $0) }.compactMap { $0 }).count
            HStack(spacing: 12) {
                statistic("居住经历", value: "\(homes) 项", symbol: "house.fill")
                statistic("私人交通工具", value: "\(vehicles) 件", symbol: "car.side.fill")
                statistic("获得资产 XP", value: "\(store.xp[.assets] ?? 0) XP", symbol: "sparkles")
            }
        case .finance:
            let count = GameEngine.financeGoalCount(entries)
            let milestones = GameEngine.financeProgressMilestoneCount(entries)
            HStack(spacing: 12) {
                statistic("财务目标", value: "\(count) 项", symbol: "chart.line.uptrend.xyaxis")
                statistic("已跨过进度节点", value: "\(milestones) 个", symbol: "chart.bar.fill")
            }
        }
    }

    private func statistic(_ title: String, value: String, symbol: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: symbol).foregroundStyle(tint)
            Text(value).font(.subheadline.weight(.semibold)).lineLimit(2).minimumScaleFactor(0.8)
            Text(title).font(.caption).foregroundStyle(Palette.secondary)
        }
        .frame(maxWidth: .infinity, minHeight: 76, alignment: .leading)
        .padding(14)
        .background(Palette.card, in: RoundedRectangle(cornerRadius: 16))
    }
}

private struct ReadingSubmoduleView: View {
    @EnvironmentObject private var store: LifeStore
    @State private var addingBook = false
    @State private var editingBook: LifeEntry?

    private var entries: [LifeEntry] {
        store.sortedEntries.filter { $0.kind == .finishedBook }
    }
    private var uniqueBooks: Int { GameEngine.uniqueBooks(entries).count }
    private var readingBadges: [LifeBadge] {
        store.badges.filter { $0.module == .learning && ($0.id.hasPrefix("book-") || $0.id.hasPrefix("reread-")) }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                HStack(spacing: 12) {
                    submoduleStat("读完的书", value: "\(uniqueBooks) 本", symbol: "books.vertical.fill")
                    submoduleStat("阅读记录", value: "\(entries.count) 条", symbol: "bookmark.fill")
                }
                BadgeShelf(title: "阅读徽章", badges: readingBadges)
                VStack(alignment: .leading, spacing: 12) {
                    Text("阅读记录").font(.title3.weight(.semibold))
                    if entries.isEmpty {
                        EmptyState(symbol: "books.vertical", title: "还没有阅读记录", detail: "读完一本书后，记录下来点亮人生书架")
                    } else {
                        LazyVStack(spacing: 10) {
                            ForEach(entries) { entry in
                                Button { editingBook = entry } label: {
                                    HStack(spacing: 12) {
                                        Image(systemName: "book.closed.fill")
                                            .foregroundStyle(Palette.tint(for: .learning))
                                            .frame(width: 38, height: 38)
                                            .background(Palette.tint(for: .learning).opacity(0.10), in: RoundedRectangle(cornerRadius: 11))
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(entry.title).font(.subheadline.weight(.semibold)).foregroundStyle(.primary)
                                            Text(entry.author.flatMap { $0.isEmpty ? nil : $0 } ?? "读完一本书")
                                                .font(.caption).foregroundStyle(Palette.secondary)
                                        }
                                        Spacer(minLength: 5)
                                        Text(AppDate.yearMonthDay(entry.date))
                                            .font(.caption2).foregroundStyle(Palette.secondary)
                                            .lineLimit(1).minimumScaleFactor(0.75)
                                    }
                                    .padding(14)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(Palette.card, in: RoundedRectangle(cornerRadius: 16))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 30)
        }
        .background(Palette.background)
        .navigationTitle("阅读")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("记录读书", systemImage: "plus") { addingBook = true }
                    .accessibilityIdentifier("add-reading-entry")
            }
        }
        .sheet(isPresented: $addingBook) { EntryFormView(initialKind: .finishedBook) }
        .sheet(item: $editingBook) { entry in EntryFormView(existing: entry) }
    }

    private func submoduleStat(_ title: String, value: String, symbol: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: symbol).foregroundStyle(Palette.tint(for: .learning))
            Text(value).font(.subheadline.weight(.semibold))
            Text(title).font(.caption).foregroundStyle(Palette.secondary)
        }
        .frame(maxWidth: .infinity, minHeight: 76, alignment: .leading)
        .padding(14)
        .background(Palette.card, in: RoundedRectangle(cornerRadius: 16))
    }
}

private struct EntryRecordSubmoduleView: View {
    @EnvironmentObject private var store: LifeStore
    let kind: EntryKind
    @State private var adding = false
    @State private var editing: LifeEntry?

    private var entries: [LifeEntry] { store.sortedEntries.filter { $0.kind == kind } }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                if entries.isEmpty {
                    EmptyState(
                        symbol: kind.symbol,
                        title: AppLanguage.format("还没有%@记录", kind.title),
                        detail: AppLanguage.localized("记录名称和取得日期，保存你完成的学习经历")
                    )
                } else {
                    LazyVStack(spacing: 10) {
                        ForEach(entries) { entry in
                            Button { editing = entry } label: {
                                HStack(spacing: 12) {
                                    Image(systemName: kind.symbol)
                                        .foregroundStyle(Palette.tint(for: .learning))
                                        .frame(width: 38, height: 38)
                                        .background(Palette.tint(for: .learning).opacity(0.10), in: RoundedRectangle(cornerRadius: 11))
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(entry.title).font(.subheadline.weight(.semibold)).foregroundStyle(.primary)
                                        Text(AppDate.yearMonthDay(entry.date)).font(.caption).foregroundStyle(Palette.secondary)
                                    }
                                    Spacer()
                                    Image(systemName: "chevron.right").font(.caption2.weight(.semibold)).foregroundStyle(Palette.secondary)
                                }
                                .padding(14)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Palette.card, in: RoundedRectangle(cornerRadius: 16))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .padding(20)
        }
        .background(Palette.background)
        .navigationTitle(kind.title)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(AppLanguage.localized("新增记录"), systemImage: "plus") { adding = true }
            }
        }
        .sheet(isPresented: $adding) { EntryFormView(initialKind: kind) }
        .sheet(item: $editing) { entry in EntryFormView(existing: entry) }
    }
}

private struct StepCountCard: View {
    @EnvironmentObject private var store: LifeStore
    @State private var isSyncing = false
    @State private var statusMessage: String?

    private var hasRequestedAccess: Bool {
        UserDefaults.standard.bool(forKey: HealthSteps.accessRequestKey)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                Image(systemName: "figure.walk")
                    .foregroundStyle(.orange)
                    .frame(width: 36, height: 36)
                    .background(Color.orange.opacity(0.11), in: RoundedRectangle(cornerRadius: 10))
                Text("步数").font(.title3.weight(.semibold))
                Spacer()
                Text("Apple 健康").font(.caption).foregroundStyle(Palette.secondary)
            }

            HStack(spacing: 12) {
                stepValue("今日", value: store.data.lastHealthStepSync == nil ? "—" : store.todayHealthSteps.formatted(), unit: "步")
                stepValue("累计", value: store.data.lastHealthStepSync == nil ? "—" : store.totalHealthSteps.formatted(), unit: "步")
            }

            if store.data.lastHealthStepSync != nil {
                let stepXP = store.totalHealthSteps / 1_000
                Text("已获得 \(stepXP.formatted()) XP · 累计每 1,000 步获得 1 XP")
                    .font(.caption).foregroundStyle(Palette.secondary)
                ProgressView(value: Double(store.totalHealthSteps % 1_000) / 1_000)
                    .tint(.orange)
                Text("距离下一个步数 XP 还差 \(1_000 - store.totalHealthSteps % 1_000) 步")
                    .font(.caption).foregroundStyle(Palette.secondary)
            } else {
                Text("连接后显示步数进度，累计每 1,000 步获得 1 XP。")
                    .font(.caption).foregroundStyle(Palette.secondary)
            }

            if let syncDate = store.data.lastHealthStepSync {
                Text("上次同步：\(syncDate.formatted(.dateTime.month().day().hour().minute()))")
                    .font(.caption2).foregroundStyle(Palette.secondary)
            }
            if let statusMessage {
                Text(statusMessage).font(.caption).foregroundStyle(Palette.secondary)
            }

            Button {
                Task { await sync(requestAccess: !hasRequestedAccess) }
            } label: {
                HStack {
                    if isSyncing { ProgressView() }
                    Text(hasRequestedAccess ? "同步 Apple 健康步数" : "连接 Apple 健康")
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(.orange)
            .disabled(isSyncing || !HealthSteps.isAvailable)

            if !HealthSteps.isAvailable {
                Text("此设备不支持 Apple 健康。请在 iPhone 上连接并同步步数。")
                    .font(.caption).foregroundStyle(Palette.secondary)
            }
        }
        .padding(18)
        .background(Palette.card, in: RoundedRectangle(cornerRadius: 18))
        .task {
            if hasRequestedAccess,
               store.data.lastHealthStepSync.map({ Date().timeIntervalSince($0) > 3_600 }) ?? true {
                await sync(requestAccess: false)
            }
        }
    }

    private func stepValue(_ title: String, value: String, unit: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(.caption).foregroundStyle(Palette.secondary)
            HStack(alignment: .firstTextBaseline, spacing: 3) {
                Text(value).font(.title3.weight(.semibold)).minimumScaleFactor(0.7).lineLimit(1)
                Text(unit).font(.caption).foregroundStyle(Palette.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Palette.background, in: RoundedRectangle(cornerRadius: 12))
    }

    @MainActor
    private func sync(requestAccess: Bool) async {
        guard !isSyncing else { return }
        isSyncing = true
        statusMessage = nil
        defer { isSyncing = false }
        do {
            let oldSteps = store.totalHealthSteps
            let oldXP = store.xp[.exercise] ?? 0
            let oldBadgeIDs = Set(store.badges.filter(\.isUnlocked).map(\.id))
            let days = try await HealthSteps.readDays(requestAccess: requestAccess)
            if days.isEmpty {
                statusMessage = AppLanguage.localized("这次未读取到步数，已保留已有数据。请在健康 App 检查数据与读取权限。")
            } else {
                store.replaceHealthStepDays(days)
                let stepChange = store.totalHealthSteps - oldSteps
                let xpChange = (store.xp[.exercise] ?? 0) - oldXP
                statusMessage = stepChange == 0
                    ? AppLanguage.localized("已同步，步数没有变化。")
                    : AppLanguage.format("已同步 %d 步（%+d 步，%+d XP）。", store.totalHealthSteps, stepChange, xpChange)
                let newBadges = store.badges.filter { $0.isUnlocked && !oldBadgeIDs.contains($0.id) }
                if !newBadges.isEmpty {
                    statusMessage = (statusMessage ?? "") + AppLanguage.format(" 新徽章：%@。", newBadges.map(\.title).joined(separator: AppLanguage.isEnglish ? ", " : "、"))
                }
            }
        } catch {
            statusMessage = AppLanguage.format("同步失败：%@", error.localizedDescription)
        }
    }
}
