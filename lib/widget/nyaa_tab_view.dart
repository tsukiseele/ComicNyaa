import 'package:flutter/material.dart';

class NyaaTabView extends StatefulWidget {
  final int itemCount;
  final IndexedWidgetBuilder tabBuilder;
  final IndexedWidgetBuilder pageBuilder;
  final Widget? stub;
  final ValueChanged<int> onPositionChange;
  final ValueChanged<double> onScroll;
  final int? position;
  final bool isScrollToNewTab;
  final Decoration? indicator;
  final Color? color;
  final Duration duration;
  final double elevation;
  final BorderRadius tabBarBorderRadius;
  final EdgeInsets tabBarPadding;

  const NyaaTabView({
    Key? key,
    required this.itemCount,
    required this.tabBuilder,
    required this.pageBuilder,
    required this.onPositionChange,
    required this.onScroll,
    this.position,
    this.isScrollToNewTab = false,
    this.indicator,
    this.stub,
    this.color,
    this.duration = const Duration(milliseconds: 1000),
    this.elevation = 8,
    this.tabBarBorderRadius = BorderRadius.zero,
    this.tabBarPadding = const EdgeInsets.all(4)
  }) : super(key: key);

  @override
  State<NyaaTabView> createState() => _NyaaTabsState();
}

class _NyaaTabsState extends State<NyaaTabView> with TickerProviderStateMixin {
  TabController? controller;
  int _currentCount = 0;
  int _currentPosition = 0;

  @override
  void initState() {
    if (widget.position != null) {
      _currentPosition = widget.position!;
    }
    controller = TabController(
      length: widget.itemCount,
      vsync: this,
      initialIndex: _currentPosition,
    );
    controller?.addListener(onPositionChange);
    controller?.animation?.addListener(onScroll);
    _currentCount = widget.itemCount;
    super.initState();
  }

  @override
  void didUpdateWidget(NyaaTabView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_currentCount != widget.itemCount) {
      controller?.animation?.removeListener(onScroll);
      controller?.removeListener(onPositionChange);
      controller?.dispose();

      // 页面被删除时，重新获取正确的当前索引值
      if (_currentPosition > widget.itemCount - 1) {
        _currentPosition = widget.itemCount - 1;
        _currentPosition = _currentPosition < 0 ? 0 : _currentPosition;
      }

      final transitionPostion = widget.isScrollToNewTab &&
              widget.itemCount > _currentCount &&
              widget.itemCount > 1
          ? widget.itemCount - 2
          : _currentPosition;

      _currentCount = widget.itemCount;

      setState(() {
        controller = TabController(
          length: widget.itemCount,
          vsync: this,
          // 此处
          initialIndex: transitionPostion,
        );
        controller?.addListener(onPositionChange);
        controller?.animation?.addListener(onScroll);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            // 跳转到新增的索引
            if (widget.isScrollToNewTab) {
              _currentPosition = widget.itemCount - 1;
            }
            controller?.animateTo(_currentPosition,
                duration: const Duration(milliseconds: 1), curve: Curves.ease);
            // onPositionChange();
          }
        });
      });
    } else if (widget.position != null) {
      controller?.animateTo(widget.position!);
    }
  }

  @override
  void dispose() {
    controller?.animation?.removeListener(onScroll);
    controller?.removeListener(onPositionChange);
    controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.itemCount < 1) return widget.stub ?? Container();

    return Stack(children: [
      AnimatedContainer(
          color: widget.color,
          duration: widget.duration,
          child: TabBarView(
            controller: controller,
            children: List.generate(widget.itemCount,
                (index) => widget.pageBuilder(context, index)),
          )),
      Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: Material(
              borderRadius: widget.tabBarBorderRadius,
              clipBehavior: Clip.hardEdge,
              color: Colors.transparent,
              elevation: widget.elevation,
              child: AnimatedContainer(
                color: widget.color,
                duration: widget.duration,
                child: TabBar(
                  padding: widget.tabBarPadding,
                  isScrollable: true,
                  controller: controller,
                  labelColor: Theme.of(context).primaryColor,
                  unselectedLabelColor: Theme.of(context).hintColor,
                  enableFeedback: true,
                  indicator: widget.indicator,
                  tabs: List.generate(
                    widget.itemCount,
                    (index) => widget.tabBuilder(context, index),
                  ),
                ),
              ))),
    ]);
  }

  onPositionChange() {
    if (!(controller?.indexIsChanging == true)) {
      _currentPosition = controller?.index ?? 0;
      widget.onPositionChange(_currentPosition);
    }
  }

  onScroll() {
    widget.onScroll(controller?.animation?.value ?? 0);
  }
}
