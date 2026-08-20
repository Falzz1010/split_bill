import 'package:flutter/material.dart';
import '../../../core/utils/app_l10n.dart';
import '../../../core/utils/app_snackbar.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/models/split_model.dart';
import '../../../core/utils/category_guesser.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../shared/widgets/neo_avatar.dart';
import '../../../shared/widgets/neo_bottom_sheet.dart';
import '../../../shared/widgets/neo_button.dart';
import '../../../shared/widgets/neo_input.dart';

class CreateSplitDialog extends StatefulWidget {
  final Function(SplitBill) onCreateSplit;
  final String? initialTitle;
  final String? initialCategory;
  final List<ReceiptItem>? initialItems;

  const CreateSplitDialog({
    super.key,
    required this.onCreateSplit,
    this.initialTitle,
    this.initialCategory,
    this.initialItems,
  });

  @override
  State<CreateSplitDialog> createState() => _CreateSplitDialogState();
}

class _CreateSplitDialogState extends State<CreateSplitDialog> {
  final _titleController = TextEditingController();
  late final _categoryController = TextEditingController(
    text: widget.initialCategory ??
        guessCategory(widget.initialTitle) ??
        'Resto & Cafe',
  );
  final _memberNameController = TextEditingController();

  /// Kategori otomatis hanya berjalan selama user belum menyentuh field
  /// kategori secara manual — setelah itu kehendak user yang menang.
  bool _categoryTouched = false;

  final _itemNameController = TextEditingController();
  final _itemPriceController = TextEditingController();

  final _scrollController = ScrollController();

  late final List<Member> _members = [
    Member(
      id: 'm1',
      name: 'Saya',
      avatarUrl: '',
      accentColorHex: '#FFCD00',
      isPaid: true,
      amountOwed: 0,
    ),
  ];

  late final List<ReceiptItem> _items = [...?widget.initialItems];

