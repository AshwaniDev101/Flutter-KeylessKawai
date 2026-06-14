import 'package:flutter/material.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'websocket_manager.dart';

// Desktop window constraints
const double kAppWidth = 850.0;
const double kAppHeight = 850.0;

// WS Payload constants
class AppStrings {
  static const String cmdLockTrigger = 'LOCK_TRIGGER';
  static const String cmdLedOn = 'LED_ON';
  static const String cmdLedOff = 'LED_OFF';
  static const String cmdIndoorOn = 'INDOOR_LIGHT_ON';
  static const String cmdIndoorOff = 'INDOOR_LIGHT_OFF';
  static const String cmdOutdoorOn = 'OUTDOOR_LIGHT_ON';
  static const String cmdOutdoorOff = 'OUTDOOR_LIGHT_OFF';
  static const String cmdBuzzerOn = 'BUZZER_ON';
  static const String cmdBuzzerOff = 'BUZZER_OFF';
}

class LogEntry {
  final String text;
  final bool isTx;

  LogEntry({required this.text, required this.isTx});
}

class Homepage extends StatefulWidget {
  const Homepage({super.key});

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  // Local state tracking
  bool _ledOn = false;
  bool _indoorOn = false;
  bool _outdoorOn = false;
  bool _buzzerOn = false;
  bool _snapToLatest = true;

  final List<LogEntry> _logs = [];
  final ScrollController _scrollController = ScrollController();

  /// Optimistically updates UI state, then fires the WS command.
  void _executeSecureCommand(String command) async {
    setState(() {
      _logs.add(LogEntry(text: "$command <- [TX]", isTx: true));

      // Parse state for local UI
      if (command == AppStrings.cmdLedOn) _ledOn = true;
      if (command == AppStrings.cmdLedOff) _ledOn = false;
      if (command == AppStrings.cmdIndoorOn) _indoorOn = true;
      if (command == AppStrings.cmdIndoorOff) _indoorOn = false;
      if (command == AppStrings.cmdOutdoorOn) _outdoorOn = true;
      if (command == AppStrings.cmdOutdoorOff) _outdoorOn = false;
      if (command == AppStrings.cmdBuzzerOn) _buzzerOn = true;
      if (command == AppStrings.cmdBuzzerOff) _buzzerOn = false;
    });

    _triggerScrollToBottom();

    final String? rxData = await WebSocketManager.sendOnce(command);

    if (rxData != null && mounted) {
      setState(() {
        _logs.add(LogEntry(text: "[RX] <- $rxData", isTx: false));
      });
      _triggerScrollToBottom();
    }
  }

  /// Kills all channels sequentially
  void _executeAllOff() async {
    final commands = [
      AppStrings.cmdLedOff,
      AppStrings.cmdIndoorOff,
      AppStrings.cmdOutdoorOff,
      AppStrings.cmdBuzzerOff,
    ];

    setState(() {
      _logs.add(LogEntry(text: "ALL_DEVICES_OFF <- [TX]", isTx: true));
      _ledOn = false;
      _indoorOn = false;
      _outdoorOn = false;
      _buzzerOn = false;
    });
    _triggerScrollToBottom();

    for (var cmd in commands) {
      final String? rxData = await WebSocketManager.sendOnce(cmd);
      if (rxData != null && mounted) {
        setState(() {
          _logs.add(LogEntry(text: "[RX] <- $rxData", isTx: false));
        });
        _triggerScrollToBottom();
      }
    }
  }

  void _triggerScrollToBottom() {
    if (_snapToLatest) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool isMobileMode = false;

    // Check if running on a physical mobile device
    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
      isMobileMode = true;
    }

