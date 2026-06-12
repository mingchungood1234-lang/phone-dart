import 'dart:async';

import 'package:flutter/material.dart';

void main() {
  runApp(const PhoneDartApp());
}

enum CallState { idle, ringing, connected, ended }

enum CallQuality { excellent, stable, weak }

class IncomingCall {
  const IncomingCall({
    required this.callerName,
    required this.callerNumber,
    required this.avatarLabel,
    required this.route,
    required this.quality,
  });

  final String callerName;
  final String callerNumber;
  final String avatarLabel;
  final String route;
  final CallQuality quality;
}

class CallSession extends ChangeNotifier {
  CallState state = CallState.idle;
  IncomingCall? currentCall;
  bool isMuted = false;
  bool isSpeakerOn = true;
  bool isHoldOn = false;
  int elapsedSeconds = 0;
  Timer? _callTimer;

  void simulateIncomingCall() {
    _callTimer?.cancel();
    elapsedSeconds = 0;
    isMuted = false;
    isSpeakerOn = true;
    isHoldOn = false;
    currentCall = const IncomingCall(
      callerName: 'Alicia Tan',
      callerNumber: '+60 12-439 8821',
      avatarLabel: 'AT',
      route: 'Kuala Lumpur edge',
      quality: CallQuality.stable,
    );
    state = CallState.ringing;
    notifyListeners();
  }

  void answer() {
    if (state != CallState.ringing) return;
    state = CallState.connected;
    _callTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      elapsedSeconds += 1;
      notifyListeners();
    });
    notifyListeners();
  }

  void decline() {
    if (state != CallState.ringing) return;
    state = CallState.ended;
    _callTimer?.cancel();
    notifyListeners();
  }

  void endCall() {
    if (state != CallState.connected) return;
    state = CallState.ended;
    _callTimer?.cancel();
    notifyListeners();
  }

  void reset() {
    _callTimer?.cancel();
    elapsedSeconds = 0;
    currentCall = null;
    state = CallState.idle;
    notifyListeners();
  }

  void toggleMute() {
    isMuted = !isMuted;
    notifyListeners();
  }

  void toggleSpeaker() {
    isSpeakerOn = !isSpeakerOn;
    notifyListeners();
  }

  void toggleHold() {
    isHoldOn = !isHoldOn;
    notifyListeners();
  }

  @override
  void dispose() {
    _callTimer?.cancel();
    super.dispose();
  }
}

class PhoneDartApp extends StatefulWidget {
  const PhoneDartApp({super.key});

  @override
  State<PhoneDartApp> createState() => _PhoneDartAppState();
}

class _PhoneDartAppState extends State<PhoneDartApp> {
  late final CallSession session;

  @override
  void initState() {
    super.initState();
    session = CallSession();
  }

  @override
  void dispose() {
    session.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: session,
      builder: (context, _) {
        return MaterialApp(
          title: 'Phone Dart',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF00D7A7),
            ),
            scaffoldBackgroundColor: const Color(0xFF101114),
            useMaterial3: true,
          ),
          home: VoipReceiverHome(session: session),
        );
      },
    );
  }
}

class VoipReceiverHome extends StatelessWidget {
  const VoipReceiverHome({required this.session, super.key});

  final CallSession session;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 280),
          child: switch (session.state) {
            CallState.idle => ReceiverHome(
              key: const ValueKey('idle'),
              session: session,
            ),
            CallState.ringing => IncomingCallView(
              key: const ValueKey('ringing'),
              session: session,
            ),
            CallState.connected => ActiveCallView(
              key: const ValueKey('connected'),
              session: session,
            ),
            CallState.ended => CallEndedView(
              key: const ValueKey('ended'),
              session: session,
            ),
          },
        ),
      ),
    );
  }
}

class ReceiverHome extends StatelessWidget {
  const ReceiverHome({required this.session, super.key});

  final CallSession session;

  @override
  Widget build(BuildContext context) {
    return _CoolBackground(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
        children: [
          _HomeHeader(session: session),
          const SizedBox(height: 28),
          _HeroDialCard(session: session),
          const SizedBox(height: 18),
          const _SignalRow(),
          const SizedBox(height: 18),
          const _RecentCallers(),
          const SizedBox(height: 18),
          _RingButton(session: session),
        ],
      ),
    );
  }
}

