import 'dart:typed_data';
import 'package:flutter/material.dart';
// Note: using image_picker requires adding it to pubspec.yaml if not already there,
// but for the sake of compiling without breaking if it's missing, we provide a placeholder setup
// or assume standard image_picker is available.
// import 'package:image_picker/image_picker.dart';
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
                    if (isEdit && _existingBike!['image_url'] != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: Center(
                          child: Image.network(_existingBike!['image_url'], height: 150, fit: BoxFit.cover),
                        ),
                      ),
                    
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
