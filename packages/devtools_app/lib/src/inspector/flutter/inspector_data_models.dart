// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
import 'dart:math' show max;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import '../../utils.dart';
import '../diagnostics_node.dart';
import '../enum_utils.dart';
import 'story_of_your_layout/flex.dart';

const Type boxConstraintsType = BoxConstraints;

// TODO(albertusangga): Move this to [RemoteDiagnosticsNode] once dart:html app is removed
class LayoutProperties {
  LayoutProperties(RemoteDiagnosticsNode node, {int copyLevel = 1})
      : description = node?.description,
        size = deserializeSize(node?.size),
        constraints = deserializeConstraints(node?.constraints),
        isFlex = node?.isFlex,
        flexFactor = node?.flexFactor,
        children = copyLevel == 0
            ? []
            : node?.childrenNow
                ?.map((child) =>
                    LayoutProperties(child, copyLevel: copyLevel - 1))
                ?.toList(growable: false);

  final List<LayoutProperties> children;
  final BoxConstraints constraints;
  final String description;
  final int flexFactor;
  final bool isFlex;
  final Size size;

  int get totalChildren => children?.length ?? 0;

  bool get hasChildren => children?.isNotEmpty ?? false;

  double get width => size?.width;

  double get height => size?.height;

  List<double> get childrenWidth =>
      children?.map((child) => child.width)?.toList();

  List<double> get childrenHeight =>
      children?.map((child) => child.height)?.toList();

  String describeWidthConstraints() => constraints.hasBoundedWidth
      ? describeAxis(constraints.minWidth, constraints.maxWidth, 'w')
      : 'w=unconstrained';

  String describeHeightConstraints() => constraints.hasBoundedHeight
      ? describeAxis(constraints.minHeight, constraints.maxHeight, 'h')
      : 'h=unconstrained';

  String describeWidth() => 'w=${toStringAsFixed(size.width)}';

  String describeHeight() => 'h=${toStringAsFixed(size.height)}';

  static String describeAxis(double min, double max, String axis) {
    if (min == max) return '$axis=${min.toStringAsFixed(1)}';
    return '${min.toStringAsFixed(1)}<=$axis<=${max.toStringAsFixed(1)}';
  }

  static BoxConstraints deserializeConstraints(Map<String, Object> json) {
    // TODO(albertusangga): Support SliverConstraint
    if (json == null || json['type'] != boxConstraintsType.toString())
      return null;
    // TODO(albertusangga): Simplify this json (i.e: when maxWidth is null it means it is unbounded)
    return BoxConstraints(
      minWidth: json['minWidth'],
      maxWidth: json['hasBoundedWidth'] ? json['maxWidth'] : double.infinity,
      minHeight: json['minHeight'],
      maxHeight: json['hasBoundedHeight'] ? json['maxHeight'] : double.infinity,
    );
  }

  static Size deserializeSize(Map<String, Object> json) {
    if (json == null) return null;
    return Size(json['width'], json['height']);
  }
}

/// TODO(albertusangga): Move this to [RemoteDiagnosticsNode] once dart:html app is removed
class FlexLayoutProperties extends LayoutProperties {
  FlexLayoutProperties._(
    RemoteDiagnosticsNode node, {
    this.direction,
    this.mainAxisAlignment,
    this.mainAxisSize,
    this.crossAxisAlignment,
    this.textDirection,
    this.verticalDirection,
    this.textBaseline,
  }) : super(node) {
    computeSpaces();
  }

  void computeSpaces() {
    if (children.isEmpty) {
      spaceBeforeChildren = spaceAfterChildren = spaceBetweenChildren = null;
    }
    final freeSpace = mainAxisDimension() -
        sum(children.map((child) => mainAxisDimension(child)));
    if (mainAxisAlignment == MainAxisAlignment.start) {
      spaceBeforeChildren = freeSpace;
    } else if (mainAxisAlignment == MainAxisAlignment.end) {
      spaceAfterChildren = freeSpace;
    } else if (mainAxisAlignment == MainAxisAlignment.center) {
      spaceBeforeChildren = spaceAfterChildren = freeSpace / 2.0;
    } else if (mainAxisAlignment == MainAxisAlignment.spaceBetween) {
      spaceBetweenChildren = freeSpace / max(1, children.length - 1);
    } else if (mainAxisAlignment == MainAxisAlignment.spaceAround) {
      spaceBetweenChildren = freeSpace / children.length;
      spaceBeforeChildren = spaceAfterChildren = spaceBetweenChildren / 2.0;
    } else if (mainAxisAlignment == MainAxisAlignment.spaceEvenly) {
      spaceAfterChildren = spaceBeforeChildren =
          spaceBetweenChildren = freeSpace / (children.length + 1);
    }
  }

