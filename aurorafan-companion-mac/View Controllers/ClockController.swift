//
//  ClockController.swift
//  aurorafan-companion-mac
//
//  Created by Thomas Niedzwiadek on 12/15/19.
//  Copyright © 2019 AuroraFan. All rights reserved.
//

import Cocoa

class ClockController: NSViewController {
    
    private var lastColorTime: Double = 0
	private var visible = true

    @IBOutlet weak var currentTimeDisplay: NSTextField!
    @IBOutlet weak var colorWell: NSColorWell!
	@IBOutlet weak var useMilitaryTimeCheckbox: NSButton!
	@IBOutlet weak var useAnalogCheckbox: NSButton!
	
    @IBAction func militaryTimeBoxCheckChanged(_ sender: NSButton) {
		sendTime(sender.state == .on, asAnalog: useAnalogCheckbox.state == .on)
    }
    
    @IBAction func colorWellChangedColor(_ sender: NSColorWell) {
        let currentTime = Date().timeIntervalSince1970
        
        if currentTime > lastColorTime + 0.5 {
			sendTime(useMilitaryTimeCheckbox.state == .on, asAnalog: useAnalogCheckbox.state == .on)
            lastColorTime = currentTime
        }
    }
    
	@IBAction func showAsAnalogCheckChanged(_ sender: NSButton) {
		useMilitaryTimeCheckbox.isEnabled = sender.state != .on
		
		if sender.state == .on {
			
		} else {
			
		}
	}
	
	@discardableResult private func sendTime(_ useMilitaryTime: Bool, asAnalog: Bool) -> String {
        let color = colorWell.color
        
        let currentDate = NSDate()
        let dateFormatter = DateFormatter()
		var date: String
        if (!useMilitaryTime) {
            dateFormatter.dateFormat = "HH"
            var hours = dateFormatter.string(from: currentDate as Date)
            var PM = false;
            if Int(hours)!>=12 {
                PM = true
                hours = String(Int(hours)!-12)
            }
            else {
                hours = String(Int(hours)!)
            }
            dateFormatter.dateFormat = "mm"
			let min = dateFormatter.string(from: currentDate as Date)
            hours += ":"
            hours += min
            if PM {
                hours += " PM"
            }
            else {
                hours += " AM"
            }
            date = String(hours)
        }
        else {
            dateFormatter.dateFormat = "HH:mm"
            date = dateFormatter.string(from: currentDate as Date)
        }
        
		if !asAnalog {
			AppDelegate.fan?.send(text: date,
				r: UInt8(color.redComponent * 255),
				g: UInt8(color.greenComponent * 255),
				b: UInt8(color.blueComponent * 255))
		} else {
			AppDelegate.fan?.sendAnalogClock(hours: UInt8(Calendar.current.component(.hour, from: Date())),
				minutes: UInt8(Calendar.current.component(.minute, from: Date())),
				seconds: UInt8(Calendar.current.component(.second, from: Date())),
				r: UInt8(color.redComponent * 255),
				g: UInt8(color.greenComponent * 255),
				b: UInt8(color.blueComponent * 255))
		}
		
		return date
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
		
		let _ = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true, block: { timer in
			if self.visible {
				self.currentTimeDisplay.stringValue = self.sendTime(self.useMilitaryTimeCheckbox.state == .on, asAnalog: self.useAnalogCheckbox.state == .on)
			}
		})
    }
    
    override func viewDidAppear() {
        AppDelegate.fan?.send(bytes: FanConnection.SerialHeaders.TEXT_PROGRAM_START)
		visible = true
    }
	
	override func viewDidDisappear() {
		visible = false
	}
    
}
