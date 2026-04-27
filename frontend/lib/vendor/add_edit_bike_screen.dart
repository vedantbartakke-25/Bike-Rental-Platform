import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'vendor_api_service.dart';

class AddEditBikeScreen extends StatefulWidget {
  const AddEditBikeScreen({super.key});

  @override
  State<AddEditBikeScreen> createState() => _AddEditBikeScreenState();
}

class _AddEditBikeScreenState extends State<AddEditBikeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _modelController = TextEditingController();
  final _engineCcController = TextEditingController();
  final _pricePerHourController = TextEditingController();
  final _pricePerDayController = TextEditingController();
  final _locationController = TextEditingController();
  String _bikeType = 'scooter';
  
  Map<String, dynamic>? _existingBike;
  bool _isInit = false;
  bool _isLoading = false;

  final ImagePicker _picker = ImagePicker();
  Uint8List? _selectedImageBytes;
  String? _selectedImageName;

  Future<void> _handleImageSelection(ImageSource source) async {
    try {
      final XFile? picked = await _picker.pickImage(source: source, imageQuality: 80);
      if (picked == null) return;
      
      final bytes = await picked.readAsBytes();
      setState(() {
        _selectedImageBytes = bytes;
        _selectedImageName = picked.name;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to pick image: $e')));
    }
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Photo Gallery'),
              onTap: () {
                Navigator.pop(context);
                _handleImageSelection(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Camera'),
              onTap: () {
                Navigator.pop(context);
                _handleImageSelection(ImageSource.camera);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInit) {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args != null) {
        _existingBike = args;
        _modelController.text = args['model']?.toString() ?? '';
        _engineCcController.text = args['engine_cc']?.toString() ?? '';
        _pricePerHourController.text = args['price_per_hour']?.toString() ?? '';
        _pricePerDayController.text = args['price_per_day']?.toString() ?? '';
        _locationController.text = args['location']?.toString() ?? '';
        _bikeType = args['bike_type'] ?? 'scooter';
      }
      _isInit = true;
    }
  }

  Future<void> _saveBike() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      if (_existingBike != null) {
        // Edit mode
        await VendorApiService.updateBike(
          _existingBike!['bike_id'],
          model: _modelController.text.trim(),
          engineCc: int.tryParse(_engineCcController.text) ?? 100,
          pricePerHour: double.tryParse(_pricePerHourController.text) ?? 0.0,
          pricePerDay: double.tryParse(_pricePerDayController.text) ?? 0.0,
          location: _locationController.text.trim(),
          bikeType: _bikeType,
          imageBytes: _selectedImageBytes,
          imageFileName: _selectedImageName,
        );
      } else {
        // Add mode
        await VendorApiService.addBike(
          model: _modelController.text.trim(),
          engineCc: int.tryParse(_engineCcController.text) ?? 100,
          pricePerHour: double.tryParse(_pricePerHourController.text) ?? 0.0,
          pricePerDay: double.tryParse(_pricePerDayController.text) ?? 0.0,
          location: _locationController.text.trim(),
          bikeType: _bikeType,
          imageBytes: _selectedImageBytes,
          imageFileName: _selectedImageName,
        );
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bike saved successfully!'), backgroundColor: Colors.green),
      );
      Navigator.pop(context, true); // true indicates a refresh is needed
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = _existingBike != null;
    return Scaffold(
      appBar: AppBar(title: Text(isEdit ? 'Edit Bike' : 'Add New Bike')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    GestureDetector(
                      onTap: _showImageSourceDialog,
                      child: Container(
                        height: 180,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade400),
                        ),
                        child: _selectedImageBytes != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.memory(_selectedImageBytes!, fit: BoxFit.cover),
                              )
                            : (isEdit && _existingBike!['image_url'] != null)
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.network(_existingBike!['image_url'], fit: BoxFit.cover),
                                  )
                                : Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.add_a_photo, size: 40, color: Colors.grey.shade600),
                                      const SizedBox(height: 8),
                                      Text('Tap to add bike photo', style: TextStyle(color: Colors.grey.shade600)),
                                    ],
                                  ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    TextFormField(
                      controller: _modelController,
                      decoration: const InputDecoration(labelText: 'Bike Model (e.g., Honda Activa)'),
                      validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _engineCcController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: 'Engine CC (e.g., 110)'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _bikeType,
                            decoration: const InputDecoration(labelText: 'Type'),
                            items: const [
                              DropdownMenuItem(value: 'scooter', child: Text('Scooter')),
                              DropdownMenuItem(value: 'commuter', child: Text('Commuter')),
                              DropdownMenuItem(value: 'sports', child: Text('Sports')),
                              DropdownMenuItem(value: 'cruiser', child: Text('Cruiser')),
                            ],
                            onChanged: (val) {
                              if (val != null) setState(() => _bikeType = val);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _pricePerHourController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: 'Price / Hr (₹)'),
                            validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _pricePerDayController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: 'Price / Day (₹)'),
                            validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _locationController,
                      decoration: const InputDecoration(labelText: 'Location / Area'),
                      validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: _saveBike,
                      child: Text(isEdit ? 'Save Changes' : 'Add Bike', style: const TextStyle(fontSize: 16)),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
