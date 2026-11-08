import Foundation

extension FormatStyle where Self == FloatingPointFormatStyle<Double>.Percent {
    static var usagePercent: Self {
        .percent.precision(.fractionLength(0)).rounded(rule: .toNearestOrAwayFromZero)
    }
}
