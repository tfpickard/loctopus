import SwiftUI

struct SensorCardView: View {
    let sensorType: SensorType
    let isEnabled: Bool
    let isRecording: Bool
    let currentValue: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: sensorType.icon)
                        .font(.title2)
                        .foregroundColor(accentColor)

                    Spacer()

                    if isRecording && isEnabled {
                        Circle()
                            .fill(Color.red)
                            .frame(width: 8, height: 8)
                            .overlay(
                                Circle()
                                    .stroke(Color.red.opacity(0.3), lineWidth: 4)
                            )
                    }
                }

                Text(sensorType.rawValue)
                    .font(.headline)
                    .foregroundColor(.primary)

                Text(sensorType.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)

                if isRecording && isEnabled {
                    Text(currentValue)
                        .font(.system(.body, design: .monospaced))
                        .foregroundColor(accentColor)
                        .lineLimit(1)
                }

                Spacer()

                HStack {
                    if isEnabled {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(accentColor)
                    } else {
                        Image(systemName: "circle")
                            .foregroundColor(.secondary)
                    }

                    Text(isEnabled ? "Enabled" : "Disabled")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .frame(maxWidth: .infinity, minHeight: 180)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isEnabled ? accentColor.opacity(0.1) : Color(.systemGray6))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isEnabled ? accentColor : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }

    private var accentColor: Color {
        switch sensorType {
        case .gps: return .cyan
        case .accelerometer: return .green
        case .gyroscope: return .orange
        case .magnetometer: return .purple
        case .barometer: return .blue
        }
    }
}
