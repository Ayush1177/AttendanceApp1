// AttendanceView.swift
import SwiftUI

struct AttendanceView: View {
    let userID: String

    var body: some View {
        VStack(spacing: 20) {
            Text("Welcome, your user ID is \(userID)")
                .font(.title2)

            NavigationLink("Verify Face") {
                FaceVerifyView(userID: userID)
            }
            .padding()
            .background(Color.green.opacity(0.7))
            .cornerRadius(8)
        }
        .padding()
        .navigationTitle("Attendance")
    }
}
