// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' show SemanticsRole;

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';

/// A group for radios.
///
/// This widget treats all radios, such as [RawRadio], [Radio], [CupertinoRadio]
/// in the sub tree with the same type T as a group. Radios with different types
/// are not included in the group.
///
/// This widget handles the group value for the radios in the subtree with the
/// same value type.
///
/// Using this widget also provides keyboard navigation and semantics for the
/// radio buttons that matches [APG](https://www.w3.org/WAI/ARIA/apg/patterns/radio/).
///
/// The keyboard behaviors are:
/// * Tab and Shift+Tab: moves focus into and out of radio group. When focus
///   moves into a radio group and a radio button is select, focus is set on
///   selected button. Otherwise, it focus the first radio button in reading
///   order.
/// * Space: toggle the selection on the focused radio button.
/// * Right and down arrow key: move selection to next radio button in the group
///   in reading order.
/// * Left and up arrow key: move selection to previous radio button in the
///   group in reading order.
///
/// Arrow keys will wrap around if it reach the first or last radio in the
/// group.
///
/// {@tool dartpad}
/// Here is an example of RadioGroup widget.
///
/// Try using tab, arrow keys, and space to see how the widget responds.
///
/// ** See code in examples/api/lib/widgets/radio_group/radio_group.0.dart **
/// {@end-tool}
class RadioGroup<T> extends StatefulWidget {
  /// Creates a radio group.
  ///
  /// The `groupValue` set the selection on a subtree radio with the same
  /// [RawRadio.value].
  ///
  /// The `onChanged` is called when the selection has changed in the subtree
  /// radios.
  const RadioGroup({
    super.key,
    this.groupValue,
    required this.onChanged,
    required this.child,
  });

  /// The selected value under this radio group.
  ///
  /// [RawRadio] under this radio group where its [RawRadio.value] equals to this
  /// value will be selected.
  final T? groupValue;

  /// Called when selection has changed.
  ///
  /// The value can be null when unselect the [RawRadio] with
  /// [RawRadio.toggleable] set to true.
  final ValueChanged<T?> onChanged;

  /// {@macro flutter.widgets.ProxyWidget.child}
  final Widget child;

  /// Gets the [RadioGroupRegistry] from the above the context.
  ///
  /// This registers a dependencies on the context that it causes rebuild
  /// if [RadioGroupRegistry] has changed or its
  /// [RadioGroupRegistry.groupValue] has changed.
  static RadioGroupRegistry<T>? maybeOf<T>(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<_RadioGroupStateScope<T>>()
        ?.state;
  }

  @override
  State<StatefulWidget> createState() => _RadioGroupState<T>();
}

class _RadioGroupState<T> extends State<RadioGroup<T>>
    implements RadioGroupRegistry<T> {
  // late final Map<ShortcutActivator, Intent> _radioGroupShortcuts =
  //     <ShortcutActivator, Intent>{
  //       const SingleActivator(LogicalKeyboardKey.arrowLeft): VoidCallbackIntent(
  //         _selectPreviousRadio,
  //       ),
  //       const SingleActivator(LogicalKeyboardKey.arrowRight):
  //           VoidCallbackIntent(_selectNextRadio),
  //       const SingleActivator(LogicalKeyboardKey.arrowDown): VoidCallbackIntent(
  //         _selectNextRadio,
  //       ),
  //       const SingleActivator(LogicalKeyboardKey.arrowUp): VoidCallbackIntent(
  //         _selectPreviousRadio,
  //       ),
  //       const SingleActivator(LogicalKeyboardKey.space): VoidCallbackIntent(
  //         _toggleFocusedRadio,
  //       ),
  //     };

  final Set<RadioClient<T>> _radios = <RadioClient<T>>{};

  bool _debugHasScheduledSingleSelectionCheck = false;

  /// Schedules a check for the next frame to verify that there is only one
  /// radio with the group value.
  bool _debugScheduleSingleSelectionCheck() {
    if (_debugHasScheduledSingleSelectionCheck) {
      return true;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _debugHasScheduledSingleSelectionCheck = false;
      if (!mounted || _debugCheckOnlySingleSelection()) {
        return;
      }
      throw FlutterError(
        "RadioGroupPolicy can't be used for a radio group that allows multiple selection.",
      );
    }, debugLabel: 'RadioGroup.singleSelectionCheck');
    _debugHasScheduledSingleSelectionCheck = true;
    return true;
  }

  bool _debugCheckOnlySingleSelection() {
    return _radios
            .where((RadioClient<T> radio) => radio.radioValue == groupValue)
            .length <
        2;
  }

  @override
  T? get groupValue => widget.groupValue;

  @override
  void registerClient(RadioClient<T> radio) {
    _radios.add(radio);
    assert(_debugScheduleSingleSelectionCheck());
  }

  @override
  void unregisterClient(RadioClient<T> radio) => _radios.remove(radio);

  void _toggleFocusedRadio() {
    final RadioClient<T>? radio = _radios.firstWhereOrNull(
      (RadioClient<T> radio) => radio.focusNode.hasFocus,
    );
    if (radio == null) {
      return;
    }
    if (radio.radioValue != widget.groupValue) {
      onChanged(radio.radioValue);
      return;
    }

    if (radio.tristate) {
      onChanged(null);
    }
  }

  @override
  ValueChanged<T?> get onChanged => widget.onChanged;

  // void _selectNextRadio() => _selectRadioInDirection(true);

  // void _selectPreviousRadio() => _selectRadioInDirection(false);

  // void _selectRadioInDirection(bool forward) {
  //   if (_radios.length < 2) {
  //     return;
  //   }
  //   final FocusNode? currentFocus = _radios
  //       .firstWhereOrNull((RadioClient<T> radio) => radio.focusNode.hasFocus)
  //       ?.focusNode;
  //   if (currentFocus == null) {
  //     // The focused node is either a non interactive radio or other controls.
  //     return;
  //   }
  //   final List<FocusNode> sorted = _ReadingOrderTraversalPolicy.sort(
  //     _radios.map<FocusNode>((RadioClient<T> radio) => radio.focusNode),
  //   ).toList();
  //   final Iterable<FocusNode> nodesInEffectiveOrder = forward
  //       ? sorted
  //       : sorted.reversed;

  //   final Iterator<FocusNode> iterator = nodesInEffectiveOrder.iterator;
  //   FocusNode? nextFocus;
  //   while (iterator.moveNext()) {
  //     if (iterator.current == currentFocus) {
  //       if (iterator.moveNext()) {
  //         nextFocus = iterator.current;
  //       }
  //       break;
  //     }
  //   }
  //   // Current focus is at the end, the next focus should wrap around.
  //   nextFocus ??= nodesInEffectiveOrder.first;
  //   final RadioClient<T> radioToSelect = _radios.firstWhere(
  //     (RadioClient<T> radio) => radio.focusNode == nextFocus,
  //   );
  //   onChanged(radioToSelect.radioValue);
  //   nextFocus.requestFocus();
  // }

  @override
  Widget build(BuildContext context) {
    assert(_debugScheduleSingleSelectionCheck());

    return Semantics(
      container: true,
      role: SemanticsRole.radioGroup,
      child: FocusTraversalGroup(
        policy: _SkipUnselectedRadioPolicy<T>(_radios, widget.groupValue),
        child: _RadioGroupStateScope<T>(
          state: this,
          groupValue: widget.groupValue,
          child: widget.child,
        ),
      ),
    );
  }
}

