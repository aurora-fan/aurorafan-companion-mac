//
//  WeatherController.swift
//  aurorafan-companion-mac
//
//  Created by Michael Pavkovic on 12/15/19.
//  Copyright © 2019 AuroraFan. All rights reserved.
//

import Cocoa
import CoreLocation

class WeatherController : NSViewController {
	
	private let locationManager = CLLocationManager()
	
	@IBOutlet weak var currentLocationTextField: NSTextField!
	@IBOutlet weak var tempTextField: NSTextField!
	@IBOutlet weak var iconTextField: NSTextField!
	@IBOutlet weak var descriptionTextField: NSTextField!
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		locationManager.delegate = self
		locationManager.requestLocation()
	}
	
	override func viewDidAppear() {
		AppDelegate.fan?.send(bytes: FanConnection.SerialHeaders.TEXT_PROGRAM_START)
		
		setLocation(CLLocation(coordinate: CLLocationCoordinate2D(latitude: 42.39719, longitude: -72.52280), altitude: 0, horizontalAccuracy: 0, verticalAccuracy: 0, course: 0, speed: 0, timestamp: Date()))
	}
	
	private func setLocation(_ location: CLLocation) {
		currentLocationTextField.stringValue = "\(location.coordinate.latitude), \(location.coordinate.longitude)"
		
		URLSession.shared.dataTask(with: URLRequest(url: URL(string: "https://api.darksky.net/forecast/ba969f6c1ba28bf09c9b612e9351a9ad/\(location.coordinate.latitude),\(location.coordinate.longitude)")!)) { data, response, error in
			guard let data = data, let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any], let currentWeather = json["currently"] as? [String: Any] else {
				print("Could not load weather")
				return
			}
			
			DispatchQueue.main.async {
				self.tempTextField.stringValue = "Temperature: \(currentWeather["temperature"]!) °F"
				self.iconTextField.stringValue = "Icon: \(currentWeather["icon"]!)"
				self.descriptionTextField.stringValue = "Description: \(currentWeather["summary"]!)"
				
				AppDelegate.fan?.send(text: "\(currentWeather["summary"]!) - \(currentWeather["temperature"]!)F", r: 0, g: 0, b: 255)
				AppDelegate.fan?.send(image: 0, startingX: 14, startingY: 0)
			}
		}.resume()
	}
}

extension WeatherController : CLLocationManagerDelegate {
	
	func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
		guard let location = locations.first else {
			return
		}
		
		setLocation(location)
	}
	
	func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
		print(status)
	}
	
	func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
		print(error)
	}
	
}
