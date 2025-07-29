import 'package:flutter/material.dart';
import 'package:mt_dashboard/ui/views/dasboard/desktop/settings_view.desktop.dart';
import 'package:responsive_builder/responsive_builder.dart';
import 'package:stacked/stacked.dart';
// import 'Settings_view.tablet.dart';
// import 'Settings_view.mobile.dart';
import 'settings_viewmodel.dart';

class SettingsView extends StackedView<SettingsViewModel> {
  const SettingsView({super.key});

  @override
  Widget builder(BuildContext context, SettingsViewModel viewModel, Widget? child) {
    return ScreenTypeLayout.builder(
      // mobile: (_) => const SettingsViewMobile(),
      // tablet: (_) => const SettingsViewTablet(),
      desktop: (_) => const SettingsViewDesktop(),
    );
  }

  @override
  SettingsViewModel viewModelBuilder(BuildContext context) => SettingsViewModel();
}
