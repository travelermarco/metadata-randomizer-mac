import Foundation
import ImageIO

struct DeviceProfile {
    let make: String
    let model: String
    let software: String
}

struct CityCoord {
    let name: String
    let lat: Double
    let lon: Double
}

enum FakeMetadata {

    private static let devices: [DeviceProfile] = [
        .init(make: "samsung",  model: "SM-A546B",        software: "A546BXXS5CXD1"),
        .init(make: "samsung",  model: "SM-S911B",        software: "S911BXXS4CXD2"),
        .init(make: "samsung",  model: "SM-G991B",        software: "G991BXXS7GWJ1"),
        .init(make: "samsung",  model: "SM-A325F",        software: "A325FXXS6CWJ1"),
        .init(make: "samsung",  model: "SM-A135F",        software: "A135FXXS4CWJ2"),
        .init(make: "Xiaomi",   model: "Redmi Note 12",   software: "V14.0.2.0.TMGEUXM"),
        .init(make: "Xiaomi",   model: "2210129SG",       software: "OS1.0.7.0.TMAITUS"),
        .init(make: "OPPO",     model: "CPH2483",         software: "CPH2483_11_F.30"),
        .init(make: "OPPO",     model: "CPH2307",         software: "CPH2307_11_F.50"),
        .init(make: "OnePlus",  model: "CPH2491",         software: "PGP110_14.0.0.500(EX01)"),
        .init(make: "OnePlus",  model: "PHB110",          software: "PHB110_13.1.0.516(EX01)"),
        .init(make: "realme",   model: "RMX3310",         software: "RMX3310_11_A.50"),
        .init(make: "motorola", model: "moto g84 5G",     software: "T2RP34.60-Q3-6-0"),
        .init(make: "motorola", model: "XT2203-1",        software: "S3RP33.20-Q4-4-4"),
        .init(make: "Nokia",    model: "TA-1581",         software: "01.110"),
        .init(make: "Nokia",    model: "TA-1563",         software: "00.140"),
        .init(make: "Sony",     model: "XQ-CQ54",         software: "62.2.A.0.459"),
        .init(make: "Sony",     model: "XQ-DQ54",         software: "67.1.A.1.116"),
        .init(make: "Google",   model: "Pixel 7a",        software: "TD2A.221216.004"),
        .init(make: "Google",   model: "Pixel 6",         software: "TP1A.221005.002"),
        .init(make: "vivo",     model: "V2248",           software: "PD2248F_EX_A_7.24.0"),
        .init(make: "HONOR",    model: "REA-NX9",         software: "REA-NX9 7.0.0.190(C10E2R1P2)"),
        .init(make: "Nothing",  model: "A065",            software: "Pong_U2.6-241218-1736"),
        .init(make: "asus",     model: "ASUS_AI2302",     software: "WW_AI2302-34.0804.2060.26"),
        .init(make: "TECNO",    model: "CK7n",            software: "CK7n-H6711E-Q-210917"),
        .init(make: "Infinix",  model: "X6833B",          software: "X6833B-H6251E-Q-231110"),
        .init(make: "ZTE",      model: "V2350",           software: "V2350V1.0.0B04"),
        .init(make: "TCL",      model: "T610K",           software: "T610K-TEUR-2PD.P12"),
        .init(make: "realme",   model: "RMX3710",         software: "RMX3710_11_C.10"),
        .init(make: "Xiaomi",   model: "22071212AG",      software: "V13.0.11.0.TLSMIXM"),
    ]

