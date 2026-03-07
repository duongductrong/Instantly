import SwiftUI

/// Main onboarding wizard — native macOS look with step indicator and navigation.
struct OnboardingView: View {
    @State var viewModel = OnboardingViewModel()

    var body: some View {
        VStack(spacing: 0) {
            // Step content
            stepContent
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            // Navigation
            if !viewModel.isFirstStep, !viewModel.isLastStep {
                Divider()
                navigationBar
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
            }
        }
        .frame(width: 520, height: 520)
        .background(.background)
    }

    // MARK: - Step Indicator

    private var stepIndicator: some View {
        HStack(spacing: 0) {
            ForEach(OnboardingViewModel.Step.allCases, id: \.rawValue) { step in
                stepDot(for: step)

                if step.rawValue < viewModel.stepCount - 1 {
                    Rectangle()
                        .fill(
                            step.rawValue < viewModel.stepIndex
                                ? Color.accentColor.opacity(0.5)
                                : Color.primary.opacity(0.08)
                        )
                        .frame(height: 1.5)
                }
            }
        }
    }

    private func stepDot(for step: OnboardingViewModel.Step) -> some View {
        ZStack {
            if step.rawValue < viewModel.stepIndex {
                // Completed
                Circle()
                    .fill(Color.accentColor)
                    .frame(width: 20, height: 20)
                Image(systemName: "checkmark")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(.white)
            } else if step.rawValue == viewModel.stepIndex {
                // Current
                Circle()
                    .fill(Color.accentColor)
                    .frame(width: 20, height: 20)
                Text("\(step.rawValue + 1)")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.white)
            } else {
                // Upcoming
                Circle()
                    .stroke(Color.primary.opacity(0.15), lineWidth: 1.5)
                    .frame(width: 20, height: 20)
                Text("\(step.rawValue + 1)")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(.tertiary)
            }
        }
    }

    // MARK: - Step Content

    @ViewBuilder
    private var stepContent: some View {
        switch viewModel.currentStep {
        case .welcome:
            WelcomeStepView {
                withAnimation(.easeInOut(duration: 0.2)) {
                    viewModel.goNext()
                }
            }
            .transition(.asymmetric(
                insertion: .move(edge: .trailing).combined(with: .opacity),
                removal: .move(edge: .leading).combined(with: .opacity)
            ))

        case .ollamaSetup:
            OllamaSetupStepView(viewModel: viewModel)
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))

        case .providerSelection:
            ProviderStepView(viewModel: viewModel)
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))

        case .completion:
            CompletionStepView(viewModel: viewModel)
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))
        }
    }

    // MARK: - Navigation Bar

    private var navigationBar: some View {
        HStack {
            Button("Back") {
                withAnimation(.easeInOut(duration: 0.2)) {
                    viewModel.goBack()
                }
            }

            Spacer()

            Button("Continue") {
                withAnimation(.easeInOut(duration: 0.2)) {
                    viewModel.goNext()
                }
            }
            .buttonStyle(.borderedProminent)
        }
    }
}
