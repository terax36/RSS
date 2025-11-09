import SwiftUI

struct RulesEditorView: View {
    @Environment(\.managedObjectContext) private var context
    @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \Rule.pattern, ascending: true)])
    private var rules: FetchedResults<Rule>
    @State private var pattern: String = ""
    @State private var isRegex = false

    var body: some View {
        Form {
            Section("新規ルール") {
                TextField("キーワード", text: $pattern)
                Toggle("正規表現", isOn: $isRegex)
                Button("追加", action: addRule)
                    .disabled(pattern.isEmpty)
            }
            Section("ルール一覧") {
                ForEach(rules) { rule in
                    VStack(alignment: .leading) {
                        Text(rule.pattern)
                        Text(rule.isRegex ? "正規表現" : "キーワード")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .onDelete(perform: delete)
            }
        }
        .navigationTitle("ミュートルール")
    }

    private func addRule() {
        let rule = Rule(context: context)
        rule.id = UUID()
        rule.pattern = pattern
        rule.isRegex = isRegex
        rule.actionHide = true
        try? context.save()
        pattern = ""
    }

    private func delete(at offsets: IndexSet) {
        offsets.map { rules[$0] }.forEach(context.delete)
        try? context.save()
    }
}