    // Route based on OS
    if (isMobileMode) {
      return _buildMobileLayout();
    } else {
      return _buildDesktopLayout();
    }
  }

  /// Standard vertical flow for Android/narrow screens
  Widget _buildMobileLayout() {
    final backgroundColor = Colors.grey.shade50;
    final surfaceColor = Colors.white;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text(
          'KEYLESS KAWAII',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: 2.0, color: Colors.black87),
        ),
        centerTitle: true,
        backgroundColor: backgroundColor,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 220,
                child: TerminalWindow(
                  logs: _logs,
                  scrollController: _scrollController,
                  snapToLatest: _snapToLatest,
                  onSnapToggle: (val) => setState(() => _snapToLatest = val),
                  isDesktop: false,
                ),
              ),
              const SizedBox(height: 36),

              const Padding(
                padding: EdgeInsets.only(left: 4.0),
                child: Text(
                  "DEVICE DASHBOARD",
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1.5, color: Colors.black45),
                ),
              ),
              const SizedBox(height: 16),

              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.1,
                children: [
                  SystemActionGridTile(
                    title: "Door Unlock",
                    subtitle: "Unlocks main door",
                    icon: Icons.lock_open_rounded,
                    btnLabel: "UNLOCK",
                    surfaceColor: surfaceColor,
                    onTap: () => _executeSecureCommand(AppStrings.cmdLockTrigger),
                  ),
                  SystemActionGridTile(
                    title: "All OFF",
                    subtitle: "Kill all channels",
                    icon: Icons.power_settings_new_rounded,
                    btnLabel: "OFF",
                    surfaceColor: surfaceColor,
                    onTap: _executeAllOff,
                  ),
                  DeviceGridTile(
                    title: "Built-in LED",
                    subtitle: "NodeMCU D4",
                    icon: Icons.developer_board_rounded,
                    onCmd: AppStrings.cmdLedOn,
                    offCmd: AppStrings.cmdLedOff,
                    surfaceColor: surfaceColor,
                    onCommandExecuted: _executeSecureCommand,
                  ),
                  DeviceGridTile(
                    title: "Indoor Light",
                    subtitle: "Living Room D1",
                    icon: Icons.light_rounded,
                    onCmd: AppStrings.cmdIndoorOn,
                    offCmd: AppStrings.cmdIndoorOff,
                    surfaceColor: surfaceColor,
                    onCommandExecuted: _executeSecureCommand,
                  ),
                  DeviceGridTile(
                    title: "Outdoor Light",
                    subtitle: "Backyard D2",
                    icon: Icons.wb_sunny_rounded,
                    onCmd: AppStrings.cmdOutdoorOn,
                    offCmd: AppStrings.cmdOutdoorOff,
                    surfaceColor: surfaceColor,
                    onCommandExecuted: _executeSecureCommand,
                  ),
                  DeviceGridTile(
                    title: "System Buzzer",
                    subtitle: "Alarm Output D7",
                    icon: Icons.volume_up_rounded,
                    onCmd: AppStrings.cmdBuzzerOn,
                    offCmd: AppStrings.cmdBuzzerOff,
                    surfaceColor: surfaceColor,
                    onCommandExecuted: _executeSecureCommand,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Fixed-dimension split view for Windows/Edge
  Widget _buildDesktopLayout() {
    final backgroundColor = Colors.grey.shade200;
    final surfaceColor = Colors.white;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Center(
        child: Container(
          width: kAppWidth,
          height: kAppHeight,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: surfaceColor,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                spreadRadius: 5,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                height: 60,
                width: double.infinity,
                color: Colors.grey.shade50,
                alignment: Alignment.center,
                child: const Text(
                  'KEYLESS KAWAII DASHBOARD',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, letterSpacing: 2.0, color: Colors.black87),
                ),
              ),
              const Divider(height: 1, thickness: 1),

              Expanded(
                child: Row(
                  children: [
                    // Terminal pane
                    Expanded(
                      flex: 4,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: TerminalWindow(
                          logs: _logs,
                          scrollController: _scrollController,
                          snapToLatest: _snapToLatest,
                          onSnapToggle: (val) => setState(() => _snapToLatest = val),
                          isDesktop: true,
                        ),
                      ),
                    ),

                    // Control panel
                    Expanded(
                      flex: 6,
                      child: Container(
                        color: Colors.white,
                        child: ListView(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.all(20.0),
                          children: [
                            const Text(
                              "SYSTEM ACTIONS",
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.5, color: Colors.black45),
                            ),
                            const SizedBox(height: 12),
                            SystemActionRow(
                              title: "Door Unlock",
                              subtitle: "Unlocks main door",
                              icon: Icons.lock_open_rounded,
                              btnLabel: "UNLOCK",
                              surfaceColor: surfaceColor,
                              onTap: () => _executeSecureCommand(AppStrings.cmdLockTrigger),
                            ),
                            const SizedBox(height: 12),
                            SystemActionRow(
                              title: "All OFF",
                              subtitle: "Kill all channels",
                              icon: Icons.power_settings_new_rounded,
                              btnLabel: "OFF",
                              surfaceColor: surfaceColor,
                              onTap: _executeAllOff,
                            ),
                            const SizedBox(height: 24),
                            const Text(
                              "DEVICE CHANNELS",
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.5, color: Colors.black45),
                            ),
                            const SizedBox(height: 12),
                            DeviceActionRow(
                              title: "Built-in LED",
                              subtitle: "NodeMCU D4",
                              icon: Icons.developer_board_rounded,
                              onCmd: AppStrings.cmdLedOn,
                              offCmd: AppStrings.cmdLedOff,
                              surfaceColor: surfaceColor,
                              onCommandExecuted: _executeSecureCommand,
                            ),
                            const SizedBox(height: 12),
                            DeviceActionRow(
                              title: "Indoor Light",
                              subtitle: "Living Room D1",
                              icon: Icons.light_rounded,
                              onCmd: AppStrings.cmdIndoorOn,
                              offCmd: AppStrings.cmdIndoorOff,
                              surfaceColor: surfaceColor,
                              onCommandExecuted: _executeSecureCommand,
                            ),
                            const SizedBox(height: 12),
                            DeviceActionRow(
                              title: "Outdoor Light",
                              subtitle: "Backyard D2",
                              icon: Icons.wb_sunny_rounded,
                              onCmd: AppStrings.cmdOutdoorOn,
                              offCmd: AppStrings.cmdOutdoorOff,
                              surfaceColor: surfaceColor,
                              onCommandExecuted: _executeSecureCommand,
                            ),
                            const SizedBox(height: 12),
                            DeviceActionRow(
                              title: "System Buzzer",
                              subtitle: "Alarm Output D7",
                              icon: Icons.volume_up_rounded,
                              onCmd: AppStrings.cmdBuzzerOn,
                              offCmd: AppStrings.cmdBuzzerOff,
                              surfaceColor: surfaceColor,
                              onCommandExecuted: _executeSecureCommand,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// --- Shared Components ---

class TerminalWindow extends StatelessWidget {
  final List<LogEntry> logs;
  final ScrollController scrollController;
  final bool snapToLatest;
  final ValueChanged<bool> onSnapToggle;
  final bool isDesktop;

  const TerminalWindow({
    super.key,
    required this.logs,
    required this.scrollController,
    required this.snapToLatest,
    required this.onSnapToggle,
    required this.isDesktop,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(12)),
      padding: const EdgeInsets.all(16),
      child: Stack(
        children: [
          logs.isEmpty
              ? const Text(
            "Terminal ready...",
            style: TextStyle(color: Colors.grey, fontFamily: 'monospace', fontSize: 12),
          )
              : ListView.builder(
            controller: scrollController,
            itemCount: logs.length,
            itemBuilder: (context, index) {
              final log = logs[index];
              return Align(
                alignment: log.isTx ? Alignment.centerRight : Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2.0),
                  child: Text(
                    log.text,
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: isDesktop ? 10 : 8,
                      color: log.isTx ? Colors.lightBlueAccent : Colors.lightGreenAccent,
                    ),
                  ),
                ),
              );
            },
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: SizedBox(
              width: 32,
              height: 32,
              child: FloatingActionButton(
                onPressed: () => onSnapToggle(!snapToLatest),
                elevation: 2,
                backgroundColor: snapToLatest ? Colors.lightGreenAccent : Colors.grey.shade800,
                mini: true,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                child: Icon(
                  Icons.vertical_align_bottom_rounded,
                  size: 16,
                  color: snapToLatest ? Colors.black87 : Colors.white70,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// --- Mobile Grid Widgets ---

class DeviceGridTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final String onCmd;
  final String offCmd;
  final Color surfaceColor;
  final Function(String) onCommandExecuted;

  const DeviceGridTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onCmd,
    required this.offCmd,
    required this.surfaceColor,
    required this.onCommandExecuted,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade200, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(icon, color: Colors.blueGrey.shade600, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.black87),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Padding(
              padding: const EdgeInsets.only(left: 28.0),
              child: Text(
                subtitle,
                style: TextStyle(fontSize: 10, color: Colors.grey.shade500, fontWeight: FontWeight.w500),
              ),
            ),
            const Spacer(),
            Row(
              children: [
                Expanded(child: _buildTileButton(label: "OFF", onTap: () => onCommandExecuted(offCmd))),
                const SizedBox(width: 6),
                Expanded(child: _buildTileButton(label: "ON", onTap: () => onCommandExecuted(onCmd))),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildTileButton({required String label, required VoidCallback onTap}) {
    return Container(
      height: 60,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300, width: 1),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Center(
            child: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Colors.black87, letterSpacing: 0.5)),
          ),
        ),
      ),
    );
  }
}

class SystemActionGridTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final String btnLabel;
  final Color surfaceColor;
  final VoidCallback onTap;

  const SystemActionGridTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.btnLabel,
    required this.surfaceColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade200, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(icon, color: Colors.blueGrey.shade600, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.black87),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Padding(
              padding: const EdgeInsets.only(left: 28.0),
              child: Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 10, color: Colors.grey.shade500, fontWeight: FontWeight.w500),
              ),
            ),
            const Spacer(),
            Container(
              height: 60,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300, width: 1),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onTap,
                  borderRadius: BorderRadius.circular(12),
                  child: Center(
                    child: Text(btnLabel, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Colors.black87, letterSpacing: 0.5)),
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}

// --- Desktop Row Widgets ---

class DeviceActionRow extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final String onCmd;
  final String offCmd;
  final Color surfaceColor;
  final Function(String) onCommandExecuted;

  const DeviceActionRow({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onCmd,
    required this.offCmd,
    required this.surfaceColor,
    required this.onCommandExecuted,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200, width: 1),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.blueGrey.shade600, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.black87)),
                const SizedBox(height: 2),
                Text(subtitle, style: TextStyle(fontSize: 11, color: Colors.grey.shade500, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Row(
            children: [
              _buildTileButton(label: "OFF", width: 60, onTap: () => onCommandExecuted(offCmd)),
              const SizedBox(width: 8),
              _buildTileButton(label: "ON", width: 60, onTap: () => onCommandExecuted(onCmd)),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildTileButton({required String label, required double width, required VoidCallback onTap}) {
    return Container(
      height: 40,
      width: width,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300, width: 1),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Center(
            child: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Colors.black87, letterSpacing: 0.5)),
          ),
        ),
      ),
    );
  }
}

class SystemActionRow extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final String btnLabel;
  final Color surfaceColor;
  final VoidCallback onTap;

  const SystemActionRow({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.btnLabel,
    required this.surfaceColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200, width: 1),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.blueGrey.shade600, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.black87)),
                const SizedBox(height: 2),
                Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11, color: Colors.grey.shade500, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            height: 40,
            width: 128,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300, width: 1),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(8),
                child: Center(
                  child: Text(btnLabel, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Colors.black87, letterSpacing: 0.5)),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}