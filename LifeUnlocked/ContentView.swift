import SwiftUI
import MapKit

enum Palette {
    static let background = Color(uiColor: .systemGroupedBackground)
    static let card = Color(uiColor: .secondarySystemGroupedBackground)
    static let accent = Color.blue
    static let secondary = Color(uiColor: .secondaryLabel)
    static let separator = Color(uiColor: .separator)
    static func tint(for module: LifeModule) -> Color {
        switch module {
        case .exercise: .orange
        case .learning: .indigo
        case .travel: .blue
        case .love: .pink
        case .family: .teal
        case .career: .brown
        case .creation: .purple
        case .lifeSkills: .green
        case .wellness: .red
        case .experiences: .cyan
        case .pets: .brown
        case .challenges: .mint
        case .relationships: .pink
        case .assets: .brown
        case .finance: .indigo
        }
    }
}

struct ContentView: View {
    @EnvironmentObject private var store: LifeStore

    var body: some View {
        TabView {
            HomeView()
                .tabItem { Label("首页", systemImage: "sparkles.rectangle.stack") }
            EntriesView()
                .tabItem { Label("经历", systemImage: "list.bullet.rectangle") }
            AchievementsView()
                .tabItem { Label("成就", systemImage: "rosette") }
            ProfileView()
                .tabItem { Label("我的", systemImage: "person.crop.circle") }
        }
        .tint(Palette.accent)
        .background(Palette.background)
        .sheet(item: $store.recentReward) { reward in RewardView(reward: reward) }
        .alert("提示", isPresented: Binding(
            get: { store.errorMessage != nil },
            set: { if !$0 { store.errorMessage = nil } }
        )) { Button("知道了") { store.errorMessage = nil } } message: {
            Text(store.errorMessage ?? "")
        }
    }
}

