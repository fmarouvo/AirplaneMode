//
//  ViewController.swift
//  AirplaneMode
//
//  Created by dev03 on 26/07/17.
//  Copyright © 2017 dev03. All rights reserved.
//

import Cocoa
import RealmSwift
import CoreFoundation

class ViewController: NSViewController {

    let realm = try! Realm()
    var tgButtonMode: TgButtonMode = .off

    @IBOutlet weak var firstView: NSView!
    @IBOutlet weak var rootPassword: NSTextField!
    @IBOutlet weak var rootSecurePassword: NSSecureTextField!
    @IBOutlet weak var defaultLocationName: NSTextField!
    @IBOutlet weak var showPassword: NSButton!
    
    @IBOutlet weak var secondView: NSView!

    @IBOutlet weak var tgBorder: NSImageView!
    @IBOutlet weak var tgBg: NSImageView!
    @IBOutlet weak var tgCornerLeft: NSImageView!
    @IBOutlet weak var tgCornerRight: NSImageView!
    @IBOutlet weak var tgButton: NSButton!
    @IBOutlet weak var tgButtonLeading: NSLayoutConstraint!
    
    override func viewDidAppear() {
        super.viewDidAppear()
        view.window?.title = "AirplaneMode (Settings)"
    }
    
	override func viewDidLoad() {
		super.viewDidLoad()
		let userData = getUserData()
		if userData?.defaultLocationName != "" && userData?.rootPassword != "" {
			view.window?.title = "AirplaneMode"
			firstView.isHidden = true
			secondView.isHidden = false
		}
		// Do any additional setup after loading the view.
	}
    
    override func mouseDown(with event: NSEvent) {
        let location = event.locationInWindow
        if location.x >= 154.7890625 && location.x <= 217.046875 && location.y >= 124.23828125 && location.y <= 139.859375 {
            buttonTgBgTapped()
        }
    }
    
    func buttonTgBgTapped() {
        switch tgButtonMode {
        case .on:
            setupTgButton(mode: .off)
        case .off:
            setupTgButton(mode: .on)
        }
    }
    
    override func viewWillAppear() {
        super.viewWillAppear()
        guard let userData = getUserData() else { return }
        guard let rootPassword = rootPassword, let defaultLocationName = defaultLocationName, let rootSecurePassword = rootSecurePassword else { return }
        rootPassword.stringValue = userData.rootPassword
        rootSecurePassword.stringValue = userData.rootPassword
        defaultLocationName.stringValue = userData.defaultLocationName 
    }

	override var representedObject: Any? {
		didSet {
		// Update the view, if already loaded.
		}
	}

    private func getUserData() -> UserData? {
        guard let user = realm.objects(UserData.self).first else {
            return nil
        }
        return user
    }

    private func setupTgButton(mode: TgButtonMode = .off) {
        guard let userData = getUserData() else { return }
        if userData.hasCreated == true {
            switch mode {
            case .on:
                tgButtonMode = .on
                tgBg.image = NSImage(named: "tg_bg_on")
                tgCornerLeft.isHidden = false
                tgCornerRight.isHidden = true
                tgButtonLeading.constant = 36
                
                NSAppleScript(source: "do shell script \"networksetup -switchtolocation AirplaneMode\" with administrator privileges password \"\(userData.rootPassword)\"")?.executeAndReturnError(nil)
            case .off:
                tgButtonMode = .off
                tgBg.image = NSImage(named: "tg_bg_off")
                tgCornerLeft.isHidden = true
                tgCornerRight.isHidden = false
                tgButtonLeading.constant = 1
                
                NSAppleScript(source: "do shell script \"networksetup -switchtolocation \(userData.defaultLocationName)\" with administrator privileges password \"\(userData.rootPassword)\"")?.executeAndReturnError(nil)
            }
        } else {
            let alert = NSAlert.init()
            alert.messageText = "Should you add AirplanMode before change network status."
            alert.informativeText = "Please, do it!"
            alert.addButton(withTitle: "OK")
            alert.runModal()
        }
    }
    
    func dialogOKCancel(question: String, text: String) -> Bool {
        let alert: NSAlert = NSAlert()
        alert.messageText = question
        alert.informativeText = text
        alert.alertStyle = NSAlertStyle.warning
        alert.addButton(withTitle: "OK")
        alert.addButton(withTitle: "Cancel")
        let res = alert.runModal()
        if res == NSAlertFirstButtonReturn {
            return true
        }
        return false
    }
    
