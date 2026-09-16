import SwiftUI
import MarkSweepCore

struct KeepRulesView: View {
    @EnvironmentObject var session: AppSession
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Matching messages stay out of Trash. Empty Days = forever. Older mail is auto-trashed on Scan.")
                .foregroundStyle(.secondary)
            List {
                ForEach(session.settings.keepRules) { rule in
                    KeepRuleEditor(
                        rule: rule,
                        onChange: session.updateKeepRule,
                        onDelete: { session.removeKeepRule(id: rule.id) }
                    )
                }
                .onDelete(perform: session.removeKeepRules)
            }
            keepRulesButtons
        }
        .padding(16)
        .frame(minWidth: 640, minHeight: 320)
    }

    var keepRulesButtons: some View {
        HStack {
            Button("Add rule", action: session.addKeepRule)
            Spacer()
            Button("Done") { dismiss() }
                .keyboardShortcut(.defaultAction)
        }
    }
}

struct KeepRuleEditor: View {
    let rule: KeepRule
    let onChange: (KeepRule) -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            Picker("Field", selection: fieldBind) {
                ForEach(KeepField.allCases) { Text(keepFieldTitle($0)).tag($0) }
            }
            .labelsHidden()
            .frame(width: 120)
            Picker("Match", selection: matchBind) {
                ForEach(KeepMatch.allCases) { Text(keepMatchTitle($0)).tag($0) }
            }
            .labelsHidden()
            .frame(width: 110)
            TextField("Value", text: valueBind)
            TextField("Days", text: daysBind)
                .frame(width: 52)
                .help("Blank = keep forever")
            Button(role: .destructive, action: onDelete) {
                Image(systemName: "trash")
            }
            .buttonStyle(.borderless)
            .help("Delete rule")
        }
    }

    var fieldBind: Binding<KeepField> {
        Binding(get: { rule.field }, set: { onChange(ruleBySettingField(rule, $0)) })
    }

    var matchBind: Binding<KeepMatch> {
        Binding(get: { rule.match }, set: { onChange(ruleBySettingMatch(rule, $0)) })
    }

    var valueBind: Binding<String> {
        Binding(get: { rule.value }, set: { onChange(ruleBySettingValue(rule, $0)) })
    }

    var daysBind: Binding<String> {
        Binding(
            get: { keepDaysText(rule.keepDays) },
            set: { onChange(ruleBySettingKeepDays(rule, parseKeepDays($0))) }
        )
    }
}
