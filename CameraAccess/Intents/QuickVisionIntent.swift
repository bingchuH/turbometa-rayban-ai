/*
 * Quick Vision Intent
 * App Intent - 支持 Siri 和快捷指令触发快速识图
 *
 * 支持的模式：
 * - 默认模式：通用图像描述
 * - 健康识图：分析食品健康程度
 * - 盲人模式：为视障用户描述环境
 * - 阅读模式：识别并朗读文字
 * - 翻译模式：识别并翻译文字
 * - 百科模式：百科知识介绍
 * - 自定义：使用自定义提示词
 */

import AppIntents
import UIKit
import SwiftUI
import AVFoundation

// MARK: - Quick Vision Intent (Default Mode)

@available(iOS 16.0, *)
struct QuickVisionIntent: AppIntent {
    static var title: LocalizedStringResource = "快速识图"
    static var description = IntentDescription("使用 Ray-Ban Meta 眼镜拍照并识别图像内容")
    static var openAppWhenRun: Bool = false

    @Parameter(title: "自定义提示")
    var customPrompt: String?

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let manager = QuickVisionManager.shared
        await manager.performQuickVisionWithMode(.standard, customPrompt: customPrompt)
        return formatResult(manager)
    }
}

// MARK: - Health Mode Intent

@available(iOS 16.0, *)
struct QuickVisionHealthIntent: AppIntent {
    static var title: LocalizedStringResource = "健康识图"
    static var description = IntentDescription("分析食品/饮料的健康程度")
    static var openAppWhenRun: Bool = false

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let manager = QuickVisionManager.shared
        await manager.performQuickVisionWithMode(.health)
        return formatResult(manager)
    }
}

// MARK: - Blind Mode Intent

@available(iOS 16.0, *)
struct QuickVisionBlindIntent: AppIntent {
    static var title: LocalizedStringResource = "环境描述"
    static var description = IntentDescription("为视障用户详细描述眼前的环境")
    static var openAppWhenRun: Bool = false

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let manager = QuickVisionManager.shared
        await manager.performQuickVisionWithMode(.blind)
        return formatResult(manager)
    }
}

// MARK: - Reading Mode Intent

@available(iOS 16.0, *)
struct QuickVisionReadingIntent: AppIntent {
    static var title: LocalizedStringResource = "朗读文字"
    static var description = IntentDescription("识别并朗读图片中的文字内容")
    static var openAppWhenRun: Bool = false

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let manager = QuickVisionManager.shared
        await manager.performQuickVisionWithMode(.reading)
        return formatResult(manager)
    }
}

// MARK: - Translation Mode Intent

@available(iOS 16.0, *)
struct QuickVisionTranslateIntent: AppIntent {
    static var title: LocalizedStringResource = "翻译文字"
    static var description = IntentDescription("识别并翻译图片中的外语文字")
    static var openAppWhenRun: Bool = false

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let manager = QuickVisionManager.shared
        await manager.performQuickVisionWithMode(.translate)
        return formatResult(manager)
    }
}

// MARK: - Encyclopedia Mode Intent

@available(iOS 16.0, *)
struct QuickVisionEncyclopediaIntent: AppIntent {
    static var title: LocalizedStringResource = "百科识别"
    static var description = IntentDescription("识别物体并提供百科知识介绍")
    static var openAppWhenRun: Bool = false

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let manager = QuickVisionManager.shared
        await manager.performQuickVisionWithMode(.encyclopedia)
        return formatResult(manager)
    }
}

// MARK: - Helper Function

@available(iOS 16.0, *)
@MainActor
private func formatResult(_ manager: QuickVisionManager) -> some IntentResult & ProvidesDialog {
    if let result = manager.lastResult {
        return .result(dialog: "识别完成：\(result)")
    } else if let error = manager.errorMessage {
        return .result(dialog: "识别失败：\(error)")
    } else {
        return .result(dialog: "识别完成")
    }
}

// MARK: - App Shortcuts Provider

