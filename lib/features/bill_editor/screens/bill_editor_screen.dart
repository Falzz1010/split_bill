import 'package:flutter/material.dart';
import '../../../core/utils/app_l10n.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/models/split_model.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../shared/widgets/neo_bottom_sheet.dart';
import '../../../shared/widgets/neo_card.dart';
import '../../../shared/widgets/neo_button.dart';
import '../../../shared/widgets/neo_chip.dart';

class BillEditorScreen extends StatefulWidget {
  final SplitBill splitBill;
  final VoidCallback onBack;
  final Function(SplitBill) onSaveAndContinue;
  final Function(String)? onDeleteSplit;

  const BillEditorScreen({
    super.key,
    required this.splitBill,
    required this.onBack,
    required this.onSaveAndContinue,
    this.onDeleteSplit,
  });

  @override
  State<BillEditorScreen> createState() => _BillEditorScreenState();
}

class _BillEditorScreenState extends State<BillEditorScreen> {
  late List<ReceiptItem> _items;
  late List<Member> _members;
  bool _includeTax = true;
  bool _includeService = true;

  @override
  void initState() {
    super.initState();
    _items = List.from(widget.splitBill.items);
    _members = List.from(widget.splitBill.members);
  }

  /// Warna aksen anggota via parser aman (hex rusak tidak membuat crash).
  Color _memberColor(Member m) => AppColors.fromHex(m.accentColorHex);

  void _toggleMemberAssignment(ReceiptItem item, String memberId) {
    setState(() {
      final index = _items.indexWhere((i) => i.id == item.id);
      if (index != -1) {
        final assigned = List<String>.from(_items[index].assignedMemberIds);
        if (assigned.contains(memberId)) {
          assigned.remove(memberId);
        } else {
          assigned.add(memberId);
        }
        _items[index] = ReceiptItem(
          id: item.id,
          name: item.name,
          price: item.price,
          quantity: item.quantity,
          assignedMemberIds: assigned,
        );
      }
    });
  }

  void _updateQuantity(ReceiptItem item, int delta) {
    setState(() {
      final index = _items.indexWhere((i) => i.id == item.id);
      if (index != -1) {
        final newQty = _items[index].quantity + delta;
        if (newQty > 0) {
          _items[index] = ReceiptItem(
            id: item.id,
            name: item.name,
            price: item.price,
            quantity: newQty,
            assignedMemberIds: item.assignedMemberIds,
          );
        }
      }
    });
  }

