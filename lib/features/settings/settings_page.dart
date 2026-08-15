import 'package:flutter/material.dart';

import '../../shared/widgets/app_badge.dart';
import '../../shared/widgets/app_button.dart';
import '../../shared/widgets/app_search_field.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text('Style Preview', style: t.headlineMedium),
        const SizedBox(height: 16),
        const AppSearchField(hint: 'Search'),
        const SizedBox(height: 16),
        const AppButton(label: 'Primary', icon: Icons.add),
        const SizedBox(height: 8),
        const AppButton(
          label: 'Secondary',
          variant: AppButtonVariant.secondary,
        ),
        const SizedBox(height: 8),
        const AppButton(label: 'Inverted', variant: AppButtonVariant.inverted),
        const SizedBox(height: 8),
        const AppButton(label: 'Outlined', variant: AppButtonVariant.outlined),
        const SizedBox(height: 16),
        const Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            AppBadge(label: 'Active'),
            AppBadge(label: 'Pending', tone: AppBadgeTone.gold),
            AppBadge(label: 'Shipped', tone: AppBadgeTone.lavender),
            AppBadge(label: 'Delivered', tone: AppBadgeTone.success),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          'The real Settings screen will live here later.',
          style: t.bodyMedium,
        ),
      ],
    );
  }
}
