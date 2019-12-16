//
//  FanConnection.swift
//  aurorafan-companion-mac
//
//  Created by Michael Pavkovic on 12/13/19.
//  Copyright © 2019 AuroraFan. All rights reserved.
//

import Foundation
import ORSSerial
import os.log

struct Pixel {
	let x: UInt8
	let y: UInt8
	let r: UInt8
	let g: UInt8
	let b: UInt8
	
	func toBytes() -> [UInt8] {
		return [x, y, r, g, b]
	}
}

class FanConnection : NSObject {
	
	enum SerialHeaders {
		
		// Program start headers
		static let ALIGN_PROGRAM_START: [UInt8] = [255, 254, 253, 252, 0]
		static let TEXT_PROGRAM_START: [UInt8] = [255, 254, 253, 252, 1]
		static let MVIZ_PROGRAM_START: [UInt8] = [255, 254, 253, 252, 2]
		
		// Detail headers
		static let TEXT: [UInt8] = [255, 254, 253, 252, 10]
		static let MVIZ_VALUES: [UInt8] = [255, 254, 253, 252, 20]
		static let IMAGE: [UInt8] = [255, 254, 253, 252, 30]
		static let ANALOG_CLOCK: [UInt8] = [255, 254, 253, 252, 90]
		
	}
	
	private let port: ORSSerialPort
	
	init?(serialPath: String, baudRate: NSNumber) {
		guard let port = ORSSerialPort(path: serialPath) else {
			os_log("%@: Fan connection error: %@", type: .error, "FanConnection", "No serial port at path \(serialPath)")
			return nil
		}
		
		self.port = port
		self.port.baudRate = baudRate
	}
	
	deinit {
		port.close()
	}
	
	func start() {
		self.port.delegate = self
		
		port.open()
	}
	
	func send(bytes: [UInt8]) {
		port.send(Data(bytes))
	}
	
	func send(text: String, r: UInt8, g: UInt8, b: UInt8, blink: Bool = false) {
		// R, G, B, shouldBlink, textLength
		let headers: [UInt8] = [
			r, g, b, blink ? 1 : 0, UInt8(text.count)
		]
		
		send(bytes: FanConnection.SerialHeaders.TEXT + headers + text.lowercased().utf8)
	}
	
	// We cannot support image transfer because the serial bus loses too many packets so the image comes out garbled
//	func send(pixels: [Pixel], startingX: UInt8 = 0, startingY: UInt8 = 0) {
//		let headers: [UInt8] = [
//			startingX, startingY, UInt8(pixels.count / 16), UInt8(pixels.count % 16)
//		]
//
//		let data = pixels
//			.map { $0.toBytes() }
//			.flatMap { $0 }
//
//		send(bytes: FanConnection.SerialHeaders.PIXELS + headers + data)
//	}
	
	func send(image: UInt8, startingX: UInt8 = 0, startingY: UInt8 = 0) {
		let headers: [UInt8] = [
			image, startingX, startingY
		]
		
		send(bytes: FanConnection.SerialHeaders.IMAGE + headers)
	}
	
	func sendAnalogClock(hours: UInt8, minutes: UInt8, seconds: UInt8, r: UInt8, g: UInt8, b: UInt8) {
		let headers: [UInt8] = [
			hours, minutes, seconds, r, g, b
		]
		
		send(bytes: FanConnection.SerialHeaders.ANALOG_CLOCK + headers)
	}
	
}

extension FanConnection : ORSSerialPortDelegate {
	
	func serialPortWasRemovedFromSystem(_ serialPort: ORSSerialPort) {
		print("removed")
	}
	
	
	func serialPortWasClosed(_ serialPort: ORSSerialPort) {
		print("closed")
	}
	
	func serialPort(_ serialPort: ORSSerialPort, didEncounterError error: Error) {
		print(error)
	}
	
	func serialPortWasOpened(_ serialPort: ORSSerialPort) {
		print("opened")
	}
	
	func serialPort(_ serialPort: ORSSerialPort, didReceive data: Data) {
		print(String(bytes: data, encoding: .utf8) ?? "oopsie")
	}
	
}
