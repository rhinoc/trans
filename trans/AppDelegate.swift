//
//  AppDelegate.swift
//  tranns
//
//  Created by Seon Wong on 2020/1/24.
//  Copyright © 2020 rhinoc. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    // 菜单
    @IBOutlet weak var menu: NSMenu!
    
    @IBOutlet weak var pasteTransToggle: NSMenuItem!
    var prefs = Preferences()
    @IBAction func onTogglePasteTrans(_ sender: NSMenuItem) {
        if (pasteTransToggle.state.rawValue == 1) { //开->关
            pasteTransToggle.state = NSControl.StateValue.off
            timer.invalidate()
        }
        else { //关->开
            pasteTransToggle.state = NSControl.StateValue.on
            newTimer()
        }
        prefs.enablePasteTrans = pasteTransToggle.state.rawValue
    }
    @IBAction func onQuit(_ sender: Any) {
        NSApplication.shared.terminate(self)
    }
    
    // 状态栏图标
    let statusItem = NSStatusBar.system.statusItem(withLength:NSStatusItem.squareLength)
    // 弹窗
    let popover = NSPopover()
    // 监视器 失去焦点后关闭弹窗
    var eventMonitor: EventMonitor?
    // 定时器 监视剪贴板
    var timer: Timer!
    let pasteboard: NSPasteboard = .general
    var lastChangeCount: Int = 0
    
    func newTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { (t) in //监视剪贴板
            if self.lastChangeCount != self.pasteboard.changeCount {
                self.lastChangeCount = self.pasteboard.changeCount
                NotificationCenter.default.post(name: .NSPasteboardDidChange, object: self.pasteboard)
            }
        }
        timer.fire()
    }

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // 指定右键菜单的代理
        menu.delegate = self
        
        // 初始化监视器
        eventMonitor = EventMonitor(mask: [.leftMouseDown, .rightMouseDown]) { [weak self] event in
            if let strongSelf = self, strongSelf.popover.isShown {
                strongSelf.closePopover(sender: event!)
            }
        }
        
        if let button = statusItem.button { //设置按钮的样式和点击事件
          button.image = NSImage(named:NSImage.Name("statusIcon"))
          button.action = #selector(mouseClickHandler)
          button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }
        popover.contentViewController = PopoverViewController.freshController() //将弹窗与storyboard绑定
        
        // 读取配置
        if (prefs.enablePasteTrans==1){
            pasteTransToggle.state = NSControl.StateValue.on
            newTimer()
        }
        else {
            pasteTransToggle.state = NSControl.StateValue.off
        }
        
        showPopover(sender: popover)
    }
    
    @objc func mouseClickHandler() {
        if let event = NSApp.currentEvent {
            switch event.type {
            case .leftMouseUp:
                togglePopover(popover) //左键打开弹窗
            default:
                statusItem.menu = menu //右键打开菜单
                statusItem.button?.performClick(nil)
            }
        }
    }
    
    @objc func togglePopover(_ sender: Any?) {
      if popover.isShown {
        closePopover(sender: sender)
      } else {
        showPopover(sender: sender)
      }
    }
    
    func showPopover(sender: Any?){
        if let button = statusItem.button{
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: NSRectEdge.minY)
        }
        eventMonitor?.start()
    }
    
    func closePopover(sender: Any?){
        popover.performClose(sender)
        eventMonitor?.stop()
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
        timer.invalidate()
    }
// 需要10.15
//    // MARK: - Core Data stack
//
//    lazy var persistentContainer: NSPersistentCloudKitContainer = {
//        /*
//         The persistent container for the application. This implementation
//         creates and returns a container, having loaded the store for the
//         application to it. This property is optional since there are legitimate
//         error conditions that could cause the creation of the store to fail.
//        */
//        let container = NSPersistentCloudKitContainer(name: "tranns")
//        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
//            if let error = error {
//                // Replace this implementation with code to handle the error appropriately.
//                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
//
//                /*
//                 Typical reasons for an error here include:
//                 * The parent directory does not exist, cannot be created, or disallows writing.
//                 * The persistent store is not accessible, due to permissions or data protection when the device is locked.
//                 * The device is out of space.
//                 * The store could not be migrated to the current model version.
//                 Check the error message to determine what the actual problem was.
//                 */
//                fatalError("Unresolved error \(error)")
//            }
//        })
//        return container
//    }()

