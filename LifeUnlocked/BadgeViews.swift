import SwiftUI

struct BadgeShelf: View {
    let title: String
    let badges: [LifeBadge]
    var showsPreview = false
    @State private var selectedBadge: LifeBadge?
    @State private var expanded = false

    private var ordered: [LifeBadge] {
        badges.sorted {
            if $0.isUnlocked != $1.isUnlocked { return $0.isUnlocked }
            if let first = $0.source?.date, let second = $1.source?.date { return first > second }
            return $0.fraction > $1.fraction
        }
    }

    private var visible: [LifeBadge] {
        showsPreview && !expanded ? Array(ordered.prefix(3)) : ordered
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .firstTextBaseline) {
                Text(title).font(.title3.weight(.semibold))
                Spacer()
                Text(AppLanguage.format("已解锁 %d/%d", badges.filter(\.isUnlocked).count, badges.count))
                    .font(.caption).foregroundStyle(Palette.secondary)
            }
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 3), spacing: 24) {
                ForEach(visible) { badge in
                    Button { selectedBadge = badge } label: { BadgeTile(badge: badge) }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier("badge-\(badge.id)")
                }
            }
            if showsPreview && ordered.count > 3 {
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) { expanded.toggle() }
                } label: {
                    HStack(spacing: 4) {
                        Text(expanded ? AppLanguage.localized("收起徽章") : AppLanguage.format("查看全部 %d 枚", ordered.count))
                        Image(systemName: expanded ? "chevron.up" : "chevron.right")
                    }
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Palette.accent)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                }
                .buttonStyle(.plain)
            }
        }
        .sheet(item: $selectedBadge) { badge in BadgeDetailView(badge: badge) }
    }
}

struct BadgeMark: View {
    let badge: LifeBadge
    var size: CGFloat = 80
    private var tint: Color { Palette.tint(for: badge.module) }

    var body: some View {
        ZStack {
            Circle()
                .fill(
                    badge.isUnlocked
                    ? LinearGradient(colors: [tint, tint.opacity(0.75)], startPoint: .topLeading, endPoint: .bottomTrailing)
                    : LinearGradient(colors: [Color(uiColor: .systemGray4), Color(uiColor: .systemGray5)], startPoint: .topLeading, endPoint: .bottomTrailing)
                )
            Circle()
                .strokeBorder(.white.opacity(badge.isUnlocked ? 0.65 : 0.45), lineWidth: max(1, size * 0.025))
                .padding(size * 0.085)
            Image(systemName: badge.symbol)
                .font(.system(size: size * 0.38, weight: .semibold))
                .foregroundStyle(badge.isUnlocked ? .white : Color(uiColor: .systemGray2))
        }
            .frame(width: size, height: size)
            .overlay(alignment: .bottomTrailing) {
                if !badge.isUnlocked {
                    Image(systemName: "lock.fill")
                        .font(.system(size: size * 0.15, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: size * 0.27, height: size * 0.27)
                        .background(Color(uiColor: .systemGray2), in: Circle())
                }
            }
            .accessibilityHidden(true)
    }
}

private struct BadgeTile: View {
    let badge: LifeBadge

    var body: some View {
        VStack(spacing: 7) {
            BadgeMark(badge: badge)
            Text(badge.title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.primary)
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .frame(height: 33, alignment: .top)
            Text(badge.isUnlocked ? AppDate.yearMonthDay(badge.source!.date) : badge.progressText)
                .font(.caption2)
                .foregroundStyle(Palette.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
        .frame(maxWidth: .infinity)
    }
}

struct BadgeDetailView: View {
    @Environment(\.dismiss) private var dismiss
    let badge: LifeBadge
    private var tint: Color { Palette.tint(for: badge.module) }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 14) {
                    BadgeMark(badge: badge, size: 62)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(badge.title).font(.headline)
                        Text(AppLanguage.format(badge.isUnlocked ? "已解锁 · %@" : "尚未解锁 · %@", badge.module.title))
                            .font(.caption).foregroundStyle(Palette.secondary)
                    }
                    Spacer(minLength: 4)
                    Button("完成", systemImage: "xmark.circle.fill") { dismiss() }
                        .labelStyle(.iconOnly)
                        .font(.title2)
                        .foregroundStyle(Palette.secondary)
                }

                VStack(alignment: .leading, spacing: 9) {
                    Text("解锁条件").font(.subheadline.weight(.semibold))
                    Text(badge.rule).font(.subheadline)
                    ProgressView(value: badge.fraction).tint(tint)
                    HStack {
                        Text("当前进度").foregroundStyle(Palette.secondary)
                        Spacer()
                        Text(badge.progressText).foregroundStyle(tint)
                    }
                    .font(.caption.weight(.medium))
                    Text(badge.repeatRule).font(.caption).foregroundStyle(Palette.secondary)
                }
                .padding(15)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Palette.card, in: RoundedRectangle(cornerRadius: 16))

                if let source = badge.source {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("解锁记录").font(.subheadline.weight(.semibold)).foregroundStyle(.primary)
                        Text(source.summary).font(.subheadline).foregroundStyle(.primary)
                        Text(AppLanguage.format("达成日期：%@", AppDate.yearMonthDay(source.date)))
                            .font(.caption).foregroundStyle(Palette.secondary)
                        Text(AppLanguage.format("数据来源：%@", source.origin))
                            .font(.caption).foregroundStyle(Palette.secondary)
                    }
                    .padding(15)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Palette.card, in: RoundedRectangle(cornerRadius: 16))
                } else {
                    Text("达到条件后，这里会显示触发解锁的经历。")
                        .font(.caption).foregroundStyle(Palette.secondary)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 12)
        }
        .background(Palette.background)
        .presentationDragIndicator(.visible)
        .presentationDetents([.height(badge.isUnlocked ? 375 : 305)])
    }
}