@available(iOS 16.0, *)
struct TurboMetaShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        // 默认识图
        AppShortcut(
            intent: QuickVisionIntent(),
            phrases: [
                "用 \(.applicationName) 识图",
                "用 \(.applicationName) 看看这是什么",
                "\(.applicationName) 快速识图",
                "\(.applicationName) 拍照识别"
            ],
            shortTitle: "快速识图",
            systemImageName: "eye.circle.fill"
        )

        // 健康识图
        AppShortcut(
            intent: QuickVisionHealthIntent(),
            phrases: [
                "用 \(.applicationName) 分析健康",
                "\(.applicationName) 健康识图",
                "\(.applicationName) 这个食物健康吗"
            ],
            shortTitle: "健康识图",
            systemImageName: "heart.circle.fill"
        )

        // 盲人模式
        AppShortcut(
            intent: QuickVisionBlindIntent(),
            phrases: [
                "用 \(.applicationName) 描述环境",
                "\(.applicationName) 看看周围有什么",
                "\(.applicationName) 帮我看看前面"
            ],
            shortTitle: "环境描述",
            systemImageName: "figure.walk.circle.fill"
        )

        // 阅读模式
        AppShortcut(
            intent: QuickVisionReadingIntent(),
            phrases: [
                "用 \(.applicationName) 朗读文字",
                "\(.applicationName) 读一下这个",
                "\(.applicationName) 帮我读文字"
            ],
            shortTitle: "朗读文字",
            systemImageName: "text.viewfinder"
        )

        // 翻译模式
        AppShortcut(
            intent: QuickVisionTranslateIntent(),
            phrases: [
                "用 \(.applicationName) 翻译",
                "\(.applicationName) 翻译这个",
                "\(.applicationName) 这个是什么意思"
            ],
            shortTitle: "翻译文字",
            systemImageName: "character.bubble.fill"
        )

        // 百科模式
        AppShortcut(
            intent: QuickVisionEncyclopediaIntent(),
            phrases: [
                "用 \(.applicationName) 介绍这个",
                "\(.applicationName) 百科识别",
                "\(.applicationName) 这是什么东西"
            ],
            shortTitle: "百科识别",
            systemImageName: "books.vertical.circle.fill"
        )

        // 实时对话
        AppShortcut(
            intent: LiveAIIntent(),
            phrases: [
                "用 \(.applicationName) 实时对话",
                "\(.applicationName) 实时对话",
                "开始 \(.applicationName) 实时对话",
                "\(.applicationName) 开始对话"
            ],
            shortTitle: "实时对话",
            systemImageName: "brain.head.profile"
        )

        // 停止实时对话
        AppShortcut(
            intent: StopLiveAIIntent(),
            phrases: [
                "\(.applicationName) 停止实时对话",
                "停止 \(.applicationName) 实时对话",
                "\(.applicationName) 结束对话"
            ],
            shortTitle: "停止实时对话",
            systemImageName: "stop.circle.fill"
        )
        // 快捷任务相关快捷方式
        AppShortcut(
            intent: QuickTasksIntent(),
            phrases: [
                "用 \(.applicationName) 创建快捷任务",
                "\(.applicationName) 创建车辆任务",
                "\(.applicationName) 车辆自动化",
                "\(.applicationName) 快捷任务"
            ],
            shortTitle: "创建快捷任务",
            systemImageName: "bolt.circle.fill"
        )

        // 查看快捷任务历史
        AppShortcut(
            intent: QuickTasksHistoryIntent(),
            phrases: [
                "用 \(.applicationName) 查看快捷任务历史",
                "\(.applicationName) 刚才创建了什么",
                "\(.applicationName) 最近的任务"
            ],
            shortTitle: "查看历史",
            systemImageName: "clock.arrow.circlepath"
        )
    }
}

// MARK: - Quick Tasks Intent
// App Intent - 支持 Siri 和快捷指令触发快捷任务创建

@available(iOS 16.0, *)
struct QuickTasksIntent: AppIntent {
    static var title: LocalizedStringResource = "创建快捷任务"
    static var description = IntentDescription("通过语音创建车辆自动化快捷任务")
    static var openAppWhenRun: Bool = false

    @Parameter(title: "任务指令")
    var taskInstruction: String?

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let manager = QuickTasksManager.shared

        // 在Intent模式下启用所有TTS反馈
        let originalTTSFeedbackMode = manager.ttsFeedbackMode
        manager.ttsFeedbackMode = .all

        defer {
            // 确保在函数退出前恢复原始设置
            manager.ttsFeedbackMode = originalTTSFeedbackMode
        }

        if let instruction = taskInstruction, !instruction.isEmpty {
            // 如果提供了具体指令，直接发送
            await manager.sendTextMessage(text: instruction)

            if let result = manager.lastResult {
                return .result(dialog: "已创建快捷任务：\(result)")
            } else if let error = manager.errorMessage {
                return .result(dialog: "创建失败：\(error)")
            } else {
                return .result(dialog: "快捷任务已创建")
            }
        } else {
            // 启动语音创建流程
            await manager.startQuickTasksSession()

            return .result(dialog: "请说出您的快捷任务指令")
        }
    }
}


// MARK: - Quick Tasks History Intent

@available(iOS 16.0, *)
struct QuickTasksHistoryIntent: AppIntent {
    static var title: LocalizedStringResource = "查看快捷任务历史"
    static var description = IntentDescription("查看最近创建的快捷任务")
    static var openAppWhenRun: Bool = false

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let manager = QuickTasksManager.shared

        // 在Intent模式下启用所有TTS反馈
        let originalTTSFeedbackMode = manager.ttsFeedbackMode
        manager.ttsFeedbackMode = .all

        defer {
            // 确保在函数退出前恢复原始设置
            manager.ttsFeedbackMode = originalTTSFeedbackMode
        }

        if let resultValue = manager.lastResult {
            return .result(dialog: "最近创建的任务：\(resultValue)")
        } else {
            return .result(dialog: "没有找到最近创建的任务")
        }
    }
}

// MARK: - Quick Tasks Service
// 快捷任务服务 - 用于创建和管理车辆自动化任务
// 通过语音指令创建任务，与后端服务器通信

class QuickTasksService: ObservableObject {
    private let baseURL = "http://106.14.106.198:5000"
    private let ttsService = TTSService.shared

    // 当前会话 ID
    @Published var sessionId: String?

    /// 启动新会话
    func startSession(userId: String, vin: String) async throws -> Bool {
        let endpoint = "\(baseURL)/api/wechat/start_session"
        let body = [
            "user_id": userId,
            "vin": vin
        ]

        guard let url = URL(string: endpoint) else {
            throw QuickTasksError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let encoder = JSONEncoder()
        request.httpBody = try encoder.encode(body)

        print("📡 [QuickTasks] Starting session...")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw QuickTasksError.invalidResponse
        }

        if httpResponse.statusCode != 200 {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            print("❌ [QuickTasks] Start session failed: \(errorMessage)")
            throw QuickTasksError.apiError(statusCode: httpResponse.statusCode, message: errorMessage)
        }

        let rawResponse = String(data: data, encoding: .utf8) ?? "Unable to decode"
        print("📡 [QuickTasks] Raw response: \(rawResponse)")

        do {
            let decoder = JSONDecoder()
            let response = try decoder.decode(SessionResponse.self, from: data)

            if response.success {
                sessionId = response.session_id
                print("✅ [QuickTasks] Session started: \(response.session_id)")
                return true
            } else {
                print("❌ [QuickTasks] Session creation failed")
                throw QuickTasksError.sessionCreationFailed
            }
        } catch {
            print("❌ [QuickTasks] JSON decode error: \(error)")
            throw QuickTasksError.invalidResponse
        }
    }

