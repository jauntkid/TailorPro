import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/data_service.dart';
import '../../services/auth_service.dart';
import '../../services/store_service.dart';
import '../../models/store.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final dataService = context.watch<DataService>();
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = dataService.themeMode == ThemeMode.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          // ─── Shop Details ─────────────────────────────────────────
          _SectionLabel(text: 'Shop', cs: cs),
          _SettingsTile(
            icon: Icons.storefront_rounded,
            title: dataService.shopName,
            subtitle: dataService.shopAddress.isNotEmpty
                ? dataService.shopAddress
                : 'Tap to edit shop details',
            onTap: () => _showShopDetailsSheet(context, dataService),
          ),
          const SizedBox(height: 16),

          // ─── Manage Items ─────────────────────────────────────────
          _SectionLabel(text: 'Catalogue', cs: cs),
          _SettingsTile(
            icon: Icons.checkroom_rounded,
            title: 'Manage Items',
            subtitle: '${dataService.garmentTypes.length} items configured',
            onTap: () => _showManageItemsSheet(context, dataService),
          ),
          const SizedBox(height: 16),

          // ─── Appearance ───────────────────────────────────────────
          _SectionLabel(text: 'Appearance', cs: cs),
          _SettingsTile(
            icon: isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
            title: 'Dark Mode',
            subtitle: isDark ? 'On' : 'Off',
            trailing: Switch.adaptive(
              value: isDark,
              onChanged: (v) => dataService
                  .setThemeMode(v ? ThemeMode.dark : ThemeMode.light),
            ),
          ),
          const SizedBox(height: 16),

          // ─── Data ─────────────────────────────────────────────────
          _SectionLabel(text: 'Data', cs: cs),
          _SettingsTile(
            icon: Icons.people_outline_rounded,
            title: 'Customers',
            trailing: _CountBadge(
              count: dataService.totalCustomers,
              cs: cs,
            ),
          ),
          _SettingsTile(
            icon: Icons.receipt_long_outlined,
            title: 'Orders',
            trailing: _CountBadge(
              count: dataService.totalOrders,
              cs: cs,
            ),
          ),
          const SizedBox(height: 16),

          // ─── About ────────────────────────────────────────────────
          _SectionLabel(text: 'About', cs: cs),
          const _SettingsTile(
            icon: Icons.storefront_rounded,
            title: 'Godukaan',
            subtitle: 'v1.0.0',
          ),
          _SettingsTile(
            icon: Icons.privacy_tip_outlined,
            title: 'Privacy Policy & Terms',
            subtitle: 'How we handle your data',
            onTap: () => Navigator.pushNamed(context, '/privacy-policy'),
          ),
          const SizedBox(height: 16),

          // ─── Store ────────────────────────────────────────────────
          _SectionLabel(text: 'Store', cs: cs),
          _StoreManagementSection(cs: cs),
          const SizedBox(height: 24),

          // ─── Account ──────────────────────────────────────────────
          _SectionLabel(text: 'Account', cs: cs),

          // ─── Danger Zone ──────────────────────────────────────────
          _SectionLabel(text: 'Danger Zone', cs: cs),
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 20),
            leading: Icon(Icons.delete_sweep_rounded,
                size: 20, color: Colors.redAccent.withValues(alpha: 0.8)),
            title: const Text(
              'Clear All Data',
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: Colors.redAccent),
            ),
            subtitle: Text(
              'Delete all customers, orders & measurements',
              style: TextStyle(
                  fontSize: 12, color: cs.onSurface.withValues(alpha: 0.4)),
            ),
            dense: true,
            onTap: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  icon: Icon(Icons.delete_forever_rounded,
                      size: 40, color: cs.error),
                  title: const Text('Clear All Data?'),
                  content: const Text(
                      'This will permanently delete ALL customers, orders, measurements, and payment records.\n\nThis action CANNOT be undone.'),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('Cancel')),
                    FilledButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      style: FilledButton.styleFrom(backgroundColor: cs.error),
                      child: const Text('Delete Everything'),
                    ),
                  ],
                ),
              );
              if (confirmed == true && context.mounted) {
                // Double confirm
                final reallyConfirmed = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Are you absolutely sure?'),
                    content: const Text(
                        'Type DELETE to confirm.\nAll data will be permanently lost.'),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('Cancel')),
                      FilledButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        style:
                            FilledButton.styleFrom(backgroundColor: cs.error),
                        child: const Text('Yes, Delete All'),
                      ),
                    ],
                  ),
                );
                if (reallyConfirmed == true && context.mounted) {
                  await dataService.clearAllData();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('All data has been cleared')),
                    );
                  }
                }
              }
            },
          ),
          const SizedBox(height: 8),
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 20),
            leading: Icon(Icons.logout_rounded,
                size: 20, color: Colors.redAccent.withValues(alpha: 0.8)),
            title: const Text(
              'Sign Out',
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: Colors.redAccent),
            ),
            dense: true,
            onTap: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Sign Out'),
                  content: const Text('Are you sure you want to sign out?'),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('Cancel')),
                    TextButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text('Sign Out')),
                  ],
                ),
              );
              if (confirmed == true && context.mounted) {
                await AuthService().signOut();
              }
            },
          ),
        ],
      ),
    );
  }

  // ─── Shop Details Bottom Sheet ──────────────────────────────────────────────
  void _showShopDetailsSheet(BuildContext context, DataService ds) {
    final cs = Theme.of(context).colorScheme;
    final nameCtrl = TextEditingController(text: ds.shopName);
    final addressCtrl = TextEditingController(text: ds.shopAddress);
    final phoneCtrl = TextEditingController(text: ds.shopPhone);
    final gstinCtrl = TextEditingController(text: ds.shopGstin);
    final upiCtrl = TextEditingController(text: ds.shopUpi);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: cs.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
          24,
          24,
          24,
          MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: cs.onSurface.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Shop Details',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: cs.onSurface,
              ),
            ),
            const SizedBox(height: 20),
            _SheetTextField(
                controller: nameCtrl,
                label: 'Shop Name',
                icon: Icons.storefront_rounded),
            const SizedBox(height: 12),
            _SheetTextField(
                controller: addressCtrl,
                label: 'Address',
                icon: Icons.location_on_outlined),
            const SizedBox(height: 12),
            _SheetTextField(
                controller: phoneCtrl,
                label: 'Phone',
                icon: Icons.phone_outlined,
                keyboardType: TextInputType.phone),
            const SizedBox(height: 12),
            _SheetTextField(
                controller: gstinCtrl,
                label: 'GSTIN',
                icon: Icons.receipt_outlined),
            const SizedBox(height: 12),
            _SheetTextField(
                controller: upiCtrl,
                label: 'UPI ID (e.g. shop@upi)',
                icon: Icons.currency_rupee_rounded),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: cs.primary,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  ds.updateShopDetails(
                    name: nameCtrl.text.trim(),
                    address: addressCtrl.text.trim(),
                    phone: phoneCtrl.text.trim(),
                    gstin: gstinCtrl.text.trim(),
                    upi: upiCtrl.text.trim(),
                  );
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Shop details updated'),
                        duration: Duration(seconds: 2)),
                  );
                },
                child: const Text('Save',
                    style:
                        TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Manage Items Bottom Sheet ──────────────────────────────────────────────
  void _showManageItemsSheet(BuildContext context, DataService ds) {
    final cs = Theme.of(context).colorScheme;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: cs.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _ManageItemsSheet(ds: ds),
    );
  }
}

