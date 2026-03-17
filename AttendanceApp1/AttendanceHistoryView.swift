import SwiftUI

struct AttendanceHistoryView: View {
    @AppStorage("user_id") var userID: String = ""
    @State private var attendanceRecords: [AttendanceRecord] = []
    @State private var isLoading = true
    @State private var isExporting = false
    @State private var exportURL: URL?

    var body: some View {
        NavigationStack {
            VStack {
                if isLoading {
                    ProgressView("Loading...")
                        .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                } else if attendanceRecords.isEmpty {
                    Text("📭 No attendance records for today.")
                        .foregroundColor(.gray)
                        .font(.subheadline)
                } else {
                    List(attendanceRecords) { record in
                        VStack(alignment: .leading, spacing: 6) {
                            Text(record.class_code)
                                .font(.headline)

                            HStack {
                                Text("Status: \(record.status?.capitalized ?? "Unknown")")
                                if record.status?.lowercased() == "present" {
                                    Text("✅")
                                } else {
                                    Text("❌")
                                }
                            }
                            .font(.subheadline)

                            Text("Time: \(formatDate(record.timestamp))")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        .padding(.vertical, 4)
                    }
                }

                if !attendanceRecords.isEmpty {
                    Button("Export to CSV") {
                        exportToCSV()
                    }
                    .padding()
                    .background(Color.blue.opacity(0.8))
                    .foregroundColor(.white)
                    .cornerRadius(8)
                    .padding(.top)
                }
            }
            .padding()
            .navigationTitle("Attendance History")
            .onAppear(perform: fetchHistory)
            .sheet(isPresented: $isExporting, content: {
                if let exportURL = exportURL {
                    ShareLink(item: exportURL) {
                        Label("Share CSV File", systemImage: "square.and.arrow.up")
                    }
                }
            })
        }
    }

    func fetchHistory() {
        guard let url = URL(string: "http://172.20.10.4:8000/get-today-attendance/\(userID)") else { return }

        URLSession.shared.dataTask(with: url) { data, _, _ in
            defer { DispatchQueue.main.async { isLoading = false } }

            if let data = data {
                do {
                    let decoded = try JSONDecoder().decode(AttendanceResponse.self, from: data)
                    DispatchQueue.main.async {
                        self.attendanceRecords = decoded.records
                    }
                } catch {
                    print("❌ Failed to decode attendance history:", error)
                }
            }
        }.resume()
    }

    func formatDate(_ isoDate: String?) -> String {
        guard let iso = isoDate else { return "N/A" }

        let isoFormatter = ISO8601DateFormatter()
        if let date = isoFormatter.date(from: iso) {
            let displayFormatter = DateFormatter()
            displayFormatter.dateFormat = "MMM d, h:mm a"
            return displayFormatter.string(from: date)
        }
        return iso
    }

    func exportToCSV() {
        let csvHeader = "Class Code,Status,Timestamp\n"
        let csvRows = attendanceRecords.map { record in
            "\(record.class_code),\(record.status ?? ""),\(record.timestamp ?? "")"
        }.joined(separator: "\n")

        let csvText = csvHeader + csvRows

        do {
            let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("Attendance_Export.csv")
            try csvText.write(to: tempURL, atomically: true, encoding: .utf8)
            exportURL = tempURL
            isExporting = true
        } catch {
            print("❌ Failed to export CSV:", error)
        }
    }
}
