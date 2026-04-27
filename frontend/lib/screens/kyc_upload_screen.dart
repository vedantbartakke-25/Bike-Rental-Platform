import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/api_service.dart';

class KycUploadScreen extends StatefulWidget {
  const KycUploadScreen({super.key});

  @override
  State<KycUploadScreen> createState() => _KycUploadScreenState();
}

enum KycState { none, uploading, pending, approved, rejected }

class _KycUploadScreenState extends State<KycUploadScreen> {
  late Map<String, dynamic> _bike;

  KycState _kycState = KycState.none;
  Uint8List? _imageBytes;
  String? _fileName;
  String? _error;
  String? _rejectReason;

  final ImagePicker _picker = ImagePicker();
  Timer? _pollingTimer;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _bike = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    _checkInitialStatus();
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  Future<void> _checkInitialStatus() async {
    await _fetchStatus();
  }

  Future<void> _fetchStatus() async {
    try {
      final data = await ApiService.getKycStatus(_bike['bike_id']);
      final statusStr = data['status'] as String?;
      
      if (!mounted) return;

      setState(() {
        if (statusStr == 'pending') {
          _kycState = KycState.pending;
          _startPolling();
        } else if (statusStr == 'approved') {
          _kycState = KycState.approved;
          _stopPolling();
          _onApproved();
        } else if (statusStr == 'rejected') {
          _kycState = KycState.rejected;
          _rejectReason = data['reject_reason'];
          _stopPolling();
        } else {
          _kycState = KycState.none;
          _stopPolling();
        }
      });
    } catch (e) {
      if (mounted) setState(() => _error = 'Failed to fetch status: $e');
    }
  }

  void _startPolling() {
    if (_pollingTimer != null && _pollingTimer!.isActive) return;
    _pollingTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _fetchStatus();
    });
  }

  void _stopPolling() {
    _pollingTimer?.cancel();
  }

  void _onApproved() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('License approved! You are now verified ✅'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) Navigator.of(context).pop(true);
    });
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? picked = await _picker.pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 1200,
      );
      if (picked == null) return;
      final bytes = await picked.readAsBytes();
      setState(() {
        _imageBytes = bytes;
        _fileName = picked.name;
        _error = null;
      });
    } catch (e) {
      setState(() => _error = 'Failed to pick image: $e');
    }
  }

  Future<void> _uploadLicense() async {
    if (_imageBytes == null || _fileName == null) {
      setState(() => _error = 'Please select an image first.');
      return;
    }
    setState(() {
      _kycState = KycState.uploading;
      _error = null;
    });

    try {
      await ApiService.uploadLicense(_imageBytes!, _fileName!, _bike['bike_id']);
      if (mounted) {
        setState(() {
          _kycState = KycState.pending;
          _startPolling();
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceAll('Exception: ', '');
          _kycState = KycState.none;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vendor Approval Required'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.badge_outlined, size: 64, color: Color(0xFF1565C0)),
            const SizedBox(height: 12),
            const Text(
              'KYC Verification for Booking',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Upload your driving license for vendor approval before booking ${_bike['model']}.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            const SizedBox(height: 32),

            _buildContent(),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_kycState == KycState.pending) {
      return Column(
        children: [
          const SizedBox(
            width: 60, height: 60,
            child: CircularProgressIndicator(strokeWidth: 4),
          ),
          const SizedBox(height: 24),
          const Text(
            'Waiting for Vendor Approval...',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'The vendor is reviewing your document.\nThis screen will update automatically.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      );
    }

    if (_kycState == KycState.approved) {
      return Column(
        children: [
          const Icon(Icons.check_circle, size: 80, color: Colors.green),
          const SizedBox(height: 24),
          const Text(
            'Approved!',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.green),
          ),
          const SizedBox(height: 8),
          Text(
            'Taking you back to the booking screen...',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      );
    }

    return Column(
      children: [
        if (_kycState == KycState.rejected) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.red.shade200),
            ),
            child: Column(
              children: [
                const Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Document Rejected', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  _rejectReason ?? 'Please upload a clearer image of your driving license.',
                  style: const TextStyle(color: Colors.red),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],

        GestureDetector(
          onTap: () => _kycState == KycState.uploading ? null : _showSourceSheet(context),
          child: Container(
            height: 220,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _imageBytes != null ? const Color(0xFF1565C0) : Colors.grey.shade300,
                width: 2,
              ),
            ),
            child: _imageBytes != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.memory(_imageBytes!, fit: BoxFit.cover),
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_photo_alternate_outlined, size: 52, color: Colors.grey[400]),
                      const SizedBox(height: 10),
                      Text('Tap to select image', style: TextStyle(color: Colors.grey[500])),
                    ],
                  ),
          ),
        ),
        const SizedBox(height: 16),

        OutlinedButton.icon(
          icon: const Icon(Icons.photo_library_outlined),
          label: Text(_imageBytes == null ? 'Choose Image' : 'Change Image'),
          onPressed: _kycState == KycState.uploading ? null : () => _showSourceSheet(context),
        ),
        const SizedBox(height: 12),

        if (_error != null) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.red.shade200),
            ),
            child: Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 13)),
          ),
          const SizedBox(height: 12),
        ],

        ElevatedButton.icon(
          icon: _kycState == KycState.uploading
              ? const SizedBox(
                  width: 20, height: 20,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                )
              : const Icon(Icons.cloud_upload_outlined),
          label: Text(
            _kycState == KycState.uploading ? 'Uploading...' : 'Upload for Approval',
            style: const TextStyle(fontSize: 16),
          ),
          onPressed: _kycState == KycState.uploading ? null : _uploadLicense,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            minimumSize: const Size(double.infinity, 50),
          ),
        ),
        const SizedBox(height: 16),

        Row(
          children: [
            Icon(Icons.lock_outline, size: 14, color: Colors.grey[500]),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                'Your license is stored securely and only used for identity verification.',
                style: TextStyle(fontSize: 12, color: Colors.grey[500]),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _showSourceSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Choose from Gallery'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Take a Photo'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
