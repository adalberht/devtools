// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import '../enum_utils.dart';

const Type boxConstraintsType = BoxConstraints;

Constraints deserializeConstraints(Map<String, Object> json) {
  // TODO(albertusangga): Support SliverConstraint
  if (json == null || json['type'] != boxConstraintsType.toString())
    return null;
  return BoxConstraints(
    minWidth: json['minWidth'],
    maxWidth: json['hasBoundedWidth'] ? json['maxWidth'] : double.infinity,
    minHeight: json['minHeight'],
    maxHeight: json['hasBoundedHeight'] ? json['maxHeight'] : double.infinity,
  );
}

/// TODO(albertusangga): Move this to [RemoteDiagnosticsNode] once dart:html app is removed
@immutable
class RenderFlexProperties {
  const RenderFlexProperties({
    this.direction,
    this.mainAxisAlignment,
    this.mainAxisSize,
    this.crossAxisAlignment,
    this.textDirection,
    this.verticalDirection,
    this.textBaseline,
  });

  final Axis direction;
  final MainAxisAlignment mainAxisAlignment;
  final MainAxisSize mainAxisSize;
  final CrossAxisAlignment crossAxisAlignment;
  final TextDirection textDirection;
  final VerticalDirection verticalDirection;
  final TextBaseline textBaseline;

  // TODO(albertusangga) Add size & constraints in this class

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

  static RenderFlexProperties fromJson(Map<String, Object> renderObjectJson) {
    final List<dynamic> properties = renderObjectJson['properties'];
    // TODO(albertusangga) should we do some checking in the validity of the API contract here?
    final Map<String, Object> data = Map<String, Object>.fromIterable(
      properties,
      key: (property) => property['name'],
      value: (property) => property['description'],
    );

    return RenderFlexProperties(
      direction: _directionUtils.toEnumEntry(data['direction']),
      mainAxisAlignment:
          _mainAxisAlignmentUtils.toEnumEntry(data['mainAxisAlignment']),
      mainAxisSize: _mainAxisSizeUtils.toEnumEntry(data['mainAxisSize']),
      crossAxisAlignment:
          _crossAxisAlignmentUtils.toEnumEntry(data['crossAxisAlignment']),
      textDirection: _textDirectionUtils.toEnumEntry(data['textDirection']),
      verticalDirection:
          _verticalDirectionUtils.toEnumEntry(data['verticalDirection']),
      textBaseline: _textBaselineUtils.toEnumEntry(data['textBaseline']),
    );
  }

  Type get type => direction == Axis.horizontal ? Row : Column;
}