struct HomeView: View {
    @EnvironmentObject private var store: LifeStore
    @AppStorage("lifeBackfillSeen") private var lifeBackfillSeen = false
    @AppStorage("showTimeEcho") private var showTimeEcho = true
    @State private var showBackfill = false
    @State private var showAllGrowthModules = false
    private var rankedGrowthModules: [LifeModule] {
        LifeModule.allCases.enumerated()
            .sorted { lhs, rhs in
                let leftXP = store.xp[lhs.element] ?? 0
                let rightXP = store.xp[rhs.element] ?? 0
                return leftXP == rightXP ? lhs.offset < rhs.offset : leftXP > rightXP
            }
            .map(\.element)
    }
    private var visibleGrowthModules: [LifeModule] {
        showAllGrowthModules ? rankedGrowthModules : Array(rankedGrowthModules.prefix(6))
    }
    private var recentBadges: [LifeBadge] {
        store.badges.filter(\.isUnlocked).sorted { ($0.source?.date ?? .distantPast) > ($1.source?.date ?? .distantPast) }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    TotalLevelCard()

                    HStack(spacing: 12) {
                        MiniStat(value: "\(store.data.entries.count)", label: "段经历", symbol: "calendar")
                        MiniStat(value: "\(recentBadges.count)", label: "枚徽章", symbol: "rosette")
                    }

                    NavigationLink {
                        AnnualRecapView()
                    } label: {
                        HStack(spacing: 14) {
                            Image(systemName: "calendar.badge.clock")
                                .font(.title3)
                                .foregroundStyle(Palette.accent)
                                .frame(width: 44, height: 44)
                                .background(Palette.accent.opacity(0.10), in: RoundedRectangle(cornerRadius: 13))
                            VStack(alignment: .leading, spacing: 4) {
                                Text("人生年鉴").font(.headline).foregroundStyle(.primary)
                                Text("回看这一年的成长与解锁").font(.caption).foregroundStyle(Palette.secondary)
                            }
                            Spacer()
                            Image(systemName: "chevron.right").font(.caption.weight(.semibold)).foregroundStyle(Palette.secondary)
                        }
                        .padding(16)
                        .background(Palette.card, in: RoundedRectangle(cornerRadius: 18))
                    }
                    .buttonStyle(.plain)

                    NavigationLink {
                        WeeklyRecapView()
                    } label: {
                        HStack(spacing: 14) {
                            Image(systemName: "calendar")
                                .font(.title3).foregroundStyle(Palette.accent)
                                .frame(width: 44, height: 44)
                                .background(Palette.accent.opacity(0.10), in: RoundedRectangle(cornerRadius: 13))
                            VStack(alignment: .leading, spacing: 4) {
                                Text("本周回顾").font(.headline).foregroundStyle(.primary)
                                Text("看看这一周留下的经历与解锁")
                                    .font(.caption).foregroundStyle(Palette.secondary)
                            }
                            Spacer()
                            Image(systemName: "chevron.right").font(.caption.weight(.semibold)).foregroundStyle(Palette.secondary)
                        }
                        .padding(16)
                        .background(Palette.card, in: RoundedRectangle(cornerRadius: 18))
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("weekly-recap")

                    NavigationLink {
                        LifeChaptersView()
                    } label: {
                        HStack(spacing: 14) {
                            Image(systemName: "book.pages.fill")
                                .font(.title3).foregroundStyle(Palette.accent)
                                .frame(width: 44, height: 44)
                                .background(Palette.accent.opacity(0.10), in: RoundedRectangle(cornerRadius: 13))
                            VStack(alignment: .leading, spacing: 4) {
                                Text("人生章节").font(.headline).foregroundStyle(.primary)
                                Text("把经历连成自己的成长故事").font(.caption).foregroundStyle(Palette.secondary)
                            }
                            Spacer()
                            Image(systemName: "chevron.right").font(.caption).foregroundStyle(Palette.secondary)
                        }
                        .padding(16)
                        .background(Palette.card, in: RoundedRectangle(cornerRadius: 18))
                    }
                    .buttonStyle(.plain)

                    if store.data.entries.count < 3 {
                        Button { showBackfill = true } label: {
                            Label("回填过去的经历", systemImage: "clock.arrow.circlepath")
                                .font(.subheadline.weight(.semibold))
                                .frame(maxWidth: .infinity)
                                .padding(16)
                                .background(Palette.accent.opacity(0.10), in: RoundedRectangle(cornerRadius: 16))
                        }
                        .buttonStyle(.plain)
                    }

                    if showTimeEcho, let echo = LifeStoryEngine.timeEcho(store.data.entries) {
                        VStack(alignment: .leading, spacing: 7) {
                            Label("时光回声", systemImage: "clock.arrow.circlepath")
                                .font(.caption.weight(.semibold)).foregroundStyle(Palette.accent)
                            Text(AppLanguage.format("%d 年前的今天", Calendar.current.component(.year, from: Date()) - Calendar.current.component(.year, from: echo.date)))
                                .font(.headline)
                            Text(echo.summary).font(.subheadline)
                            Text(AppDate.yearMonthDay(echo.date)).font(.caption).foregroundStyle(Palette.secondary)
                        }
                        .padding(18)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Palette.card, in: RoundedRectangle(cornerRadius: 18))
                    }

                    HStack {
                        Text("成长领域").font(.title3.weight(.semibold))
                        Spacer()
                        if rankedGrowthModules.count > 6 {
                            Button(showAllGrowthModules ? "收起" : "展开全部") {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    showAllGrowthModules.toggle()
                                }
                            }
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(Palette.accent)
                            .accessibilityIdentifier("toggle-growth-modules")
                        }
                    }
                    VStack(spacing: 12) {
                        ForEach(0..<((visibleGrowthModules.count + 1) / 2), id: \.self) { row in
                            HStack(spacing: 12) {
                                ForEach(Array(visibleGrowthModules.dropFirst(row * 2).prefix(2))) { module in
                                    NavigationLink {
                                        ModuleDetailView(module: module)
                                    } label: {
                                        ModuleCard(module: module)
                                    }
                                    .buttonStyle(.plain)
                                    .accessibilityIdentifier("module-\(module.rawValue)")
                                    .frame(maxWidth: .infinity)
                                }
                                if row * 2 + 1 >= visibleGrowthModules.count {
                                    Color.clear.frame(maxWidth: .infinity)
                                }
                            }
                        }
                    }

                    if let goal = store.data.goals.first {
                        let progress = GameEngine.goalProgress(goal, entries: store.data.entries)
                        VStack(alignment: .leading, spacing: 10) {
                            Label("个人目标", systemImage: "scope").font(.caption.weight(.semibold)).foregroundStyle(Palette.accent)
                            Text(goal.title).font(.subheadline.weight(.semibold))
                            ProgressView(value: min(progress / max(goal.target, 1), 1))
                                .tint(Palette.accent)
                            Text("\(progress.formatted(.number.precision(.fractionLength(0...1)))) / \(goal.target.formatted()) \(goal.metric.unit)")
                                .font(.caption).foregroundStyle(Palette.secondary)
                        }
                        .padding(18).frame(maxWidth: .infinity, alignment: .leading)
                        .background(Palette.card, in: RoundedRectangle(cornerRadius: 18))
                    }

