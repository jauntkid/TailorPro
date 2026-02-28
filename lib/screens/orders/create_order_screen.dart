import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/customer.dart';
import '../../models/order.dart';
import '../../services/data_service.dart';

class CreateOrderScreen extends StatefulWidget {
  final Customer? preselectedCustomer;

  const CreateOrderScreen({super.key, this.preselectedCustomer});

  @override
  State<CreateOrderScreen> createState() => _CreateOrderScreenState();
}

class _CreateOrderScreenState extends State<CreateOrderScreen> {
  Customer? _selectedCustomer;
  final List<OrderItem> _items = [];
  final List<String> _referenceImages = [];
  DateTime? _dueDate;
  final _notesController = TextEditingController();
  final _advanceController = TextEditingController();
  final _urgentChargeController = TextEditingController();
  final _imagePicker = ImagePicker();
  bool _isUrgent = false;

  @override
  void initState() {
    super.initState();
    _selectedCustomer = widget.preselectedCustomer;
  }

  @override
  void dispose() {
    _notesController.dispose();
    _advanceController.dispose();
    _urgentChargeController.dispose();
    super.dispose();
  }

  bool get _canSubmit =>
      _selectedCustomer != null && _items.isNotEmpty && _dueDate != null;

  @override
  Widget build(BuildContext context) {
    final dataService = context.watch<DataService>();
    final customers = dataService.getCustomers();
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final total = _items.fold(0.0, (sum, item) => sum + item.total) +
        (_isUrgent ? (double.tryParse(_urgentChargeController.text) ?? 0) : 0);

    return Scaffold(
      appBar: AppBar(title: const Text('New Order')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ─── Customer ───────────────────────────────────────────────
          const _SectionHeader(title: 'Customer'),
          const SizedBox(height: 8),
          Autocomplete<Customer>(
            initialValue: _selectedCustomer != null
                ? TextEditingValue(text: _selectedCustomer!.name)
                : TextEditingValue.empty,
            displayStringForOption: (c) => c.name,
            optionsBuilder: (textEditingValue) {
              if (textEditingValue.text.isEmpty) return customers;
              final query = textEditingValue.text.toLowerCase();
              return customers.where((c) =>
                  c.name.toLowerCase().contains(query) ||
                  c.phone.contains(query));
            },
            fieldViewBuilder: (context, controller, focusNode, onSubmitted) {
              return TextField(
                controller: controller,
                focusNode: focusNode,
                decoration: InputDecoration(
                  hintText: 'Search customer by name or phone...',
                  prefixIcon: const Icon(Icons.person_search_outlined),
                  suffixIcon: _selectedCustomer != null
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () {
                            controller.clear();
                            setState(() => _selectedCustomer = null);
                          },
                        )
                      : null,
                ),
                onChanged: (value) {
                  if (value.isEmpty) {
                    setState(() => _selectedCustomer = null);
                  }
                },
              );
            },
            optionsViewBuilder: (context, onSelected, options) {
              return Align(
                alignment: Alignment.topLeft,
                child: Material(
                  elevation: 4,
                  borderRadius: BorderRadius.circular(12),
                  color: Theme.of(context).colorScheme.surface,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: 220,
                      maxWidth: MediaQuery.of(context).size.width - 32,
                    ),
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      shrinkWrap: true,
                      itemCount: options.length,
                      itemBuilder: (context, index) {
                        final customer = options.elementAt(index);
                        return ListTile(
                          dense: true,
                          leading: CircleAvatar(
                            radius: 16,
                            backgroundColor: Theme.of(context)
                                .colorScheme
                                .primary
                                .withValues(alpha: 0.1),
                            child: Text(
                              customer.name[0].toUpperCase(),
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          title: Text(customer.name,
                              style: const TextStyle(fontSize: 14)),
                          subtitle: Text(customer.phone,
                              style: const TextStyle(fontSize: 12)),
                          onTap: () => onSelected(customer),
                        );
                      },
                    ),
                  ),
                ),
              );
            },
            onSelected: (customer) {
              setState(() => _selectedCustomer = customer);
            },
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () async {
                final result =
                    await Navigator.pushNamed(context, '/add-customer');
                if (result is Customer && mounted) {
                  setState(() => _selectedCustomer = result);
                }
              },
              icon: const Icon(Icons.person_add, size: 18),
              label: const Text('New Customer'),
            ),
          ),
          const SizedBox(height: 8),

