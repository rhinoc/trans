//
//  AppDelegate.swift
//  trans
//
//  Created by Seon Wong on 2020/1/24.
//  Copyright © 2020 rhinoc. All rights reserved.
//

import Cocoa
import AppKit
import Async
import Carbon
import Foundation
import Alamofire
import HotKey

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    // 菜单
    @IBOutlet weak var menu: NSMenu!
    @IBAction func onCapture(_ sender: NSMenuItem) {
        guard let picPath = Utils.capturePic() else {
            return
        }
        recognizepic(picPath: picPath)
    }
    
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
        // 全局快捷键
        hotKey = HotKey(key: .a, modifiers: [.control])
        
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
        timer.invalidate()
    }
    
    public var hotKey: HotKey?{
        didSet {
            guard let hotKey = hotKey else{
                return
            }
            
            hotKey.keyDownHandler = { [weak self] in
                guard let picPath = Utils.capturePic() else {
                    return
                }
                self!.recognizepic(picPath: picPath)
            }
        }
    }
    
    private func recognizepic(picPath: String) {
        let picData = try? Data(contentsOf: URL(fileURLWithPath: picPath))
        if let base64 = picData?.base64EncodedString() {
            var prefs = Preferences()
            let auth_url = "https://aip.baidubce.com/oauth/2.0/token?grant_type=client_credentials&client_id="+prefs.key_bce+"&client_secret="+prefs.token_bce
            
            func getAuthToken(data: Data?, response: URLResponse?, error: Error?) -> Void {
                DispatchQueue.main.async {
                    do {
                        let decoder = JSONDecoder()
                        struct Res: Codable {
                            let refreshToken: String
                            let expiresIn: Int
                            let sessionKey, accessToken, scope, sessionSecret: String
                            
                            enum CodingKeys: String, CodingKey {
                                case refreshToken = "refresh_token"
                                case expiresIn = "expires_in"
                                case sessionKey = "session_key"
                                case accessToken = "access_token"
                                case scope
                                case sessionSecret = "session_secret"
                            }
                        }
                        
                        if (data != nil){
                            let r = try decoder.decode(Res.self, from: data!)
                            let access_token = r.accessToken
                            let request_url = "https://aip.baidubce.com/rest/2.0/ocr/v1/general_basic?access_token="+access_token
                            
                            let request = try! URLRequest(url: URL(string: request_url)!, method: HTTPMethod.post)
                            let encodedRequest = try? URLEncoding.default.encode(request, with: ["image":base64])
                            let body = encodedRequest?.httpBody!
                            let rq = AF.upload(body!, to: request.url!)
                            rq.responseData(completionHandler: { response in
                                switch response.result{
                                case .success(let JSON):
                                    struct BaiduOCRRes: Codable {
                                        let logID: Double
                                        let wordsResultNum: Int
                                        let wordsResult: [WordsResult]
                                        
                                        enum CodingKeys: String, CodingKey {
                                            case logID = "log_id"
                                            case wordsResultNum = "words_result_num"
                                            case wordsResult = "words_result"
                                        }
                                    }
                                    struct WordsResult: Codable {
                                        let words: String
                                    }
                                    
                                    let decoder = JSONDecoder()
                                    if let r = try? decoder.decode(BaiduOCRRes.self, from: JSON){
                                        print(r.wordsResult[0].words)
                                        NotificationCenter.default.post(name: .NSOCR, object: r.wordsResult[0].words)
                                    }
                                    else {
                                        let str = String(decoding: JSON, as: UTF8.self)
                                        print(str)
                                    }
                                    break
                                    
                                case .failure(let error):
                                    print(error)
                                }
                            })
                        }
                        
                    } catch{
                        print("Parse Error")
                        return
                    }
                }
            }
            
            func sendGetRequest(url: String, completionHandler: @escaping ((Data?,URLResponse?,Error?)->Void)) {
                let session = URLSession(configuration: .default)
                let task = session.dataTask(with: URL(string: url)!, completionHandler: completionHandler)
                task.resume()
            }
            
            sendGetRequest(url: auth_url, completionHandler: getAuthToken(data:response:error:))
            
            
        }
    }
    
}

extension NSNotification.Name {
    public static let NSPasteboardDidChange: NSNotification.Name = .init(rawValue: "pasteboardDidChangeNotification")
    public static let NSOCR: NSNotification.Name = .init(rawValue: "OCRNotification")
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


