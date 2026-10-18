import Foundation
import HealthKit

enum HealthStepsError: LocalizedError {
    case unavailable
    case missingResults

    var errorDescription: String? {
        switch self {
        case .unavailable: "此设备无法使用 Apple 健康步数数据。"
        case .missingResults: "Apple 健康暂时没有返回步数数据。"
        }
    }
}

enum HealthSteps {
    static let accessRequestKey = "hasRequestedHealthStepAccess"

    static var isAvailable: Bool { HKHealthStore.isHealthDataAvailable() }

    static func readDays(requestAccess: Bool) async throws -> [HealthStepDay] {
        guard isAvailable,
              let stepType = HKObjectType.quantityType(forIdentifier: .stepCount) else {
            throw HealthStepsError.unavailable
        }
        let healthStore = HKHealthStore()
        if requestAccess {
            try await healthStore.requestAuthorization(toShare: [], read: [stepType])
            UserDefaults.standard.set(true, forKey: accessRequestKey)
        }

        let calendar = Calendar.current
        let start = calendar.date(from: DateComponents(year: 2010, month: 1, day: 1))!
        let end = Date()
        let predicate = HKQuery.predicateForSamples(withStart: start, end: end, options: .strictStartDate)

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKStatisticsCollectionQuery(
                quantityType: stepType,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum,
                anchorDate: start,
                intervalComponents: DateComponents(day: 1)
            )
            query.initialResultsHandler = { _, collection, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                guard let collection else {
                    continuation.resume(throwing: HealthStepsError.missingResults)
                    return
                }
                var days: [HealthStepDay] = []
                collection.enumerateStatistics(from: start, to: end) { statistics, _ in
                    let count = Int((statistics.sumQuantity()?.doubleValue(for: .count()) ?? 0).rounded())
                    if count > 0 {
                        days.append(HealthStepDay(date: statistics.startDate, count: count))
                    }
                }
                continuation.resume(returning: days)
            }
            healthStore.execute(query)
        }
    }
}