  void _showAddMemberBottomSheet() {
    final textController = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return NeoBottomSheet(
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                NeoSheetHeader(title: tr('edit_add_member')),
                const SizedBox(height: 16),
                TextField(
                  controller: textController,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: tr('edit_member_name_hint'),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: AppColors.borderBlack,
                        width: 2,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: AppColors.secondary,
                        width: 2.5,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                NeoButton(
                  onTap: () {
                    if (textController.text.trim().isNotEmpty) {
                      setState(() {
                        _members.add(
                          Member(
                            id: 'm_${DateTime.now().millisecondsSinceEpoch}',
                            name: textController.text.trim(),
                            avatarUrl: '',
                            accentColorHex: '#62FAE3',
                            isPaid: false,
                            amountOwed: 0,
                          ),
                        );
                      });
                      Navigator.pop(context);
                    }
                  },
                  width: double.infinity,
                  backgroundColor: AppColors.primaryContainer,
                  child: Text(
                    tr('edit_save_member'),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: AppColors.onPrimaryContainer,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showAddItemBottomSheet() {
    final nameController = TextEditingController();
    final priceController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return NeoBottomSheet(
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                NeoSheetHeader(title: tr('edit_add_item')),
                const SizedBox(height: 16),
                Text(
                  tr('edit_menu_name'),
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: nameController,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: tr('edit_name_example'),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: AppColors.borderBlack,
                        width: 2,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  tr('edit_hint_price'),
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: priceController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    hintText: tr('edit_price_example'),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: AppColors.borderBlack,
                        width: 2,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                NeoButton(
                  onTap: () {
                    final name = nameController.text.trim();
                    final priceStr = priceController.text.trim();
                    final price =
                        double.tryParse(
                          priceStr.replaceAll(RegExp(r'[^0-9]'), ''),
                        ) ??
                        0;

                    if (name.isNotEmpty && price > 0) {
                      setState(() {
                        _items.add(
                          ReceiptItem(
                            id: 'item_${DateTime.now().millisecondsSinceEpoch}',
                            name: name,
                            price: price,
                            quantity: 1,
                            assignedMemberIds: _members
                                .map((m) => m.id)
                                .toList(),
                          ),
                        );
                      });
                      Navigator.pop(context);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            tr('edit_invalid_input'),
                            style: TextStyle(color: AppColors.background),
                          ),
                          backgroundColor: AppColors.error,
                        ),
                      );
                    }
                  },
                  width: double.infinity,
                  backgroundColor: AppColors.primaryContainer,
                  child: Text(
                    tr('edit_save_item'),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.onPrimaryContainer,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showEditItemNominalBottomSheet(ReceiptItem item) {
    final nameController = TextEditingController(text: item.name);
    final priceController = TextEditingController(
      text: item.price.toStringAsFixed(0),
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return NeoBottomSheet(
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                NeoSheetHeader(title: tr('edit_edit_item')),
                const SizedBox(height: 16),
                Text(
                  tr('edit_menu_name'),
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: AppColors.borderBlack,
                        width: 2,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  tr('edit_hint_price'),
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: priceController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: AppColors.borderBlack,
                        width: 2,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: NeoButton(
                        onTap: () {
                          setState(() {
                            _items.removeWhere((i) => i.id == item.id);
                          });
                          Navigator.pop(context);
                        },
                        backgroundColor: AppColors.errorContainer,
                        child: Text(
                          tr('edit_delete_item'),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.error,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: NeoButton(
                        onTap: () {
                          final newName = nameController.text.trim();
                          final newPriceStr = priceController.text.trim();
                          final newPrice =
                              double.tryParse(
                                newPriceStr.replaceAll(RegExp(r'[^0-9]'), ''),
                              ) ??
                              item.price;

                          if (newName.isNotEmpty && newPrice > 0) {
                            setState(() {
                              final idx = _items.indexWhere(
                                (i) => i.id == item.id,
                              );
                              if (idx != -1) {
                                _items[idx] = ReceiptItem(
                                  id: item.id,
                                  name: newName,
                                  price: newPrice,
                                  quantity: item.quantity,
                                  assignedMemberIds: item.assignedMemberIds,
                                );
                              }
                            });
                            Navigator.pop(context);
                          }
                        },
                        backgroundColor: AppColors.primaryContainer,
                        child: Text(
                          tr('edit_save_changes'),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.onPrimaryContainer,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(64),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: widget.onBack,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerLowest,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.borderBlack,
                        width: 2,
                      ),
                    ),
                    child: Icon(Icons.arrow_back, color: AppColors.onSurface),
                  ),
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      tr('edit_title'),
                      style: Theme.of(
                        context,
                      ).textTheme.headlineSmall?.copyWith(fontSize: 17),
                    ),
                    Text(
                      widget.splitBill.title,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
                if (widget.onDeleteSplit != null)
                  GestureDetector(
                    onTap: () {
                      widget.onDeleteSplit!(widget.splitBill.id);
                      widget.onBack();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            tr(
                              'ring_deleted',
                            ).replaceAll('{title}', widget.splitBill.title),
                          ),
                          backgroundColor: AppColors.borderBlack,
                        ),
                      );
                    },
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.errorContainer,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.borderBlack,
                          width: 2,
                        ),
                      ),
                      child: Icon(
                        Icons.delete_outline_rounded,
                        size: 20,
                        color: AppColors.error,
                      ),
                    ),
                  )
                else
                  const SizedBox(width: 40),
              ],
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Horizontal Member Bar
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${tr('edit_members')} (${_members.length})',
                        style: Theme.of(
                          context,
                        ).textTheme.headlineSmall?.copyWith(fontSize: 16),
                      ),
                      GestureDetector(
                        onTap: _showAddMemberBottomSheet,
                        child: NeoChip(
                          label: tr('edit_add_friend'),
                          icon: Icons.person_add_alt_1_rounded,
                          backgroundColor: AppColors.secondaryContainer,
                          textColor: AppColors.onAccent(
                            AppColors.secondaryContainer,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  SizedBox(
                    height: 44,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _members.length,
                      itemBuilder: (context, idx) {
                        final m = _members[idx];
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: _memberColor(m),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: AppColors.borderBlack,
                                width: 1.5,
                              ),
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 10,
                                  backgroundColor:
                                      AppColors.surfaceContainerLowest,
                                  child: Text(
                                    m.name[0],
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.onSurface,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  m.name,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: AppColors.onAccent(_memberColor(m)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Section Title
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        tr('edit_orders'),
                        style: Theme.of(
                          context,
                        ).textTheme.headlineSmall?.copyWith(fontSize: 16),
                      ),
                      GestureDetector(
                        onTap: _showAddItemBottomSheet,
                        child: NeoChip(
                          label: tr('edit_add_item_label'),
                          backgroundColor: AppColors.primaryContainer,
                          textColor: AppColors.onPrimaryContainer,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    tr('edit_assign_hint'),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 12),

                  // Items List
                  ..._items.map((item) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: NeoCard(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    item.name,
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelLarge
                                        ?.copyWith(fontSize: 15),
                                  ),
                                ),
                                Row(
                                  children: [
                                    Text(
                                      formatCurrency(
                                        item.price * item.quantity,
                                      ),
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelLarge
                                          ?.copyWith(color: AppColors.primary),
                                    ),
                                    const SizedBox(width: 8),
                                    GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          _items.removeWhere(
                                            (i) => i.id == item.id,
                                          );
                                        });
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          color: AppColors.errorContainer,
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: AppColors.borderBlack,
                                            width: 1,
                                          ),
                                        ),
                                        child: Icon(
                                          Icons.delete_outline_rounded,
                                          size: 16,
                                          color: AppColors.error,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),

                            // Stepper Qty & Unit Price
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                GestureDetector(
                                  onTap: () =>
                                      _showEditItemNominalBottomSheet(item),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.primaryContainer
                                          .withAlpha(120),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: AppColors.borderBlack,
                                        width: 1,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Text(
                                          '@ ${formatCurrency(item.price)}',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall
                                              ?.copyWith(
                                                fontWeight: FontWeight.bold,
                                              ),
                                        ),
                                        const SizedBox(width: 4),
                                        Icon(
                                          Icons.edit_rounded,
                                          size: 13,
                                          color: AppColors.onPrimaryContainer,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                Container(
                                  decoration: BoxDecoration(
                                    color: AppColors.surfaceContainerLow,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: AppColors.borderBlack,
                                      width: 1.5,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      GestureDetector(
                                        onTap: () => _updateQuantity(item, -1),
                                        child: const Padding(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 4,
                                          ),
                                          child: Text(
                                            '-',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                        ),
                                      ),
                                      Text(
                                        '${item.quantity}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                      GestureDetector(
                                        onTap: () => _updateQuantity(item, 1),
                                        child: const Padding(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 4,
                                          ),
                                          child: Text(
                                            '+',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            Divider(
                              height: 18,
                              thickness: 1,
                              color: AppColors.outlineVariant,
                            ),

                            // Interactive Member Assignment Chips
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: _members.map((m) {
                                final isAssigned = item.assignedMemberIds
                                    .contains(m.id);
                                return GestureDetector(
                                  onTap: () =>
                                      _toggleMemberAssignment(item, m.id),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 150),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isAssigned
                                          ? _memberColor(m)
                                          : AppColors.surfaceContainerLowest,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: isAssigned
                                            ? AppColors.borderBlack
                                            : AppColors.outlineVariant,
                                        width: isAssigned ? 2.0 : 1.0,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          isAssigned
                                              ? Icons.check_circle_rounded
                                              : Icons.circle_outlined,
                                          size: 14,
                                          color: isAssigned
                                              ? Colors.black
                                              : AppColors.outline,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          m.name,
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: isAssigned
                                                ? FontWeight.bold
                                                : FontWeight.normal,
                                            color: isAssigned
                                                ? Colors.black
                                                : AppColors.onSurfaceVariant,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 16),

                  // Tax & Service Controls
                  NeoCard(
                    backgroundColor: AppColors.surfaceContainerHigh,
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              tr('edit_tax'),
                              style: Theme.of(context).textTheme.labelMedium,
                            ),
                            Switch.adaptive(
                              value: _includeTax,
                              activeTrackColor: AppColors.secondaryContainer,
                              activeThumbColor: AppColors.secondary,
                              onChanged: (v) => setState(() => _includeTax = v),
                            ),
                          ],
                        ),
                        Divider(
                          height: 12,
                          thickness: 1,
                          color: AppColors.outlineVariant,
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              tr('edit_service'),
                              style: Theme.of(context).textTheme.labelMedium,
                            ),
                            Switch.adaptive(
                              value: _includeService,
                              activeTrackColor: AppColors.secondaryContainer,
                              activeThumbColor: AppColors.secondary,
                              onChanged: (v) =>
                                  setState(() => _includeService = v),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),

          // Bottom Fixed Action CTA Button
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLowest,
              border: Border(
                top: BorderSide(
                  color: AppColors.borderBlack,
                  width: AppColors.borderWidth,
                ),
              ),
            ),
            child: SafeArea(
              top: false,
              child: NeoButton(
                onTap: () {
                  final double subtotal = _items.fold(
                    0.0,
                    (sum, i) => sum + (i.price * i.quantity),
                  );
                  final totals = computeTaxAndService(
                    subtotal,
                    includeTax: _includeTax,
                    includeService: _includeService,
                  );
                  final membersWithAmounts = computeMemberAmounts(
                    _members,
                    _items,
                    tax: totals.tax,
                    serviceCharge: totals.serviceCharge,
                  );

                  final updatedSplit = SplitBill(
                    id: widget.splitBill.id,
                    title: widget.splitBill.title,
                    // Prefix "N Anggota • " disegarkan agar sesuai jumlah anggota
                    // saat ini (konvensi data yang di-parse dashboard).
                    category: categoryWithMemberCount(
                      widget.splitBill.category,
                      _members.length,
                    ),
                    date: widget.splitBill.date,
                    subtotal: subtotal,
                    tax: totals.tax,
                    serviceCharge: totals.serviceCharge,
                    discount: 0,
                    totalAmount: totals.total,
                    isCompleted: widget.splitBill.isCompleted,
                    members: membersWithAmounts,
                    items: _items,
                  );
                  widget.onSaveAndContinue(updatedSplit);
                },
                width: double.infinity,
                backgroundColor: AppColors.primaryContainer,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      tr('edit_save'),
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        color: AppColors.onPrimaryContainer,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.arrow_forward_rounded,
                      color: AppColors.onPrimaryContainer,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
