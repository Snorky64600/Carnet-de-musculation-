import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';

class ChronoScreen extends StatefulWidget {
  const ChronoScreen({Key? key}) : super(key: key);
  @override
  State<ChronoScreen> createState() => _ChronoScreenState();
}

class _ChronoScreenState extends State<ChronoScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final Stopwatch _stopwatch = Stopwatch();
  Timer? _stopwatchTimer;
  Timer? _countdownTimer;
  int _countdownSeconds = 90;
  int _currentCountdown = 90;
  bool _isCountdownRunning = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _stopwatchTimer?.cancel();
    _countdownTimer?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  void _startStopwatch() {
    HapticFeedback.mediumImpact();
    if (!_stopwatch.isRunning) {
      _stopwatch.start();
      _stopwatchTimer = Timer.periodic(const Duration(milliseconds: 100), (_) => setState(() {}));
    }
  }

  void _pauseStopwatch() {
    HapticFeedback.mediumImpact();
    if (_stopwatch.isRunning) {
      _stopwatch.stop();
      _stopwatchTimer?.cancel();
      setState(() {});
    }
  }

  void _stopAndResetStopwatch() {
    HapticFeedback.heavyImpact();
    _stopwatch.stop();
    _stopwatchTimer?.cancel();
    _stopwatch.reset();
    setState(() {});
  }

  void _startCountdown(int seconds) {
    HapticFeedback.mediumImpact();
    _countdownTimer?.cancel();
    setState(() {
      _countdownSeconds = seconds;
      _currentCountdown = seconds;
      _isCountdownRunning = true;
    });
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_currentCountdown > 0) {
        setState(() => _currentCountdown--);
      } else {
        _countdownTimer?.cancel();
        setState(() => _isCountdownRunning = false);
      }
    });
  }

  void _pauseCountdown() {
    HapticFeedback.mediumImpact();
    _countdownTimer?.cancel();
    setState(() => _isCountdownRunning = false);
  }

  void _resetCountdown() {
    HapticFeedback.heavyImpact();
    _countdownTimer?.cancel();
    setState(() {
      _currentCountdown = _countdownSeconds;
      _isCountdownRunning = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chronométrage'),
        backgroundColor: Colors.transparent,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF10B981),
          labelColor: const Color(0xFF10B981),
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(text: 'Chronomètre (Gainage)'),
            Tab(text: 'Minuteur de Repos'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _formatStopwatchTime(_stopwatch.elapsed),
                  style: const TextStyle(fontSize: 65, fontWeight: FontWeight.bold, color: Color(0xFF10B981)),
                ),
                const SizedBox(height: 50),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _startStopwatch,
                        icon: const Icon(Icons.play_arrow, color: Colors.white),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        label: const Text('Play', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _pauseStopwatch,
                        icon: const Icon(Icons.pause, color: Colors.white),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFF59E0B),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        label: const Text('Pause', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _stopAndResetStopwatch,
                        icon: const Icon(Icons.stop, color: Colors.white),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFEF4444),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        label: const Text('Stop & Reset', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${(_currentCountdown ~/ 60).toString().padLeft(2, '0')}:${(_currentCountdown % 60).toString().padLeft(2, '0')}',
                  style: const TextStyle(fontSize: 75, fontWeight: FontWeight.bold, color: Color(0xFF0D9488)),
                ),
                const SizedBox(height: 25),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: [30, 60, 90, 180, 300].map((sec) {
                    bool isSelected = _countdownSeconds == sec;
                    return OutlinedButton(
                      onPressed: () {
                        HapticFeedback.selectionClick();
                        setState(() {
                          _countdownSeconds = sec;
                          _currentCountdown = sec;
                          _isCountdownRunning = false;
                          _countdownTimer?.cancel();
                        });
                      },
                      style: OutlinedButton.styleFrom(
                        backgroundColor: isSelected ? const Color(0xFF0D9488).withOpacity(0.3) : Colors.transparent,
                        side: BorderSide(color: isSelected ? const Color(0xFF0D9488) : Colors.grey),
                      ),
                      child: Text('${sec}s', style: TextStyle(color: isSelected ? const Color(0xFF10B981) : Theme.of(context).textTheme.bodyLarge?.color)),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 40),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isCountdownRunning ? _pauseCountdown : () => _startCountdown(_currentCountdown),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isCountdownRunning ? const Color(0xFFF59E0B) : const Color(0xFF10B981),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text(_isCountdownRunning ? 'Pause' : 'Lancer', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _resetCountdown,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFEF4444),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Réinitialiser', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatStopwatchTime(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    final tenths = (duration.inMilliseconds.remainder(1000) ~/ 100);
    return '$minutes:$seconds.$tenths';
  }
}
