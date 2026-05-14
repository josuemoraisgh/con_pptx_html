import '../models/pptx_models.dart';

Set<int>? buildVisibleShapeIds(SlideData slide, int step) {
  if (slide.animSteps.isEmpty) return null;

  final animatedIds = <int>{};
  for (final animationStep in slide.animSteps) {
    animatedIds.addAll(animationStep);
  }

  final visible = <int>{};
  for (final element in slide.elements) {
    if (element.shapeId == 0 ||
        !animatedIds.contains(element.shapeId) ||
        _isTitlePlaceholder(element)) {
      visible.add(element.shapeId);
    }
  }

  for (var i = 0; i < slide.animSteps.length && i < step; i++) {
    visible.addAll(slide.animSteps[i]);
  }
  return visible;
}

bool _isTitlePlaceholder(SlideElement element) {
  return element is ShapeElement &&
      (element.placeholderType == 'title' ||
          element.placeholderType == 'ctrTitle' ||
          element.placeholderType == 'subTitle');
}
