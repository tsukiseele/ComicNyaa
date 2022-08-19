import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class DynamicTabView extends StatefulWidget {
  final int itemCount;
  final IndexedWidgetBuilder tabBuilder;
  final IndexedWidgetBuilder pageBuilder;
  final Widget? stub;
  final ValueChanged<int> onPositionChange;
  final ValueChanged<double> onScroll;
  final int? initPosition;
  final bool isScrollToNewTab;

  const DynamicTabView({
    Key? key,
    required this.itemCount,
    required this.tabBuilder,
    required this.pageBuilder,
    this.stub,
    required this.onPositionChange,
    required this.onScroll,
    this.initPosition,
    this.isScrollToNewTab = false,
  }) : super(key: key);

  @override
  _DynamicTabsState createState() => _DynamicTabsState();
}

class _DynamicTabsState extends State<DynamicTabView>
    with TickerProviderStateMixin {
  TabController? controller;
  int _currentCount = 0;
  int _currentPosition = 0;

  @override
  void initState() {
    if (widget.initPosition != null) {
      _currentPosition = widget.initPosition!;
    }

    // _currentPosition = widget.initPosition;
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

      if (widget.initPosition != null) {
        _currentPosition = widget.initPosition!;
      }

      if (_currentPosition > widget.itemCount - 1) {
        _currentPosition = widget.itemCount - 1;
        _currentPosition = _currentPosition < 0 ? 0 : _currentPosition;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            widget.onPositionChange(_currentPosition);
          }
        });
      }

      _currentCount = widget.itemCount;
      setState(() {
        if (widget.isScrollToNewTab) {
          print('CURRENTTAB COUNT: ${widget.itemCount}');
          _currentPosition = widget.itemCount - 1;
        }
        controller = TabController(
          length: widget.itemCount,
          vsync: this,
          initialIndex: _currentPosition,
        );
        controller?.addListener(onPositionChange);
        controller?.animation?.addListener(onScroll);
      });
    } else if (widget.initPosition != null) {
      controller?.animateTo(widget.initPosition!);
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
    if (widget.onScroll is ValueChanged<double>) {
      widget.onScroll(controller?.animation?.value ?? 0);
    }
  }
}
