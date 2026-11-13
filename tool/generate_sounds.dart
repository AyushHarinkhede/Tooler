import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

void main() {
  final outputDir = Directory('assets/sounds');
  if (!outputDir.existsSync()) {
    outputDir.createSync(recursive: true);
  }

  print('Generating high-definition audio assets...');
  generateClick('${outputDir.path}/click.wav');
  generateKey('${outputDir.path}/key.wav');
  generateTap('${outputDir.path}/tap.wav');
  generateSuccess('${outputDir.path}/success.wav');
  generateAlert('${outputDir.path}/alert.wav');
  generateAlarm('${outputDir.path}/alarm.wav');
  print('All sound assets generated successfully!');
}

Uint8List createWavHeader(int dataLength, int sampleRate, int channels, int bitsPerSample) {
  final byteRate = sampleRate * channels * (bitsPerSample ~/ 8);
  final blockAlign = channels * (bitsPerSample ~/ 8);
  final totalLength = 36 + dataLength;

  final header = ByteData(44);
  // RIFF chunk descriptor
  header.setUint8(0, 0x52); // 'R'
  header.setUint8(1, 0x49); // 'I'
  header.setUint8(2, 0x46); // 'F'
  header.setUint8(3, 0x46); // 'F'
  header.setUint32(4, totalLength, Endian.little);
  header.setUint8(8, 0x57);  // 'W'
  header.setUint8(9, 0x41);  // 'A'
  header.setUint8(10, 0x56); // 'V'
  header.setUint8(11, 0x45); // 'E'

  // 'fmt ' subchunk
  header.setUint8(12, 0x66); // 'f'
  header.setUint8(13, 0x6D); // 'm'
  header.setUint8(14, 0x74); // 't'
  header.setUint8(15, 0x20); // ' '
  header.setUint32(16, 16, Endian.little); // Subchunk1Size (16 for PCM)
  header.setUint16(20, 1, Endian.little);  // AudioFormat (1 for PCM)
  header.setUint16(22, channels, Endian.little);
  header.setUint32(24, sampleRate, Endian.little);
  header.setUint32(28, byteRate, Endian.little);
  header.setUint16(32, blockAlign, Endian.little);
  header.setUint16(34, bitsPerSample, Endian.little);

  // 'data' subchunk
  header.setUint8(36, 0x64); // 'd'
  header.setUint8(37, 0x61); // 'a'
  header.setUint8(38, 0x74); // 't'
  header.setUint8(39, 0x61); // 'a'
  header.setUint32(40, dataLength, Endian.little);

  return header.buffer.asUint8List();
}

void writeWavFile(String path, List<double> samples, int sampleRate) {
  final bytes = BytesBuilder();
  final dataLength = samples.length * 2;
  bytes.add(createWavHeader(dataLength, sampleRate, 1, 16));

  final sampleBytes = ByteData(samples.length * 2);
  for (int i = 0; i < samples.length; i++) {
    final clamped = samples[i].clamp(-1.0, 1.0);
    final intVal = (clamped * 32767.0).round();
    sampleBytes.setInt16(i * 2, intVal, Endian.little);
  }
  bytes.add(sampleBytes.buffer.asUint8List());

  File(path).writeAsBytesSync(bytes.toBytes());
  print('Saved $path (${samples.length} samples, ${(samples.length / sampleRate * 1000).toStringAsFixed(1)}ms)');
}

/// Snappy, crisp modern UI click (glassy acoustic transient)
void generateClick(String path) {
  const sampleRate = 44100;
  const durationSec = 0.028; // 28ms
  final numSamples = (sampleRate * durationSec).round();
  final samples = List<double>.filled(numSamples, 0.0);

  double phase = 0.0;
  for (int i = 0; i < numSamples; i++) {
    final t = i / sampleRate;
    // Pitch sweep from 2400Hz down to 700Hz
    final freq = 700.0 + 1700.0 * exp(-t / 0.004);
    phase += 2.0 * pi * freq / sampleRate;

    // Fast attack (0.8ms), exponential decay (tau = 4.5ms)
    final attack = (t / 0.0008).clamp(0.0, 1.0);
    final decay = exp(-t / 0.0045);
    final env = attack * decay;

    // Subtle harmonic overtone for warmth
    final val = sin(phase) * 0.75 + sin(phase * 1.6) * 0.25;
    samples[i] = val * env * 0.95;
  }

  writeWavFile(path, samples, sampleRate);
}

