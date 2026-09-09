import 'package:flutter/material.dart';
import '../../../app_theme.dart';
import '../../../data/models/subject_model.dart';

class SubjectMultiSelectDialog extends StatefulWidget {
  final List<SubjectModel> allSubjects;
  final List<String> initialSelectedIds;
  final int maxSelection;

  const SubjectMultiSelectDialog({
    super.key,
    required this.allSubjects,
    required this.initialSelectedIds,
    this.maxSelection = 2,
  });

  @override
  State<SubjectMultiSelectDialog> createState() =>
      _SubjectMultiSelectDialogState();
}

class _SubjectMultiSelectDialogState extends State<SubjectMultiSelectDialog> {
  late List<String> _tempSelectedIds;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tempSelectedIds = List.from(widget.initialSelectedIds);
  }

  void _toggle(String id) {
    setState(() {
      if (_tempSelectedIds.contains(id)) {
        _tempSelectedIds.remove(id);
      } else {
        if (_tempSelectedIds.length >= widget.maxSelection) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Maksimal hanya dapat memilih ${widget.maxSelection} mata pelajaran.',
              ),
              backgroundColor: AppTheme.warning,
              duration: const Duration(seconds: 2),
            ),
          );
          return;
        }
        _tempSelectedIds.add(id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final filtered = widget.allSubjects.where((s) {
      if (_searchQuery.isEmpty) return true;
      return s.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          s.code.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusDialog),
      ),
      titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
      actionsPadding: const EdgeInsets.all(16),
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Pilih Mata Pelajaran',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: AppTheme.primaryLight,
              borderRadius: BorderRadius.circular(AppTheme.radiusBadge),
            ),
            child: Text(
              '${_tempSelectedIds.length}/${widget.maxSelection}',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppTheme.primary,
              ),
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: const InputDecoration(
                hintText: 'Cari mata pelajaran...',
                prefixIcon: Icon(Icons.search, size: 18),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
              onChanged: (val) => setState(() => _searchQuery = val),
            ),
            const SizedBox(height: 12),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 300),
              child: filtered.isEmpty
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Text(
                          'Mata pelajaran tidak ditemukan.',
                          style: TextStyle(
                            color: AppTheme.textMuted,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final subject = filtered[index];
                        final isChecked = _tempSelectedIds.contains(subject.id);

                        return CheckboxListTile(
                          value: isChecked,
                          title: Text(
                            subject.name,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          subtitle: subject.code.isNotEmpty
                              ? Text(
                                  subject.code,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppTheme.textMuted,
                                  ),
                                )
                              : null,
                          activeColor: AppTheme.primary,
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          onChanged: (_) => _toggle(subject.id),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Batal'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(_tempSelectedIds),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusButton),
            ),
          ),
          child: const Text('Konfirmasi Pilihan'),
        ),
      ],
    );
  }
}
