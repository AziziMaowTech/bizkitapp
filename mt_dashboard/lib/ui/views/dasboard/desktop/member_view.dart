import 'package:flutter/material.dart';
import 'package:mt_dashboard/ui/views/dasboard/desktop/member_view.desktop.dart';
import 'package:mt_dashboard/ui/views/dasboard/desktop/member_viewmodel.dart';
import 'package:responsive_builder/responsive_builder.dart';
import 'package:stacked/stacked.dart';

class MemberView extends StackedView<MemberViewModel> {
  const MemberView({super.key});

  @override
  Widget builder(BuildContext context, MemberViewModel viewModel, Widget? child) {
    return ScreenTypeLayout.builder(
      // mobile: (_) => const MemberViewMobile(),
      // tablet: (_) => const MemberViewTablet(),
      desktop: (_) => const MemberViewDesktop(),
    );
  }

  @override
  MemberViewModel viewModelBuilder(BuildContext context) => MemberViewModel();
}
