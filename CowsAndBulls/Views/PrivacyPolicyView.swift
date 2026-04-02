//
//  PrivacyPolicyView.swift
//  CowsAndBulls
//
//  Created by OpenAI Codex.
//

import SwiftUI

struct PrivacyPolicyView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                Text(localized("privacy.title"))
                    .font(.largeTitle)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 4)

                Text(localized("privacy.last_updated", localized("privacy.last_updated_value")))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 4)
                    .padding(.top, 6)

                PrivacyDivider()
                PrivacyPolicySection(titleKey: "privacy.controller.title", bodyKey: "privacy.controller.body")
                PrivacyDivider()
                PrivacyPolicySection(titleKey: "privacy.data_purposes.title", bodyKey: "privacy.data_purposes.body")
                PrivacyDivider()
                PrivacyPolicySection(titleKey: "privacy.legal_basis.title", bodyKey: "privacy.legal_basis.body")
                PrivacyDivider()
                PrivacyPolicySection(titleKey: "privacy.data_sharing.title", bodyKey: "privacy.data_sharing.body")
                PrivacyDivider()
                PrivacyPolicySection(titleKey: "privacy.third_party.title", bodyKey: "privacy.third_party.body")
                PrivacyDivider()
                PrivacyPolicySection(titleKey: "privacy.security.title", bodyKey: "privacy.security.body")
                PrivacyDivider()
                PrivacyPolicySection(titleKey: "privacy.data_retention.title", bodyKey: "privacy.data_retention.body")
                PrivacyDivider()
                PrivacyPolicySection(titleKey: "privacy.user_rights.title", bodyKey: "privacy.user_rights.body")
                PrivacyDivider()
                PrivacyPolicySection(titleKey: "privacy.children.title", bodyKey: "privacy.children.body")
                PrivacyDivider()
                PrivacyPolicySection(titleKey: "privacy.open_source.title", bodyKey: "privacy.open_source.body")
                PrivacyDivider()
                PrivacyPolicySection(titleKey: "privacy.changes.title", bodyKey: "privacy.changes.body")
                PrivacyDivider()
                PrivacyPolicySection(titleKey: "privacy.contact.title", bodyKey: "privacy.contact.body")
            }
            .frame(maxWidth: 900)
            .frame(maxWidth: .infinity)
            .padding(20)
        }
    }
}

private struct PrivacyPolicySection: View {
    let titleKey: String
    let bodyKey: String

    var body: some View {
        LearnSection(title: localized(titleKey)) {
            Text(localized(bodyKey))
                .textSelection(.enabled)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

private struct PrivacyDivider: View {
    var body: some View {
        Divider()
            .padding()
    }
}

#Preview {
    PrivacyPolicyView()
}
