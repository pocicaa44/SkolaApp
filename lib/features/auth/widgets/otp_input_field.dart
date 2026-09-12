import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../app_theme.dart';

/// Widget input 6-digit OTP dengan auto-forward focus dan paste handler
class OtpInputField extends StatefulWidget {
  final int length;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onCompleted;
  final bool enabled;

  const OtpInputField({
    super.key,
    this.length = 6,
    this.onChanged,
    this.onCompleted,
    this.enabled = true,
  });

  @override
  State<OtpInputField> createState() => OtpInputFieldState();
}

class OtpInputFieldState extends State<OtpInputField> {
  late final List<TextEditingController> _controllers;
  late final List<FocusNode> _focusNodes;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      widget.length,
      (_) => TextEditingController(),
    );
    _focusNodes = List.generate(
      widget.length,
      (_) => FocusNode(),
    );
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    for (final node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  String get otpCode => _controllers.map((c) => c.text).join();

  void clear() {
    for (final controller in _controllers) {
      controller.clear();
    }
    if (_focusNodes.isNotEmpty && mounted) {
      _focusNodes[0].requestFocus();
    }
    widget.onChanged?.call('');
  }

  void _handleChanged(int index, String value) {
    // Menangani paste string panjang (contoh 6 digit sekaligus)
    if (value.length > 1) {
      final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
      for (int i = 0; i < widget.length; i++) {
        if (i < digits.length) {
          _controllers[i].text = digits[i];
        } else {
          _controllers[i].clear();
        }
      }
      final lastIndex = digits.length.clamp(0, widget.length - 1);
      _focusNodes[lastIndex].requestFocus();

      final fullCode = otpCode;
      widget.onChanged?.call(fullCode);
      if (fullCode.length == widget.length) {
        widget.onCompleted?.call(fullCode);
      }
      return;
    }

    // Input 1 digit normal
    if (value.isNotEmpty) {
      if (index < widget.length - 1) {
        _focusNodes[index + 1].requestFocus();
      } else {
        _focusNodes[index].unfocus();
      }
    }

    final fullCode = otpCode;
    widget.onChanged?.call(fullCode);

    if (fullCode.length == widget.length) {
      widget.onCompleted?.call(fullCode);
    }
  }

  void _handleKeyEvent(int index, KeyEvent event) {
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.backspace) {
      if (_controllers[index].text.isEmpty && index > 0) {
        _controllers[index - 1].clear();
        _focusNodes[index - 1].requestFocus();
        widget.onChanged?.call(otpCode);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;
        // Hitung lebar kotak secara proporsional dengan batas ideal 44 - 52
        final itemWidth = ((availableWidth - ((widget.length - 1) * 8)) / widget.length)
            .clamp(36.0, 52.0);

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(widget.length, (index) {
            return SizedBox(
              width: itemWidth,
              height: 56,
              child: KeyboardListener(
                focusNode: FocusNode(),
                onKeyEvent: (event) => _handleKeyEvent(index, event),
                child: TextFormField(
                  controller: _controllers[index],
                  focusNode: _focusNodes[index],
                  enabled: widget.enabled,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                  inputFormatters: [
                    LengthLimitingTextInputFormatter(widget.length),
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  decoration: InputDecoration(
                    contentPadding: EdgeInsets.zero,
                    filled: true,
                    fillColor: widget.enabled
                        ? AppTheme.surface
                        : AppTheme.surfaceMuted,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusInput),
                      borderSide: const BorderSide(color: AppTheme.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusInput),
                      borderSide: BorderSide(
                        color: _controllers[index].text.isNotEmpty
                            ? AppTheme.primary
                            : AppTheme.border,
                        width: _controllers[index].text.isNotEmpty ? 1.5 : 1.0,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusInput),
                      borderSide: const BorderSide(
                        color: AppTheme.primary,
                        width: 2.0,
                      ),
                    ),
                  ),
                  onChanged: (value) => _handleChanged(index, value),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}