class _RadioGroupStateScope<T> extends InheritedWidget {
  const _RadioGroupStateScope({
    required this.state,
    required this.groupValue,
    required super.child,
  }) : super();
  final _RadioGroupState<T> state;
  // Need to include group value to notify listener when group value changes.
  final T? groupValue;

  @override
  bool updateShouldNotify(covariant _RadioGroupStateScope<T> oldWidget) {
    return state != oldWidget.state || groupValue != oldWidget.groupValue;
  }
}

/// An abstract interface for registering a group of radios.
///
/// Use [registerClient] or [unregisterClient] to handle registrations of radios.
///
/// The registry manages the group value for the radios. The radio needs to call
/// [onChanged] to notify the group value needs to be changed.
abstract class RadioGroupRegistry<T> {
  /// The group value for the group.
  T? get groupValue;

  /// Registers a radio client.
  ///
  /// The subclass provides additional features, such as keyboard navigation
  /// for the registered clients.
  void registerClient(RadioClient<T> radio);

  /// Unregisters a radio client.
  void unregisterClient(RadioClient<T> radio);

  /// Notifies the registry that the a radio is selected or unselected.
  ValueChanged<T?> get onChanged;
}

/// A client for a [RadioGroupRegistry].
///
/// This is typically mixed with a [State].
///
/// To register to a [RadioGroupRegistry], assign the registry to [registry].
///
/// To unregister from previous [RadioGroupRegistry], either assign a different
/// value to [registry] or set it to null.
mixin RadioClient<T> {
  /// Whether this radio support toggles.
  ///
  /// Used by registry to provide additional feature such as keyboard support.
  bool get tristate;

  /// This value this radio represents.
  ///
  /// Used by registry to provide additional feature such as keyboard support.
  T get radioValue;

  /// Focus node for this radio.
  ///
  /// Used by registry to provide additional feature such as keyboard support.
  FocusNode get focusNode;

  /// The [RadioGroupRegistry] this client register to.
  ///
  /// Setting this property automatically register to the new value and
  /// unregister the old value.
  ///
  /// This should set to null when dispose.
  RadioGroupRegistry<T>? get registry => _registry;
  RadioGroupRegistry<T>? _registry;
  set registry(RadioGroupRegistry<T>? newRegistry) {
    if (_registry != newRegistry) {
      _registry?.unregisterClient(this);
    }
    _registry = newRegistry;
    _registry?.registerClient(this);
  }
}

/// A traversal policy that is the same as [ReadingOrderTraversalPolicy] except
/// it skips nodes of unselected radio button if there is one selected radio
/// button.
///
/// If none of the radio is selected, this defaults to
/// [ReadingOrderTraversalPolicy] for all nodes.
///
/// This policy is to ensure when tabbing into a radio group, it will only focus
/// the current selected radio button and prevent focus from reaching unselected
/// ones.
class _SkipUnselectedRadioPolicy<T> extends ReadingOrderTraversalPolicy {
  _SkipUnselectedRadioPolicy(this.radios, this.groupValue);
  final Set<RadioClient<T>> radios;
  final T? groupValue;

  bool _radioSelected(RadioClient<T> radio) => radio.radioValue == groupValue;

  @override
  Iterable<FocusNode> sortDescendants(
    Iterable<FocusNode> descendants,
    FocusNode currentNode,
  ) {
    final Iterable<FocusNode> nodesInReadOrder = super.sortDescendants(
      descendants,
      currentNode,
    );
    RadioClient<T>? selected = radios.firstWhereOrNull(_radioSelected);

    if (selected == null) {
      // None of the radio are selected. Select the first radio in read order.
      final Map<FocusNode, RadioClient<T>> radioFocusNodes =
          <FocusNode, RadioClient<T>>{};
      for (final RadioClient<T> radio in radios) {
        radioFocusNodes[radio.focusNode] = radio;
      }

      for (final FocusNode node in nodesInReadOrder) {
        selected = radioFocusNodes[node];
        if (selected != null) {
          break;
        }
      }
    }

    if (selected == null) {
      // None of the radio is selected or focusable, defaults to reading order
      return nodesInReadOrder;
    }

    // Nodes that are not selected AND not currently focused, since we can't
    // remove the focused node from the sorted result.
    final Set<FocusNode> nodeToSkip = radios
        .where(
          (RadioClient<T> radio) =>
              selected != radio && radio.focusNode != currentNode,
        )
        .map<FocusNode>((RadioClient<T> radio) => radio.focusNode)
        .toSet();
    final Iterable<FocusNode> skipsNonSelected = descendants.where(
      (FocusNode node) => !nodeToSkip.contains(node),
    );
    return super.sortDescendants(skipsNonSelected, currentNode);
  }
}