                    HStack {
                        Text("最近徽章").font(.title3.weight(.semibold))
                        Spacer()
                    }
                    if recentBadges.isEmpty {
                        EmptyState(symbol: "rosette", title: "第一枚徽章正在等待你", detail: "完成一次五公里、读完一本书或到访一座城市")
                    } else {
                        ForEach(recentBadges.prefix(3)) { badge in
                            HStack(spacing: 12) {
                                BadgeMark(badge: badge, size: 38)
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(badge.title).font(.subheadline.weight(.semibold))
                                    Text(badge.module.title).font(.caption).foregroundStyle(Palette.secondary)
                                }
                                Spacer()
                                if let date = badge.source?.date {
                                    Text(date, format: .dateTime.month().day())
                                        .font(.caption).foregroundStyle(Palette.secondary)
                                }
                            }
                            .padding(14)
                            .background(Palette.card, in: RoundedRectangle(cornerRadius: 16))
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)
                .padding(.bottom, 28)
            }
            .background(Palette.background)
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                if store.data.entries.isEmpty && !lifeBackfillSeen {
                    lifeBackfillSeen = true
                    showBackfill = true
                }
            }
            .sheet(isPresented: $showBackfill) { LifeBackfillView() }
        }
    }
}

struct TotalLevelCard: View {
    @EnvironmentObject private var store: LifeStore

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(spacing: 20) {
                ZStack {
                    Circle().stroke(Palette.accent.opacity(0.12), lineWidth: 8)
                    Circle()
                        .trim(from: 0, to: store.totalProgress)
                        .stroke(Palette.accent, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                    VStack(spacing: 0) {
                        Text("等级").font(.caption2.weight(.medium)).foregroundStyle(Palette.secondary)
                        Text("\(store.totalLevel)").font(.system(size: 42, weight: .semibold, design: .rounded))
                            .foregroundStyle(Palette.accent)
                    }
                }
                .frame(width: 112, height: 112)
                VStack(alignment: .leading, spacing: 8) {
                    Text("人生等级").font(.title3.weight(.semibold))
                    Text("由各成长领域共同组成")
                        .font(.subheadline).foregroundStyle(Palette.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
            }
            HStack {
                Text("下一等级").font(.subheadline).foregroundStyle(Palette.secondary)
                Spacer()
                Text("\(Int(store.totalProgress * 100))%")
                    .font(.subheadline.weight(.semibold)).foregroundStyle(Palette.accent)
            }
            ProgressView(value: store.totalProgress).tint(Palette.accent)
        }
        .padding(22)
        .frame(maxWidth: .infinity)
        .background(Palette.card, in: RoundedRectangle(cornerRadius: 24))
        .overlay(RoundedRectangle(cornerRadius: 24).stroke(Palette.accent.opacity(0.10)))
    }
}

struct MiniStat: View {
    let value: String
    let label: String
    let symbol: String
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: symbol)
                .font(.title3)
                .foregroundStyle(Palette.accent)
                .frame(width: 34, height: 34)
                .background(Palette.accent.opacity(0.10), in: RoundedRectangle(cornerRadius: 10))
            VStack(alignment: .leading, spacing: 2) {
                Text(value).font(.title3.weight(.semibold))
                Text(label).font(.caption).foregroundStyle(Palette.secondary)
            }
            Spacer()
        }
        .padding(14)
        .frame(maxWidth: .infinity)
        .background(Palette.card, in: RoundedRectangle(cornerRadius: 16))
    }
}

struct ModuleCard: View {
    @EnvironmentObject private var store: LifeStore
    let module: LifeModule

    var body: some View {
        let xp = store.xp[module] ?? 0
        let level = store.levels[module] ?? 1
        let current = GameEngine.threshold(for: level)
        let next = GameEngine.threshold(for: level + 1)
        let progress = Double(xp - current) / Double(max(1, next - current))
        let tint = Palette.tint(for: module)
        VStack(alignment: .leading, spacing: 13) {
            HStack {
                Image(systemName: module.symbol)
                    .font(.title3)
                    .foregroundStyle(tint)
                    .frame(width: 40, height: 40)
                    .background(tint.opacity(0.11), in: RoundedRectangle(cornerRadius: 12))
                Spacer()
                Text("Lv.\(level)").font(.caption.weight(.semibold)).foregroundStyle(tint)
            }
            Text(module.title).font(.subheadline.weight(.semibold))
            ProgressView(value: progress).tint(tint)
            Text("\(xp) XP · 下一级 \(next) XP")
                .font(.caption2).foregroundStyle(Palette.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: 154)
        .background(Palette.card, in: RoundedRectangle(cornerRadius: 18))
    }
}

struct EntriesView: View {
    @EnvironmentObject private var store: LifeStore
    @State private var editingEntry: LifeEntry?
    @State private var searchText = ""
    @State private var selectedModule: LifeModule?

