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

        if let result = manager.lastResult {
            return .result(dialog: "最近创建的任务：\(result)")
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

    // Service
    private let quickTasksService = QuickTasksService()
    private let ttsService = TTSService.shared

    // Audio recording
    var audioRecorder: AVAudioRecorder?
    private var recordingSession: AVAudioSession!

    // Configuration - Load from UserDefaults or use defaults
    private var userId: String {
        UserDefaults.standard.string(forKey: "quick_tasks_user_id") ?? "user_\(UIDevice.current.identifierForVendor?.uuidString.prefix(8) ?? UUID().uuidString.prefix(8))"
    }

    private var vin: String {
        UserDefaults.standard.string(forKey: "quick_tasks_vin") ?? "default_vin_\(UUID().uuidString.prefix(8))"
    }

    private init() {
        setupAudioSession()
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
                ttsService.speak("请说出您的快捷任务指令")
            } else {
                print("❌ [QuickTasks] Failed to start session")
                errorMessage = "会话启动失败"
                ttsService.speak("会话启动失败，请重试")
            }
        } catch let error as QuickTasksError {
            errorMessage = error.localizedDescription
            print("❌ [QuickTasks] Start session error: \(error)")
            ttsService.speak(error.localizedDescription)
        } catch {
            errorMessage = error.localizedDescription
            print("❌ [QuickTasks] Start session error: \(error)")
            ttsService.speak("服务暂时不可用，请稍后再试")
        }

        isProcessing = false
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
        } catch {
            print("❌ [QuickTasks] Recording failed: \(error)")
            isListening = false
            ttsService.speak("录音失败，请重试")
        }
    }

    /// 停止录音并发送
    func stopRecordingAndSend() async {
        guard isListening, let recorder = audioRecorder else {
            print("⚠️ [QuickTasks] Not recording")
            return
        }

        recorder.stop()
        audioRecorder = nil

        isListening = false

        let audioFileURL = getDocumentsDirectory().appendingPathComponent("quick_tasks_recording.m4a")

        do {
            let audioData = try Data(contentsOf: audioFileURL)

            // 发送语音消息
            let response = try await quickTasksService.sendVoiceMessage(
                voiceFileData: audioData,
                userId: userId,
                vin: vin
            )

            lastResult = response
            print("✅ [QuickTasks] Voice message sent successfully: \(response)")

            // 播放结果
            ttsService.speak(response)

            // 删除临时录音文件
            try? FileManager.default.removeItem(at: audioFileURL)

        } catch let error as QuickTasksError {
            errorMessage = error.localizedDescription
            print("❌ [QuickTasks] Send voice error: \(error)")

            // 根据错误类型提供不同的语音反馈
            let errorMessageText = getSpokenErrorMessage(error: error)
            ttsService.speak(errorMessageText)

            // 删除临时录音文件
            try? FileManager.default.removeItem(at: audioFileURL)
        } catch {
            errorMessage = error.localizedDescription
            print("❌ [QuickTasks] Send voice error: \(error)")
            ttsService.speak("服务暂时不可用，请稍后再试")

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

            // 播放结果
            ttsService.speak(response)

        } catch let error as QuickTasksError {
            errorMessage = error.localizedDescription
            print("❌ [QuickTasks] Send text error: \(error)")

            // 根据错误类型提供不同的语音反馈
            let errorMessageText = getSpokenErrorMessage(error: error)
            ttsService.speak(errorMessageText)
        } catch {
            errorMessage = error.localizedDescription
            print("❌ [QuickTasks] Send text error: \(error)")
            ttsService.speak("服务暂时不可用，请稍后再试")
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
