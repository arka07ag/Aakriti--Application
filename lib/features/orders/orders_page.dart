import 'package:flutter/material.dart';

class OrdersPage extends StatelessWidget {
  const OrdersPage({super.key});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
      children: [
        Text('Orders Management', style: t.headlineMedium),
        const SizedBox(height: 6),
        Text('Review and process customer orders.', style: t.bodyMedium),
        const SizedBox(height: 24),
        Text('Order list coming in Step 7 ✨', style: t.bodyMedium),
      ],
    );
  }
}