    /// 发送文本消息
    func sendMessage(query: String, userId: String, vin: String) async throws -> String {
        guard let currentSessionId = sessionId else {
            throw QuickTasksError.noActiveSession
        }

        let endpoint = "\(baseURL)/api/wechat/message"
        let body = [
            "query": query,
            "session_id": currentSessionId,
            "user_id": userId,
            "vin": vin
        ]

        guard let url = URL(string: endpoint) else {
            throw QuickTasksError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let encoder = JSONEncoder()
        request.httpBody = try encoder.encode(body)

        print("📡 [QuickTasks] Sending message: \(query)")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw QuickTasksError.invalidResponse
        }

        if httpResponse.statusCode != 200 {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            print("❌ [QuickTasks] Send message failed: \(errorMessage)")
            throw QuickTasksError.apiError(statusCode: httpResponse.statusCode, message: errorMessage)
        }

        let rawResponse = String(data: data, encoding: .utf8) ?? "Unable to decode"
        print("📡 [QuickTasks] Raw response: \(rawResponse)")

        do {
            let decoder = JSONDecoder()
            let response = try decoder.decode(MessageResponse.self, from: data)

            if response.success {
                // 更新会话 ID (以防服务器返回新的会话 ID)
                if let newSessionId = response.session_id {
                    sessionId = newSessionId
                }
                print("✅ [QuickTasks] Message response: \(response.response)")
                return response.response
            } else {
                print("❌ [QuickTasks] Message failed")
                throw QuickTasksError.messageFailed
            }
        } catch {
            print("❌ [QuickTasks] JSON decode error: \(error)")
            throw QuickTasksError.invalidResponse
        }
    }

    /// 上传语音文件并获取响应
    func sendVoiceMessage(voiceFileData: Data, userId: String, vin: String) async throws -> String {
        guard let currentSessionId = sessionId else {
            throw QuickTasksError.noActiveSession
        }

        let endpoint = "\(baseURL)/api/wechat/message"

        guard let url = URL(string: endpoint) else {
            throw QuickTasksError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"

        let boundary = "Boundary-\(UUID().uuidString)"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        var body = Data()

        // 添加 session_id
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"session_id\"\r\n\r\n\(currentSessionId)\r\n".data(using: .utf8)!)

        // 添加 user_id
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"user_id\"\r\n\r\n\(userId)\r\n".data(using: .utf8)!)

        // 添加 vin
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"vin\"\r\n\r\n\(vin)\r\n".data(using: .utf8)!)

        // 添加语音文件
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"voice\"; filename=\"voice.m4a\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: audio/m4a\r\n\r\n".data(using: .utf8)!)
        body.append(voiceFileData)
        body.append("\r\n".data(using: .utf8)!)

        // 结束边界
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)

        request.httpBody = body

        print("📡 [QuickTasks] Uploading voice file...")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw QuickTasksError.invalidResponse
        }

        if httpResponse.statusCode != 200 {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            print("❌ [QuickTasks] Voice upload failed: \(errorMessage)")
            throw QuickTasksError.apiError(statusCode: httpResponse.statusCode, message: errorMessage)
        }

        let rawResponse = String(data: data, encoding: .utf8) ?? "Unable to decode"
        print("📡 [QuickTasks] Raw response: \(rawResponse)")

        do {
            let decoder = JSONDecoder()
            let response = try decoder.decode(MessageResponse.self, from: data)

            if response.success {
                // 更新会话 ID (以防服务器返回新的会话 ID)
                if let newSessionId = response.session_id {
                    sessionId = newSessionId
                }
                print("✅ [QuickTasks] Voice message response: \(response.response)")
                return response.response
            } else {
                print("❌ [QuickTasks] Voice message failed")
                throw QuickTasksError.messageFailed
            }
        } catch {
            print("❌ [QuickTasks] JSON decode error: \(error)")
            throw QuickTasksError.invalidResponse
        }
    }

    // MARK: - Data Models

    struct SessionResponse: Codable {
        let success: Bool
        let session_id: String?
    }

    struct MessageResponse: Codable {
        let success: Bool
        let response: String
        let session_id: String?
    }
}

// MARK: - Error Types

enum QuickTasksError: LocalizedError {
    case invalidURL
    case noActiveSession
    case sessionCreationFailed
    case messageFailed
    case invalidResponse
    case apiError(statusCode: Int, message: String)
    case networkError(message: String)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "无效的服务器地址"
        case .noActiveSession:
            return "没有活跃的会话，请先启动会话"
        case .sessionCreationFailed:
            return "会话创建失败"
        case .messageFailed:
            return "消息发送失败"
        case .invalidResponse:
            return "无效的响应格式"
        case .apiError(let statusCode, let message):
            switch statusCode {
            case 0, -1:
                return "网络连接失败，请检查网络后重试"
            default:
                return "API错误(\(statusCode)): \(message)"
            }
        case .networkError(let message):
            return message
        }
    }
}