// class _ReadingOrderTraversalPolicy{


//   static Iterable<FocusNode> sort(Iterable<FocusNode> nodes) {
//     if (nodes.length <= 1) {
//       return nodes;
//     }

//     final List<_ReadingOrderSortData> data = <_ReadingOrderSortData>[
//       for (final FocusNode node in nodes) _ReadingOrderSortData(node),
//     ];

//     final List<FocusNode> sortedList = <FocusNode>[];
//     final List<_ReadingOrderSortData> unplaced = data;

//     // Pick the initial widget as the one that is at the beginning of the band
//     // of the topmost, or the topmost, if there are no others in its band.
//     _ReadingOrderSortData current = _pickNext(unplaced);
//     sortedList.add(current.node);
//     unplaced.remove(current);

//     // Go through each node, picking the next one after eliminating the previous
//     // one, since removing the previously picked node will expose a new band in
//     // which to choose candidates.
//     while (unplaced.isNotEmpty) {
//       final _ReadingOrderSortData next = _pickNext(unplaced);
//       current = next;
//       sortedList.add(current.node);
//       unplaced.remove(current);
//     }
//     return sortedList;
//   }  static List<_ReadingOrderDirectionalGroupData> _collectDirectionalityGroups(
//     Iterable<_ReadingOrderSortData> candidates,
//   ) {
//     TextDirection? currentDirection = candidates.first.directionality;
//     List<_ReadingOrderSortData> currentGroup = <_ReadingOrderSortData>[];
//     final List<_ReadingOrderDirectionalGroupData> result = <_ReadingOrderDirectionalGroupData>[];
//     // Split candidates into runs of the same directionality.
//     for (final _ReadingOrderSortData candidate in candidates) {
//       if (candidate.directionality == currentDirection) {
//         currentGroup.add(candidate);
//         continue;
//       }
//       currentDirection = candidate.directionality;
//       result.add(_ReadingOrderDirectionalGroupData(currentGroup));
//       currentGroup = <_ReadingOrderSortData>[candidate];
//     }
//     if (currentGroup.isNotEmpty) {
//       result.add(_ReadingOrderDirectionalGroupData(currentGroup));
//     }
//     // Sort each group separately. Each group has the same directionality.
//     for (final _ReadingOrderDirectionalGroupData bandGroup in result) {
//       if (bandGroup.members.length == 1) {
//         continue; // No need to sort one node.
//       }
//       _ReadingOrderSortData.sortWithDirectionality(bandGroup.members, bandGroup.directionality!);
//     }
//     return result;
//   }


//     static _ReadingOrderSortData _pickNext(List<_ReadingOrderSortData> candidates) {
//     // Find the topmost node by sorting on the top of the rectangles.
//     mergeSort<_ReadingOrderSortData>(
//       candidates,
//       compare: (_ReadingOrderSortData a, _ReadingOrderSortData b) =>
//           a.rect.top.compareTo(b.rect.top),
//     );
//     final _ReadingOrderSortData topmost = candidates.first;

//     // Find the candidates that are in the same horizontal band as the current one.
//     List<_ReadingOrderSortData> inBand(
//       _ReadingOrderSortData current,
//       Iterable<_ReadingOrderSortData> candidates,
//     ) {
//       final Rect band = Rect.fromLTRB(
//         double.negativeInfinity,
//         current.rect.top,
//         double.infinity,
//         current.rect.bottom,
//       );
//       return candidates.where((_ReadingOrderSortData item) {
//         return !item.rect.intersect(band).isEmpty;
//       }).toList();
//     }

//     final List<_ReadingOrderSortData> inBandOfTop = inBand(topmost, candidates);
//     // It has to have at least topmost in it if the topmost is not degenerate.
//     assert(topmost.rect.isEmpty || inBandOfTop.isNotEmpty);

//     // The topmost rect is in a band by itself, so just return that one.
//     if (inBandOfTop.length <= 1) {
//       return topmost;
//     }

//     // Now that we know there are others in the same band as the topmost, then pick
//     // the one at the beginning, depending on the text direction in force.

//     // Find out the directionality of the nearest common Directionality
//     // ancestor for all nodes. This provides a base directionality to use for
//     // the ordering of the groups.
//     final TextDirection? nearestCommonDirectionality = _ReadingOrderSortData.commonDirectionalityOf(
//       inBandOfTop,
//     );

//     // Do an initial common-directionality-based sort to get consistent geometric
//     // ordering for grouping into directionality groups. It has to use the
//     // common directionality to be able to group into sane groups for the
//     // given directionality, since rectangles can overlap and give different
//     // results for different directionalities.
//     _ReadingOrderSortData.sortWithDirectionality(inBandOfTop, nearestCommonDirectionality!);

//     // Collect the top band into internally sorted groups with shared directionality.
//     final List<_ReadingOrderDirectionalGroupData> bandGroups = _collectDirectionalityGroups(
//       inBandOfTop,
//     );
//     if (bandGroups.length == 1) {
//       // There's only one directionality group, so just send back the first
//       // one in that group, since it's already sorted.
//       return bandGroups.first.members.first;
//     }

//     // Sort the groups based on the common directionality and bounding boxes.
//     _ReadingOrderDirectionalGroupData.sortWithDirectionality(
//       bandGroups,
//       nearestCommonDirectionality,
//     );
//     return bandGroups.first.members.first;
//   }

// }

// class _ReadingOrderDirectionalGroupData with Diagnosticable {
//   _ReadingOrderDirectionalGroupData(this.members);

//   final List<_ReadingOrderSortData> members;

//   TextDirection? get directionality => members.first.directionality;

//   Rect? _rect;
//   Rect get rect {
//     if (_rect == null) {
//       for (final Rect rect in members.map<Rect>((_ReadingOrderSortData data) => data.rect)) {
//         _rect ??= rect;
//         _rect = _rect!.expandToInclude(rect);
//       }
//     }
//     return _rect!;
//   }

