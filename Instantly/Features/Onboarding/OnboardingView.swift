import SwiftUI

/// Main onboarding wizard — native macOS look with step indicator and navigation.
struct OnboardingView: View {
    @State var viewModel = OnboardingViewModel()

    var body: some View {
        VStack(spacing: 0) {
            // Step indicator
            if !viewModel.isFirstStep, !viewModel.isLastStep {
                stepIndicator
                    .padding(.horizontal, 40)
                    .padding(.top, 24)
                    .padding(.bottom, 8)
            }

            // Step content
            stepContent
                .id(viewModel.currentStep)
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            // Navigation
            if !viewModel.isFirstStep, !viewModel.isLastStep {
                Divider()
                    .padding(.horizontal, 0)
                navigationBar
                    .padding(.horizontal, 28)
                    .padding(.vertical, 16)
            }
        }
        .frame(
            minWidth: 640,
            idealWidth: 720,
            maxWidth: 720,
            minHeight: 520,
            idealHeight: 600,
            maxHeight: 600
        )
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
                                ? DesignTokens.brandGreen.opacity(0.4)
                                : Color.primary.opacity(0.08)
                        )
                        .frame(height: 2)
                        .animation(.snappy(duration: 0.25), value: viewModel.stepIndex)
                }
            }
        }
    }

    private func stepDot(for step: OnboardingViewModel.Step) -> some View {
        ZStack {
            if step.rawValue < viewModel.stepIndex {
                // Completed
                Circle()
                    .fill(DesignTokens.brandGreen)
                    .frame(width: 24, height: 24)
                Image(systemName: "checkmark")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.white)
                    .transition(.scale.combined(with: .opacity))
            } else if step.rawValue == viewModel.stepIndex {
                // Current
                Circle()
                    .fill(DesignTokens.brandGreen)
                    .frame(width: 24, height: 24)
                Text("\(step.rawValue + 1)")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(.white)
            } else {
                // Upcoming
                Circle()
                    .stroke(Color.primary.opacity(0.12), lineWidth: 1.5)
                    .frame(width: 24, height: 24)
                Text("\(step.rawValue + 1)")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.tertiary)
            }
        }
        .animation(.snappy(duration: 0.25), value: viewModel.stepIndex)
    }

    // MARK: - Step Content

    @ViewBuilder
    private var stepContent: some View {
        switch viewModel.currentStep {
        case .welcome:
            WelcomeStepView {
                withAnimation(.snappy(duration: 0.3)) {
                    viewModel.goNext()
                }
            }
            .transition(.asymmetric(
                insertion: .opacity,
                removal: .opacity
            ))

        case .ollamaSetup:
            OllamaSetupStepView(viewModel: viewModel)
                .padding(.horizontal, 32)
                .padding(.top, 16)
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))

        case .providerSelection:
            ProviderStepView(viewModel: viewModel)
                .padding(.horizontal, 32)
                .padding(.top, 16)
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))

        case .completion:
            CompletionStepView(viewModel: viewModel)
                .transition(.asymmetric(
                    insertion: .opacity.combined(with: .scale(scale: 0.98)),
                    removal: .opacity
                ))
        }
    }

    // MARK: - Navigation Bar

    private var navigationBar: some View {
        HStack {
            Button("Back") {
                withAnimation(.snappy(duration: 0.25)) {
                    viewModel.goBack()
                }
            }
            .keyboardShortcut(.escape, modifiers: [])

            Spacer()

            Button("Continue") {
                withAnimation(.snappy(duration: 0.25)) {
                    viewModel.goNext()
                }
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .keyboardShortcut(.return, modifiers: [])
        }
    }
}