    private var visibleEntries: [LifeEntry] {
        store.sortedEntries.filter { entry in
            let matchesModule = selectedModule == nil || entry.kind.module == selectedModule
            let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
            let matchesSearch = query.isEmpty
                || entry.summary.localizedCaseInsensitiveContains(query)
                || (entry.note?.localizedCaseInsensitiveContains(query) ?? false)
                || entry.kind.module.title.localizedCaseInsensitiveContains(query)
            return matchesModule && matchesSearch
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if store.sortedEntries.isEmpty {
                    EmptyState(symbol: "square.and.pencil", title: "还没有记录", detail: "在首页选一个成长领域，记录第一段经历")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .padding(20)
                } else {
                    List {
                        Section {
                        if visibleEntries.isEmpty {
                            Text("没有找到匹配的经历")
                                .font(.subheadline)
                                .foregroundStyle(Palette.secondary)
                        }
                        ForEach(visibleEntries) { entry in
                            Button { editingEntry = entry } label: {
                              HStack(spacing: 12) {
                                Image(systemName: entry.kind.symbol)
                                    .foregroundStyle(Palette.tint(for: entry.kind.module))
                                    .frame(width: 30)
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(entry.kind.title).font(.caption).foregroundStyle(Palette.secondary)
                                    Text(entry.summary).font(.subheadline.weight(.semibold))
                                    if let note = entry.note, !note.isEmpty {
                                        Text(note).font(.caption).foregroundStyle(Palette.secondary).lineLimit(2)
                                    }
                                }
                                Spacer()
                                Text(entry.date, format: .dateTime.month().day())
                                    .font(.caption).foregroundStyle(Palette.secondary)
                              }
                            }
                            .buttonStyle(.plain)
                        }
                        .onDelete { offsets in
                            for index in offsets { store.delete(visibleEntries[index]) }
                        }
                        } header: {
                            Text(AppLanguage.format("共 %d 段经历", visibleEntries.count))
                        }
                    }
                    .listStyle(.insetGrouped)
                    .scrollContentBackground(.hidden)
                }
            }
            .background(Palette.background)
            .navigationTitle("经历")
            .searchable(text: $searchText, prompt: "搜索经历或备注")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Picker("筛选成长领域", selection: $selectedModule) {
                            Text("全部领域").tag(LifeModule?.none)
                            ForEach(LifeModule.allCases) { module in
                                Text(module.title).tag(Optional(module))
                            }
                        }
                    } label: {
                        Label("筛选", systemImage: selectedModule == nil ? "line.3.horizontal.decrease.circle" : "line.3.horizontal.decrease.circle.fill")
                    }
                    .accessibilityIdentifier("filter-experiences")
                }
            }
            .sheet(item: $editingEntry) { EntryFormView(existing: $0) }
        }
    }
}

struct AchievementsView: View {
    @EnvironmentObject private var store: LifeStore

