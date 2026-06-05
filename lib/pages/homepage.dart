import 'package:flutter/material.dart';
import 'websocket_manager.dart';

class AppStrings {
  // Commands
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

class Homepage extends StatefulWidget {
  const Homepage({super.key});

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  // UI state tracking
  bool _ledOn = false;
  bool _indoorOn = false;
  bool _outdoorOn = false;
  bool _buzzerOn = false;

  // Snap/Autoscroll flag for terminal tracking
  bool _snapToLatest = true;

  final TextEditingController _consoleController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  // Optimistic UI state updates, WS execution & terminal logging
  void _executeSecureCommand(String command) {
    WebSocketManager.sendOnce(command);

    setState(() {
      _consoleController.text += "[TX] -> $command\n";

      if (command == AppStrings.cmdLedOn) _ledOn = true;
      if (command == AppStrings.cmdLedOff) _ledOn = false;
      if (command == AppStrings.cmdIndoorOn) _indoorOn = true;
      if (command == AppStrings.cmdIndoorOff) _indoorOn = false;
      if (command == AppStrings.cmdOutdoorOn) _outdoorOn = true;
      if (command == AppStrings.cmdOutdoorOff) _outdoorOn = false;
      if (command == AppStrings.cmdBuzzerOn) _buzzerOn = true;
      if (command == AppStrings.cmdBuzzerOff) _buzzerOn = false;
    });

    // Handle automated scroll execution if flag is active
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
    _consoleController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final backgroundColor = Colors.grey.shade50;
    final surfaceColor = Colors.white;
    final primaryAccent = Colors.deepOrange.shade600;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text(
          'KEYLESS KAWAII',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            letterSpacing: 2.0,
            color: Colors.black87,
          ),
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
              // Terminal window container stack with nested snap controller
              Stack(
                children: [
                  TextField(
                    controller: _consoleController,
                    scrollController: _scrollController,
                    maxLines: 14, // Increased maxLines for a taller console window
                    readOnly: true,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 8,
                      color: Colors.lightGreenAccent,
                    ),
                    decoration: InputDecoration(
                      fillColor: Colors.black87,
                      filled: true,
                      hintText: "Terminal ready...",
                      hintStyle: const TextStyle(color: Colors.grey, fontFamily: 'monospace', fontSize: 12),
                      contentPadding: const EdgeInsets.all(16),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  Positioned(
                    right: 8,
                    bottom: 8,
                    child: SizedBox(
                      width: 32,
                      height: 32,
                      child: FloatingActionButton(
                        onPressed: () {
                          setState(() {
                            _snapToLatest = !_snapToLatest;
                          });
                        },
                        elevation: 2,
                        backgroundColor: _snapToLatest ? Colors.lightGreenAccent : Colors.grey.shade800,
                        mini: true,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        child: Icon(
                          Icons.vertical_align_bottom_rounded,
                          size: 16,
                          color: _snapToLatest ? Colors.black87 : Colors.white70,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Normalized and downsized central interactive asset
              Center(
                child: SizedBox(
                  width: 160,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: () => _executeSecureCommand(AppStrings.cmdLockTrigger),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: surfaceColor,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.grey.shade200, width: 1),
                      ),
                    ),
                    icon: Icon(Icons.lock_open_rounded, color: primaryAccent, size: 20),
                    label: const Text(
                      "Unlock",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: Colors.black87,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 36),

              const Padding(
                padding: EdgeInsets.only(left: 4.0),
                child: Text(
                  "DEVICE DASHBOARD",
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.5,
                      color: Colors.black45),
                ),
              ),
              const SizedBox(height: 16),

              // Device Control Grid
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.1,
                children: [
                  _buildMinimalGridTile(
                    title: "Built-in LED",
                    subtitle: "NodeMCU D4",
                    icon: Icons.developer_board_rounded,
                    onCmd: AppStrings.cmdLedOn,
                    offCmd: AppStrings.cmdLedOff,
                    surfaceColor: surfaceColor,
                  ),
                  _buildMinimalGridTile(
                    title: "Indoor Light",
                    subtitle: "Living Room D1",
                    icon: Icons.light_rounded,
                    onCmd: AppStrings.cmdIndoorOn,
                    offCmd: AppStrings.cmdIndoorOff,
                    surfaceColor: surfaceColor,
                  ),
                  _buildMinimalGridTile(
                    title: "Outdoor Light",
                    subtitle: "Backyard D2",
                    icon: Icons.wb_sunny_rounded,
                    onCmd: AppStrings.cmdOutdoorOn,
                    offCmd: AppStrings.cmdOutdoorOff,
                    surfaceColor: surfaceColor,
                  ),
                  _buildMinimalGridTile(
                    title: "System Buzzer",
                    subtitle: "Alarm Output D7",
                    icon: Icons.volume_up_rounded,
                    onCmd: AppStrings.cmdBuzzerOn,
                    offCmd: AppStrings.cmdBuzzerOff,
                    surfaceColor: surfaceColor,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMinimalGridTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required String onCmd,
    required String offCmd,
    required Color surfaceColor,
  }) {
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
                Icon(
                  icon,
                  color: Colors.blueGrey.shade600,
                  size: 20,
                ),
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

            const SizedBox(height: 14),

            Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    label: "OFF",
                    onTap: () => _executeSecureCommand(offCmd),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: _buildActionButton(
                    label: "ON",
                    onTap: () => _executeSecureCommand(onCmd),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required VoidCallback onTap,
  }) {
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
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: Colors.black87,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
      ),
    );
  }
}