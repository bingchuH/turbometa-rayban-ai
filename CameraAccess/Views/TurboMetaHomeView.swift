/*
 * TurboMeta Home View
 * 主页 - 功能入口
 */

import SwiftUI
import AVFoundation
import UIKit
import AppIntents

struct TurboMetaHomeView: View {
    @ObservedObject var streamViewModel: StreamSessionViewModel
    @ObservedObject var wearablesViewModel: WearablesViewModel
    @StateObject private var quickVisionManager = QuickVisionManager.shared
    @StateObject private var liveAIManager = LiveAIManager.shared
    let apiKey: String

    @State private var showLiveAI = false
    @State private var showLiveStream = false
    @State private var showRTMPStreaming = false
    @State private var showLeanEat = false
    @State private var showQuickVision = false
    @State private var showLiveTranslate = false
    @State private var showQuickTasks = false

    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [
                        AppColors.primary.opacity(0.1),
                        AppColors.secondary.opacity(0.1)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: AppSpacing.lg) {
                        // Header
                        VStack(spacing: AppSpacing.sm) {
                            Text("app.name".localized)
                                .font(AppTypography.largeTitle)
                                .foregroundColor(AppColors.textPrimary)

                            Text("app.subtitle".localized)
                                .font(AppTypography.callout)
                                .foregroundColor(AppColors.textSecondary)
                        }
                        .padding(.top, AppSpacing.xl)

                        // Feature Grid
                        VStack(spacing: AppSpacing.md) {
                            // Row 1
                            HStack(spacing: AppSpacing.md) {
                                FeatureCard(
                                    title: "home.liveai.title".localized,
                                    subtitle: "home.liveai.subtitle".localized,
                                    icon: "brain.head.profile",
                                    gradient: [AppColors.liveAI, AppColors.liveAI.opacity(0.7)]
                                ) {
                                    showLiveAI = true
                                }

                                FeatureCard(
                                    title: "home.quickvision.title".localized,
                                    subtitle: "home.quickvision.subtitle".localized,
                                    icon: "eye.circle.fill",
                                    gradient: [Color.purple, Color.purple.opacity(0.7)]
                                ) {
                                    showQuickVision = true
                                }
                            }

                            // Row 2
                            HStack(spacing: AppSpacing.md) {
                                FeatureCard(
                                    title: "home.translate.title".localized,
                                    subtitle: "home.translate.subtitle".localized,
                                    icon: "globe",
                                    gradient: [Color.teal, Color.teal.opacity(0.7)]
                                ) {
                                    showLiveTranslate = true
                                }

                                FeatureCard(
                                    title: "home.leaneat.title".localized,
                                    subtitle: "home.leaneat.subtitle".localized,
                                    icon: "chart.bar.fill",
                                    gradient: [AppColors.leanEat, AppColors.leanEat.opacity(0.7)]
                                ) {
                                    showLeanEat = true
                                }
                            }

                            // Row 3 - RTMP Streaming (Experimental)
                            FeatureCardWide(
                                title: "home.rtmp.title".localized,
                                subtitle: "home.rtmp.subtitle".localized,
                                icon: "antenna.radiowaves.left.and.right",
                                gradient: [Color.red, Color.orange],
                                badge: "home.experimental".localized
                            ) {
                                showRTMPStreaming = true
                            }

                            // Row 4 - Quick Tasks
                            FeatureCardWide(
                                title: "home.quicktasks.title".localized,
                                subtitle: "home.quicktasks.subtitle".localized,
                                icon: "bolt.circle.fill",
                                gradient: [Color.blue, Color.blue.opacity(0.7)]
                            ) {
                                showQuickTasks = true
                            }

                            // Row 5 - Screen Recording Stream
                            FeatureCardWide(
                                title: "home.livestream.title".localized,
                                subtitle: "home.livestream.subtitle".localized,
                                icon: "video.fill",
                                gradient: [AppColors.liveStream, AppColors.liveStream.opacity(0.7)]
                            ) {
                                showLiveStream = true
                            }
                        }
                        .padding(.horizontal, AppSpacing.lg)
                        .padding(.bottom, AppSpacing.xl)
                    }
                }
            }
            .navigationBarHidden(true)
            .fullScreenCover(isPresented: $showLiveAI) {
                LiveAIView(streamViewModel: streamViewModel, apiKey: apiKey)
            }
            .fullScreenCover(isPresented: $showLiveStream) {
                SimpleLiveStreamView(streamViewModel: streamViewModel)
            }
            .fullScreenCover(isPresented: $showRTMPStreaming) {
                RTMPStreamingView(streamViewModel: streamViewModel)
            }
            .fullScreenCover(isPresented: $showLeanEat) {
                StreamView(viewModel: streamViewModel, wearablesVM: wearablesViewModel)
            }
            .fullScreenCover(isPresented: $showQuickVision) {
                QuickVisionView(streamViewModel: streamViewModel, apiKey: apiKey)
            }
            .fullScreenCover(isPresented: $showLiveTranslate) {
                LiveTranslateView(streamViewModel: streamViewModel)
            }
            .fullScreenCover(isPresented: $showQuickTasks) {
                QuickTasksView(streamViewModel: streamViewModel, apiKey: apiKey)
            }
        }
        .onAppear {
            // 确保 QuickVisionManager 有 streamViewModel 引用
            quickVisionManager.setStreamViewModel(streamViewModel)
            // 确保 LiveAIManager 有 streamViewModel 引用
            liveAIManager.setStreamViewModel(streamViewModel)
        }
        .onReceive(NotificationCenter.default.publisher(for: .liveAITriggered)) { _ in
            // 从快捷指令触发，自动打开 Live AI 界面
            showLiveAI = true
        }
    }
}


