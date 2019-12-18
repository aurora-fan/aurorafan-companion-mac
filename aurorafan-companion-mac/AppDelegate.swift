//
//  AppDelegate.swift
//  aurorafan-companion-mac
//
//  Created by Michael Pavkovic on 12/13/19.
//  Copyright © 2019 AuroraFan. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

	static var fan: FanConnection?

	func applicationDidFinishLaunching(_ aNotification: Notification) {
		AppDelegate.fan = FanConnection(serialPath: "/dev/cu.wchusbserial1430", baudRate: 115200)
	}

	func applicationWillTerminate(_ aNotification: Notification) {
		// Insert code here to tear down your application
	}


}

