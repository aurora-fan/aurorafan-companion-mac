//
//  TextController.swift
//  aurorafan-companion-mac
//
//  Created by Michael Pavkovic on 12/14/19.
//  Copyright © 2019 AuroraFan. All rights reserved.
//

import Cocoa

class TextController: NSViewController {
	
	private var lastColorTime: Double = 0

	@IBOutlet weak var textField: NSTextField!
	@IBOutlet weak var colorWell: NSColorWell!
	
	@IBAction func sendPressed(_ sender: NSButton) {
		sendText()
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
		
		AppDelegate.fan?.send(text: textField.stringValue,
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
