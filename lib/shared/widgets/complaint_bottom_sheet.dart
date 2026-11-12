import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:toidym/app/di/providers.dart';
import 'package:toidym/app/theme/app_spacing.dart';
import 'package:toidym/app/theme/app_text_styles.dart';
import 'package:toidym/core/utils/extensions.dart';
import 'package:toidym/core/utils/halal_photo_picker.dart';
import 'package:toidym/shared/models/order.dart';
import 'package:toidym/shared/widgets/halal_cert_image.dart';
import 'package:toidym/shared/widgets/primary_button.dart';

/// Модальная форма жалобы на заказ (Правило 7: 24 часа, фото, ответ до 3 рабочих дней).
Future<bool> showComplaintBottomSheet(
  BuildContext context, {
  required Order order,
}) async {
  final result = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _ComplaintSheet(order: order),
  );
  return result ?? false;
}

class _ComplaintSheet extends ConsumerStatefulWidget {
  const _ComplaintSheet({required this.order});

  final Order order;

  @override
  ConsumerState<_ComplaintSheet> createState() => _ComplaintSheetState();
}

class _ComplaintSheetState extends ConsumerState<_ComplaintSheet> {
  final _noteController = TextEditingController();
  String? _photoDataUrl;
  bool _isSubmitting = false;
  String? _errorText;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto({required bool useCamera}) async {
    final photo = await pickHalalCertPhoto(useCamera: useCamera);
    if (!mounted || photo == null || photo.isEmpty) return;
    setState(() => _photoDataUrl = photo);
  }

  Future<void> _submit() async {
    final l10n = context.l10n;
    final note = _noteController.text.trim();
    if (note.isEmpty) {
      setState(() => _errorText = l10n.complaintNoteHint);
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorText = null;
    });

    try {
      await ref.read(orderRepositoryProvider).submitComplaint(
            orderId: widget.order.id,
            note: note,
            photoPaths: _photoDataUrl != null ? [_photoDataUrl!] : const [],
          );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _errorText = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.md,
        0,
        AppSpacing.md,
        AppSpacing.lg + bottomInset,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.complaintTitle, style: AppTextStyles.titleLarge),
          const SizedBox(height: AppSpacing.xs),
          Text(l10n.complaintSubtitle, style: AppTextStyles.bodyMedium),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _noteController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: l10n.complaintNoteHint,
              errorText: _errorText,
            ),
          ),
          if (_photoDataUrl != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Stack(
              alignment: Alignment.topRight,
              children: [
                HalalCertImage(source: _photoDataUrl!, height: 140),
                IconButton(
                  tooltip: l10n.actionCancel,
                  onPressed: _isSubmitting
                      ? null
                      : () => setState(() => _photoDataUrl = null),
                  icon: const CircleAvatar(
                    radius: 14,
                    backgroundColor: Colors.black54,
                    child: Icon(Icons.close_rounded, size: 16, color: Colors.white),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _isSubmitting
                      ? null
                      : () => _pickPhoto(useCamera: true),
                  icon: const Icon(Icons.photo_camera_outlined),
                  label: Text(
                    Localizations.localeOf(context).languageCode == 'kk'
                        ? 'Суретке түсіру'
                        : 'Сфотографировать',
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _isSubmitting
                      ? null
                      : () => _pickPhoto(useCamera: false),
                  icon: const Icon(Icons.photo_library_outlined),
                  label: Text(l10n.complaintAddPhoto),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          PrimaryButton(
            label: l10n.complaintSubmit,
            isLoading: _isSubmitting,
            onPressed: _submit,
          ),
        ],
      ),
    );
  }
}
