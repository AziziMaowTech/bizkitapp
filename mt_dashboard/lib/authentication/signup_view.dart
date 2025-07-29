import 'package:flutter/material.dart';
import 'package:responsive_builder/responsive_builder.dart';
import 'package:stacked/stacked.dart';

import 'signup_view.desktop.dart';
import 'signup_view.tablet.dart';
import 'signup_view.mobile.dart';
import 'signup_viewmodel.dart';

class SignupView extends StackedView<SignupViewModel> {
  const SignupView({super.key});

  @override
  Widget builder(BuildContext context, SignupViewModel viewModel, Widget? child) {
    return ScreenTypeLayout.builder(
      mobile: (_) => const SignupViewMobile(),
      tablet: (_) => const SignupViewTablet(),
      desktop: (_) => const SignupViewDesktop(),
    );
  }

  @override
  SignupViewModel viewModelBuilder(BuildContext context) => SignupViewModel();
}
