//
//  FFT.swift
//  aurorafan-companion-mac
//
//  Created by Michael Pavkovic on 12/13/19.
//  Copyright © 2019 AuroraFan. All rights reserved.
//

import Accelerate
import AVFoundation

func fftTransform(buffer: AVAudioPCMBuffer, frameCount: Int, numberOfBands: Int) -> [Float] {
	assert(frameCount >= 512, "Frame count must be >= 512!")
	
	let log2n = UInt(round(log2(Double(frameCount))))
	let windowSize = Int(1 << log2n)
	
	var transferBuffer = [Float](repeating: 0, count: windowSize)
	var window = [Float](repeating: 0, count: windowSize)
	
	vDSP_hann_window(&window, vDSP_Length(windowSize), Int32(vDSP_HANN_NORM))
	vDSP_vmul((buffer.floatChannelData?.pointee)!, 1, window, 1, &transferBuffer, 1, vDSP_Length(windowSize))
	
	let fft = TempiFFT(withSize: 512, sampleRate: 44100.0)
	fft.windowType = TempiFFTWindowType.hanning
	fft.fftForward(transferBuffer)
	
	fft.calculateLinearBands(minFrequency: 0, maxFrequency: 10000, numberOfBands: numberOfBands)
	
	return fft.bandMagnitudes
}
