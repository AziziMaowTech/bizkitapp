import 'package:flutter/material.dart';
import 'package:mt_dashboard/ui/views/dasboard/desktop/catalouge_view.desktop.dart';
import 'package:responsive_builder/responsive_builder.dart';
import 'package:stacked/stacked.dart';
// import 'Settings_view.tablet.dart';
// import 'Settings_view.mobile.dart';
import 'catalouge_viewmodel.dart';

class CatalougeView extends StackedView<CatalougeViewModel> {
  const CatalougeView({super.key});

  @override
  Widget builder(BuildContext context, CatalougeViewModel viewModel, Widget? child) {
    return ScreenTypeLayout.builder(
      // mobile: (_) => const CatalougeViewMobile(),
      // tablet: (_) => const CatalougeViewTablet(),
      desktop: (_) => const CatalougeViewDesktop(),
    );
  }

  @override
  CatalougeViewModel viewModelBuilder(BuildContext context) => CatalougeViewModel();
}
