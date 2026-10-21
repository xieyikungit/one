import Foundation

enum BackupImportMode {
    case merge
    case replace
}

struct BackupImportSummary {
    let addedEntries: Int
    let skippedEntries: Int
    let conflictingEntries: Int
    let addedGoals: Int
}

struct BackupImportPreview: Identifiable {
    let id = UUID()
    let filename: String
    let incoming: LifeData
    let merged: LifeData
    let summary: BackupImportSummary
}

enum BackupImporter {
    static func exportableData(_ source: LifeData) -> LifeData {
        var result = source
        result.healthStepDays = nil
        result.lastHealthStepSync = nil
        return result
    }

    static func preview(current: LifeData, incoming: LifeData, filename: String) -> BackupImportPreview {
        // Imported files are untrusted. HealthKit-derived values are always read from this device.
        let incoming = exportableData(incoming)
        var merged = current
        var knownEntries = Dictionary(current.entries.map { ($0.id, fingerprint($0)) }) { local, _ in local }
        var fingerprints = Set(knownEntries.values)
        var addedEntries = 0
        var skippedEntries = 0
        var conflictingEntries = 0

        for entry in incoming.entries {
            let signature = fingerprint(entry)
            if let existing = knownEntries[entry.id] {
                skippedEntries += 1
                if existing != signature { conflictingEntries += 1 }
            } else if fingerprints.contains(signature) {
                skippedEntries += 1
            } else {
                merged.entries.append(entry)
                knownEntries[entry.id] = signature
                fingerprints.insert(signature)
                addedEntries += 1
            }
        }

        var goalIDs = Set(current.goals.map(\.id))
        var goalSignatures = Set(current.goals.map(goalSignature))
        var addedGoals = 0
        for goal in incoming.goals {
            let signature = goalSignature(goal)
            guard !goalIDs.contains(goal.id), !goalSignatures.contains(signature) else { continue }
            merged.goals.append(goal)
            goalIDs.insert(goal.id)
            goalSignatures.insert(signature)
            addedGoals += 1
        }

        if merged.profile.nickname == "探索者", incoming.profile.nickname != "探索者" {
            merged.profile.nickname = incoming.profile.nickname
        }
        if merged.profile.birthDate == nil { merged.profile.birthDate = incoming.profile.birthDate }
        if merged.profile.education.isEmpty { merged.profile.education = incoming.profile.education }
        if merged.profile.graduationDate == nil { merged.profile.graduationDate = incoming.profile.graduationDate }
        merged.profile.hasDriversLicense = current.profile.hasDriversLicense || incoming.profile.hasDriversLicense
        if merged.profile.licenseDate == nil { merged.profile.licenseDate = incoming.profile.licenseDate }

        var titles = incoming.chapterTitles ?? [:]
        titles.merge(current.chapterTitles ?? [:]) { _, local in local }
        merged.chapterTitles = titles.isEmpty ? nil : titles
        merged.joinedAt = [current.joinedAt, incoming.joinedAt].compactMap { $0 }.min()

        return BackupImportPreview(
            filename: filename,
            incoming: incoming,
            merged: merged,
            summary: BackupImportSummary(addedEntries: addedEntries, skippedEntries: skippedEntries,
                                         conflictingEntries: conflictingEntries, addedGoals: addedGoals)
        )
    }

    private static func fingerprint(_ entry: LifeEntry) -> Data {
        var copy = entry
        copy.id = UUID(uuidString: "00000000-0000-0000-0000-000000000000")!
        // Geocoding can update coordinates after a record was saved.
        copy.latitude = nil
        copy.longitude = nil
        let encoder = JSONEncoder()
        encoder.outputFormatting = .sortedKeys
        return (try? encoder.encode(copy)) ?? Data()
    }

    private static func goalSignature(_ goal: PersonalGoal) -> String {
        "\(GameEngine.normalized(goal.title))|\(goal.metric.rawValue)|\(goal.target)"
    }
}