//   List<Directionality> get memberAncestors {
//     if (_memberAncestors == null) {
//       _memberAncestors = <Directionality>[];
//       for (final _ReadingOrderSortData member in members) {
//         _memberAncestors!.addAll(member.directionalAncestors);
//       }
//     }
//     return _memberAncestors!;
//   }

//   List<Directionality>? _memberAncestors;

//   static void sortWithDirectionality(
//     List<_ReadingOrderDirectionalGroupData> list,
//     TextDirection directionality,
//   ) {
//     mergeSort<_ReadingOrderDirectionalGroupData>(
//       list,
//       compare: (_ReadingOrderDirectionalGroupData a, _ReadingOrderDirectionalGroupData b) =>
//           switch (directionality) {
//             TextDirection.ltr => a.rect.left.compareTo(b.rect.left),
//             TextDirection.rtl => b.rect.right.compareTo(a.rect.right),
//           },
//     );
//   }

//   @override
//   void debugFillProperties(DiagnosticPropertiesBuilder properties) {
//     super.debugFillProperties(properties);
//     properties.add(DiagnosticsProperty<TextDirection>('directionality', directionality));
//     properties.add(DiagnosticsProperty<Rect>('rect', rect));
//     properties.add(
//       IterableProperty<String>(
//         'members',
//         members.map<String>((_ReadingOrderSortData member) {
//           return '"${member.node.debugLabel}"(${member.rect})';
//         }),
//       ),
//     );
//   }
// }


// class _ReadingOrderSortData with Diagnosticable {
//   _ReadingOrderSortData(this.node)
//     : rect = node.rect,
//       directionality = _findDirectionality(node.context!);

//   final TextDirection? directionality;
//   final Rect rect;
//   final FocusNode node;

//   // Find the directionality in force for a build context without creating a
//   // dependency.
//   static TextDirection? _findDirectionality(BuildContext context) {
//     return context.getInheritedWidgetOfExactType<Directionality>()?.textDirection;
//   }

//   /// Finds the common Directional ancestor of an entire list of groups.
//   static TextDirection? commonDirectionalityOf(List<_ReadingOrderSortData> list) {
//     final Iterable<Set<Directionality>> allAncestors = list.map<Set<Directionality>>(
//       (_ReadingOrderSortData member) => member.directionalAncestors.toSet(),
//     );
//     Set<Directionality>? common;
//     for (final Set<Directionality> ancestorSet in allAncestors) {
//       common ??= ancestorSet;
//       common = common.intersection(ancestorSet);
//     }
//     if (common!.isEmpty) {
//       // If there is no common ancestor, then arbitrarily pick the
//       // directionality of the first group, which is the equivalent of the
//       // "first strongly typed" item in a bidirectional algorithm.
//       return list.first.directionality;
//     }
//     // Find the closest common ancestor. The memberAncestors list contains the
//     // ancestors for all members, but the first member's ancestry was
//     // added in order from nearest to furthest, so we can still use that
//     // to determine the closest one.
//     return list.first.directionalAncestors.firstWhere(common.contains).textDirection;
//   }

//   static void sortWithDirectionality(
//     List<_ReadingOrderSortData> list,
//     TextDirection directionality,
//   ) {
//     mergeSort<_ReadingOrderSortData>(
//       list,
//       compare: (_ReadingOrderSortData a, _ReadingOrderSortData b) => switch (directionality) {
//         TextDirection.ltr => a.rect.left.compareTo(b.rect.left),
//         TextDirection.rtl => b.rect.right.compareTo(a.rect.right),
//       },
//     );
//   }

//   /// Returns the list of Directionality ancestors, in order from nearest to
//   /// furthest.
//   Iterable<Directionality> get directionalAncestors {
//     List<Directionality> getDirectionalityAncestors(BuildContext context) {
//       final List<Directionality> result = <Directionality>[];
//       InheritedElement? directionalityElement = context
//           .getElementForInheritedWidgetOfExactType<Directionality>();
//       while (directionalityElement != null) {
//         result.add(directionalityElement.widget as Directionality);
//         directionalityElement = _getAncestor(
//           directionalityElement,
//         )?.getElementForInheritedWidgetOfExactType<Directionality>();
//       }
//       return result;
//     }

//     _directionalAncestors ??= getDirectionalityAncestors(node.context!);
//     return _directionalAncestors!;
//   }

//   List<Directionality>? _directionalAncestors;

//   @override
//   void debugFillProperties(DiagnosticPropertiesBuilder properties) {
//     super.debugFillProperties(properties);
//     properties.add(DiagnosticsProperty<TextDirection>('directionality', directionality));
//     properties.add(StringProperty('name', node.debugLabel, defaultValue: null));
//     properties.add(DiagnosticsProperty<Rect>('rect', rect));
//   }
// }

// enum DiagnosticsTreeStyle {
//   /// A style that does not display the tree, for release mode.
//   none,

//   /// Sparse style for displaying trees.
//   ///
//   /// See also:
//   ///
//   ///  * [RenderObject], which uses this style.
//   sparse,

//   /// Connects a node to its parent with a dashed line.
//   ///
//   /// See also:
//   ///
//   ///  * [RenderSliverMultiBoxAdaptor], which uses this style to distinguish
//   ///    offstage children from onstage children.
//   offstage,

//   /// Slightly more compact version of the [sparse] style.
//   ///
//   /// See also:
//   ///
//   ///  * [Element], which uses this style.
//   dense,

//   /// Style that enables transitioning from nodes of one style to children of
//   /// another.
//   ///
//   /// See also:
//   ///
//   ///  * [RenderParagraph], which uses this style to display a [TextSpan] child
//   ///    in a way that is compatible with the [DiagnosticsTreeStyle.sparse]
//   ///    style of the [RenderObject] tree.
//   transition,

//   /// Style for displaying content describing an error.
//   ///
//   /// See also:
//   ///
//   ///  * [FlutterError], which uses this style for the root node in a tree
//   ///    describing an error.
//   error,