// MARK: - Quick Tasks Manager
// 快捷任务管理器 - 处理任务创建流程和状态管理

@MainActor
class QuickTasksManager: ObservableObject {
    static let shared = QuickTasksManager()

    // Published state
    @Published var isProcessing = false
    @Published var isListening = false
    @Published var lastResult: String?
    @Published var errorMessage: String?
    @Published var currentTranscript: String = ""

    // ASR and Wake Word Detection
    @Published var isWakeWordDetectionActive = false
    private var omnirealtimeService: OmniRealtimeService?
    private var wakeWordDetectionTimer: Timer?
    private var currentASRTranscript = ""
    private var silenceTimeout: TimeInterval = 2.0 // 默认2秒静音超时，稍后会从UserDefaults加载

    // Wake words for detection
    private let wakeWords: Set<String> = ["你好斑马", "嘿你好呀", "你好宝马", "嗨斑马", "斑马你好", "你好班马", "hello班马", "斑马斑马", "你好半马"]

    // 在初始化时加载用户设置的静音超时值
    private func loadUserSettings() {
        let savedTimeout = UserDefaults.standard.double(forKey: "quick_tasks_silence_timeout")
        if savedTimeout != 0 {
            silenceTimeout = savedTimeout
        } else {
            // 默认值
            silenceTimeout = 2.0
            // 同时保存到UserDefaults以确保一致性
            UserDefaults.standard.set(silenceTimeout, forKey: "quick_tasks_silence_timeout")
        }
    }

    // Service
    private let quickTasksService = QuickTasksService()
    private let ttsService = TTSService.shared

    // 控制是否启用TTS语音反馈
    // - 全部启用（Intent模式）：所有TTS反馈都启用
    // - 仅结果反馈（UI模式）：只在任务成功/失败时启用TTS反馈
    // - 全部禁用：没有TTS反馈
    enum TTSFeedbackMode {
        case all        // 启用所有TTS反馈
        case resultsOnly // 仅在结果时启用TTS反馈（成功/失败）
        case none       // 不启用TTS反馈
    }

    var ttsFeedbackMode: TTSFeedbackMode = .all

    // 检查是否应该播放TTS反馈
    private func shouldPlayTTS(isResultFeedback: Bool = false) -> Bool {
        switch ttsFeedbackMode {
        case .all:
            return true
        case .resultsOnly:
            // 仅结果反馈模式下，只在结果（成功/失败）时播放TTS
            return isResultFeedback
        case .none:
            return false
        }
    }

    // Audio recording
    var audioRecorder: AVAudioRecorder?
    private var recordingSession: AVAudioSession!

    // Configuration - Load from UserDefaults or use defaults
    private var userId: String {
        UserDefaults.standard.string(forKey: "quick_tasks_user_id") ?? "user_\(UIDevice.current.identifierForVendor?.uuidString.prefix(8) ?? UUID().uuidString.prefix(8))"
    }

    private var vin: String {
        "LSJEH43C0SZ000475"
    }

    private init() {
        setupAudioSession()
        loadUserSettings()  // 加载用户配置
        setupOmniRealtimeService()
    }

