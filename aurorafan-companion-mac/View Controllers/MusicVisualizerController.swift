//
//  MusicVisualizerController.swift
//  aurorafan-companion-mac
//
//  Created by Michael Pavkovic on 12/13/19.
//  Copyright © 2019 AuroraFan. All rights reserved.
//

import AVFoundation
import Cocoa
import iTunesLibrary
import os.log

class MusicVisualizerController: NSViewController {
	
	private var visible = false
	
	let audioEngine = AVAudioEngine()
    let audioNode = AVAudioPlayerNode()
	
	private var songs: [ITLibMediaItem] = []
	private var isPlaying = false
	private let levels: [NSLevelIndicator] = (0..<50).map { _ in
		let view = NSLevelIndicator()
		view.minValue = 0
		view.maxValue = 8
		view.warningValue = 7
		view.criticalValue = 8
		
		view.rotate(byDegrees: 90)
		
		return view
	}
	
	private var previousTime: Double = 0

	@IBOutlet weak var playButton: NSButton!
	@IBOutlet weak var songPopupSelectionButton: NSPopUpButton!
	@IBOutlet weak var spectrumStackView: NSStackView!
	
	@IBAction func skipPreviousPressed(_ sender: NSButton) {
		
	}
	
	@IBAction func playPressed(_ sender: NSButton) {
		if isPlaying {
			pause()
		} else {
			play()
		}
	}
	
	@IBAction func skipNextPressed(_ sender: NSButton) {
		
	}
	
	@IBAction func songPopupSelectionButtonPressed(_ sender: NSPopUpButton) {
		stop()
		let song = songs[sender.indexOfSelectedItem]
		begin(file: song.location!)
		
		play()
		AppDelegate.fan?.send(text: friendlyDescriptionForMedia(song), r: 255, g: 0, b: 255)
	}
	
	override func viewDidLoad() {
        super.viewDidLoad()
		
		AppDelegate.fan?.start()
		
		levels.forEach {
			spectrumStackView.addArrangedSubview($0)
			$0.translatesAutoresizingMaskIntoConstraints = false
			$0.topAnchor.constraint(equalTo: spectrumStackView.topAnchor).isActive = true
			$0.bottomAnchor.constraint(equalTo: spectrumStackView.bottomAnchor).isActive = true
		}
		
		do {
			let library = try ITLibrary(apiVersion: "1.0")
			
			songs = library.allMediaItems
				.filter { $0.location != nil && $0.mediaKind == .kindSong }
				.sorted { $0.artist!.name! < $1.artist!.name! }
			
			songPopupSelectionButton.addItems(withTitles: songs
				.map(friendlyDescriptionForMedia(_:)))
			
			audioEngine.mainMixerNode.installTap(onBus: 0, bufferSize: 1024, format: audioEngine.mainMixerNode.outputFormat(forBus: 0)) { (buffer, time) in
				if time.audioTimeStamp.mSampleTime > self.previousTime + 1 && self.visible {
					let values = fftTransform(buffer: buffer, frameCount: 2048, numberOfBands: 50).map {
						UInt8(max(min(ceil(TempiFFT.toDB($0) / 4), 8), 0))
					}

					DispatchQueue.main.sync {
						AppDelegate.fan?.send(bytes: FanConnection.SerialHeaders.MVIZ_VALUES + values)
						
						values[0..<50].enumerated().forEach { index, level in
							self.levels[index].floatValue = Float(level)
						}
					}

					self.previousTime = time.audioTimeStamp.mSampleTime
				}
			}
			
			begin(file: songs[0].location!)
		} catch let error {
			os_log("%@: Cannot read iTunes Library: %@", type: .error, self.description, error.localizedDescription)
		}
    }
	
	override func viewDidAppear() {
		visible = true
		AppDelegate.fan?.send(bytes: FanConnection.SerialHeaders.MVIZ_PROGRAM_START)
	}
	
	override func viewDidDisappear() {
		visible = false
		pause()
	}
	
	private func begin(file: URL) {
        audioEngine.attach(audioNode)
        
        guard let audioFile = try? AVAudioFile(forReading: file) else {
			os_log("%@: Invalid file: %@", self.description, file.absoluteString)
            return
        }
		
        let buffer = AVAudioPCMBuffer(pcmFormat: audioFile.processingFormat,
                                      frameCapacity: AVAudioFrameCount(audioFile.length))
        try? audioFile.read(into: buffer!)
		
        audioEngine.connect(audioNode, to: audioEngine.mainMixerNode, format: buffer?.format)
        audioNode.scheduleBuffer(buffer!, at: nil, options: .loops, completionHandler: nil)
		
		previousTime = 0
		
		do {
            try audioEngine.start()
        }
        catch {
            os_log("%@: Error starting audio engine: %@", type: .error, self.description, error.localizedDescription)
        }
    }
	
	private func play() {
		isPlaying = true
		playButton.image = NSImage(named: "NSTouchBarPauseTemplate")
		audioNode.play()
	}
	
	private func pause() {
		isPlaying = false
		playButton.image = NSImage(named: "NSTouchBarPlayTemplate")
		audioNode.pause()
	}
	
	private func stop() {
		pause()
        audioEngine.detach(audioNode)
		audioEngine.reset()
	}
	
	private func friendlyDescriptionForMedia(_ media: ITLibMediaItem) -> String {
		return "\(media.artist!.name!) - \(media.title)"
	}

}
