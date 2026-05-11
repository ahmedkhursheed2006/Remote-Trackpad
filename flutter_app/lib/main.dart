import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:convert';
import 'dart:async';

void main() {
  runApp(const RemoteDrawingApp());
}

class RemoteDrawingApp extends StatelessWidget {
  const RemoteDrawingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Remote Trackpad',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        primaryColor: Colors.deepPurple,
        scaffoldBackgroundColor: const Color(0xFF0F0F0F),
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple, brightness: Brightness.dark),
      ),
      home: const TouchPadScreen(),
    );
  }
}

class TouchPadScreen extends StatefulWidget {
  const TouchPadScreen({super.key});

  @override
  State<TouchPadScreen> createState() => _TouchPadScreenState();
}

class _TouchPadScreenState extends State<TouchPadScreen> {
  RawDatagramSocket? _socket;
  final TextEditingController _ipController = TextEditingController();
  String _selectedServerName = 'None';
  List<Map<String, String>> _foundServers = [];
  
  final int _port = 6000;
  final int _discoveryPort = 6001;
  
  bool _isTabletMode = false;
  double _sensitivity = 1.5;
  bool _isSearching = false;
  
  // High-frequency interaction state (Updating these doesn't always need setState)
  final Map<int, Offset> _pointers = {};
  final Map<int, Offset> _initialPointers = {};
  DateTime? _firstTouchTime;
  bool _isManualDragActive = false;
  Offset? _previousPosition;

  @override
  void initState() {
    super.initState();
    _initSocket();
    _discoverServer();
  }
  
  void _initSocket() async {
    try {
      _socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
    } catch (e) {
      debugPrint('Error: $e');
    }
  }

  Future<void> _discoverServer() async {
    if (_isSearching) return;
    setState(() {
      _isSearching = true;
      _ipController.text = 'Searching...';
      _foundServers.clear();
    });

    try {
      RawDatagramSocket discoverySocket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
      discoverySocket.broadcastEnabled = true;
      discoverySocket.send(utf8.encode("DISCOVERY_REQUEST"), InternetAddress("255.255.255.255"), _discoveryPort);

      Timer(const Duration(seconds: 3), () {
        discoverySocket.close();
        if (mounted) {
          setState(() => _isSearching = false);
          if (_foundServers.isNotEmpty) _showServerSelectionDialog();
        }
      });

      discoverySocket.listen((RawSocketEvent event) {
        if (event == RawSocketEvent.read) {
          Datagram? dg = discoverySocket.receive();
          if (dg != null) {
            String response = utf8.decode(dg.data);
            if (response.startsWith("DISCOVERY_RESPONSE:")) {
              String name = response.split(':')[1];
              String ip = dg.address.address;
              if (!_foundServers.any((s) => s['ip'] == ip)) {
                setState(() => _foundServers.add({'name': name, 'ip': ip}));
              }
            }
          }
        }
      });
    } catch (e) {
      setState(() => _isSearching = false);
    }
  }

