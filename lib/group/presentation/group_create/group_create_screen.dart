import 'dart:io';
import 'package:devlink_mobile_app/core/styles/app_color_styles.dart';
import 'package:devlink_mobile_app/core/styles/app_text_styles.dart';
import 'package:devlink_mobile_app/group/presentation/group_create/group_create_action.dart';
import 'package:devlink_mobile_app/group/presentation/group_create/group_create_state.dart';
import 'package:devlink_mobile_app/group/presentation/tag_input_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class GroupCreateScreen extends StatefulWidget {
  final GroupCreateState state;
  final void Function(GroupCreateAction action) onAction;

  const GroupCreateScreen({
    super.key,
    required this.state,
    required this.onAction,
  });

  @override
  State<GroupCreateScreen> createState() => _GroupCreateScreenState();
}

// 2-50 범위의 값만 허용하는 TextInputFormatter
class _MemberCountTextInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // 빈 문자열은 허용
    if (newValue.text.isEmpty) {
      return newValue;
    }

    // 숫자로 변환
    final int? value = int.tryParse(newValue.text);

    // 2-50 범위 체크
    if (value == null || value < 2 || value > 50) {
      // 범위 밖이면 이전 값 유지
      return oldValue;
    }

    // 변경 허용
    return newValue;
  }
}

