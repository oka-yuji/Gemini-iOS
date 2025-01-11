//
//  ContentView.swift
//  GeminiSampler
//
//  Created by yuji on 2025/01/10.
//

import SwiftUI
import PhotosUI

struct ContentView: View {
    @State private var gemini: GeminiService = .init()
    @State private var selectedItem: PhotosPickerItem?
    var body: some View {
        NavigationStack {
            VStack {
                Picker("Model", selection: $gemini.modelName) {
                    ForEach(ModelName.allCases, id: \.self) { model in
                        Text(model.rawValue)
                    }
                }
                .pickerStyle(.segmented)

                Picker("Model", selection: $gemini.mode) {
                    ForEach(GeminiService.InteractionMode.allCases, id: \.self) { mode in
                        Text(mode.rawValue)
                    }
                }
                .pickerStyle(.segmented)

                ScrollView {
                    ForEach(gemini.histories) { history in
                        VStack(alignment: .trailing) {
                            if let image = history.image {
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 300, height: 200)
                                    .clipShape(RoundedRectangle(cornerRadius: 16))
                            }
                            Text(history.prompt)
                                .foregroundStyle(.white)
                                .textSelection(.enabled)
                                .padding(8)
                                .background(
                                    Color.blue
                                        .clipShape(.rect(
                                            topLeadingRadius: 8,
                                            bottomLeadingRadius: 8,
                                            bottomTrailingRadius: 0,
                                            topTrailingRadius: 8
                                        ))
                                )
                        }
                        .frame(maxWidth: .infinity, alignment: .trailing)

                        Text((history.response ?? "").getAttributedString())
                            .textSelection(.enabled)
                            .padding(8)
                            .background(
                                Color.secondary.opacity(0.2)
                                    .clipShape(.rect(
                                        topLeadingRadius: 8,
                                        bottomLeadingRadius: 0,
                                        bottomTrailingRadius: 8,
                                        topTrailingRadius: 8
                                    ))
                            )
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .foregroundStyle(.black)
                    }
                }
                HStack {
                    TextField("Prompt", text: $gemini.prompt)

                    if gemini.mode == .imageToText {
                        PhotosPicker(selection: $selectedItem) { [selectedUIImage = gemini.selectedUIImage] in
                            if selectedUIImage != nil {
                                Image(uiImage: selectedUIImage!)
                                    .resizable()
                                    .frame(width: 40, height: 30)
                                    .clipShape( RoundedRectangle(cornerRadius: 4) )
                            } else {
                                Image(systemName: "photo")
                                    .foregroundStyle(.gray)
                            }
                        }
                    }

                    Button {
                        switch gemini.mode {
                        case .textToText:
                            gemini.sendTextToText()
                        case .imageToText:
                            gemini.sendImageToText()
                        case .chat:
                            gemini.sendChat()
                        case .streaming:
                            gemini.sendStreaming()
                        }
                    } label: {
                        if gemini.isLoading {
                            ProgressView()
                        } else {
                            Image(systemName: "paperplane")
                                .foregroundStyle(.gray)
                        }
                    }
                    .disabled(gemini.isLoading)
                }
                .textFieldStyle(.roundedBorder)
            }
            .padding()
            .navigationTitle("Gemini Sampler")
            .onChange(of: selectedItem) {
                Task {
                    guard let data = try? await selectedItem?.loadTransferable(type: Data.self) else { return }
                    guard let image = UIImage(data: data) else { return }
                    gemini.selectedUIImage = image
                }
            }
        }
    }
}

#Preview {
    ContentView()
}

extension String {
    func getAttributedString() -> AttributedString {
        do {
            let attributedString = try AttributedString(markdown: self)
            return attributedString
        } catch {
            print("Couldn't parse: \(error)")
        }
        return AttributedString("Error parsing markdown")
    }
}