    private func setupAudioSession() {
        recordingSession = AVAudioSession.sharedInstance()

        do {
            try recordingSession.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker])
            try recordingSession.setActive(true)
        } catch {
            print("❌ [QuickTasks] Audio session setup failed: \(error)")
        }
    }

    private func setupOmniRealtimeService() {
        // 初始化OmniRealtimeService用于ASR转录
        if let apiKey = APIKeyManager.shared.getAPIKey(), !apiKey.isEmpty {
            omnirealtimeService = OmniRealtimeService(apiKey: apiKey)
            setupOmniCallbacks()
        } else {
            print("⚠️ [QuickTasks] API key not found, waiting for setup")
        }
    }

    private func setupOmniCallbacks() {
        omnirealtimeService?.onUserTranscript = { [weak self] transcript in
            Task { @MainActor in
                self?.handleASRTranscript(transcript)
            }
        }

        // 监听快捷任务语音识别结果
        omnirealtimeService?.onQuickTaskTranscript = { [weak self] transcript in
            Task { @MainActor in
                self?.handleQuickTaskTranscript(transcript)
            }
        }

        // 监听AI助手的文本回复，以处理非语音形式的快捷任务检测
        omnirealtimeService?.onAssistantText = { [weak self] text in
            // 当AI回复是快捷任务时，此回调将被触发，但我们主要依靠onQuickTaskTranscript来处理
            // 保持静默以避免TTS重复播放
            // 对于快捷任务，不要触发任何TTS
            print("🤖 [Omni] AI助手回复: \(text)")
        }

        // 也可以监听实时转录片段
        omnirealtimeService?.onTranscriptDelta = { [weak self] delta in
            Task { @MainActor in
                // 实时检测，不需要积累完整的转录文本
                if self?.detectWakeWord(in: delta) == true {
                    print("✅ [QuickTasks] Wake word detected in delta: \(delta)")
                    self?.startFormalRecording()
                }
            }
        }

        // 监听语音活动事件，以便在用户说话结束后重新激活唤醒词检测
        omnirealtimeService?.onSpeechStopped = { [weak self] in
            Task { @MainActor in
                // 如果不是在正式录音模式，但处于唤醒词检测模式，则可以重置继续监听
                if !(self?.isListening ?? false) && (self?.isWakeWordDetectionActive ?? false) {
                    print("⏸️ [QuickTasks] Speech stopped, continuing wake word detection")
                    // 保持唤醒词检测状态，继续监听
                }
            }
        }

        omnirealtimeService?.onConnected = { [weak self] in
            Task { @MainActor in
                print("✅ [QuickTasks] OmniRealtimeService connected for ASR")
            }
        }

        omnirealtimeService?.onError = { [weak self] error in
            Task { @MainActor in
                print("❌ [QuickTasks] OmniRealtimeService error: \(error)")

                // 如果出现错误且当前处于唤醒词检测模式，尝试重启
                if self?.isWakeWordDetectionActive == true {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                        self?.stopWakeWordDetection()
                        self?.startWakeWordDetection()
                    }
                }
            }
        }
    }

    /// 启动快捷任务会话
    func startQuickTasksSession() async {
        guard !isProcessing else {
            print("⚠️ [QuickTasks] Already processing")
            return
        }

        isProcessing = true
        errorMessage = nil
        lastResult = nil

        do {
            // 启动会话
            let success = try await quickTasksService.startSession(userId: userId, vin: vin)

            if success {
                print("✅ [QuickTasks] Session started successfully")
                if shouldPlayTTS(isResultFeedback: false) {  // 非结果反馈
                    ttsService.speak("请说出唤醒词召唤快捷任务")
                }
            } else {
                print("❌ [QuickTasks] Failed to start session")
                errorMessage = "会话启动失败"
                if shouldPlayTTS(isResultFeedback: true) {  // 结果反馈
                    ttsService.speak("会话启动失败，请重试")
                }
            }
        } catch let error as QuickTasksError {
            errorMessage = error.localizedDescription
            print("❌ [QuickTasks] Start session error: \(error)")
            if shouldPlayTTS(isResultFeedback: true) {  // 结果反馈
                ttsService.speak(error.localizedDescription)
            }
        } catch {
            errorMessage = error.localizedDescription
            print("❌ [QuickTasks] Start session error: \(error)")
            if shouldPlayTTS(isResultFeedback: true) {  // 结果反馈
                ttsService.speak("服务暂时不可用，请稍后再试")
            }
        }

        isProcessing = false
    }

    /// 处理ASR转录文本 - 唤醒词检测
    private func handleASRTranscript(_ transcript: String) {
        print("📝 [QuickTasks] Received ASR transcript: \(transcript)")

        // 更新当前ASR转录文本
        currentASRTranscript += transcript

        // 检查是否包含唤醒词
        if detectWakeWord(in: currentASRTranscript) {
            // 检测到唤醒词，启动正式录音
            print("✅ [QuickTasks] Wake word detected, starting formal recording")
            startFormalRecording()
        }
    }

    /// 检测唤醒词
    private func detectWakeWord(in text: String) -> Bool {
        let normalizedText = text.trimmingCharacters(in: .whitespacesAndNewlines)

        // 精确匹配，允许一些常见的标点符号和空格变化
        for wakeWord in wakeWords {
            if normalizedText.localizedCaseInsensitiveContains(wakeWord) {
                return true
            }
        }

        return false
    }

    /// 重置ASR转录文本
    private func resetASRTranscript() {
        currentASRTranscript = ""
    }

    /// 启动正式录音 - 检测到唤醒词后的流程
    private func startFormalRecording() {
        // 停止ASR监听
        stopWakeWordDetection()

        // 播放唤醒提示音
        playWakeupSound()

        // 播放语音提示（可选）
        if shouldPlayTTS(isResultFeedback: false) {
            ttsService.speak("请说您的指令")
        }

        // 启动手动录音（与UI的录音逻辑一致）
        startRecording()
    }

    /// 处理快捷任务语音识别文本
    private func handleQuickTaskTranscript(_ transcript: String) {
        print("⚡ [QuickTasks] Received quick task transcript: \(transcript)")

        // 直接将提取的查询发送到后端的文字接口
        Task { @MainActor in
            await sendQuickTaskQueryToBackend(transcript)
        }
    }

    /// 将快捷任务查询发送到后端
    private func sendQuickTaskQueryToBackend(_ query: String) async {
        guard !isProcessing else {
            print("⚠️ [QuickTasks] Already processing")
            return
        }

        isProcessing = true
        errorMessage = nil

        do {
            // 如果没有活跃会话，则启动新会话
            if !hasActiveSession {
                let success = try await quickTasksService.startSession(userId: userId, vin: vin)
                if !success {
                    throw QuickTasksError.sessionCreationFailed
                }
            }

            let response = try await quickTasksService.sendMessage(
                query: query,
                userId: userId,
                vin: vin
            )

            lastResult = response
            print("✅ [QuickTasks] Quick task query sent successfully: \(response)")

            // 播放后端API返回的response内容
            if shouldPlayTTS(isResultFeedback: true) {
                ttsService.speak(response)
            }

        } catch let error as QuickTasksError {
            errorMessage = error.localizedDescription
            print("❌ [QuickTasks] Send quick task query error: \(error)")

            // 快捷任务错误也不播放TTS
            print("⚠️ [QuickTasks] 快捷任务错误，不播放TTS: \(error.localizedDescription)")
        } catch {
            errorMessage = error.localizedDescription
            print("❌ [QuickTasks] Send quick task query error: \(error)")

            // 快捷任务错误也不播放TTS
            print("⚠️ [QuickTasks] 快捷任务错误，不播放TTS")
        }

        // Quick task processing done, unmute Omni audio responses if needed
        DispatchQueue.main.async {
            self.omnirealtimeService?.unmuteAudioResponses()
        }

        isProcessing = false
    }

    /// 播放唤醒提示音
    private func playWakeupSound() {
        // 查找wakeup.mp3文件
        guard let soundURL = Bundle.main.url(forResource: "wakeup", withExtension: "mp3") else {
            print("⚠️ [QuickTasks] wakeup.mp3 not found in bundle, skipping sound")
            return
        }

        do {
            // 创建音频播放器
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playback, mode: .default)
            try audioSession.setActive(true)

            let soundPlayer = try AVAudioPlayer(contentsOf: soundURL)
            soundPlayer.volume = 1.0
            soundPlayer.play()

            print("🔊 [QuickTasks] Wakeup sound played successfully")

            // 设置播放完成回调（可选）
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak soundPlayer] in
                // 保持播放器引用直到播放完成
                _ = soundPlayer
            }
        } catch {
            print("❌ [QuickTasks] Failed to play wakeup sound: \(error.localizedDescription)")
        }
    }

    /// 启用唤醒词检测模式
    func startWakeWordDetection() {
        guard !isWakeWordDetectionActive else {
            print("⚠️ [QuickTasks] Wake word detection already active")
            return
        }

        // 检查API Key
        if let apiKey = APIKeyManager.shared.getAPIKey(), !apiKey.isEmpty, omnirealtimeService == nil {
            omnirealtimeService = OmniRealtimeService(apiKey: apiKey)
            setupOmniCallbacks()
        }

        guard var service = omnirealtimeService else {
            print("❌ [QuickTasks] OmniRealtime service not available")
            return
        }

        isWakeWordDetectionActive = true
        resetASRTranscript()

        // 连接到ASR服务
        service.connect()

        // 等待连接后配置使用快捷任务模式的提示词
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            service.updateSessionConfiguration(instructions: LiveAIMode.quicktask.systemPrompt)
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            // 等待连接后开始录音
            service.startRecording()
            print("👂 [QuickTasks] Started wake word detection listening")
        }
    }

    /// 停止唤醒词检测模式
    func stopWakeWordDetection() {
        guard isWakeWordDetectionActive else { return }

        omnirealtimeService?.stopRecording()
        omnirealtimeService = nil
        isWakeWordDetectionActive = false
        resetASRTranscript()

        // 清除静音超时定时器
        wakeWordDetectionTimer?.invalidate()
        wakeWordDetectionTimer = nil

        print("🛑 [QuickTasks] Wake word detection stopped")
    }

    /// 开始录音
    func startRecording() {
        guard !isListening else {
            print("⚠️ [QuickTasks] Already listening")
            return
        }

        isListening = true
        currentTranscript = ""

        let audioFilename = getDocumentsDirectory().appendingPathComponent("quick_tasks_recording.m4a")

        let settings = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 12000,
            AVNumberOfChannelsKey: 1,
            AVEncoderBitRateKey: 16000,
            AVEncoderAudioQualityKey: AVAudioQuality.min.rawValue
        ]

        do {
            audioRecorder = try AVAudioRecorder(url: audioFilename, settings: settings)
            audioRecorder?.prepareToRecord()
            audioRecorder?.record()

            print("🎤 [QuickTasks] Started recording")

            // 设置静音超时检测 - 2秒无语音则自动停止录音
            startSilenceTimeoutTimer()
        } catch {
            print("❌ [QuickTasks] Recording failed: \(error)")
            isListening = false
            if shouldPlayTTS(isResultFeedback: true) {  // 结果反馈
                ttsService.speak("录音失败，请重试")
            }
        }
    }

    /// 启动静音超时定时器
    private func startSilenceTimeoutTimer() {
        // 清除之前的定时器
        wakeWordDetectionTimer?.invalidate()
        wakeWordDetectionTimer = nil

        // 设置新的定时器
        wakeWordDetectionTimer = Timer.scheduledTimer(withTimeInterval: silenceTimeout, repeats: false) { [weak self] _ in
            Task { @MainActor in
                print("⏰ [QuickTasks] Silence timeout detected, stopping recording")
                await self?.stopRecordingAndSend()
            }
        }
    }

    /// 停止录音并发送
    func stopRecordingAndSend() async {
        // 清除定时器
        wakeWordDetectionTimer?.invalidate()
        wakeWordDetectionTimer = nil

        guard isListening, let recorder = audioRecorder else {
            print("⚠️ [QuickTasks] Not recording")
            return
        }

        recorder.stop()
        audioRecorder = nil

        isListening = false

        let audioFileURL = getDocumentsDirectory().appendingPathComponent("quick_tasks_recording.m4a")

        // 检查录音文件是否为空
        guard FileManager.default.fileExists(atPath: audioFileURL.path),
              let audioData = try? Data(contentsOf: audioFileURL),
              !audioData.isEmpty else {
            print("⚠️ [QuickTasks] Recording file is empty")
            if shouldPlayTTS(isResultFeedback: true) {  // 结果反馈
                ttsService.speak("没有检测到声音，请重试")
            }
            return
        }

        do {
            // 发送语音消息
            let response = try await quickTasksService.sendVoiceMessage(
                voiceFileData: audioData,
                userId: userId,
                vin: vin
            )

            lastResult = response
            print("✅ [QuickTasks] Voice message sent successfully: \(response)")

            // 播放结果 - 这是结果反馈
            if shouldPlayTTS(isResultFeedback: true) {
                ttsService.speak(response)
            }

            // 删除临时录音文件
            try? FileManager.default.removeItem(at: audioFileURL)

        } catch let error as QuickTasksError {
            errorMessage = error.localizedDescription
            print("❌ [QuickTasks] Send voice error: \(error)")

            // 根据错误类型提供不同的语音反馈
            let errorMessageText = getSpokenErrorMessage(error: error)
            if shouldPlayTTS(isResultFeedback: true) {  // 结果反馈
                ttsService.speak(errorMessageText)
            }

            // 删除临时录音文件
            try? FileManager.default.removeItem(at: audioFileURL)
        } catch {
            errorMessage = error.localizedDescription
            print("❌ [QuickTasks] Send voice error: \(error)")
            if shouldPlayTTS(isResultFeedback: true) {  // 结果反馈
                ttsService.speak("服务暂时不可用，请稍后再试")
            }

            // 删除临时录音文件
            try? FileManager.default.removeItem(at: audioFileURL)
        }
    }

    /// 发送文本消息
    func sendTextMessage(text: String) async {
        guard !isProcessing else {
            print("⚠️ [QuickTasks] Already processing")
            return
        }

        isProcessing = true
        errorMessage = nil

        do {
            let response = try await quickTasksService.sendMessage(
                query: text,
                userId: userId,
                vin: vin
            )

            lastResult = response
            print("✅ [QuickTasks] Text message sent successfully: \(response)")

            // 播放结果 - 这是结果反馈
            if shouldPlayTTS(isResultFeedback: true) {
                ttsService.speak(response)
            }

        } catch let error as QuickTasksError {
            errorMessage = error.localizedDescription
            print("❌ [QuickTasks] Send text error: \(error)")

            // 根据错误类型提供不同的语音反馈
            let errorMessageText = getSpokenErrorMessage(error: error)
            if shouldPlayTTS(isResultFeedback: true) {  // 结果反馈
                ttsService.speak(errorMessageText)
            }
        } catch {
            errorMessage = error.localizedDescription
            print("❌ [QuickTasks] Send text error: \(error)")
            if shouldPlayTTS(isResultFeedback: true) {  // 结果反馈
                ttsService.speak("服务暂时不可用，请稍后再试")
            }
        }

        isProcessing = false
    }

    /// 获取语音错误消息
    private func getSpokenErrorMessage(error: QuickTasksError) -> String {
        switch error {
        case .apiError(_, let message):
            // 检查是否包含中文字符，如果是则直接返回
            if message.contains("暂不支持") || message.contains("试试换个说法") {
                return message
            } else if message.lowercased().contains("network") || message.contains("connection") || message.contains("网络连接失败") {
                return "网络连接失败，请检查网络后重试"
            } else if message.contains("超时") || message.contains("timeout") {
                return "请求超时，请重试"
            } else {
                return "服务暂时不可用，请稍后再试"
            }
        case .invalidURL:
            return "服务器地址错误，请联系管理员"
        case .noActiveSession:
            return "会话已失效，请重新开始"
        case .sessionCreationFailed:
            return "会话创建失败，请重试"
        case .messageFailed:
            return "消息发送失败，请重试"
        case .invalidResponse:
            return "服务返回无效响应，请重试"
        case .networkError(let message):
            if message.contains("网络连接失败") {
                return "网络连接失败，请检查网络后重试"
            } else {
                return message
            }
        }
    }

    /// 获取文档目录
    private func getDocumentsDirectory() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    /// 检查是否有活跃会话
    var hasActiveSession: Bool {
        quickTasksService.sessionId != nil
    }

    /// 清除会话
    func clearSession() {
        quickTasksService.sessionId = nil
    }

    /// 更新API密钥后重新设置服务
    func updateAPIKeyIfNeeded() {
        if let apiKey = APIKeyManager.shared.getAPIKey(), !apiKey.isEmpty {
            if omnirealtimeService == nil {
                setupOmniRealtimeService()
            }
        }
    }

    /// 更新静音超时设置
    func updateSilenceTimeout(_ newTimeout: TimeInterval) {
        silenceTimeout = newTimeout
        UserDefaults.standard.set(newTimeout, forKey: "quick_tasks_silence_timeout")
        print("⏱️ [QuickTasks] Silence timeout updated to \(newTimeout)s")
    }
}

