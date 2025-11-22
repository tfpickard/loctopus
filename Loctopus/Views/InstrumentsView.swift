import SwiftUI

struct InstrumentsView: View {
    @EnvironmentObject var appModel: AppViewModel
    @EnvironmentObject var recordingModel: RecordingViewModel
    @ObservedObject var locationService: LocationService
    @ObservedObject var motionService: MotionService
    @ObservedObject var barometerService: BarometerService
    @State private var selectedSensors: Set<SensorType> = Set(SensorType.allCases)
    @State private var showingRecording = false

    init(appModel: AppViewModel) {
        self._locationService = ObservedObject(initialValue: appModel.locationService)
        self._motionService = ObservedObject(initialValue: appModel.motionService)
        self._barometerService = ObservedObject(initialValue: appModel.barometerService)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                HStack {
                    VStack(alignment: .leading) {
                        Text("Loctopus")
                            .font(.largeTitle.bold())
                        Text(appModel.cloudEnabled ? "Local + iCloud" : "Local Only")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Button(action: { showingRecording = true }) {
                        Label("Start Recording", systemImage: "record.circle")
                            .padding()
                            .background(.blue.gradient)
                            .foregroundColor(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                }
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 160), spacing: 16)], spacing: 16) {
                    ForEach(SensorType.allCases) { sensor in
                        SensorCardView(sensor: sensor,
                                       location: locationService.lastLocation,
                                       heading: locationService.lastHeading,
                                       accelerometer: motionService.lastAccelerometer,
                                       gyro: motionService.lastGyro,
                                       magnetometer: motionService.lastMagnetometer,
                                       barometer: barometerService.lastSample)
                        .overlay(alignment: .topTrailing) {
                            Button(action: {
                                if selectedSensors.contains(sensor) {
                                    selectedSensors.remove(sensor)
                                } else {
                                    selectedSensors.insert(sensor)
                                }
                            }) {
                                Image(systemName: selectedSensors.contains(sensor) ? "checkmark.circle.fill" : "circle")
                                    .foregroundStyle(sensor.accentColor)
                                    .padding(8)
                            }
                        }
                    }
                }
            }
            .padding()
        }
        .sheet(isPresented: $showingRecording) {
            RecordingView(selectedSensors: Array(selectedSensors))
                .environmentObject(appModel)
                .environmentObject(recordingModel)
        }
        .onAppear {
            locationService.start()
            motionService.start(accelerometer: true, gyro: true, magnetometer: true, interval: 1.0)
            barometerService.start()
        }
    }
}
