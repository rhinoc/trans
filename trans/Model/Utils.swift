//
//  Utils.swift
//  trans
//
//  Created by Seon Wong on 2020/2/4.
//  Copyright © 2020 rhinoc. All rights reserved.
//

import Foundation
class Utils {
    static func capturePic() -> String? {
        let dest = NSTemporaryDirectory()+"\(UUID().uuidString).png";
        let task = Process()
        task.launchPath = "/usr/sbin/screencapture"
        task.arguments = ["-i", "-r", dest]
        task.launch()
        task.waitUntilExit()
        return
            FileManager.default.fileExists(atPath: dest) ? dest : nil
    }
    
}
