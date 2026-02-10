
import SwiftUI

struct DonutChartSegment: Identifiable {
    let id = UUID()
    let value: Double
    let color: Color
    let title: String
}

struct DonutChart: View {
    let data: [DonutChartSegment]
    let centerText: String?
    
    var body: some View {
        ZStack {
            ForEach(data.indices, id: \.self) { index in
                DonutSlice(
                    startAngle: startAngle(for: index),
                    endAngle: endAngle(for: index)
                )
                .stroke(data[index].color, lineWidth: 20)
            }
            
            if let centerText = centerText {
                Text(centerText)
                    .foregroundStyle(.white)
                    .font(.headline)
            }
        }
        .padding()
    }
    
    private var totalValue: Double {
        data.reduce(0) { $0 + $1.value }
    }
    
    private func startAngle(for index: Int) -> Angle {
        let sumBefore = data.prefix(index).reduce(0) { $0 + $1.value }
        return .degrees(sumBefore / totalValue * 360 - 90)
    }
    
    private func endAngle(for index: Int) -> Angle {
        let sumIncluding = data.prefix(index + 1).reduce(0) { $0 + $1.value }
        return .degrees(sumIncluding / totalValue * 360 - 90)
    }
}

struct DonutSlice: Shape {
    let startAngle: Angle
    let endAngle: Angle
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2
        
        path.addArc(
            center: center,
            radius: radius,
            startAngle: startAngle,
            endAngle: endAngle,
            clockwise: false
        )
        return path
    }
}