class _GroupCreateScreenState extends State<GroupCreateScreen> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _tagController = TextEditingController();
  final _memberCountController = TextEditingController();

  // 최대 설명 길이 상수
  static const int _maxDescriptionLength = 1000;

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.state.name;
    _descriptionController.text = widget.state.description;
    _memberCountController.text = widget.state.limitMemberCount.toString();
  }

  @override
  void didUpdateWidget(GroupCreateScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    // 상태가 변경되었을 때 멤버 카운트 컨트롤러 업데이트
    if (oldWidget.state.limitMemberCount != widget.state.limitMemberCount) {
      _memberCountController.text = widget.state.limitMemberCount.toString();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _tagController.dispose();
    _memberCountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = widget.state.isSubmitting;
    // 현재 입력된 글자 수
    final currentDescriptionLength = _descriptionController.text.length;
    // 글자 수에 따른 색상 설정
    final Color counterColor =
        currentDescriptionLength > _maxDescriptionLength * 0.9
            ? (currentDescriptionLength >= _maxDescriptionLength
                ? Colors.red
                : Colors.orange)
            : AppColorStyles.gray80;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 22),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text('새 그룹 만들기', style: AppTextStyles.heading6Bold),
        actions: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.only(right: 16),
            child: TextButton(
              onPressed:
                  isLoading
                      ? null
                      : () => widget.onAction(const GroupCreateAction.submit()),
              style: TextButton.styleFrom(
                backgroundColor:
                    isLoading
                        ? Colors.grey.shade200
                        : AppColorStyles.primary100.withOpacity(0.1),
                foregroundColor:
                    isLoading ? Colors.grey : AppColorStyles.primary100,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: Text(
                '완료',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ],
      ),
      body:
          isLoading
              ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text(
                      '그룹을 생성 중입니다...',
                      style: TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                  ],
                ),
              )
              : CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 썸네일 선택기
                          _buildImageSelector(),
                          const SizedBox(height: 32),

                          // 그룹 이름 - 트렌디한 텍스트 필드로 교체
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(
                                  left: 4,
                                  bottom: 8,
                                ),
                                child: Text(
                                  '그룹 이름',
                                  style: AppTextStyles.subtitle1Bold.copyWith(
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.05),
                                      blurRadius: 10,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: TextField(
                                  controller: _nameController,
                                  style: AppTextStyles.body1Regular,
                                  decoration: InputDecoration(
                                    hintText: '그룹 이름을 입력하세요',
                                    hintStyle: AppTextStyles.body1Regular
                                        .copyWith(color: AppColorStyles.gray60),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: BorderSide.none,
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                      vertical: 16,
                                    ),
                                    filled: true,
                                    fillColor: Colors.white,
                                    suffixIcon:
                                        _nameController.text.isNotEmpty
                                            ? IconButton(
                                              icon: const Icon(
                                                Icons.cancel,
                                                color: AppColorStyles.gray60,
                                                size: 18,
                                              ),
                                              onPressed: () {
                                                _nameController.clear();
                                                widget.onAction(
                                                  const GroupCreateAction.nameChanged(
                                                    '',
                                                  ),
                                                );
                                              },
                                            )
                                            : null,
                                  ),
                                  onChanged:
                                      (value) => widget.onAction(
                                        GroupCreateAction.nameChanged(value),
                                      ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // 그룹 설명 - 트렌디한 텍스트 영역으로 교체
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(
                                  left: 4,
                                  bottom: 8,
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      '그룹 설명',
                                      style: AppTextStyles.subtitle1Bold
                                          .copyWith(fontSize: 16),
                                    ),
                                    // 글자 수 카운터
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: counterColor.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        '$currentDescriptionLength/$_maxDescriptionLength',
                                        style: TextStyle(
                                          color: counterColor,
                                          fontWeight: FontWeight.w500,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.05),
                                      blurRadius: 10,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: TextField(
                                  controller: _descriptionController,
                                  style: AppTextStyles.body1Regular,
                                  maxLines: 5,
                                  maxLength: _maxDescriptionLength,
                                  decoration: InputDecoration(
                                    hintText:
                                        '그룹에 대한 설명을 입력하세요 (최대 $_maxDescriptionLength자)',
                                    hintStyle: AppTextStyles.body1Regular
                                        .copyWith(color: AppColorStyles.gray60),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: BorderSide.none,
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                      vertical: 16,
                                    ),
                                    filled: true,
                                    fillColor: Colors.white,
                                    counterText: '', // 기본 카운터 숨김
                                    suffixIcon:
                                        _descriptionController.text.isNotEmpty
                                            ? IconButton(
                                              icon: const Icon(
                                                Icons.cancel,
                                                color: AppColorStyles.gray60,
                                                size: 18,
                                              ),
                                              onPressed: () {
                                                _descriptionController.clear();
                                                setState(() {}); // UI 업데이트
                                                widget.onAction(
                                                  const GroupCreateAction.descriptionChanged(
                                                    '',
                                                  ),
                                                );
                                              },
                                            )
                                            : null,
                                  ),
                                  onChanged: (value) {
                                    setState(() {}); // 글자 수 카운터 업데이트
                                    widget.onAction(
                                      GroupCreateAction.descriptionChanged(
                                        value,
                                      ),
                                    );
                                  },
                                  inputFormatters: [
                                    LengthLimitingTextInputFormatter(
                                      _maxDescriptionLength,
                                    ),
                                  ],
                                ),
                              ),

                              // 글자 수 임계치 표시기 (진행률 표시)
                            ],
                          ),
                          const SizedBox(height: 32),

                          // 멤버 제한
                          _buildMemberLimitSection(),
                          const SizedBox(height: 32),

                          // 태그 입력 영역
                          _buildTagInputSection(),
                          const SizedBox(height: 24),

                          // 에러 메시지
                          if (widget.state.errorMessage != null)
                            _buildErrorMessage(),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
    );
  }

  Widget _buildImageSelector() {
    return Center(
      child: Column(
        children: [
          Material(
            elevation: 6,
            shadowColor: AppColorStyles.primary100.withOpacity(0.2),
            shape: const CircleBorder(),
            child: GestureDetector(
              onTap:
                  () => widget.onAction(const GroupCreateAction.selectImage()),
              child: Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient:
                      widget.state.imageUrl == null
                          ? LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              AppColorStyles.primary60.withOpacity(0.2),
                              AppColorStyles.primary100.withOpacity(0.3),
                            ],
                          )
                          : null,
                  border: Border.all(color: Colors.white, width: 4),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(80),
                  child:
                      widget.state.imageUrl == null
                          ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.8),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.add_photo_alternate_rounded,
                                  size: 36,
                                  color: AppColorStyles.primary100,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                '그룹 이미지 추가',
                                style: TextStyle(
                                  color: AppColorStyles.primary100,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          )
                          : Stack(
                            fit: StackFit.expand,
                            children: [
                              widget.state.imageUrl!.startsWith('http')
                                  ? Image.network(
                                    widget.state.imageUrl!,
                                    fit: BoxFit.cover,
                                  )
                                  : Image.file(
                                    File(
                                      widget.state.imageUrl!.replaceFirst(
                                        'file://',
                                        '',
                                      ),
                                    ),
                                    fit: BoxFit.cover,
                                  ),
                            ],
                          ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '그룹을 대표하는 이미지를 선택하세요',
            style: TextStyle(fontSize: 14, color: AppColorStyles.gray80),
          ),
          // 이미지가 있을 경우 삭제 버튼 추가
          if (widget.state.imageUrl != null)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: TextButton.icon(
                onPressed: () {
                  widget.onAction(
                    const GroupCreateAction.imageUrlChanged(null),
                  );
                },
                icon: const Icon(Icons.delete, color: Colors.red),
                label: const Text(
                  '이미지 삭제',
                  style: TextStyle(color: Colors.red),
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  backgroundColor: Colors.red.withOpacity(0.1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMemberLimitSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [Text('멤버 제한', style: AppTextStyles.subtitle1Bold)],
        ),
        const SizedBox(height: 20),

        // 세련된 슬라이더
        SliderTheme(
          data: SliderThemeData(
            trackHeight: 8,
            activeTrackColor: AppColorStyles.primary100,
            inactiveTrackColor: Colors.grey[200],
            thumbColor: Colors.white,
            thumbShape: const RoundSliderThumbShape(
              enabledThumbRadius: 14,
              elevation: 4,
            ),
            overlayColor: AppColorStyles.primary100.withOpacity(0.2),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 24),
          ),
          child: Slider(
            value: widget.state.limitMemberCount.toDouble(),
            min: 2,
            max: 50,
            divisions: 48,
            onChanged: (value) {
              // 슬라이더 변경 시 컨트롤러 업데이트
              _memberCountController.text = value.toInt().toString();
              widget.onAction(
                GroupCreateAction.limitMemberCountChanged(value.toInt()),
              );
            },
          ),
        ),

        const SizedBox(height: 16),

        // 최대 인원수 컨트롤러
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColorStyles.primary100.withOpacity(0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColorStyles.primary100.withOpacity(0.1),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('최대 인원수', style: AppTextStyles.body1Regular),
              const SizedBox(width: 16),

              // 인원수 감소 버튼
              _buildMemberCountButton(
                icon: Icons.remove,
                onPressed:
                    widget.state.limitMemberCount > 2
                        ? () {
                          final newValue = widget.state.limitMemberCount - 1;
                          // 컨트롤러 업데이트 먼저
                          _memberCountController.text = newValue.toString();
                          // 그다음 상태 업데이트
                          widget.onAction(
                            GroupCreateAction.limitMemberCountChanged(newValue),
                          );
                        }
                        : null,
              ),

              // 인원수 입력창
              Container(
                width: 56,
                height: 36,
                margin: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColorStyles.gray40),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: TextField(
                    controller: _memberCountController,
                    textAlign: TextAlign.center,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      contentPadding: EdgeInsets.zero,
                      border: InputBorder.none,
                      isDense: true,
                    ),
                    style: AppTextStyles.subtitle1Bold.copyWith(
                      color: AppColorStyles.primary100,
                    ),
                    // 입력 제한 formatter 수정
                    inputFormatters: [
                      // 숫자만 입력 가능하도록 제한
                      FilteringTextInputFormatter.digitsOnly,
                      // 최대 2자리 수만 허용
                      LengthLimitingTextInputFormatter(2),
                    ],
                    // 중요한 수정: onChanged 이벤트가 아닌 onEditingComplete 사용
                    onEditingComplete: () {
                      // 편집이 완료된 후에 상태 업데이트
                      final value = _memberCountController.text;
                      if (value.isEmpty) {
                        // 빈 값인 경우 기본값으로 설정
                        _memberCountController.text = "2";
                        widget.onAction(
                          const GroupCreateAction.limitMemberCountChanged(2),
                        );
                        return;
                      }

                      final count = int.tryParse(value);
                      if (count != null) {
                        // 유효 범위 내에서만 상태 업데이트
                        if (count >= 2 && count <= 50) {
                          widget.onAction(
                            GroupCreateAction.limitMemberCountChanged(count),
                          );
                        } else if (count < 2) {
                          _memberCountController.text = "2";
                          widget.onAction(
                            const GroupCreateAction.limitMemberCountChanged(2),
                          );
                        } else if (count > 50) {
                          _memberCountController.text = "50";
                          widget.onAction(
                            const GroupCreateAction.limitMemberCountChanged(50),
                          );
                        }
                      }
                      FocusScope.of(context).unfocus();
                    },
                    // 키보드에서 완료 버튼 눌렀을 때
                    textInputAction: TextInputAction.done,
                    // 포커스 끝날 때 처리 (키보드 외부 터치 등)
                    onSubmitted: (value) {
                      // onEditingComplete와 동일한 로직 수행
                      if (value.isEmpty) {
                        _memberCountController.text = "2";
                        widget.onAction(
                          const GroupCreateAction.limitMemberCountChanged(2),
                        );
                        return;
                      }

                      final count = int.tryParse(value);
                      if (count != null) {
                        if (count >= 2 && count <= 50) {
                          widget.onAction(
                            GroupCreateAction.limitMemberCountChanged(count),
                          );
                        } else if (count < 2) {
                          _memberCountController.text = "2";
                          widget.onAction(
                            const GroupCreateAction.limitMemberCountChanged(2),
                          );
                        } else if (count > 50) {
                          _memberCountController.text = "50";
                          widget.onAction(
                            const GroupCreateAction.limitMemberCountChanged(50),
                          );
                        }
                      }
                    },
                  ),
                ),
              ),

              // 인원수 증가 버튼
              _buildMemberCountButton(
                icon: Icons.add,
                onPressed:
                    widget.state.limitMemberCount < 50
                        ? () {
                          final newValue = widget.state.limitMemberCount + 1;
                          // 컨트롤러 업데이트 먼저
                          _memberCountController.text = newValue.toString();
                          // 그다음 상태 업데이트
                          widget.onAction(
                            GroupCreateAction.limitMemberCountChanged(newValue),
                          );
                        }
                        : null,
              ),

              const SizedBox(width: 4),
              Text('명', style: AppTextStyles.body1Regular),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMemberCountButton({
    required IconData icon,
    required VoidCallback? onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color:
            onPressed != null
                ? AppColorStyles.primary100
                : AppColorStyles.gray60.withOpacity(0.3),
        boxShadow:
            onPressed != null
                ? [
                  BoxShadow(
                    color: AppColorStyles.primary100.withOpacity(0.3),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
                : null,
      ),
      child: IconButton(
        icon: Icon(icon, color: Colors.white, size: 16),
        onPressed: onPressed,
        padding: const EdgeInsets.all(4),
        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
      ),
    );
  }

  Widget _buildTagInputSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('그룹 태그', style: AppTextStyles.subtitle1Bold),
            Text(
              '${widget.state.hashTags.length}/10',
              style: TextStyle(color: AppColorStyles.gray80, fontSize: 14),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TagInputField(
            tags: widget.state.hashTags,
            onAddTag:
                (value) =>
                    widget.onAction(GroupCreateAction.hashTagAdded(value)),
            onRemoveTag:
                (value) =>
                    widget.onAction(GroupCreateAction.hashTagRemoved(value)),
            hintText: '#태그를 입력 후 추가하세요',
          ),
        ),
      ],
    );
  }

  Widget _buildErrorMessage() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.red[100],
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.error_outline, color: Colors.red[700], size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              widget.state.errorMessage!,
              style: TextStyle(
                color: Colors.red[700],
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
