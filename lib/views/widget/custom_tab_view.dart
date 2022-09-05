import 'package:flutter/material.dart';

class CustomTabView extends StatefulWidget {
  final int? itemCount;
  final IndexedWidgetBuilder? tabBuilder;
  final IndexedWidgetBuilder? pageBuilder;
  final Widget? stub;
  final ValueChanged<int>? onPositionChange;
  final ValueChanged<double>? onScroll;
  final int? initPosition;


  const CustomTabView({Key? key, this.itemCount, this.tabBuilder, this.pageBuilder, this.stub,
    this.onPositionChange, this.onScroll, this.initPosition}) : super(key: key);

  @override
  State<CustomTabView> createState() => _CustomTabsState();
}

class _CustomTabsState extends State<CustomTabView> with TickerProviderStateMixin {
  late TabController controller;
  late int _currentCount;
  late int _currentPosition;

  @override
  void initState() {
    _currentPosition = widget.initPosition!;
    controller = TabController(
      length: widget.itemCount!,
      vsync: this,
      initialIndex: _currentPosition,
    );
    controller.addListener(onPositionChange);
    controller.animation!.addListener(onScroll);
    _currentCount = widget.itemCount!;
    super.initState();
  }

  @override
  void didUpdateWidget(CustomTabView oldWidget) {
    if (_currentCount != widget.itemCount) {
      controller.animation!.removeListener(onScroll);
      controller.removeListener(onPositionChange);
      controller.dispose();

      /// 重新获取初始位置
      // if (widget.initPosition != null) {
      //   _currentPosition = widget.initPosition!;
      // }
      /// 判断越界
      if (_currentPosition > widget.itemCount! - 1) {
        _currentPosition = widget.itemCount! - 1;
        _currentPosition = _currentPosition < 0 ? 0 :
        _currentPosition;
        if (widget.onPositionChange is ValueChanged<int>) {
          WidgetsBinding.instance.addPostFrameCallback((_){
            if(mounted) {
              widget.onPositionChange!(_currentPosition);
            }
          });
        }
      }

      _currentCount = widget.itemCount!;
      setState(() {
        controller = TabController(
          length: widget.itemCount!,
          vsync: this,
          initialIndex: _currentPosition,
        );
        controller.addListener(onPositionChange);
        controller.animation!.addListener(onScroll);
      });
      if (widget.initPosition != null) {
        _currentPosition = widget.initPosition!;
      }
      // WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      //   if (mounted) {
      //     controller.animateTo(_currentPosition);
      //   }
      // });
      print('SIZE CHANGED ANIMATE_TO::: $_currentPosition');
      controller.animateTo(widget.initPosition!);
    } else if (widget.initPosition != null) {
      controller.animateTo(widget.initPosition!);
    }

    super.didUpdateWidget(oldWidget);
  }

  @override
  void dispose() {
    controller.animation!.removeListener(onScroll);
    controller.removeListener(onPositionChange);
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.itemCount! < 1) return widget.stub ?? Container();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Expanded(
          child: TabBarView(
            controller: controller,
            children: List.generate(
              widget.itemCount!,
                  (index) => widget.pageBuilder!(context, index),
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
            indicator: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Theme.of(context).primaryColor,
                  width: 2,
                ),
              ),
            ),
            tabs: List.generate(
              widget.itemCount!,
                  (index) => widget.tabBuilder!(context, index),
            ),
          ),
        ),
      ],
    );
  }

  onPositionChange() {
    if (!controller.indexIsChanging) {
      _currentPosition = controller.index;
      if (widget.onPositionChange is ValueChanged<int>) {
        widget.onPositionChange!(_currentPosition);
      }
    }
  }

  onScroll() {
    if (widget.onScroll is ValueChanged<double>) {
      widget.onScroll!(controller.animation!.value);
    }
  }
}