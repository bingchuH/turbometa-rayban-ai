/*
 * Qwen-Omni-Realtime WebSocket Service
 * Provides real-time audio and video chat with AI
 */

import Foundation
import UIKit
import AVFoundation

// MARK: - WebSocket Events

enum OmniClientEvent: String {
    case sessionUpdate = "session.update"
    case inputAudioBufferAppend = "input_audio_buffer.append"
    case inputAudioBufferCommit = "input_audio_buffer.commit"
    case inputImageBufferAppend = "input_image_buffer.append"
    case responseCreate = "response.create"
}

enum OmniServerEvent: String {
    case sessionCreated = "session.created"
    case sessionUpdated = "session.updated"
    case inputAudioBufferSpeechStarted = "input_audio_buffer.speech_started"
    case inputAudioBufferSpeechStopped = "input_audio_buffer.speech_stopped"
    case inputAudioBufferCommitted = "input_audio_buffer.committed"
    case responseCreated = "response.created"
    case responseAudioTranscriptDelta = "response.audio_transcript.delta"
    case responseAudioTranscriptDone = "response.audio_transcript.done"
    case responseAudioDelta = "response.audio.delta"
    case responseAudioDone = "response.audio.done"
    case responseDone = "response.done"
    case conversationItemCreated = "conversation.item.created"
    case conversationItemInputAudioTranscriptionCompleted = "conversation.item.input_audio_transcription.completed"
    case error = "error"
}

// MARK: - Service Class

class OmniRealtimeService: NSObject {

    // WebSocket
    private var webSocket: URLSessionWebSocketTask?
    private var urlSession: URLSession?

    // Configuration
    private let apiKey: String
    private let model = "qwen3-omni-flash-realtime-2025-12-01"
    // 根据用户设置的区域动态获取 WebSocket URL（北京/新加坡）
    private var baseURL: String {
        return APIProviderManager.staticLiveAIWebsocketURL
    }

    // Audio Engine (for recording)
    private var audioEngine: AVAudioEngine?

    // Audio Playback Engine (separate engine for playback)
    private var playbackEngine: AVAudioEngine?
    private var playerNode: AVAudioPlayerNode?
    // 使用 Float32 标准格式，兼容 iOS 18
    private let playbackFormat = AVAudioFormat(standardFormatWithSampleRate: 24000, channels: 1)

    // Audio buffer management
    private var audioBuffer = Data()
    private var isCollectingAudio = false
    private var audioChunkCount = 0
    private let minChunksBeforePlay = 2 // 首次收到2个片段后开始播放
    private var hasStartedPlaying = false
    private var isPlaybackEngineRunning = false

    // Callbacks
    var onTranscriptDelta: ((String) -> Void)?
    var onTranscriptDone: ((String) -> Void)?
    var onUserTranscript: ((String) -> Void)? // 用户语音识别结果
    var onQuickTaskTranscript: ((String) -> Void)? // 快捷任务语音识别结果
    var onAssistantText: ((String) -> Void)? // AI助手文本回复
    var onAudioDelta: ((Data) -> Void)?
    var onAudioDone: (() -> Void)?
    var onSpeechStarted: (() -> Void)?
    var onSpeechStopped: (() -> Void)?
    var onError: ((String) -> Void)?
    var onConnected: (() -> Void)?
    var onFirstAudioSent: (() -> Void)?

    // State
    private var isRecording = false
    private var hasAudioBeenSent = false
    private var eventIdCounter = 0

    // Quick task detection support
    private var aiResponseBuffer = ""
    private var aiResponseStartTime: TimeInterval = 0
    private let quickTaskTimeout: TimeInterval = 2.0 // 2秒内检查是否为快捷任务
    private var shouldMuteAudioResponses = false // 是否静音音频回复

    // Flag to indicate if we're in direct streaming mode (no wake word)
    private var isDirectStreamingMode = false

    init(apiKey: String, isDirectStreaming: Bool = false) {
        self.apiKey = apiKey
        self.isDirectStreamingMode = isDirectStreaming
        super.init()
        setupAudioEngine()
    }

    // MARK: - Audio Engine Setup

    private func setupAudioEngine() {
        // Recording engine
        audioEngine = AVAudioEngine()

        // Playback engine (separate from recording)
        setupPlaybackEngine()
    }

