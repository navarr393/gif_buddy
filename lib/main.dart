import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:giphy_picker/giphy_picker.dart';

import 'device_settings.dart';
import 'gif_buddy_client.dart';
import 'settings_screen.dart';

const _giphyApiKey = 'ZwNN1sABFBjnLE3iaVFX8nyUX00YrcI8';
const _maxBytes = 4 * 1024 * 1024;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(home: MyHomePage(title: 'Gif Buddy'));
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  GiphyGif? _gif;
  String _host = DeviceSettings.defaultHost;
  bool? _deviceOnline;

  @override
  void initState() {
    super.initState();
    _loadHostAndPing();
  }

  Future<void> _loadHostAndPing() async {
    final host = await DeviceSettings.getHost();
    if (!mounted) return;
    setState(() => _host = host);
    await _refreshLiveness();
  }

  Future<bool> _refreshLiveness() async {
    final online = await GifBuddyClient(_host).ping();
    if (mounted) setState(() => _deviceOnline = online);
    return online;
  }

  Future<void> _openSettings() async {
    final newHost = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const SettingsScreen()),
    );
    if (newHost != null && newHost != _host) {
      setState(() {
        _host = newHost;
        _deviceOnline = null;
      });
      await _refreshLiveness();
    }
  }

  String? _pickUrl(GiphyGif gif) {
    final original = gif.images.original;
    final downsized = gif.images.downsized;
    final originalSize = int.tryParse(original?.size ?? '');
    if (original?.url != null && (originalSize == null || originalSize <= _maxBytes)) {
      return original!.url;
    }
    if (downsized?.url != null) {
      return downsized!.url;
    }
    return original?.url;
  }

  Future<void> _pickAndSend() async {
    await _refreshLiveness();
    if (!mounted) return;

    final gif = await GiphyPicker.pickGif(context: context, apiKey: _giphyApiKey);
    if (gif == null || !mounted) return;
    setState(() => _gif = gif);

    final url = _pickUrl(gif);
    if (url == null) {
      _showError('No downloadable URL on this GIF.');
      return;
    }

    final client = GifBuddyClient(_host);
    final progress = ValueNotifier<double?>(null);
    _showProgressDialog(progress);

    try {
      final bytes = await client.downloadGif(url);
      if (bytes.length > _maxBytes) {
        final downsizedUrl = gif.images.downsized?.url;
        if (downsizedUrl != null && downsizedUrl != url) {
          final fallback = await client.downloadGif(downsizedUrl);
          if (fallback.length > _maxBytes) {
            throw PayloadTooLargeException(
              'GIF is ${fallback.length} bytes after downsize; device max is $_maxBytes.',
            );
          }
          await client.uploadGif(
            fallback,
            onProgress: (s, t) => progress.value = t > 0 ? s / t : null,
          );
          _dismissDialog();
          _showSuccess(fallback.length);
          return;
        }
        throw PayloadTooLargeException(
          'GIF is ${bytes.length} bytes; device max is $_maxBytes and no downsized variant available.',
        );
      }
      await client.uploadGif(
        bytes,
        onProgress: (s, t) => progress.value = t > 0 ? s / t : null,
      );
      _dismissDialog();
      _showSuccess(bytes.length);
    } on PayloadTooLargeException catch (e) {
      _dismissDialog();
      _showError(e.message);
    } on DeviceUnreachableException catch (e) {
      _dismissDialog();
      _showError(e.message);
    } catch (e) {
      _dismissDialog();
      _showError('Upload failed: $e');
    }
  }

  void _showProgressDialog(ValueListenable<double?> progress) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('Sending to gif-buddy'),
        content: ValueListenableBuilder<double?>(
          valueListenable: progress as ValueNotifier<double?>,
          builder: (_, value, _) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              LinearProgressIndicator(value: value),
              const SizedBox(height: 12),
              Text(value == null ? 'Uploading…' : '${(value * 100).toStringAsFixed(0)}%'),
            ],
          ),
        ),
      ),
    );
  }

  void _dismissDialog() {
    if (Navigator.of(context).canPop()) Navigator.of(context).pop();
  }

  void _showSuccess(int bytes) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Sent ${(bytes / 1024).toStringAsFixed(1)} KB to gif-buddy.')),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red.shade700),
    );
  }

  @override
  Widget build(BuildContext context) {
    final offline = _deviceOnline == false;
    return Scaffold(
      appBar: AppBar(
        title: Text(_gif?.title?.isNotEmpty == true ? _gif!.title! : widget.title),
        backgroundColor: Colors.red.shade500,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _openSettings,
          ),
        ],
      ),
      body: Column(
        children: [
          if (offline)
            MaterialBanner(
              backgroundColor: Colors.amber.shade100,
              content: Text('Device "$_host" appears offline. You can still pick a GIF.'),
              leading: const Icon(Icons.wifi_off),
              actions: [
                TextButton(onPressed: _refreshLiveness, child: const Text('Retry')),
              ],
            ),
          Expanded(
            child: SafeArea(
              child: Center(
                child: _gif == null
                    ? const Text('Pick a gif..')
                    : GiphyImage.original(gif: _gif!),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.red.shade500,
        onPressed: _pickAndSend,
        child: const Icon(Icons.search),
      ),
    );
  }
}
