import 'package:flutter/material.dart';
import '../../helpers/file_size_helper.dart';
import '../../models/result_info.dart';
import '../../strings/app_strings.dart';

class ResultCard extends StatelessWidget {
  const ResultCard({super.key, required this.info});

  final ResultInfo info;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: [
          ListTile(
            title: const Text(AppStrings.resultPath),
            subtitle: SelectableText(info.path),
          ),
          ListTile(
            title: const Text(AppStrings.resultSize),
            subtitle: Text(FileSizeHelper.format(info.fileSizeBytes)),
          ),
        ],
      ),
    );
  }
}
