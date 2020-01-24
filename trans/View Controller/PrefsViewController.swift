//
//  PrefsViewController.swift
//  tranns
//
//  Created by Seon Wong on 2020/1/24.
//  Copyright © 2020 rhinoc. All rights reserved.
//

import Cocoa

class PrefsViewController: NSViewController {
    @IBOutlet weak var translateEngine: NSPopUpButton! //翻译引擎
    @IBOutlet weak var appidField: NSTextField!//APPID
    @IBOutlet weak var keyField: NSSecureTextField!//密钥
    @IBOutlet weak var okButton: NSButton!//确认按钮
    @IBOutlet weak var cancelButton: NSButton!//取消按钮
    
    var prefs = Preferences()
    
    func showExistingPrefs() {
        let APPID_baidu = prefs.APPID_baidu
        let APPID_youdao = prefs.APPID_youdao
        let key_baidu = prefs.key_baidu
        let key_youdao = prefs.key_youdao
        let defaultEngine = prefs.defaultEngine
        translateEngine.selectItem(at: defaultEngine)
        if (defaultEngine==0) {
            appidField.stringValue = APPID_baidu
            keyField.stringValue = key_baidu
        }
        else {
            appidField.stringValue = APPID_youdao
            keyField.stringValue = key_youdao
        }
    }
    
    
    
    @IBAction func onEngineChange(_ sender: NSPopUpButton) {
        if (translateEngine.indexOfSelectedItem == 0) {
            appidField.stringValue = prefs.APPID_baidu
            keyField.stringValue = prefs.key_baidu
        }
        else {
            appidField.stringValue = prefs.APPID_youdao
            keyField.stringValue = prefs.key_youdao
        }
    }
    
    @IBAction func onCancel(_ sender: Any) {
        view.window?.close()
    }
    @IBAction func onOK(_ sender: Any) {
        saveNewPrefs()
        view.window?.close()
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        showExistingPrefs()
    }
    
    func saveNewPrefs() {
        prefs.defaultEngine = translateEngine.indexOfSelectedItem
        if (translateEngine.indexOfSelectedItem==0){
            prefs.APPID_baidu = appidField.stringValue
            prefs.key_baidu = keyField.stringValue
        }
        else {
            prefs.APPID_youdao = appidField.stringValue
            prefs.key_youdao = keyField.stringValue
        }
    }
    
}