// MARK: - Notification Name

extension Notification.Name {
    static let quickVisionTriggered = Notification.Name("quickVisionTriggered")
}

// MARK: - Quick Vision Manager

@MainActor
class QuickVisionManager: ObservableObject {
    static let shared = QuickVisionManager()

    @Published var isProcessing = false
    @Published var lastResult: String?
    @Published var errorMessage: String?
    @Published var lastImage: UIImage?
    @Published var lastMode: QuickVisionMode = .standard

    // 公开 streamViewModel 用于 Intent 检查初始化状态
    private(set) var streamViewModel: StreamSessionViewModel?
    private let tts = TTSService.shared

    private init() {
        // 监听 Intent 触发
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleQuickVisionTrigger(_:)),
            name: .quickVisionTriggered,
            object: nil
        )
    }

    /// 设置 StreamSessionViewModel 引用
    func setStreamViewModel(_ viewModel: StreamSessionViewModel) {
        self.streamViewModel = viewModel
    }

    @objc private func handleQuickVisionTrigger(_ notification: Notification) {
        let customPrompt = notification.userInfo?["customPrompt"] as? String
        let modeString = notification.userInfo?["mode"] as? String
        let mode = modeString.flatMap { QuickVisionMode(rawValue: $0) } ?? .standard

        Task { @MainActor in
            await performQuickVisionWithMode(mode, customPrompt: customPrompt)
        }
    }

    /// 使用指定模式执行快速识图
    func performQuickVisionWithMode(_ mode: QuickVisionMode, customPrompt: String? = nil) async {
        guard !isProcessing else {
            print("⚠️ [QuickVision] Already processing")
            return
        }

        guard let streamViewModel = streamViewModel else {
            print("❌ [QuickVision] StreamViewModel not set")
            tts.speak("识图功能未初始化，请先打开应用")
            return
        }

        isProcessing = true
        errorMessage = nil
        lastResult = nil
        lastImage = nil
        lastMode = mode

        // 获取 API Key
        guard let apiKey = APIKeyManager.shared.getAPIKey(), !apiKey.isEmpty else {
            errorMessage = "请先在设置中配置 API Key"
            tts.speak("请先在设置中配置 API Key")
            isProcessing = false
            return
        }

        // 播报开始
        tts.speak("正在识别", apiKey: apiKey)

        // 获取提示词
        let prompt = customPrompt ?? QuickVisionModeManager.shared.getPrompt(for: mode)

        do {
            // 0. 检查设备是否已连接
            if !streamViewModel.hasActiveDevice {
                print("❌ [QuickVision] No active device connected")
                throw QuickVisionError.noDevice
            }

            // 1. 启动视频流（如果未启动）
            if streamViewModel.streamingStatus != .streaming {
                print("📹 [QuickVision] Starting stream...")
                await streamViewModel.handleStartStreaming()

                // 等待流进入 streaming 状态（最多 5 秒）
                var streamWait = 0
                while streamViewModel.streamingStatus != .streaming && streamWait < 50 {
                    try await Task.sleep(nanoseconds: 100_000_000) // 0.1秒
                    streamWait += 1
                }

                if streamViewModel.streamingStatus != .streaming {
                    print("❌ [QuickVision] Failed to start streaming")
                    throw QuickVisionError.streamNotReady
                }
            }

            // 2. 等待流稳定
            try await Task.sleep(nanoseconds: 500_000_000) // 0.5秒

            // 3. 清除之前的照片，然后拍照
            streamViewModel.dismissPhotoPreview()
            print("📸 [QuickVision] Capturing photo...")
            streamViewModel.capturePhoto()

            // 4. 等待照片捕获完成（最多 3 秒）
            var photoWait = 0
            while streamViewModel.capturedPhoto == nil && photoWait < 30 {
                try await Task.sleep(nanoseconds: 100_000_000) // 0.1秒
                photoWait += 1
            }

            // 如果 SDK capturePhoto 失败，使用当前视频帧作为备选
            let photo: UIImage
            if let capturedPhoto = streamViewModel.capturedPhoto {
                photo = capturedPhoto
                print("📸 [QuickVision] Using SDK captured photo")
            } else if let videoFrame = streamViewModel.currentVideoFrame {
                photo = videoFrame
                print("📸 [QuickVision] SDK capturePhoto failed, using video frame as fallback")
            } else {
                print("❌ [QuickVision] No photo or video frame available")
                throw QuickVisionError.frameTimeout
            }

            print("📸 [QuickVision] Photo captured: \(photo.size.width)x\(photo.size.height)")

            // 保存图片用于历史记录
            lastImage = photo

            // 5. 预配置 TTS 音频会话
            tts.prepareAudioSession()

            // 6. 立即停止视频流
            print("🛑 [QuickVision] Stopping stream after capture")
            await streamViewModel.stopSession()

            // 7. 调用识图 API
            let service = QuickVisionService(apiKey: apiKey)
            let result = try await service.analyzeImage(photo, customPrompt: prompt)

            // 8. 保存结果
            lastResult = result

            // 9. 保存到历史记录
            saveToHistory(mode: mode, prompt: prompt, result: result, image: photo)

            // 10. TTS 播报结果
            tts.speak(result, apiKey: apiKey)

            print("✅ [QuickVision] Complete: \(result)")

        } catch let error as QuickVisionError {
            errorMessage = error.localizedDescription
            print("❌ [QuickVision] QuickVisionError: \(error)")
            tts.speak(error.localizedDescription, apiKey: apiKey)
            await streamViewModel.stopSession()
        } catch {
            errorMessage = error.localizedDescription
            print("❌ [QuickVision] Error: \(error)")
            tts.speak("识别失败，\(error.localizedDescription)", apiKey: apiKey)
            await streamViewModel.stopSession()
        }

        isProcessing = false
    }

    /// 执行快速识图（使用当前设置的模式）
    func performQuickVision(customPrompt: String? = nil) async {
        await performQuickVisionWithMode(QuickVisionModeManager.staticCurrentMode, customPrompt: customPrompt)
    }

    /// 执行快速识图（从快捷指令/Siri 触发）
    func performQuickVisionFromIntent(customPrompt: String? = nil) async {
        await performQuickVision(customPrompt: customPrompt)
    }

    /// 保存识图结果到历史记录
    private func saveToHistory(mode: QuickVisionMode, prompt: String, result: String, image: UIImage) {
        let record = QuickVisionRecord(
            mode: mode,
            prompt: prompt,
            result: result,
            thumbnail: image
        )
        QuickVisionStorage.shared.saveRecord(record)
        print("💾 [QuickVision] Record saved to history")
    }

    /// 停止视频流（在页面关闭时调用）
    func stopStream() async {
        await streamViewModel?.stopSession()
    }

    /// 手动触发快速识图（从 UI 调用）
    func triggerQuickVision(customPrompt: String? = nil) {
        Task { @MainActor in
            await performQuickVision(customPrompt: customPrompt)
        }
    }

    /// 手动触发指定模式的快速识图（从 UI 调用）
    func triggerQuickVisionWithMode(_ mode: QuickVisionMode) {
        Task { @MainActor in
            await performQuickVisionWithMode(mode)
        }
    }
}
