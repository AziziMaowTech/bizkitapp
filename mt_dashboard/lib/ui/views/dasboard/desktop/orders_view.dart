import 'package:flutter/material.dart';
import 'package:mt_dashboard/ui/views/dasboard/desktop/orders_view.desktop.dart';
import 'package:mt_dashboard/ui/views/dasboard/desktop/orders_viewmodel.dart';
import 'package:responsive_builder/responsive_builder.dart';
import 'package:stacked/stacked.dart';

class OrdersView extends StackedView<OrdersViewModel> {
  const OrdersView({super.key});

  @override
  Widget builder(BuildContext context, OrdersViewModel viewModel, Widget? child) {
    return ScreenTypeLayout.builder(
      // mobile: (_) => const OrdersViewMobile(),
      // tablet: (_) => const OrdersViewTablet(),
      desktop: (_) => const OrdersViewDesktop(),
    );
  }

  @override
  OrdersViewModel viewModelBuilder(BuildContext context) => OrdersViewModel();
}
