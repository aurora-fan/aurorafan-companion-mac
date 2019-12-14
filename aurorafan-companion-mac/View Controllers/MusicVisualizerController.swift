//
//  MusicVisualizerController.swift
//  aurorafan-companion-mac
//
//  Created by Michael Pavkovic on 12/13/19.
//  Copyright © 2019 AuroraFan. All rights reserved.
//

import Cocoa
import AVFoundation
import iTunesLibrary
import os.log

class MusicVisualizerController: NSViewController {
	
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
		
		begin(file: songs[sender.indexOfSelectedItem].location!)
		
		play()
	}
	
	override func viewDidLoad() {
        super.viewDidLoad()
		
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
				if time.audioTimeStamp.mSampleTime > self.previousTime + 0.5 {
					let values = fftTransform(buffer: buffer, frameCount: 2048, numberOfBands: 50)

					DispatchQueue.main.sync {
						values[0..<50].enumerated().forEach { index, magnitude in
							self.levels[index].floatValue = ceil(TempiFFT.toDB(magnitude) / 4)
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