// MARK: - Quick Tasks View
// 快捷任务界面 - 用于创建和管理车辆自动化任务

struct QuickTasksView: View {
    @ObservedObject var streamViewModel: StreamSessionViewModel
    let apiKey: String

    @StateObject private var quickTasksManager = QuickTasksManager.shared
    @State private var showingErrorAlert = false
    @State private var errorMessage = ""

    init(streamViewModel: StreamSessionViewModel, apiKey: String) {
        self.streamViewModel = streamViewModel
        self.apiKey = apiKey
        // 在UI界面中只启用结果反馈，避免与用户操作冲突和节省token
        QuickTasksManager.shared.ttsFeedbackMode = .resultsOnly
    }

    var body: some View {
        NavigationView {
            VStack(spacing: AppSpacing.lg) {
                // Header
                VStack(spacing: AppSpacing.sm) {
                    Text("快捷任务")
                        .font(AppTypography.title2)
                        .fontWeight(.bold)
                        .foregroundColor(AppColors.textPrimary)

                    Text("通过语音创建车辆自动化任务")
                        .font(AppTypography.subheadline)
                        .foregroundColor(AppColors.textSecondary)
                }
                .padding(.top, AppSpacing.xl)

                // Status Indicator
                HStack {
                    Circle()
                        .fill(getStatusColor())
                        .frame(width: 12, height: 12)

                    Text(getStatusText())
                        .font(AppTypography.caption)
                        .foregroundColor(getStatusColor())
                }

                // Action Buttons
                VStack(spacing: AppSpacing.md) {
                    // Start Session Button
                    PrimaryButton(
                        title: quickTasksManager.hasActiveSession ? "会话已建立" : "开始快捷任务",
                        systemImage: quickTasksManager.hasActiveSession ? "checkmark.circle.fill" : "bolt.circle.fill",
                        disabled: quickTasksManager.hasActiveSession || quickTasksManager.isProcessing
                    ) {
                        await quickTasksManager.startQuickTasksSession()
                    }
                    .opacity(quickTasksManager.hasActiveSession ? 0.7 : 1.0)

                    // Wake Word Detection Toggle
                    Toggle("启用唤醒词检测", isOn: Binding(
                        get: { quickTasksManager.isWakeWordDetectionActive },
                        set: { isOn in
                            if isOn {
                                quickTasksManager.startWakeWordDetection()
                            } else {
                                quickTasksManager.stopWakeWordDetection()
                            }
                        }
                    ))
                    .toggleStyle(SwitchToggleStyle(tint: AppColors.primary))
                    .padding(.horizontal, AppSpacing.lg)
                    .disabled(!quickTasksManager.hasActiveSession || quickTasksManager.isProcessing)
                    .opacity(quickTasksManager.hasActiveSession && !quickTasksManager.isProcessing ? 1.0 : 0.5)

                    Text("当检测到唤醒词时自动开始录音")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, AppSpacing.lg)

                    // Record Button
                    PrimaryButton(
                        title: quickTasksManager.isListening ? "正在录音..." : quickTasksManager.isWakeWordDetectionActive ? "唤醒词检测中..." : "按住说话",
                        systemImage: quickTasksManager.isListening ? "stop.circle.fill" :
                                     quickTasksManager.isWakeWordDetectionActive ? "ear.fill" : "mic.fill",
                        backgroundColor: quickTasksManager.isListening ? .red :
                                       quickTasksManager.isWakeWordDetectionActive ? .orange : AppColors.primary,
                        disabled: !quickTasksManager.hasActiveSession || quickTasksManager.isProcessing
                    ) {
                        if quickTasksManager.isListening {
                            await quickTasksManager.stopRecordingAndSend()
                        } else if !quickTasksManager.isWakeWordDetectionActive {
                            quickTasksManager.startRecording()
                        }
                    }
                    .simultaneousGesture(
                        LongPressGesture(minimumDuration: 0.1)
                            .onEnded { _ in
                                if !quickTasksManager.isListening && !quickTasksManager.isWakeWordDetectionActive {
                                    quickTasksManager.startRecording()
                                }
                            }
                    )
                    .simultaneousGesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                if quickTasksManager.isListening && value.translation.height > 50 {
                                    // Cancel recording if user drags up
                                    quickTasksManager.audioRecorder?.stop()
                                    quickTasksManager.audioRecorder = nil
                                    quickTasksManager.isListening = false
                                }
                            }
                            .onEnded { value in
                                if quickTasksManager.isListening {
                                    if value.translation.height > 50 {
                                        // Cancelled
                                        print("🎤 [QuickTasks] Recording cancelled")
                                    } else {
                                        // Complete recording
                                        Task {
                                            await quickTasksManager.stopRecordingAndSend()
                                        }
                                    }
                                }
                            }
                    )

                    // Clear Session Button
                    PrimaryButton(
                        title: "清除会话",
                        systemImage: "xmark.circle.fill",
                        backgroundColor: .secondary,
                        disabled: !quickTasksManager.hasActiveSession
                    ) {
                        quickTasksManager.clearSession()
                    }
                }
                .padding(.horizontal, AppSpacing.lg)