//   /// Render the tree just using whitespace without connecting parents to
//   /// children using lines.
//   ///
//   /// See also:
//   ///
//   ///  * [SliverGeometry], which uses this style.
//   whitespace,

//   /// Render the tree without indenting children at all.
//   ///
//   /// See also:
//   ///
//   ///  * [DiagnosticsStackTrace], which uses this style.
//   flat,

//   /// Render the tree on a single line without showing children.
//   singleLine,

//   /// Render the tree using a style appropriate for properties that are part
//   /// of an error message.
//   ///
//   /// The name is placed on one line with the value and properties placed on
//   /// the following line.
//   ///
//   /// See also:
//   ///
//   ///  * [singleLine], which displays the same information but keeps the
//   ///    property and value on the same line.
//   errorProperty,

//   /// Render only the immediate properties of a node instead of the full tree.
//   ///
//   /// See also:
//   ///
//   ///  * [DebugOverflowIndicatorMixin], which uses this style to display just
//   ///    the immediate children of a node.
//   shallow,

//   /// Render only the children of a node truncating before the tree becomes too
//   /// large.
//   truncateChildren,
// }

// class DiagnosticsProperty<T> extends DiagnosticsNode {
//   /// Create a diagnostics property.
//   ///
//   /// The [level] argument is just a suggestion and can be overridden if
//   /// something else about the property causes it to have a lower or higher
//   /// level. For example, if the property value is null and [missingIfNull] is
//   /// true, [level] is raised to [DiagnosticLevel.warning].
//   DiagnosticsProperty(
//     String? name,
//     T? value, {
//     String? description,
//     String? ifNull,
//     this.ifEmpty,
//     super.showName,
//     super.showSeparator,
//     this.defaultValue = kNoDefaultValue,
//     this.tooltip,
//     this.missingIfNull = false,
//     super.linePrefix,
//     this.expandableValue = false,
//     this.allowWrap = true,
//     this.allowNameWrap = true,
//     DiagnosticsTreeStyle super.style = DiagnosticsTreeStyle.singleLine,
//     DiagnosticLevel level = DiagnosticLevel.info,
//   }) : _description = description,
//        _valueComputed = true,
//        _value = value,
//        _computeValue = null,
//        ifNull = ifNull ?? (missingIfNull ? 'MISSING' : null),
//        _defaultLevel = level,
//        super(name: name);

//   /// Property with a [value] that is computed only when needed.
//   ///
//   /// Use if computing the property [value] may throw an exception or is
//   /// expensive.
//   ///
//   /// The [level] argument is just a suggestion and can be overridden
//   /// if something else about the property causes it to have a lower or higher
//   /// level. For example, if calling `computeValue` throws an exception, [level]
//   /// will always return [DiagnosticLevel.error].
//   DiagnosticsProperty.lazy(
//     String? name,
//     ComputePropertyValueCallback<T> computeValue, {
//     String? description,
//     String? ifNull,
//     this.ifEmpty,
//     super.showName,
//     super.showSeparator,
//     this.defaultValue = kNoDefaultValue,
//     this.tooltip,
//     this.missingIfNull = false,
//     this.expandableValue = false,
//     this.allowWrap = true,
//     this.allowNameWrap = true,
//     DiagnosticsTreeStyle super.style = DiagnosticsTreeStyle.singleLine,
//     DiagnosticLevel level = DiagnosticLevel.info,
//   }) : assert(defaultValue == kNoDefaultValue || defaultValue is T?),
//        _description = description,
//        _valueComputed = false,
//        _value = null,
//        _computeValue = computeValue,
//        _defaultLevel = level,
//        ifNull = ifNull ?? (missingIfNull ? 'MISSING' : null),
//        super(name: name);

//   final String? _description;

//   /// Whether to expose properties and children of the value as properties and
//   /// children.
//   final bool expandableValue;

//   @override
//   final bool allowWrap;

//   @override
//   final bool allowNameWrap;

//   @override
//   Map<String, Object?> toJsonMap(DiagnosticsSerializationDelegate delegate) {
//     final T? v = value;
//     List<Map<String, Object?>>? properties;
//     if (delegate.expandPropertyValues &&
//         delegate.includeProperties &&
//         v is Diagnosticable &&
//         getProperties().isEmpty) {
//       // Exclude children for expanded nodes to avoid cycles.
//       delegate = delegate.copyWith(subtreeDepth: 0, includeProperties: false);
//       properties = DiagnosticsNode.toJsonList(
//         delegate.filterProperties(v.toDiagnosticsNode().getProperties(), this),
//         this,
//         delegate,
//       );
//     }
//     final Map<String, Object?> json = super.toJsonMap(delegate);
//     if (properties != null) {
//       json['properties'] = properties;
//     }
//     if (defaultValue != kNoDefaultValue) {
//       json['defaultValue'] = defaultValue.toString();
//     }
//     if (ifEmpty != null) {
//       json['ifEmpty'] = ifEmpty;
//     }
//     if (ifNull != null) {
//       json['ifNull'] = ifNull;
//     }
//     if (tooltip != null) {
//       json['tooltip'] = tooltip;
//     }
//     json['missingIfNull'] = missingIfNull;
//     if (exception != null) {
//       json['exception'] = exception.toString();
//     }
//     json['propertyType'] = propertyType.toString();
//     json['defaultLevel'] = _defaultLevel.name;
//     if (value is Diagnosticable || value is DiagnosticsNode) {
//       json['isDiagnosticableValue'] = true;
//     }
//     if (v is num) {
//       // TODO(jacob314): Workaround, since JSON.stringify replaces infinity and NaN with null,
//       // https://github.com/flutter/flutter/issues/39937#issuecomment-529558033)
//       json['value'] = v.isFinite ? v : v.toString();
//     }
//     if (value is String || value is bool || value == null) {
//       json['value'] = value;
//     }
//     return json;
//   }

