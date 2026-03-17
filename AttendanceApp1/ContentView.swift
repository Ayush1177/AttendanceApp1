// ContentView.swift
import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationStack {
            LoginView()
        }
    }
}


#Preview {
    ContentView()
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
