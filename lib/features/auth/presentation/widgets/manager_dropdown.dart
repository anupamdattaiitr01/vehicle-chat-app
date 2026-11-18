import 'package:flutter/material.dart';
import '../../domain/entities/manager_entity.dart';

class ManagerDropdown extends StatelessWidget {
  final List<ManagerEntity> managers;
  final String? selectedManagerId;
  final bool isLoading;
  final ValueChanged<String?> onChanged;
  final VoidCallback onRefresh;

  const ManagerDropdown({
    super.key,
    required this.managers,
    required this.selectedManagerId,
    required this.isLoading,
    required this.onChanged,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: DropdownButtonFormField<String>(
            key: ValueKey(selectedManagerId),
            initialValue: selectedManagerId,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Select Your Manager',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.supervisor_account),
            ),
            items: managers.map((manager) {
              return DropdownMenuItem<String>(
                value: manager.id,
                child: Text(
                  '${manager.name} (${manager.phone})',
                  overflow: TextOverflow.ellipsis,
                ),
              );
            }).toList(),
            onChanged: onChanged,
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          tooltip: 'Refresh Managers',
          onPressed: isLoading ? null : onRefresh,
          icon: isLoading
              ? const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
              : const Icon(Icons.refresh),
        ),
      ],
    );
  }
}