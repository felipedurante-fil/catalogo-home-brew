import SwiftUI

struct CommandLogView: View {
    var runner: BrewCommandRunner
    let title: String
    var onFinished: () -> Void = {}

    @Environment(\.dismiss) private var dismiss
    @State private var didNotifyFinish = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("brew \(title)").font(.headline)
                Spacer()
                if runner.isRunning {
                    ProgressView().controlSize(.small)
                } else if let code = runner.exitCode {
                    Label(code == 0 ? "Concluído" : "Falhou", systemImage: code == 0 ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundStyle(code == 0 ? .green : .red)
                }
            }

            ScrollViewReader { proxy in
                ScrollView {
                    Text(runner.log.isEmpty ? "Aguardando saída…" : runner.log)
                        .font(.system(.caption, design: .monospaced))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .textSelection(.enabled)
                        .id("log-end")
                }
                .frame(minWidth: 500, minHeight: 320)
                .background(Color.black.opacity(0.05), in: RoundedRectangle(cornerRadius: 8))
                .onChange(of: runner.log) {
                    proxy.scrollTo("log-end", anchor: .bottom)
                }
            }

            HStack {
                if runner.isRunning {
                    Button("Cancelar", role: .destructive) { runner.cancel() }
                }
                Spacer()
                Button("Fechar") { dismiss() }
                    .keyboardShortcut(.defaultAction)
                    .disabled(runner.isRunning)
            }
        }
        .padding()
        .onChange(of: runner.isRunning) {
            if !runner.isRunning, !didNotifyFinish {
                didNotifyFinish = true
                onFinished()
            }
        }
    }
}