    private func setupPlaybackEngine() {
        playbackEngine = AVAudioEngine()
        playerNode = AVAudioPlayerNode()

        guard let playbackEngine = playbackEngine,
              let playerNode = playerNode,
              let playbackFormat = playbackFormat else {
            print("❌ [Omni] 无法初始化播放引擎")
            return
        }

        // Attach player node
        playbackEngine.attach(playerNode)

        // Connect player node to output with explicit format
        playbackEngine.connect(playerNode, to: playbackEngine.mainMixerNode, format: playbackFormat)
        playbackEngine.prepare()

        print("✅ [Omni] 播放引擎初始化完成: Float32 @ 24kHz")
    }

    private func startPlaybackEngine() {
        guard let playbackEngine = playbackEngine, !isPlaybackEngineRunning else { return }

        do {
            try playbackEngine.start()
            isPlaybackEngineRunning = true
            print("▶️ [Omni] 播放引擎已启动")
        } catch {
            print("❌ [Omni] 播放引擎启动失败: \(error)")
        }
    }

    private func stopPlaybackEngine() {
        guard let playbackEngine = playbackEngine, isPlaybackEngineRunning else { return }

        // 重要：先重置 playerNode 以清除所有已调度但未播放的 buffer
        playerNode?.stop()
        playerNode?.reset()  // 清除队列中的所有 buffer
        playbackEngine.stop()
        isPlaybackEngineRunning = false
        print("⏹️ [Omni] 播放引擎已停止并清除队列")
    }

    // MARK: - WebSocket Connection

