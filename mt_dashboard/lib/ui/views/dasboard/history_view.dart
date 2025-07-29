import 'package:flutter/material.dart';
import 'package:mt_dashboard/ui/views/dasboard/history_view.desktop.dart';
import 'package:mt_dashboard/ui/views/dasboard/history_viewmodel.dart';
import 'package:responsive_builder/responsive_builder.dart';
import 'package:stacked/stacked.dart';

class HistoryView extends StackedView<HistoryViewModel> {
  const HistoryView({super.key});

  @override
  Widget builder(BuildContext context, HistoryViewModel viewModel, Widget? child) {
    return ScreenTypeLayout.builder(
      // mobile: (_) => const HistoryViewMobile(),
      // tablet: (_) => const HistoryViewTablet(),
      desktop: (_) => const HistoryViewDesktop(),
    );
  }

  @override
  HistoryViewModel viewModelBuilder(BuildContext context) => HistoryViewModel();
}
