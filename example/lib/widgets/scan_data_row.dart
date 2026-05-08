import 'package:flutter/material.dart';

/// A single icon-labelled row shown inside [ScanDataCard].
///
/// Distinct from `DetailRow` (which is a plain title/value row used by the
/// results page) — this variant prepends an icon and aligns the value to the
/// trailing edge.
class ScanDataRow extends StatelessWidget {
  const ScanDataRow({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Text(label),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