  final List<String> _accentColors = [
    '#FFCD00',
    '#62FAE3',
    '#FF7A59',
    '#A5B4FC',
    '#C084FC',
    '#22C55E',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.initialTitle != null && widget.initialTitle!.trim().isNotEmpty) {
      _titleController.text = widget.initialTitle!.trim();
    }
  }

  /// Tebak kategori dari judul struk saat user mengetik, selama field
  /// kategori belum diedit manual.
  void _onTitleChanged(String value) {
    if (_categoryTouched) return;
    final guessed = guessCategory(value);
    if (guessed != null && _categoryController.text != guessed) {
      _categoryController.text = guessed;
    }
  }

  void _addMember() {
    final name = _memberNameController.text.trim();
    if (name.isNotEmpty) {
      setState(() {
        final color = _accentColors[_members.length % _accentColors.length];
        _members.add(
          Member(
            id: 'm_${DateTime.now().millisecondsSinceEpoch}',
            name: name,
            avatarUrl: '',
            accentColorHex: color,
            isPaid: false,
            amountOwed: 0,
          ),
        );
        _memberNameController.clear();
      });
    }
  }

  void _removeMember(int index) {
    if (_members.length > 1) {
      setState(() {
        _members.removeAt(index);
      });
    }
  }

  /// Item baru selalu dibagi ke semua anggota yang ada saat itu.
  ReceiptItem _newItem(String name, double price) => ReceiptItem(
    id: 'item_${DateTime.now().millisecondsSinceEpoch}',
    name: name,
    price: price,
    quantity: 1,
    assignedMemberIds: _members.map((m) => m.id).toList(),
  );

  void _addItem() {
    final name = _itemNameController.text.trim();
    final price = parsePrice(_itemPriceController.text);

    if (name.isEmpty || price <= 0) {
      showNeoSnack(context, tr('create_invalid_input'), isError: true);
      return;
    }

    setState(() {
      _items.add(_newItem(name, price));
      _itemNameController.clear();
      _itemPriceController.clear();
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  void _removeItem(int index) {
    setState(() {
      _items.removeAt(index);
    });
  }

  void _submit() {
    // Auto-add pending item input (nama/harga yang belum ditekan tombol "+")
    final pendingName = _itemNameController.text.trim();
    final pendingPrice = parsePrice(_itemPriceController.text);
    if (pendingName.isNotEmpty && pendingPrice > 0) {
      _items.add(_newItem(pendingName, pendingPrice));
    }

    final title = _titleController.text.trim().isEmpty
        ? 'Struk Baru'
        : _titleController.text.trim();
    final subtotal = _items.fold(0.0, (sum, i) => sum + i.lineTotal);
    final totals = computeTaxAndService(subtotal);

    widget.onCreateSplit(
      SplitBill(
        id: 'split_${DateTime.now().millisecondsSinceEpoch}',
        title: title,
        category: categoryLabelOf(_categoryController.text.trim()),
        date: DateTime.now(),
        subtotal: subtotal,
        tax: totals.tax,
        serviceCharge: totals.serviceCharge,
        discount: 0,
        totalAmount: totals.total,
        isCompleted: false,
        members: computeMemberAmounts(
          _members,
          _items,
          tax: totals.tax,
          serviceCharge: totals.serviceCharge,
        ),
        items: _items,
      ),
    );
    Navigator.pop(context);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _titleController.dispose();
    _categoryController.dispose();
    _memberNameController.dispose();
    _itemNameController.dispose();
    _itemPriceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return NeoBottomSheet(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header tetap di atas, tidak ikut ter-scroll.
          NeoSheetHeader(title: tr('create_manual_title')),
          const SizedBox(height: 16),

          // Konten yang bisa di-scroll (field, anggota, item)
          Flexible(
            child: SingleChildScrollView(
              controller: _scrollController,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Nama Resto / Struk
                  Text(
                    tr('create_name'),
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _titleController,
                    onChanged: _onTitleChanged,
                    decoration: neoInputDecoration(
                      context,
                      hintText: tr('create_name_hint'),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Kategori
                  Text(
                    tr('create_category'),
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _categoryController,
                    onChanged: (_) => _categoryTouched = true,
                    decoration: neoInputDecoration(
                      context,
                      hintText: tr('create_category_hint'),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Add Members Section
                  Text(
                    '${tr('create_members')} (${_members.length})',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _memberNameController,
                          decoration: neoInputDecoration(
                            context,
                            hintText: tr('create_member_hint'),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      NeoButton(
                        onTap: _addMember,
                        backgroundColor: context.palette.secondaryContainer,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        child: Text(
                          tr('create_add_member'),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.onAccent(
                              context.palette.secondaryContainer,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _members.asMap().entries.map((entry) {
                      final idx = entry.key;
                      final m = entry.value;
                      return Chip(
                        avatar: NeoAvatar(
                          member: m,
                          size: 24,
                          fontSize: 12,
                          bordered: false,
                        ),
                        label: Text(
                          m.name,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        deleteIcon: idx > 0
                            ? const Icon(Icons.close, size: 16)
                            : null,
                        onDeleted: idx > 0 ? () => _removeMember(idx) : null,
                        backgroundColor: context.palette.surfaceContainerLowest,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                          side: BorderSide(
                            color: context.palette.borderBlack,
                            width: 1.5,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),

                  // Input Item Pesanan & Harga Manual
                  Text(
                    '${tr('create_input_items')} (${_items.length} ${tr('create_item_label')})',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: TextField(
                          controller: _itemNameController,
                          decoration: neoInputDecoration(
                            context,
                            hintText: tr('create_item_name'),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        flex: 2,
                        child: TextField(
                          controller: _itemPriceController,
                          keyboardType: TextInputType.number,
                          decoration: neoInputDecoration(
                            context,
                            hintText: tr('create_item_price'),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      NeoButton(
                        onTap: _addItem,
                        backgroundColor: context.palette.primaryContainer,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                        child: Icon(
                          Icons.add,
                          color: context.palette.onPrimaryContainer,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Item List Added
                  if (_items.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(12),
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: context.palette.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: context.palette.outlineVariant),
                      ),
                      child: Text(
                        tr('create_no_items'),
                        style: TextStyle(
                          fontSize: 11,
                          color: context.palette.onSurfaceVariant,
                        ),
                      ),
                    )
                  else
                    Column(
                      children: _items.asMap().entries.map((entry) {
                        final idx = entry.key;
                        final item = entry.value;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: context.palette.surfaceContainerLowest,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: context.palette.borderBlack,
                                width: 1.5,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    item.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                Row(
                                  children: [
                                    Text(
                                      formatCurrency(item.price),
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: context.palette.primary,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    GestureDetector(
                                      onTap: () => _removeItem(idx),
                                      child: Icon(
                                        Icons.delete_outline,
                                        size: 18,
                                        color: context.palette.error,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),

                  if (_items.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: context.palette.secondaryContainer.withAlpha(70),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: context.palette.borderBlack,
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              '${tr('create_subtotal')} (${_items.length} ${tr('create_item_label')})',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          Text(
                            formatCurrency(
                              _items.fold(0.0, (s, i) => s + i.lineTotal),
                            ),
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              color: context.palette.primary,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Submit CTA Button (tetap di bawah, di atas keyboard)
          NeoButton(
            onTap: _submit,
            width: double.infinity,
            backgroundColor: context.palette.primaryContainer,
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.flash_on_rounded,
                  color: context.palette.onPrimaryContainer,
                  size: 20,
                ),
                const SizedBox(width: 6),
                Text(
                  tr('create_create'),
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    color: context.palette.onPrimaryContainer,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