    @IBAction func buttonSaveTapped(button: NSButton) {
        print(rootSecurePassword.stringValue)
        if rootSecurePassword.stringValue != "" && defaultLocationName.stringValue != "" {
            let userData = getUserData()
            if userData != nil {
                try! realm.write {
                    userData?.rootPassword = rootSecurePassword.stringValue
                    userData?.defaultLocationName = defaultLocationName.stringValue
                    try! realm.commitWrite()
                }
            } else {
                let userData = UserData()
                userData.rootPassword = rootSecurePassword.stringValue
                userData.defaultLocationName = defaultLocationName.stringValue
                try! realm.write {
                    realm.add(userData)
                    try! realm.commitWrite()
                }
            }
        } else {
            let alert = NSAlert.init()
            alert.messageText = "Should you fill the fields before continue"
            alert.informativeText = "Please, do it!"
            alert.addButton(withTitle: "OK")
            alert.runModal()
        }
    }
    
    @IBAction func buttonShowPasswordTapped(button: NSButton) {
        if button.state == NSOnState {
            rootPassword.isHidden = false
            rootSecurePassword.isHidden = true
        } else {
            rootPassword.isHidden = true
            rootSecurePassword.isHidden = false
        }
    }

    @IBAction func buttonModeTapped(button: NSButton) {
        guard let userData = getUserData() else { return }
        if userData.hasCreated == false {
			NSAppleScript(source: "do shell script \"networksetup -createlocation AirplaneMode populate\" with administrator privileges password \"\(userData.rootPassword)\"")?.executeAndReturnError(nil)
			NSAppleScript(source: "do shell script \"networksetup -switchtolocation AirplaneMode\" with administrator privileges password \"\(userData.rootPassword)\"")?.executeAndReturnError(nil)
			NSAppleScript(source: "do shell script \"networksetup -setv4off Ethernet\" with administrator privileges password \"\(userData.rootPassword)\"")?.executeAndReturnError(nil)
			NSAppleScript(source: "do shell script \"networksetup -switchtolocation \(userData.defaultLocationName)\" with administrator privileges password \"\(userData.rootPassword)\"")?.executeAndReturnError(nil)
            try! realm.write {
                userData.hasCreated = true
                try! realm.commitWrite()
            }
        } else {
            let answer = dialogOKCancel(question: "You already create this location, do you want continue?", text: "Choose your answer.")
            if answer == true {
				NSAppleScript(source: "do shell script \"networksetup -createlocation AirplaneMode populate\" with administrator privileges password \"\(userData.rootPassword)\"")?.executeAndReturnError(nil)
				NSAppleScript(source: "do shell script \"networksetup -switchtolocation AirplaneMode\" with administrator privileges password \"\(userData.rootPassword)\"")?.executeAndReturnError(nil)
				NSAppleScript(source: "do shell script \"networksetup -setv4off Ethernet\" with administrator privileges password \"\(userData.rootPassword)\"")?.executeAndReturnError(nil)
				NSAppleScript(source: "do shell script \"networksetup -switchtolocation \(userData.defaultLocationName)\" with administrator privileges password \"\(userData.rootPassword)\"")?.executeAndReturnError(nil)
				try! realm.write {
					userData.hasCreated = true
					try! realm.commitWrite()
				}
            }
        }
    }

    @IBAction func buttonNextTapped(button: NSButton) {
        if rootPassword.stringValue != "" && defaultLocationName.stringValue != "" {
            view.window?.title = "AirplaneMode"
            firstView.isHidden = true
            secondView.isHidden = false
        } else {
            let alert = NSAlert.init()
            alert.messageText = "Should you fill the fields before continue"
            alert.informativeText = "Please, do it!"
            alert.addButton(withTitle: "OK")
            alert.runModal()
        }
    }
    
    @IBAction func buttonBackTapped(button: NSButton) {
        view.window?.title = "AirplaneMode (Settings)"
        firstView.isHidden = false
        secondView.isHidden = true
    }
    
    @IBAction func buttonTgButtonTapped(button: NSButton) {
        switch tgButtonMode {
        case .on:
            setupTgButton(mode: .off)
        case .off:
            setupTgButton(mode: .on)
        }
    }
}

//MARK: - Extensions
extension ViewController: NSControlTextEditingDelegate {
    override func controlTextDidChange(_ notification: Notification) {
        if let rootPassword = notification.object as? NSTextField {
            rootSecurePassword.stringValue = rootPassword.stringValue
        }
        
        if let rootSecurePassword = notification.object as? NSTextField {
            rootPassword.stringValue = rootSecurePassword.stringValue
        }
    }
}

//MARK: - Struct
final class UserData: Object {
    dynamic var rootPassword: String = ""
    dynamic var defaultLocationName: String = "Automatic"
    dynamic var hasCreated: Bool = false
}

//MARK: - Enum
enum TgButtonMode {
    case on
    case off
}

