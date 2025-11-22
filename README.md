# Loctopus

A privacy-first sensor recording lab for iOS and iPadOS.

## Overview

Loctopus is a SwiftUI-based app that records device sensor data into sessions, visualizes it with rich UI, and optionally syncs via iCloud/CloudKit. No ads, no in-app purchases, no analytics, no third-party SDKs.

## Features

### Sensor Recording
- **GPS**: Location, speed, altitude, heading
- **Accelerometer**: 3-axis acceleration data
- **Gyroscope**: 3-axis rotation rate
- **Magnetometer**: Magnetic field and compass heading
- **Barometer**: Atmospheric pressure and relative altitude

### Sessions
- Create recording sessions with selected sensors
- Real-time visualization during recording
- Editable session names, notes, and tags
- Comprehensive session statistics
- Search and filter sessions

### Data Export
- **GPX**: GPS track data for mapping applications
- **CSV**: Sensor data in tabular format
- **JSON**: Complete session data with all sensors
- **ZIP**: All formats bundled together

### Privacy & Sync
- **Local-only mode** (default): All data stays on device
- **iCloud sync** (optional): Private CloudKit database sync
- No third-party servers, analytics, or tracking
- Complete user control over data

### UI/UX
- Dark-themed interface with sensor-specific accent colors
- Adaptive layout for iPhone and iPad
- Real-time sensor visualizations
- Smooth animations and haptic feedback

## Technical Architecture

### Project Structure
```
Loctopus/
├── Models/
│   ├── Session.swift          # Session data model with CloudKit support
│   ├── SensorData.swift        # Sensor sample definitions
│   └── SensorType.swift        # Sensor type enumeration
├── ViewModels/
│   ├── InstrumentViewModel.swift
│   ├── SessionListViewModel.swift
│   ├── SessionDetailViewModel.swift
│   └── SettingsViewModel.swift
├── Views/
│   ├── InstrumentDashboardView.swift
│   ├── RecordingView.swift
│   ├── SessionListView.swift
│   ├── SessionDetailView.swift
│   ├── SettingsView.swift
│   └── Components/
│       ├── SensorCardView.swift
│       ├── LiveGraphView.swift
│       └── CompassView.swift
├── Services/
│   ├── LocationManager.swift   # CoreLocation wrapper
│   ├── MotionManager.swift     # CoreMotion wrapper
│   ├── SensorManager.swift     # Unified sensor orchestration
│   ├── StorageManager.swift    # File-based local storage
│   └── CloudKitManager.swift   # CloudKit sync
└── Utilities/
    ├── ExportManager.swift     # Data export functionality
    └── PermissionManager.swift # Permission handling
```

### Data Storage

**Local Storage**:
- File-based approach for efficiency
- Each session gets a dedicated folder in `Documents/Sessions/{sessionID}/`
- Sensor data stored in JSONL format (one JSON object per line)
- Session metadata stored in `sessions_metadata.json`

**iCloud Storage** (Optional):
- CloudKit Private Database for session metadata
- CKAsset for sensor data files
- Automatic conflict resolution (last-writer-wins)

### Sensor Data Format

Each sensor type has its own sample structure:

```swift
struct GPSSample {
    timestamp, latitude, longitude, altitude,
    horizontalAccuracy, verticalAccuracy, speed, course
}

struct AccelerometerSample {
    timestamp, x, y, z
}

struct GyroscopeSample {
    timestamp, x, y, z
}

struct MagnetometerSample {
    timestamp, x, y, z, heading?
}

struct BarometerSample {
    timestamp, pressure, relativeAltitude
}
```

## Requirements

- **iOS/iPadOS**: 17.0+
- **Xcode**: 15.0+
- **Swift**: 5.9+

### Permissions Required
- Location (for GPS and heading)
- Motion & Fitness (for accelerometer, gyroscope, magnetometer, barometer)

## Setup Instructions

1. **Open in Xcode**:
   ```bash
   open Loctopus/Loctopus.xcodeproj
   ```

2. **Configure Signing**:
   - Select the Loctopus target
   - Go to "Signing & Capabilities"
   - Set your development team
   - Bundle identifier is pre-configured as `com.loctopus.app`

3. **CloudKit Setup** (Optional):
   - The app includes CloudKit entitlements
   - Xcode will automatically create the CloudKit container on first build
   - No additional CloudKit configuration required

4. **Build and Run**:
   - Select your target device or simulator
   - Press Cmd+R to build and run

## Usage

### Recording a Session

1. **Enable Sensors**: On the Instruments tab, tap sensor cards to enable/disable them
2. **Grant Permissions**: Tap permission banners if prompted
3. **Start Recording**: Tap "Start Recording" button
4. **Monitor Sensors**: Swipe between sensor pages to view live data
5. **Stop Recording**: Tap "Stop" when finished

### Managing Sessions

1. **View Sessions**: Navigate to Sessions tab
2. **Session Details**: Tap a session to view detailed statistics and visualizations
3. **Edit Session**: Tap session name or notes to edit
4. **Export Data**: Use export buttons to share data in various formats
5. **Delete**: Swipe left on a session to delete

### Settings

- **Storage Mode**: Toggle between Local Only and Local + iCloud
- **Units**: Choose Metric or Imperial
- **Map Style**: Select map appearance
- **Privacy Info**: View privacy guarantees

## Privacy Commitment

Loctopus is designed with privacy as a core principle:

- ✅ **No Ads**: Completely ad-free
- ✅ **No Analytics**: Zero usage tracking or telemetry
- ✅ **No Third Parties**: No external SDKs or services
- ✅ **Local First**: Data stays on your device by default
- ✅ **Your iCloud**: Optional sync uses your private iCloud
- ✅ **No Backend**: App doesn't communicate with any developer-controlled servers

## Export Formats

### GPX (GPS only)
```xml
<?xml version="1.0"?>
<gpx version="1.1">
  <trk>
    <trkseg>
      <trkpt lat="37.7749" lon="-122.4194">
        <ele>10.5</ele>
        <time>2025-01-01T00:00:00Z</time>
      </trkpt>
    </trkseg>
  </trk>
</gpx>
```

### CSV
```csv
Timestamp,Latitude,Longitude,Altitude,Speed,Course,H_Accuracy,V_Accuracy
2025-01-01T00:00:00Z,37.7749,-122.4194,10.5,2.3,90.0,5.0,10.0
```

### JSON
```json
{
  "id": "uuid",
  "name": "Session Name",
  "createdAt": "2025-01-01T00:00:00Z",
  "sensorData": {
    "gps": [...],
    "accelerometer": [...],
    ...
  }
}
```

## Known Limitations

1. **ZIP Export**: Currently simplified (future enhancement planned)
2. **Map Rendering**: Uses placeholder UI (can integrate MapKit with actual route rendering)
3. **Graph Details**: Live graphs use basic line charts (can be enhanced with more sophisticated charting)

## Future Enhancements

- [ ] Real MapKit integration with route rendering
- [ ] Advanced data analysis and statistics
- [ ] Session comparison features
- [ ] Custom export templates
- [ ] Background recording improvements
- [ ] Apple Watch companion app

## License

This is a reference implementation. Customize as needed for your use case.

## Support

For issues or questions, please refer to the code documentation or create an issue in your repository.
