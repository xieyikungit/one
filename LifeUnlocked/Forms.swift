import SwiftUI
import UniformTypeIdentifiers

struct EntryFormView: View {
    @EnvironmentObject private var store: LifeStore
    @Environment(\.dismiss) private var dismiss
    var existing: LifeEntry? = nil
    var initialKind: EntryKind = .run

    @State private var kind: EntryKind = .run
    @State private var date = Date()
    @State private var title = ""
    @State private var author = ""
    @State private var distance = ""
    @State private var amountML = ""
    @State private var stage = ""
    @State private var city = ""
    @State private var country = ""
    @State private var origin = ""
    @State private var tripMode: TripMode = .visit
    @State private var financeGoalType: FinanceGoalType = .savings
    @State private var financeTarget = ""
    @State private var financeCurrent = ""
    @State private var selectedFinanceGoalKey = "new"
    @State private var careerCategory: CareerMilestoneCategory = .starting
    @State private var careerChoice: CareerMilestoneChoice = .firstJob
    @State private var careerDetails = ""
    @State private var careerCompany = ""
    @State private var careerPosition = ""
    @State private var vehicleType: VehicleType = .car
    @State private var note = ""
    @State private var choosingDate = false

    private var tint: Color { Palette.tint(for: kind.module) }
    private var isChoosingAssetKind: Bool {
        existing == nil && (initialKind == .livingMilestone || initialKind == .vehicleMilestone)
    }
    private var isChoosingLearningKind: Bool {
        existing == nil && initialKind.module == .learning
    }
    private var kindName: String {
        switch kind {
        case .run: AppLanguage.localized("跑步")
        case .cycling: AppLanguage.localized("骑行")
        case .learnedSport: AppLanguage.localized("学会运动")
        case .finishedBook: AppLanguage.localized("读完一本书")
        case .degree: AppLanguage.localized("学历")
        case .certificate: AppLanguage.localized("证书")
        case .languageMilestone: AppLanguage.localized("语言进阶")
        case .trip: AppLanguage.localized("旅行")
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
    private var dateTitle: String {
        if kind == .financialMilestone { return "记录日期" }
        if kind == .vehicleMilestone { return "获得日期" }
        if kind == .careerMilestone { return "发生日期" }
        return "完成日期"
    }
    private var dateText: String {
        AppDate.yearMonthDay(date)
    }

    private var distanceValue: Double? {
        Double(distance.replacingOccurrences(of: ",", with: "."))
    }
    private var financeTargetValue: Double? {
        Double(financeTarget.replacingOccurrences(of: ",", with: "."))
    }
    private var financeCurrentValue: Double? {
        Double(financeCurrent.replacingOccurrences(of: ",", with: "."))
    }
    private var financeGoalEntries: [LifeEntry] {
        var seen = Set<String>()
        return store.sortedEntries.filter { $0.kind == .financialMilestone }
            .filter { seen.insert(GameEngine.financeGoalKey(for: $0) ?? GameEngine.normalized($0.title)).inserted }
    }
    private var valid: Bool {
        switch kind {
        case .run, .cycling: return (distanceValue ?? 0) > 0
        case .learnedSport, .finishedBook, .degree, .certificate, .kindness, .familyMoment, .creativeWork, .lifeSkill, .wellnessAction, .lifeExperience, .petMoment, .completedChallenge, .relationshipMoment, .livingMilestone: return !title.trimmingCharacters(in: .whitespaces).isEmpty
        case .vehicleMilestone: return !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        case .careerMilestone:
            return !careerCompany.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                && (careerChoice != .other || !careerDetails.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        case .financialMilestone:
            return !title.trimmingCharacters(in: .whitespaces).isEmpty
                && (financeTargetValue ?? 0) > 0
                && (financeCurrentValue ?? -1) >= 0
        case .languageMilestone:
            return !title.trimmingCharacters(in: .whitespaces).isEmpty && !stage.trimmingCharacters(in: .whitespaces).isEmpty
        case .bloodDonation: return (Int(amountML) ?? 0) > 0
        case .trip:
            return (!city.trimmingCharacters(in: .whitespaces).isEmpty || !country.trimmingCharacters(in: .whitespaces).isEmpty)
                && (tripMode == .visit || ((distanceValue ?? 0) > 0 && !origin.trimmingCharacters(in: .whitespaces).isEmpty))
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    HStack(spacing: 12) {
                        Image(systemName: kind.symbol)
                            .font(.title2)
                            .foregroundStyle(tint)
                            .frame(width: 48, height: 48)
                            .background(tint.opacity(0.12), in: RoundedRectangle(cornerRadius: 14))
                        VStack(alignment: .leading, spacing: 3) {
                            Text(kindName).font(.title3.weight(.semibold))
                            Text(AppLanguage.format("%@经历", kind.module.title))
                                .font(.subheadline).foregroundStyle(Palette.secondary)
                        }
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        Text(AppLanguage.localized(dateTitle)).font(.subheadline.weight(.semibold))
                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) { choosingDate.toggle() }
                        } label: {
                            HStack {
                                Image(systemName: "calendar").foregroundStyle(tint)
                                Text(dateText).foregroundStyle(.primary)
                                Spacer()
                                Image(systemName: choosingDate ? "chevron.up" : "chevron.down")
                                    .font(.caption).foregroundStyle(Palette.secondary)
                            }
                            .font(.subheadline)
                            .padding(14)
                            .background(Palette.background, in: RoundedRectangle(cornerRadius: 12))
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier("entry-date")
                        if choosingDate {
                            DatePicker(AppLanguage.localized(dateTitle), selection: $date, in: ...Date(), displayedComponents: .date)
                                .datePickerStyle(.graphical)
                                .tint(tint)
                        }
                    }
                    .padding(16)
                    .background(Palette.card, in: RoundedRectangle(cornerRadius: 18))

                    VStack(alignment: .leading, spacing: 14) {
                        Text("记录内容").font(.subheadline.weight(.semibold))
                        if isChoosingAssetKind {
                            Picker("资产类型", selection: $kind) {
                                Text("居住经历").tag(EntryKind.livingMilestone)
                                Text("私人交通工具").tag(EntryKind.vehicleMilestone)
                            }
                            .pickerStyle(.segmented)
                        } else if isChoosingLearningKind {
                            Picker("学习记录类型", selection: $kind) {
                                Text("阅读").tag(EntryKind.finishedBook)
                                Text("语言进阶").tag(EntryKind.languageMilestone)
                                Text("学历").tag(EntryKind.degree)
                                Text("证书").tag(EntryKind.certificate)
                            }
                            .pickerStyle(.menu)
                        }
                        entryFields
                    }
                    .padding(16)
                    .background(Palette.card, in: RoundedRectangle(cornerRadius: 18))

                    VStack(alignment: .leading, spacing: 12) {
                        Text("补充内容").font(.subheadline.weight(.semibold))
                        TextField("想记下的感受或细节", text: $note, axis: .vertical)
                            .lineLimit(2...4)
                            .padding(14)
                            .background(Palette.background, in: RoundedRectangle(cornerRadius: 12))
                        Text("可选，之后也能补充").font(.caption).foregroundStyle(Palette.secondary)
                    }
                    .padding(16)
                    .background(Palette.card, in: RoundedRectangle(cornerRadius: 18))
                }
                .padding(20)
            }
            .background(Palette.background)
            .navigationTitle(existing == nil ? "新增经历" : "修改经历")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("取消") { dismiss() } }
            }
            .safeAreaInset(edge: .bottom) {
                Button("保存") { save() }
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(15)
                    .foregroundStyle(.white)
                    .background(valid ? tint : tint.opacity(0.4), in: RoundedRectangle(cornerRadius: 14))
                    .disabled(!valid)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Palette.background)
            }
            .onAppear(perform: loadExisting)
        }
        .tint(Palette.accent)
        .onChange(of: selectedFinanceGoalKey) { _, key in
            guard existing == nil else { return }
            if key == "new" {
                title = ""
                financeTarget = ""
                financeCurrent = ""
                financeGoalType = .savings
            } else if let goal = financeGoalEntries.first(where: { GameEngine.financeGoalKey(for: $0) == key }) {
                title = goal.title
                financeGoalType = goal.financeGoalType ?? .savings
                financeTarget = goal.financeTargetValue.map { String($0) } ?? ""
                financeCurrent = goal.financeCurrentValue.map { String($0) } ?? ""
            }
        }
        .onChange(of: careerCategory) { _, category in
            if !category.choices.contains(careerChoice) {
                careerChoice = category.choices.first ?? .other
            }
        }
        .onChange(of: kind) { oldKind, newKind in
            guard isChoosingAssetKind, oldKind != newKind else { return }
            title = ""
            if newKind == .vehicleMilestone { vehicleType = .car }
        }
        .onChange(of: kind) { oldKind, newKind in
            guard isChoosingLearningKind, oldKind != newKind else { return }
            title = ""
            author = ""
            stage = ""
        }
    }

    @ViewBuilder
    private var entryFields: some View {
        switch kind {
        case .run:
            input("跑步距离", placeholder: "公里数，例如 8.5", text: $distance, keyboard: .decimalPad)
            Text("按实际完成的公里数记录").font(.caption).foregroundStyle(Palette.secondary)
        case .cycling:
            input("骑行距离", placeholder: "公里数，例如 12.5", text: $distance, keyboard: .decimalPad)
            Text("每公里获得 3 XP，计入运动等级").font(.caption).foregroundStyle(Palette.secondary)
        case .learnedSport:
            input("运动名称", placeholder: "运动名称，例如 游泳", text: $title)
            Text("同一种运动只奖励一次").font(.caption).foregroundStyle(Palette.secondary)
        case .finishedBook:
            input("书名", placeholder: "书名", text: $title)
            input("作者", placeholder: "作者，可选", text: $author)
            Text("重读可记录，不重复获得书籍经验").font(.caption).foregroundStyle(Palette.secondary)
        case .degree:
            input("学历名称", placeholder: "例如 本科、硕士", text: $title)
            Text("填写取得该学历的日期，可分别记录多个学历")
                .font(.caption).foregroundStyle(Palette.secondary)
        case .certificate:
            input("证书名称", placeholder: "例如 注册会计师", text: $title)
            Text("填写取得证书的日期，可记录多张证书")
                .font(.caption).foregroundStyle(Palette.secondary)
        case .languageMilestone:
            input("语言名称", placeholder: "例如 英语、日语", text: $title)
            input("达到的水平", placeholder: "例如 入门、日常交流、流利", text: $stage)
            Text("首次记录一种语言水平获得 100 XP")
                .font(.caption).foregroundStyle(Palette.secondary)
        case .trip:
            Picker("方式", selection: $tripMode) {
                ForEach(TripMode.allCases) { Text($0.title).tag($0) }
            }
            .pickerStyle(.segmented)
            if tripMode != .visit {
                input("出发地", placeholder: "出发地", text: $origin)
                input("行程距离", placeholder: "行程公里数", text: $distance, keyboard: .decimalPad)
            }
            input("到达城市", placeholder: "实际到达的城市", text: $city)
            input("国家或地区", placeholder: "实际到达的国家或地区", text: $country)
            Text("经停和转机不计入到访地点")
                .font(.caption).foregroundStyle(Palette.secondary)
        case .kindness:
            input("善行内容", placeholder: "例如，参加社区志愿服务", text: $title)
            Text("每次记录一次真实的帮助行动或志愿服务，获得 50 XP")
                .font(.caption).foregroundStyle(Palette.secondary)
        case .bloodDonation:
            input("献血量（毫升）", placeholder: "例如 200", text: $amountML, keyboard: .numberPad)
            Text("记录本次献血量；每次献血获得 50 XP")
                .font(.caption).foregroundStyle(Palette.secondary)
        case .familyMoment:
            input("家庭经历", placeholder: "例如 一起庆祝孩子生日", text: $title)
            Text("记录重要的家庭纪念日或共同经历，每条获得 50 XP")
                .font(.caption).foregroundStyle(Palette.secondary)
        case .careerMilestone:
            Picker("经历类型", selection: $careerCategory) {
                ForEach(CareerMilestoneCategory.allCases) { category in
                    Text(category.title).tag(category)
                }
            }
            Picker("具体节点", selection: $careerChoice) {
                ForEach(careerCategory.choices) { choice in
                    Text(choice.title).tag(choice)
                }
            }
            input("公司名称（必填）", placeholder: "例如：公司、组织或雇主名称", text: $careerCompany)
            input("职位", placeholder: "例如：产品经理、教师、设计师（可选）", text: $careerPosition)
            input(careerChoice == .other ? "职业经历内容" : "补充具体内容（可选）",
                  placeholder: careerChoice.detailPlaceholder, text: $careerDetails)
            Text("公司名称为必填；职位和补充内容可选。每条不同职业经历首次记录获得 50 XP")
                .font(.caption).foregroundStyle(Palette.secondary)
        case .creativeWork:
            input("创作名称", placeholder: "例如 完成一幅画、发布一篇文章", text: $title)
            Text("记录完成或公开发布的作品；相同作品只获得一次 100 XP")
                .font(.caption).foregroundStyle(Palette.secondary)
        case .lifeSkill:
            input("技能名称", placeholder: "例如 学会做饭、急救或驾驶", text: $title)
            Text("记录已经掌握并能独立完成的实用技能；每项首次获得 100 XP")
                .font(.caption).foregroundStyle(Palette.secondary)
        case .wellnessAction:
            input("健康行动", placeholder: "例如 完成年度体检、坚持康复训练", text: $title)
            Text("记录已完成的健康维护行动；每次获得 50 XP。避免填写诊断等敏感细节")
                .font(.caption).foregroundStyle(Palette.secondary)
        case .lifeExperience:
            input("体验内容", placeholder: "例如 看一场演出、参观一座博物馆", text: $title)
            Text("记录真实参加的展览、演出、赛事或特别体验；每次获得 50 XP")
                .font(.caption).foregroundStyle(Palette.secondary)
        case .petMoment:
            input("宠物经历", placeholder: "例如 领养、第一次出游、完成训练", text: $title)
            input("宠物名字", placeholder: "可选", text: $stage)
            Text("记录陪伴宠物的重要时刻；每次获得 50 XP")
                .font(.caption).foregroundStyle(Palette.secondary)
        case .completedChallenge:
            input("挑战名称", placeholder: "例如 连续写作 30 天、完成一次徒步", text: $title)
            Text("只记录已经完成的个人挑战；每项不同挑战首次获得 100 XP")
                .font(.caption).foregroundStyle(Palette.secondary)
        case .relationshipMoment:
            input("关系时刻", placeholder: "例如 与老朋友重聚、一起完成一件重要的事", text: $title)
            Text("记录值得珍藏的人际时刻，不需要填写他人姓名；每次获得 50 XP")
                .font(.caption).foregroundStyle(Palette.secondary)
        case .livingMilestone:
            input("居住里程碑", placeholder: "例如 第一次独立居住、搬到新城市", text: $title)
            Text("记录搬迁、建立新家或居住阶段变化；每个不同里程碑首次获得 100 XP")
                .font(.caption).foregroundStyle(Palette.secondary)
        case .vehicleMilestone:
            Picker("交通工具类型", selection: $vehicleType) {
                ForEach(VehicleType.allCases) { type in Text(type.title).tag(type) }
            }
            input("交通工具名称", placeholder: "例如 特斯拉 Model 3、山地自行车", text: $title)
            Text("记录你拥有或购入的私人交通工具；每件不同交通工具首次登记获得 100 XP")
                .font(.caption).foregroundStyle(Palette.secondary)
        case .financialMilestone:
            Picker("选择或新建目标", selection: $selectedFinanceGoalKey) {
                Text("新建财务目标").tag("new")
                ForEach(financeGoalEntries) { goal in
                    let key = GameEngine.financeGoalKey(for: goal) ?? "new"
                    let label = goal.financeProgress.map { AppLanguage.format("%@ · %.0f%%", goal.title, $0 * 100) } ?? goal.title
                    Text(label).tag(key)
                }
            }
            Picker("目标类型", selection: $financeGoalType) {
                ForEach(FinanceGoalType.allCases) { Text($0.title).tag($0) }
            }
            .pickerStyle(.segmented)
            .disabled(selectedFinanceGoalKey != "new")
            input("目标名称", placeholder: "例如 应急储备金、提前还清房贷", text: $title)
                .disabled(selectedFinanceGoalKey != "new")
            input("目标金额", placeholder: "例如 30000", text: $financeTarget, keyboard: .decimalPad)
                .disabled(selectedFinanceGoalKey != "new")
            input(financeGoalType == .savings ? "目前已存金额" : "目前已偿还金额", placeholder: "例如 5000", text: $financeCurrent, keyboard: .decimalPad)
            Text("目标金额和当前金额使用同一货币单位。按完成比例计进度；每跨过 25%、50%、75%、100% 获得 50 XP。同一目标每个阶段只奖励一次，金额仅保存在本机")
                .font(.caption).foregroundStyle(Palette.secondary)
        }
    }

    private func input(
        _ label: String,
        placeholder: String,
        text: Binding<String>,
        keyboard: UIKeyboardType = .default
    ) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(AppLanguage.localized(label)).font(.caption.weight(.medium)).foregroundStyle(Palette.secondary)
            TextField(AppLanguage.localized(placeholder), text: text)
                .keyboardType(keyboard)
                .font(.subheadline)
                .padding(14)
                .background(Palette.background, in: RoundedRectangle(cornerRadius: 12))
        }
    }

    private func loadExisting() {
        kind = initialKind
        guard let existing else { return }
        kind = existing.kind
        date = existing.date
        title = existing.title
        author = existing.author ?? ""
        distance = existing.distanceKM.map { String($0) } ?? ""
        amountML = existing.amountML.map(String.init) ?? ""
        vehicleType = existing.vehicleType ?? .car
        stage = existing.stage ?? ""
        if existing.kind == .careerMilestone {
            if let choice = CareerMilestoneChoice(rawValue: existing.stage ?? "") {
                careerChoice = choice
                careerCategory = choice.category
                careerCompany = existing.careerCompany ?? ""
                careerPosition = existing.careerPosition ?? ""
                careerDetails = choice == .other ? existing.title : (existing.careerDetail ?? "")
            } else {
                careerCategory = .other
                careerChoice = .other
                careerDetails = existing.title
                careerCompany = existing.careerCompany ?? ""
                careerPosition = existing.careerPosition ?? ""
            }
        }
        financeGoalType = existing.financeGoalType ?? .savings
        financeTarget = existing.financeTargetValue.map { String($0) } ?? ""
        financeCurrent = existing.financeCurrentValue.map { String($0) } ?? ""
        selectedFinanceGoalKey = GameEngine.financeGoalKey(for: existing) ?? "new"
        city = existing.city ?? ""
        country = existing.country ?? ""
        origin = existing.origin ?? ""
        tripMode = existing.tripMode ?? .visit
        note = existing.note ?? ""
    }

    private func save() {
        var entry = existing ?? LifeEntry(kind: kind, date: date, title: "")
        entry.kind = kind
        entry.date = date
        let trimmedCareerDetails = careerDetails.trimmingCharacters(in: .whitespacesAndNewlines)
        let careerTitle = careerChoice == .other ? trimmedCareerDetails : careerChoice.title
        entry.title = kind == .run ? "跑步" : kind == .cycling ? "骑行" : kind == .trip ? "旅行" : kind == .bloodDonation ? "献血" : kind == .careerMilestone ? careerTitle : title.trimmingCharacters(in: .whitespacesAndNewlines)
        entry.distanceKM = kind == .run || kind == .cycling || (kind == .trip && tripMode != .visit) ? distanceValue : nil
        entry.author = kind == .finishedBook ? author.trimmingCharacters(in: .whitespacesAndNewlines) : nil
        entry.city = kind == .trip ? city.trimmingCharacters(in: .whitespacesAndNewlines) : nil
        entry.country = kind == .trip ? country.trimmingCharacters(in: .whitespacesAndNewlines) : nil
        entry.origin = kind == .trip && tripMode != .visit ? origin.trimmingCharacters(in: .whitespacesAndNewlines) : nil
        entry.tripMode = kind == .trip ? tripMode : nil
        entry.amountML = kind == .bloodDonation ? Int(amountML) : nil
        entry.stage = kind == .languageMilestone || kind == .petMoment
            ? stage.trimmingCharacters(in: .whitespacesAndNewlines)
            : kind == .careerMilestone ? careerChoice.rawValue : nil
        entry.careerCompany = kind == .careerMilestone ? careerCompany.trimmingCharacters(in: .whitespacesAndNewlines) : nil
        entry.careerPosition = kind == .careerMilestone && !careerPosition.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? careerPosition.trimmingCharacters(in: .whitespacesAndNewlines) : nil
        entry.careerDetail = kind == .careerMilestone && careerChoice != .other && !trimmedCareerDetails.isEmpty
            ? trimmedCareerDetails : nil
        entry.vehicleType = kind == .vehicleMilestone ? vehicleType : nil
        entry.financeGoalType = kind == .financialMilestone ? financeGoalType : nil
        entry.financeTargetValue = kind == .financialMilestone ? financeTargetValue : nil
        entry.financeCurrentValue = kind == .financialMilestone ? financeCurrentValue : nil
        entry.note = note.trimmingCharacters(in: .whitespacesAndNewlines)
        if kind == .trip && (entry.city != existing?.city || entry.country != existing?.country) {
            entry.latitude = nil
            entry.longitude = nil
        }
        if existing == nil { store.add(entry) } else { store.update(entry) }
        dismiss()
    }
}

