import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../providers/staff_provider.dart';
import '../theme/app_colors.dart';
import 'staff_password_setup_screen.dart';

class StaffWaitingScreen extends ConsumerStatefulWidget {
  final String invitationId;
  final String businessName;
  final String email;

  const StaffWaitingScreen({
    super.key,
    required this.invitationId,
    required this.businessName,
    required this.email,
  });

  @override
  ConsumerState<StaffWaitingScreen> createState() => _StaffWaitingScreenState();
}

class _StaffWaitingScreenState extends ConsumerState<StaffWaitingScreen> {
  RealtimeChannel? _channel;
  String _status = 'awaiting_approval';
  String? _error;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    setState(() {
      _error = null;
    });

    try {
      final staffService = ref.read(staffServiceProvider);
      final result = await staffService.checkInvitationStatus(widget.invitationId);
      
      _handleStatus(result.status);

      if (result.status == 'awaiting_approval') {
        _channel = staffService.subscribeToInvitationStatus(
          widget.invitationId,
          (newStatus) {
            if (mounted) {
              _handleStatus(newStatus);
            }
          },
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceAll('Exception: ', '');
        });
      }
    }
  }

  void _handleStatus(String status) {
    if (status == 'accepted') {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => StaffPasswordSetupScreen(
            invitationId: widget.invitationId,
            email: widget.email,
          ),
        ),
      );
    } else {
      setState(() {
        _status = status;
      });
    }
  }

  @override
  void dispose() {
    if (_channel != null) {
      ref.read(staffServiceProvider).unsubscribeFromInvitationStatus(_channel!);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Status')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: AppColors.statusError),
                const SizedBox(height: 16),
                const Text('Failed to check status', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textGray)),
                const SizedBox(height: 24),
                ElevatedButton(onPressed: _init, child: const Text('Retry')),
              ],
            ),
          ),
        ),
      );
    }

    if (_status == 'declined') {
      return Scaffold(
        appBar: AppBar(title: const Text('Request Declined')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.close, size: 64, color: AppColors.statusError),
                const SizedBox(height: 16),
                Text(
                  'Your request was declined by ${widget.businessName}\'s owner.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
                    child: const Text('Back to Home'),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Pending Approval')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                widget.businessName,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryPurple,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              const CircularProgressIndicator(),
              const SizedBox(height: 24),
              Text(
                'Waiting for ${widget.businessName} to approve your request',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, color: AppColors.textGray),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
