import SwiftUI
import MapKit

struct DashboardView: View {
    @AppStorage("user_id") var userID: String = ""
    @StateObject private var locationManager = LocationManager()
    @State private var classSchedule: [ClassModel] = []
    @State private var todayAttendance: [String] = []
    @State private var isCameraPresented = false
    @State private var selectedClass: String = ""
    @State private var showingResult = false
    @State private var resultMessage = ""
    @State private var locationTimer: Timer?

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(colors: [.blue.opacity(0.4), .purple.opacity(0.7)],
                               startPoint: .top,
                               endPoint: .bottom)
                .ignoresSafeArea()

                VStack(spacing: 10) {
                    Text("Dashboard")
                        .font(.largeTitle).bold()
                        .foregroundColor(.white)

                    MapView(location: locationManager.currentLocation)
                        .frame(height: 100)
                        .cornerRadius(12)
                        .padding(.horizontal)

                    Text("Today's Classes")
                        .font(.title2).bold().foregroundColor(.white)

                    if classSchedule.isEmpty {
                        ProgressView("Loading...")
                            .foregroundColor(.white)
                    } else {
                        ScrollView {
                            ForEach(classSchedule) { classItem in
                                classCard(for: classItem)
                            }
                        }
                    }

                    NavigationLink("📜 View History") {
                        AttendanceHistoryView()
                    }
                    .foregroundColor(.white)
                    .padding(.top)
                }
                .padding()
            }
            .onAppear {
                loadSchedule()
                loadTodayAttendance()
            }
            .sheet(isPresented: $isCameraPresented) {
                FaceCaptureView(userID: userID, isForVerification: true) { image in
                    uploadAttendanceFace(image: image)
                }
            }
            .alert("Result", isPresented: $showingResult) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(resultMessage)
            }
        }
    }

    private func classCard(for classItem: ClassModel) -> some View {
        let isMarked = todayAttendance.contains(classItem.subject)

        return VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(classItem.subject)
                    .font(.headline)
                    .foregroundColor(.white)
                if isMarked {
                    Text("✅")
                }
            }

            Text("\(classItem.start_time) - \(classItem.end_time)")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.8))

            if isMarked {
                Text("Marked Present")
                    .foregroundColor(.green)
                    .font(.caption)
            }

            Button("Mark Attendance") {
                if locationManager.isInsideClassroom() {
                    selectedClass = classItem.subject
                    isCameraPresented = true
                } else {
                    resultMessage = "⚠️ You are not inside the classroom area."
                    showingResult = true
                }
            }
            .disabled(isMarked)
            .padding(.vertical, 6)
            .frame(maxWidth: .infinity)
            .background(isMarked ? Color.gray : Color.green)
            .foregroundColor(.white)
            .cornerRadius(8)
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(12)
        .padding(.horizontal)
        .padding(.bottom, 6)
    }

    func loadSchedule() {
        guard let url = URL(string: "http://172.20.10.4:8000/class-schedule") else { return }
        URLSession.shared.dataTask(with: url) { data, _, _ in
            if let data = data,
               let decoded = try? JSONDecoder().decode([ClassModel].self, from: data) {
                DispatchQueue.main.async {
                    self.classSchedule = decoded
                }
            }
        }.resume()
    }

    func loadTodayAttendance() {
        guard let url = URL(string: "http://172.20.10.4:8000/get-today-attendance/\(userID)") else { return }
        URLSession.shared.dataTask(with: url) { data, _, _ in
            if let data = data,
               let result = try? JSONDecoder().decode([AttendanceRecord].self, from: data) {
                DispatchQueue.main.async {
                    self.todayAttendance = result.map { $0.class_code }
                }
            }
        }.resume()
    }

    func uploadAttendanceFace(image: UIImage) {
        isCameraPresented = false
        AuthService.shared.checkLiveness(image: image) { livenessResult in
            DispatchQueue.main.async {
                switch livenessResult {
                case .success(let isLive):
                    if isLive {
                        performAttendanceUpload(image: image)
                    } else {
                        resultMessage = "❌ Liveness check failed. Try again with a real face."
                        showingResult = true
                    }
                case .failure(let error):
                    resultMessage = "⚠️ Liveness check error: \(error.localizedDescription)"
                    showingResult = true
                }
            }
        }
    }

    private func performAttendanceUpload(image: UIImage) {
        guard let url = URL(string: "http://172.20.10.4:8000/mark-attendance/\(userID)/\(selectedClass)") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"

        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        guard let loc = locationManager.currentLocation else {
            resultMessage = "❌ Couldn't get location."
            showingResult = true
            return
        }

        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            resultMessage = "❌ Couldn't process image."
            showingResult = true
            return
        }

        var body = Data()
        body.append("--\(boundary)\r\n")
        body.append("Content-Disposition: form-data; name=\"lat\"\r\n\r\n")
        body.append("\(loc.coordinate.latitude)\r\n")
        body.append("--\(boundary)\r\n")
        body.append("Content-Disposition: form-data; name=\"lon\"\r\n\r\n")
        body.append("\(loc.coordinate.longitude)\r\n")
        body.append("--\(boundary)\r\n")
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"face.jpg\"\r\n")
        body.append("Content-Type: image/jpeg\r\n\r\n")
        body.append(imageData)
        body.append("\r\n--\(boundary)--\r\n")

        request.httpBody = body

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let data = data,
               let result = try? JSONDecoder().decode(AttendanceResult.self, from: data) {
                DispatchQueue.main.async {
                    resultMessage = result.message
                    showingResult = true
                    loadTodayAttendance()
                }
            } else {
                DispatchQueue.main.async {
                    resultMessage = "Failed to mark attendance."
                    showingResult = true
                }
            }
        }.resume()
    }
}