struct GoalFormView: View {
    @EnvironmentObject private var store: LifeStore
    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var metric: GoalMetric = .runningKM
    @State private var target = ""

    var body: some View {
        NavigationStack {
            Form {
                TextField("目标名称，例如 累计跑满 500 公里", text: $title)
                Picker("衡量方式", selection: $metric) {
                    ForEach(GoalMetric.allCases) { Text($0.title).tag($0) }
                }
                TextField("目标数量", text: $target).keyboardType(.decimalPad)
                Text("个人目标用于展示进度，不参与未来公共排行榜计分。")
                    .font(.caption).foregroundStyle(.secondary)
            }
            .navigationTitle("设定个人目标")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("取消") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        guard let value = Double(target.replacingOccurrences(of: ",", with: ".")) else { return }
                        store.addGoal(PersonalGoal(title: title, metric: metric, target: value))
                        dismiss()
                    }
                    .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty || (Double(target.replacingOccurrences(of: ",", with: ".")) ?? 0) <= 0)
                }
            }
        }
        .tint(Palette.accent)
    }
}

struct ProfileView: View {
    @EnvironmentObject private var store: LifeStore
    @AppStorage("appLanguage") private var appLanguage = AppLanguage.system.rawValue
    @AppStorage("showTimeEcho") private var showTimeEcho = true
    @State private var addGoal = false
    @State private var exporting = false
    @State private var importing = false
    @State private var backupDocument: BackupDocument?
    @State private var exportingCSV = false
    @State private var csvDocument: ExperienceCSVDocument?

