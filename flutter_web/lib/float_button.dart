import 'package:flutter/material.dart';

class FloatingButtonWidget extends StatefulWidget {
  const FloatingButtonWidget({super.key});

  @override
  FloatingButtonWidgetState createState() => FloatingButtonWidgetState();
}

class FloatingButtonWidgetState extends State<FloatingButtonWidget>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  bool isExpanded = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
  }

  void _toggleExpand() {
    setState(() {
      isExpanded = !isExpanded;
      isExpanded ? _controller.forward() : _controller.reverse();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _buildFloatingButton(
      IconData icon, VoidCallback onPressed, String tag) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: FloatingActionButton(
        heroTag: tag,
        onPressed: onPressed,
        backgroundColor: Colors.white,
        child: Icon(icon, color: const Color.fromARGB(255, 199, 23, 23)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          bottom: 80,
          right: 20,
          child: ScaleTransition(
            scale: _animation,
            alignment: Alignment.bottomRight,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _buildFloatingButton(Icons.home, () {
                  Navigator.pushNamed(context, '/home');
                }, 'home'),
                _buildFloatingButton(Icons.qr_code_scanner, () {
                  Navigator.pushNamed(context, '/scanner');
                }, 'scanner'),
                _buildFloatingButton(Icons.pageview, () {
                  // Navigate to Generic Page 1
                }, 'page1'),
                _buildFloatingButton(Icons.pageview, () {
                  // Navigate to Generic Page 2
                }, 'page2'),
                _buildFloatingButton(Icons.pageview, () {
                  // Navigate to Generic Page 3
                }, 'page3'),
              ],
            ),
          ),
        ),
        Positioned(
          bottom: 20,
          right: 20,
          child: FloatingActionButton(
            heroTag: 'main',
            onPressed: _toggleExpand,
            backgroundColor: const Color.fromARGB(255, 199, 23, 23),
            child: AnimatedIcon(
              icon: AnimatedIcons.menu_close,
              progress: _animation,
            ),
          ),
        ),
      ],
    );
  }
}
