import 'package:flutter/material.dart';

class DynamicTabView extends StatefulWidget {
  final int itemCount;
  final IndexedWidgetBuilder tabBuilder;
  final IndexedWidgetBuilder pageBuilder;
  final Widget? stub;
  final ValueChanged<int> onPositionChange;
  final ValueChanged<double> onScroll;
  final int? position;
  final bool isScrollToNewTab;

  const DynamicTabView({
    Key? key,
    required this.itemCount,
    required this.tabBuilder,
    required this.pageBuilder,
    this.stub,
    required this.onPositionChange,
    required this.onScroll,
    this.position,
    this.isScrollToNewTab = false,
  }) : super(key: key);

  @override
  State<DynamicTabView> createState() => _DynamicTabsState();
}

class _DynamicTabsState extends State<DynamicTabView> with TickerProviderStateMixin {
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
  void didUpdateWidget(DynamicTabView oldWidget) {
    if (_currentCount != widget.itemCount) {
      controller?.animation?.removeListener(onScroll);
      controller?.removeListener(onPositionChange);
      controller?.dispose();
      // 尝试使用传入索引
      if (widget.position != null) {
        _currentPosition = widget.position!;
      }
      // 页面被删除时，重新获取正确的当前索引值
      if (_currentPosition > widget.itemCount - 1) {
        _currentPosition = widget.itemCount - 1;
        _currentPosition = _currentPosition < 0 ? 0 : _currentPosition;
      }
      // 重置控制器
      _currentCount = widget.itemCount;
      setState(() {
        controller = TabController(
          length: widget.itemCount,
          vsync: this,
          initialIndex: _currentPosition,
        );
        controller?.addListener(onPositionChange);
        controller?.animation?.addListener(onScroll);

        // 跳转到新增的索引
        if (widget.isScrollToNewTab) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              _currentPosition = widget.itemCount - 1;
              controller?.animateTo(_currentPosition, duration: const Duration(milliseconds: 1), curve: Curves.ease);
            }
          });
        } else {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              onPositionChange();
              controller?.animateTo(_currentPosition, duration: const Duration(milliseconds: 1), curve: Curves.ease);
            }
          });
        }
      });
    } else if (widget.position != null) {
      controller?.animateTo(widget.position!);
    }

    super.didUpdateWidget(oldWidget);
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Expanded(
          child: TabBarView(
            controller: controller,
            children: List.generate(
              widget.itemCount,
              (index) => widget.pageBuilder(context, index),
            ),
          ),
        ),
        Container(
          alignment: Alignment.center,
          child: TabBar(
            isScrollable: true,
            controller: controller,
            labelColor: Theme.of(context).primaryColor,
            unselectedLabelColor: Theme.of(context).hintColor,
            enableFeedback: true,
            indicator: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Theme.of(context).primaryColor,
                  width: 2,
                ),
              ),
            ),
            tabs: List.generate(
              widget.itemCount,
              (index) => widget.tabBuilder(context, index),
            ),
          ),
        ),
      ],
    );
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