/// Satisfying mechanical keyboard / calculator key click
void generateKey(String path) {
  const sampleRate = 44100;
  const durationSec = 0.035; // 35ms
  final numSamples = (sampleRate * durationSec).round();
  final samples = List<double>.filled(numSamples, 0.0);

  double phase1 = 0.0;
  double phase2 = 0.0;
  for (int i = 0; i < numSamples; i++) {
    final t = i / sampleRate;

    // Dual frequency tactile mechanical thump + click
    final freq1 = 480.0 + 900.0 * exp(-t / 0.006);
    final freq2 = 1800.0 * exp(-t / 0.003);
    phase1 += 2.0 * pi * freq1 / sampleRate;
    phase2 += 2.0 * pi * freq2 / sampleRate;

    final attack = (t / 0.0007).clamp(0.0, 1.0);
    final decay1 = exp(-t / 0.0075);
    final decay2 = exp(-t / 0.0035);

    final val = (sin(phase1) * decay1 * 0.65) + (sin(phase2) * decay2 * 0.35);
    samples[i] = val * attack * 0.95;
  }

  writeWavFile(path, samples, sampleRate);
}

/// Soft touch tap for subtle UI controls
void generateTap(String path) {
  const sampleRate = 44100;
  const durationSec = 0.020; // 20ms
  final numSamples = (sampleRate * durationSec).round();
  final samples = List<double>.filled(numSamples, 0.0);

  double phase = 0.0;
  for (int i = 0; i < numSamples; i++) {
    final t = i / sampleRate;
    final freq = 550.0 * exp(-t / 0.007);
    phase += 2.0 * pi * freq / sampleRate;

    final attack = (t / 0.001).clamp(0.0, 1.0);
    final decay = exp(-t / 0.005);
    samples[i] = sin(phase) * attack * decay * 0.85;
  }

  writeWavFile(path, samples, sampleRate);
}

/// Bright, cheerful 3-note ascending chime (C5 -> E5 -> G5)
void generateSuccess(String path) {
  const sampleRate = 44100;
  const durationSec = 0.42; // 420ms
  final numSamples = (sampleRate * durationSec).round();
  final samples = List<double>.filled(numSamples, 0.0);

  // Note parameters: [startSec, freq, tau, amplitude]
  final notes = [
    [0.00, 523.25, 0.14, 0.65], // C5
    [0.08, 659.25, 0.16, 0.70], // E5
    [0.16, 783.99, 0.22, 0.85], // G5
    [0.22, 1046.50, 0.18, 0.35], // C6 overtone sparkle
  ];

  for (final n in notes) {
    final startT = n[0];
    final freq = n[1];
    final tau = n[2];
    final amp = n[3];

    final startIdx = (startT * sampleRate).round();
    double phase = 0.0;
    for (int i = startIdx; i < numSamples; i++) {
      final t = (i - startIdx) / sampleRate;
      phase += 2.0 * pi * freq / sampleRate;

      final attack = (t / 0.004).clamp(0.0, 1.0);
      final decay = exp(-t / tau);
      // Bell harmonics
      final wave = sin(phase) + 0.25 * sin(phase * 2.0) + 0.10 * sin(phase * 3.0);
      samples[i] += wave * attack * decay * amp * 0.45;
    }
  }

  writeWavFile(path, samples, sampleRate);
}

