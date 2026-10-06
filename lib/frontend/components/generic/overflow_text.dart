import "package:async/async.dart";
import "package:flutter/material.dart";

class OverflowText extends StatefulWidget {
  final String text;
  final double width;
  final TextStyle? style;

  /// How fast to scroll the text
  final double scrollSpeed;

  /// How long on the start position before scrolling and
  ///   how long on the end position to jump back to the start position
  final Duration waitDuration;

  const OverflowText(
    this.text, {
    super.key,
    required this.width,
    this.style,
    this.scrollSpeed = 25.0,
    this.waitDuration = const Duration(milliseconds: 1500),
  });

  @override
  State<OverflowText> createState() => _OverflowTextState();
}

// NOTE: Optimization, make this state based
class _OverflowTextState extends State<OverflowText> {
  /// The difference between the container and text width
  double _overflowWidth = 0.0;
  final _scrollContainer = ScrollController();
  CancelableOperation? _delay;

  @override
  void initState() {
    super.initState();

    _scrollContainer.addListener(() {
      if (!_scrollContainer.hasClients ||
          _scrollContainer.position.pixels <
              _scrollContainer.position.maxScrollExtent) {
        return;
      }

      _delay = CancelableOperation.fromFuture(
        Future.delayed(widget.waitDuration, () {
          _scrollContainer.jumpTo(0);

          _delay = CancelableOperation.fromFuture(
            Future.delayed(widget.waitDuration, () => _scrollToEnd()),
          );
        }),
      );
    });

    WidgetsBinding.instance.addPostFrameCallback((_) => _initScroll());
  }

  @override
  void didUpdateWidget(covariant OverflowText oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.text == widget.text && oldWidget.width == widget.width) {
      return;
    }

    _scrollContainer.jumpTo(0);
    _initScroll();
  }

  void _initScroll() {
    _delay?.cancel();
    _delay = null;

    final textWidth = (TextPainter(
      text: TextSpan(text: widget.text, style: widget.style),
      maxLines: 1,
      textDirection: TextDirection.ltr,
    )..layout()).size.width;

    if (!_scrollContainer.hasClients || widget.width >= textWidth) {
      return;
    }

    _overflowWidth = textWidth - widget.width;
    _delay = CancelableOperation.fromFuture(
      Future.delayed(widget.waitDuration, () => _scrollToEnd()),
    );
  }

  void _scrollToEnd() {
    _scrollContainer.animateTo(
      _scrollContainer.position.maxScrollExtent,
      duration: Duration(
        milliseconds: (_overflowWidth / widget.scrollSpeed * 1000).round(),
      ),
      curve: Curves.linear,
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.width,
      child: SingleChildScrollView(
        physics: NeverScrollableScrollPhysics(),
        controller: _scrollContainer,
        scrollDirection: Axis.horizontal,
        child: Text(widget.text, style: widget.style),
      ),
    );
  }
}
