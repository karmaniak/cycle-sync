import SwiftUI
import CycleCore

struct OnboardingView: View {
    @EnvironmentObject private var model: AppModel
    @EnvironmentObject private var sharer: SharerStore

    private enum Step { case welcome, sharerSetup }

    @State private var step: Step = .welcome
    @State private var typicalLength: Int? = nil

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                switch step {
                case .welcome: welcome
                case .sharerSetup: sharerSetup
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 24)
        }
        .background(Color(.systemGroupedBackground))
    }

    // MARK: Step 1

    private var welcome: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text(Copy.Onboarding.welcomeTitle)
                .font(.system(.largeTitle, design: .rounded).weight(.bold))
            Text(Copy.Onboarding.welcomeBody)
                .font(.body)
                .foregroundStyle(.secondary)
            Text(Copy.Onboarding.chooseRole)
                .font(.headline)
                .padding(.top, 8)

            roleCard(title: Copy.Onboarding.sharerTitle, body: Copy.Onboarding.sharerBody, symbol: "heart.circle") {
                step = .sharerSetup
            }
            roleCard(title: Copy.Onboarding.viewerTitle, body: Copy.Onboarding.viewerBody, symbol: "eye") {
                model.role = .viewer
            }
        }
    }

    private func roleCard(title: String, body: String, symbol: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(alignment: .top, spacing: 14) {
                Image(systemName: symbol)
                    .font(.title)
                    .foregroundStyle(Color(ColorScale.color(at: 0.5)))
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 6) {
                    Text(title)
                        .font(.system(.headline, design: .rounded))
                        .foregroundStyle(.primary)
                    Text(body)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.leading)
                }
                Spacer(minLength: 0)
            }
            .softCard()
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isButton)
    }

    // MARK: Step 2 (Sharer)

    private var sharerSetup: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 8) {
                Text(Copy.Onboarding.healthTitle)
                    .font(.system(.title2, design: .rounded).weight(.bold))
                Text(Copy.Onboarding.healthBody)
                    .font(.body)
                    .foregroundStyle(.secondary)
                if sharer.isHealthAvailable && !sharer.healthConnected {
                    Button {
                        Task { await sharer.connectHealth() }
                    } label: {
                        Text(Copy.Onboarding.healthAllow)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Color(ColorScale.color(at: 0.6)))
                    .controlSize(.large)
                    .padding(.top, 4)
                }
                if sharer.healthConnected {
                    Label(Copy.Settings.healthConnected, systemImage: "checkmark.circle")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            .softCard()

            VStack(alignment: .leading, spacing: 8) {
                Text(Copy.Onboarding.typicalLengthTitle)
                    .font(.system(.title3, design: .rounded).weight(.bold))
                Text(Copy.Onboarding.typicalLengthBody)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Picker(Copy.Onboarding.typicalLengthTitle, selection: $typicalLength) {
                    Text(Copy.Onboarding.typicalLengthAuto).tag(Int?.none)
                    ForEach(21...40, id: \.self) { days in
                        Text(Copy.Onboarding.typicalLengthDays(days)).tag(Int?.some(days))
                    }
                }
                .pickerStyle(.menu)
            }
            .softCard()

            Button {
                let chosen = typicalLength
                Task {
                    await sharer.setTypicalCycleLength(chosen)
                    model.role = .sharer
                }
            } label: {
                Text(Copy.Onboarding.done)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(Color(ColorScale.color(at: 0.6)))
            .controlSize(.large)
        }
    }
}
