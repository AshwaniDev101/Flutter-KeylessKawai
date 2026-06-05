import 'package:flutter/material.dart';
import 'websocket_manager.dart';

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

  // Optimistic UI state updates & WS execution
  void _executeSecureCommand(String command) {
    WebSocketManager.sendOnce(command);

    setState(() {
      if (command == "LED_ON") _ledOn = true;
      if (command == "LED_OFF") _ledOn = false;
      if (command == "INDOOR_LIGHT_ON") _indoorOn = true;
      if (command == "INDOOR_LIGHT_OFF") _indoorOn = false;
      if (command == "OUTDOOR_LIGHT_ON") _outdoorOn = true;
      if (command == "OUTDOOR_LIGHT_OFF") _outdoorOn = false;
      if (command == "BUZZER_ON") _buzzerOn = true;
      if (command == "BUZZER_OFF") _buzzerOn = false;
    });
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
              // Hero Banner: Main Lock
              Container(
                decoration: BoxDecoration(
                  color: surfaceColor,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: Colors.grey.shade200, width: 1),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => _executeSecureCommand("LOCK_TRIGGER"),
                      splashColor: primaryAccent.withValues(alpha: 0.1),
                      highlightColor: Colors.transparent,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 36.0, horizontal: 16.0),
                        child: Column(
                          mainAxisAlignment:  MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            CircleAvatar(
                              radius: 36,
                              backgroundColor: primaryAccent.withValues(alpha: 0.08),
                              child: Icon(Icons.lock_open_rounded, size: 36, color: primaryAccent),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              "Main Entrance Lock",
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.black87),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              "Tap to unlock for 1 second",
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 13, color: Colors.grey.shade500, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
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
                childAspectRatio: 1.1, // Aspect ratio optimized for a compact layout
                children: [
                  _buildMinimalGridTile(
                    title: "Built-in LED",
                    subtitle: "NodeMCU D4",
                    icon: Icons.developer_board_rounded,
                    onCmd: "LED_ON",
                    offCmd: "LED_OFF",
                    surfaceColor: surfaceColor,
                  ),
                  _buildMinimalGridTile(
                    title: "Indoor Light",
                    subtitle: "Living Room D1",
                    icon: Icons.light_rounded,
                    onCmd: "INDOOR_LIGHT_ON",
                    offCmd: "INDOOR_LIGHT_OFF",
                    surfaceColor: surfaceColor,
                  ),
                  _buildMinimalGridTile(
                    title: "Outdoor Light",
                    subtitle: "Backyard D2",
                    icon: Icons.wb_sunny_rounded,
                    onCmd: "OUTDOOR_LIGHT_ON",
                    offCmd: "OUTDOOR_LIGHT_OFF",
                    surfaceColor: surfaceColor,
                  ),
                  _buildMinimalGridTile(
                    title: "System Buzzer",
                    subtitle: "Alarm Output D7",
                    icon: Icons.volume_up_rounded,
                    onCmd: "BUZZER_ON",
                    offCmd: "BUZZER_OFF",
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
          mainAxisSize: MainAxisSize.min, // Forces column to stay compact
          children: [
            // Icon and Header Layout
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

            // Nested Subtitle
            Padding(
              padding: const EdgeInsets.only(left: 28.0),
              child: Text(
                subtitle,
                style: TextStyle(fontSize: 10, color: Colors.grey.shade500, fontWeight: FontWeight.w500),
              ),
            ),

            const SizedBox(height: 14), // Controlled fixed gap between info and controls

            // Identical Action Buttons
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
      height: 40,
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