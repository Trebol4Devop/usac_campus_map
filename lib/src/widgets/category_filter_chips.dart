import 'package:flutter/material.dart';
import '../models/building_category.dart';

class CategoryFilterChips extends StatelessWidget {
  final BuildingCategory? selectedCategory;
  final Set<BuildingCategory>? selectedCategories;
  final ValueChanged<BuildingCategory?>? onCategorySelected;
  final ValueChanged<Set<BuildingCategory>>? onCategoriesChanged;
  final bool isMultiSelect;
  final bool showAllOption;
  final String allLabel;
  final EdgeInsetsGeometry padding;
  final double spacing;

  const CategoryFilterChips({
    super.key,
    this.selectedCategory,
    this.selectedCategories,
    this.onCategorySelected,
    this.onCategoriesChanged,
    this.isMultiSelect = false,
    this.showAllOption = true,
    this.allLabel = 'Todos',
    this.padding = const EdgeInsets.symmetric(horizontal: 12),
    this.spacing = 8.0,
  });



  void _handleSelection(BuildingCategory? category) {
    if (isMultiSelect) {
      final current = Set<BuildingCategory>.from(selectedCategories ?? {});
      if (category == null) {
        current.clear();
      } else {
        if (current.contains(category)) {
          current.remove(category);
        } else {
          current.add(category);
        }
      }
      onCategoriesChanged?.call(current);
    } else {
      if (category == null) {
        onCategorySelected?.call(null);
      } else {
        if (selectedCategory == category) {
          onCategorySelected?.call(null);
        } else {
          onCategorySelected?.call(category);
        }
      }
    }
  }

  bool _isSelected(BuildingCategory? category) {
    if (isMultiSelect) {
      if (category == null) {
        return selectedCategories == null || selectedCategories!.isEmpty;
      }
      return selectedCategories?.contains(category) ?? false;
    }
    if (category == null) {
      return selectedCategory == null;
    }
    return selectedCategory == category;
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: padding,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showAllOption)
              Padding(
                padding: EdgeInsets.only(right: spacing),
                child: FilterChip(
                  label: Text(allLabel),
                  selected: _isSelected(null),
                  onSelected: (_) => _handleSelection(null),
                  showCheckmark: false,
                  selectedColor:
                      const Color(0xFF002B49).withValues(alpha: 0.15),
                  checkmarkColor: const Color(0xFF002B49),
                  labelStyle: TextStyle(
                    color: _isSelected(null)
                        ? const Color(0xFF002B49)
                        : Colors.black87,
                    fontWeight:
                        _isSelected(null) ? FontWeight.bold : FontWeight.normal,
                    fontSize: 13,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(
                      color: _isSelected(null)
                          ? const Color(0xFF002B49)
                          : Colors.grey.shade300,
                    ),
                  ),
                ),
              ),
            ...BuildingCategory.values.map((category) {
              final isCurrentSelected = _isSelected(category);
              final categoryColor = category.color;

              return Padding(
                padding: EdgeInsets.only(right: spacing),
                child: FilterChip(
                  avatar: Icon(
                    category.icon,
                    size: 16,
                    color: isCurrentSelected ? Colors.white : categoryColor,
                  ),
                  label: Text(category.label),
                  selected: isCurrentSelected,
                  onSelected: (_) => _handleSelection(category),
                  showCheckmark: false,
                  backgroundColor: Colors.white,
                  selectedColor: categoryColor,
                  labelStyle: TextStyle(
                    color: isCurrentSelected ? Colors.white : Colors.black87,
                    fontWeight:
                        isCurrentSelected ? FontWeight.bold : FontWeight.normal,
                    fontSize: 13,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(
                      color: isCurrentSelected
                          ? categoryColor
                          : Colors.grey.shade300,
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