                // Last Result
                if let lastResult = quickTasksManager.lastResult {
                    VStack(alignment: .leading, spacing: AppSpacing.sm) {
                        Text("最近结果:")
                            .font(AppTypography.footnote)
                            .foregroundColor(AppColors.textSecondary)

                        Text(lastResult)
                            .font(AppTypography.body)
                            .foregroundColor(AppColors.textPrimary)
                            .multilineTextAlignment(.leading)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(AppSpacing.md)
                            .background(AppColors.secondaryBackground)
                            .cornerRadius(AppCornerRadius.md)
                    }
                    .padding(.horizontal, AppSpacing.lg)
                }

                Spacer()
            }
            .alert("错误", isPresented: $showingErrorAlert) {
                Button("确定") { }
            } message: {
                Text(errorMessage)
            }
            .onChange(of: quickTasksManager.errorMessage) { newValue in
                if let error = newValue {
                    errorMessage = error
                    showingErrorAlert = true
                }
            }
            .onDisappear {
                // 在页面消失时停止录音
                if quickTasksManager.isListening {
                    quickTasksManager.audioRecorder?.stop()
                    quickTasksManager.audioRecorder = nil
                    quickTasksManager.isListening = false
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }

    private func getStatusColor() -> Color {
        if quickTasksManager.isProcessing {
            return .orange
        } else if quickTasksManager.hasActiveSession {
            return .green
        } else {
            return .gray
        }
    }

    private func getStatusText() -> String {
        if quickTasksManager.isProcessing {
            return "处理中..."
        } else if quickTasksManager.hasActiveSession {
            return "会话已就绪"
        } else {
            return "等待启动"
        }
    }
}

