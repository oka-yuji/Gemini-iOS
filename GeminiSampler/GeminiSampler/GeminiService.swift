//
//  GeminiService.swift
//  GeminiSampler
//
//  Created by yuji on 2025/01/10.
//

import UIKit
@preconcurrency import GoogleGenerativeAI

@MainActor @Observable final class GeminiService {
    let apiKey: String = "API_KEY"
    var mode: InteractionMode = .textToText
    var modelName: ModelName
    let model: GenerativeModel
    let chat: Chat
    var histories: [History] = []
    var isLoading: Bool = false
    var prompt: String = ""
    var selectedUIImage: UIImage?

    init(mode: InteractionMode = .textToText,
         modelName: ModelName = .gemini15FlashLatest) {
        self.mode = mode
        self.modelName = modelName
        model = GenerativeModel(name: modelName.rawValue, apiKey: apiKey)
        chat = model.startChat()
    }

    func sendTextToText() {
        isLoading = true
        histories.append(History(prompt: prompt, response: ""))
        let endIndex = histories.endIndex - 1
        Task {
            do {
                let response = try await model.generateContent(prompt).text ?? ""
                histories[endIndex].response = response
                promptReset()
                isLoading = false
            } catch {
                print(error)
                isLoading = false
            }
        }
    }

    func sendImageToText() {
        isLoading = true
        histories.append(History(prompt: prompt,image: selectedUIImage, response: ""))
        let endIndex = histories.endIndex - 1
        guard let selectedUIImage else { return }
        Task {
            do {
                let response = try await model.generateContent(prompt, selectedUIImage).text ?? ""
                histories[endIndex].response = response
                promptReset()
                isLoading = false
            } catch {
                print(error)
                isLoading = false
            }
        }
    }

    func sendChat() {
        isLoading = true
        histories.append(History(prompt: prompt, response: ""))
        let endIndex = histories.endIndex - 1
        Task {
            do {
                let history = [
                    try ModelContent(role: "user", "こんにちは、私は家で2匹の犬を飼っています。名前は武蔵と小次郎です。"),
                    try ModelContent(role: "model", "こんにちは。何を知りたいですか？")
                ]
                let chat = model.startChat(history: history)
                let response = try await chat.sendMessage(prompt).text ?? ""
                histories[endIndex].response = response
                promptReset()
                isLoading = false
            } catch {
                print(error)
                isLoading = false
            }
        }
    }

    func sendStreaming() {
        isLoading = true
        histories.append(History(prompt: prompt, response: ""))
        let endIndex = histories.endIndex - 1
        Task {
            do {
                let contentStream = chat.sendMessageStream(prompt)
                for try await chunk in contentStream {
                    if let text = chunk.text {
                        histories[endIndex].response! += text
                    }
                }
                promptReset()
                isLoading = false
            } catch {
                print(error)
                isLoading = false
            }
        }
    }

    private func promptReset() {
        prompt = ""
        selectedUIImage = nil
    }

    enum InteractionMode: String, CaseIterable {
        case textToText = "Text to Text"
        case imageToText = "Image to Text"
        case chat = "Chat"
        case streaming = "Streaming"
    }
}