    private var profileSummary: String {
        let profile = store.data.profile
        var parts: [String] = []
        if let birthDate = profile.birthDate {
            let age = Calendar.current.dateComponents([.year], from: birthDate, to: Date()).year ?? 0
            parts.append(AppLanguage.isEnglish ? "Age \(age)" : "\(age) 岁")
        }
        if !profile.education.isEmpty { parts.append(profile.education) }
        if profile.hasDriversLicense { parts.append(AppLanguage.localized("已取得驾照")) }
        return parts.isEmpty ? AppLanguage.localized("点击填写出生日期、学历和驾照") : parts.joined(separator: " · ")
    }

    var body: some View {
        NavigationStack {
            List {
                Section("人生档案") {
                    NavigationLink {
                        ProfileEditView()
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "person.crop.circle.fill")
                                .font(.title2)
                                .foregroundStyle(Palette.accent)
                                .frame(width: 42, height: 42)
                                .background(Palette.accent.opacity(0.10), in: RoundedRectangle(cornerRadius: 12))
                            VStack(alignment: .leading, spacing: 4) {
                                Text(store.data.profile.nickname)
                                    .font(.headline)
                                Text(profileSummary)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Text("Lv.\(store.totalLevel)")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(Palette.accent)
                        }
                    }
                    .accessibilityIdentifier("life-profile")
                }
                Section {
                    ForEach(store.data.goals) { goal in
                        let progress = GameEngine.goalProgress(goal, entries: store.data.entries)
                        VStack(alignment: .leading, spacing: 6) {
                            Text(goal.title).font(.subheadline.bold())
                            ProgressView(value: min(progress / max(goal.target, 1), 1)).tint(Palette.accent)
                            Text("\(progress.formatted(.number.precision(.fractionLength(0...1)))) / \(goal.target.formatted()) \(goal.metric.unit)")
                                .font(.caption).foregroundStyle(.secondary)
                        }
                    }
                    .onDelete { offsets in
                        let goals = store.data.goals
                        for index in offsets { store.deleteGoal(goals[index]) }
                    }
                    Button("添加个人目标") { addGoal = true }
                } header: { Text("个人目标") }
                Section("数据") {
                    Button("导出 JSON 备份") {
                        backupDocument = store.backup()
                        exporting = backupDocument != nil
                    }
                    Button("导出 CSV 经历表") {
                        csvDocument = store.exportExperiencesCSV()
                        exportingCSV = true
                    }
                    Button("导入 JSON 备份") { importing = true }
                    NavigationLink("查看导入前快照") { BackupSnapshotListView() }
                    NavigationLink("隐私与数据控制") { PrivacyView() }
                    Text("JSON 备份包含手动记录与档案，不包含 Apple 健康步数。导入前可预览并选择合并或替换；请定期导出备份。")
                        .font(.caption).foregroundStyle(.secondary)
                }
                Section("语言") {
                    Picker("应用语言", selection: $appLanguage) {
                        ForEach(AppLanguage.allCases) { language in
                            Text(language.title).tag(language.rawValue)
                        }
                    }
                }
                Section("回忆") {
                    Toggle("显示时光回声", isOn: $showTimeEcho)
                }
                Section("规则") {
                    NavigationLink("查看经验规则") { RulesView() }
                    Text("\(GameEngine.scoringVersion) · 排行榜与自动同步将在后续版本加入")
                        .font(.caption).foregroundStyle(.secondary)
                }
            }
            .scrollContentBackground(.hidden)
            .background(Palette.background)
            .navigationTitle("我的人生")
            .sheet(isPresented: $addGoal) { GoalFormView() }
            .fileExporter(isPresented: $exporting, document: backupDocument, contentType: .json, defaultFilename: "有迹备份") { result in
                if case .failure(let error) = result { store.errorMessage = "导出失败：\(error.localizedDescription)" }
            }
            .fileExporter(isPresented: $exportingCSV, document: csvDocument, contentType: .commaSeparatedText, defaultFilename: "有迹经历") { result in
                if case .failure(let error) = result { store.errorMessage = "导出失败：\(error.localizedDescription)" }
            }
            .fileImporter(isPresented: $importing, allowedContentTypes: [.json]) { result in
                switch result {
                case .success(let url): store.prepareImport(from: url)
                case .failure(let error): store.errorMessage = "导入失败：\(error.localizedDescription)"
                }
            }
            .sheet(item: $store.pendingImport) { preview in
                BackupImportPreviewView(preview: preview)
            }
        }
    }
}

