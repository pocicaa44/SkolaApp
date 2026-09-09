import 'package:flutter/material.dart';
import '../../../app_theme.dart';
import '../../../data/models/journal_model.dart';

class JournalBottomSheet extends StatefulWidget {
  final JournalModel? existingJournal;
  final bool isLocked;
  final void Function(String material, String? notes) onSave;

  const JournalBottomSheet({
    super.key,
    this.existingJournal,
    this.isLocked = false,
    required this.onSave,
  });

  @override
  State<JournalBottomSheet> createState() => _JournalBottomSheetState();
}

class _JournalBottomSheetState extends State<JournalBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _materialController = TextEditingController();
  final _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.existingJournal != null) {
      _materialController.text = widget.existingJournal!.teachingMaterial;
      _notesController.text = widget.existingJournal!.notes ?? '';
    }
  }

  @override
  void dispose() {
    _materialController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: AppTheme.space16,
        right: AppTheme.space16,
        top: AppTheme.space20,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppTheme.space20,
      ),
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppTheme.radiusCard),
        ),
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Jurnal Pembelajaran (Opsional)',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.space12),

              const Text(
                'Materi yang Diajarkan',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _materialController,
                readOnly: widget.isLocked,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'mis. Persamaan Kuadrat & Contoh Soal Latihan',
                ),
              ),
              const SizedBox(height: AppTheme.space16),

              const Text(
                'Catatan Kejadian / Siswa (Opsional)',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _notesController,
                readOnly: widget.isLocked,
                maxLines: 2,
                decoration: const InputDecoration(
                  hintText:
                      'mis. Siswa A izin dispensasi kegiatan OSIS di JP ke-2',
                ),
              ),
              const SizedBox(height: AppTheme.space24),

              if (!widget.isLocked)
                ElevatedButton(
                  onPressed: () {
                    widget.onSave(
                      _materialController.text,
                      _notesController.text,
                    );
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      vertical: AppTheme.space14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        AppTheme.radiusButton,
                      ),
                    ),
                  ),
                  child: const Text(
                    'Simpan Jurnal',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
