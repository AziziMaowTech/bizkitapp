import 'package:flutter/material.dart';
import 'package:mt_dashboard/ui/views/dasboard/desktop/calendar_view.desktop.dart';
import 'package:mt_dashboard/ui/views/dasboard/desktop/calendar_viewmodel.dart';
import 'package:responsive_builder/responsive_builder.dart';
import 'package:stacked/stacked.dart';
// import 'Settings_view.tablet.dart';
// import 'Settings_view.mobile.dart';

class CalendarView extends StackedView<CalendarViewModel> {
  const CalendarView({super.key});

  @override
  Widget builder(BuildContext context, CalendarViewModel viewModel, Widget? child) {
    return ScreenTypeLayout.builder(
      // mobile: (_) => const CalendarViewMobile(),
      // tablet: (_) => const CalendarViewTablet(),
      desktop: (_) => const CalendarViewDesktop(),
    );
  }

  @override
  CalendarViewModel viewModelBuilder(BuildContext context) => CalendarViewModel();
}
