import SwiftUI

struct CompassView: View {
    let heading: Double

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.secondary.opacity(0.3), lineWidth: 2)

            ForEach(0..<4) { index in
                Text(["N", "E", "S", "W"][index])
                    .font(.caption.bold())
                    .foregroundColor(.secondary)
                    .offset(y: -40)
                    .rotationEffect(.degrees(Double(index) * 90 - heading))
            }

            Image(systemName: "location.north.fill")
                .font(.title)
                .foregroundColor(.red)
                .rotationEffect(.degrees(-heading))

            Text("\(Int(heading))°")
                .font(.caption)
                .foregroundColor(.secondary)
                .offset(y: 30)
        }
        .frame(width: 100, height: 100)
    }
}
