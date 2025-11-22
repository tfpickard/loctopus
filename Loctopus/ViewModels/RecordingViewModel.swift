import Foundation
import CoreLocation
import CoreMotion

@MainActor
final class RecordingViewModel: ObservableObject {
    @Published var currentSession: Session?
    @Published var elapsed: TimeInterval = 0
    @Published var gpsSamples: [GPSSample] = []
    @Published var accelSamples: [MotionSample] = []
    @Published var gyroSamples: [MotionSample] = []
    @Published var magnetometerSamples: [MotionSample] = []
    @Published var baroSamples: [BarometerSample] = []
    @Published var permissionMessage: String?

    private let appModel: AppViewModel
    private var timer: Timer?
    private var startDate: Date?

    init(appModel: AppViewModel) {
        self.appModel = appModel
    }

    func startSession(name: String, sensors: [SensorType]) {
        Task {
            let session = try await appModel.sessionStore.createSession(name: name, sensors: sensors)
            startDate = Date()
            currentSession = session
            elapsed = 0
            startTimer()
            bindSensors(for: sensors, session: session)
        }
    }

    func stopSession() {
        guard var session = currentSession else { return }
        timer?.invalidate()
        session.endedAt = Date()
        session.duration = session.endedAt?.timeIntervalSince(session.createdAt) ?? 0
        session.sampleCounts = [
            .gps: gpsSamples.count,
            .accelerometer: accelSamples.count,
            .gyroscope: gyroSamples.count,
            .magnetometer: magnetometerSamples.count,
            .barometer: baroSamples.count
        ]
        Task {
            try await appModel.sessionStore.updateSession(session)
            if appModel.cloudEnabled {
                let folder = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
                    .appendingPathComponent("Sessions").appendingPathComponent(session.id.uuidString)
                try? await appModel.cloudSync.sync(session: session, folder: folder)
            }
            await appModel.refreshSessions()
        }
        stopSensors()
        currentSession = nil
    }

    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            guard let self, let startDate else { return }
            elapsed = Date().timeIntervalSince(startDate)
        }
    }

    private func stopSensors() {
        appModel.locationService.stop()
        appModel.motionService.stop()
        appModel.barometerService.stop()
    }

    private func bindSensors(for sensors: [SensorType], session: Session) {
        let locationService = appModel.locationService
        let motionService = appModel.motionService
        let baroService = appModel.barometerService

        if sensors.contains(.gps) || sensors.contains(.magnetometer) {
            locationService.requestAuthorization(always: true)
        }

        locationService.locationHandler = { [weak self] location in
            guard let self, self.currentSession?.id == session.id else { return }
            let sample = GPSSample(timestamp: Date(), latitude: location.coordinate.latitude, longitude: location.coordinate.longitude, altitude: location.altitude, speed: location.speed, course: location.course, horizontalAccuracy: location.horizontalAccuracy)
            Task { try? await self.appModel.sessionStore.append(sample, for: session, sensor: .gps) }
            DispatchQueue.main.async { self.gpsSamples.append(sample) }
        }

        locationService.headingHandler = { [weak self] heading in
            guard let self, self.currentSession?.id == session.id else { return }
            let sample = MotionSample(timestamp: Date(), x: heading.x, y: heading.y, z: heading.z)
            Task { try? await self.appModel.sessionStore.append(sample, for: session, sensor: .magnetometer) }
            DispatchQueue.main.async { self.magnetometerSamples.append(sample) }
        }

        motionService.accelerometerHandler = { [weak self] data in
            guard let self, self.currentSession?.id == session.id else { return }
            let sample = MotionSample(timestamp: Date(), x: data.acceleration.x, y: data.acceleration.y, z: data.acceleration.z)
            Task { try? await self.appModel.sessionStore.append(sample, for: session, sensor: .accelerometer) }
            DispatchQueue.main.async { self.accelSamples.append(sample) }
        }

        motionService.gyroHandler = { [weak self] data in
            guard let self, self.currentSession?.id == session.id else { return }
            let sample = MotionSample(timestamp: Date(), x: data.rotationRate.x, y: data.rotationRate.y, z: data.rotationRate.z)
            Task { try? await self.appModel.sessionStore.append(sample, for: session, sensor: .gyroscope) }
            DispatchQueue.main.async { self.gyroSamples.append(sample) }
        }

        motionService.magnetometerHandler = { [weak self] data in
            guard let self, self.currentSession?.id == session.id else { return }
            let sample = MotionSample(timestamp: Date(), x: data.magneticField.x, y: data.magneticField.y, z: data.magneticField.z)
            Task { try? await self.appModel.sessionStore.append(sample, for: session, sensor: .magnetometer) }
            DispatchQueue.main.async { self.magnetometerSamples.append(sample) }
        }

        baroService.handler = { [weak self] data in
            guard let self, self.currentSession?.id == session.id else { return }
            let sample = BarometerSample(timestamp: Date(), pressure: data.pressure.doubleValue, relativeAltitude: data.relativeAltitude.doubleValue)
            Task { try? await self.appModel.sessionStore.append(sample, for: session, sensor: .barometer) }
            DispatchQueue.main.async { self.baroSamples.append(sample) }
        }

        appModel.locationService.start()
        appModel.motionService.start(accelerometer: sensors.contains(.accelerometer), gyro: sensors.contains(.gyroscope), magnetometer: sensors.contains(.magnetometer))
        if sensors.contains(.barometer) { appModel.barometerService.start() }
    }
}
