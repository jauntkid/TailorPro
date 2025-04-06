import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../utils/error_handler.dart';
import '../utils/validators.dart';

class AddCustomerScreen extends StatefulWidget {
  final String? customerId;

  const AddCustomerScreen({Key? key, this.customerId}) : super(key: key);

  @override
  _AddCustomerScreenState createState() => _AddCustomerScreenState();
}

class _AddCustomerScreenState extends State<AddCustomerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _apiService = ApiService();
  bool _isLoading = false;

  // Form fields
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();
  final _referralController = TextEditingController();
  final _notesController = TextEditingController();

  bool _isEdit = false;

  @override
  void initState() {
    super.initState();
    _isEdit = widget.customerId != null;

    if (_isEdit) {
      _loadCustomerData();
    }
  }

  Future<void> _loadCustomerData() async {
    setState(() {
      _isLoading = true;
    });

    final result = await _apiService.getCustomerById(widget.customerId!);

    setState(() {
      _isLoading = false;
    });

    if (result['success']) {
      final customerData = result['data'];
      if (customerData != null) {
        _nameController.text = customerData['name'] ?? '';
        _phoneController.text = customerData['phone'] ?? '';
        _emailController.text = customerData['email'] ?? '';
        _addressController.text = customerData['address'] ?? '';
        _referralController.text = customerData['referral'] ?? '';
        _notesController.text = customerData['notes'] ?? '';
      }
    } else {
      ErrorHandler.showError(
          context, result['error'] ?? 'Failed to load customer data');
      Navigator.pop(context);
    }
  }

  Future<void> _saveCustomer() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final customerData = {
      'name': _nameController.text.trim(),
      'phone': _phoneController.text.trim(),
      'email': _emailController.text.trim().isEmpty
          ? null
          : _emailController.text.trim(),
      'address': _addressController.text.trim().isEmpty
          ? null
          : _addressController.text.trim(),
      'referral': _referralController.text.trim().isEmpty
          ? null
          : _referralController.text.trim(),
      'notes': _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
    };

    final result = _isEdit
        ? await _apiService.updateCustomer(widget.customerId!, customerData)
        : await _apiService.createCustomer(customerData);

    setState(() {
      _isLoading = false;
    });

    if (result['success']) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isEdit
              ? 'Customer updated successfully!'
              : 'Customer added successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    } else {
      ErrorHandler.showError(
          context, result['error'] ?? 'Failed to save customer');
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _referralController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit Customer' : 'Add Customer'),
      ),
      body: _isLoading && _isEdit
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Name *',
                        border: OutlineInputBorder(),
                      ),
                      validator: Validators.required('Name is required'),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _phoneController,
                      decoration: const InputDecoration(
                        labelText: 'Phone *',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.phone,
                      validator: Validators.required('Phone is required'),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: Validators.email(),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _addressController,
                      decoration: const InputDecoration(
                        labelText: 'Address',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _referralController,
                      decoration: const InputDecoration(
                          labelText: 'Referral',
                          border: OutlineInputBorder(),
                          hintText: 'How did they hear about us?'),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _notesController,
                      decoration: const InputDecoration(
                        labelText: 'Notes',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _saveCustomer,
                        child: _isLoading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : Text(
                                _isEdit ? 'Update Customer' : 'Save Customer',
                                style: const TextStyle(fontSize: 16),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
