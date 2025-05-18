import 'dart:io';

import 'package:devlink_mobile_app/profile/data/data_source/user_storage_profile_update.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../auth/data/data_source/user_storage.dart';
import '../../../auth/data/dto/profile_dto.dart';
import '../../../auth/data/dto/user_dto.dart';
import '../../../core/styles/app_color_styles.dart';
import '../../../core/styles/app_text_styles.dart';

class MockProfileSettingScreen extends StatefulWidget {
  const MockProfileSettingScreen({super.key});

  @override
  State<MockProfileSettingScreen> createState() =>
      _MockProfileSettingScreenState();
}

class _MockProfileSettingScreenState extends State<MockProfileSettingScreen> {
  final _userStorage = UserStorage.instance;

  // 현재 프로필 정보
  UserDto? _currentUser;
  ProfileDto? _currentProfile;

  // 수정 폼 컨트롤러
  final _nicknameController = TextEditingController();
  final _descriptionController = TextEditingController();

  // 선택한 이미지
  File? _selectedImage;

  // 로딩 상태
  bool _isLoading = false;
  String? _message;

  @override
  void initState() {
    super.initState();
    // 초기화 시 현재 프로필 정보 로드
    _loadCurrentProfile();
  }

  // 현재 프로필 정보 로드
  void _loadCurrentProfile() {
    setState(() {
      _isLoading = true;
      _message = null;
    });

    try {
      // 스토리지 초기화
      _userStorage.initialize();

      // 기본적으로 'user1'으로 로그인 (없으면 로그인하지 않음)
      final wasLoggedIn = _userStorage.currentUserId != null;
      if (!wasLoggedIn) {
        _userStorage.login('user1');
      }

      // 현재 로그인된 사용자 정보 가져오기
      final user = _userStorage.currentUser;

      if (user != null) {
        final profile = _userStorage.getProfileById(user.id!);

        // 상태 및 폼 업데이트
        setState(() {
          _currentUser = user;
          _currentProfile = profile;

          // 컨트롤러 초기값 설정
          _nicknameController.text = user.nickname ?? '';
          if (profile != null && profile.description != null) {
            _descriptionController.text = profile.description!;
          }

          // 이미지가 로컬 파일인 경우
          if (profile != null &&
              profile.image != null &&
              profile.image!.startsWith('/')) {
            _selectedImage = File(profile.image!);
          }
        });
      }
    } catch (e) {
      setState(() {
        _message = '프로필 로드 실패: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // 프로필 업데이트
  Future<void> _updateProfile() async {
    if (_currentUser == null) return;

    setState(() {
      _isLoading = true;
      _message = null;
    });

    try {
      // 확장 메서드를 사용하여 프로필 업데이트
      final success = _userStorage.updateCurrentUserProfile(
        nickname: _nicknameController.text,
        description: _descriptionController.text,
      );

      if (success) {
        setState(() {
          _message = '프로필이 성공적으로 업데이트되었습니다';
        });

        // 프로필 정보 다시 로드
        _loadCurrentProfile();
      } else {
        setState(() {
          _message = '프로필 업데이트 실패';
        });
      }
    } catch (e) {
      setState(() {
        _message = '프로필 업데이트 오류: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // 이미지 선택
  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
      });

      // 이미지 업데이트
      await _updateProfileImage(image);
    }
  }

  // 프로필 이미지 업데이트
  Future<void> _updateProfileImage(XFile image) async {
    if (_currentUser == null) return;

    setState(() {
      _isLoading = true;
      _message = null;
    });

    try {
      // 확장 메서드를 사용하여 이미지 업데이트
      final success = _userStorage.updateCurrentUserImage(image.path);

      if (success) {
        setState(() {
          _message = '이미지가 성공적으로 업데이트되었습니다';
        });

        // 프로필 정보 다시 로드
        _loadCurrentProfile();
      } else {
        setState(() {
          _message = '이미지 업데이트 실패';
        });
      }
    } catch (e) {
      setState(() {
        _message = '이미지 업데이트 오류: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('프로필 수정 데모'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadCurrentProfile,
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 현재 프로필 정보 표시
                    Card(
                      margin: const EdgeInsets.only(bottom: 24),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('현재 프로필', style: AppTextStyles.heading6Bold),
                            const SizedBox(height: 16),

                            // 프로필 정보 표시
                            Row(
                              children: [
                                // 프로필 이미지
                                _buildCurrentProfileImage(),
                                const SizedBox(width: 16),

                                // 사용자 정보
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _currentUser?.nickname ?? '이름 없음',
                                        style: AppTextStyles.subtitle1Bold,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        _currentUser?.email ?? '이메일 없음',
                                        style: AppTextStyles.body1Regular,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),

                            // 소개글
                            if (_currentProfile?.description != null &&
                                _currentProfile!.description!.isNotEmpty) ...[
                              const SizedBox(height: 16),
                              Text('소개', style: AppTextStyles.subtitle1Medium),
                              const SizedBox(height: 8),
                              Text(
                                _currentProfile!.description!,
                                style: AppTextStyles.body1Regular,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),

                    // 프로필 수정 폼
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('프로필 수정', style: AppTextStyles.heading6Bold),
                            const SizedBox(height: 16),

                            // 이미지 선택
                            Center(
                              child: Stack(
                                children: [
                                  _buildSelectableProfileImage(),
                                  Positioned(
                                    bottom: 0,
                                    right: 0,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: AppColorStyles.primary100,
                                        shape: BoxShape.circle,
                                      ),
                                      child: IconButton(
                                        icon: const Icon(
                                          Icons.camera_alt,
                                          color: Colors.white,
                                        ),
                                        onPressed: _pickImage,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),

                            // 닉네임 입력
                            TextField(
                              controller: _nicknameController,
                              decoration: const InputDecoration(
                                labelText: '닉네임',
                                border: OutlineInputBorder(),
                              ),
                            ),
                            const SizedBox(height: 16),

                            // 소개글 입력
                            TextField(
                              controller: _descriptionController,
                              decoration: const InputDecoration(
                                labelText: '소개글',
                                border: OutlineInputBorder(),
                              ),
                              minLines: 3,
                              maxLines: 5,
                            ),
                            const SizedBox(height: 24),

                            // 저장 버튼
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColorStyles.primary100,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                ),
                                onPressed: _isLoading ? null : _updateProfile,
                                child: Text(
                                  '프로필 저장',
                                  style: AppTextStyles.button1Medium.copyWith(
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // 메시지 표시
                    if (_message != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color:
                              _message!.contains('실패') ||
                                      _message!.contains('오류')
                                  ? Colors.red.shade50
                                  : Colors.green.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color:
                                _message!.contains('실패') ||
                                        _message!.contains('오류')
                                    ? Colors.red.shade200
                                    : Colors.green.shade200,
                          ),
                        ),
                        child: Text(
                          _message!,
                          style: AppTextStyles.body1Regular.copyWith(
                            color:
                                _message!.contains('실패') ||
                                        _message!.contains('오류')
                                    ? Colors.red.shade700
                                    : Colors.green.shade700,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
    );
  }

  // 현재 프로필 이미지 표시
  Widget _buildCurrentProfileImage() {
    if (_currentProfile?.image == null || _currentProfile!.image!.isEmpty) {
      // 이미지 없음
      return CircleAvatar(
        radius: 40,
        backgroundColor: Colors.grey.shade200,
        child: Icon(Icons.person, size: 40, color: Colors.grey.shade400),
      );
    }

    // 로컬 파일 경로인 경우
    if (_currentProfile!.image!.startsWith('/')) {
      return CircleAvatar(
        radius: 40,
        backgroundImage: FileImage(File(_currentProfile!.image!)),
        backgroundColor: Colors.grey.shade200,
        onBackgroundImageError: (_, __) {
          debugPrint('이미지 로드 오류: ${_currentProfile!.image}');
        },
      );
    }

    // 네트워크 이미지인 경우
    return CircleAvatar(
      radius: 40,
      backgroundImage: NetworkImage(_currentProfile!.image!),
      backgroundColor: Colors.grey.shade200,
    );
  }

  // 선택 가능한 프로필 이미지 표시
  Widget _buildSelectableProfileImage() {
    if (_selectedImage != null) {
      // 선택한 이미지 표시
      return CircleAvatar(
        radius: 50,
        backgroundImage: FileImage(_selectedImage!),
        backgroundColor: Colors.grey.shade200,
      );
    }

    if (_currentProfile?.image != null && _currentProfile!.image!.isNotEmpty) {
      // 현재 프로필 이미지 표시 (로컬 파일 또는 네트워크 이미지)
      if (_currentProfile!.image!.startsWith('/')) {
        return CircleAvatar(
          radius: 50,
          backgroundImage: FileImage(File(_currentProfile!.image!)),
          backgroundColor: Colors.grey.shade200,
        );
      } else {
        return CircleAvatar(
          radius: 50,
          backgroundImage: NetworkImage(_currentProfile!.image!),
          backgroundColor: Colors.grey.shade200,
        );
      }
    }

    // 이미지 없음
    return CircleAvatar(
      radius: 50,
      backgroundColor: Colors.grey.shade200,
      child: Icon(Icons.person, size: 50, color: Colors.grey.shade400),
    );
  }
}