private struct BackupSnapshotListView: View {
    @EnvironmentObject private var store: LifeStore

    var body: some View {
        List {
            if store.preImportSnapshots.isEmpty {
                ContentUnavailableView("还没有本机快照", systemImage: "externaldrive", description: Text("首次导入备份前会自动保存当前数据。"))
            } else {
                Section {
                    ForEach(store.preImportSnapshots, id: \.self) { url in
                        Button {
                            store.prepareImport(from: url)
                        } label: {
                            Label(url.deletingPathExtension().lastPathComponent.replacingOccurrences(of: "life-data-before-import-", with: ""),
                                  systemImage: "clock.arrow.circlepath")
                        }
                    }
                } footer: {
                    Text("点开快照可预览、合并或恢复。最近五份会保留在本机。")
                }
            }
        }
        .navigationTitle("导入前快照")
    }
}

private struct BackupImportPreviewView: View {
    @EnvironmentObject private var store: LifeStore
    @State private var confirmReplace = false
    let preview: BackupImportPreview

    var body: some View {
        NavigationStack {
            List {
                Section("备份文件") {
                    Text(preview.filename).lineLimit(2)
                    LabeledContent("经历", value: "\(preview.incoming.entries.count)")
                    LabeledContent("个人目标", value: "\(preview.incoming.goals.count)")
                    LabeledContent("人生章节", value: "\(preview.incoming.chapterTitles?.count ?? 0)")
                }
                Section("合并预览") {
                    LabeledContent("新增经历", value: "\(preview.summary.addedEntries)")
                    LabeledContent("跳过重复经历", value: "\(preview.summary.skippedEntries)")
                    LabeledContent("新增个人目标", value: "\(preview.summary.addedGoals)")
                    LabeledContent("合并后经历总数", value: "\(preview.merged.entries.count)")
                    if preview.summary.conflictingEntries > 0 {
                        Text(AppLanguage.format("%d 条记录与本机记录标识相同但内容不同；合并时保留本机版本。", preview.summary.conflictingEntries))
                            .font(.footnote).foregroundStyle(.orange)
                    }
                }
                Section {
                    Text("合并会优先保留本机档案和章节标题。替换会使用备份中的手动记录；本机 Apple 健康步数在两种方式下都会保留。")
                        .font(.footnote).foregroundStyle(Palette.secondary)
                }
            }
            .navigationTitle("导入预览")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { store.pendingImport = nil }
                }
            }
            .safeAreaInset(edge: .bottom) {
                VStack(spacing: 10) {
                    Button("合并新增内容") { store.applyPendingImport(.merge) }
                        .buttonStyle(.borderedProminent)
                        .frame(maxWidth: .infinity)
                    Button("用备份替换当前数据", role: .destructive) { confirmReplace = true }
                        .font(.subheadline)
                }
                .frame(maxWidth: .infinity)
                .padding(16)
                .background(.regularMaterial)
            }
            .confirmationDialog("替换所有本机数据？", isPresented: $confirmReplace, titleVisibility: .visible) {
                Button("确认替换", role: .destructive) { store.applyPendingImport(.replace) }
                Button("取消", role: .cancel) { }
            } message: {
                Text("当前记录会先保存为本机快照，然后由备份内容替换。")
            }
        }
        .tint(Palette.accent)
    }
}

