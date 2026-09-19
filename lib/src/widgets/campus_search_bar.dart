import 'package:flutter/material.dart';

class CampusSearchBar extends StatefulWidget {
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onClear;
  final ValueChanged<String>? onSubmitted;
  final String hintText;
  final Widget? leading;
  final List<Widget>? trailing;
  final EdgeInsetsGeometry padding;
  final Color? fillColor;
  final BorderRadius? borderRadius;
  final double elevation;

  const CampusSearchBar({
    super.key,
    this.controller,
    this.onChanged,
    this.onClear,
    this.onSubmitted,
    this.hintText = 'Buscar edificio, sigla o facultad...',
    this.leading,
    this.trailing,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    this.fillColor,
    this.borderRadius,
    this.elevation = 2.0,
  });

  @override
  State<CampusSearchBar> createState() => _CampusSearchBarState();
}

class _CampusSearchBarState extends State<CampusSearchBar> {
  late final TextEditingController _effectiveController;
  bool _isInternalController = false;

  @override
  void initState() {
    super.initState();
    if (widget.controller == null) {
      _effectiveController = TextEditingController();
      _isInternalController = true;
    } else {
      _effectiveController = widget.controller!;
    }
  }

  @override
  void dispose() {
    if (_isInternalController) {
      _effectiveController.dispose();
    }
    super.dispose();
  }

  void _handleClear() {
    _effectiveController.clear();
    widget.onChanged?.call('');
    widget.onClear?.call();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final effectiveBorderRadius =
        widget.borderRadius ?? BorderRadius.circular(12);

    return Padding(
      padding: widget.padding,
      child: Material(
        elevation: widget.elevation,
        borderRadius: effectiveBorderRadius,
        color: widget.fillColor ?? Theme.of(context).colorScheme.surface,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: effectiveBorderRadius,
            border: Border.all(
              color: Theme.of(context).dividerColor.withValues(alpha: 0.2),
              width: 1.0,
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
          child: Row(
            children: [
              widget.leading ??
                  const Icon(
                    Icons.search,
                    color: Color(0xFF002B49),
                    size: 22,
                  ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _effectiveController,
                  onChanged: (value) {
                    setState(() {});
                    widget.onChanged?.call(value);
                  },
                  onSubmitted: widget.onSubmitted,
                  decoration: InputDecoration(
                    hintText: widget.hintText,
                    hintStyle: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 14,
                    ),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
              if (_effectiveController.text.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: _handleClear,
                  splashRadius: 18,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  color: Colors.grey.shade600,
                ),
              if (widget.trailing != null) ...widget.trailing!,
            ],
          ),
        ),
      ),
    );
  }
}
