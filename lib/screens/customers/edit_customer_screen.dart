import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/customer.dart';
import '../../services/data_service.dart';

class EditCustomerScreen extends StatefulWidget {
  final String customerId;
  const EditCustomerScreen({super.key, required this.customerId});

  @override
  State<EditCustomerScreen> createState() => _EditCustomerScreenState();
}

class _EditCustomerScreenState extends State<EditCustomerScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _addressController;
  late TextEditingController _notesController;
  bool _isInitialized = false;

  void _initFromCustomer(Customer customer) {
    if (_isInitialized) return;
    _nameController = TextEditingController(text: customer.name);
    _phoneController = TextEditingController(text: customer.phone);
    _emailController = TextEditingController(text: customer.email ?? '');
    _addressController = TextEditingController(text: customer.address ?? '');
    _notesController = TextEditingController(text: customer.notes ?? '');
    _isInitialized = true;
  }

  @override
  void dispose() {
    if (_isInitialized) {
      _nameController.dispose();
      _phoneController.dispose();
      _emailController.dispose();
      _addressController.dispose();
      _notesController.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ds = context.watch<DataService>();
    final customer = ds.getCustomerById(widget.customerId);

    if (customer == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Edit Customer')),
        body: const Center(child: Text('Customer not found')),
      );
    }

    _initFromCustomer(customer);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Customer'),
        actions: [
          TextButton(
            onPressed: () => _save(customer),
            child: const Text('Save'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Avatar
            Center(
              child: CircleAvatar(
                radius: 40,
                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                child: Text(
                  customer.name[0].toUpperCase(),
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Full Name *',
                prefixIcon: Icon(Icons.person_outline),
              ),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Name is required' : null,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _phoneController,
              decoration: const InputDecoration(
                labelText: 'Phone Number *',
                prefixIcon: Icon(Icons.phone_outlined),
              ),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Phone is required' : null,
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email (optional)',
                prefixIcon: Icon(Icons.email_outlined),
              ),
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _addressController,
              decoration: const InputDecoration(
                labelText: 'Address (optional)',
                prefixIcon: Icon(Icons.location_on_outlined),
              ),
              maxLines: 2,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Notes (optional)',
                prefixIcon: Icon(Icons.note_outlined),
              ),
              maxLines: 2,
              textInputAction: TextInputAction.done,
            ),
            const SizedBox(height: 28),
            SizedBox(
              height: 52,
              child: FilledButton.icon(
                onPressed: () => _save(customer),
                icon: const Icon(Icons.save_rounded),
                label: const Text('Save Changes'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _save(Customer customer) {
    if (!_formKey.currentState!.validate()) return;

    final ds = context.read<DataService>();
    ds.updateCustomer(customer.copyWith(
      name: _nameController.text.trim(),
      phone: _phoneController.text.trim(),
      email: _emailController.text.trim().isEmpty
          ? null
          : _emailController.text.trim(),
      address: _addressController.text.trim().isEmpty
          ? null
          : _addressController.text.trim(),
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
    ));

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${_nameController.text.trim()} updated')),
    );
    Navigator.pop(context);
  }
}
