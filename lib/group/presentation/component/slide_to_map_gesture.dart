// lib/group/presentation/group_detail/components/slide_to_map_gesture.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SlideToMapGesture extends StatefulWidget {
  final String groupId;
  final double triggerThreshold;
  final Color indicatorColor;

  const SlideToMapGesture({
    super.key,
    required this.groupId,
    this.triggerThreshold = 0.3, // 화면 너비의 이 비율만큼 슬라이드하면 지도로 이동
    this.indicatorColor = Colors.blue,
  });

  @override
  State<SlideToMapGesture> createState() => _SlideToMapGestureState();
}

class _SlideToMapGestureState extends State<SlideToMapGesture>
    with SingleTickerProviderStateMixin {
  double _dragPosition = 0;
  bool _isDragging = false;
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _animation = Tween<double>(
      begin: 0.0,
      end: 0.0,
    ).animate(_animationController);

    // 시작 시 인디케이터 애니메이션 실행
    _startPulseAnimation();
  }

  void _startPulseAnimation() {
    // 펄스 효과를 위한 애니메이션 설정
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    // 애니메이션 반복 설정
    _animationController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onHorizontalDragStart(DragStartDetails details) {
    setState(() {
      _isDragging = true;
      _dragPosition = 0;
    });
    _animationController.stop();
  }

  void _onHorizontalDragUpdate(DragUpdateDetails details) {
    if (!_isDragging) return;

    // 오른쪽으로만 드래그할 수 있도록 제한
    if (details.delta.dx > 0) {
      setState(() {
        _dragPosition += details.delta.dx;
      });
    }
  }

  void _onHorizontalDragEnd(DragEndDetails details) {
    final screenWidth = MediaQuery.of(context).size.width;
    final threshold = screenWidth * widget.triggerThreshold;

    // 임계값을 넘었다면 지도 화면으로 이동
    if (_dragPosition > threshold) {
      context.push('/group/${widget.groupId}/map');
    }

    // 드래그 상태 초기화
    setState(() {
      _isDragging = false;
      _dragPosition = 0;
    });

    // 애니메이션 다시 시작
    _startPulseAnimation();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragStart: _onHorizontalDragStart,
      onHorizontalDragUpdate: _onHorizontalDragUpdate,
      onHorizontalDragEnd: _onHorizontalDragEnd,
      child: Container(
        width: 40, // 슬라이드 터치 영역 너비
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [
              Colors.transparent,
              widget.indicatorColor.withValues(alpha: 0.1),
            ],
          ),
        ),
        child: AnimatedBuilder(
          animation: _animation,
          builder: (context, child) {
            // 드래그 중이면 진행 표시기 보여주기
            if (_isDragging) {
              return _buildDragProgress();
            }

            // 드래그 중이 아니면 힌트 표시기 보여주기
            return _buildHintIndicator();
          },
        ),
      ),
    );
  }

  Widget _buildDragProgress() {
    final screenWidth = MediaQuery.of(context).size.width;
    final threshold = screenWidth * widget.triggerThreshold;
    final progress = (_dragPosition / threshold).clamp(0.0, 1.0);

    return Center(
      child: Icon(
        Icons.arrow_forward_ios,
        color: widget.indicatorColor.withValues(alpha: 0.5 + (progress * 0.5)),
        size: 18 + (progress * 8), // 드래그에 따라 아이콘 크기 커짐
      ),
    );
  }

  Widget _buildHintIndicator() {
    return Center(
      child: Icon(
        Icons.arrow_forward_ios,
        color: widget.indicatorColor.withValues(
          alpha: 0.3 + (_animation.value * 0.4),
        ),
        size: 18,
      ),
    );
  }
}