class IncomingCallView extends StatelessWidget {
  const IncomingCallView({required this.session, super.key});

  final CallSession session;

  @override
  Widget build(BuildContext context) {
    final call = session.currentCall!;

    return _CoolBackground(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 28, 22, 28),
        child: Column(
          children: [
            const _RingingIndicator(),
            const Spacer(),
            _RingingAvatar(label: call.avatarLabel),
            const SizedBox(height: 28),
            Text(
              call.callerName,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 36,
                fontWeight: FontWeight.w900,
                height: 1.05,
              ),
            ),
            const SizedBox(height: 9),
            Text(
              call.callerNumber,
              style: const TextStyle(color: Color(0xFFD0DED9), fontSize: 18),
            ),
            const SizedBox(height: 18),
            _RouteBadge(route: call.route, quality: call.quality),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _RoundCallButton(
                  tooltip: 'Decline call',
                  label: 'Decline',
                  icon: Icons.call_end,
                  color: const Color(0xFFFF4D5D),
                  onPressed: session.decline,
                ),
                _RoundCallButton(
                  tooltip: 'Answer call',
                  label: 'Answer',
                  icon: Icons.call,
                  color: const Color(0xFF00D7A7),
                  onPressed: session.answer,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class ActiveCallView extends StatelessWidget {
  const ActiveCallView({required this.session, super.key});

  final CallSession session;

  @override
  Widget build(BuildContext context) {
    final call = session.currentCall!;

    return _CoolBackground(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(22, 24, 22, 24),
        children: [
          _ActiveStatusBar(
            isHoldOn: session.isHoldOn,
            elapsedSeconds: session.elapsedSeconds,
          ),
          const SizedBox(height: 42),
          Center(child: _CallerAvatar(label: call.avatarLabel, size: 124)),
          const SizedBox(height: 22),
          Text(
            call.callerName,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 33,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            call.callerNumber,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFFD0DED9), fontSize: 17),
          ),
          const SizedBox(height: 16),
          Center(
            child: _RouteBadge(route: call.route, quality: call.quality),
          ),
          const SizedBox(height: 34),
          _ControlDeck(session: session),
          const SizedBox(height: 26),
          Center(
            child: _RoundCallButton(
              tooltip: 'End call',
              label: 'End',
              icon: Icons.call_end,
              color: const Color(0xFFFF4D5D),
              onPressed: session.endCall,
            ),
          ),
        ],
      ),
    );
  }
}

class CallEndedView extends StatelessWidget {
  const CallEndedView({required this.session, super.key});

  final CallSession session;

  @override
  Widget build(BuildContext context) {
    final call = session.currentCall;

    return _CoolBackground(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 94,
              height: 94,
              decoration: BoxDecoration(
                color: const Color(0xFFFF4D5D),
                borderRadius: BorderRadius.circular(32),
              ),
              child: const Icon(Icons.call_end, size: 42, color: Colors.white),
            ),
            const SizedBox(height: 24),
            const Text(
              'Call ended',
              style: TextStyle(
                color: Colors.white,
                fontSize: 30,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              call == null
                  ? 'Ready for the next ring.'
                  : '${call.callerName} is no longer connected.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFFD0DED9), fontSize: 16),
            ),
            const SizedBox(height: 30),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF00D7A7),
                foregroundColor: const Color(0xFF081311),
                minimumSize: const Size(210, 56),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              onPressed: session.reset,
              icon: const Icon(Icons.phone_callback),
              label: const Text(
                'Back to phone',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CoolBackground extends StatelessWidget {
  const _CoolBackground({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF101114), Color(0xFF173834), Color(0xFF151414)],
        ),
      ),
      child: child,
    );
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({required this.session});

  final CallSession session;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
          ),
          child: const Icon(Icons.phone_in_talk, color: Color(0xFF5FE7C3)),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Phone Dart',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                'Your VoIP line is live',
                style: TextStyle(color: Color(0xFFB9C7C3), fontSize: 14),
              ),
            ],
          ),
        ),
        IconButton.filled(
          style: IconButton.styleFrom(
            backgroundColor: const Color(0xFFFF6B6B),
            foregroundColor: Colors.white,
          ),
          tooltip: 'Simulate incoming call',
          onPressed: session.simulateIncomingCall,
          icon: const Icon(Icons.add_call),
        ),
      ],
    );
  }
}

