import SwiftUI

struct AddFeedView: View {
    @EnvironmentObject private var feedVM: FeedViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var urlString: String = ""
    @State private var errorMessage: String?
    @State private var isProcessing = false

    var body: some View {
        Form {
            Section("URL") {
                TextField("https://example.com", text: $urlString)
                    #if os(iOS)
                    .textInputAutocapitalization(.never)
                    .keyboardType(.URL)
                    #endif
            }
            if let errorMessage {
                Text(errorMessage).foregroundColor(.red)
            }
            Button(action: addFeed) {
                if isProcessing {
                    ProgressView()
                } else {
                    Text("購読を追加")
                }
            }
            .disabled(isProcessing || URL(string: urlString) == nil)
        }
        .navigationTitle("購読を追加")
        .toolbar { ToolbarItem(placement: .cancellationAction) { Button("閉じる", action: dismiss.callAsFunction) } }
    }

    private func addFeed() {
        guard let url = URL(string: urlString) else {
            errorMessage = "URL が不正です"
            return
        }
        isProcessing = true
        Task {
            do {
                try await feedVM.addFeed(url: url)
                dismiss()
            } catch {
                errorMessage = error.localizedDescription
            }
            isProcessing = false
        }
    }
}
