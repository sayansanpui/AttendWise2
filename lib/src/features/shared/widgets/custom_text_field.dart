import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A reusable custom text field widget with enhanced styling and features.
class CustomTextField extends StatelessWidget {
  /// Controller for the text field
  final TextEditingController controller;

  /// Label text to display
  final String labelText;

  /// Optional hint text
  final String? hintText;

  /// Optional helper text displayed below the field
  final String? helperText;

  /// Optional error text displayed below the field
  final String? errorText;

  /// Optional prefix icon
  final IconData? prefixIcon;

  /// Optional suffix icon
  final IconData? suffixIcon;

  /// Action when suffix icon is tapped
  final VoidCallback? onSuffixIconTap;

  /// Whether the field is for password entry
  final bool isPassword;

  /// Whether the field is read-only
  final bool readOnly;

  /// Whether the field is required
  final bool required;

  /// Validator function
  final String? Function(String?)? validator;

  /// Action on text changed
  final Function(String)? onChanged;

  /// Action when field is tapped
  final VoidCallback? onTap;

  /// Maximum lines (defaults to 1)
  final int? maxLines;

  /// Minimum lines
  final int? minLines;

  /// Text input type (defaults to text)
  final TextInputType keyboardType;

  /// List of input formatters
  final List<TextInputFormatter>? inputFormatters;

  /// Focus node for the field
  final FocusNode? focusNode;

  /// Whether to auto-focus this field
  final bool autofocus;

  /// Whether field is enabled
  final bool enabled;

  /// Text style for the field
  final TextStyle? textStyle;

  /// Max length of input
  final int? maxLength;

  const CustomTextField({
    Key? key,
    required this.controller,
    required this.labelText,
    this.hintText,
    this.helperText,
    this.errorText,
    this.prefixIcon,
    this.suffixIcon,
    this.onSuffixIconTap,
    this.isPassword = false,
    this.readOnly = false,
    this.required = false,
    this.validator,
    this.onChanged,
    this.onTap,
    this.maxLines = 1,
    this.minLines,
    this.keyboardType = TextInputType.text,
    this.inputFormatters,
    this.focusNode,
    this.autofocus = false,
    this.enabled = true,
    this.textStyle,
    this.maxLength,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: required ? '$labelText *' : labelText,
        hintText: hintText,
        helperText: helperText,
        errorText: errorText,
        prefixIcon: prefixIcon != null ? Icon(prefixIcon) : null,
        suffixIcon: suffixIcon != null
            ? InkWell(
                onTap: onSuffixIconTap,
                child: Icon(suffixIcon),
              )
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: BorderSide(
            color: theme.colorScheme.outline,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: BorderSide(
            color: theme.colorScheme.primary,
            width: 2.0,
          ),
        ),
        filled: true,
        fillColor: theme.colorScheme.surface,
      ),
      obscureText: isPassword,
      readOnly: readOnly,
      validator: validator,
      onChanged: onChanged,
      onTap: onTap,
      maxLines: maxLines,
      minLines: minLines,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      focusNode: focusNode,
      autofocus: autofocus,
      enabled: enabled,
      style: textStyle ?? theme.textTheme.bodyLarge,
      maxLength: maxLength,
    );
  }
}
