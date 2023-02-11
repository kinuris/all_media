import 'package:flutter/material.dart';

class HeavyScrollPhysics extends BouncingScrollPhysics {
  const HeavyScrollPhysics({ScrollPhysics? parent}) : super(parent: parent);

  @override
  HeavyScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return HeavyScrollPhysics(parent: buildParent(ancestor));
  }

  @override
  SpringDescription get spring => const SpringDescription(
    mass: 200,
    stiffness: 200,
    damping: 0.5,
  );
}
