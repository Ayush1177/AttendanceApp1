import Foundation

struct AttendanceRecord: Codable, Identifiable {
    let user_id: String?
    let class_code: String
    let status: String?
    let timestamp: String?

    var id: String {
        "\(class_code)-\(timestamp ?? UUID().uuidString)"
    }
}

struct AttendanceResponse: Codable {
    let records: [AttendanceRecord]
}

struct ClassModel: Codable, Identifiable {
    var id: String { subject }
    let subject: String
    let start_time: String
    let end_time: String
}

struct AttendanceResult: Codable {
    let match: Bool
    let similarity: Double
    let message: String
}
