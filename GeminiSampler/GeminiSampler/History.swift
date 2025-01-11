//
//  History.swift
//  GeminiSampler
//
//  Created by yuji on 2025/01/10.
//

import UIKit

struct History: Identifiable {
    let id = UUID()
    let prompt: String
    let image: UIImage?
    var response: String?

    init(prompt: String,
         image: UIImage? = nil,
         response: String? = nil) {
        self.prompt = prompt
        self.image = image
        self.response = response
    }
}
