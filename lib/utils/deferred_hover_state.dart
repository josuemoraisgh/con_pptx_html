import 'dart:async';

import 'package:flutter/widgets.dart';

mixin DeferredHoverState<T extends StatefulWidget> on State<T> {
  bool hovered = false;

  bool? _pendingHovered;
  bool _hoverUpdateScheduled = false;

  void setHovered(bool value) {
    if (hovered == value && !_hoverUpdateScheduled) return;

    _pendingHovered = value;
    if (_hoverUpdateScheduled) return;

    _hoverUpdateScheduled = true;
    scheduleMicrotask(() {
      _hoverUpdateScheduled = false;
      final next = _pendingHovered;
      _pendingHovered = null;

      if (!mounted || next == null || hovered == next) return;
      setState(() => hovered = next);
    });
  }
}
