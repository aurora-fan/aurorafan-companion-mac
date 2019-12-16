//
//  AlignController.swift
//  aurorafan-companion-mac
//
//  Created by Michael Pavkovic on 12/15/19.
//  Copyright © 2019 AuroraFan. All rights reserved.
//

import Cocoa

class AlignController: NSViewController {
	
	override func viewDidAppear() {
		AppDelegate.fan?.send(bytes: FanConnection.SerialHeaders.ALIGN_PROGRAM_START)
	}
    
}