// MARK: - Supporting Views

struct PrimaryButton: View {
    let title: String
    let systemImage: String
    var backgroundColor: Color = AppColors.primary
    var disabled: Bool = false
    let action: () async -> Void

    var body: some View {
        Button(action: {
            Task {
                await action()
            }
        }) {
            HStack {
                Image(systemName: systemImage)
                    .font(.system(size: 18, weight: .medium))

                Text(title)
                    .font(AppTypography.headline)
                    .fontWeight(.medium)
            }
            .frame(maxWidth: .infinity)
            .padding(AppSpacing.lg)
            .background(disabled ? .secondary : backgroundColor)
            .foregroundColor(.white)
            .cornerRadius(AppCornerRadius.lg)
            .opacity(disabled ? 0.5 : 1.0)
        }
        .disabled(disabled)
        .buttonStyle(ScaleButtonStyle())
    }
}

// MARK: - Feature Card

struct FeatureCard: View {
    let title: String
    let subtitle: String
    let icon: String
    let gradient: [Color]
    var isPlaceholder: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: AppSpacing.md) {
                Spacer()

                // Icon
                ZStack {
                    Circle()
                        .fill(.white.opacity(0.2))
                        .frame(width: 56, height: 56)

                    Image(systemName: icon)
                        .font(.system(size: 26, weight: .medium))
                        .foregroundColor(.white)
                }

                // Text
                VStack(spacing: AppSpacing.xs) {
                    Text(title)
                        .font(AppTypography.headline)
                        .foregroundColor(.white)

                    Text(subtitle)
                        .font(AppTypography.caption)
                        .foregroundColor(.white.opacity(0.8))
                }

                if isPlaceholder {
                    Text("home.comingsoon".localized)
                        .font(AppTypography.caption)
                        .foregroundColor(.white.opacity(0.9))
                        .padding(.horizontal, AppSpacing.md)
                        .padding(.vertical, AppSpacing.xs)
                        .background(.white.opacity(0.2))
                        .cornerRadius(AppCornerRadius.sm)
                }

                Spacer()
            }
            .frame(maxWidth: .infinity)
            .frame(height: 180)
            .background(
                LinearGradient(
                    colors: gradient,
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .cornerRadius(AppCornerRadius.lg)
            .shadow(color: AppShadow.medium(), radius: 10, x: 0, y: 5)
        }
        .disabled(isPlaceholder)
        .buttonStyle(ScaleButtonStyle())
    }
}

// MARK: - Feature Card Wide

struct FeatureCardWide: View {
    let title: String
    let subtitle: String
    let icon: String
    let gradient: [Color]
    var badge: String? = nil
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: AppSpacing.lg) {
                // Icon
                ZStack {
                    Circle()
                        .fill(.white.opacity(0.2))
                        .frame(width: 64, height: 64)

                    Image(systemName: icon)
                        .font(.system(size: 30, weight: .medium))
                        .foregroundColor(.white)
                }

                // Text
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    HStack(spacing: AppSpacing.sm) {
                        Text(title)
                            .font(AppTypography.title2)
                            .foregroundColor(.white)

                        if let badge = badge {
                            Text(badge)
                                .font(.caption2)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.white.opacity(0.25))
                                .cornerRadius(4)
                        }
                    }

                    Text(subtitle)
                        .font(AppTypography.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.white.opacity(0.6))
            }
            .padding(AppSpacing.lg)
            .background(
                LinearGradient(
                    colors: gradient,
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(AppCornerRadius.lg)
            .shadow(color: AppShadow.medium(), radius: 10, x: 0, y: 5)
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// MARK: - Scale Button Style

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: configuration.isPressed)
    }
}
