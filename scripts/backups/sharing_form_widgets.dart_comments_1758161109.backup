/// Form-related sharing widgets for MovieStar.
///
/// Copyright (C) 2025, Software Innovation Institute, ANU.
///
/// Licensed under the GNU General Public License, Version 3 (the "License").
///
/// License: https://www.gnu.org/licenses/gpl-3.0.en.html.
//
// This program is free software: you can redistribute it and/or modify it under
// the terms of the GNU General Public License as published by the Free Software
// Foundation, either version 3 of the License, or (at your option) any later
// version.
//
// This program is distributed in the hope that it will be useful, but WITHOUT
// ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
// FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
// details.
//
// You should have received a copy of the GNU General Public License along with
// this program.  If not, see <https://www.gnu.org/licenses/>.
///
/// Authors: Software Innovation Institute

library;

import 'package:flutter/material.dart';

import 'package:moviestar/core/services/pod/pod_sharing_service.dart';

/// Permission selector widget for choosing access levels
class PermissionSelector extends StatefulWidget {
  final List<String> availablePermissions;
  final List<String> selectedPermissions;
  final ValueChanged<List<String>> onChanged;
  final bool readOnly;
  final String? label;
  final bool requireRead; // New parameter to enforce read permission

  const PermissionSelector({
    super.key,
    required this.availablePermissions,
    required this.selectedPermissions,
    required this.onChanged,
    this.readOnly = false,
    this.label,
    this.requireRead = false, // Default to false for backward compatibility
  });

  @override
  State<PermissionSelector> createState() => _PermissionSelectorState();
}

class _PermissionSelectorState extends State<PermissionSelector> {
  late List<String> _selected;

  @override
  void initState() {
    super.initState();
    _selected = List.from(widget.selectedPermissions);

    // Ensure read permission is always included if required
    if (widget.requireRead && !_selected.contains('read')) {
      _selected.add('read');
      // Notify parent of the change
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.onChanged(_selected);
      });
    }
  }

  @override
  void didUpdateWidget(PermissionSelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedPermissions != oldWidget.selectedPermissions) {
      _selected = List.from(widget.selectedPermissions);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.readOnly) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          children: [
            if (widget.label != null) ...[
              Text(
                widget.label!,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(width: 8),
            ],
            Chip(
              label: Text(
                widget.selectedPermissions.join(', ').toUpperCase(),
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              backgroundColor:
                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Text(
              widget.label!,
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ),
        Wrap(
          spacing: 12,
          runSpacing: 8,
          children: widget.availablePermissions.map((permission) {
            final isSelected = _selected.contains(permission);
            final isReadRequired = widget.requireRead && permission == 'read';

            return Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context)
                          .colorScheme
                          .outline
                          .withValues(alpha: 0.5),
                  width: isSelected ? 2 : 1,
                ),
                color: isSelected
                    ? Theme.of(context)
                        .colorScheme
                        .primary
                        .withValues(alpha: 0.1)
                    : Colors.transparent,
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: isReadRequired && isSelected
                    ? null // Don't allow deselecting required read permission
                    : () {
                        setState(() {
                          if (isSelected) {
                            _selected.remove(permission);
                          } else {
                            _selected.add(permission);
                          }
                          widget.onChanged(_selected);
                        });
                      },
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isSelected ? Icons.check_circle : Icons.circle_outlined,
                        size: 18,
                        color: isSelected
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.outline,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        permission.toUpperCase(),
                        style: TextStyle(
                          color: isSelected
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.onSurface,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      if (isReadRequired)
                        Padding(
                          padding: const EdgeInsets.only(left: 4),
                          child: Icon(
                            Icons.lock,
                            size: 14,
                            color: Theme.of(context)
                                .colorScheme
                                .primary
                                .withValues(alpha: 0.7),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

/// WebID input field with validation
class WebIdInput extends StatefulWidget {
  final TextEditingController controller;
  final Function(String?) onValidated;
  final String? initialValue;
  final String? label;
  final String? hint;

  const WebIdInput({
    super.key,
    required this.controller,
    required this.onValidated,
    this.initialValue,
    this.label,
    this.hint,
  });

  @override
  State<WebIdInput> createState() => _WebIdInputState();
}

class _WebIdInputState extends State<WebIdInput> {
  bool _isValidating = false;
  String? _validationError;

  @override
  void initState() {
    super.initState();
    if (widget.initialValue != null) {
      widget.controller.text = widget.initialValue!;
      _validateWebId(widget.initialValue!);
    }
  }

  Future<void> _validateWebId(String value) async {
    if (value.isEmpty) {
      setState(() {
        _validationError = null;
      });
      widget.onValidated(null);
      return;
    }

    setState(() {
      _isValidating = true;
      _validationError = null;
    });

    final isValid = await PodSharingService.validateWebId(value);

    if (mounted) {
      setState(() {
        _isValidating = false;
        _validationError = isValid ? null : 'Invalid WebID format';
      });
      widget.onValidated(isValid ? value : null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      decoration: InputDecoration(
        labelText: widget.label ?? 'Recipient WebID',
        hintText: widget.hint ?? 'https://pod.example.com/profile/card#me',
        errorText: _validationError,
        suffixIcon: _isValidating
            ? const SizedBox(
                width: 20,
                height: 20,
                child: Padding(
                  padding: EdgeInsets.all(12.0),
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            : _validationError == null && widget.controller.text.isNotEmpty
                ? Icon(
                    Icons.check_circle,
                    color: Theme.of(context).colorScheme.primary,
                  )
                : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      onChanged: (value) {
        _validateWebId(value);
      },
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter a WebID';
        }
        return _validationError;
      },
    );
  }
}
