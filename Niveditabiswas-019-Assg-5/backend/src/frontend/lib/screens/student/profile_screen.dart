import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import '../../services/auth_provider.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isUploading = false;

  Future<void> _pickAndUploadProfilePic() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        withData: true,
      );

      if (result != null && result.files.single.bytes != null) {
        final file = result.files.single;
        setState(() => _isUploading = true);

        final api = Provider.of<ApiService>(context, listen: false);
        final photoUrl = await api.uploadProfilePicture(file.bytes!, file.name);

        if (mounted) {
          final auth = Provider.of<AuthProvider>(context, listen: false);
          auth.updateProfilePhoto(photoUrl);

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('🎉 Profile photo successfully uploaded to Cloudinary!'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final user = auth.user;

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 520),
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.slate200),
              boxShadow: const [
                BoxShadow(color: Color(0x0A0F172A), blurRadius: 20, offset: Offset(0, 8)),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('My Student Profile', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.slate900)),
                const SizedBox(height: 4),
                const Text('Manage your account details and Cloudinary avatar.', style: TextStyle(fontSize: 13, color: AppColors.slate500)),
                const SizedBox(height: 28),

                // Avatar with Cloudinary badge
                Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    CircleAvatar(
                      radius: 54,
                      backgroundColor: AppColors.primaryLight,
                      backgroundImage: user?.photoUrl.isNotEmpty == true ? NetworkImage(user!.photoUrl) : null,
                      child: user?.photoUrl.isEmpty == true
                          ? Text(
                              user?.name.isNotEmpty == true ? user!.name[0].toUpperCase() : 'S',
                              style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: AppColors.primary),
                            )
                          : null,
                    ),
                    InkWell(
                      onTap: _isUploading ? null : _pickAndUploadProfilePic,
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: _isUploading
                            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Icon(Icons.camera_alt, color: Colors.white, size: 16),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _isUploading ? null : _pickAndUploadProfilePic,
                  icon: const Icon(Icons.cloud_upload_outlined, size: 16),
                  label: const Text('Upload Photo to Cloudinary', style: TextStyle(fontSize: 13)),
                ),
                const SizedBox(height: 24),
                const Divider(color: AppColors.slate200),
                const SizedBox(height: 16),

                // Details List
                _profileDetailRow('Full Name', user?.name ?? 'Student'),
                _profileDetailRow('Email Address', user?.email ?? 'N/A'),
                _profileDetailRow('Student ID', user?.uid ?? 'N/A'),
                _profileDetailRow('Role', (user?.role ?? 'student').toUpperCase()),

                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
                    onPressed: () => auth.logout(),
                    icon: const Icon(Icons.logout, size: 18),
                    label: const Text('Sign Out'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _profileDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.slate500, fontSize: 13)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.slate900)),
        ],
      ),
    );
  }
}