  void _showServerSelectionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Laptop'),
        backgroundColor: const Color(0xFF1E1E1E),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: _foundServers.length,
            itemBuilder: (context, index) {
              final server = _foundServers[index];
              return ListTile(
                leading: const Icon(Icons.laptop, color: Colors.deepPurpleAccent),
                title: Text(server['name']!),
                subtitle: Text(server['ip']!),
                onTap: () {
                  setState(() {
                    _ipController.text = server['ip']!;
                    _selectedServerName = server['name']!;
                  });
                  Navigator.pop(context);
                },
              );
            },
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _socket?.close();
    _ipController.dispose();
    super.dispose();
  }

  // Optimize packet sending by using a faster string construction
  void _sendPacket(double x, double y, String actionType) {
    if (_socket == null || _ipController.text.isEmpty || _ipController.text == 'Searching...') return;
    
    final mode = _isTabletMode ? 'tablet' : 'trackpad';
    final message = '${x.toStringAsFixed(3)},${y.toStringAsFixed(3)},$actionType,$mode';
    
    try {
      _socket?.send(utf8.encode(message), InternetAddress(_ipController.text), _port);
    } catch (e) {}
  }

  void _sendMovement(PointerEvent event, String actionType) {
    if (_isTabletMode) {
      final RenderBox box = context.findRenderObject() as RenderBox;
      final localPos = box.globalToLocal(event.position);
      _sendPacket(
        (localPos.dx / box.size.width).clamp(0.0, 1.0),
        (localPos.dy / box.size.height).clamp(0.0, 1.0),
        actionType
      );
    } else {
      if (_previousPosition != null) {
        _sendPacket(
          (event.position.dx - _previousPosition!.dx) * _sensitivity,
          (event.position.dy - _previousPosition!.dy) * _sensitivity,
          actionType
        );
      }
      _previousPosition = event.position;
    }
  }

  void _handlePointerDown(PointerDownEvent event) {
    _pointers[event.pointer] = event.position;
    _initialPointers[event.pointer] = event.position;
    _previousPosition = event.position;
    _firstTouchTime = DateTime.now();
    // Use setState only for UI changes
    setState(() {});
  }

  void _handlePointerMove(PointerMoveEvent event) {
    _pointers[event.pointer] = event.position;
    _sendMovement(event, 'hover');
    // NO setState here! This keeps the movement processing at maximum speed.
  }

  void _handlePointerUp(PointerUpEvent event) {
    if (!_isManualDragActive && _pointers.length == 1 && _firstTouchTime != null) {
      final duration = DateTime.now().difference(_firstTouchTime!);
      final distance = (event.position - _initialPointers[event.pointer]!).distance;
      if (duration.inMilliseconds < 200 && distance < 10) {
        _sendPacket(0, 0, 'down');
        _sendPacket(0, 0, 'up');
      }
    }
    _pointers.remove(event.pointer);
    _initialPointers.remove(event.pointer);
    _previousPosition = null;
    setState(() {});
  }

  void _startManualDrag() {
    setState(() => _isManualDragActive = true);
    _sendPacket(0, 0, 'down');
  }

  void _stopManualDrag() {
    setState(() => _isManualDragActive = false);
    _sendPacket(0, 0, 'up');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Remote Trackpad'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(icon: Icon(_isSearching ? Icons.sync : Icons.refresh), onPressed: _discoverServer),
          IconButton(icon: const Icon(Icons.settings), onPressed: () => _showSettings(context)),
        ],
      ),
      body: Stack(
        children: [
          Listener(
            onPointerDown: _handlePointerDown,
            onPointerMove: _handlePointerMove,
            onPointerUp: _handlePointerUp,
            behavior: HitTestBehavior.opaque,
            child: Container(
              width: double.infinity,
              height: double.infinity,
              color: Colors.transparent, 
              child: Stack(
                children: [
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _isTabletMode ? Icons.tablet_mac : Icons.touch_app,
                          size: 100,
                          color: _isManualDragActive ? Colors.deepPurpleAccent.withOpacity(0.5) : Colors.white10,
                        ),
                        const SizedBox(height: 30),
                        Text(
                          _isManualDragActive ? 'DRAGGING' : (_isTabletMode ? 'TABLET MODE' : 'TRACKPAD MODE'),
                          style: TextStyle(
                            color: _isManualDragActive ? Colors.deepPurpleAccent : Colors.white30, 
                            fontSize: 28, 
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2.0
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(_ipController.text.isEmpty || _ipController.text == 'Searching...' 
                            ? 'Not Connected' : 'Connected to: $_selectedServerName', 
                            style: const TextStyle(color: Colors.white24, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ),
                  if (_isTabletMode)
                    Positioned.fill(child: IgnorePointer(child: CustomPaint(painter: GridPainter()))),
                ],
              ),
            ),
          ),
          
          Positioned(
            bottom: 40,
            left: 20,
            right: 20,
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onPanDown: (_) => _startManualDrag(),
                    onPanCancel: () => _stopManualDrag(),
                    onPanEnd: (_) => _stopManualDrag(),
                    child: Container(
                      height: 80,
                      decoration: BoxDecoration(
                        color: _isManualDragActive ? Colors.deepPurpleAccent : Colors.deepPurple.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.deepPurpleAccent.withOpacity(0.5), width: 2),
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.mouse, color: _isManualDragActive ? Colors.white : Colors.white54),
                            const Text('HOLD TO DRAG', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                GestureDetector(
                  onTap: () => _sendPacket(0, 0, 'right_click'),
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: const Center(child: Text('RIGHT', style: TextStyle(fontWeight: FontWeight.bold))),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showSettings(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateBottomSheet) {
            return Padding(
              padding: EdgeInsets.only(
                left: 24.0, 
                right: 24.0, 
                top: 24.0, 
                bottom: MediaQuery.of(context).viewInsets.bottom + 24.0
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Configuration', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 25),
                  TextField(
                    controller: _ipController,
                    decoration: InputDecoration(
                      labelText: 'Desktop IP Address',
                      suffixIcon: IconButton(icon: const Icon(Icons.sync), onPressed: _discoverServer),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.05),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  ),
                  const SizedBox(height: 10),
                  Text('Current Server: $_selectedServerName', style: const TextStyle(color: Colors.white54)),
                  const SizedBox(height: 30),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Input Mode', style: TextStyle(fontSize: 18)),
                      ToggleButtons(
                        borderRadius: BorderRadius.circular(12),
                        fillColor: Colors.deepPurple.withOpacity(0.3),
                        selectedColor: Colors.white,
                        isSelected: [_isTabletMode == false, _isTabletMode == true],
                        onPressed: (index) {
                          setState(() {
                            _isTabletMode = index == 1;
                          });
                          setStateBottomSheet(() {});
                        },
                        children: const [
                          Padding(padding: EdgeInsets.symmetric(horizontal: 20), child: Text('Trackpad')),
                          Padding(padding: EdgeInsets.symmetric(horizontal: 20), child: Text('Tablet')),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),
                  if (!_isTabletMode) ...[
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      const Text('Sensitivity', style: TextStyle(fontSize: 18)),
                      Text(_sensitivity.toStringAsFixed(1), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.deepPurpleAccent)),
                    ]),
                    Slider(
                      value: _sensitivity,
                      min: 0.1,
                      max: 5.0,
                      activeColor: Colors.deepPurpleAccent,
                      onChanged: (val) {
                        setState(() {
                          _sensitivity = val;
                        });
                        setStateBottomSheet(() {});
                      },
                    ),
                  ],
                ],
              ),
            );
          }
        );
      }
    );
  }
}

class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withOpacity(0.03)..strokeWidth = 1.0;
    const double step = 60.0;
    for (double i = 0; i < size.width; i += step) canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    for (double i = 0; i < size.height; i += step) canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
