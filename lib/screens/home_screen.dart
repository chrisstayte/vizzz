import 'dart:async';
import 'dart:math';
import 'package:fftea/fftea.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:vizzz/screens/info_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  StreamSubscription<Food>? _recordingSubscription;
  final _spots = StreamController<List<FlSpot>>.broadcast();
  final _fftSpots = StreamController<List<FlSpot>>.broadcast();
  final int _samplesPerSecond = 44100;
  double _maxTimeValue = 1;
  double _maxFFTValue = 1;

  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);

    startRecorder();
    super.initState();
  }

  @override
  void dispose() async {
    WidgetsBinding.instance.removeObserver(this);
    stopRecorder();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
        stopRecorder();
        break;
      case AppLifecycleState.resumed:
        startRecorder();
        break;
    }

    super.didChangeAppLifecycleState(state);
  }

  Future<void> startRecorder() async {
    var status = await Permission.microphone.request();
    if (status.isGranted) {
      _recorder.openRecorder().then((value) async {
        var recordingDataController = StreamController<Food>();
        _recordingSubscription =
            recordingDataController.stream.listen((buffer) {
          if (buffer is FoodData) {
            _processAudio(buffer.data!);
          }
        });
        await _recorder.startRecorder(
          toStream: recordingDataController.sink,
          codec: Codec.pcm16,
          numChannels: 1,
          sampleRate: _samplesPerSecond,
        );
      });
    }
  }

  bool _mutex = false;
  static FFT? _fft;
  void _processAudio(Uint8List f) async {
    if (_mutex) return;
    _mutex = true;
    final computedData = await compute<List, List>((List f) {
      final data = _calculateWaveSamples(f[0]);
      double maxTimeValue = f[1];
      double maxFFTValue = f[2];
      final sampleRate = (f[3] as int).toDouble();
      int initialPowerOfTwo = (log(data.length) * log2e).ceil();
      int samplesFinalLength = pow(2, initialPowerOfTwo).toInt();
      _fft ??= FFT(data.length);
      final fftSamples = _fft!.realFft(data).magnitudes();
      final deltaTime = 1E6 / (sampleRate * fftSamples.length);
      final timeSpots = List<FlSpot>.generate(data.length, (n) {
        final y = data[n];
        maxTimeValue = max(maxTimeValue, y);
        return FlSpot(n * deltaTime, y);
      });
      final deltaFrequency = sampleRate / fftSamples.length;
      final frequencySpots = List<FlSpot>.generate(
        1 + fftSamples.length ~/ 2,
        (n) {
          double y = fftSamples[n].abs();
          maxFFTValue = max(maxFFTValue, y);
          return FlSpot(n * deltaFrequency, y);
        },
      );
      return [maxTimeValue, timeSpots, maxFFTValue, frequencySpots];
    }, [f, _maxTimeValue, _maxFFTValue, _samplesPerSecond]);
    _mutex = false;
    _maxTimeValue = computedData[0];

    _spots.add(computedData[1]);
    _maxFFTValue = computedData[2];
    _fftSpots.add(computedData[3]);
  }

  static List<double> _calculateWaveSamples(Uint8List samples) {
    final x = List<double>.filled(samples.length ~/ 2, 0);
    for (int i = 0; i < x.length; i++) {
      int msb = samples[i * 2 + 1];
      int lsb = samples[i * 2];
      if (msb > 128) msb -= 255;
      if (lsb > 128) lsb -= 255;
      x[i] = lsb + msb * 128;
    }
    return x;
  }

  Future<void> pauseRecorder() async {
    if (_recorder.isRecording) {
      await _recorder.pauseRecorder();
    }
  }

  Future<void> stopRecorder() async {
    await _recorder.stopRecorder();
    if (_recordingSubscription != null) {
      _recordingSubscription!.cancel();
      _recordingSubscription = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vizzz'),
        actions: [
          IconButton(
              onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      fullscreenDialog: true,
                      builder: (context) => InfoScreen(),
                    ),
                  ),
              icon: Icon(Icons.info))
        ],
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: StreamBuilder<List<FlSpot>>(
              stream: _spots.stream,
              builder: (context, snapshot) {
                if (snapshot.data == null) {
                  return const Align(
                    alignment: Alignment.bottomCenter,
                    child: Text(
                      'Seems to be an issue!',
                      style: TextStyle(fontSize: 16),
                    ),
                  );
                }

                return AbsorbPointer(
                  child: LineChart(
                    LineChartData(
                      lineBarsData: [
                        LineChartBarData(
                          color: const Color(0xff645DE0),
                          isStrokeCapRound: true,
                          isStrokeJoinRound: true,
                          spots: snapshot.data!,
                          dotData: FlDotData(show: false),
                        )
                      ],
                      maxY: 12000,
                      minY: -12000,
                    ),
                  ),
                );
              },
            ),
          ),
          Expanded(
            child: StreamBuilder<List<FlSpot>>(
              stream: _fftSpots.stream,
              builder: (context, snapshot) {
                if (snapshot.data == null) {
                  return Column(
                    children: [
                      SizedBox(
                        child: OutlinedButton(
                          onPressed: () => openAppSettings(),
                          child: const Text(
                            'Enable Microphone Access',
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                    ],
                  );
                }
                return AbsorbPointer(
                  child: LineChart(
                    LineChartData(
                      lineBarsData: [
                        LineChartBarData(
                          color: const Color(0xff645DE0),
                          isStrokeCapRound: true,
                          isStrokeJoinRound: true,
                          spots: snapshot.data!,
                          dotData: FlDotData(show: false),
                        )
                      ],
                      maxY: _maxFFTValue,
                      minY: 0,
                    ),
                  ),
                );
              },
            ),
          )
        ],
      ),
    );
  }
}
