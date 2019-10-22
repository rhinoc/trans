//
//  PopoverDemoViewController.swift
//  trans
//
//  Created by Seon Wong on 2019/10/19.
//  Copyright © 2019 Seon. All rights reserved.
//

import Cocoa
import CommonCrypto
import UserNotifications
import Foundation

var temp = ""
var tempTrans = ""
var from = "auto"
var to = "zh"


class PopoverViewController: NSViewController {
    
    @IBOutlet weak var inputText: NSSearchField!
    @IBOutlet weak var translatedText: NSTextField!
    @IBOutlet weak var copyButton: NSButton!
    @IBOutlet weak var langSwicher: NSPopUpButtonCell!
    @IBOutlet weak var touchBarView: NSPopoverTouchBarItem!
    @IBOutlet weak var touchBarText: NSTextField!
    
    @IBAction func switchLanguage(_ sender: Any) {
        let selected = langSwicher.indexOfSelectedItem
        temp = ""
        tempTrans = ""
        switch selected {
        case 0:
            from = "auto"
            to = "zh"
            break
        case 1:
            from = "auto"
            to = "en"
            break
        default:
            from = "auto"
            to = "zh"
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        NotificationCenter.default.addObserver(self, selector: #selector(onPasteboardChanged), name: .NSPasteboardDidChange, object: nil)
    }
    
    @objc
    func onPasteboardChanged(_ notification: Notification) {
        guard let pb = notification.object as? NSPasteboard else { return }
        guard let items = pb.pasteboardItems else { return }
        
        guard let cur = items.first?.string(forType: .string) else { return }
        if (cur != temp && cur != tempTrans){
            inputText.stringValue = cur
            getTranslationResult(str: cur, type:"copy")
            temp = cur
        }
    }
    
    @IBAction func closePopover(_ sender: Any) {
        NSApplication.shared.terminate(self)
    }
    
    @IBAction func searchClick(_ sender: NSSearchField) {
        copyButton.title = "Copy"
        let cur = sender.stringValue;
        if (cur != temp && cur != tempTrans){
            getTranslationResult(str: cur, type:"search")
            temp = cur
        }
    }
    
    @IBAction func clearResult(_ sender: Any) {
        inputText.stringValue = "";
        translatedText.stringValue = "";
    }
    
    @IBAction func copyResult(_ sender: Any) {
        let pb = NSPasteboard.general
        pb.clearContents()
        pb.setString(tempTrans, forType: .string)
        copyButton.title = "Copied"
//        copyButton.image = NSImage(named: NSImage.Name("NSMenuOnStateTemplate"))
    }
    
    func getTranslationResult(str:String, type:String) -> Void {
        if (str.isEmpty) {
            translatedText.stringValue = ""
            labelTouchBar(str: "")
            return
        }
        
        let appid = "xxxx"; //换成你自己的百度翻译APPID
        let salt = "1435660288"; //其实应该是随机数的但是我太懒了
        let key = "xxxx"; //换成你自己的百度翻译KEY
        let sign = md5Hash(str: appid+str+salt+key);
        let base = "https://fanyi-api.baidu.com/api/trans/vip/translate"
        let url = base+"?q="+str.urlEncoded()+"&appid="+appid+"&salt="+salt+"&sign="+sign+"&from="+from+"&to="+to;
        
        func getTranslationSuccess(data: Data?, response: URLResponse?, error: Error?) -> Void {
            DispatchQueue.main.async {
                do {
                    let decoder = JSONDecoder()
                    
                    struct Res: Codable {
                        var from: String
                        var to: String
                        var trans_result: [TransResult]
                        
                        struct TransResult: Codable {
                            let src: String
                            let dst: String
                        }
                    }
                    if (data != nil){
                        let r = try decoder.decode(Res.self, from: data!)
                        
                        tempTrans = r.trans_result[0].dst;
                        self.translatedText.stringValue = tempTrans;
                        self.labelTouchBar(str: r.trans_result[0].dst)
                        
                        if (type == "copy" ) {
                            self.notify(title: r.trans_result[0].src,body: r.trans_result[0].dst)
                        }
                    }
                    
                } catch{
                    self.translatedText.stringValue = "Error";
                    if (type == "copy" ) {
                        self.notify(title: "Error",body: "Something just happened")
                    }
                    return
                }
            }
        }
        
        func sendGetRequest(url: String, completionHandler: @escaping ((Data?,URLResponse?,Error?)->Void)) {
            let session = URLSession(configuration: .default)
            let task = session.dataTask(with: URL(string: url)!, completionHandler: completionHandler)
            task.resume()
        }
        
        sendGetRequest(url: url, completionHandler: getTranslationSuccess(data:response:error:))
    }
    
    func md5Hash (str: String) -> String {
        if let strData = str.data(using: String.Encoding.utf8) {
            var digest = [UInt8](repeating: 0, count:Int(CC_MD5_DIGEST_LENGTH))
            strData.withUnsafeBytes {
                CC_MD5($0.baseAddress, UInt32(strData.count), &digest)
            }
            var md5String = ""
            for byte in digest {
                md5String += String(format:"%02x", UInt8(byte))
            }
            return md5String
        }
        return ""
    }
    
    func labelTouchBar(str: String){
        touchBarText.stringValue = str;
        
//        touchBarView.collapsedRepresentationLabel = str;
//        touchBarView.customizationLabel = str;
//        touchBarView.showsCloseButton = true;
//        touchBarView.showPopover(<#T##sender: Any?##Any?#>)
    }
    
    func notify(title: String,body: String){
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound]) { success, error in
           if error == nil {
               if success == true {
                print("Permission granted")
                let content = UNMutableNotificationContent()
                content.title = title;
                content.body = body;
                content.userInfo = ["method": "new"]

                content.categoryIdentifier = "TRANSLATION_RESULT"
                
                let acceptAction = UNNotificationAction(identifier: "SHOW_ACTION", title: "Copy", options: .init(rawValue: 0))
                let declineAction = UNNotificationAction(identifier: "CLOSE_ACTION", title: "Close", options: .init(rawValue: 0))
                let testCategory = UNNotificationCategory(identifier: "TRANSLATION_RESULT",
                                                          actions: [acceptAction,declineAction],
                                                          intentIdentifiers: [],
                                                          hiddenPreviewsBodyPlaceholder: "",
                                                          options: .customDismissAction)
                
                let request = UNNotificationRequest(identifier: "NOTIFICATION_REQUEST",
                                                    content: content,
                                                    trigger: nil)
                
                // Schedule the request with the system.
                let notificationCenter = UNUserNotificationCenter.current()
                notificationCenter.delegate = self
                notificationCenter.setNotificationCategories([testCategory])
                notificationCenter.add(request) { (error) in
                    if error != nil {
                        // Handle any errors.
                    }
                }
               }
               else {
                   print("Permission denied")
               }
           }
           else {
               print(error)
           }
        }
    }
}

