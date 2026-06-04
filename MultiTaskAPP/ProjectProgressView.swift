import SwiftUI

// MARK: - 專案進度條元件
struct ProjectProgressView: View {
    var tasks: [ProjectDetailTask]
    
    private var progress: Double {
        guard !tasks.isEmpty else { return 0.0 }

        let doneCount = tasks.filter { $0.isCompleted }.count
        return Double(doneCount) / Double(tasks.count)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("專案總進度")
                .font(.headline)
            
            ProgressView(value: progress)
                .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                .scaleEffect(x: 1, y: 2, anchor: .center)
                .animation(.default, value: progress)
            
            HStack {
                Text("\(Int(progress * 100))%")
                    .font(.subheadline)
                    .bold()
                Spacer()

                Text("已完成: \(tasks.filter { $0.isCompleted }.count) / 總任務: \(tasks.count)")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(10)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}
