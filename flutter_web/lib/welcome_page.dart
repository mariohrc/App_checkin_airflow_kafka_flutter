import 'package:flutter/material.dart';
import 'float_button.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  void _onStop() {
    // Implement any required functionality here for stopping background processes
    print("Stopping background processes");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Welcome'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedText(
              text: 'Welcome to the App!',
              style: Theme.of(context).textTheme.headlineLarge!,
              duration: const Duration(seconds: 2),
            ),
            const SizedBox(height: 20),
            AnimatedText(
              text: 'Use the floating button to navigate through the app.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge!,
              duration: const Duration(seconds: 2),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingButtonWidget(onStop: _onStop),
    );
  }
}

class AnimatedText extends StatefulWidget {
  final String text;
  final TextStyle style;
  final TextAlign? textAlign;
  final Duration duration;

  const AnimatedText({
    required this.text,
    required this.style,
    this.textAlign,
    required this.duration,
    super.key,
  });

  @override
  AnimatedTextState createState() => AnimatedTextState();
}

class AnimatedTextState extends State<AnimatedText>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    _opacityAnimation =
        Tween<double>(begin: 0.0, end: 1.0).animate(_controller);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacityAnimation,
      child: Text(
        widget.text,
        style: widget.style,
        textAlign: widget.textAlign,
      ),
    );
  }
}