//   /// Returns a string representation of the property value.
//   ///
//   /// Subclasses should override this method instead of [toDescription] to
//   /// customize how property values are converted to strings.
//   ///
//   /// Overriding this method ensures that behavior controlling how property
//   /// values are decorated to generate a nice [toDescription] are consistent
//   /// across all implementations. Debugging tools may also choose to use
//   /// [valueToString] directly instead of [toDescription].
//   ///
//   /// `parentConfiguration` specifies how the parent is rendered as text art.
//   /// For example, if the parent places all properties on one line, the value
//   /// of the property should be displayed without line breaks if possible.
//   String valueToString({TextTreeConfiguration? parentConfiguration}) {
//     final T? v = value;
//     // DiagnosticableTree values are shown using the shorter toStringShort()
//     // instead of the longer toString() because the toString() for a
//     // DiagnosticableTree value is likely too large to be useful.
//     return v is DiagnosticableTree ? v.toStringShort() : v.toString();
//   }

//   @override
//   String toDescription({TextTreeConfiguration? parentConfiguration}) {
//     if (_description != null) {
//       return _addTooltip(_description);
//     }

//     if (exception != null) {
//       return 'EXCEPTION (${exception.runtimeType})';
//     }

//     if (ifNull != null && value == null) {
//       return _addTooltip(ifNull!);
//     }

//     String result = valueToString(parentConfiguration: parentConfiguration);
//     if (result.isEmpty && ifEmpty != null) {
//       result = ifEmpty!;
//     }
//     return _addTooltip(result);
//   }

//   /// If a [tooltip] is specified, add the tooltip it to the end of `text`
//   /// enclosing it parenthesis to disambiguate the tooltip from the rest of
//   /// the text.
//   String _addTooltip(String text) {
//     return tooltip == null ? text : '$text ($tooltip)';
//   }

//   /// Description if the property [value] is null.
//   final String? ifNull;

//   /// Description if the property description would otherwise be empty.
//   final String? ifEmpty;

//   /// Optional tooltip typically describing the property.
//   ///
//   /// Example tooltip: 'physical pixels per logical pixel'
//   ///
//   /// If present, the tooltip is added in parenthesis after the raw value when
//   /// generating the string description.
//   final String? tooltip;

//   /// Whether a [value] of null causes the property to have [level]
//   /// [DiagnosticLevel.warning] warning that the property is missing a [value].
//   final bool missingIfNull;

//   /// The type of the property [value].
//   ///
//   /// This is determined from the type argument `T` used to instantiate the
//   /// [DiagnosticsProperty] class. This means that the type is available even if
//   /// [value] is null, but it also means that the [propertyType] is only as
//   /// accurate as the type provided when invoking the constructor.
//   ///
//   /// Generally, this is only useful for diagnostic tools that should display
//   /// null values in a manner consistent with the property type. For example, a
//   /// tool might display a null [Color] value as an empty rectangle instead of
//   /// the word "null".
//   Type get propertyType => T;

//   /// Returns the value of the property either from cache or by invoking a
//   /// [ComputePropertyValueCallback].
//   ///
//   /// If an exception is thrown invoking the [ComputePropertyValueCallback],
//   /// [value] returns null and the exception thrown can be found via the
//   /// [exception] property.
//   ///
//   /// See also:
//   ///
//   ///  * [valueToString], which converts the property value to a string.
//   @override
//   T? get value {
//     _maybeCacheValue();
//     return _value;
//   }

//   T? _value;

//   bool _valueComputed;

//   Object? _exception;

//   /// Exception thrown if accessing the property [value] threw an exception.
//   ///
//   /// Returns null if computing the property value did not throw an exception.
//   Object? get exception {
//     _maybeCacheValue();
//     return _exception;
//   }

//   void _maybeCacheValue() {
//     if (_valueComputed) {
//       return;
//     }

//     _valueComputed = true;
//     assert(_computeValue != null);
//     try {
//       _value = _computeValue!();
//     } catch (exception) {
//       // The error is reported to inspector; rethrowing would destroy the
//       // debugging experience.
//       _exception = exception;
//       _value = null;
//     }
//   }

//   /// The default value of this property, when it has not been set to a specific
//   /// value.
//   ///
//   /// For most [DiagnosticsProperty] classes, if the [value] of the property
//   /// equals [defaultValue], then the priority [level] of the property is
//   /// downgraded to [DiagnosticLevel.fine] on the basis that the property value
//   /// is uninteresting. This is implemented by [isInteresting].
//   ///
//   /// The [defaultValue] is [kNoDefaultValue] by default. Otherwise it must be of
//   /// type `T?`.
//   final Object? defaultValue;

//   /// Whether to consider the property's value interesting. When a property is
//   /// uninteresting, its [level] is downgraded to [DiagnosticLevel.fine]
//   /// regardless of the value provided as the constructor's `level` argument.
//   bool get isInteresting => defaultValue == kNoDefaultValue || value != defaultValue;

//   final DiagnosticLevel _defaultLevel;

//   /// Priority level of the diagnostic used to control which diagnostics should
//   /// be shown and filtered.
//   ///
//   /// The property level defaults to the value specified by the [level]
//   /// constructor argument. The level is raised to [DiagnosticLevel.error] if
//   /// an [exception] was thrown getting the property [value]. The level is
//   /// raised to [DiagnosticLevel.warning] if the property [value] is null and
//   /// the property is not allowed to be null due to [missingIfNull]. The
//   /// priority level is lowered to [DiagnosticLevel.fine] if the property
//   /// [value] equals [defaultValue].
//   @override
//   DiagnosticLevel get level {
//     if (_defaultLevel == DiagnosticLevel.hidden) {
//       return _defaultLevel;
//     }

//     if (exception != null) {
//       return DiagnosticLevel.error;
//     }

//     if (value == null && missingIfNull) {
//       return DiagnosticLevel.warning;
//     }

//     if (!isInteresting) {
//       return DiagnosticLevel.fine;
//     }

//     return _defaultLevel;
//   }

//   final ComputePropertyValueCallback<T>? _computeValue;

//   @override
//   List<DiagnosticsNode> getProperties() {
//     if (expandableValue) {
//       final T? object = value;
//       if (object is DiagnosticsNode) {
//         return object.getProperties();
//       }
//       if (object is Diagnosticable) {
//         return object.toDiagnosticsNode(style: style).getProperties();
//       }
//     }
//     return const <DiagnosticsNode>[];
//   }

