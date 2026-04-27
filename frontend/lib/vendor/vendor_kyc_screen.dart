import 'package:flutter/material.dart';
import 'vendor_api_service.dart';

class VendorKycScreen extends StatefulWidget {
  const VendorKycScreen({super.key});

  @override
  State<VendorKycScreen> createState() => _VendorKycScreenState();
}

class _VendorKycScreenState extends State<VendorKycScreen> {
  List<dynamic> _kycList = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchPendingKyc();
  }

  Future<void> _fetchPendingKyc() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final list = await VendorApiService.getPendingKyc();
      if (mounted) {
        setState(() {
          _kycList = list;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _approveKyc(int kycId) async {
    try {
      await VendorApiService.approveKyc(kycId);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Document approved!'), backgroundColor: Colors.green),
      );
      _fetchPendingKyc();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _rejectKyc(int kycId, String reason) async {
    try {
      await VendorApiService.rejectKyc(kycId, reason: reason);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Document rejected.'), backgroundColor: Colors.orange),
      );
      _fetchPendingKyc();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  void _showRejectDialog(int kycId) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reject Document'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Reason for rejection',
            hintText: 'e.g. Image is blurry',
            border: OutlineInputBorder(),
          ),
          maxLines: 2,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final reason = controller.text.trim();
              if (reason.isEmpty) return;
              Navigator.pop(ctx);
              _rejectKyc(kycId, reason);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
  }

  void _showImageDialog(String url) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        child: Stack(
          children: [
            InteractiveViewer(
              child: Image.network(url, fit: BoxFit.contain),
            ),
            Positioned(
              right: 8,
              top: 8,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.black, size: 30),
                onPressed: () => Navigator.pop(ctx),
                style: IconButton.styleFrom(backgroundColor: Colors.white70),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pending KYC Approvals'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchPendingKyc,
          )
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Error: $_error', style: const TextStyle(color: Colors.red)),
            ElevatedButton(onPressed: _fetchPendingKyc, child: const Text('Retry')),
          ],
        ),
      );
    }
    if (_kycList.isEmpty) {
      return const Center(
        child: Text('No pending KYC submissions.', style: TextStyle(fontSize: 16)),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _kycList.length,
      itemBuilder: (context, index) {
        final kyc = _kycList[index];
        final String imageUrl = kyc['license_image'] ?? '';
        
        return Card(
          elevation: 3,
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('User: ${kyc['user_name']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          Text('Email: ${kyc['user_email']}', style: TextStyle(color: Colors.grey[600])),
                          const SizedBox(height: 8),
                          Text('Bike: ${kyc['bike_model']}', style: const TextStyle(fontWeight: FontWeight.w500)),
                          Text('Submitted: ${kyc['created_at'].toString().substring(0, 10)}', style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                        ],
                      ),
                    ),
                    if (imageUrl.isNotEmpty)
                      GestureDetector(
                        onTap: () => _showImageDialog(imageUrl),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            imageUrl,
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                          ),
                        ),
                      )
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.close, color: Colors.red),
                        label: const Text('Reject', style: TextStyle(color: Colors.red)),
                        style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.red)),
                        onPressed: () => _showRejectDialog(kyc['kyc_id']),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.check),
                        label: const Text('Approve'),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                        onPressed: () => _approveKyc(kyc['kyc_id']),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
