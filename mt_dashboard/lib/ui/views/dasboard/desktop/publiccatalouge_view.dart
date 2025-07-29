import 'package:flutter/material.dart';
import 'package:mt_dashboard/ui/views/dasboard/desktop/publiccatalouge_view.desktop.dart';
import 'package:responsive_builder/responsive_builder.dart';
import 'package:stacked/stacked.dart';
// import 'Settings_view.tablet.dart';
// import 'Settings_view.mobile.dart';
import 'publiccatalouge_viewmodel.dart';

class PublicCatalougeView extends StackedView<PublicCatalougeViewModel> {
  const PublicCatalougeView({super.key, required String storename});

  @override
  Widget builder(BuildContext context, PublicCatalougeViewModel viewModel, Widget? child) {
    return ScreenTypeLayout.builder(
      // mobile: (_) => const PublicCatalougeViewMobile(),
      // tablet: (_) => const PublicCatalougeViewTablet(),
      desktop: (_) => const PublicCatalougeViewDesktop(),
    );
  }

  @override
  PublicCatalougeViewModel viewModelBuilder(BuildContext context) => PublicCatalougeViewModel();
}