//   @override
//   List<DiagnosticsNode> getChildren() {
//     if (expandableValue) {
//       final T? object = value;
//       if (object is DiagnosticsNode) {
//         return object.getChildren();
//       }
//       if (object is Diagnosticable) {
//         return object.toDiagnosticsNode(style: style).getChildren();
//       }
//     }
//     return const <DiagnosticsNode>[];
//   }
// }


// mixin Diagnosticable {
//   /// A brief description of this object, usually just the [runtimeType] and the
//   /// [hashCode].
//   ///
//   /// See also:
//   ///
//   ///  * [toString], for a detailed description of the object.
//   String toStringShort() => describeIdentity(this);

//   @override
//   String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
//     String? fullString;
//     assert(() {
//       fullString = toDiagnosticsNode(
//         style: DiagnosticsTreeStyle.singleLine,
//       ).toString(minLevel: minLevel);
//       return true;
//     }());
//     return fullString ?? toStringShort();
//   }

//   /// Returns a debug representation of the object that is used by debugging
//   /// tools and by [DiagnosticsNode.toStringDeep].
//   ///
//   /// Leave [name] as null if there is not a meaningful description of the
//   /// relationship between the this node and its parent.
//   ///
//   /// Typically the [style] argument is only specified to indicate an atypical
//   /// relationship between the parent and the node. For example, pass
//   /// [DiagnosticsTreeStyle.offstage] to indicate that a node is offstage.
//   DiagnosticsNode toDiagnosticsNode({String? name, DiagnosticsTreeStyle? style}) {
//     return DiagnosticableNode<Diagnosticable>(name: name, value: this, style: style);
//   }

