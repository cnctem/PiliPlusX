import 'package:PiliPlus/adapt/radio_group.dart';
import 'package:flutter/material.dart';

class RadioWidget<T> extends StatefulWidget {
  final T value;
  final String title;
  final bool tristate;
  final EdgeInsetsGeometry? padding;
  final MainAxisSize mainAxisSize;

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

  const RadioWidget({
    super.key,
    required this.value,
    required this.title,
    this.tristate = false,
    this.padding,
    this.mainAxisSize = MainAxisSize.min,
    this.groupValue,
    required this.onChanged,
  });

  @override
  State<RadioWidget<T>> createState() => RadioWidgetState<T>();
}

class RadioWidgetState<T> extends State<RadioWidget<T>> with RadioClient<T> {
  late final _RadioRegistry<T> _radioRegistry = _RadioRegistry<T>(this);

  @override
  final focusNode = FocusNode();

  @override
  T get radioValue => widget.value;

  bool get checked => radioValue == registry!.groupValue;

  @override
  bool get tristate => widget.tristate;

  @override
  void dispose() {
    registry = null;
    focusNode.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    registry = RadioGroup.maybeOf(context);
    assert(registry != null);
  }

  void _handleTap() {
    if (checked) {
      if (tristate) registry!.onChanged(null);
      return;
    }
    registry!.onChanged(radioValue);
  }

  @override
  Widget build(BuildContext context) {
    final child = Row(
      mainAxisSize: widget.mainAxisSize,
      children: [
        Focus(
          parentNode: focusNode,
          canRequestFocus: false,
          skipTraversal: true,
          includeSemantics: true,
          descendantsAreFocusable: false,
          descendantsAreTraversable: false,
          child: Radio<T>(
            value: radioValue,
            // groupRegistry: _radioRegistry,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            groupValue: widget.groupValue,
            onChanged: widget.onChanged,
          ),
        ),
        Text(widget.title),
      ],
    );
    return InkWell(
      onTap: _handleTap,
      focusNode: focusNode,
      child: widget.padding == null
          ? child
          : Padding(padding: widget.padding!, child: child),
    );
  }
}

class WrapRadioOptionsGroup<T> extends StatelessWidget {
  final String groupTitle;
  final Map<T, String> options;
  final EdgeInsetsGeometry? itemPadding;

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

  const WrapRadioOptionsGroup({
    super.key,
    required this.groupTitle,
    required this.options,
    this.itemPadding,
    this.groupValue,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (groupTitle.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 22),
            child: Text(
              groupTitle,
              style: TextStyle(color: Theme.of(context).colorScheme.outline),
            ),
          ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Wrap(
            children: options.entries.map((entry) {
              return RadioWidget<T>(
                groupValue: groupValue,
                onChanged: onChanged,
                value: entry.key,
                title: entry.value,
                padding: itemPadding ?? const EdgeInsets.only(right: 10),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

/// A registry to controls internal [Radio] and hides it from [RadioGroup]
/// ancestor.
///
/// [RadioListTile] implements the [RadioClient] directly to register to
/// [RadioGroup] ancestor. Therefore, it has to hide the internal [Radio] from
/// participate in the [RadioGroup] ancestor.
class _RadioRegistry<T> extends RadioGroupRegistry<T> {
  _RadioRegistry(this.state);

  final RadioWidgetState<T> state;

  @override
  T? get groupValue => state.registry!.groupValue;

  @override
  ValueChanged<T?> get onChanged => state.registry!.onChanged;

  @override
  void registerClient(RadioClient<T> radio) {}

  @override
  void unregisterClient(RadioClient<T> radio) {}
}
