import 'package:flutter/material.dart';

import 'device_settings.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _controller = TextEditingController();
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    DeviceSettings.getHost().then((host) {
      if (!mounted) return;
      setState(() {
        _controller.text = host;
        _loading = false;
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final value = _controller.text.trim();
    if (value.isEmpty) return;
    await DeviceSettings.setHost(value);
    if (!mounted) return;
    Navigator.of(context).pop(value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Device settings'),
        backgroundColor: Colors.red.shade500,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Hostname or IP for the gif-buddy device. Use '
                    '"gif-buddy.local" if mDNS works on your network, '
                    'otherwise enter the device IP (e.g. 192.168.1.50).',
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _controller,
                    autocorrect: false,
                    decoration: const InputDecoration(
                      labelText: 'Host',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _save(),
                  ),
                  const SizedBox(height: 16),
                  FilledButton(onPressed: _save, child: const Text('Save')),
                ],
              ),
            ),
    );
  }
}