class _HeroDialCard extends StatelessWidget {
  const _HeroDialCard({required this.session});

  final CallSession session;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 24, 22, 22),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Ready for calls',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 34,
                    fontWeight: FontWeight.w900,
                    height: 1.02,
                  ),
                ),
              ),
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFD166),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(
                  Icons.wifi_calling_3,
                  color: Color(0xFF101114),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          const _Waveform(),
          const SizedBox(height: 24),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(58),
              backgroundColor: const Color(0xFF00D7A7),
              foregroundColor: const Color(0xFF081311),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
            onPressed: session.simulateIncomingCall,
            icon: const Icon(Icons.call_received),
            label: const Text(
              'Preview incoming call',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
    );
  }
}

class _Waveform extends StatelessWidget {
  const _Waveform();

  @override
  Widget build(BuildContext context) {
    const heights = [20.0, 38.0, 28.0, 58.0, 42.0, 72.0, 34.0, 48.0, 24.0];

    return SizedBox(
      height: 88,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          for (final height in heights)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Center(
                  child: Container(
                    height: height,
                    decoration: BoxDecoration(
                      color: height > 50
                          ? const Color(0xFFFF6B6B)
                          : const Color(0xFF5FE7C3),
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SignalRow extends StatelessWidget {
  const _SignalRow();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: const [
        Expanded(
          child: _SignalTile(
            icon: Icons.lock,
            value: 'SRTP',
            label: 'secure voice',
            color: Color(0xFF5FE7C3),
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: _SignalTile(
            icon: Icons.flash_on,
            value: '24 ms',
            label: 'low latency',
            color: Color(0xFFFFD166),
          ),
        ),
      ],
    );
  }
}

class _SignalTile extends StatelessWidget {
  const _SignalTile({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Color(0xFFB9C7C3)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RecentCallers extends StatelessWidget {
  const _RecentCallers();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F2E8),
        borderRadius: BorderRadius.circular(26),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Recent callers',
            style: TextStyle(
              color: Color(0xFF101114),
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: const [
              _MiniContact(
                label: 'AT',
                name: 'Alicia',
                color: Color(0xFFFFD166),
              ),
              SizedBox(width: 10),
              _MiniContact(
                label: 'KM',
                name: 'Kumar',
                color: Color(0xFF5FE7C3),
              ),
              SizedBox(width: 10),
              _MiniContact(
                label: 'SN',
                name: 'Sofia',
                color: Color(0xFFFF8A65),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniContact extends StatelessWidget {
  const _MiniContact({
    required this.label,
    required this.name,
    required this.color,
  });

  final String label;
  final String name;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        height: 118,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _CallerAvatar(label: label, size: 48, color: color),
            const SizedBox(height: 10),
            Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
          ],
        ),
      ),
    );
  }
}

class _RingButton extends StatelessWidget {
  const _RingButton({required this.session});

  final CallSession session;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      style: FilledButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF101114),
        minimumSize: const Size.fromHeight(72),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        padding: const EdgeInsets.symmetric(horizontal: 18),
      ),
      onPressed: session.simulateIncomingCall,
      child: Row(
        children: [
          const _CallerAvatar(label: 'AT', size: 48, color: Color(0xFFFFD166)),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Ring the phone',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
            ),
          ),
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFF00D7A7),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.call_received, color: Color(0xFF081311)),
          ),
        ],
      ),
    );
  }
}

class _ActiveStatusBar extends StatelessWidget {
  const _ActiveStatusBar({
    required this.isHoldOn,
    required this.elapsedSeconds,
  });