/// Clean 2-note attention chime (E5 -> A5)
void generateAlert(String path) {
  const sampleRate = 44100;
  const durationSec = 0.28; // 280ms
  final numSamples = (sampleRate * durationSec).round();
  final samples = List<double>.filled(numSamples, 0.0);

  final notes = [
    [0.00, 659.25, 0.12, 0.70], // E5
    [0.06, 880.00, 0.18, 0.85], // A5
    [0.09, 1318.50, 0.12, 0.25], // E6 harmonic
  ];

  for (final n in notes) {
    final startT = n[0];
    final freq = n[1];
    final tau = n[2];
    final amp = n[3];

    final startIdx = (startT * sampleRate).round();
    double phase = 0.0;
    for (int i = startIdx; i < numSamples; i++) {
      final t = (i - startIdx) / sampleRate;
      phase += 2.0 * pi * freq / sampleRate;

      final attack = (t / 0.003).clamp(0.0, 1.0);
      final decay = exp(-t / tau);
      final wave = sin(phase) + 0.20 * sin(phase * 2.0);
      samples[i] += wave * attack * decay * amp * 0.50;
    }
  }

  writeWavFile(path, samples, sampleRate);
}

/// Loud, authoritative, professional digital alarm & wake chime (4 urgent beeps + resonant chord)
/// Tuned to 1kHz-3kHz human acoustic sensitivity zone for high penetration through phone speakers.
void generateAlarm(String path) {
  const sampleRate = 44100;
  const durationSec = 1.08; // 1080ms total cycle
  final numSamples = (sampleRate * durationSec).round();
  final samples = List<double>.filled(numSamples, 0.0);

  // 4 Urgent Beep Bursts: [startT, endT, f1, f2, f3, amp]
  final bursts = [
    [0.00, 0.09, 2093.00, 1046.50, 3139.50, 0.95], // Beep 1 (C7 + C6 + G7)
    [0.13, 0.22, 2093.00, 1046.50, 3139.50, 0.95], // Beep 2
    [0.26, 0.35, 2093.00, 1046.50, 3139.50, 0.95], // Beep 3
    [0.39, 0.62, 2349.32, 1174.66, 3523.98, 0.98], // Beep 4 (D7 + D6, longer accented chord)
  ];

  for (final b in bursts) {
    final startT = b[0];
    final endT = b[1];
    final f1 = b[2];
    final f2 = b[3];
    final f3 = b[4];
    final peakAmp = b[5];

    final startIdx = (startT * sampleRate).round();
    final endIdx = (endT * sampleRate).round().clamp(0, numSamples);
    final burstLen = endIdx - startIdx;

    double phase1 = 0.0;
    double phase2 = 0.0;
    double phase3 = 0.0;

    for (int i = startIdx; i < endIdx; i++) {
      final t = (i - startIdx) / sampleRate;
      final dur = (endT - startT);
      phase1 += 2.0 * pi * f1 / sampleRate;
      phase2 += 2.0 * pi * f2 / sampleRate;
      phase3 += 2.0 * pi * f3 / sampleRate;

      // Fast punchy attack (1.5ms) and gentle release
      final attack = (t / 0.0015).clamp(0.0, 1.0);
      final decay = ((dur - t) / 0.015).clamp(0.0, 1.0);
      final sustain = exp(-t / (dur * 1.8));

      // Rich harmonics with dual sub-octave and third harmonic
      final wave = (sin(phase1) * 0.52) +
          (sin(phase2) * 0.33) +
          (sin(phase3) * 0.15);

      samples[i] += wave * attack * decay * sustain * peakAmp;
    }
  }

  // Harmonic resonance echo tail on 4th beep (reverberant chime)
  final tailStartIdx = (0.39 * sampleRate).round();
  final tailEndIdx = (0.95 * sampleRate).round();
  double bellPhase = 0.0;
  for (int i = tailStartIdx; i < tailEndIdx; i++) {
    final t = (i - tailStartIdx) / sampleRate;
    bellPhase += 2.0 * pi * 1760.0 / sampleRate; // A6 warm chime resonance
    final decay = exp(-t / 0.18);
    samples[i] += sin(bellPhase) * decay * 0.22;
  }

  writeWavFile(path, samples, sampleRate);
}
