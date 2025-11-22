import SwiftUI

struct SensorBadgeView: View {
    let sensor: SensorType
    var body: some View {
        Label(sensor.displayName, systemImage: sensor.systemImage)
            .padding(8)
            .background(sensor.accentColor.opacity(0.2))
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .foregroundStyle(sensor.accentColor)
    }
}
