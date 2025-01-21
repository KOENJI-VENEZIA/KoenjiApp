//
//  TouchDebugView.swift
//  KoenjiApp
//
//  Created by Matteo Nassini on 21/1/25.
//
import UIKit
import SwiftUI

struct TouchDebugView: UIViewRepresentable {
    func makeUIView(context: Context) -> DebugTouchView {
        return DebugTouchView()
    }

    func updateUIView(_ uiView: DebugTouchView, context: Context) {}
}

class DebugTouchView: UIView {
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        print("Touches began at: \(touches.first?.location(in: self) ?? .zero)")
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesMoved(touches, with: event)
        print("Touches moved at: \(touches.first?.location(in: self) ?? .zero)")
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        print("Touches ended at: \(touches.first?.location(in: self) ?? .zero)")
    }
}