//   /// Add additional properties associated with the node.
//   ///
//   /// {@youtube 560 315 https://www.youtube.com/watch?v=DnC7eT-vh1k}
//   ///
//   /// Use the most specific [DiagnosticsProperty] existing subclass to describe
//   /// each property instead of the [DiagnosticsProperty] base class. There are
//   /// only a small number of [DiagnosticsProperty] subclasses each covering a
//   /// common use case. Consider what values a property is relevant for users
//   /// debugging as users debugging large trees are overloaded with information.
//   /// Common named parameters in [DiagnosticsNode] subclasses help filter when
//   /// and how properties are displayed.
//   ///
//   /// `defaultValue`, `showName`, `showSeparator`, and `level` keep string
//   /// representations of diagnostics terse and hide properties when they are not
//   /// very useful.
//   ///
//   ///  * Use `defaultValue` any time the default value of a property is
//   ///    uninteresting. For example, specify a default value of null any time
//   ///    a property being null does not indicate an error.
//   ///  * Avoid specifying the `level` parameter unless the result you want
//   ///    cannot be achieved by using the `defaultValue` parameter or using
//   ///    the [ObjectFlagProperty] class to conditionally display the property
//   ///    as a flag.
//   ///  * Specify `showName` and `showSeparator` in rare cases where the string
//   ///    output would look clumsy if they were not set.
//   ///    ```dart
//   ///    DiagnosticsProperty<Object>('child(3, 4)', null, ifNull: 'is null', showSeparator: false).toString()
//   ///    ```
//   ///    Shows using `showSeparator` to get output `child(3, 4) is null` which
//   ///    is more polished than `child(3, 4): is null`.
//   ///    ```dart
//   ///    DiagnosticsProperty<IconData>('icon', icon, ifNull: '<empty>', showName: false).toString()
//   ///    ```
//   ///    Shows using `showName` to omit the property name as in this context the
//   ///    property name does not add useful information.
//   ///
//   /// `ifNull`, `ifEmpty`, `unit`, and `tooltip` make property
//   /// descriptions clearer. The examples in the code sample below illustrate
//   /// good uses of all of these parameters.
//   ///
//   /// ## DiagnosticsProperty subclasses for primitive types
//   ///
//   ///  * [StringProperty], which supports automatically enclosing a [String]
//   ///    value in quotes.
//   ///  * [DoubleProperty], which supports specifying a unit of measurement for
//   ///    a [double] value.
//   ///  * [PercentProperty], which clamps a [double] to between 0 and 1 and
//   ///    formats it as a percentage.
//   ///  * [IntProperty], which supports specifying a unit of measurement for an
//   ///    [int] value.
//   ///  * [FlagProperty], which formats a [bool] value as one or more flags.
//   ///    Depending on the use case it is better to format a bool as
//   ///    `DiagnosticsProperty<bool>` instead of using [FlagProperty] as the
//   ///    output is more verbose but unambiguous.
//   ///
//   /// ## Other important [DiagnosticsProperty] variants
//   ///
//   ///  * [EnumProperty], which provides terse descriptions of enum values
//   ///    working around limitations of the `toString` implementation for Dart
//   ///    enum types.
//   ///  * [IterableProperty], which handles iterable values with display
//   ///    customizable depending on the [DiagnosticsTreeStyle] used.
//   ///  * [ObjectFlagProperty], which provides terse descriptions of whether a
//   ///    property value is present or not. For example, whether an `onClick`
//   ///    callback is specified or an animation is in progress.
//   ///  * [ColorProperty], which must be used if the property value is
//   ///    a [Color] or one of its subclasses.
//   ///  * [IconDataProperty], which must be used if the property value
//   ///    is of type [IconData].
//   ///
//   /// If none of these subclasses apply, use the [DiagnosticsProperty]
//   /// constructor or in rare cases create your own [DiagnosticsProperty]
//   /// subclass as in the case for [TransformProperty] which handles [Matrix4]
//   /// that represent transforms. Generally any property value with a good
//   /// `toString` method implementation works fine using [DiagnosticsProperty]
//   /// directly.
//   ///
//   /// {@tool snippet}
//   ///
//   /// This example shows best practices for implementing [debugFillProperties]
//   /// illustrating use of all common [DiagnosticsProperty] subclasses and all
//   /// common [DiagnosticsProperty] parameters.
//   ///
//   /// ```dart
//   /// class ExampleObject extends ExampleSuperclass {
//   ///
//   ///   // ...various members and properties...
//   ///
//   ///   @override
//   ///   void debugFillProperties(DiagnosticPropertiesBuilder properties) {
//   ///     // Always add properties from the base class first.
//   ///     super.debugFillProperties(properties);
//   ///
//   ///     // Omit the property name 'message' when displaying this String property
//   ///     // as it would just add visual noise.
//   ///     properties.add(StringProperty('message', message, showName: false));
//   ///
//   ///     properties.add(DoubleProperty('stepWidth', stepWidth));
//   ///
//   ///     // A scale of 1.0 does nothing so should be hidden.
//   ///     properties.add(DoubleProperty('scale', scale, defaultValue: 1.0));
//   ///
//   ///     // If the hitTestExtent matches the paintExtent, it is just set to its
//   ///     // default value so is not relevant.
//   ///     properties.add(DoubleProperty('hitTestExtent', hitTestExtent, defaultValue: paintExtent));
//   ///
//   ///     // maxWidth of double.infinity indicates the width is unconstrained and
//   ///     // so maxWidth has no impact.
//   ///     properties.add(DoubleProperty('maxWidth', maxWidth, defaultValue: double.infinity));
//   ///
//   ///     // Progress is a value between 0 and 1 or null. Showing it as a
//   ///     // percentage makes the meaning clear enough that the name can be
//   ///     // hidden.
//   ///     properties.add(PercentProperty(
//   ///       'progress',
//   ///       progress,
//   ///       showName: false,
//   ///       ifNull: '<indeterminate>',
//   ///     ));
//   ///
//   ///     // Most text fields have maxLines set to 1.
//   ///     properties.add(IntProperty('maxLines', maxLines, defaultValue: 1));
//   ///
//   ///     // Specify the unit as otherwise it would be unclear that time is in
//   ///     // milliseconds.
//   ///     properties.add(IntProperty('duration', duration.inMilliseconds, unit: 'ms'));
//   ///
//   ///     // Tooltip is used instead of unit for this case as a unit should be a
//   ///     // terse description appropriate to display directly after a number
//   ///     // without a space.
//   ///     properties.add(DoubleProperty(
//   ///       'device pixel ratio',
//   ///       devicePixelRatio,
//   ///       tooltip: 'physical pixels per logical pixel',
//   ///     ));
//   ///
//   ///     // Displaying the depth value would be distracting. Instead only display
//   ///     // if the depth value is missing.
//   ///     properties.add(ObjectFlagProperty<int>('depth', depth, ifNull: 'no depth'));
//   ///
//   ///     // bool flag that is only shown when the value is true.
//   ///     properties.add(FlagProperty('using primary controller', value: primary));
//   ///
//   ///     properties.add(FlagProperty(
//   ///       'isCurrent',
//   ///       value: isCurrent,
//   ///       ifTrue: 'active',
//   ///       ifFalse: 'inactive',
//   ///     ));
//   ///
//   ///     properties.add(DiagnosticsProperty<bool>('keepAlive', keepAlive));
//   ///
//   ///     // FlagProperty could have also been used in this case.
//   ///     // This option results in the text "obscureText: true" instead
//   ///     // of "obscureText" which is a bit more verbose but a bit clearer.
//   ///     properties.add(DiagnosticsProperty<bool>('obscureText', obscureText, defaultValue: false));
//   ///
//   ///     properties.add(EnumProperty<TextAlign>('textAlign', textAlign, defaultValue: null));
//   ///     properties.add(EnumProperty<ImageRepeat>('repeat', repeat, defaultValue: ImageRepeat.noRepeat));
//   ///
//   ///     // Warn users when the widget is missing but do not show the value.
//   ///     properties.add(ObjectFlagProperty<Widget>('widget', widget, ifNull: 'no widget'));
//   ///
//   ///     properties.add(IterableProperty<BoxShadow>(
//   ///       'boxShadow',
//   ///       boxShadow,
//   ///       defaultValue: null,
//   ///       style: style,
//   ///     ));
//   ///
//   ///     // Getting the value of size throws an exception unless hasSize is true.
//   ///     properties.add(DiagnosticsProperty<Size>.lazy(
//   ///       'size',
//   ///       () => size,
//   ///       description: '${ hasSize ? size : "MISSING" }',
//   ///     ));
//   ///
//   ///     // If the `toString` method for the property value does not provide a
//   ///     // good terse description, write a DiagnosticsProperty subclass as in
//   ///     // the case of TransformProperty which displays a nice debugging view
//   ///     // of a Matrix4 that represents a transform.
//   ///     properties.add(TransformProperty('transform', transform));
//   ///
//   ///     // If the value class has a good `toString` method, use
//   ///     // DiagnosticsProperty<YourValueType>. Specifying the value type ensures
//   ///     // that debugging tools always know the type of the field and so can
//   ///     // provide the right UI affordances. For example, in this case even
//   ///     // if color is null, a debugging tool still knows the value is a Color
//   ///     // and can display relevant color related UI.
//   ///     properties.add(DiagnosticsProperty<Color>('color', color));
//   ///
//   ///     // Use a custom description to generate a more terse summary than the
//   ///     // `toString` method on the map class.
//   ///     properties.add(DiagnosticsProperty<Map<Listenable, VoidCallback>>(
//   ///       'handles',
//   ///       handles,
//   ///       description: handles != null
//   ///         ? '${handles!.length} active client${ handles!.length == 1 ? "" : "s" }'
//   ///         : null,
//   ///       ifNull: 'no notifications ever received',
//   ///       showName: false,
//   ///     ));
//   ///   }
//   /// }
//   /// ```
//   /// {@end-tool}
//   ///
//   /// Used by [toDiagnosticsNode] and [toString].
//   ///
//   /// Do not add values that have lifetime shorter than the object.
//   @protected
//   @mustCallSuper
//   void debugFillProperties(DiagnosticPropertiesBuilder properties) {}
// }