extension String {
     
    //将原始的url编码为合法的url
    func urlEncoded() -> String {
        let encodeUrlString = self.addingPercentEncoding(withAllowedCharacters:
            .urlQueryAllowed)
        return encodeUrlString ?? ""
    }
     
    //将编码后的url转换回原始的url
    func urlDecoded() -> String {
        return self.removingPercentEncoding ?? ""
    }
}

extension PopoverViewController: UNUserNotificationCenterDelegate {
    
    // 用户点击弹窗后的回调
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        switch response.actionIdentifier {
        case "SHOW_ACTION":
            let pb = NSPasteboard.general
            pb.clearContents()
            pb.setString(tempTrans, forType: .string)
        case "CLOSE_ACTION":
            print("Nothing to do")
        default:
            break
        }
        completionHandler()
    }
    
    // 配置通知发起时的行为 alert -> 显示弹窗, sound -> 播放提示音
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.alert, .sound])
    }
}



class VerticallyCenteredTextFieldCell: NSTextFieldCell {
    
    override func drawingRect(forBounds theRect: NSRect) -> NSRect {
        var newRect:NSRect = super.drawingRect(forBounds: theRect)
        let textSize:NSSize = self.cellSize(forBounds: theRect)
        let heightDelta:CGFloat = newRect.size.height - textSize.height
        if heightDelta > 0 {
            newRect.size.height = textSize.height
            newRect.origin.y += heightDelta / 2
        }
        return newRect
    }
}
