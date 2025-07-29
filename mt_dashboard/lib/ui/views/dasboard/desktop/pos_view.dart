import 'package:flutter/material.dart';
import 'package:mt_dashboard/ui/views/dasboard/desktop/pos_view.desktop.dart';
import 'package:responsive_builder/responsive_builder.dart';
import 'package:stacked/stacked.dart';
// import 'Settings_view.tablet.dart';
// import 'Settings_view.mobile.dart';
import 'pos_viewmodel.dart';

class PosView extends StackedView<PosViewModel> {
  const PosView({super.key});

  @override
  Widget builder(BuildContext context, PosViewModel viewModel, Widget? child) {
    return ScreenTypeLayout.builder(
      // mobile: (_) => const PosViewMobile(),
      // tablet: (_) => const PosViewTablet(),
      desktop: (_) => const PosViewDesktop(),
    );
  }

  @override
  PosViewModel viewModelBuilder(BuildContext context) => PosViewModel();
}
