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

    @IBOutlet weak var currentTimeDisplay: NSTextField!
    @IBOutlet weak var colorWell: NSColorWell!
    
    @IBAction func militaryTimeBoxCheckChanged(_ sender: NSButton) {
        
    }
    
    @IBAction func colorWellChangedColor(_ sender: NSColorWell) {
        let currentTime = Date().timeIntervalSince1970
        
        if currentTime > lastColorTime + 0.5 {
            sendText()
            lastColorTime = currentTime
        }
    }
    
    private func sendText() {
        let color = colorWell.color
        
        let currentDate = NSDate()
        let dateFormatter = DateFormatter()
        var doing12Hour = true;
        if (doing12Hour) {
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
            var min = dateFormatter.string(from: currentDate as Date)
            hours += ":"
            hours += min
            if PM {
                hours += " PM"
            }
            else {
                hours += " AM"
            }
            var date = String(hours)
        }
        else {
            dateFormatter.dateFormat = "HH:mm"
            var date = dateFormatter.string(from: currentDate as Date)
        }
        
        AppDelegate.fan?.send(text: convertedDate,
            r: UInt8(color.redComponent * 255),
            g: UInt8(color.greenComponent * 255),
            b: UInt8(color.blueComponent * 255))
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewDidAppear() {
        AppDelegate.fan?.send(bytes: FanConnection.SerialHeaders.TEXT_PROGRAM_START)
    }
    
}
