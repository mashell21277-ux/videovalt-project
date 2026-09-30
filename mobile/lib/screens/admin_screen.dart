import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/constants.dart';
import '../models/video.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  final _passwordController = TextEditingController();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  VideoCategory _category = VideoCategory.entertainment;
  VideoType _type = VideoType.video;
  PlatformFile? _selectedFile;
  bool _loggingIn = false;
  bool _uploading = false;
  double _uploadProgress = 0;
  String? _error;
  List<VideoModel> _videos = [];
  bool _loadingVideos = false;
  bool _videosLoaded = false;

  @override
  void dispose() {
    _passwordController.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    setState(() {
      _loggingIn = true;
      _error = null;
    });

    try {
      final auth = context.read<AuthService>();
      final success = await auth.login(_passwordController.text);
      if (!success && mounted) {
        setState(() => _error = 'Invalid password');
      } else {
        setState(() => _videosLoaded = false);
        await _loadVideos();
      }
    } catch (_) {
      if (mounted) setState(() => _error = 'Could not connect to server');
    } finally {
      if (mounted) setState(() => _loggingIn = false);
    }
  }

  Future<void> _loadVideos() async {
    setState(() => _loadingVideos = true);
    try {
      final api = context.read<ApiService>();
      final videos = await api.fetchVideos();
      if (mounted) {
        setState(() {
          _videos = videos;
          _videosLoaded = true;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _error = 'Failed to load videos');
    } finally {
      if (mounted) setState(() => _loadingVideos = false);
    }
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.video,
      withData: false,
    );
    if (result != null && result.files.single.path != null) {
      setState(() => _selectedFile = result.files.single);
    }
  }

  Future<void> _upload() async {
    if (_selectedFile == null || _titleController.text.isEmpty) return;

    setState(() {
      _uploading = true;
      _uploadProgress = 0;
      _error = null;
    });

    try {
      final api = context.read<ApiService>();
      await api.uploadVideo(
        file: _selectedFile!,
        title: _titleController.text,
        description: _descriptionController.text.isEmpty
            ? null
            : _descriptionController.text,
        category: _category,
        type: _type,
        onProgress: (sent, total) {
          if (mounted && total > 0) {
            setState(() => _uploadProgress = sent / total);
          }
        },
      );

      _titleController.clear();
      _descriptionController.clear();
      setState(() => _selectedFile = null);
      await _loadVideos();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Video uploaded successfully')),
        );
      }
    } catch (_) {
      if (mounted) setState(() => _error = 'Upload failed');
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _delete(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete video?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final api = context.read<ApiService>();
      await api.deleteVideo(id);
      if (mounted) await _loadVideos();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Delete failed')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthService>(
      builder: (context, auth, _) {
        if (!auth.initialized) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!auth.isAdmin) {
          return _buildLogin();
        }

        if (!_videosLoaded && !_loadingVideos) {
          WidgetsBinding.instance.addPostFrameCallback((_) => _loadVideos());
        }

        return _buildDashboard(auth);
      },
    );
  }

  Widget _buildLogin() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.lock, color: AppColors.primary, size: 28),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Admin Access',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Only you can upload videos',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      hintText: 'Enter admin password',
                      prefixIcon: Icon(Icons.key),
                    ),
                    onSubmitted: (_) => _login(),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(_error!, style: const TextStyle(color: Colors.redAccent)),
                  ],
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _loggingIn ? null : _login,
                      child: _loggingIn
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Sign In'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDashboard(AuthService auth) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
            child: Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Admin Dashboard',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        'Upload and manage your videos',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                TextButton.icon(
                  onPressed: () async {
                    await auth.logout();
                    setState(() {
                      _videos = [];
                      _videosLoaded = false;
                    });
                  },
                  icon: const Icon(Icons.logout),
                  label: const Text('Logout'),
                ),
              ],
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.upload, color: AppColors.primary),
                        SizedBox(width: 8),
                        Text(
                          'Upload Video',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: _titleController,
                      decoration: const InputDecoration(labelText: 'Title'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(labelText: 'Description'),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<VideoCategory>(
                      initialValue: _category,
                      decoration: const InputDecoration(labelText: 'Category'),
                      items: categories
                          .map(
                            (c) => DropdownMenuItem(
                              value: c,
                              child: Text('${c.emoji} ${c.label}'),
                            ),
                          )
                          .toList(),
                      onChanged: (v) {
                        if (v != null) setState(() => _category = v);
                      },
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: VideoType.values.map((t) {
                        final selected = _type == t;
                        return Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(
                              right: t == VideoType.video ? 8 : 0,
                            ),
                            child: OutlinedButton.icon(
                              onPressed: () => setState(() => _type = t),
                              style: OutlinedButton.styleFrom(
                                backgroundColor: selected
                                    ? AppColors.primary.withValues(alpha: 0.15)
                                    : null,
                                foregroundColor:
                                    selected ? AppColors.primary : null,
                              ),
                              icon: Icon(
                                t == VideoType.video
                                    ? Icons.movie
                                    : Icons.view_stream,
                              ),
                              label: Text(
                                t == VideoType.video ? 'Video' : 'Reel',
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: _pickFile,
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 56),
                      ),
                      icon: const Icon(Icons.video_file),
                      label: Text(
                        _selectedFile?.name ?? 'Choose video file',
                      ),
                    ),
                    if (_uploading) ...[
                      const SizedBox(height: 16),
                      LinearProgressIndicator(value: _uploadProgress),
                    ],
                    if (_error != null) ...[
                      const SizedBox(height: 12),
                      Text(_error!, style: const TextStyle(color: Colors.redAccent)),
                    ],
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _uploading || _selectedFile == null
                            ? null
                            : _upload,
                        icon: const Icon(Icons.cloud_upload),
                        label: Text(_uploading ? 'Uploading...' : 'Upload'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'All Videos (${_videos.length})',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        if (_loadingVideos)
          const SliverFillRemaining(
            child: Center(child: CircularProgressIndicator()),
          )
        else if (_videos.isEmpty)
          const SliverFillRemaining(
            child: Center(
              child: Text(
                'No videos uploaded yet',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
          )
        else
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final video = _videos[index];
                return ListTile(
                  leading: const CircleAvatar(
                    child: Icon(Icons.play_arrow),
                  ),
                  title: Text(video.title),
                  subtitle: Text(
                    '${video.category.label} · ${video.type.name} · ${video.formattedSize}',
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => _delete(video.id),
                  ),
                );
              },
              childCount: _videos.length,
            ),
          ),
        const SliverToBoxAdapter(child: SizedBox(height: 100)),
      ],
    );
  }
}
