import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';

class SoundSynthesizer {
  static final AudioPlayer _player = AudioPlayer();

  /// Generates a WAV file with a sine wave of the given frequency and duration
  static Future<File> _generateWavFile({
    required double frequency,
    required double durationSeconds,
    required String filename,
    double? endFrequency, // Optional for sweep/siren effects
  }) async {
    final int sampleRate = 22050;
    final int numSamples = (durationSeconds * sampleRate).toInt();
    final int numChannels = 1;
    final int bitsPerSample = 16;
    final int byteRate = sampleRate * numChannels * (bitsPerSample ~/ 8);
    final int blockAlign = numChannels * (bitsPerSample ~/ 8);
    final int subChunk2Size = numSamples * blockAlign;
    final int chunkSize = 36 + subChunk2Size;

    final Uint8List wavHeader = Uint8List(44);
    final ByteData headerData = ByteData.sublistView(wavHeader);

    // RIFF header
    headerData.setUint8(0, 0x52); // R
    headerData.setUint8(1, 0x49); // I
    headerData.setUint8(2, 0x46); // F
    headerData.setUint8(3, 0x46); // F
    headerData.setUint32(4, chunkSize, Endian.little);
    headerData.setUint8(8, 0x57); // W
    headerData.setUint8(9, 0x41); // A
    headerData.setUint8(10, 0x56); // V
    headerData.setUint8(11, 0x45); // E

    // fmt chunk
    headerData.setUint8(12, 0x66); // f
    headerData.setUint8(13, 0x6d); // m
    headerData.setUint8(14, 0x74); // t
    headerData.setUint8(15, 0x20); // space
    headerData.setUint32(16, 16, Endian.little); // subchunk1Size
    headerData.setUint16(20, 1, Endian.little); // audioFormat (PCM)
    headerData.setUint16(22, numChannels, Endian.little);
    headerData.setUint32(24, sampleRate, Endian.little);
    headerData.setUint32(28, byteRate, Endian.little);
    headerData.setUint16(32, blockAlign, Endian.little);
    headerData.setUint16(34, bitsPerSample, Endian.little);

    // data chunk
    headerData.setUint8(36, 0x64); // d
    headerData.setUint8(37, 0x61); // a
    headerData.setUint8(38, 0x74); // t
    headerData.setUint8(39, 0x61); // a
    headerData.setUint32(40, subChunk2Size, Endian.little);

    final Uint8List wavData = Uint8List(44 + subChunk2Size);
    wavData.setRange(0, 44, wavHeader);

    final int bytesPerSample = bitsPerSample ~/ 8;
    double phase = 0.0;

    for (int i = 0; i < numSamples; i++) {
      final double t = i / sampleRate;
      
      // Calculate active frequency (handling sweep/rises)
      double currentFreq = frequency;
      if (endFrequency != null) {
        currentFreq = frequency + (endFrequency - frequency) * (t / durationSeconds);
      }

      // Update phase incrementally to avoid frequency distortion
      phase += 2 * pi * currentFreq / sampleRate;
      final double sample = sin(phase);

      // Scale to 16-bit signed integer (-32768 to 32767)
      final int intSample = (sample * 32767).toInt();
      final int byteOffset = 44 + i * bytesPerSample;
      
      wavData[byteOffset] = intSample & 0xFF;
      wavData[byteOffset + 1] = (intSample >> 8) & 0xFF;
    }

    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}/$filename');
    await file.writeAsBytes(wavData);
    return file;
  }

  /// Synthesizes and plays a single pure frequency tone
  static Future<void> playTone({
    required double frequency,
    required double durationSeconds,
    double? endFrequency,
    String name = 'beep.wav',
  }) async {
    try {
      final file = await _generateWavFile(
        frequency: frequency,
        durationSeconds: durationSeconds,
        endFrequency: endFrequency,
        filename: name,
      );
      await _player.play(DeviceFileSource(file.path));
    } catch (e) {
      debugPrint('Audio synthesis error: $e');
    }
  }

  /// Plays the standard Prepaid transit card double beep: 880Hz for 0.07s, silence, 880Hz for 0.07s
  static Future<void> playSuicaBeep() async {
    // Generate a slightly longer file containing two beeps separated by silence
    final int sampleRate = 22050;
    final double durationSeconds = 0.25;
    final int numSamples = (durationSeconds * sampleRate).toInt();
    final int numChannels = 1;
    final int bitsPerSample = 16;
    final int byteRate = sampleRate * numChannels * (bitsPerSample ~/ 8);
    final int blockAlign = numChannels * (bitsPerSample ~/ 8);
    final int subChunk2Size = numSamples * blockAlign;
    final int chunkSize = 36 + subChunk2Size;

    final Uint8List wavHeader = Uint8List(44);
    final ByteData headerData = ByteData.sublistView(wavHeader);

    // RIFF & fmt chunk settings
    headerData.setUint8(0, 0x52); headerData.setUint8(1, 0x49); headerData.setUint8(2, 0x46); headerData.setUint8(3, 0x46);
    headerData.setUint32(4, chunkSize, Endian.little);
    headerData.setUint8(8, 0x57); headerData.setUint8(9, 0x41); headerData.setUint8(10, 0x56); headerData.setUint8(11, 0x45);
    headerData.setUint8(12, 0x66); headerData.setUint8(13, 0x6d); headerData.setUint8(14, 0x74); headerData.setUint8(15, 0x20);
    headerData.setUint32(16, 16, Endian.little);
    headerData.setUint16(20, 1, Endian.little);
    headerData.setUint16(22, numChannels, Endian.little);
    headerData.setUint32(24, sampleRate, Endian.little);
    headerData.setUint32(28, byteRate, Endian.little);
    headerData.setUint16(32, blockAlign, Endian.little);
    headerData.setUint16(34, bitsPerSample, Endian.little);
    headerData.setUint8(36, 0x64); headerData.setUint8(37, 0x61); headerData.setUint8(38, 0x74); headerData.setUint8(39, 0x61);
    headerData.setUint32(40, subChunk2Size, Endian.little);

    final Uint8List wavData = Uint8List(44 + subChunk2Size);
    wavData.setRange(0, 44, wavHeader);

    final int bytesPerSample = bitsPerSample ~/ 8;
    final double frequency = 880.0;

    for (int i = 0; i < numSamples; i++) {
      final double t = i / sampleRate;
      double sample = 0.0;
      // Beep 1: 0.00s to 0.07s
      // Beep 2: 0.12s to 0.19s
      if ((t >= 0.0 && t <= 0.07) || (t >= 0.12 && t <= 0.19)) {
        sample = sin(2 * pi * frequency * t);
      }

      final int intSample = (sample * 32767).toInt();
      final int byteOffset = 44 + i * bytesPerSample;
      wavData[byteOffset] = intSample & 0xFF;
      wavData[byteOffset + 1] = (intSample >> 8) & 0xFF;
    }

    try {
      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/suica_beep.wav');
      await file.writeAsBytes(wavData);
      await _player.play(DeviceFileSource(file.path));
    } catch (e) {
      debugPrint('Prepaid transit beep error: $e');
    }
  }

  /// Plays a premium rising key unlock chime: sweeps from 1000Hz to 1800Hz over 0.3s
  static Future<void> playUnlockChime() async {
    await playTone(
      frequency: 900,
      endFrequency: 1600,
      durationSeconds: 0.35,
      name: 'unlock_chime.wav',
    );
  }

  /// Plays dial beep tone for the SOS dialer screen
  static Future<void> playDialTone() async {
    await playTone(frequency: 350, endFrequency: 440, durationSeconds: 0.8, name: 'dial_tone.wav');
  }

  /// Plays a standard disconnect tone for SOS call termination
  static Future<void> playDisconnectTone() async {
    await playTone(frequency: 480, durationSeconds: 0.5, name: 'disconnect.wav');
  }
}