// ─── Helpers ──────────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;
  final ColorScheme cs;
  const _SectionLabel({required this.text, required this.cs});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 16, 6),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 1,
          color: cs.onSurface.withValues(alpha: 0.35),
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
      leading: Icon(icon, size: 20, color: cs.onSurface.withValues(alpha: 0.5)),
      title: Text(
        title,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle!,
              style: TextStyle(
                fontSize: 12,
                color: cs.onSurface.withValues(alpha: 0.4),
              ),
            )
          : null,
      trailing: trailing ??
          (onTap != null
              ? Icon(Icons.chevron_right_rounded,
                  size: 20, color: cs.onSurface.withValues(alpha: 0.3))
              : null),
      dense: true,
      onTap: onTap != null
          ? () {
              HapticFeedback.lightImpact();
              onTap!();
            }
          : null,
    );
  }
}

class _CountBadge extends StatelessWidget {
  final int count;
  final ColorScheme cs;
  const _CountBadge({required this.count, required this.cs});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: cs.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        '$count',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: cs.primary,
        ),
      ),
    );
  }
}

class _SheetTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final TextInputType keyboardType;

  const _SheetTextField({
    required this.controller,
    required this.label,
    required this.icon,
    this.keyboardType = TextInputType.text,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        labelStyle:
            TextStyle(fontSize: 13, color: cs.onSurface.withValues(alpha: 0.5)),
        prefixIcon:
            Icon(icon, size: 18, color: cs.onSurface.withValues(alpha: 0.4)),
        filled: true,
        fillColor: cs.onSurface.withValues(alpha: 0.05),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}

class _ManageItemsSheet extends StatefulWidget {
  final DataService ds;
  const _ManageItemsSheet({required this.ds});

  @override
  State<_ManageItemsSheet> createState() => _ManageItemsSheetState();
}

class _ManageItemsSheetState extends State<_ManageItemsSheet> {
  late List<String> _items;
  late Map<String, double> _prices;
  final _newItemCtrl = TextEditingController();
  final _newPriceCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _items = List.from(widget.ds.garmentTypes);
    _prices = Map.from(widget.ds.garmentDefaults);
  }

  @override
  void dispose() {
    _newItemCtrl.dispose();
    _newPriceCtrl.dispose();
    super.dispose();
  }

  void _addItem() {
    final text = _newItemCtrl.text.trim();
    if (text.isEmpty) return;
    if (_items.any((e) => e.toLowerCase() == text.toLowerCase())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Item already exists'),
            duration: Duration(seconds: 1)),
      );
      return;
    }
    final price = double.tryParse(_newPriceCtrl.text.trim()) ?? 0;
    setState(() {
      _items.add(text);
      _prices[text] = price;
    });
    _newItemCtrl.clear();
    _newPriceCtrl.clear();
    widget.ds.updateGarmentTypes(_items);
    widget.ds.updateGarmentDefault(text, price);
  }

  void _removeItem(int index) {
    final name = _items[index];
    setState(() {
      _items.removeAt(index);
      _prices.remove(name);
    });
    widget.ds.updateGarmentTypes(_items);
  }

  void _editItem(int index) {
    final itemName = _items[index];
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _EditItemScreen(
          ds: widget.ds,
          itemName: itemName,
          price: _prices[itemName] ?? 0,
          onSaved: (newName, newPrice) {
            setState(() {
              if (newName != itemName) {
                _items[index] = newName;
                _prices.remove(itemName);
                widget.ds.renameGarmentType(itemName, newName);
              }
              _prices[newName] = newPrice;
              widget.ds.updateGarmentDefault(newName, newPrice);
            });
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final unit = widget.ds.measurementUnit;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        24,
        24,
        24,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: cs.onSurface.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Manage Items',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface,
                  ),
                ),
              ),
              // Measurement unit toggle
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: cs.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: unit,
                    isDense: true,
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: cs.primary),
                    dropdownColor: cs.surface,
                    items: const [
                      DropdownMenuItem(value: 'inches', child: Text('Inches')),
                      DropdownMenuItem(value: 'cm', child: Text('CM')),
                    ],
                    onChanged: (v) {
                      if (v != null) {
                        widget.ds.updateMeasurementUnit(v);
                        setState(() {});
                      }
                    },
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Add new item row
          Row(
            children: [
              Expanded(
                flex: 3,
                child: TextField(
                  controller: _newItemCtrl,
                  style: const TextStyle(fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Item name',
                    hintStyle: TextStyle(
                        fontSize: 13,
                        color: cs.onSurface.withValues(alpha: 0.35)),
                    filled: true,
                    fillColor: cs.onSurface.withValues(alpha: 0.05),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                  ),
                  onSubmitted: (_) => _addItem(),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: TextField(
                  controller: _newPriceCtrl,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(fontSize: 14),
                  decoration: InputDecoration(
                    hintText: '₹ Price',
                    hintStyle: TextStyle(
                        fontSize: 13,
                        color: cs.onSurface.withValues(alpha: 0.35)),
                    filled: true,
                    fillColor: cs.onSurface.withValues(alpha: 0.05),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                  ),
                  onSubmitted: (_) => _addItem(),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                onPressed: _addItem,
                icon: const Icon(Icons.add_rounded, size: 20),
                style: IconButton.styleFrom(
                  backgroundColor: cs.primary,
                  foregroundColor: cs.onPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 320),
            child: _items.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'No items added yet',
                        style: TextStyle(
                          fontSize: 13,
                          color: cs.onSurface.withValues(alpha: 0.4),
                        ),
                      ),
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: _items.length,
                    itemBuilder: (ctx, i) {
                      final price = _prices[_items[i]] ?? 0;
                      final fields = widget.ds.getMeasurementFields(_items[i]);
                      return ListTile(
                        dense: true,
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 8),
                        leading: Icon(Icons.checkroom_rounded,
                            size: 16, color: cs.primary.withValues(alpha: 0.6)),
                        title: Text(_items[i],
                            style: const TextStyle(fontSize: 14)),
                        subtitle: Text(
                          '₹${price > 0 ? price.toStringAsFixed(0) : '—'} · ${fields.length} fields',
                          style: TextStyle(
                            fontSize: 12,
                            color: cs.onSurface.withValues(alpha: 0.4),
                          ),
                        ),
                        onTap: () => _editItem(i),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(Icons.edit_rounded,
                                  size: 15,
                                  color: cs.onSurface.withValues(alpha: 0.4)),
                              onPressed: () => _editItem(i),
                              visualDensity: VisualDensity.compact,
                            ),
                            IconButton(
                              icon: Icon(Icons.delete_outline_rounded,
                                  size: 15,
                                  color:
                                      Colors.redAccent.withValues(alpha: 0.6)),
                              onPressed: () => _removeItem(i),
                              visualDensity: VisualDensity.compact,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

/// Full-screen editor for a single item's settings: name, price, and measurement fields.
class _EditItemScreen extends StatefulWidget {
  final DataService ds;
  final String itemName;
  final double price;
  final void Function(String newName, double newPrice) onSaved;

  const _EditItemScreen({
    required this.ds,
    required this.itemName,
    required this.price,
    required this.onSaved,
  });

  @override
  State<_EditItemScreen> createState() => _EditItemScreenState();
}

class _EditItemScreenState extends State<_EditItemScreen> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _priceCtrl;
  late List<String> _fields;
  final _newFieldCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.itemName);
    _priceCtrl = TextEditingController(
      text: widget.price > 0 ? widget.price.toStringAsFixed(0) : '',
    );
    _fields = List.from(widget.ds.getMeasurementFields(widget.itemName));
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _priceCtrl.dispose();
    _newFieldCtrl.dispose();
    super.dispose();
  }

  void _addField() {
    final text = _newFieldCtrl.text.trim();
    if (text.isEmpty) return;
    if (_fields.any((f) => f.toLowerCase() == text.toLowerCase())) return;
    setState(() => _fields.add(text));
    _newFieldCtrl.clear();
  }

  void _removeField(int index) {
    setState(() => _fields.removeAt(index));
  }

  void _reorderField(int oldIndex, int newIndex) {
    if (newIndex > oldIndex) newIndex -= 1;
    setState(() {
      final item = _fields.removeAt(oldIndex);
      _fields.insert(newIndex, item);
    });
  }

  void _save() {
    final newName = _nameCtrl.text.trim();
    final newPrice = double.tryParse(_priceCtrl.text.trim()) ?? 0;
    if (newName.isEmpty) return;

    widget.ds.updateGarmentMeasurements(
      newName.isEmpty ? widget.itemName : newName,
      _fields,
    );
    widget.onSaved(newName, newPrice);
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text('$newName updated'),
          duration: const Duration(seconds: 2)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final unit = widget.ds.measurementUnit;

    return Scaffold(
      appBar: AppBar(
        title: Text('Edit ${widget.itemName}'),
        actions: [
          TextButton(
            onPressed: _save,
            child: Text('Save',
                style:
                    TextStyle(color: cs.primary, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Name
          TextField(
            controller: _nameCtrl,
            style: const TextStyle(fontSize: 15),
            decoration: InputDecoration(
              labelText: 'Item Name',
              prefixIcon: Icon(Icons.checkroom_rounded,
                  size: 18, color: cs.onSurface.withValues(alpha: 0.4)),
              filled: true,
              fillColor: cs.onSurface.withValues(alpha: 0.05),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 16),

          // Price
          TextField(
            controller: _priceCtrl,
            keyboardType: TextInputType.number,
            style: const TextStyle(fontSize: 15),
            decoration: InputDecoration(
              labelText: 'Default Price (₹)',
              prefixText: '₹ ',
              prefixIcon: Icon(Icons.currency_rupee_rounded,
                  size: 18, color: cs.onSurface.withValues(alpha: 0.4)),
              filled: true,
              fillColor: cs.onSurface.withValues(alpha: 0.05),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 28),

          // Measurement fields header
          Row(
            children: [
              Icon(Icons.straighten_rounded, size: 16, color: cs.primary),
              const SizedBox(width: 8),
              Text(
                'Measurement Fields ($unit)',
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'These fields will appear when creating orders for this item',
            style: TextStyle(
                fontSize: 12, color: cs.onSurface.withValues(alpha: 0.4)),
          ),
          const SizedBox(height: 12),

          // Add measurement field row
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _newFieldCtrl,
                  style: const TextStyle(fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'e.g. Chest, Shoulder, Sleeve...',
                    hintStyle: TextStyle(
                        fontSize: 13,
                        color: cs.onSurface.withValues(alpha: 0.35)),
                    filled: true,
                    fillColor: cs.onSurface.withValues(alpha: 0.05),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                  ),
                  onSubmitted: (_) => _addField(),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                onPressed: _addField,
                icon: const Icon(Icons.add_rounded, size: 20),
                style: IconButton.styleFrom(
                  backgroundColor: cs.primary,
                  foregroundColor: cs.onPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Reorderable list of fields
          if (_fields.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: Text(
                  'No measurement fields yet.\nAdd fields like Chest, Shoulder, Length, etc.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 13, color: cs.onSurface.withValues(alpha: 0.4)),
                ),
              ),
            )
          else
            ReorderableListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _fields.length,
              onReorder: _reorderField,
              itemBuilder: (ctx, i) {
                return Container(
                  key: ValueKey(_fields[i]),
                  margin: const EdgeInsets.only(bottom: 4),
                  decoration: BoxDecoration(
                    color: cs.onSurface.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: ListTile(
                    dense: true,
                    contentPadding: const EdgeInsets.only(left: 12, right: 4),
                    leading: Icon(Icons.drag_handle_rounded,
                        size: 16, color: cs.onSurface.withValues(alpha: 0.25)),
                    title:
                        Text(_fields[i], style: const TextStyle(fontSize: 14)),
                    trailing: IconButton(
                      icon: Icon(Icons.close_rounded,
                          size: 16,
                          color: Colors.redAccent.withValues(alpha: 0.6)),
                      onPressed: () => _removeField(i),
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

// ─── Store Management Section ─────────────────────────────────────────────────
class _StoreManagementSection extends StatefulWidget {
  final ColorScheme cs;
  const _StoreManagementSection({required this.cs});

  @override
  State<_StoreManagementSection> createState() =>
      _StoreManagementSectionState();
}

class _StoreManagementSectionState extends State<_StoreManagementSection> {
  final _storeService = StoreService();
  Store? _store;
  bool _loading = true;
  String? _currentUid;

  @override
  void initState() {
    super.initState();
    _loadStore();
  }

  Future<void> _loadStore() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    _currentUid = user.uid;
    final storeId = await _storeService.getUserStoreId(user.uid);
    if (storeId != null) {
      final store = await _storeService.getStore(storeId);
      if (mounted)
        setState(() {
          _store = store;
          _loading = false;
        });
    } else {
      if (mounted) setState(() => _loading = false);
    }
  }

  bool get _isOwner => _store != null && _store!.isOwner(_currentUid ?? '');

  Future<void> _addUser() async {
    String emailText = '';
    final cs = widget.cs;
    final email = await showDialog<String>(
      context: context,
      builder: (ctx) {
        final emailCtrl = TextEditingController();
        return AlertDialog(
          title: const Text('Add User'),
          content: TextField(
            controller: emailCtrl,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              hintText: 'Enter email address',
              border: OutlineInputBorder(),
            ),
            autofocus: true,
            onChanged: (v) => emailText = v.trim(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                emailText = emailCtrl.text.trim();
                Navigator.pop(ctx, emailText);
              },
              child: Text('Add', style: TextStyle(color: cs.primary)),
            ),
          ],
        );
      },
    );
    if (email != null && email.isNotEmpty && _store != null) {
      try {
        await _storeService.addAllowedEmail(
          storeId: _store!.id,
          ownerUid: _currentUid!,
          email: email,
        );
        await _loadStore();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$email added to store')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.toString())),
          );
        }
      }
    }
  }

  Future<void> _removeUser(String email) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove User'),
        content: Text('Remove $email from this store?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child:
                const Text('Remove', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
    if (confirmed == true && _store != null) {
      try {
        await _storeService.removeAllowedEmail(
          storeId: _store!.id,
          ownerUid: _currentUid!,
          email: email,
        );
        await _loadStore();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$email removed from store')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.toString())),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = widget.cs;

    if (_loading) {
      return const Padding(
        padding: EdgeInsets.all(20),
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }

    if (_store == null) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Text('No store linked', style: TextStyle(fontSize: 14)),
      );
    }

    final allowed = _store!.allowedEmails;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Store ID
        ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 20),
          leading: Icon(Icons.tag_rounded,
              size: 20, color: cs.onSurface.withValues(alpha: 0.5)),
          title: const Text('Store ID',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
          subtitle: Text(_store!.id,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: cs.primary,
                letterSpacing: 2,
              )),
          trailing: IconButton(
            icon: Icon(Icons.copy_rounded,
                size: 18, color: cs.onSurface.withValues(alpha: 0.4)),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: _store!.id));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Store ID copied to clipboard')),
              );
            },
          ),
          dense: true,
        ),

        // Owner
        ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 20),
          leading: Icon(Icons.admin_panel_settings_rounded,
              size: 20, color: cs.onSurface.withValues(alpha: 0.5)),
          title: const Text('Owner',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
          subtitle:
              Text(_store!.ownerEmail, style: const TextStyle(fontSize: 14)),
          trailing: _isOwner
              ? Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: cs.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text('You',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: cs.primary)),
                )
              : null,
          dense: true,
        ),

        // Allowed Users header
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
          child: Row(
            children: [
              Icon(Icons.people_outline_rounded,
                  size: 18, color: cs.onSurface.withValues(alpha: 0.5)),
              const SizedBox(width: 8),
              Text('Allowed Users (${allowed.length})',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: cs.onSurface.withValues(alpha: 0.7))),
              const Spacer(),
              if (_isOwner)
                TextButton.icon(
                  onPressed: _addUser,
                  icon: Icon(Icons.person_add_alt_1_rounded,
                      size: 16, color: cs.primary),
                  label: Text('Add',
                      style: TextStyle(fontSize: 13, color: cs.primary)),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    visualDensity: VisualDensity.compact,
                  ),
                ),
            ],
          ),
        ),

        // Allowed user list
        if (allowed.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Text('No additional users added yet.',
                style: TextStyle(
                    fontSize: 13, color: cs.onSurface.withValues(alpha: 0.4))),
          )
        else
          ...allowed.map((email) => ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 28),
                leading: Icon(Icons.person_outline_rounded,
                    size: 18, color: cs.onSurface.withValues(alpha: 0.4)),
                title: Text(email, style: const TextStyle(fontSize: 14)),
                trailing: _isOwner
                    ? IconButton(
                        icon: Icon(Icons.remove_circle_outline_rounded,
                            size: 18,
                            color: Colors.redAccent.withValues(alpha: 0.6)),
                        onPressed: () => _removeUser(email),
                        visualDensity: VisualDensity.compact,
                      )
                    : null,
                dense: true,
              )),
      ],
    );
  }
}
