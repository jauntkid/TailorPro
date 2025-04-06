import 'package:flutter/material.dart';
import '../config/theme.dart';

class CategoryModel {
  final String title;
  final List<Color> gradientColors;
  final IconData icon;
  final List<String> measurements;

  CategoryModel({
    required this.title,
    required this.gradientColors,
    required this.icon,
    required this.measurements,
  });
}

class NewOrderScreen extends StatefulWidget {
  const NewOrderScreen({Key? key}) : super(key: key);

  @override
  State<NewOrderScreen> createState() => _NewOrderScreenState();
}

class _NewOrderScreenState extends State<NewOrderScreen> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  DateTime? _selectedDate;
  String _priority = 'High';
  CategoryModel? _selectedCategory;

  // Measurement controllers
  final Map<String, TextEditingController> _measurementControllers = {};

  final List<CategoryModel> _categories = [
    CategoryModel(
      title: 'Suits & Blazers',
      gradientColors: [const Color(0xFFEA580C), const Color(0xFFDC2626)],
      icon: Icons.business,
      measurements: [
        'Chest',
        'Waist',
        'Shoulder',
        'Length',
        'Arm Length',
        'Neck'
      ],
    ),
    CategoryModel(
      title: 'Shirts & Pants',
      gradientColors: [const Color(0xFF2563EB), const Color(0xFF4F46E5)],
      icon: Icons.dry_cleaning,
      measurements: [
        'Chest',
        'Waist',
        'Hip',
        'Inseam',
        'Shoulder',
        'Sleeve Length'
      ],
    ),
    CategoryModel(
      title: 'Traditional Wear',
      gradientColors: [const Color(0xFF059669), const Color(0xFF0D9488)],
      icon: Icons.accessibility_new,
      measurements: [
        'Chest',
        'Waist',
        'Shoulder',
        'Length',
        'Sleeve',
        'Collar'
      ],
    ),
  ];

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _notesController.dispose();
    _measurementControllers.forEach((_, controller) => controller.dispose());
    super.dispose();
  }

  void _initializeMeasurementControllers(List<String> measurements) {
    // Clear old controllers
    _measurementControllers.forEach((_, controller) => controller.dispose());
    _measurementControllers.clear();

    // Create new controllers for selected category
    for (var measurement in measurements) {
      _measurementControllers[measurement] = TextEditingController();
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(DateTime.now().year + 2),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: AppTheme.primary,
              onPrimary: Colors.white,
              surface: AppTheme.cardBackground,
              onSurface: AppTheme.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _generateBill() {
    // Navigate to bill screen
    Navigator.pushNamed(context, '/bill');
  }

  void _exit() {
    Navigator.pop(context);
  }

  void _selectCategory(CategoryModel category) {
    setState(() {
      _selectedCategory = category;
      _initializeMeasurementControllers(category.measurements);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text('New Order', style: AppTheme.headingLarge),
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
                    // Search customer
                    _buildSearchBar(),

                    SizedBox(height: AppTheme.paddingLarge),

                    // Categories
                    Text(
                      'Select Category',
                      style: AppTheme.bodySmall,
                    ),
                    SizedBox(height: AppTheme.paddingMedium),

                    // Category cards
                    ..._categories
                        .map((category) => _buildCategoryCard(category)),

                    // Measurements (only show if category is selected)
                    if (_selectedCategory != null) ...[
                      SizedBox(height: AppTheme.paddingLarge),
                      Text(
                        'Measurements',
                        style: AppTheme.bodySmall,
                      ),
                      SizedBox(height: AppTheme.paddingMedium),
                      _buildMeasurementsGrid(),

                      SizedBox(height: AppTheme.paddingLarge),

                      // Deadline selector
                      Text(
                        'Deadline',
                        style: AppTheme.bodySmall,
                      ),
                      SizedBox(height: AppTheme.paddingMedium),
                      _buildDatePicker(),

                      SizedBox(height: AppTheme.paddingLarge),

                      // Priority selector
                      Text(
                        'Priority',
                        style: AppTheme.bodySmall,
                      ),
                      SizedBox(height: AppTheme.paddingMedium),
                      _buildPrioritySelector(),

                      SizedBox(height: AppTheme.paddingLarge),

                      // Notes
                      Text(
                        'Notes',
                        style: AppTheme.bodySmall,
                      ),
                      SizedBox(height: AppTheme.paddingMedium),
                      _buildNotesField(),

                      SizedBox(height: AppTheme.paddingLarge),

                      // Photos
                      Text(
                        'Photos',
                        style: AppTheme.bodySmall,
                      ),
                      SizedBox(height: AppTheme.paddingMedium),
                      _buildPhotoUpload(),
                    ],
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

  Widget _buildSearchBar() {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
      ),
      child: TextField(
        controller: _searchController,
        style: AppTheme.bodyRegular,
        decoration: InputDecoration(
          hintText: 'Search customer',
          hintStyle: TextStyle(color: const Color(0xFFADAEBC)),
          prefixIcon: Icon(Icons.search, color: AppTheme.textSecondary),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(
            vertical: 16,
            horizontal: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryCard(CategoryModel category) {
    final bool isSelected = _selectedCategory?.title == category.title;

    return GestureDetector(
      onTap: () => _selectCategory(category),
      child: Container(
        margin: EdgeInsets.only(bottom: AppTheme.paddingMedium),
        height: 56,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: isSelected
                ? [category.gradientColors[0], category.gradientColors[1]]
                : [
                    category.gradientColors[0].withOpacity(0.7),
                    category.gradientColors[1].withOpacity(0.7)
                  ],
          ),
          borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: category.gradientColors[1].withOpacity(0.5),
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  )
                ]
              : [],
        ),
        child: Row(
          children: [
            SizedBox(width: AppTheme.paddingMedium),
            Icon(
              category.icon,
              color: Colors.white,
              size: 24,
            ),
            SizedBox(width: AppTheme.paddingMedium),
            Text(
              category.title,
              style: AppTheme.bodyLarge,
            ),
            Spacer(),
            Icon(
              isSelected ? Icons.check_circle : Icons.arrow_forward_ios,
              color: Colors.white,
              size: 18,
            ),
            SizedBox(width: AppTheme.paddingMedium),
          ],
        ),
      ),
    );
  }

  Widget _buildMeasurementsGrid() {
    if (_selectedCategory == null) return SizedBox.shrink();

    return GridView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 173 / 48,
        crossAxisSpacing: AppTheme.paddingMedium,
        mainAxisSpacing: AppTheme.paddingMedium,
      ),
      itemCount: _selectedCategory!.measurements.length,
      itemBuilder: (context, index) {
        final measurement = _selectedCategory!.measurements[index];
        final controller = _measurementControllers[measurement]!;

        return Container(
          decoration: BoxDecoration(
            color: AppTheme.cardBackground,
            borderRadius: BorderRadius.circular(AppTheme.borderRadiusSmall),
          ),
          child: TextField(
            controller: controller,
            style: AppTheme.bodyRegular,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              hintText: measurement,
              hintStyle: TextStyle(color: const Color(0xFFADAEBC)),
              border: InputBorder.none,
              contentPadding: EdgeInsets.only(left: 12),
              suffixText: 'in',
              suffixStyle: TextStyle(color: AppTheme.textSecondary),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDatePicker() {
    return InkWell(
      onTap: () => _selectDate(context),
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: AppTheme.cardBackground,
          borderRadius: BorderRadius.circular(AppTheme.borderRadiusSmall),
        ),
        padding: EdgeInsets.symmetric(horizontal: AppTheme.paddingMedium),
        child: Row(
          children: [
            Text(
              _selectedDate == null
                  ? 'mm/dd/yyyy'
                  : '${_selectedDate!.month}/${_selectedDate!.day}/${_selectedDate!.year}',
              style: _selectedDate == null
                  ? AppTheme.bodyRegular
                      .copyWith(color: const Color(0xFFADAEBC))
                  : AppTheme.bodyRegular,
            ),
            Spacer(),
            Icon(
              Icons.calendar_today_outlined,
              color: AppTheme.textSecondary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrioritySelector() {
    return Row(
      children: [
        _buildPriorityButton('High', const Color(0xFFDC2626)),
        SizedBox(width: AppTheme.paddingMedium),
        _buildPriorityButton('Medium', AppTheme.cardBackground),
        SizedBox(width: AppTheme.paddingMedium),
        _buildPriorityButton('Low', AppTheme.cardBackground),
      ],
    );
  }

  Widget _buildPriorityButton(String priority, Color backgroundColor) {
    final bool isSelected = _priority == priority;

    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            _priority = priority;
          });
        },
        child: Container(
          height: 40,
          decoration: BoxDecoration(
            color: isSelected
                ? (priority == 'High'
                    ? const Color(0xFFDC2626)
                    : (priority == 'Medium'
                        ? const Color(0xFFF59E0B)
                        : const Color(0xFF059669)))
                : AppTheme.cardBackground,
            borderRadius: BorderRadius.circular(AppTheme.borderRadiusSmall),
          ),
          alignment: Alignment.center,
          child: Text(
            priority,
            style: AppTheme.bodyRegular.copyWith(
              fontWeight: isSelected ? FontWeight.w500 : FontWeight.w400,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNotesField() {
    return Container(
      height: 96,
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusSmall),
      ),
      child: TextField(
        controller: _notesController,
        maxLines: 4,
        style: AppTheme.bodyRegular,
        decoration: InputDecoration(
          hintText: 'Add special instructions...',
          hintStyle: TextStyle(color: const Color(0xFFADAEBC)),
          border: InputBorder.none,
          contentPadding: EdgeInsets.all(AppTheme.paddingMedium),
        ),
      ),
    );
  }

  Widget _buildPhotoUpload() {
    return Container(
      height: 88,
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusSmall),
        border: Border.all(
          width: 2,
          color: const Color(0xFF374151),
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_a_photo_outlined,
              color: AppTheme.textSecondary,
              size: 24,
            ),
            SizedBox(height: AppTheme.paddingSmall),
            Text(
              'Add photos',
              style: AppTheme.bodySmall,
            ),
          ],
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
              onPressed: _selectedCategory == null ? null : _generateBill,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(9999),
                ),
                disabledBackgroundColor: Colors.grey.shade300,
                disabledForegroundColor: Colors.grey.shade700,
              ),
              child: Text(
                'Generate Bill',
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
