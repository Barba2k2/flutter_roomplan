import 'package:flutter/material.dart';
import '../controllers/support_controller.dart';
import '../helpers/support_actions_helper.dart';
import '../strings/app_strings.dart';
import '../widgets/error_banner/error_banner.dart';
import '../widgets/limits_card/limits_card.dart';
import '../widgets/unsupported_card/unsupported_card.dart';

class SupportPage extends StatefulWidget {
  const SupportPage({super.key, required this.controller});

  final SupportController controller;

  @override
  State<SupportPage> createState() => _SupportPageState();
}

class _SupportPageState extends State<SupportPage> {
  @override
  void initState() {
    super.initState();
    widget.controller.load();
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
        title: const Text(AppStrings.supportTitle),
      ),
      body: ListenableBuilder(
        listenable: controller,
        builder: (context, _) {
          final info = controller.info;
          final errorMessage = controller.errorMessage;
          final limits = info?.limits;
          final canContinue = info != null && info.supported;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (controller.isLoading) const Text(AppStrings.supportChecking),
              if (errorMessage != null) ErrorBanner(message: errorMessage),
              if (info != null && !info.supported) const UnsupportedCard(),
              if (limits != null) LimitsCard(limits: limits),
              if (info != null) ...[
                const SizedBox(height: 16),
                const Text(AppStrings.deviceNote),
              ],
              const SizedBox(height: 16),
              if (canContinue)
                FilledButton(
                  onPressed: () {
                    SupportActionsHelper.openReconstruct(context);
                  },
                  child: const Text(AppStrings.continueToReconstruct),
                )
              else
                OutlinedButton(
                  onPressed: controller.isLoading ? null : controller.load,
                  child: const Text(AppStrings.checkAgain),
                ),
            ],
          );
        },
      ),
    );
  }
}
