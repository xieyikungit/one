import SwiftUI

struct WeeklyRecap {
    let start: Date
    let end: Date
    let entries: [LifeEntry]
    let stepDays: [HealthStepDay]
    let xpGained: Int
    let newBadges: [LifeBadge]
    let moduleCount: Int

    var isEmpty: Bool { entries.isEmpty && stepDays.isEmpty }
    var stepCount: Int { GameEngine.totalSteps(stepDays) }
}

enum WeeklyRecapEngine {
    static func recap(for date: Date, entries: [LifeEntry], stepDays: [HealthStepDay], calendar: Calendar = .current) -> WeeklyRecap {
        let interval = calendar.dateInterval(of: .weekOfYear, for: date)!
        let beforeWeek = entries.filter { $0.date < interval.start }
        let throughWeek = entries.filter { $0.date < interval.end }
        let stepsBeforeWeek = stepDays.filter { $0.date < interval.start }
        let stepsThroughWeek = stepDays.filter { $0.date < interval.end }
        let weeklyEntries = entries.filter { $0.date >= interval.start && $0.date < interval.end }
            .sorted { $0.date > $1.date }
        let weeklySteps = stepDays.filter { $0.date >= interval.start && $0.date < interval.end }
        let xpBefore = GameEngine.xpByModule(beforeWeek, stepDays: stepsBeforeWeek).values.reduce(0, +)
        let xpAfter = GameEngine.xpByModule(throughWeek, stepDays: stepsThroughWeek).values.reduce(0, +)
        let badges = GameEngine.badges(entries: throughWeek, stepDays: stepsThroughWeek)
            .filter { badge in
                guard badge.isUnlocked, let date = badge.source?.date else { return false }
                return date >= interval.start && date < interval.end
            }
            .sorted { ($0.source?.date ?? .distantPast) > ($1.source?.date ?? .distantPast) }
        var modules = Set(weeklyEntries.map { $0.kind.module })
        if !weeklySteps.isEmpty { modules.insert(.exercise) }
        return WeeklyRecap(start: interval.start, end: interval.end, entries: weeklyEntries,
                           stepDays: weeklySteps, xpGained: max(0, xpAfter - xpBefore),
                           newBadges: badges, moduleCount: modules.count)
    }
}

struct WeeklyRecapView: View {
    @EnvironmentObject private var store: LifeStore
    @State private var selectedWeek = Date()
    @State private var selectedBadge: LifeBadge?

    private var recap: WeeklyRecap {
        WeeklyRecapEngine.recap(for: selectedWeek, entries: store.data.entries,
                                stepDays: store.data.healthStepDays ?? [])
    }
    private var isCurrentWeek: Bool {
        Calendar.current.isDate(selectedWeek, equalTo: Date(), toGranularity: .weekOfYear)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                HStack(spacing: 12) {
                    Button {
                        moveWeek(-1)
                    } label: {
                        Image(systemName: "chevron.left").frame(width: 34, height: 34)
                    }
                    .accessibilityLabel("上一周")
                    Spacer()
                    VStack(spacing: 2) {
                        Text(AppDate.yearMonthDay(recap.start))
                        Text(AppDate.yearMonthDay(recap.end.addingTimeInterval(-1)))
                    }
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(1)
                    Spacer()
                    Button {
                        moveWeek(1)
                    } label: {
                        Image(systemName: "chevron.right").frame(width: 34, height: 34)
                    }
                    .accessibilityLabel("下一周")
                    .disabled(isCurrentWeek)
                }
                .padding(.horizontal, 8)

                VStack(alignment: .leading, spacing: 13) {
                    Label("这周留下了什么", systemImage: "sparkles.rectangle.stack")
                        .font(.subheadline.weight(.semibold)).foregroundStyle(.white.opacity(0.88))
                    HStack(alignment: .firstTextBaseline, spacing: 6) {
                        Text("+\(recap.xpGained)")
                            .font(.system(size: 42, weight: .bold, design: .rounded))
                        Text("XP").font(.headline)
                    }
                    .foregroundStyle(.white)
                    Text(AppLanguage.format("%d 段经历 · %d 个领域 · %d 枚新徽章", recap.entries.count, recap.moduleCount, recap.newBadges.count))
                        .font(.subheadline).foregroundStyle(.white.opacity(0.88))
                    if recap.stepCount > 0 {
                        Text(AppLanguage.format("Apple 健康记录了 %d 步", recap.stepCount))
                            .font(.caption).foregroundStyle(.white.opacity(0.78))
                    }
                }
                .padding(20)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(LinearGradient(colors: [Palette.accent, .indigo], startPoint: .topLeading, endPoint: .bottomTrailing),
                            in: RoundedRectangle(cornerRadius: 22))

                if recap.isEmpty {
                    EmptyState(symbol: "calendar", title: "这一周还没有记录", detail: "想起值得记住的一件事时，回到首页选一个领域记录下来。")
                } else {
                    if let highlight = recap.entries.first {
                        VStack(alignment: .leading, spacing: 8) {
                            Label("本周一刻", systemImage: "bookmark.fill")
                                .font(.caption.weight(.semibold)).foregroundStyle(Palette.accent)
                            Text(highlight.summary).font(.headline)
                            Text("\(highlight.kind.module.title) · \(AppDate.yearMonthDay(highlight.date))")
                                .font(.caption).foregroundStyle(Palette.secondary)
                        }
                        .padding(18)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Palette.card, in: RoundedRectangle(cornerRadius: 18))
                    }

                    if !recap.newBadges.isEmpty {
                        Text("本周解锁").font(.title3.weight(.semibold))
                        ScrollView(.horizontal) {
                            HStack(spacing: 16) {
                                ForEach(recap.newBadges) { badge in
                                    Button { selectedBadge = badge } label: {
                                        VStack(spacing: 8) {
                                            BadgeMark(badge: badge, size: 64)
                                            Text(badge.title).font(.caption.weight(.medium)).lineLimit(1)
                                        }
                                        .frame(width: 100)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                        .scrollIndicators(.hidden)
                    }

                    if !recap.entries.isEmpty {
                        Text("本周经历").font(.title3.weight(.semibold))
                        ForEach(recap.entries) { entry in
                            HStack(spacing: 12) {
                                Image(systemName: entry.kind.symbol)
                                    .foregroundStyle(Palette.tint(for: entry.kind.module))
                                    .frame(width: 32)
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(entry.summary).font(.subheadline.weight(.semibold))
                                    Text("\(entry.kind.module.title) · \(AppDate.yearMonthDay(entry.date))")
                                        .font(.caption).foregroundStyle(Palette.secondary)
                                }
                                Spacer()
                            }
                            .padding(14)
                            .background(Palette.card, in: RoundedRectangle(cornerRadius: 16))
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
        }
        .background(Palette.background)
        .navigationTitle("本周回顾")
        .sheet(item: $selectedBadge) { BadgeDetailView(badge: $0) }
    }

    private func moveWeek(_ offset: Int) {
        guard let next = Calendar.current.date(byAdding: .weekOfYear, value: offset, to: selectedWeek) else { return }
        selectedWeek = next
    }
}
