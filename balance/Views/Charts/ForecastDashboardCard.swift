import SwiftUI

// MARK: - Safe to Spend Dashboard Card

/// Compact card showing safe-to-spend amount and risk level.
/// Taps into full ForecastDetailView.
struct SafeToSpendCard: View {

    @StateObject private var engine = ForecastEngine.shared

    var body: some View {
        if let f = engine.forecast {
            NavigationLink(destination: ForecastDetailView()) {
                DS.Card {
                    VStack(alignment: .leading, spacing: 10) {
                        // Header
                        HStack {
                            HStack(spacing: 5) {
                                Image(systemName: f.riskLevel.icon)
                                    .font(.system(size: 11))
                                    .foregroundStyle(f.riskLevel.color)
                                Text("Safe to Spend")
                                    .font(DS.Typography.caption)
                                    .foregroundStyle(DS.Colors.subtext)
                            }

                            Spacer()

                            // Risk badge
                            Text(f.riskLevel.label)
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundStyle(f.riskLevel.color)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(f.riskLevel.color.opacity(0.12), in: Capsule())

                            Image(systemName: "chevron.right")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundStyle(DS.Colors.subtext.opacity(0.4))
                        }

                        // Main amount
                        HStack(alignment: .firstTextBaseline, spacing: 4) {
                            Text(DS.Format.money(f.safeToSpend.totalAmount))
                                .font(.system(size: 24, weight: .bold, design: .rounded))
                                .foregroundStyle(f.riskLevel.color)

                            Text("left")
                                .font(DS.Typography.caption)
                                .foregroundStyle(DS.Colors.subtext)
                        }

                        // Daily safe
                        HStack(spacing: 12) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Per day")
                                    .font(.system(size: 10))
                                    .foregroundStyle(DS.Colors.subtext)
                                Text(DS.Format.money(f.safeToSpend.perDay))
                                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                                    .foregroundStyle(DS.Colors.text)
                            }

                            Rectangle()
                                .fill(DS.Colors.grid)
                                .frame(width: 0.5, height: 24)

                            VStack(alignment: .leading, spacing: 2) {
                                Text("Days left")
                                    .font(.system(size: 10))
                                    .foregroundStyle(DS.Colors.subtext)
                                Text("\(f.daysRemainingInMonth)")
                                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                                    .foregroundStyle(DS.Colors.text)
                            }

                            Rectangle()
                                .fill(DS.Colors.grid)
                                .frame(width: 0.5, height: 24)

                            VStack(alignment: .leading, spacing: 2) {
                                Text("Bills due")
                                    .font(.system(size: 10))
                                    .foregroundStyle(DS.Colors.subtext)
                                Text(DS.Format.money(f.safeToSpend.reservedForBills))
                                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                                    .foregroundStyle(DS.Colors.warning)
                            }
                        }

                        // Spending pace indicator
                        if f.budget > 0 {
                            GeometryReader { geo in
                                ZStack(alignment: .leading) {
                                    // Background
                                    RoundedRectangle(cornerRadius: 2)
                                        .fill(DS.Colors.surface2)
                                        .frame(height: 4)

                                    // Spent
                                    RoundedRectangle(cornerRadius: 2)
                                        .fill(paceColor(f))
                                        .frame(width: geo.size.width * min(f.spentRatio, 1.0), height: 4)

                                    // Time marker
                                    Circle()
                                        .fill(DS.Colors.text.opacity(0.6))
                                        .frame(width: 6, height: 6)
                                        .offset(x: geo.size.width * f.monthProgressRatio - 3)
                                }
                            }
                            .frame(height: 6)

                            HStack {
                                Text("\(Int(f.spentRatio * 100))% spent")
                                    .font(.system(size: 10))
                                    .foregroundStyle(DS.Colors.subtext)
                                Spacer()
                                Text("\(Int(f.monthProgressRatio * 100))% of month")
                                    .font(.system(size: 10))
                                    .foregroundStyle(DS.Colors.subtext)
                            }
                        }
                    }
                }
            }
            .buttonStyle(.plain)
        }
    }

    private func paceColor(_ f: ForecastResult) -> Color {
        if f.spentRatio > f.monthProgressRatio * 1.2 { return DS.Colors.danger }
        if f.spentRatio > f.monthProgressRatio { return DS.Colors.warning }
        return DS.Colors.positive
    }
}

// MARK: - Forecast Dashboard Card

/// Shows 30-day projection and upcoming bills summary.
struct ForecastDashboardCard: View {

    @StateObject private var engine = ForecastEngine.shared

    var body: some View {
        if let f = engine.forecast {
            NavigationLink(destination: ForecastDetailView()) {
                DS.Card {
                    VStack(alignment: .leading, spacing: 10) {
                        // Header
                        HStack {
                            HStack(spacing: 5) {
                                Image(systemName: "chart.line.uptrend.xyaxis")
                                    .font(.system(size: 11))
                                    .foregroundStyle(DS.Colors.accent)
                                Text("Forecast")
                                    .font(DS.Typography.caption)
                                    .foregroundStyle(DS.Colors.subtext)
                            }

                            Spacer()

                            Image(systemName: "chevron.right")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundStyle(DS.Colors.subtext.opacity(0.4))
                        }

                        // Projections row
                        HStack(spacing: 0) {
                            projectionColumn("End of month", f.projectedMonthEnd)
                            Spacer()
                            projectionColumn("30 days", f.projected30Day)
                            Spacer()
                            projectionColumn("60 days", f.projected60Day)
                        }

                        // Mini sparkline
                        if !f.timeline.isEmpty {
                            miniChart(points: f.timeline)
                                .frame(height: 32)
                        }

                        // Upcoming bills
                        if !f.upcomingBills.isEmpty {
                            HStack(spacing: 4) {
                                Image(systemName: "clock")
                                    .font(.system(size: 10))
                                let nextBill = f.upcomingBills.first!
                                Text("\(nextBill.name): \(DS.Format.money(nextBill.amount)) due \(nextBill.dueDate, format: .dateTime.month(.abbreviated).day())")
                                    .font(.system(size: 10))
                                    .lineLimit(1)
                            }
                            .foregroundStyle(DS.Colors.warning)
                            .padding(.top, 2)
                        }
                    }
                }
            }
            .buttonStyle(.plain)
        }
    }

    private func projectionColumn(_ label: String, _ amount: Int) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.system(size: 10))
                .foregroundStyle(DS.Colors.subtext)
            Text(DS.Format.money(amount))
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(amount >= 0 ? DS.Colors.text : DS.Colors.danger)
        }
    }

    // Mini sparkline chart (no Charts framework needed)
    private func miniChart(points: [ForecastPoint]) -> some View {
        GeometryReader { geo in
            let values = points.map { $0.balance }
            let minVal = values.min() ?? 0
            let maxVal = values.max() ?? 1
            let range = max(1, maxVal - minVal)

            Path { path in
                for (i, point) in points.enumerated() {
                    let x = geo.size.width * CGFloat(i) / CGFloat(max(1, points.count - 1))
                    let y = geo.size.height * (1.0 - CGFloat(point.balance - minVal) / CGFloat(range))

                    if i == 0 {
                        path.move(to: CGPoint(x: x, y: y))
                    } else {
                        path.addLine(to: CGPoint(x: x, y: y))
                    }
                }
            }
            .stroke(
                points.last?.balance ?? 0 >= 0 ? DS.Colors.accent : DS.Colors.danger,
                style: StrokeStyle(lineWidth: 1.5, lineCap: .round, lineJoin: .round)
            )
        }
    }
}
