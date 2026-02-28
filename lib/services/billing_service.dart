import 'dart:io';
import 'dart:ui' show Color;
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import '../models/order.dart';

/// Generates billing PDF invoices for orders and supports sharing via WhatsApp.
class BillingService {
  BillingService._();
  static final instance = BillingService._();

  pw.Font? _regularFont;
  pw.Font? _boldFont;

  Future<void> _loadFonts() async {
    if (_regularFont != null) return;
    final regularData = await rootBundle.load('assets/fonts/Inter-Regular.ttf');
    final boldData = await rootBundle.load('assets/fonts/Inter-Bold.ttf');
    _regularFont = pw.Font.ttf(regularData);
    _boldFont = pw.Font.ttf(boldData);
  }

  /// Generates a PDF invoice for the given order and returns the file path.
  Future<String> generateInvoice({
    required Order order,
    required String shopName,
    String shopAddress = '',
    String shopPhone = '',
    String shopGstin = '',
  }) async {
    await _loadFonts();
    final pdf = pw.Document();
    final dateFormat = DateFormat('dd MMM yyyy');
    final gold = PdfColor.fromHex('#D4A574');
    final dark = PdfColor.fromHex('#1a1a1a');
    final grey = PdfColor.fromHex('#666666');
    final lightGrey = PdfColor.fromHex('#f0f0f0');

    final pdfTheme = pw.ThemeData.withFont(
      base: _regularFont!,
      bold: _boldFont!,
    );

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        theme: pdfTheme,
        header: (context) => _buildHeader(
          shopName: shopName,
          shopAddress: shopAddress,
          shopPhone: shopPhone,
          shopGstin: shopGstin,
          gold: gold,
          dark: dark,
          grey: grey,
        ),
        footer: (context) => _buildFooter(shopName: shopName, grey: grey),
        build: (context) => [
          pw.SizedBox(height: 20),

          // Invoice & Order info
          _buildInfoRow(
              order: order,
              dateFormat: dateFormat,
              dark: dark,
              grey: grey,
              gold: gold),
          pw.SizedBox(height: 8),

          // Customer info
          _buildCustomerInfo(
              order: order, dark: dark, grey: grey, lightGrey: lightGrey),
          pw.SizedBox(height: 20),

          // Items table
          _buildItemsTable(
              order: order,
              dark: dark,
              grey: grey,
              gold: gold,
              lightGrey: lightGrey),
          pw.SizedBox(height: 16),

          // Totals
          _buildTotals(order: order, dark: dark, grey: grey, gold: gold),
          pw.SizedBox(height: 24),

          // Payment history
          if (order.advancePaid > 0 || order.payments.isNotEmpty)
            _buildPaymentHistory(
                order: order,
                dateFormat: dateFormat,
                dark: dark,
                grey: grey,
                lightGrey: lightGrey),
        ],
      ),
    );

    final dir = await getTemporaryDirectory();
    final file = File(
        '${dir.path}/invoice_${order.orderNumber.replaceAll('-', '_')}.pdf');
    await file.writeAsBytes(await pdf.save());
    return file.path;
  }

  /// Generates and shares the invoice PDF.
  Future<void> shareInvoice({
    required Order order,
    required String shopName,
    String shopAddress = '',
    String shopPhone = '',
    String shopGstin = '',
  }) async {
    final path = await generateInvoice(
      order: order,
      shopName: shopName,
      shopAddress: shopAddress,
      shopPhone: shopPhone,
      shopGstin: shopGstin,
    );
    await Share.shareXFiles(
      [XFile(path)],
      text: 'Invoice for ${order.orderNumber} - $shopName',
    );
  }

  /// Generates the invoice PDF and shares it via the system share sheet.
  /// User can pick WhatsApp (or any other app) from the share sheet.
  Future<void> shareInvoiceViaWhatsApp({
    required Order order,
    required String shopName,
    String shopAddress = '',
    String shopPhone = '',
    String shopGstin = '',
  }) async {
    final path = await generateInvoice(
      order: order,
      shopName: shopName,
      shopAddress: shopAddress,
      shopPhone: shopPhone,
      shopGstin: shopGstin,
    );

    // Use system share sheet — user picks WhatsApp or any messaging app
    await Share.shareXFiles(
      [XFile(path)],
      text:
          'Hi ${order.customer.name}, here is the invoice for order ${order.orderNumber} - $shopName',
    );
  }

  // ─── Header ──────────────────────────────────────────────────────

  pw.Widget _buildHeader({
    required String shopName,
    required String shopAddress,
    required String shopPhone,
    required String shopGstin,
    required PdfColor gold,
    required PdfColor dark,
    required PdfColor grey,
  }) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  shopName,
                  style: pw.TextStyle(
                    fontSize: 22,
                    fontWeight: pw.FontWeight.bold,
                    color: dark,
                  ),
                ),
                if (shopAddress.isNotEmpty)
                  pw.Padding(
                    padding: const pw.EdgeInsets.only(top: 4),
                    child: pw.Text(shopAddress,
                        style: pw.TextStyle(fontSize: 10, color: grey)),
                  ),
                if (shopPhone.isNotEmpty)
                  pw.Text('Tel: $shopPhone',
                      style: pw.TextStyle(fontSize: 10, color: grey)),
                if (shopGstin.isNotEmpty)
                  pw.Text('GSTIN: $shopGstin',
                      style: pw.TextStyle(fontSize: 10, color: grey)),
              ],
            ),
            pw.Container(
              padding:
                  const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: pw.BoxDecoration(
                color: gold,
                borderRadius: pw.BorderRadius.circular(4),
              ),
              child: pw.Text(
                'INVOICE',
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white,
                ),
              ),
            ),
          ],
        ),
        pw.SizedBox(height: 8),
        pw.Container(height: 2, color: gold),
      ],
    );
  }

  // ─── Footer ──────────────────────────────────────────────────────

  pw.Widget _buildFooter({
    required String shopName,
    required PdfColor grey,
  }) {
    return pw.Column(
      children: [
        pw.Divider(color: grey, thickness: 0.5),
        pw.SizedBox(height: 4),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text('Thank you for choosing $shopName!',
                style: pw.TextStyle(
                    fontSize: 9, color: grey, fontStyle: pw.FontStyle.italic)),
            pw.Text(
                'Generated on ${DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now())}',
                style: pw.TextStyle(fontSize: 8, color: grey)),
          ],
        ),
      ],
    );
  }

  // ─── Info Row ────────────────────────────────────────────────────

  pw.Widget _buildInfoRow({
    required Order order,
    required DateFormat dateFormat,
    required PdfColor dark,
    required PdfColor grey,
    required PdfColor gold,
  }) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('Invoice #: ${order.orderNumber}',
                style: pw.TextStyle(
                    fontSize: 12, fontWeight: pw.FontWeight.bold, color: dark)),
            pw.Text('Date: ${dateFormat.format(order.createdAt)}',
                style: pw.TextStyle(fontSize: 10, color: grey)),
            pw.Text('Due: ${dateFormat.format(order.dueDate)}',
                style: pw.TextStyle(fontSize: 10, color: grey)),
          ],
        ),
        pw.Row(
          children: [
            pw.Container(
              padding:
                  const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: pw.BoxDecoration(
                color: order.status.color.toPdfColor(),
                borderRadius: pw.BorderRadius.circular(3),
              ),
              child: pw.Text(
                order.status.label.toUpperCase(),
                style: pw.TextStyle(
                    fontSize: 9,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.white),
              ),
            ),
            if (order.isUrgent) ...[
              pw.SizedBox(width: 6),
              pw.Container(
                padding:
                    const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: pw.BoxDecoration(
                  color: PdfColors.red,
                  borderRadius: pw.BorderRadius.circular(3),
                ),
                child: pw.Text('URGENT',
                    style: pw.TextStyle(
                        fontSize: 9,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.white)),
              ),
            ],
          ],
        ),
      ],
    );
  }

  // ─── Customer Info ───────────────────────────────────────────────

  pw.Widget _buildCustomerInfo({
    required Order order,
    required PdfColor dark,
    required PdfColor grey,
    required PdfColor lightGrey,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: lightGrey,
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Row(
        children: [
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('BILL TO',
                    style: pw.TextStyle(
                        fontSize: 8,
                        fontWeight: pw.FontWeight.bold,
                        color: grey)),
                pw.SizedBox(height: 4),
                pw.Text(order.customer.name,
                    style: pw.TextStyle(
                        fontSize: 12,
                        fontWeight: pw.FontWeight.bold,
                        color: dark)),
                pw.Text(order.customer.phone,
                    style: pw.TextStyle(fontSize: 10, color: grey)),
                if (order.customer.address != null &&
                    order.customer.address!.isNotEmpty)
                  pw.Text(order.customer.address!,
                      style: pw.TextStyle(fontSize: 10, color: grey)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Items Table ─────────────────────────────────────────────────

  pw.Widget _buildItemsTable({
    required Order order,
    required PdfColor dark,
    required PdfColor grey,
    required PdfColor gold,
    required PdfColor lightGrey,
  }) {
    return pw.TableHelper.fromTextArray(
      border:
          pw.TableBorder.all(color: PdfColor.fromHex('#dddddd'), width: 0.5),
      headerStyle: pw.TextStyle(
          fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.white),
      headerDecoration: pw.BoxDecoration(color: gold),
      cellStyle: pw.TextStyle(fontSize: 10, color: dark),
      cellAlignments: {
        0: pw.Alignment.centerLeft,
        1: pw.Alignment.center,
        2: pw.Alignment.centerRight,
        3: pw.Alignment.center,
        4: pw.Alignment.centerRight,
      },
      headerAlignments: {
        0: pw.Alignment.centerLeft,
        1: pw.Alignment.center,
        2: pw.Alignment.centerRight,
        3: pw.Alignment.center,
        4: pw.Alignment.centerRight,
      },
      cellPadding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      headers: ['Item', 'Measurements', 'Price', 'Qty', 'Total'],
      data: order.items.map((item) {
        final measurementStr = item.measurements.entries
            .map((e) => '${e.key}: ${e.value}"')
            .join(', ');
        return [
          '${item.type.label}${item.fabricDetails != null ? '\n${item.fabricDetails}' : ''}',
          measurementStr.isEmpty ? '-' : measurementStr,
          _curr(item.price),
          '${item.quantity}',
          _curr(item.total),
        ];
      }).toList(),
    );
  }

  // ─── Totals ──────────────────────────────────────────────────────

  pw.Widget _buildTotals({
    required Order order,
    required PdfColor dark,
    required PdfColor grey,
    required PdfColor gold,
  }) {
    return pw.Align(
      alignment: pw.Alignment.centerRight,
      child: pw.SizedBox(
        width: 220,
        child: pw.Column(
          children: [
            _totalRow(
                'Subtotal',
                _curr(order.items.fold(0.0, (s, i) => s + i.total)),
                dark,
                grey),
            if (order.isUrgent && order.urgentCharge > 0)
              _totalRow('Urgent Charge', _curr(order.urgentCharge), dark, grey),
            pw.Divider(color: grey),
            _totalRow('Total', _curr(order.totalAmount), dark, gold,
                bold: true, large: true),
            pw.SizedBox(height: 4),
            _totalRow('Paid', _curr(order.totalPaid), dark,
                PdfColor.fromHex('#10B981')),
            _totalRow(
              'Balance Due',
              _curr(order.balanceAmount),
              dark,
              order.balanceAmount > 0
                  ? PdfColors.red
                  : PdfColor.fromHex('#10B981'),
              bold: true,
            ),
          ],
        ),
      ),
    );
  }

  pw.Widget _totalRow(
      String label, String value, PdfColor dark, PdfColor valueColor,
      {bool bold = false, bool large = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label,
              style: pw.TextStyle(
                  fontSize: large ? 12 : 10,
                  fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
                  color: dark)),
          pw.Text(value,
              style: pw.TextStyle(
                  fontSize: large ? 14 : 10,
                  fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
                  color: valueColor)),
        ],
      ),
    );
  }

  // ─── Payment History ─────────────────────────────────────────────

  pw.Widget _buildPaymentHistory({
    required Order order,
    required DateFormat dateFormat,
    required PdfColor dark,
    required PdfColor grey,
    required PdfColor lightGrey,
  }) {
    final payments = <pw.Widget>[];

    if (order.advancePaid > 0) {
      payments.add(
        _paymentEntry('Advance', dateFormat.format(order.createdAt),
            _curr(order.advancePaid), 'Cash', dark, grey),
      );
    }

    for (final p in order.payments) {
      payments.add(
        _paymentEntry(p.notes ?? 'Payment', dateFormat.format(p.date),
            _curr(p.amount), p.method, dark, grey),
      );
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('PAYMENT HISTORY',
            style: pw.TextStyle(
                fontSize: 10, fontWeight: pw.FontWeight.bold, color: dark)),
        pw.SizedBox(height: 6),
        ...payments,
      ],
    );
  }

  pw.Widget _paymentEntry(String label, String date, String amount,
      String method, PdfColor dark, PdfColor grey) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 3),
      child: pw.Row(
        children: [
          pw.SizedBox(
            width: 180,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(label, style: pw.TextStyle(fontSize: 10, color: dark)),
                pw.Text('$date • $method',
                    style: pw.TextStyle(fontSize: 8, color: grey)),
              ],
            ),
          ),
          pw.Expanded(
            child: pw.Text(amount,
                style: pw.TextStyle(
                    fontSize: 10, fontWeight: pw.FontWeight.bold, color: dark),
                textAlign: pw.TextAlign.right),
          ),
        ],
      ),
    );
  }

  String _curr(double v) =>
      '₹${v.toStringAsFixed(v == v.roundToDouble() ? 0 : 2)}';
}

/// Extension to convert Flutter Color to PdfColor
extension _ColorToPdf on Color {
  PdfColor toPdfColor() => PdfColor(
        r / 255,
        g / 255,
        b / 255,
        a / 255,
      );
}
