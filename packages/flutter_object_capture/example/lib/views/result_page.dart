import 'package:flutter/material.dart';
import '../controllers/result_controller.dart';
import '../helpers/result_actions_helper.dart';
import '../strings/app_strings.dart';
import '../widgets/error_banner/error_banner.dart';
import '../widgets/result_card/result_card.dart';

class ResultPage extends StatefulWidget {
  const ResultPage({super.key, required this.controller});

  final ResultController controller;

  @override
  State<ResultPage> createState() => _ResultPageState();
}

class _ResultPageState extends State<ResultPage> {
  @override
  void initState() {
    super.initState();
    widget.controller.checkFile();
  }

  @override
  void dispose() {
    widget.controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.resultTitle),
      ),
      body: ListenableBuilder(
        listenable: controller,
        builder: (context, _) {
          final errorMessage = controller.errorMessage;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              ResultCard(info: controller.info),
              if (errorMessage != null) ...[
                const SizedBox(height: 16),
                ErrorBanner(message: errorMessage),
              ],
              const SizedBox(height: 16),
              FilledButton(
                onPressed: controller.fileExists
                    ? () => ResultActionsHelper.share(context, controller)
                    : null,
                child: const Text(AppStrings.resultShare),
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text(AppStrings.resultBack),
              ),
            ],
          );
        },
      ),
    );
  }
}
