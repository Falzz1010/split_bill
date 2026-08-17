import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../../core/utils/app_l10n.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/models/split_model.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/utils/app_snackbar.dart';
import '../../../shared/widgets/neo_avatar.dart';
import '../../../shared/widgets/neo_button.dart';
import '../../../shared/widgets/neo_confirm_dialog.dart';

class RingkasanScreen extends StatefulWidget {
  final SplitBill splitBill;
  final VoidCallback onBack;
  final Function(SplitBill)? onUpdateSplit;
  final Function(String)? onDeleteSplit;
  final VoidCallback? onAllPaid;

  const RingkasanScreen({
    super.key,
    required this.splitBill,
    required this.onBack,
    this.onUpdateSplit,
    this.onDeleteSplit,
    this.onAllPaid,
  });

  @override
  State<RingkasanScreen> createState() => _RingkasanScreenState();
}

class _RingkasanScreenState extends State<RingkasanScreen> {
  late List<Member> _members;

  @override
  void initState() {
    super.initState();
    _members = List.from(widget.splitBill.members);
  }

  @override
  void didUpdateWidget(covariant RingkasanScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.splitBill.id != widget.splitBill.id) {
      _members = List.from(widget.splitBill.members);
    }
  }

  void _toggleMemberPaidStatus(int index) {
    setState(() {
      final m = _members[index];
      _members[index] = m.copyWith(isPaid: !m.isPaid);
      _notifyUpdate();
    });

    final name = _members[index].name;
    final status = _members[index].isPaid
        ? tr('ring_lunas_status')
        : tr('ring_belum_bayar');
    showNeoSnack(
      context,
      tr(
        'ring_status_changed',
      ).replaceAll('{name}', name).replaceAll('{status}', status),
      duration: const Duration(seconds: 1),
    );

    if (_members.every((m) => m.isPaid)) {
      widget.onAllPaid?.call();
    }
  }

  SplitBill _notifyUpdate() {
    final updated = widget.splitBill.copyWith(
      isCompleted: _members.every((m) => m.isPaid),
      members: _members,
    );
    widget.onUpdateSplit?.call(updated);
    return updated;
  }

  /// Persentase pajak & layanan terhadap subtotal (dibulatkan).
  int _taxPct() {
    final extra =
        widget.splitBill.tax +
        widget.splitBill.serviceCharge -
        widget.splitBill.discount;
    final sub = widget.splitBill.subtotal <= 0
        ? 1.0
        : widget.splitBill.subtotal;
    return ((extra / sub) * 100).round();
  }

  /// Item milik member: yang di-assign ke member, plus item tanpa assign
  /// (dibagi rata ke semua member oleh computeMemberAmounts).
  List<ReceiptItem> _memberItems(Member member) => widget.splitBill.items
      .where(
        (i) =>
            i.assignedMemberIds.contains(member.id) ||
            i.assignedMemberIds.isEmpty,
      )
      .toList();

  double _memberSubtotal(Member member) {
    return _memberItems(member).fold(0.0, (sum, i) {
      final count = i.assignedMemberIds.isEmpty
          ? _members.length
          : i.assignedMemberIds.length;
      return sum + (count > 0 ? i.lineTotal / count : 0);
    });
  }

  /// Baris rincian (judul, total, per anggota) yang sama dipakai untuk teks
  /// WhatsApp dan isi PDF.
  List<String> _summaryLines() {
    final lines = <String>[
      '${widget.splitBill.title} - ${DateFormatter.formatDate(widget.splitBill.date)}',
      '${tr('ring_total_tagihan')}: ${formatCurrency(widget.splitBill.totalAmount)}',
      '',
    ];
    for (final member in _members) {
      lines.add(
        '${member.name} (${member.isPaid ? tr('ring_lunas') : tr('ring_belum_bayar2')})',
      );
      final items = _memberItems(member);
      for (final item in items) {
        lines.add(
          '  ${item.name} (x${item.quantity}) = ${formatCurrency(item.lineTotal)}',
        );
      }
      final taxShare = (member.amountOwed - _memberSubtotal(member))
          .clamp(0.0, double.infinity)
          .toDouble();
      lines.add(
        '  ${tr('ring_subtotal')}: ${formatCurrency(_memberSubtotal(member))}',
      );
      if (taxShare > 0) {
        lines.add('  ${tr('ring_pajak_layanan').replaceAll('{pct}', '${_taxPct()}')}: ${formatCurrency(taxShare)}');
      }
      lines.add('  ${tr('ring_total_anda')}: ${formatCurrency(member.amountOwed)}');
      lines.add('');
    }
    return lines;
  }

  Future<void> _shareWhatsApp() async {
    final text = _summaryLines().join('\n');
    final uri = Uri.parse('https://wa.me/?text=${Uri.encodeComponent(text)}');
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && mounted) showNeoSnack(context, tr('ring_share_failed'));
  }

  Future<void> _exportPdf() async {
    final doc = pw.Document();
    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: _summaryLines().map((line) => pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 3),
            child: pw.Text(
              line,
              style: line.startsWith('  ')
                  ? pw.TextStyle(fontSize: 10)
                  : pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
            ),
          )).toList(),
        ),
      ),
    );
    final bytes = await doc.save();
    await Printing.sharePdf(bytes: bytes, filename: 'fair_split_struk.pdf');
  }

  @override
  Widget build(BuildContext context) {
    final pct = _taxPct();

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
                NeoCircleButton(
                  icon: Icons.arrow_back,
                  iconSize: null,
                  onTap: widget.onBack,
                ),
                Text(
                  tr('ring_pembayaran'),
                  style: Theme.of(
                    context,
                  ).textTheme.headlineSmall?.copyWith(fontSize: 18),
                ),
                Row(
                  children: [
                    if (widget.onDeleteSplit != null)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: NeoCircleButton(
                          icon: Icons.delete_outline_rounded,
                          backgroundColor: AppColors.errorContainer,
                          iconColor: AppColors.error,
                          onTap: () async {
                            final confirmed = await showDeleteConfirmDialog(
                              context,
                              widget.splitBill.title,
                            );
                            if (!confirmed || !context.mounted) return;
                            widget.onDeleteSplit!(widget.splitBill.id);
                            widget.onBack();
                            showNeoSnack(
                              context,
                              tr(
                                'ring_deleted',
                              ).replaceAll('{title}', widget.splitBill.title),
                            );
                          },
                        ),
                      ),
                    NeoCircleButton(
                      icon: Icons.share_rounded,
                      onTap: _shareWhatsApp,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Text(
              tr('ring_pembayaran'),
              style: Theme.of(
                context,
              ).textTheme.headlineLarge?.copyWith(fontSize: 30),
            ),
            const SizedBox(height: 4),
            Text(
              '${widget.splitBill.title} - ${DateFormatter.formatDate(widget.splitBill.date)}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),

            // Total Bill Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              decoration: BoxDecoration(
                color: AppColors.primaryContainer,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: AppColors.borderBlack,
                  width: AppColors.borderWidth,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.borderBlack,
                    offset: AppColors.shadowOffset,
                    blurRadius: 0,
                  ),
                ],
              ),
              child: Column(
                children: [
                  Text(
                    tr('ring_total_tagihan').toUpperCase(),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.onPrimaryContainer,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    formatCurrency(widget.splitBill.totalAmount),
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      fontSize: 30,
                      color: AppColors.onPrimaryContainer,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerLowest.withAlpha(170),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: AppColors.borderBlack,
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.receipt_long_rounded,
                          size: 16,
                          color: AppColors.onSurface,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          tr('ring_incl_tax').replaceAll('{pct}', '$pct'),
                          style: Theme.of(context).textTheme.labelMedium
                              ?.copyWith(color: AppColors.onSurface),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Breakdown Per Member
            LayoutBuilder(
              builder: (context, constraints) {
                final twoCol = constraints.maxWidth > 640;
                final cardWidth = twoCol
                    ? (constraints.maxWidth - 12) / 2
                    : constraints.maxWidth;
                return Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: _members.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final member = entry.value;
                    return SizedBox(
                      width: cardWidth,
                      child: _buildMemberCard(context, member, idx),
                    );
                  }).toList(),
                );
              },
            ),

            const SizedBox(height: 24),

            // Actions
            NeoButton(
              onTap: _shareWhatsApp,
              width: double.infinity,
              backgroundColor: AppColors.accentGreen,
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.send_rounded, color: Colors.black, size: 20),
                  const SizedBox(width: 8),
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        tr('ring_bagikan'),
                        style: const TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            NeoButton(
              onTap: _exportPdf,
              width: double.infinity,
              backgroundColor: AppColors.surfaceContainerLowest,
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.download_rounded,
                    color: AppColors.onSurface,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        tr('ring_simpan_pdf'),
                        style: TextStyle(
                          color: AppColors.onSurface,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildMemberCard(BuildContext context, Member member, int index) {
    final memberItems = _memberItems(member);
    final subtotal = _memberSubtotal(member);
    final taxShare = (member.amountOwed - subtotal)
        .clamp(0.0, double.infinity)
        .toDouble();
    final pct = _taxPct();
    final cardBg = member.isPaid
        ? AppColors.secondaryContainer.withAlpha(90)
        : AppColors.surfaceContainerLow;

    return GestureDetector(
      onTap: () => _toggleMemberPaidStatus(index),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppColors.borderBlack,
            width: AppColors.borderWidth,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Row(
                    children: [
                      NeoAvatar(member: member, size: 40, fontSize: 16),
                      const SizedBox(width: 10),
                      Flexible(
                        child: Text(
                          member.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(
                            context,
                          ).textTheme.headlineSmall?.copyWith(fontSize: 16),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: member.isPaid
                        ? AppColors.secondaryContainer
                        : AppColors.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: AppColors.borderBlack,
                      width: 1.5,
                    ),
                  ),
                  child: Text(
                    member.isPaid ? tr('ring_lunas') : tr('ring_belum_bayar2'),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: member.isPaid
                          ? AppColors.onAccent(AppColors.secondaryContainer)
                          : AppColors.onSurface,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Divider(height: 1, thickness: 2.5, color: AppColors.borderBlack),
            const SizedBox(height: 10),
            if (memberItems.isEmpty)
              Text(
                '-',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              )
            else
              ...memberItems.map((item) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          '${item.name} (x${item.quantity})',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        formatCurrency(item.price * item.quantity),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            const SizedBox(height: 10),
            Divider(height: 1, thickness: 2.5, color: AppColors.borderBlack),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  tr('ring_subtotal'),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
                Text(
                  formatCurrency(subtotal),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            if (taxShare > 0) ...[
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    tr('ring_pajak_layanan').replaceAll('{pct}', '$pct'),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    formatCurrency(taxShare),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  tr('ring_total_anda'),
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                Text(
                  formatCurrency(member.amountOwed),
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  }
