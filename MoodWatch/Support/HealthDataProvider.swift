import Foundation

/// Seam for real health data.
///
/// `DemoHealthDataProvider` ships with deterministic demo history so the app is usable
/// without any entitlement. A `HealthKitHealthDataProvider` (reading
/// `HKQuantityTypeIdentifier.heartRateVariabilitySDNN` and resting heart rate) can be added
/// behind the same protocol once the HealthKit capability is enabled and the app is signed
/// with a profile that supports it — see docs/BUILD.md.
protocol HealthDataProvider {
    func dailyStress(days: Int) -> [DailyStress]
    func intradayHRV(on day: DailyStress) -> [HRVPoint]
}

struct DemoHealthDataProvider: HealthDataProvider {
    func dailyStress(days: Int) -> [DailyStress] {
        SampleData.days(count: days)
    }

    func intradayHRV(on day: DailyStress) -> [HRVPoint] {
        SampleData.todayCurve(for: day)
    }
}
