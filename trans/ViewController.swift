//
//  ViewController.swift
//  trans
//
//  Created by Seon Wong on 2019/10/20.
//  Copyright © 2019 Seon. All rights reserved.
//

import Cocoa

class ViewController: NSViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        NotificationCenter.default.addObserver(self, selector: #selector(onPasteboardChanged), name: .NSPasteboardDidChange, object: nil)
    }
    
    @objc
    func onPasteboardChanged(_ notification: Notification) {
        guard let pb = notification.object as? NSPasteboard else { return }
        guard let items = pb.pasteboardItems else { return }
        guard let item = items.first?.string(forType: .string) else { return } // you should handle multiple types
      
        print("New item in pasteboard: '\(item)'")
    }
}