          // ─── Items ──────────────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const _SectionHeader(title: 'Items'),
              FilledButton.tonalIcon(
                onPressed: _showAddItemSheet,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add Item'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (_items.isEmpty)
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                border: Border.all(
                  color: cs.outline.withValues(alpha: 0.1),
                  style: BorderStyle.solid,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Icon(Icons.checkroom_outlined,
                      size: 28, color: cs.onSurface.withValues(alpha: 0.2)),
                  const SizedBox(height: 8),
                  Text(
                    'No items added yet.\nTap "Add Item" to get started.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: cs.onSurfaceVariant),
                  ),
                ],
              ),
            )
          else
            ..._items.asMap().entries.map(
                  (entry) => _buildItemCard(entry.key, entry.value, theme, cs),
                ),
          const SizedBox(height: 16),

          // ─── Due Date ───────────────────────────────────────────────
          const _SectionHeader(title: 'Due Date'),
          const SizedBox(height: 8),
          InkWell(
            onTap: _pickDueDate,
            borderRadius: BorderRadius.circular(12),
            child: InputDecorator(
              decoration: const InputDecoration(
                hintText: 'Select due date',
                prefixIcon: Icon(Icons.calendar_today),
              ),
              child: Text(
                _dueDate != null
                    ? DateFormat('EEEE, MMM d, yyyy').format(_dueDate!)
                    : 'Tap to select',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: _dueDate != null ? cs.onSurface : cs.onSurfaceVariant,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // ─── Reference Images ───────────────────────────────────────
          const _SectionHeader(title: 'Reference Images'),
          const SizedBox(height: 8),
          SizedBox(
            height: 100,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                ..._referenceImages.asMap().entries.map(
                      (entry) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Stack(
                          children: [
                            Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                color: cs.primary.withValues(alpha: 0.08),
                                border: Border.all(
                                  color: cs.primary.withValues(alpha: 0.15),
                                ),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: _buildImagePreview(entry.value, cs),
                              ),
                            ),
                            Positioned(
                              top: 2,
                              right: 2,
                              child: GestureDetector(
                                onTap: () => setState(
                                    () => _referenceImages.removeAt(entry.key)),
                                child: Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: BoxDecoration(
                                    color: cs.error,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(Icons.close,
                                      size: 14, color: cs.onError),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                GestureDetector(
                  onTap: _pickReferenceImage,
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: cs.outline.withValues(alpha: 0.15),
                        style: BorderStyle.solid,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_a_photo_outlined,
                            size: 24,
                            color: cs.onSurface.withValues(alpha: 0.4)),
                        const SizedBox(height: 4),
                        Text(
                          'Add Photo',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: cs.onSurface.withValues(alpha: 0.4),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ─── Notes ──────────────────────────────────────────────────
          TextField(
            controller: _notesController,
            textInputAction: TextInputAction.done,
            decoration: const InputDecoration(
              labelText: 'Notes (optional)',
              prefixIcon: Icon(Icons.note_outlined),
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 20),

          // ─── Urgent Order ───────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: _isUrgent
                  ? Colors.redAccent.withValues(alpha: 0.06)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _isUrgent
                    ? Colors.redAccent.withValues(alpha: 0.2)
                    : cs.outline.withValues(alpha: 0.1),
              ),
            ),
            child: Column(
              children: [
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: Row(
                    children: [
                      Icon(Icons.bolt_rounded,
                          size: 20,
                          color: _isUrgent
                              ? Colors.redAccent
                              : cs.onSurface.withValues(alpha: 0.5)),
                      const SizedBox(width: 8),
                      const Text('Urgent Order',
                          style: TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w500)),
                    ],
                  ),
                  subtitle: Text(
                    'Priority processing with extra charge',
                    style: TextStyle(
                        fontSize: 12,
                        color: cs.onSurface.withValues(alpha: 0.4)),
                  ),
                  value: _isUrgent,
                  onChanged: (v) => setState(() => _isUrgent = v),
                  activeColor: Colors.redAccent,
                ),
                if (_isUrgent)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: TextField(
                      controller: _urgentChargeController,
                      textInputAction: TextInputAction.done,
                      decoration: const InputDecoration(
                        labelText: 'Urgent Charge (₹)',
                        prefixText: '₹ ',
                        isDense: true,
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ─── Payment Summary ────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: cs.primary.withValues(alpha: 0.08)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Total', style: theme.textTheme.bodySmall),
                      const SizedBox(height: 2),
                      Text(
                        '₹${total.toStringAsFixed(0)}',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: cs.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    controller: _advanceController,
                    textInputAction: TextInputAction.done,
                    decoration: const InputDecoration(
                      labelText: 'Advance (₹)',
                      prefixText: '₹ ',
                      isDense: true,
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ─── Submit ─────────────────────────────────────────────────
          SizedBox(
            height: 50,
            child: FilledButton(
              onPressed: _canSubmit ? _createOrder : null,
              child: const Text('Create Order'),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ─── Helpers ──────────────────────────────────────────────────────────

  Widget _buildImagePreview(String path, ColorScheme cs) {
    final file = File(path);
    if (file.existsSync()) {
      return GestureDetector(
        onTap: () => _showImageViewer(path),
        child: Image.file(file, fit: BoxFit.cover, width: 100, height: 100),
      );
    }
    return Icon(Icons.image,
        size: 36, color: cs.primary.withValues(alpha: 0.4));
  }

  void _showImageViewer(String path) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: Stack(
          children: [
            Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.file(File(path), fit: BoxFit.contain),
              ),
            ),
            Positioned(
              top: 0,
              right: 0,
              child: IconButton(
                onPressed: () => Navigator.pop(ctx),
                icon: const Icon(Icons.close, color: Colors.white, size: 28),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _pickReferenceImage() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Camera'),
              onTap: () async {
                Navigator.pop(ctx);
                final xFile =
                    await _imagePicker.pickImage(source: ImageSource.camera);
                if (xFile != null) {
                  setState(() => _referenceImages.add(xFile.path));
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Gallery'),
              onTap: () async {
                Navigator.pop(ctx);
                final xFile =
                    await _imagePicker.pickImage(source: ImageSource.gallery);
                if (xFile != null) {
                  setState(() => _referenceImages.add(xFile.path));
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _pickDueDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null) setState(() => _dueDate = date);
  }

  void _showAddItemSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _AddItemSheet(
        customerId: _selectedCustomer?.id,
        onAdd: (item) {
          setState(() => _items.add(item));
          Navigator.pop(ctx);
        },
      ),
    );
  }

  Widget _buildItemCard(
      int index, OrderItem item, ThemeData theme, ColorScheme cs) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: cs.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(item.type.icon, color: cs.primary, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${item.type.label} ×${item.quantity}',
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  if (item.fabricDetails != null)
                    Text(
                      item.fabricDetails!,
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: cs.onSurfaceVariant),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            Text(
              '₹${item.total.toStringAsFixed(0)}',
              style: theme.textTheme.bodyMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(width: 4),
            IconButton(
              icon: Icon(Icons.close, size: 18, color: cs.error),
              onPressed: () => setState(() => _items.removeAt(index)),
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
      ),
    );
  }

  void _createOrder() {
    HapticFeedback.mediumImpact();
    final dataService = context.read<DataService>();
    final order = dataService.addOrder(
      customer: _selectedCustomer!,
      items: _items,
      dueDate: _dueDate!,
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
      advancePaid: double.tryParse(_advanceController.text) ?? 0,
      referenceImages: _referenceImages,
      isUrgent: _isUrgent,
      urgentCharge:
          _isUrgent ? (double.tryParse(_urgentChargeController.text) ?? 0) : 0,
    );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Order ${order.orderNumber} created')),
    );
    Navigator.pop(context);
  }
}

// ─── Section Header ─────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context)
          .textTheme
          .titleMedium
          ?.copyWith(fontWeight: FontWeight.w600),
    );
  }
}

// ─── Add Item Bottom Sheet ──────────────────────────────────────────────────

class _AddItemSheet extends StatefulWidget {
  final void Function(OrderItem) onAdd;
  final String? customerId;
  const _AddItemSheet({required this.onAdd, this.customerId});

  @override
  State<_AddItemSheet> createState() => _AddItemSheetState();
}

class _AddItemSheetState extends State<_AddItemSheet> {
  late String _selectedTypeName;
  final _priceController = TextEditingController();
  final _quantityController = TextEditingController(text: '1');
  final _fabricController = TextEditingController();
  final _notesController = TextEditingController();
  final Map<String, TextEditingController> _measurementControllers = {};

  GarmentType get _selectedGarmentType {
    // Match setting name to enum, fallback to 'other'
    for (final gt in GarmentType.values) {
      if (gt.label.toLowerCase() == _selectedTypeName.toLowerCase()) return gt;
    }
    return GarmentType.other;
  }

  @override
  void initState() {
    super.initState();
    final ds = context.read<DataService>();
    _selectedTypeName = ds.garmentTypes.isNotEmpty
        ? ds.garmentTypes.first
        : GarmentType.shirt.label;
    _updateMeasurementFields();
  }

  void _updateMeasurementFields() {
    for (final c in _measurementControllers.values) {
      c.dispose();
    }
    _measurementControllers.clear();
    final ds = context.read<DataService>();
    final fields = ds.getMeasurementFields(_selectedTypeName);
    for (final field in fields) {
      _measurementControllers[field] = TextEditingController();
    }
    // Auto-fill price from garment defaults
    final defaultPrice = ds.garmentDefaults[_selectedTypeName];
    if (defaultPrice != null && _priceController.text.isEmpty) {
      _priceController.text = defaultPrice.toStringAsFixed(0);
    } else if (defaultPrice != null) {
      _priceController.text = defaultPrice.toStringAsFixed(0);
    }
    // Auto-fill from saved template if available
    _tryAutoFill();
  }

  void _tryAutoFill() {
    if (widget.customerId == null) return;
    final ds = context.read<DataService>();
    final templates = ds.getTemplates(
      customerId: widget.customerId,
      garmentType: _selectedGarmentType,
    );
    // Also check templates by name match for custom types
    var template = templates.isNotEmpty ? templates.first : null;
    if (template == null) {
      // Try matching by label stored in template
      final allTemplates = ds.getTemplates(customerId: widget.customerId);
      template = allTemplates
          .where((t) =>
              t.label.toLowerCase().contains(_selectedTypeName.toLowerCase()))
          .firstOrNull;
    }
    if (template != null) {
      final t = template;
      for (final entry in t.measurements.entries) {
        final ctrl = _measurementControllers[entry.key];
        if (ctrl != null) {
          ctrl.text = entry.value.toString();
        }
      }
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Auto-filled from "${t.label}"'),
              duration: const Duration(seconds: 2),
              action: SnackBarAction(
                label: 'Clear',
                onPressed: () {
                  for (final c in _measurementControllers.values) {
                    c.clear();
                  }
                },
              ),
            ),
          );
        }
      });
    }
  }

  @override
  void dispose() {
    _priceController.dispose();
    _quantityController.dispose();
    _fabricController.dispose();
    _notesController.dispose();
    for (final c in _measurementControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      expand: false,
      builder: (context, scrollController) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: ListView(
          controller: scrollController,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: cs.outline.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text(
              'Add Item',
              style: theme.textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // Item Type
            Text('Item Type', style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            Builder(builder: (context) {
              final garmentTypes = context.read<DataService>().garmentTypes;
              return Wrap(
                spacing: 8,
                runSpacing: 8,
                children: garmentTypes.map((typeName) {
                  final isSelected = _selectedTypeName == typeName;
                  // Try to find matching GarmentType for icon
                  final gt = GarmentType.values.where(
                    (g) => g.label.toLowerCase() == typeName.toLowerCase(),
                  );
                  final icon = gt.isNotEmpty ? gt.first.icon : Icons.category;
                  return ChoiceChip(
                    label: Text(typeName),
                    avatar: Icon(icon, size: 16),
                    selected: isSelected,
                    onSelected: (_) {
                      setState(() {
                        _selectedTypeName = typeName;
                        _updateMeasurementFields();
                      });
                    },
                  );
                }).toList(),
              );
            }),
            const SizedBox(height: 20),

            // Price & Quantity
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: _priceController,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Price (₹)',
                      prefixText: '₹ ',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 90,
                  child: TextField(
                    controller: _quantityController,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(labelText: 'Qty'),
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Measurements
            Builder(builder: (context) {
              final unit = context.read<DataService>().measurementUnit;
              final unitSuffix =
                  unit == 'inches' ? '"' : (unit == 'cm' ? 'cm' : unit);
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Measurements ($unit)',
                      style: theme.textTheme.titleSmall),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: _measurementControllers.entries
                        .map(
                          (entry) => SizedBox(
                            width: (MediaQuery.of(context).size.width - 58) / 2,
                            child: TextField(
                              controller: entry.value,
                              decoration: InputDecoration(
                                labelText: entry.key,
                                isDense: true,
                                suffixText: unitSuffix,
                              ),
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                      decimal: true),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ],
              );
            }),
            const SizedBox(height: 16),

            // Fabric Details
            TextField(
              controller: _fabricController,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Fabric Details (optional)',
                prefixIcon: Icon(Icons.texture),
              ),
            ),
            const SizedBox(height: 12),

            // Notes
            TextField(
              controller: _notesController,
              textInputAction: TextInputAction.done,
              decoration: const InputDecoration(
                labelText: 'Item Notes (optional)',
                prefixIcon: Icon(Icons.note_outlined),
              ),
            ),
            const SizedBox(height: 24),

            // Add Button
            SizedBox(
              height: 50,
              child: FilledButton.icon(
                onPressed: _addItem,
                icon: const Icon(Icons.add),
                label: const Text('Add Item'),
              ),
            ),
            SizedBox(height: MediaQuery.of(context).viewInsets.bottom + 16),
          ],
        ),
      ),
    );
  }

  void _addItem() {
    HapticFeedback.lightImpact();
    final price = double.tryParse(_priceController.text) ?? 0;
    final qty = int.tryParse(_quantityController.text) ?? 1;

    if (price <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid price')),
      );
      return;
    }

    final measurements = <String, double>{};
    for (final entry in _measurementControllers.entries) {
      final val = double.tryParse(entry.value.text);
      if (val != null && val > 0) {
        measurements[entry.key] = val;
      }
    }

    widget.onAdd(OrderItem(
      type: _selectedGarmentType,
      quantity: qty,
      price: price,
      measurements: measurements,
      fabricDetails: _fabricController.text.trim().isEmpty
          ? null
          : _fabricController.text.trim(),
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
    ));
  }
}