    func connect() {
        let urlString = "\(baseURL)?model=\(model)"
        print("🔌 [Omni] 准备连接 WebSocket: \(urlString)")

        guard let url = URL(string: urlString) else {
            print("❌ [Omni] 无效的 URL")
            onError?("Invalid URL")
            return
        }

        var request = URLRequest(url: url)
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")

        let configuration = URLSessionConfiguration.default
        urlSession = URLSession(configuration: configuration, delegate: self, delegateQueue: OperationQueue())

        webSocket = urlSession?.webSocketTask(with: request)
        webSocket?.resume()

        print("🔌 [Omni] WebSocket 任务已启动")
        receiveMessage()

        // Wait a bit then send session configuration
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            print("⚙️ [Omni] 准备配置会话")
            self.configureSession()
        }
    }

    func disconnect() {
        print("🔌 [Omni] 断开 WebSocket 连接")
        webSocket?.cancel(with: .goingAway, reason: nil)
        webSocket = nil
        stopRecording()
        stopPlaybackEngine()
    }

    // MARK: - Session Configuration

    private func configureSession() {
        // 根据当前语言设置获取语音和提示词
        let voice = LanguageManager.staticTtsVoice

        // Determine the instructions based on mode
        let instructions: String
        if isDirectStreamingMode {
            // Arbitration mode: Determine if query is related to quick tasks or general conversation
            // instructions = """
            // 你是一个AI助手，用于判断用户的查询是否与快速任务（车辆自动化）相关，以及是否需要视觉输入。
            // 如果查询与车辆自动化、汽车功能、驾驶辅助或汽车控制相关：
            // - 如果查询涉及视觉元素（例如：“看一下这个位置，一会上车的时候导航去这里”、“调整我指向的座椅”、“打开我看到的灯”、“播放我面前的播放列表”、“导航到屏幕上的位置”），请回复：{"query": "实际的查询文本内容", "need_photo": true}
            // - 如果查询是基于文本的（例如：“当我到家时，播放音乐”、“我坐上座位后启动汽车”、“将温度设置为24度”），请回复：{"query": "实际的查询文本内容"}
            // 如果查询是与快速任务无关的普通对话，请回复：{"query": "off"}
            // 不要在JSON响应前后添加任何其他文本。
            // """
            instructions = """
            你是一个AI助手，用于判断用户的查询是否与快捷任务（车辆自动化）相关，以及是否需要视觉输入。
            如果查询是与车辆无关的普通对话，请回复：{"query": "off"}
            如果查询与车辆自动化、汽车功能、驾驶辅助或汽车控制相关：
            - 如果用户话术中涉及指代词比如 这/那/这些/那些/这个/那个等，（例如："这个音乐不错，上车的时候播放一下"、"导航到这个位置"），而缺乏具体的指代对象，请回复：{"query": "实际的查询文本内容", "need_photo": true}
            - 如果查询是仅基于文本的（例如："当我到家时，播放音乐"、"我坐上座位后启动汽车"、"将温度设置为24度"），请回复：{"query": "实际的查询文本内容", "need_photo": false}
            不要在JSON响应前后添加任何其他文本。
            """

        } else {
            instructions = LiveAIModeManager.staticSystemPrompt
        }

        let sessionConfig: [String: Any] = [
            "event_id": generateEventId(),
            "type": OmniClientEvent.sessionUpdate.rawValue,
            "session": [
                "modalities": ["text", "audio"],
                "voice": voice,
                "input_audio_format": "pcm16",
                "output_audio_format": "pcm24",
                "instructions": instructions,
                "turn_detection": [
                    "type": "server_vad",
                    "threshold": 0.5,
                    "silence_duration_ms": 800
                ],
                // Configure response behavior for better quick task detection
                "temperature": 0.7,
                "max_response_output_tokens": 4096
            ]
        ]

        sendEvent(sessionConfig)
    }

    // MARK: - Audio Recording

    func startRecording() {
        guard !isRecording else {
            return
        }

        do {
            print("🎤 [Omni] 开始录音")

            // Stop engine if already running and remove any existing taps
            if let engine = audioEngine, engine.isRunning {
                engine.stop()
                engine.inputNode.removeTap(onBus: 0)
            }

            let audioSession = AVAudioSession.sharedInstance()

            // Allow Bluetooth to use the glasses' microphone
            try audioSession.setCategory(.playAndRecord, mode: .voiceChat, options: [.allowBluetooth, .allowBluetoothA2DP])
            try audioSession.setActive(true)

            guard let engine = audioEngine else {
                print("❌ [Omni] 音频引擎未初始化")
                return
            }

            let inputNode = engine.inputNode
            let inputFormat = inputNode.outputFormat(forBus: 0)

            // Convert to PCM16 24kHz mono
            inputNode.installTap(onBus: 0, bufferSize: 4096, format: inputFormat) { [weak self] buffer, time in
                self?.processAudioBuffer(buffer)
            }

            engine.prepare()
            try engine.start()

            isRecording = true
            print("✅ [Omni] 录音已启动")

        } catch {
            print("❌ [Omni] 启动录音失败: \(error.localizedDescription)")
            onError?("Failed to start recording: \(error.localizedDescription)")
        }
    }

    func stopRecording() {
        guard isRecording else {
            return
        }

        print("🛑 [Omni] 停止录音")
        audioEngine?.inputNode.removeTap(onBus: 0)
        audioEngine?.stop()
        isRecording = false
        hasAudioBeenSent = false
    }

    private func processAudioBuffer(_ buffer: AVAudioPCMBuffer) {
        // Convert Float32 audio to PCM16 format
        guard let floatChannelData = buffer.floatChannelData else {
            return
        }

        let frameLength = Int(buffer.frameLength)
        let channel = floatChannelData.pointee

        // Convert Float32 (-1.0 to 1.0) to Int16 (-32768 to 32767)
        var int16Data = [Int16](repeating: 0, count: frameLength)
        for i in 0..<frameLength {
            let sample = channel[i]
            let clampedSample = max(-1.0, min(1.0, sample))
            int16Data[i] = Int16(clampedSample * 32767.0)
        }

        let data = Data(bytes: int16Data, count: frameLength * MemoryLayout<Int16>.size)
        let base64Audio = data.base64EncodedString()

        sendAudioAppend(base64Audio)

        // 通知第一次音频已发送
        if !hasAudioBeenSent {
            hasAudioBeenSent = true
            print("✅ [Omni] 第一次音频已发送，启用语音触发模式")
            DispatchQueue.main.async { [weak self] in
                self?.onFirstAudioSent?()
            }
        }
    }

    // MARK: - Send Events

    private func sendEvent(_ event: [String: Any]) {
        guard let jsonData = try? JSONSerialization.data(withJSONObject: event),
              let jsonString = String(data: jsonData, encoding: .utf8) else {
            print("❌ [Omni] 无法序列化事件")
            return
        }

        let message = URLSessionWebSocketTask.Message.string(jsonString)
        webSocket?.send(message) { error in
            if let error = error {
                print("❌ [Omni] 发送事件失败: \(error.localizedDescription)")
                self.onError?("Send error: \(error.localizedDescription)")
            }
        }
    }

    func sendAudioAppend(_ base64Audio: String) {
        let event: [String: Any] = [
            "event_id": generateEventId(),
            "type": OmniClientEvent.inputAudioBufferAppend.rawValue,
            "audio": base64Audio
        ]
        sendEvent(event)
    }

    func sendImageAppend(_ image: UIImage) {
        guard let imageData = image.jpegData(compressionQuality: 0.6) else {
            print("❌ [Omni] 无法压缩图片")
            return
        }
        let base64Image = imageData.base64EncodedString()

        print("📸 [Omni] 发送图片: \(imageData.count) bytes")

        let event: [String: Any] = [
            "event_id": generateEventId(),
            "type": OmniClientEvent.inputImageBufferAppend.rawValue,
            "image": base64Image
        ]
        sendEvent(event)
    }

    func commitAudioBuffer() {
        let event: [String: Any] = [
            "event_id": generateEventId(),
            "type": OmniClientEvent.inputAudioBufferCommit.rawValue
        ]
        sendEvent(event)
    }

    // MARK: - Receive Messages

    private func receiveMessage() {
        webSocket?.receive { [weak self] result in
            switch result {
            case .success(let message):
                self?.handleMessage(message)
                self?.receiveMessage() // Continue receiving

            case .failure(let error):
                print("❌ [Omni] 接收消息失败: \(error.localizedDescription)")
                self?.onError?("Receive error: \(error.localizedDescription)")
            }
        }
    }

    private func handleMessage(_ message: URLSessionWebSocketTask.Message) {
        switch message {
        case .string(let text):
            handleServerEvent(text)
        case .data(let data):
            if let text = String(data: data, encoding: .utf8) {
                handleServerEvent(text)
            }
        @unknown default:
            break
        }
    }

    private func handleServerEvent(_ jsonString: String) {
        guard let data = jsonString.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let type = json["type"] as? String else {
            return
        }

        DispatchQueue.main.async {
            switch type {
            case OmniServerEvent.sessionCreated.rawValue,
                 OmniServerEvent.sessionUpdated.rawValue:
                print("✅ [Omni] 会话已建立")
                self.onConnected?()

            case OmniServerEvent.inputAudioBufferSpeechStarted.rawValue:
                print("🎤 [Omni] 检测到语音开始")
                self.onSpeechStarted?()

            case OmniServerEvent.inputAudioBufferSpeechStopped.rawValue:
                print("🛑 [Omni] 检测到语音停止")
                self.onSpeechStopped?()

            case OmniServerEvent.responseAudioTranscriptDelta.rawValue:
                if let delta = json["delta"] as? String {
                    print("💬 [Omni] AI回复片段: \(delta)")

                    // Accumulate AI response to detect quick tasks
                    self.aiResponseBuffer += delta

                    // Check if the accumulated buffer contains a complete quick task JSON
                    if self.tryDetectQuickTaskFromBuffer() {
                        // Clear buffer after processing quick task
                        self.aiResponseBuffer = ""
                        // Do NOT forward the delta to avoid playing JSON as speech
                        // The JSON was processed internally and shouldn't be spoken
                    } else {
                        // Forward regular text delta
                        self.onTranscriptDelta?(delta)
                        // Also forward to assistant text callback if needed
                        self.onAssistantText?(delta)
                    }
                }

            case OmniServerEvent.responseAudioTranscriptDone.rawValue:
                let text = json["text"] as? String ?? ""
                if text.isEmpty {
                    print("⚠️ [Omni] AI回复完成但done事件无text字段（使用累积的delta）")
                } else {
                    print("✅ [Omni] AI完整回复: \(text)")
                }
                // 总是调用回调，即使text为空，让ViewModel使用累积的片段
                self.onTranscriptDone?(text)

            case OmniServerEvent.responseAudioDelta.rawValue:
                if let base64Audio = json["delta"] as? String,
                   let audioData = Data(base64Encoded: base64Audio) {
                    self.onAudioDelta?(audioData)

                    // Buffer audio chunks
                    if !self.isCollectingAudio {
                        self.isCollectingAudio = true
                        self.audioBuffer = Data()
                        self.audioChunkCount = 0
                        self.hasStartedPlaying = false

                        // 清除 playerNode 队列中可能残留的旧 buffer
                        if self.isPlaybackEngineRunning {
                            // 重要：reset 会断开 playerNode，需要完全重新初始化
                            self.stopPlaybackEngine()
                            self.setupPlaybackEngine()
                            self.startPlaybackEngine()
                            self.playerNode?.play()
                            print("🔄 [Omni] 重新初始化播放引擎")
                        }
                    }

                    self.audioChunkCount += 1

                    // 流式播放策略：收集少量片段后开始流式调度
                    if !self.hasStartedPlaying {
                        // 首次播放前：先收集
                        self.audioBuffer.append(audioData)

                        if self.audioChunkCount >= self.minChunksBeforePlay {
                            // 已收集足够片段，开始播放
                            self.hasStartedPlaying = true
                            self.playAudio(self.audioBuffer)
                            self.audioBuffer = Data()
                        }
                    } else {
                        // 已开始播放：直接调度每个片段，AVAudioPlayerNode 会自动排队
                        self.playAudio(audioData)
                    }
                }

            case OmniServerEvent.responseAudioDone.rawValue:
                self.isCollectingAudio = false

                // Play remaining buffered audio (if any)
                if !self.audioBuffer.isEmpty {
                    self.playAudio(self.audioBuffer)
                    self.audioBuffer = Data()
                }

                self.audioChunkCount = 0
                self.hasStartedPlaying = false
                self.onAudioDone?()

            case OmniServerEvent.conversationItemInputAudioTranscriptionCompleted.rawValue:
                // 用户语音识别完成
                if let transcript = json["transcript"] as? String {
                    print("👤 [Omni] 用户说: \(transcript)")

                    // 判断是否为快捷任务，如果 transcript 中包含特定 JSON 结构，则认为是快捷任务
                    if transcript.trimmingCharacters(in: .whitespaces).hasPrefix("{") && transcript.trimmingCharacters(in: .whitespaces).hasSuffix("}") {
                        // 尝试解析 JSON 来看是否是 {query: "..."} 格式
                        if let jsonData = transcript.data(using: .utf8),
                           let jsonObject = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
                           let queryValue = jsonObject["query"] as? String {
                            print("⚡ [Omni] 检测到快捷任务命令: \(queryValue)")
                            self.onQuickTaskTranscript?(queryValue)
                        } else {
                            print("💬 [Omni] 一般对话命令")
                            self.onUserTranscript?(transcript)
                        }
                    } else {
                        // 直接发送用户转录文本，由接收方判断是否为快捷任务
                        print("💬 [Omni] 一般对话命令")
                        self.onUserTranscript?(transcript)
                    }
                }

            case OmniServerEvent.conversationItemCreated.rawValue:
                // 可能包含其他类型的会话项
                break

            case OmniServerEvent.error.rawValue:
                if let error = json["error"] as? [String: Any],
                   let message = error["message"] as? String {
                    print("❌ [Omni] 服务器错误: \(message)")
                    self.onError?(message)
                }

            default:
                break
            }
        }
    }

    // MARK: - Quick Task Detection

    private func tryDetectQuickTaskFromBuffer() -> Bool {
        let buffer = self.aiResponseBuffer.trimmingCharacters(in: .whitespacesAndNewlines)

        // Check if buffer looks like it's starting a JSON object
        if buffer.hasPrefix("{") {
            // Try to find a complete JSON object by looking for matching braces
            if let completeJson = extractCompleteJson(from: buffer) {
                if let jsonData = completeJson.data(using: .utf8),
                   let jsonObject = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
                   let queryValue = jsonObject["query"] as? String {

                    if queryValue == "off" {
                        print("⏭️ [Omni] Query is off, skipping TTS and quick task processing")
                        // Mute audio responses to skip TTS for general conversation
                        self.shouldMuteAudioResponses = true
                        // Clear the buffer after processing
                        self.aiResponseBuffer = ""
                        return true
                    } else {
                        // Check if need_photo field exists and is true
                        if let needPhoto = jsonObject["need_photo"] as? Bool, needPhoto == true {
                            print("📸 [Omni] 检测到视觉增强快捷任务命令: \(queryValue), 需要拍照")
                            // Send the complete JSON object to onUserTranscript to maintain consistency with direct streaming logic
                            self.onUserTranscript?(completeJson)

                            // For visual tasks, keep audio muted during photo capture and processing
                            self.shouldMuteAudioResponses = true
                        } else {
                            print("⚡ [Omni] 检测到快捷任务命令: \(queryValue)")
                            // Send the complete JSON object to onUserTranscript so QuickTasksManager can distinguish
                            // between general conversation and quick tasks based on the need_photo field
                            self.onUserTranscript?(completeJson)

                            // For non-visual tasks, we should also keep audio muted during backend processing
                            // but audio will be unmuted after task is sent as handled by QuickTasksManager
                            self.shouldMuteAudioResponses = true
                        }

                        // Clear the buffer after processing
                        self.aiResponseBuffer = ""
                        return true
                    }
                }
            }
        }
        return false
    }

    private func extractCompleteJson(from text: String) -> String? {
        var braceCount = 0
        var startIndex = text.startIndex

        // Find opening brace
        while startIndex < text.endIndex {
            if text[startIndex] == "{" {
                break
            }
            startIndex = text.index(after: startIndex)
        }

        // If no opening brace, return nil
        if startIndex == text.endIndex {
            return nil
        }

        var currentIndex = startIndex

        // Count braces to find the matching closing brace
        while currentIndex < text.endIndex {
            if text[currentIndex] == "{" {
                braceCount += 1
            } else if text[currentIndex] == "}" {
                braceCount -= 1
                if braceCount == 0 {
                    // Found matching closing brace
                    let endIndex = text.index(after: currentIndex)
                    return String(text[startIndex..<endIndex])
                }
            }
            currentIndex = text.index(after: currentIndex)
        }

        // Didn't find a complete JSON object
        return nil
    }

    // MARK: - Audio Playback (AVAudioEngine + AVAudioPlayerNode)

    private func playAudio(_ audioData: Data) {
        // Check if audio responses should be muted (during quick task processing)
        if shouldMuteAudioResponses {
            print("🔇 [Omni] 音频回复已静音（快捷任务模式）")
            return
        }

        guard let playerNode = playerNode,
              let playbackFormat = playbackFormat else {
            return
        }

        // Start playback engine if not running
        if !isPlaybackEngineRunning {
            startPlaybackEngine()
            playerNode.play()
        } else {
            // 确保 playerNode 在运行
            if !playerNode.isPlaying {
                playerNode.play()
            }
        }

        // Convert PCM16 Data to Float32 AVAudioPCMBuffer
        guard let pcmBuffer = createPCMBuffer(from: audioData, format: playbackFormat) else {
            return
        }

        // Schedule buffer for playback
        playerNode.scheduleBuffer(pcmBuffer)
    }

    private func createPCMBuffer(from data: Data, format: AVAudioFormat) -> AVAudioPCMBuffer? {
        // 服务器发送的是 PCM16 格式，每帧 2 字节
        let frameCount = data.count / 2
        guard frameCount > 0 else { return nil }

        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(frameCount)),
              let channelData = buffer.floatChannelData else {
            return nil
        }

        buffer.frameLength = AVAudioFrameCount(frameCount)

        // 将 PCM16 转换为 Float32（兼容 iOS 18+）
        data.withUnsafeBytes { (bytes: UnsafeRawBufferPointer) in
            guard let baseAddress = bytes.baseAddress else { return }
            let int16Pointer = baseAddress.assumingMemoryBound(to: Int16.self)
            let floatData = channelData[0]
            for i in 0..<frameCount {
                // Int16 范围 -32768 到 32767，转换为 -1.0 到 1.0
                floatData[i] = Float(int16Pointer[i]) / 32768.0
            }
        }

        return buffer
    }

    // MARK: - Helpers

    private func generateEventId() -> String {
        eventIdCounter += 1
        return "event_\(eventIdCounter)_\(UUID().uuidString.prefix(8))"
    }

    // Public method to update session configuration
    func updateSessionConfiguration(instructions: String) {
        let sessionConfig: [String: Any] = [
            "event_id": generateEventId(),
            "type": OmniClientEvent.sessionUpdate.rawValue,
            "session": [
                "modalities": ["text", "audio"],
                "voice": LanguageManager.staticTtsVoice,
                "input_audio_format": "pcm16",
                "output_audio_format": "pcm24",
                "smooth_output": true,
                "instructions": instructions,
                "turn_detection": [
                    "type": "server_vad",
                    "threshold": 0.5,
                    "silence_duration_ms": 800
                ]
            ]
        ]

        sendEvent(sessionConfig)
    }

    // Public method to unmute audio responses (call when quick task processing is done)
    func unmuteAudioResponses() {
        shouldMuteAudioResponses = false
        print("🔊 [Omni] 音频回复已取消静音")
    }
}

// MARK: - URLSessionWebSocketDelegate

extension OmniRealtimeService: URLSessionWebSocketDelegate {
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didOpenWithProtocol protocol: String?) {
        print("✅ [Omni] WebSocket 连接已建立, protocol: \(`protocol` ?? "none")")
    }

    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didCloseWith closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) {
        let reasonString = reason.flatMap { String(data: $0, encoding: .utf8) } ?? "unknown"
        print("🔌 [Omni] WebSocket 已断开, closeCode: \(closeCode.rawValue), reason: \(reasonString)")
    }
}
