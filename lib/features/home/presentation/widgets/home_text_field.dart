import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class HomeTextField extends StatelessWidget {
  const HomeTextField({
    super.key,
    required this.controller,
    required this.label,
    this.prefixIcon,
    this.keyboardType,
    this.inputFormatters,
    this.onSubmitted,
    this.onChanged,
    this.onTap,
    this.obscureText = false,
    this.enabled = true,
    this.maxLines = 1,
    this.minLines,
    this.maxLength,
    this.hintText,
    this.suffixIcon,
    this.decoration,
    this.textAlign = TextAlign.start,
    this.textAlignVertical,
    this.style,
    this.readOnly = false,
  });

  final TextEditingController controller;
  final String label;
  final IconData? prefixIcon;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final ValueChanged<String>? onSubmitted;
  final ValueChanged<String>? onChanged;
  final GestureTapCallback? onTap;
  final bool obscureText;
  final bool enabled;
  final int maxLines;
  final int? minLines;
  final int? maxLength;
  final String? hintText;
  final Widget? suffixIcon;
  final InputDecoration? decoration;
  final TextAlign textAlign;
  final TextAlignVertical? textAlignVertical;
  final TextStyle? style;
  final bool readOnly;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      onSubmitted: onSubmitted,
      onChanged: onChanged,
      onTap: onTap,
      obscureText: obscureText,
      enabled: enabled,
      maxLines: maxLines,
      minLines: minLines,
      maxLength: maxLength,
      readOnly: readOnly,
      textAlign: textAlign,
      textAlignVertical: textAlignVertical,
      style: style,
      decoration: decoration ??
          InputDecoration(
            labelText: label,
            hintText: hintText,
            prefixIcon: prefixIcon != null ? Icon(prefixIcon) : null,
            suffixIcon: suffixIcon,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
    );
  }
}