//    // MARK: - Core Data Saving and Undo support
//
//    @IBAction func saveAction(_ sender: AnyObject?) {
//        // Performs the save action for the application, which is to send the save: message to the application's managed object context. Any encountered errors are presented to the user.
//        let context = persistentContainer.viewContext
//
//        if !context.commitEditing() {
//            NSLog("\(NSStringFromClass(type(of: self))) unable to commit editing before saving")
//        }
//        if context.hasChanges {
//            do {
//                try context.save()
//            } catch {
//                // Customize this code block to include application-specific recovery steps.
//                let nserror = error as NSError
//                NSApplication.shared.presentError(nserror)
//            }
//        }
//    }

//    func windowWillReturnUndoManager(window: NSWindow) -> UndoManager? {
//        // Returns the NSUndoManager for the application. In this case, the manager returned is that of the managed object context for the application.
//        return persistentContainer.viewContext.undoManager
//    }

//    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
//        // Save changes in the application's managed object context before the application terminates.
//        let context = persistentContainer.viewContext
//        
//        if !context.commitEditing() {
//            NSLog("\(NSStringFromClass(type(of: self))) unable to commit editing to terminate")
//            return .terminateCancel
//        }
//        
//        if !context.hasChanges {
//            return .terminateNow
//        }
//        
//        do {
//            try context.save()
//        } catch {
//            let nserror = error as NSError
//
//            // Customize this code block to include application-specific recovery steps.
//            let result = sender.presentError(nserror)
//            if (result) {
//                return .terminateCancel
//            }
//            
//            let question = NSLocalizedString("Could not save changes while quitting. Quit anyway?", comment: "Quit without saves error question message")
//            let info = NSLocalizedString("Quitting now will lose any changes you have made since the last successful save", comment: "Quit without saves error question info");
//            let quitButton = NSLocalizedString("Quit anyway", comment: "Quit anyway button title")
//            let cancelButton = NSLocalizedString("Cancel", comment: "Cancel button title")
//            let alert = NSAlert()
//            alert.messageText = question
//            alert.informativeText = info
//            alert.addButton(withTitle: quitButton)
//            alert.addButton(withTitle: cancelButton)
//            
//            let answer = alert.runModal()
//            if answer == .alertSecondButtonReturn {
//                return .terminateCancel
//            }
//        }
//        // If we got here, it is time to quit.
//        return .terminateNow
//    }

}

extension NSNotification.Name {
    public static let NSPasteboardDidChange: NSNotification.Name = .init(rawValue: "pasteboardDidChangeNotification")
}

extension NSTextField { //令NSTextField可操作常用快捷键
    open override func performKeyEquivalent(with event: NSEvent) -> Bool {
        if event.modifierFlags.isDisjoint(with: .command) {
            return super.performKeyEquivalent(with: event)
        }
        
        switch event.charactersIgnoringModifiers {
        case "a":
            return NSApp.sendAction(#selector(NSText.selectAll(_:)), to: self.window?.firstResponder, from: self)
        case "c":
            return NSApp.sendAction(#selector(NSText.copy(_:)), to: self.window?.firstResponder, from: self)
        case "v":
            return NSApp.sendAction(#selector(NSText.paste(_:)), to: self.window?.firstResponder, from: self)
        case "x":
            return NSApp.sendAction(#selector(NSText.cut(_:)), to: self.window?.firstResponder, from: self)
        default:
            return super.performKeyEquivalent(with: event)
        }
    }
}

extension AppDelegate: NSMenuDelegate {
    func menuDidClose(_ menu: NSMenu) {
        self.statusItem.menu = nil
    }
}


