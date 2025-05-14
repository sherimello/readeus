import 'package:flutter/material.dart';

class DockAnimationDemoScreen extends StatefulWidget {
  @override
  _DockAnimationDemoScreenState createState() => _DockAnimationDemoScreenState();
}

class _DockAnimationDemoScreenState extends State<DockAnimationDemoScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  Animation<double>? _scaleAnimation;
  Animation<Offset>? _positionAnimation;
  Animation<double>? _fadeAnimation;

  OverlayEntry? _overlayEntry;
  final GlobalKey _dockIconKey = GlobalKey();
  final GlobalKey _windowKey = GlobalKey();

  bool _isWindowVisible = true;
  Offset? _windowPosition;
  Size? _windowSize;
  Offset? _dockIconPosition;
  Size? _dockIconSize;

  // Store the target icon properties when minimize is initiated
  Offset? _targetDockIconPosition;
  Size? _targetDockIconSize;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 450), // Adjust duration
      vsync: this,
    );

    // Get initial positions after the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) => _getWidgetBounds());
  }

  void _getWidgetBounds() {
    // Get Window position and size
    final RenderBox? windowRenderBox =
    _windowKey.currentContext?.findRenderObject() as RenderBox?;
    if (windowRenderBox != null) {
      _windowPosition = windowRenderBox.localToGlobal(Offset.zero);
      _windowSize = windowRenderBox.size;
      // print('Window Pos: $_windowPosition, Size: $_windowSize');
    }

    // Get Dock Icon position and size
    final RenderBox? dockIconRenderBox =
    _dockIconKey.currentContext?.findRenderObject() as RenderBox?;
    if (dockIconRenderBox != null) {
      _dockIconPosition = dockIconRenderBox.localToGlobal(Offset.zero);
      _dockIconSize = dockIconRenderBox.size;
      //print('Dock Icon Pos: $_dockIconPosition, Size: $_dockIconSize');
    }
    // Set the target initially in case we open first
    _targetDockIconPosition = _dockIconPosition;
    _targetDockIconSize = _dockIconSize;
  }

  Offset _getCenter(Offset position, Size size) {
    if (position == null || size == null) return Offset.zero;
    return Offset(position.dx + size.width / 2, position.dy + size.height / 2);
  }

  void _startAnimation({required bool minimize}) {
    if (_controller.isAnimating) return; // Prevent spamming

    _getWidgetBounds(); // Ensure positions are up-to-date

    if (_windowPosition == null ||
        _windowSize == null ||
        _targetDockIconPosition == null || // Use stored target
        _targetDockIconSize == null) {
      print("Error: Widget bounds not available.");
      // Fallback: just toggle visibility without animation
      setState(() {
        _isWindowVisible = !minimize;
      });
      return;
    }

    final Offset windowCenter = _getCenter(_windowPosition!, _windowSize!);
    final Offset dockIconCenter =
    _getCenter(_targetDockIconPosition!, _targetDockIconSize!);

    // Define start and end points for tweens based on minimize/restore
    final Offset startPosition = minimize ? windowCenter : dockIconCenter;
    final Offset endPosition = minimize ? dockIconCenter : windowCenter;
    final double startScale = minimize ? 1.0 : 0.1; // Start smaller when restoring
    final double endScale = minimize ? 0.1 : 1.0;   // End smaller when minimizing
    final double startFade = minimize ? 1.0 : 0.0;
    final double endFade = minimize ? 0.0 : 1.0;

    // Calculate translation offset needed for Transform.translate
    // It animates the delta from the initial position (top-left)
    final Offset startTranslation = minimize ? _windowPosition! : _targetDockIconPosition!;
    final Offset endTranslation = minimize ? _targetDockIconPosition! : _windowPosition!;


    _positionAnimation = Tween<Offset>(
      begin: startTranslation,
      end: endTranslation,
    ).animate(CurvedAnimation(
      parent: _controller,
      // Curve for position might differ from scale/fade
      curve: minimize ? Curves.easeOutCubic : Curves.easeInCubic,
    ));

    _scaleAnimation = Tween<double>(
      begin: startScale,
      end: endScale,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOutQuad, // Experiment with curves
    ));

    _fadeAnimation = Tween<double>(
      begin: startFade,
      end: endFade,
    ).animate(CurvedAnimation(
      parent: _controller,
      // Fade out quicker when minimizing, fade in slower when restoring?
      curve: minimize ? Interval(0.0, 0.7) : Interval(0.3, 1.0),
    ));


    // Create the overlay entry
    _overlayEntry = _createOverlayEntry(minimize);
    Overlay.of(context)?.insert(_overlayEntry!);

    // Hide the real window immediately if minimizing
    if (minimize) {
      setState(() {
        _isWindowVisible = false;
        // Store the icon that was targeted for the potential restore animation
        _targetDockIconPosition = _dockIconPosition;
        _targetDockIconSize = _dockIconSize;
      });
    }

    // Listener to remove overlay and show real window (if restoring)
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _overlayEntry?.remove();
        _overlayEntry = null;
        if (!minimize) {
          // Show the real window only after restore animation completes
          setState(() {
            _isWindowVisible = true;
          });
        }
        _controller.reset();
      }
    });

    // Start the animation
    _controller.forward();
  }

  OverlayEntry _createOverlayEntry(bool minimize) {
    // Use the stored _target values when restoring
    final Offset initialPosition = minimize ? _windowPosition! : _targetDockIconPosition!;
    final Size initialSize = minimize ? _windowSize! : _targetDockIconSize!;


    return OverlayEntry(
      builder: (context) {
        // Use AnimatedBuilder to react to animation changes
        return AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            if (_positionAnimation == null || _scaleAnimation == null || _fadeAnimation == null) {
              return SizedBox.shrink(); // Should not happen if bounds are checked
            }

            return Positioned(
              // We use Transform.translate based on the _positionAnimation
              // which animates the top-left corner's position.
              // We also apply scale transform which scales around the center.
              // To make scale center align with translate center, some adjustments
              // might be needed, but this provides the core effect.
              top: _positionAnimation!.value.dy,
              left: _positionAnimation!.value.dx,
              child: Opacity(
                opacity: _fadeAnimation!.value.clamp(0.0, 1.0),
                child: Transform.scale(
                  scale: _scaleAnimation!.value.clamp(0.0, 1.0),
                  // Optional: Alignment for scaling if needed
                  // alignment: Alignment.center,
                  child: Container(
                    // This container represents the animating window
                    width: initialSize.width, // Use initial size for base
                    height: initialSize.height,
                    decoration: BoxDecoration(
                      color: Colors.blueAccent.withOpacity(0.8), // Simpler representation
                      borderRadius: BorderRadius.circular(minimize
                          ? initialSize.width * (1-_scaleAnimation!.value) * 0.5 // Round more as it shrinks
                          : 8.0), // Less round when expanding
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3 * _fadeAnimation!.value),
                          blurRadius: 10 * _scaleAnimation!.value,
                          spreadRadius: 2 * _scaleAnimation!.value,
                        ),
                      ],
                    ),
                    // Optional: Add blurred content imitation? (more complex)
                    // child: ClipRRect(
                    //   borderRadius: BorderRadius.circular(8.0),
                    //   child: BackdropFilter(
                    //     filter: ui.ImageFilter.blur(sigmaX: 3.0, sigmaY: 3.0),
                    //     child: Container(color: Colors.transparent), // Needed for BackdropFilter
                    //   ),
                    // ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _overlayEntry?.remove(); // Ensure cleanup if disposed mid-animation
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('macOS Dock Animation Demo'),
      ),
      body: Stack(
        children: [
          // Main content area
          Center(
            child: Text(
              'Your App Content Area',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ),

          // The "App Window"
          if (_isWindowVisible) // Conditionally display the real window
            Positioned(
              key: _windowKey, // Key to get its bounds
              top: 100,
              left: 100,
              child: Container(
                width: 300,
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.blueAccent,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 10,
                      spreadRadius: 2,
                    )
                  ],
                ),
                child: Column(
                  children: [
                    AppBar( // Fake window title bar
                      title: Text('My App Window', style: TextStyle(fontSize: 14)),
                      leading: Icon(Icons.apps, size: 16),
                      actions: [
                        IconButton( // Minimize Button
                          icon: Icon(Icons.remove, size: 18),
                          onPressed: () {
                            // Start MINIMIZE animation
                            _startAnimation(minimize: true);
                          },
                        ),
                      ],
                      primary: false, // Not a real AppBar
                      toolbarHeight: 40,
                    ),
                    Expanded(
                      child: Center(child: Text('Window Content')),
                    ),
                  ],
                ),
              ),
            ),

          // The "Dock"
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              padding: const EdgeInsets.all(8.0),
              margin: const EdgeInsets.only(bottom: 20.0),
              decoration: BoxDecoration(
                  color: Colors.grey[800]?.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(color: Colors.black38, blurRadius: 15)
                  ]
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildDockIcon(Icons.mail),
                  SizedBox(width: 10),
                  _buildDockIcon(Icons.photo_library),
                  SizedBox(width: 10),
                  // The icon associated with our window
                  InkWell(
                    key: _dockIconKey, // Key to get its bounds
                    onTap: () {
                      if (!_isWindowVisible) {
                        // Start RESTORE animation
                        _startAnimation(minimize: false);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(_isWindowVisible ? 0.3 : 0.7), // Indicate state
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.apps, size: 40, color: Colors.white),
                    ),
                  ),
                  SizedBox(width: 10),
                  _buildDockIcon(Icons.settings),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDockIcon(IconData icon) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey[700],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, size: 40, color: Colors.white70),
    );
  }
}