    private var mappedPlaces: [LifeEntry] {
        store.data.entries.filter { $0.kind == .trip && $0.latitude != nil && $0.longitude != nil }
    }
    private var trips: [LifeEntry] { store.data.entries.filter { $0.kind == .trip } }
    private var cityCount: Int {
        Set(trips.map { GameEngine.normalized($0.country) + "|" + GameEngine.normalized($0.city) }
            .filter { !$0.hasSuffix("|") }).count
    }
    private var countryCount: Int {
        Set(trips.map { GameEngine.normalized($0.country) }.filter { !$0.isEmpty }).count
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    HStack(alignment: .firstTextBaseline, spacing: 7) {
                        Text("\(store.badges.filter(\.isUnlocked).count)")
                            .font(.system(size: 34, weight: .bold, design: .rounded))
                        Text("/ \(store.badges.count) 枚徽章")
                            .font(.subheadline).foregroundStyle(Palette.secondary)
                    }
                    .padding(.bottom, 4)
                    BadgeShelf(title: "跨领域成就", badges: store.badges.filter { $0.id.hasPrefix("combo-") })
                    ForEach(LifeModule.allCases) { module in
                        BadgeShelf(title: AppLanguage.format("%@徽章", module.title), badges: store.badges.filter { $0.module == module && !$0.id.hasPrefix("combo-") })
                    }

                    NavigationLink {
                        PersonalRecordsView()
                    } label: {
                        HStack {
                            Label("个人纪录册", systemImage: "list.star").font(.headline).foregroundStyle(.primary)
                            Spacer()
                            Image(systemName: "chevron.right").font(.caption).foregroundStyle(Palette.secondary)
                        }
                        .padding(18)
                        .background(Palette.card, in: RoundedRectangle(cornerRadius: 18))
                    }
                    .buttonStyle(.plain)

                    VStack(alignment: .leading, spacing: 12) {
                        Text("去过的地方").font(.title3.weight(.semibold))
                        if mappedPlaces.isEmpty {
                            EmptyState(symbol: "map", title: "地图等待你的足迹", detail: "记录到访的城市后，这里会出现标记")
                        } else {
                            Map(initialPosition: .automatic) {
                                ForEach(mappedPlaces) { entry in
                                    Marker(entry.city ?? entry.country ?? "到访", coordinate: CLLocationCoordinate2D(latitude: entry.latitude!, longitude: entry.longitude!))
                                }
                            }
                            .frame(height: 240)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                    }
                    .padding(18)
                    .background(Palette.card, in: RoundedRectangle(cornerRadius: 20))

                    HStack(spacing: 10) {
                        travelStat("城市", value: "\(cityCount)", symbol: "mappin")
                        travelStat("国家", value: "\(countryCount)", symbol: "globe")
                        travelStat("高铁", value: "\(trips.filter { $0.tripMode == .train }.count)", symbol: "tram.fill")
                        travelStat("飞行", value: "\(trips.filter { $0.tripMode == .flight }.count)", symbol: "airplane")
                    }
                    let trainKM = trips.filter { $0.tripMode == .train }.reduce(0.0) { $0 + ($1.distanceKM ?? 0) }
                    let flightKM = trips.filter { $0.tripMode == .flight }.reduce(0.0) { $0 + ($1.distanceKM ?? 0) }
                    Text("高铁 \(Int(trainKM)) 公里 · 飞行 \(Int(flightKM)) 公里")
                        .font(.caption).foregroundStyle(Palette.secondary)

                    Text(AppLanguage.format("人生印记 · %d", store.achievements.count)).font(.title3.weight(.semibold))
                    if store.achievements.isEmpty {
                        EmptyState(symbol: "square.stack", title: "经历印记等待点亮", detail: "普通经历与称号会在这里留下记录")
                    } else {
                        ForEach(store.achievements) { achievement in
                            AchievementRow(achievement: achievement)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)
                .padding(.bottom, 28)
            }
            .background(Palette.background)
            .navigationTitle("成就")
        }
    }