    private static let cities: [CityCoord] = [
        .init(name: "London",      lat:  51.5074, lon:  -0.1278),
        .init(name: "Paris",       lat:  48.8566, lon:   2.3522),
        .init(name: "Berlin",      lat:  52.5200, lon:  13.4050),
        .init(name: "Rome",        lat:  41.9028, lon:  12.4964),
        .init(name: "Madrid",      lat:  40.4168, lon:  -3.7038),
        .init(name: "Amsterdam",   lat:  52.3676, lon:   4.9041),
        .init(name: "Vienna",      lat:  48.2082, lon:  16.3738),
        .init(name: "Brussels",    lat:  50.8503, lon:   4.3517),
        .init(name: "Prague",      lat:  50.0755, lon:  14.4378),
        .init(name: "Warsaw",      lat:  52.2297, lon:  21.0122),
        .init(name: "Budapest",    lat:  47.4979, lon:  19.0402),
        .init(name: "Barcelona",   lat:  41.3851, lon:   2.1734),
        .init(name: "Lisbon",      lat:  38.7169, lon:  -9.1399),
        .init(name: "Copenhagen",  lat:  55.6761, lon:  12.5683),
        .init(name: "Stockholm",   lat:  59.3293, lon:  18.0686),
        .init(name: "Helsinki",    lat:  60.1699, lon:  24.9384),
        .init(name: "Oslo",        lat:  59.9139, lon:  10.7522),
        .init(name: "Zurich",      lat:  47.3769, lon:   8.5417),
        .init(name: "Munich",      lat:  48.1351, lon:  11.5820),
        .init(name: "Hamburg",     lat:  53.5753, lon:  10.0153),
        .init(name: "New York",    lat:  40.7128, lon: -74.0060),
        .init(name: "Tokyo",       lat:  35.6762, lon: 139.6503),
        .init(name: "Sydney",      lat: -33.8688, lon: 151.2093),
        .init(name: "Dubai",       lat:  25.2048, lon:  55.2708),
        .init(name: "São Paulo",   lat: -23.5505, lon: -46.6333),
        .init(name: "Toronto",     lat:  43.6532, lon: -79.3832),
        .init(name: "Melbourne",   lat: -37.8136, lon: 144.9631),
        .init(name: "Singapore",   lat:   1.3521, lon: 103.8198),
        .init(name: "Seoul",       lat:  37.5665, lon: 126.9780),
        .init(name: "Mexico City", lat:  19.4326, lon: -99.1332),
    ]

    static func randomImageFilename() -> String {
        "IMG_\(String(format: "%08d", Int.random(in: 10_000_000...99_999_999))).jpg"
    }

    static func randomVideoFilename() -> String {
        "VID_\(String(format: "%08d", Int.random(in: 10_000_000...99_999_999))).mp4"
    }

    private static func randomDateTime() -> String {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "UTC")!
        let now = Date()
        let daysAgo = Int.random(in: 180...1100)
        let date = cal.date(byAdding: .day, value: -daysAgo, to: now)!
        var comps = cal.dateComponents([.year, .month, .day], from: date)
        comps.hour   = Int.random(in: 7...20)
        comps.minute = Int.random(in: 0...59)
        comps.second = Int.random(in: 0...59)
        let final = cal.date(from: comps)!
        let parts = cal.dateComponents([.year, .month, .day, .hour, .minute, .second], from: final)
        return String(format: "%04d:%02d:%02d %02d:%02d:%02d",
                      parts.year!, parts.month!, parts.day!,
                      parts.hour!, parts.minute!, parts.second!)
    }

    // Returns the CGImageDestination-compatible properties dict and a summary string.
    static func generateImageProperties() -> ([CFString: Any], String) {
        let device   = devices.randomElement()!
        let city     = cities.randomElement()!
        let lat      = city.lat + Double.random(in: -0.04...0.04)
        let lon      = city.lon + Double.random(in: -0.04...0.04)
        let dateTime = randomDateTime()
        let datePart = String(dateTime.prefix(10))  // "YYYY:MM:DD"

        let props: [CFString: Any] = [
            kCGImagePropertyTIFFDictionary: [
                kCGImagePropertyTIFFMake:     device.make,
                kCGImagePropertyTIFFModel:    device.model,
                kCGImagePropertyTIFFSoftware: device.software,
                kCGImagePropertyTIFFDateTime: dateTime,
            ] as [CFString: Any],
            kCGImagePropertyExifDictionary: [
                kCGImagePropertyExifDateTimeOriginal:  dateTime,
                kCGImagePropertyExifDateTimeDigitized: dateTime,
            ] as [CFString: Any],
            kCGImagePropertyGPSDictionary: [
                kCGImagePropertyGPSLatitude:      abs(lat),
                kCGImagePropertyGPSLatitudeRef:   lat >= 0 ? "N" : "S",
                kCGImagePropertyGPSLongitude:     abs(lon),
                kCGImagePropertyGPSLongitudeRef:  lon >= 0 ? "E" : "W",
                kCGImagePropertyGPSAltitude:      Double.random(in: 5...280),
                kCGImagePropertyGPSAltitudeRef:   0,
                kCGImagePropertyGPSDateStamp:     datePart,
            ] as [CFString: Any],
            kCGImagePropertyOrientation: CGImagePropertyOrientation.up.rawValue,
            kCGImageDestinationLossyCompressionQuality: 0.92,
        ]

        let summary = "\(device.make) \(device.model) · \(city.name) · \(datePart)"
        return (props, summary)
    }

    static func videoSummary() -> String {
        let device = devices.randomElement()!
        let city   = cities.randomElement()!
        return "\(device.make) \(device.model) · \(city.name)"
    }
}
