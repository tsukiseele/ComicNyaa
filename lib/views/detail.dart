import 'package:flutter/material.dart';

class DetailsView extends StatefulWidget {
  const DetailsView({Key? key}) : super(key: key);
  final title = '详情';

  @override
  State<StatefulWidget> createState() {
    return DetailViewState();
  }
}

class DetailViewState extends State<DetailsView> {
  final title = '';

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
        ),
        body: Container(
            padding: const EdgeInsets.all(8.0),
            child: Column(children: [
              const Text('FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF'),
              const Text('FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF'),
              Text(title)
            ])));
  }
}
