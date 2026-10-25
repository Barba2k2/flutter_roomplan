import 'package:flutter/material.dart';
import 'package:flutter_object_capture/flutter_object_capture.dart';
import '../../helpers/detail_label_helper.dart';
import '../../strings/app_strings.dart';

class DetailSelector extends StatelessWidget {
  const DetailSelector({
    super.key,
    required this.details,
    required this.selected,
    required this.onChanged,
  });

  final List<ObjectDetail> details;
  final ObjectDetail selected;
  final ValueChanged<ObjectDetail>? onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<ObjectDetail>(
      initialValue: selected,
      decoration: const InputDecoration(
        labelText: AppStrings.detailLabel,
        border: OutlineInputBorder(),
      ),
      items: [
        for (final detail in details)
          DropdownMenuItem(
            value: detail,
            child: Text(DetailLabelHelper.label(detail)),
          ),
      ],
      onChanged: onChanged == null
          ? null
          : (detail) {
              if (detail != null) onChanged!(detail);
            },
    );
  }
}
