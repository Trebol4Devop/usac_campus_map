import 'package:flutter/material.dart';
import '../themes/usac_map_theme.dart';

class FloorSelector extends StatelessWidget {
  final int floorsCount;
  final int selectedFloor;
  final ValueChanged<int> onFloorSelected;
  final UsacMapTheme theme;

  const FloorSelector({
    super.key,
    required this.floorsCount,
    required this.selectedFloor,
    required this.onFloorSelected,
    this.theme = const UsacMapTheme(),
  });

  @override
  Widget build(BuildContext context) {
    if (floorsCount <= 1) {
      return const SizedBox.shrink();
    }

    final levels = List<int>.generate(floorsCount, (i) => floorsCount - i);

    return Material(
      color: Colors.white,
      elevation: 4.0,
      shadowColor: Colors.black26,
      borderRadius: BorderRadius.circular(24.0),
      child: Container(
        width: 44.0,
        padding: const EdgeInsets.symmetric(vertical: 4.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24.0),
          border: Border.all(color: theme.primaryColor.withValues(alpha: 0.15)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: levels.map((level) {
            final isSelected = level == selectedFloor;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 2.0),
              child: InkWell(
                onTap: () => onFloorSelected(level),
                borderRadius: BorderRadius.circular(18.0),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 36.0,
                  height: 36.0,
                  decoration: BoxDecoration(
                    color: isSelected ? theme.primaryColor : Colors.transparent,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '$level',
                    style: TextStyle(
                      color: isSelected ? Colors.white : theme.primaryColor,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                      fontSize: 14.0,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
