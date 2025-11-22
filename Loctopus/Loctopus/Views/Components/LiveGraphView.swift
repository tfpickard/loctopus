import SwiftUI

struct LiveGraphView: View {
    let data: [Double]
    let color: Color
    let maxDataPoints: Int = 50

    var body: some View {
        GeometryReader { geometry in
            Path { path in
                guard !data.isEmpty else { return }

                let displayData = Array(data.suffix(maxDataPoints))
                let stepX = geometry.size.width / CGFloat(max(displayData.count - 1, 1))
                let maxValue = displayData.max() ?? 1
                let minValue = displayData.min() ?? 0
                let range = max(maxValue - minValue, 0.001)

                for (index, value) in displayData.enumerated() {
                    let x = CGFloat(index) * stepX
                    let normalizedValue = (value - minValue) / range
                    let y = geometry.size.height * (1 - CGFloat(normalizedValue))

                    if index == 0 {
                        path.move(to: CGPoint(x: x, y: y))
                    } else {
                        path.addLine(to: CGPoint(x: x, y: y))
                    }
                }
            }
            .stroke(color, lineWidth: 2)
        }
    }
}

struct ThreeAxisGraphView: View {
    let xData: [Double]
    let yData: [Double]
    let zData: [Double]

    var body: some View {
        ZStack {
            LiveGraphView(data: xData, color: .red)
            LiveGraphView(data: yData, color: .green)
            LiveGraphView(data: zData, color: .blue)
        }
        .frame(height: 120)
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}
