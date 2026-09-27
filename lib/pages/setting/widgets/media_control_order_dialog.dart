import 'package:PiliPlus/models/common/media_control_button.dart';
import 'package:material_ui/material_ui.dart';

class MediaControlOrderDialog extends StatefulWidget {
  const MediaControlOrderDialog({
    super.key,
    required this.selectedValues,
  });

  final Iterable<MediaControlButton> selectedValues;

  @override
  State<MediaControlOrderDialog> createState() =>
      _MediaControlOrderDialogState();
}

class _MediaControlOrderDialogState extends State<MediaControlOrderDialog> {
  late final List<MediaControlButton> _controls;
  late final Set<MediaControlButton> _selectedValues;

  @override
  void initState() {
    super.initState();
    final selectedValues = widget.selectedValues.toList();
    _selectedValues = selectedValues.toSet()..add(MediaControlButton.playPause);
    _controls = [
      ...selectedValues,
      ...defaultMediaControlButtons.where(
        (button) => !_selectedValues.contains(button),
      ),
    ];
    _controls.removeDuplicates();
  }

  void _onReorder(int oldIndex, int newIndex) {
    setState(() {
      _controls.insert(newIndex, _controls.removeAt(oldIndex));
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      clipBehavior: Clip.hardEdge,
      title: const Text('系统媒体控制按钮'),
      contentPadding: const EdgeInsets.only(top: 12),
      content: SizedBox(
        width: 360,
        height: 300,
        child: Material(
          type: MaterialType.transparency,
          child: ReorderableListView.builder(
            padding: EdgeInsets.zero,
            itemCount: _controls.length,
            onReorderItem: _onReorder,
            itemBuilder: (context, index) {
              final button = _controls[index];
              final isPlayPause = button == MediaControlButton.playPause;
              return CheckboxListTile(
                key: ValueKey(button),
                value: isPlayPause || _selectedValues.contains(button),
                onChanged: isPlayPause
                    ? (_) {}
                    : (value) {
                        setState(() {
                          value == true
                              ? _selectedValues.add(button)
                              : _selectedValues.remove(button);
                        });
                      },
                dense: true,
                title: Text(button.label),
                subtitle: isPlayPause ? const Text('固定显示，可拖动排序') : null,
                secondary: const Icon(Icons.drag_indicator_rounded),
              );
            },
          ),
        ),
      ),
      actionsPadding: const EdgeInsets.only(left: 16, right: 16, bottom: 12),
      actions: [
        TextButton(
          onPressed: Navigator.of(context).pop,
          child: Text(
            '取消',
            style: TextStyle(color: theme.colorScheme.outline),
          ),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(
            _controls.where(_selectedValues.contains).toList(),
          ),
          child: const Text('确定'),
        ),
      ],
    );
  }
}

extension on List<MediaControlButton> {
  void removeDuplicates() {
    final seen = <MediaControlButton>{};
    removeWhere((value) => !seen.add(value));
  }
}
