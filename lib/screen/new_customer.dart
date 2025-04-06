import 'package:flutter/material.dart';
import '../config/theme.dart';

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

  // Image path - in a real app, this would store the actual image path
  String? _profileImagePath;

  @override
  void dispose() {
    _nameController.dispose();
    _whatsappController.dispose();
    _addressController.dispose();
    _referralController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _createCustomer() {
    // Validate form
    if (_nameController.text.isEmpty || _whatsappController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Name and WhatsApp number are required'),
          backgroundColor: AppTheme.accentColor,
        ),
      );
      return;
    }

    // In a real app, you would save the customer data here
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Customer created successfully'),
        backgroundColor: AppTheme.statusInProgress,
      ),
    );

    // Navigate back or to a customer list
    Navigator.pop(context);
  }

  void _exit() {
    Navigator.pop(context);
  }

  void _selectProfileImage() {
    // In a real app, you would implement image picker functionality
    setState(() {
      _profileImagePath = 'https://randomuser.me/api/portraits/men/32.jpg';
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Profile photo updated'),
        backgroundColor: AppTheme.statusInProgress,
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
        title: Text('New Customer', style: AppTheme.headingLarge),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppTheme.textPrimary),
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
                    // Profile photo
                    Text(
                      'Profile Photo',
                      style: AppTheme.bodySmall,
                    ),
                    SizedBox(height: AppTheme.paddingMedium),

                    _buildProfilePhotoSection(),

                    SizedBox(height: AppTheme.paddingLarge),

                    // Customer information
                    Text(
                      'Customer Information',
                      style: AppTheme.bodySmall,
                    ),
                    SizedBox(height: AppTheme.paddingMedium),

                    // Name field
                    _buildTextField(
                      controller: _nameController,
                      hintText: 'Full Name',
                      icon: Icons.person,
                    ),

                    SizedBox(height: AppTheme.paddingMedium),

                    // WhatsApp number field
                    _buildTextField(
                      controller: _whatsappController,
                      hintText: 'WhatsApp Number',
                      icon: Icons.phone,
                      keyboardType: TextInputType.phone,
                    ),

                    SizedBox(height: AppTheme.paddingMedium),

                    // Address field
                    _buildTextField(
                      controller: _addressController,
                      hintText: 'Address',
                      icon: Icons.location_on,
                      maxLines: 3,
                    ),

                    SizedBox(height: AppTheme.paddingLarge),

                    // Referral information
                    Text(
                      'Referral Information',
                      style: AppTheme.bodySmall,
                    ),
                    SizedBox(height: AppTheme.paddingMedium),

                    // Referral field
                    _buildTextField(
                      controller: _referralController,
                      hintText: 'How did they find you?',
                      icon: Icons.people,
                    ),

                    SizedBox(height: AppTheme.paddingLarge),

                    // Notes
                    Text(
                      'Notes',
                      style: AppTheme.bodySmall,
                    ),
                    SizedBox(height: AppTheme.paddingMedium),

                    // Notes field
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

            // Bottom action buttons
            _buildBottomActions(),
          ],
        ),
      ),
    );
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
              child: _profileImagePath != null
                  ? CircleAvatar(
                      radius: 58,
                      backgroundImage: NetworkImage(_profileImagePath!),
                    )
                  : Icon(
                      Icons.add_a_photo,
                      size: 40,
                      color: AppTheme.textSecondary,
                    ),
            ),
            SizedBox(height: AppTheme.paddingSmall),
            Text(
              _profileImagePath != null ? 'Change Photo' : 'Add Photo',
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
          hintStyle: TextStyle(color: const Color(0xFFADAEBC)),
          prefixIcon: Icon(icon, color: AppTheme.textSecondary),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(
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
      padding: EdgeInsets.all(AppTheme.paddingMedium),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _createCustomer,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(9999),
                ),
              ),
              child: Text(
                'Create Customer',
                style: AppTheme.bodyLarge.copyWith(color: Colors.black),
              ),
            ),
          ),
          SizedBox(height: AppTheme.paddingMedium),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton(
              onPressed: _exit,
              style: OutlinedButton.styleFrom(
                side: BorderSide(width: 1, color: Colors.white),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(9999),
                ),
              ),
              child: Text(
                'Exit',
                style: AppTheme.bodyLarge,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
