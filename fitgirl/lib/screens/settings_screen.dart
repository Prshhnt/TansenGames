import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/custom/custom_scrollbar.dart';
import '../services/api_service.dart';
import '../services/api_settings_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final ScrollController _scrollController;
  late final TextEditingController _apiController;
  bool _autoOpenDownloads = true;
  bool _showNotifications = true;
  bool _useCustomFonts = true;
  String _downloadFolder = 'Downloads/Tansen Games';
  double _timeoutSeconds = 30;
  bool _isCheckingApi = false;
  bool _apiStatusOk = false;
  String? _apiStatusMessage;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _apiController = TextEditingController(text: ApiSettings.baseUrl);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _apiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.backgroundDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: CustomScrollbar(
                controller: _scrollController,
                child: ListView(
                  controller: _scrollController,
                  padding: const EdgeInsets.only(bottom: 48),
                  children: [
                    const SizedBox(height: 16),
                    _section('Appearance', [
                      _settingRow(
                        'Theme',
                        'Dark (custom)',
                        trailing: _badge('Locked'),
                      ),
                      _switchRow(
                        label: 'Use custom fonts',
                        value: _useCustomFonts,
                        onChanged: (v) => setState(() => _useCustomFonts = v),
                      ),
                    ]),
                    const SizedBox(height: 16),
                    _section('Network', [
                      _apiEndpointRow(),
                      _sliderRow(
                        label: 'Timeout',
                        value: _timeoutSeconds,
                        min: 10,
                        max: 60,
                        unit: 's',
                        onChanged: (v) => setState(() => _timeoutSeconds = v),
                      ),
                    ]),
                    const SizedBox(height: 16),
                    _section('Downloads', [
                      _settingRow('Download folder', _downloadFolder,
                          trailing: _pillButton('Change', onTap: () {})),
                      _switchRow(
                        label: 'Auto-open Downloads tab when a download starts',
                        value: _autoOpenDownloads,
                        onChanged: (v) => setState(() => _autoOpenDownloads = v),
                      ),
                    ]),
                    const SizedBox(height: 16),
                    _section('Notifications', [
                      _switchRow(
                        label: 'Show toast for download start/completion',
                        value: _showNotifications,
                        onChanged: (v) => setState(() => _showNotifications = v),
                      ),
                    ]),
                    const SizedBox(height: 16),
                    _section('About', [
                      _settingRow('Version', 'v1.0.2'),
                      _settingRow('Status', 'All systems operational', leading: _dot()),
                    ]),
                    const SizedBox(height: 20),
                    _footerActions(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
      decoration: const BoxDecoration(
        color: Color(0xFF111A22),
        border: Border(bottom: BorderSide(color: AppTheme.borderColor)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            'Settings',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              fontFamily: 'SpaceGrotesk',
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Configure appearance and backend connectivity.',
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.slate400,
              fontFamily: 'NotoSans',
            ),
          ),
        ],
      ),
    );
  }

  Widget _section(String title, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  fontFamily: 'SpaceGrotesk',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _settingRow(String label, String value, {Widget? leading, Widget? trailing}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.surfaceHover,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Row(
        children: [
          if (leading != null) ...[leading, const SizedBox(width: 8)],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    fontFamily: 'SpaceGrotesk',
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.slate400,
                    fontFamily: 'NotoSans',
                  ),
                ),
              ],
            ),
          ),
          if (trailing != null) trailing,
        ],
      ),
    );
  }

  Widget _switchRow({required String label, required bool value, required ValueChanged<bool> onChanged}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceHover,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                fontFamily: 'SpaceGrotesk',
              ),
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppTheme.primary,
          ),
        ],
      ),
    );
  }

  Widget _sliderRow({
    required String label,
    required double value,
    required double min,
    required double max,
    required String unit,
    required ValueChanged<double> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceHover,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    fontFamily: 'SpaceGrotesk',
                  ),
                ),
              ),
              Text(
                '${value.toStringAsFixed(0)}$unit',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.slate400,
                  fontFamily: 'NotoSans',
                ),
              ),
            ],
          ),
          Slider(
            value: value,
            min: min,
            max: max,
            divisions: (max - min).toInt(),
            activeColor: AppTheme.primary,
            inactiveColor: AppTheme.slate700,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _badge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppTheme.primary.withOpacity(0.3)),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: AppTheme.primary,
          fontFamily: 'SpaceGrotesk',
        ),
      ),
    );
  }

  Widget _dot() {
    return Container(
      width: 10,
      height: 10,
      decoration: const BoxDecoration(
        color: Colors.green,
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _pillButton(String label, {required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppTheme.surfaceDark,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: AppTheme.borderColor),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: Colors.white,
            fontFamily: 'SpaceGrotesk',
          ),
        ),
      ),
    );
  }

  Widget _footerActions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _pillButton('Reset to defaults', onTap: () {}),
        Row(
          children: [
            _pillButton('Export settings', onTap: () {}),
            const SizedBox(width: 8),
            _pillButton('Import settings', onTap: () {}),
          ],
        ),
      ],
    );
  }

  Widget _apiEndpointRow() {
    final statusColor = _apiStatusMessage == null
        ? AppTheme.slate400
        : _apiStatusOk
            ? Colors.greenAccent
            : Colors.orangeAccent;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceHover,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'API Base URL',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              fontFamily: 'SpaceGrotesk',
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _apiController,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.white,
                    fontFamily: 'NotoSans',
                  ),
                  decoration: InputDecoration(
                    hintText: 'http://127.0.0.1:8000',
                    hintStyle: const TextStyle(color: AppTheme.slate500),
                    filled: true,
                    fillColor: AppTheme.surfaceDark,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppTheme.borderColor),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppTheme.primary),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: _isCheckingApi ? null : _updateApiEndpoint,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: _isCheckingApi ? AppTheme.slate700 : AppTheme.primary,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: _isCheckingApi ? AppTheme.slate700 : AppTheme.primary),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_isCheckingApi)
                        const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      else
                        const Icon(Icons.sync, size: 16, color: Colors.white),
                      const SizedBox(width: 6),
                      Text(
                        _isCheckingApi ? 'Checking' : 'Update',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          fontFamily: 'SpaceGrotesk',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (_apiStatusMessage != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  _apiStatusOk ? Icons.check_circle : Icons.error_outline,
                  color: statusColor,
                  size: 16,
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    _apiStatusMessage!,
                    style: TextStyle(
                      fontSize: 12,
                      color: statusColor,
                      fontFamily: 'NotoSans',
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _updateApiEndpoint() async {
    final input = _apiController.text.trim();

    if (input.isEmpty) {
      setState(() {
        _apiStatusOk = false;
        _apiStatusMessage = 'Please enter a valid URL.';
      });
      return;
    }

    setState(() {
      _isCheckingApi = true;
      _apiStatusOk = false;
      _apiStatusMessage = 'Checking endpoint...';
    });

    try {
      final healthy = await ApiService.testEndpoint(input);

      if (!mounted) return;

      if (healthy) {
        await ApiSettings.setBaseUrl(input);
        ApiService(baseUrl: input); // refresh shared client to use new base
        setState(() {
          _apiStatusOk = true;
          _apiStatusMessage = 'Endpoint reachable and saved.';
        });
      } else {
        setState(() {
          _apiStatusOk = false;
          _apiStatusMessage = 'Endpoint responded with a non-200 status.';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _apiStatusOk = false;
        _apiStatusMessage = 'Failed to reach endpoint: $e';
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _isCheckingApi = false;
      });
    }
  }
}
