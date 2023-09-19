import SwiftUI
import Combine

struct StatisticsView: View {
    @State private var memoryUsage: String = "--"
    @State private var cpuUsage: String = "--"
    @EnvironmentObject var encodingTimeModel: EncodingTimeModel
    
    private let timer = Timer.publish(every: 1.0, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Application statistics")
                .font(.system(size: 26))
            Text("Memory Usage: \(memoryUsage)")
            Text("Encoding Time: \(encodingTimeModel.elapsedTime) ms")
            Text("CPU Usage: \(cpuUsage)")
        }
        .frame(width: 280)
        .bold()
        .padding()
        .background(Color.gray.opacity(0.2))
        .cornerRadius(12)
        .onAppear {
            self.updateStatistics()
        }
        .onReceive(timer) { _ in
            self.updateStatistics()
        }
    }
    
    func updateStatistics() {
        self.memoryUsage = StatisticsUtility.reportMemory()
        self.cpuUsage = StatisticsUtility.cpuUsage()
    }
}

