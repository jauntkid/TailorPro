import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../config/theme.dart';
import '../services/api_service.dart';

class NewCustomerScreen extends StatefulWidget {
  const NewCustomerScreen({Key? key}) : super(key: key);

  @override
  State<NewCustomerScreen> createState() => _NewCustomerScreenState();
}

class _NewCustomerScreenState extends State<NewCustomerScreen> {
  // Form controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _whatsappController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _referralController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();

  File? _profileImageFile; // Selected image file
  final ImagePicker _picker = ImagePicker();
  final ApiService _apiService = ApiService();

  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _whatsappController.dispose();
    _addressController.dispose();
    _referralController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  // Allows user to choose an image from camera or gallery
  Future<void> _selectProfileImage() async {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Gallery'),
              onTap: () async {
                Navigator.of(context).pop();
                final pickedFile =
                    await _picker.pickImage(source: ImageSource.gallery);
                if (pickedFile != null) {
                  setState(() {
                    _profileImageFile = File(pickedFile.path);
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Profile photo updated'),
                      backgroundColor: AppTheme.statusInProgress,
                    ),
                  );
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera),
              title: const Text('Camera'),
              onTap: () async {
                Navigator.of(context).pop();
                final pickedFile =
                    await _picker.pickImage(source: ImageSource.camera);
                if (pickedFile != null) {
                  setState(() {
                    _profileImageFile = File(pickedFile.path);
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Profile photo updated'),
                      backgroundColor: AppTheme.statusInProgress,
                    ),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  // Simulated method: Upload the image file to your server and return its URL.
  Future<String?> _uploadProfileImage(File imageFile) async {
    // TODO: Implement your file upload logic here.
    // For example, you might use http.MultipartRequest to upload the file.
    // Here we simulate a successful upload by returning a dummy URL.
    await Future.delayed(const Duration(seconds: 2));
    return 'https://yourserver.com/uploads/${imageFile.path.split('/').last}';
  }

  Future<void> _createCustomer() async {
    // Validate form fields
    if (_nameController.text.isEmpty || _whatsappController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Name and WhatsApp number are required'),
          backgroundColor: AppTheme.accentColor,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    String? profileImageUrl;
    if (_profileImageFile != null) {
      // Upload the image first
      profileImageUrl = await _uploadProfileImage(_profileImageFile!);
      if (profileImageUrl == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Image upload failed'),
            backgroundColor: AppTheme.accentColor,
          ),
        );
        setState(() {
          _isSubmitting = false;
        });
        return;
      }
    }

    // Build customer data payload
    final customerData = {
      'name': _nameController.text,
      'phone': _whatsappController.text,
      'address': _addressController.text,
      'referral': _referralController.text,
      'note': _noteController.text,
      'profileImage': profileImageUrl, // may be null if no image was selected
    };

    // Call API to create customer
    final result = await _apiService.createCustomer(customerData);

    setState(() {
      _isSubmitting = false;
    });

    if (result['success']) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Customer created successfully'),
          backgroundColor: AppTheme.statusInProgress,
        ),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['error'] ?? 'Failed to create customer'),
          backgroundColor: AppTheme.accentColor,
        ),
      );
    }
  }

  void _exit() {
    Navigator.pop(context);
  }

  Widget _buildProfilePhotoSection() {
    return Center(
      child: GestureDetector(
        onTap: _selectProfileImage,
        child: Column(
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: AppTheme.cardBackground,
                shape: BoxShape.circle,
                border: Border.all(
                    color: AppTheme.borderColor.withOpacity(0.3), width: 2),
              ),
              child: _profileImageFile != null
                  ? CircleAvatar(
                      radius: 58,
                      backgroundImage: FileImage(_profileImageFile!),
                    )
                  : const Icon(
                      Icons.add_a_photo,
                      size: 40,
                      color: AppTheme.textSecondary,
                    ),
            ),
            const SizedBox(height: AppTheme.paddingSmall),
            Text(
              _profileImageFile != null ? 'Change Photo' : 'Add Photo',
              style: AppTheme.bodySmall.copyWith(color: AppTheme.primary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusSmall),
      ),
      child: TextField(
        controller: controller,
        style: AppTheme.bodyRegular,
        keyboardType: keyboardType,
        maxLines: maxLines,
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: const TextStyle(color: Color(0xFFADAEBC)),
          prefixIcon: Icon(icon, color: AppTheme.textSecondary),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            vertical: 16,
            horizontal: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildBottomActions() {
    return Container(
      color: AppTheme.cardBackground,
      padding: const EdgeInsets.all(AppTheme.paddingMedium),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _createCustomer,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(9999),
                ),
              ),
              child: _isSubmitting
                  ? const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                    )
                  : Text(
                      'Create Customer',
                      style: AppTheme.bodyLarge.copyWith(color: Colors.black),
                    ),
            ),
          ),
          const SizedBox(height: AppTheme.paddingMedium),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton(
              onPressed: _exit,
              style: OutlinedButton.styleFrom(
                side: const BorderSide(width: 1, color: Colors.white),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(9999),
                ),
              ),
              child: const Text(
                'Exit',
                style: AppTheme.bodyLarge,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        elevation: 0,
        title: const Text('New Customer', style: AppTheme.headingLarge),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimary),
          onPressed: _exit,
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppTheme.paddingMedium),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Profile photo section
                    const Text(
                      'Profile Photo',
                      style: AppTheme.bodySmall,
                    ),
                    const SizedBox(height: AppTheme.paddingMedium),
                    _buildProfilePhotoSection(),
                    const SizedBox(height: AppTheme.paddingLarge),
                    // Customer Information
                    const Text(
                      'Customer Information',
                      style: AppTheme.bodySmall,
                    ),
                    const SizedBox(height: AppTheme.paddingMedium),
                    _buildTextField(
                      controller: _nameController,
                      hintText: 'Full Name',
                      icon: Icons.person,
                    ),
                    const SizedBox(height: AppTheme.paddingMedium),
                    _buildTextField(
                      controller: _whatsappController,
                      hintText: 'WhatsApp Number',
                      icon: Icons.phone,
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: AppTheme.paddingMedium),
                    _buildTextField(
                      controller: _addressController,
                      hintText: 'Address',
                      icon: Icons.location_on,
                      maxLines: 3,
                    ),
                    const SizedBox(height: AppTheme.paddingLarge),
                    const Text(
                      'Referral Information',
                      style: AppTheme.bodySmall,
                    ),
                    const SizedBox(height: AppTheme.paddingMedium),
                    _buildTextField(
                      controller: _referralController,
                      hintText: 'How did they find you?',
                      icon: Icons.people,
                    ),
                    const SizedBox(height: AppTheme.paddingLarge),
                    const Text(
                      'Notes',
                      style: AppTheme.bodySmall,
                    ),
                    const SizedBox(height: AppTheme.paddingMedium),
                    _buildTextField(
                      controller: _noteController,
                      hintText: 'Add any additional information here...',
                      icon: Icons.note,
                      maxLines: 4,
                    ),
                  ],
                ),
              ),
            ),
            _buildBottomActions(),
          ],
        ),
      ),
    );
  }
}
