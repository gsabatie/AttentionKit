//
//  ContentView.swift
//  Demo
//
//  Created by P995531 on 18/09/2021.
//

import SwiftUI
import AttentionKit

struct ContentView: View {
    @ObservedObject var service = EyeRecognitionService()

    var body: some View {
        Text(service.faceDetected ? "EyeRecognitionService face true" : "EyeRecognitionService face false")
            .padding()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