  final Axis direction;
  final MainAxisAlignment mainAxisAlignment;
  final MainAxisSize mainAxisSize;
  final CrossAxisAlignment crossAxisAlignment;
  final TextDirection textDirection;
  final VerticalDirection verticalDirection;
  final TextBaseline textBaseline;

  double spaceBeforeChildren;
  double spaceBetweenChildren;
  double spaceAfterChildren;

  int _totalFlex;

  static FlexLayoutProperties fromRemoteDiagnosticsNode(
      RemoteDiagnosticsNode node) {
    final Map<String, Object> renderObjectJson = node.json['renderObject'];
    final List<dynamic> properties = renderObjectJson['properties'];
    final Map<String, Object> data = Map<String, Object>.fromIterable(
      properties,
      key: (property) => property['name'],
      value: (property) => property['description'],
    );
    return FlexLayoutProperties._(
      node,
      direction: _directionUtils.enumEntry(data['direction']),
      mainAxisAlignment:
          _mainAxisAlignmentUtils.enumEntry(data['mainAxisAlignment']),
      mainAxisSize: _mainAxisSizeUtils.enumEntry(data['mainAxisSize']),
      crossAxisAlignment:
          _crossAxisAlignmentUtils.enumEntry(data['crossAxisAlignment']),
      textDirection: _textDirectionUtils.enumEntry(data['textDirection']),
      verticalDirection:
          _verticalDirectionUtils.enumEntry(data['verticalDirection']),
      textBaseline: _textBaselineUtils.enumEntry(data['textBaseline']),
    );
  }

  bool get isMainAxisHorizontal => direction == Axis.horizontal;

  bool get isMainAxisVertical => direction == Axis.vertical;

  String get horizontalDirectionDescription =>
      direction == Axis.horizontal ? 'Main Axis' : 'Cross Axis';

  String get verticalDirectionDescription =>
      direction == Axis.vertical ? 'Main Axis' : 'Cross Axis';

  String get type => direction == Axis.horizontal ? 'Row' : 'Column';

  int get totalFlex {
    if (children?.isEmpty ?? true) return 0;
    _totalFlex ??= children
        .map((child) => child.flexFactor ?? 0)
        .reduce((value, element) => value + element);
    return _totalFlex;
  }

  Axis get crossDirection =>
      direction == Axis.horizontal ? Axis.vertical : Axis.horizontal;

  double mainAxisDimension([LayoutProperties properties]) {
    properties ??= this;
    direction == Axis.horizontal ? properties.width : properties.height;
  }

  double crossAxisDimension([LayoutProperties properties]) {
    properties ??= this;
    direction == Axis.vertical ? properties.width : properties.height;
  }

  List<double> get childrenAndSpacesWidths {}

  static final _directionUtils = EnumUtils<Axis>(Axis.values);
  static final _mainAxisAlignmentUtils =
      EnumUtils<MainAxisAlignment>(MainAxisAlignment.values);
  static final _mainAxisSizeUtils =
      EnumUtils<MainAxisSize>(MainAxisSize.values);
  static final _crossAxisAlignmentUtils =
      EnumUtils<CrossAxisAlignment>(CrossAxisAlignment.values);
  static final _textDirectionUtils =
      EnumUtils<TextDirection>(TextDirection.values);
  static final _verticalDirectionUtils =
      EnumUtils<VerticalDirection>(VerticalDirection.values);
  static final _textBaselineUtils =
      EnumUtils<TextBaseline>(TextBaseline.values);
}