struct ProfileEditView: View {
    @EnvironmentObject private var store: LifeStore
    @Environment(\.dismiss) private var dismiss
    @State private var nickname = ""
    @State private var hasBirthDate = false
    @State private var birthDate = Date()
    @State private var education = ""
    @State private var graduationDate = Date()
    @State private var hasDriversLicense = false
    @State private var licenseDate = Date()

    var body: some View {
        Form {
            Section("身份") {
                TextField("昵称", text: $nickname)
                Toggle("记录出生日期", isOn: $hasBirthDate)
                if hasBirthDate {
                    DatePicker("出生日期", selection: $birthDate, in: ...Date(), displayedComponents: .date)
                }
            }
            Section("人生里程碑") {
                TextField("已取得的学历，例如 本科", text: $education)
                if !education.isEmpty {
                    DatePicker("取得日期", selection: $graduationDate, in: ...Date(), displayedComponents: .date)
                }
                Toggle("已取得驾照", isOn: $hasDriversLicense)
                if hasDriversLicense {
                    DatePicker("取得日期", selection: $licenseDate, in: ...Date(), displayedComponents: .date)
                }
            }
            Text("年龄和学历不增加经验。原型中的驾照成就须填写出生日期，且取得驾照时年满 18 岁；这只是成就规则，不判断实际驾驶资格。")
                .font(.caption).foregroundStyle(.secondary)
        }
        .navigationTitle("人生档案")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("保存") {
                    let trimmedNickname = nickname.trimmingCharacters(in: .whitespacesAndNewlines)
                    let trimmedEducation = education.trimmingCharacters(in: .whitespacesAndNewlines)
                    store.updateProfile(LifeProfile(
                        nickname: trimmedNickname.isEmpty ? "探索者" : trimmedNickname,
                        birthDate: hasBirthDate ? birthDate : nil,
                        education: trimmedEducation,
                        graduationDate: trimmedEducation.isEmpty ? nil : graduationDate,
                        hasDriversLicense: hasDriversLicense,
                        licenseDate: hasDriversLicense ? licenseDate : nil
                    ))
                    dismiss()
                }
            }
        }
        .onAppear {
            let profile = store.data.profile
            nickname = profile.nickname
            hasBirthDate = profile.birthDate != nil
            birthDate = profile.birthDate ?? Date()
            education = profile.education
            graduationDate = profile.graduationDate ?? Date()
            hasDriversLicense = profile.hasDriversLicense
            licenseDate = profile.licenseDate ?? Date()
        }
        .tint(Palette.accent)
    }
}

