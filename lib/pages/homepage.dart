import 'package:flutter/material.dart';
import 'websocket_manager.dart';

class Homepage extends StatefulWidget {
  const Homepage({super.key});

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  // Hardware States Tracking (false = OFF, true = ON)
  bool _ledOn = false;
  bool _indoorOn = false;
  bool _outdoorOn = false;

  // Software Debounce Gate Guard
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    // Fetch live device data directly when app opens
    _refreshDeviceStates();
  }

  // Request state tracking string from the micro-controller
  void _refreshDeviceStates() {
    setState(() => _isProcessing = true);

    WebSocketManager.sendOnce("GET_STATUS", onResponse: (response) {
      if (mounted) {
        setState(() => _isProcessing = false);
        if (response.startsWith("STATUS:")) {
          _parseAndSetTelemetry(response);
        }
      }
    });
  }

  // Intercepts commands to prevent rapid-click user inputs
  void _executeSecureCommand(String command) {
    if (_isProcessing) return; // --- HARDWARE DEBOUNCE BLOCK ---

    setState(() => _isProcessing = true);

    WebSocketManager.sendOnce(command, onResponse: (response) {
      if (mounted) {
        setState(() => _isProcessing = false);

        if (response == "ERROR") {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Network communication failed')),
          );
          return;
        }

        // --- DIRECT COMMAND INTERCEPTOR FIX ---
        // Instantly switch the UI states depending on the unique execution code returned
        setState(() {
          if (response == "LED_ON_OK") _ledOn = true;
          if (response == "LED_OFF_OK") _ledOn = false;
          if (response == "INDOOR_ON_OK") _indoorOn = true;
          if (response == "INDOOR_OFF_OK") _indoorOn = false;
          if (response == "OUTDOOR_ON_OK") _outdoorOn = true;
          if (response == "OUTDOOR_OFF_OK") _outdoorOn = false;
        });

        // Trigger an absolute status check query to verify reality
        _refreshDeviceStates();
      }
    });
  }

  // Cleaves string attributes: "STATUS:LED=1,INDOOR=0,OUTDOOR=0"
  void _parseAndSetTelemetry(String payload) {
    try {
      final cleanData = payload.replaceFirst("STATUS:", "");
      final segments = cleanData.split(",");

      bool targetLed = _ledOn;
      bool targetIndoor = _indoorOn;
      bool targetOutdoor = _outdoorOn;

      for (var segment in segments) {
        final kv = segment.split("=");
        if (kv.length == 2) {
          final key = kv[0];
          final val = kv[1];

          if (key == "LED") {
            // LED uses inverted logic (0 means light is ON)
            targetLed = (val == "0");
          } else if (key == "INDOOR") {
            // Standard logic (1 means light is ON)
            targetIndoor = (val == "1");
          } else if (key == "OUTDOOR") {
            targetOutdoor = (val == "1");
          }
        }
      }

      setState(() {
        _ledOn = targetLed;
        _indoorOn = targetIndoor;
        _outdoorOn = targetOutdoor;
      });
    } catch (e) {
      debugPrint("Parsing exception: $e");
    }
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
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.black54),
            onPressed: _isProcessing ? null : _refreshDeviceStates,
          ),
        ],
        bottom: _isProcessing
            ? PreferredSize(
          preferredSize: const Size.fromHeight(2),
          child: LinearProgressIndicator(
            backgroundColor: backgroundColor,
            valueColor: AlwaysStoppedAnimation<Color>(primaryAccent),
          ),
        )
            : null,
      ),
      body: AbsorbPointer(
        absorbing: _isProcessing,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- HERO BANNER: UNLOCK ACTION ---
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
                        splashColor: primaryAccent.withOpacity(0.1),
                        highlightColor: Colors.transparent,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 36.0, horizontal: 16.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              CircleAvatar(
                                radius: 36,
                                backgroundColor: primaryAccent.withOpacity(0.08),
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

                // --- TWO COLUMN SWITCH GRID ---
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.15,
                  children: [
                    _buildMinimalGridTile(
                      title: "Built-in LED",
                      subtitle: "NodeMCU D4",
                      icon: Icons.developer_board_rounded,
                      isActive: _ledOn,
                      onCmd: "LED_ON",
                      offCmd: "LED_OFF",
                      surfaceColor: surfaceColor,
                    ),
                    _buildMinimalGridTile(
                      title: "Indoor Light",
                      subtitle: "Living Room D1",
                      icon: Icons.light_rounded,
                      isActive: _indoorOn,
                      onCmd: "INDOOR_LIGHT_ON",
                      offCmd: "INDOOR_LIGHT_OFF",
                      surfaceColor: surfaceColor,
                    ),
                    _buildMinimalGridTile(
                      title: "Outdoor Light",
                      subtitle: "Backyard D2",
                      icon: Icons.wb_sunny_rounded,
                      isActive: _outdoorOn,
                      onCmd: "OUTDOOR_LIGHT_ON",
                      offCmd: "OUTDOOR_LIGHT_OFF",
                      surfaceColor: surfaceColor,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMinimalGridTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isActive,
    required String onCmd,
    required String offCmd,
    required Color surfaceColor,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
            color: isActive ? Colors.amber.shade200 : Colors.grey.shade200,
            width: isActive ? 1.5 : 1
        ),
      ),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(
                  icon,
                  color: isActive ? Colors.amber.shade600 : Colors.blueGrey.shade600,
                  size: 24
              ),
              Container(
                height: 32,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    _buildMicroActionButton(
                        label: "OFF",
                        cmd: offCmd,
                        isSelected: !isActive,
                        activeColor: Colors.black54
                    ),
                    Container(width: 1, height: 16, color: Colors.grey.shade300),
                    _buildMicroActionButton(
                        label: "ON",
                        cmd: onCmd,
                        isSelected: isActive,
                        activeColor: Colors.amber.shade600
                    ),
                  ],
                ),
              )
            ],
          ),
          const Spacer(),
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isActive ? Colors.amber.shade500 : Colors.grey.shade300,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.black87),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: TextStyle(fontSize: 11, color: Colors.grey.shade500, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildMicroActionButton({
    required String label,
    required String cmd,
    required bool isSelected,
    required Color activeColor
  }) {
    return Material(
      color: isSelected ? Colors.white : Colors.transparent,
      elevation: isSelected ? 1 : 0,
      shadowColor: isSelected ? Colors.black54 : Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => _executeSecureCommand(cmd),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: isSelected ? activeColor : Colors.grey.shade400,
                  letterSpacing: 0.5
              ),
            ),
          ),
        ),
      ),
    );
  }
}