  final bool isHoldOn;
  final int elapsedSeconds;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.13)),
      ),
      child: Row(
        children: [
          const Icon(Icons.lock, size: 18, color: Color(0xFF5FE7C3)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              isHoldOn ? 'Call on hold' : 'Encrypted VoIP call',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Text(
            _formatDuration(elapsedSeconds),
            style: const TextStyle(
              color: Color(0xFFFFD166),
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _ControlDeck extends StatelessWidget {
  const _ControlDeck({required this.session});

  final CallSession session;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 3,
          mainAxisSpacing: 14,
          crossAxisSpacing: 12,
          childAspectRatio: 0.92,
          children: [
            _CallControlButton(
              tooltip: session.isMuted ? 'Unmute' : 'Mute',
              label: 'Mute',
              icon: session.isMuted ? Icons.mic_off : Icons.mic,
              isSelected: session.isMuted,
              onPressed: session.toggleMute,
            ),
            _CallControlButton(
              tooltip: session.isSpeakerOn ? 'Speaker off' : 'Speaker on',
              label: 'Speaker',
              icon: session.isSpeakerOn ? Icons.volume_up : Icons.volume_off,
              isSelected: session.isSpeakerOn,
              onPressed: session.toggleSpeaker,
            ),
            _CallControlButton(
              tooltip: session.isHoldOn ? 'Resume call' : 'Hold call',
              label: 'Hold',
              icon: session.isHoldOn ? Icons.play_arrow : Icons.pause,
              isSelected: session.isHoldOn,
              onPressed: session.toggleHold,
            ),
          ],
        ),
      ),
    );
  }
}

class _CallerAvatar extends StatelessWidget {
  const _CallerAvatar({
    required this.label,
    required this.size,
    this.color = const Color(0xFFFFD166),
  });

  final String label;
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(size * 0.34),
        border: Border.all(
          color: Colors.white.withValues(alpha: size > 80 ? 0.84 : 1),
          width: size > 80 ? 4 : 2,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: const Color(0xFF101114),
          fontSize: size * 0.32,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _RingingAvatar extends StatelessWidget {
  const _RingingAvatar({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 176,
          height: 176,
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0x665FE7C3), width: 2),
            borderRadius: BorderRadius.circular(60),
          ),
        ),
        Container(
          width: 146,
          height: 146,
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0x66FFD166), width: 2),
            borderRadius: BorderRadius.circular(50),
          ),
        ),
        _CallerAvatar(label: label, size: 116),
      ],
    );
  }
}

class _RingingIndicator extends StatefulWidget {
  const _RingingIndicator();

  @override
  State<_RingingIndicator> createState() => _RingingIndicatorState();
}

class _RingingIndicatorState extends State<_RingingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController controller;

  @override
  void initState() {
    super.initState();
    controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween<double>(begin: 0.45, end: 1).animate(controller),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.call_received, color: Color(0xFF5FE7C3)),
            SizedBox(width: 8),
            Text(
              'Incoming VoIP call',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RouteBadge extends StatelessWidget {
  const _RouteBadge({required this.route, required this.quality});

  final String route;
  final CallQuality quality;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (quality) {
      CallQuality.excellent => ('Excellent', const Color(0xFF00D7A7)),
      CallQuality.stable => ('Stable', const Color(0xFF5FE7C3)),
      CallQuality.weak => ('Weak', const Color(0xFFFFD166)),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
      ),
      child: Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 8,
        runSpacing: 4,
        children: [
          Icon(Icons.network_check, size: 18, color: color),
          Text(
            label,
            style: TextStyle(color: color, fontWeight: FontWeight.w900),
          ),
          Text(route, style: const TextStyle(color: Color(0xFFD0DED9))),
        ],
      ),
    );
  }
}

class _RoundCallButton extends StatelessWidget {
  const _RoundCallButton({
    required this.tooltip,
    required this.label,
    required this.icon,
    required this.color,
    required this.onPressed,
  });

  final String tooltip;
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Tooltip(
          message: tooltip,
          child: SizedBox(
            width: 76,
            height: 76,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: color,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
                padding: EdgeInsets.zero,
              ),
              onPressed: onPressed,
              child: Icon(
                icon,
                color: color == const Color(0xFF00D7A7)
                    ? const Color(0xFF081311)
                    : Colors.white,
                size: 30,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _CallControlButton extends StatelessWidget {
  const _CallControlButton({
    required this.tooltip,
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onPressed,
  });

  final String tooltip;
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: FilledButton.tonal(
        style: FilledButton.styleFrom(
          backgroundColor: isSelected
              ? const Color(0xFF00D7A7)
              : Colors.white.withValues(alpha: 0.12),
          foregroundColor: isSelected ? const Color(0xFF081311) : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 8),
        ),
        onPressed: onPressed,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 28),
            const SizedBox(height: 8),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
          ],
        ),
      ),
    );
  }
}

String _formatDuration(int totalSeconds) {
  final minutes = (totalSeconds ~/ 60).toString().padLeft(2, '0');
  final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
  return '$minutes:$seconds';
}
