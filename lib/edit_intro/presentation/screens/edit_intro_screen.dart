import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:devlink_mobile_app/edit_intro/presentation/providers/edit_intro_provider.dart';

class EditIntroScreen extends ConsumerStatefulWidget {
  const EditIntroScreen({super.key});

  @override
  ConsumerState<EditIntroScreen> createState() => _EditIntroScreenState();
}

class _EditIntroScreenState extends ConsumerState<EditIntroScreen> {
  final _nicknameController = TextEditingController();
  final _introController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(editIntroProvider.notifier).loadProfile();
    });
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    _introController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      ref.read(editIntroProvider.notifier).updateProfileImage(image);
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final success = await ref.read(editIntroProvider.notifier).updateProfile(
          nickname: _nicknameController.text,
          intro: _introController.text,
        );

    if (success && mounted) {
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(editIntroProvider);

    if (state.isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (state.hasError) {
      return Scaffold(
        body: Center(
          child: Text(state.errorMessage ?? '오류가 발생했습니다'),
        ),
      );
    }

    final member = state.member;
    if (member == null) {
      return const Scaffold(
        body: Center(child: Text('프로필 정보를 불러올 수 없습니다')),
      );
    }

    _nicknameController.text = member.nickname;
    _introController.text = member.image;

    return Scaffold(
      appBar: AppBar(
        title: const Text('프로필 수정'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundImage: member.image.isNotEmpty
                          ? NetworkImage(member.image)
                          : null,
                      child: member.image.isEmpty
                          ? const Icon(Icons.person, size: 50)
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        decoration: const BoxDecoration(
                          color: Colors.blue,
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.camera_alt, color: Colors.white),
                          onPressed: _pickImage,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _nicknameController,
                decoration: const InputDecoration(
                  labelText: '닉네임',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '닉네임을 입력해주세요';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _introController,
                decoration: const InputDecoration(
                  labelText: '소개글',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _saveProfile,
                child: const Text('저장하기'),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 