    private func travelStat(_ title: String, value: String, symbol: String) -> some View {
        VStack(spacing: 5) {
            Image(systemName: symbol).foregroundStyle(Palette.accent)
            Text(value).font(.headline)
            Text(title).font(.caption2).foregroundStyle(Palette.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Palette.card, in: RoundedRectangle(cornerRadius: 16))
    }
}

struct AchievementRow: View {
    let achievement: Achievement
    var body: some View {
        HStack(spacing: 13) {
            Image(systemName: achievement.symbol)
                .font(.title3).foregroundStyle(Palette.accent)
                .frame(width: 42, height: 42)
                .background(Palette.accent.opacity(0.10), in: RoundedRectangle(cornerRadius: 12))
            VStack(alignment: .leading, spacing: 3) {
                Text(achievement.title).font(.subheadline.weight(.semibold))
                Text(achievement.detail).font(.caption).foregroundStyle(Palette.secondary)
            }
            Spacer()
            Text(AppDate.yearMonthDay(achievement.date))
                .font(.caption2)
                .foregroundStyle(Palette.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .padding(16)
        .background(Palette.card, in: RoundedRectangle(cornerRadius: 16))
    }
}

struct EmptyState: View {
    let symbol: String
    let title: String
    let detail: String
    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: symbol)
                .font(.title2)
                .foregroundStyle(Palette.accent)
                .frame(width: 50, height: 50)
                .background(Palette.accent.opacity(0.09), in: Circle())
            Text(title).font(.subheadline.weight(.semibold))
            Text(detail).font(.caption).foregroundStyle(Palette.secondary).multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(22)
        .background(Palette.card, in: RoundedRectangle(cornerRadius: 16))
    }
}

struct RewardView: View {
    @Environment(\.dismiss) private var dismiss
    let reward: Reward
    private var tint: Color { Palette.tint(for: reward.module) }
    private var nextLevelXP: Int { GameEngine.threshold(for: reward.newModuleLevel + 1) }
    private var progress: Double {
        let currentLevelXP = GameEngine.threshold(for: reward.newModuleLevel)
        return Double(reward.newModuleXP - currentLevelXP) / Double(max(1, nextLevelXP - currentLevelXP))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                Image(systemName: reward.newBadges.isEmpty ? reward.module.symbol : "star.fill")
                    .font(.system(size: 26, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 64, height: 64)
                    .background(tint, in: Circle())
                    .symbolEffect(.bounce, value: reward.newBadges.count)
                Text("经历已收录").font(.title2.weight(.semibold))
                Text(reward.title).font(.subheadline).foregroundStyle(Palette.secondary)
                    .multilineTextAlignment(.center)
                Text("+\(reward.xpGained) XP")
                    .font(.system(size: 34, weight: .semibold, design: .rounded))
                    .foregroundStyle(tint)

                VStack(alignment: .leading, spacing: 8) {
                    Label("本次点亮", systemImage: "sparkles")
                        .font(.caption.weight(.semibold)).foregroundStyle(tint)
                    Text(reward.impact.title).font(.headline)
                    Text(reward.impact.detail).font(.subheadline).foregroundStyle(Palette.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(18)
                .background(tint.opacity(0.09), in: RoundedRectangle(cornerRadius: 18))

                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text(AppLanguage.format("%@成长", reward.module.title)).font(.subheadline.weight(.semibold))
                        Spacer()
                        Text("\(reward.oldModuleXP) → \(reward.newModuleXP) XP")
                            .font(.caption.weight(.medium)).foregroundStyle(tint)
                    }
                    ProgressView(value: progress).tint(tint)
                    Text(AppLanguage.format("距离 %@ Lv.%d 还差 %d XP", reward.module.title, reward.newModuleLevel + 1, nextLevelXP - reward.newModuleXP))
                        .font(.caption).foregroundStyle(Palette.secondary)
                    HStack(spacing: 12) {
                        levelPill(reward.module.title, old: reward.oldModuleLevel, new: reward.newModuleLevel)
                        levelPill("人生", old: reward.oldTotalLevel, new: reward.newTotalLevel)
                    }
                }
                .padding(18)
                .background(Palette.card, in: RoundedRectangle(cornerRadius: 18))

                if !reward.newBadges.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("本次解锁徽章").font(.subheadline.weight(.semibold))
                        ForEach(reward.newBadges.prefix(3)) { badge in
                            HStack(spacing: 12) {
                                BadgeMark(badge: badge, size: 36)
                                Text(badge.title).font(.subheadline.weight(.medium))
                                Spacer()
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(tint)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(18)
                    .background(Palette.card, in: RoundedRectangle(cornerRadius: 18))
                }

                VStack(alignment: .leading, spacing: 7) {
                    Text("下一步").font(.caption.weight(.semibold)).foregroundStyle(tint)
                    Text(reward.nextMilestone).font(.subheadline)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(18)
                .background(Palette.card, in: RoundedRectangle(cornerRadius: 18))

            }
            .padding(24)
        }
        .safeAreaInset(edge: .bottom) {
            Button("继续探索") { dismiss() }
                .font(.headline).frame(maxWidth: .infinity).padding(15)
                .background(Palette.accent, in: RoundedRectangle(cornerRadius: 14))
                .foregroundStyle(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(Palette.background)
        }
        .background(Palette.background)
        .presentationDragIndicator(.visible)
        .presentationDetents([.large])
    }

    private func levelPill(_ label: String, old: Int, new: Int) -> some View {
        VStack(spacing: 4) {
            Text(label).font(.caption).foregroundStyle(Palette.secondary)
            Text(old == new ? "Lv.\(new)" : "Lv.\(old) → Lv.\(new)")
                .font(.subheadline.bold()).foregroundStyle(Palette.accent)
        }
        .frame(maxWidth: .infinity).padding(12)
        .background(Palette.card, in: RoundedRectangle(cornerRadius: 14))
    }
}
