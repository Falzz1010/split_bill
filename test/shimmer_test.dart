import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fairsplit/core/models/split_model.dart';
import 'package:fairsplit/core/theme/app_colors.dart';
import 'package:fairsplit/features/dashboard/screens/dashboard_screen.dart';
import 'package:fairsplit/features/riwayat/screens/riwayat_screen.dart';
import 'package:fairsplit/shared/widgets/neo_shimmer_skeleton.dart';

import 'helpers/palette_test_wrapper.dart';

void main() {
  final dummy = SplitBill(
    id: 'x',
    title: 'Test',
    category: 'makanan',
    date: DateTime.now(),
    subtotal: 10000,
    tax: 0,
    serviceCharge: 0,
    discount: 0,
    totalAmount: 10000,
    isCompleted: false,
    members: [],
    items: [],
  );

  Future<void> pumpDashboard(WidgetTester tester, {required bool isLoading}) async {
    await tester.pumpWidget(
      wrapWithPalette(
        DashboardScreen(
          splits: const [],
          activeFeaturedSplit: dummy,
          isLoading: isLoading,
          onOpenScanner: () {},
          onCreateNewSplit: () {},
          onSelectSplit: (_) {},
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));
  }

  Future<void> pumpRiwayat(WidgetTester tester, {required bool isLoading}) async {
    await tester.pumpWidget(
      wrapWithPalette(
        RiwayatScreen(
          splits: const [],
          isLoading: isLoading,
          onSelectSplit: (_) {},
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));
  }

  testWidgets('Skeleton shimmer tampil saat loading, hilang setelah selesai',
      (tester) async {
    // Dashboard: 3 kartu horizontal + 1 featured + 2 chart = 6.
    await pumpDashboard(tester, isLoading: true);
    expect(find.byType(NeoShimmerCard), findsNWidgets(6));
    await pumpDashboard(tester, isLoading: false);
    expect(find.byType(NeoShimmerCard), findsNothing);

    // Riwayat: 4 kartu list (ListView lazy — sebagian item mungkin di luar
    // viewport test, jadi pastikan minimal 3 dibangun).
    await pumpRiwayat(tester, isLoading: true);
    expect(find.byType(NeoShimmerCard), findsAtLeastNWidgets(3));
    await pumpRiwayat(tester, isLoading: false);
    expect(find.byType(NeoShimmerCard), findsNothing);
  });
}
