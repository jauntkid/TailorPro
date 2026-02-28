import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/order.dart';
import '../../services/data_service.dart';

class EditOrderScreen extends StatefulWidget {
  final String orderId;
  const EditOrderScreen({super.key, required this.orderId});

  @override
  State<EditOrderScreen> createState() => _EditOrderScreenState();
}

class _EditOrderScreenState extends State<EditOrderScreen> {
  late List<OrderItem> _items;
  late List<String> _referenceImages;
  late DateTime _dueDate;
  late TextEditingController _notesController;
  late TextEditingController _advanceController;
  final _imagePicker = ImagePicker();
  bool _isInitialized = false;

  void _initFromOrder(Order order) {
    if (_isInitialized) return;
    _items = List.from(order.items);
    _referenceImages = List.from(order.referenceImages);
    _dueDate = order.dueDate;
    _notesController = TextEditingController(text: order.notes ?? '');
    _advanceController =
        TextEditingController(text: order.advancePaid.toStringAsFixed(0));
    _isInitialized = true;
  }

  @override
  void dispose() {
    if (_isInitialized) {
      _notesController.dispose();
      _advanceController.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ds = context.watch<DataService>();
    final order = ds.getOrderById(widget.orderId);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    if (order == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Edit Order')),
        body: const Center(child: Text('Order not found')),
      );
    }

    _initFromOrder(order);
    final total = _items.fold(0.0, (sum, item) => sum + item.total);

    return Scaffold(
      appBar: AppBar(
        title: Text('Edit ${order.orderNumber}'),
        actions: [
          TextButton(
            onPressed: () => _save(order),
            child: const Text('Save'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Customer (read-only)
          Card(
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: cs.primaryContainer,
                child: Text(
                  order.customer.name[0],
                  style: TextStyle(
                    color: cs.onPrimaryContainer,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              title: Text(order.customer.name),
              subtitle: Text(order.customer.phone),
              trailing: Icon(Icons.lock_outline,
                  size: 16, color: cs.onSurfaceVariant),
            ),
          ),
          const SizedBox(height: 16),

          // Items
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Items',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w600)),
              FilledButton.tonalIcon(
                onPressed: _showAddItemSheet,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ..._items
              .asMap()
              .entries
              .map((e) => _buildItemCard(e.key, e.value, theme, cs)),
          const SizedBox(height: 16),

          // Due Date
          Text('Due Date',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          InkWell(
            onTap: _pickDueDate,
            borderRadius: BorderRadius.circular(12),
            child: InputDecorator(
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.calendar_today),
              ),
              child: Text(
                DateFormat('EEEE, MMM d, yyyy').format(_dueDate),
                style: theme.textTheme.bodyLarge,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Reference Images
          Text('Reference Images',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w600)),
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
                                    color: cs.primary.withValues(alpha: 0.15)),
                              ),
                              child: Icon(Icons.image,
                                  size: 36,
                                  color: cs.primary.withValues(alpha: 0.4)),
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
                                      color: cs.error, shape: BoxShape.circle),
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
                      border:
                          Border.all(color: cs.outline.withValues(alpha: 0.15)),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_a_photo_outlined,
                            size: 24,
                            color: cs.onSurface.withValues(alpha: 0.4)),
                        const SizedBox(height: 4),
                        Text('Add',
                            style: theme.textTheme.bodySmall?.copyWith(
                                color: cs.onSurface.withValues(alpha: 0.4))),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Notes
          TextField(
            controller: _notesController,
            decoration: const InputDecoration(
                labelText: 'Notes', prefixIcon: Icon(Icons.note_outlined)),
            maxLines: 2,
          ),
          const SizedBox(height: 20),

          // Payment Summary
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
                            fontWeight: FontWeight.bold, color: cs.primary),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    controller: _advanceController,
                    decoration: const InputDecoration(
                        labelText: 'Advance (₹)',
                        prefixText: '₹ ',
                        isDense: true),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          SizedBox(
            height: 52,
            child: FilledButton.icon(
              onPressed: () => _save(order),
              icon: const Icon(Icons.save_rounded),
              label: const Text('Save Changes'),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  void _save(Order order) {
    final ds = context.read<DataService>();
    ds.updateOrder(
      widget.orderId,
      items: _items,
      dueDate: _dueDate,
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
      advancePaid:
          double.tryParse(_advanceController.text) ?? order.advancePaid,
      referenceImages: _referenceImages,
    );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${order.orderNumber} updated')),
    );
    Navigator.pop(context);
  }

  void _pickDueDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _dueDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null) setState(() => _dueDate = date);
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
                if (xFile != null)
                  setState(() => _referenceImages.add(xFile.path));
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Gallery'),
              onTap: () async {
                Navigator.pop(ctx);
                final xFile =
                    await _imagePicker.pickImage(source: ImageSource.gallery);
                if (xFile != null)
                  setState(() => _referenceImages.add(xFile.path));
              },
            ),
          ],
        ),
      ),
    );
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
            Text('₹${item.total.toStringAsFixed(0)}',
                style: theme.textTheme.bodyMedium
                    ?.copyWith(fontWeight: FontWeight.w600)),
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
}

// ─── Add Item Sheet (reused from create order) ────────────────────────────────

class _AddItemSheet extends StatefulWidget {
  final void Function(OrderItem) onAdd;
  const _AddItemSheet({required this.onAdd});

  @override
  State<_AddItemSheet> createState() => _AddItemSheetState();
}

class _AddItemSheetState extends State<_AddItemSheet> {
  GarmentType _selectedType = GarmentType.shirt;
  final _priceController = TextEditingController();
  final _quantityController = TextEditingController(text: '1');
  final _fabricController = TextEditingController();
  final _notesController = TextEditingController();
  final Map<String, TextEditingController> _measurementControllers = {};

  @override
  void initState() {
    super.initState();
    _updateMeasurementFields();
  }

  void _updateMeasurementFields() {
    for (final c in _measurementControllers.values) {
      c.dispose();
    }
    _measurementControllers.clear();
    for (final field in _selectedType.defaultMeasurements) {
      _measurementControllers[field] = TextEditingController();
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
            Text('Add Item',
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Text('Item Type', style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: GarmentType.values.map((type) {
                final isSelected = _selectedType == type;
                return ChoiceChip(
                  label: Text(type.label),
                  avatar: Icon(type.icon, size: 16),
                  selected: isSelected,
                  onSelected: (_) {
                    setState(() {
                      _selectedType = type;
                      _updateMeasurementFields();
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: _priceController,
                    decoration: const InputDecoration(
                        labelText: 'Price (₹)', prefixText: '₹ '),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 90,
                  child: TextField(
                    controller: _quantityController,
                    decoration: const InputDecoration(labelText: 'Qty'),
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text('Measurements (inches)', style: theme.textTheme.titleSmall),
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
                            suffixText: '"'),
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                      ),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _fabricController,
              decoration: const InputDecoration(
                  labelText: 'Fabric Details (optional)',
                  prefixIcon: Icon(Icons.texture)),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _notesController,
              decoration: const InputDecoration(
                  labelText: 'Item Notes (optional)',
                  prefixIcon: Icon(Icons.note_outlined)),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 50,
              child: FilledButton.icon(
                onPressed: _addItem,
                icon: const Icon(Icons.add),
                label: const Text('Add Item'),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _addItem() {
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
      type: _selectedType,
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