struct RulesView: View {
    var body: some View {
        List {
            Section("总等级") {
                Text("八个大类等权。单个大类等级越高，对总等级的新增贡献越小；新增大类不会降低现有总等级。")
            }
            Section("运动") {
                Text("每公里 10 XP。首次单次跑满半马额外 200 XP；首次单次跑满全马额外 500 XP。已有至少 5 公里最长纪录后，单次刷新最长纪录至少 1 公里，额外 60 XP。")
                Text("骑行每公里 3 XP，单独累计骑行里程，计入运动等级。")
                Text("每学会一种新运动 200 XP。重复记录同一运动不再加分。跑步、骑行和运动技能的经验合并为运动等级。")
            }
            Section("学习") {
                Text("学习包含阅读、语言、学历和证书。每读完一本不同的书获得 100 XP；每种语言阶段首次记录获得 100 XP；每种不同学历首次记录获得 200 XP；每张不同证书首次记录获得 100 XP。重复记录可留档，但不重复获得经验。")
            }
            Section("旅行") {
                Text("首次到访城市 120 XP，首次到访国家或地区 300 XP。高铁或飞行每次 20 XP，并按里程计算少量经验。同一次行程最多获得 400 XP。")
            }
            Section("爱心") {
                Text("每记录一次真实的帮助行动或志愿服务，获得 50 XP。填写行动内容，可用补充内容记录细节。爱心记录为个人自述，暂不计入公共排行榜。")
            }
            Section("人生里程碑") { Text("年龄、学历、驾照记录不直接增加经验。个人目标完成可展示成就，不参与未来公共排行。") }
        }
        .navigationTitle("\(GameEngine.scoringVersion)")
    }
}
