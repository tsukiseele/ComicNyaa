import 'package:comic_nyaa/library/mio/core/mio.dart';
import 'package:comic_nyaa/models/typed_model.dart';
import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

class ComicDetailView extends StatefulWidget {
  const ComicDetailView({Key? key, required this.model}) : super(key: key);
  final title = '漫画';
  final TypedModel model;

  @override
  State<StatefulWidget> createState() {
    return ComicDetailViewState();
  }
}

class ComicDetailViewState extends State<ComicDetailView> {
  final Map<int, double> _heightCache = {};
  TypedModel? _model;
  List<TypedModel>? _children;


  void getChildren() async {
    try {
      final model = widget.model;
      print('model.\$section: ${model.$section}');
      final dynamicResult = await Mio(model.$site).parseChildrenConcurrency(model.toJson(), model.$section!.rules!);
      final models = TypedModel.fromJson(dynamicResult);
      print('UUUUUU: ${getUrl(models)}');
      setState(() {
        _model = models; //TypedModel.fromJson(dynamicResult);
        _children = _model?.children;
      });

      setState(() {});
    } catch (e) {
      print('ERROR: ${e.toString()}');
    }
    // return data;;
  }

  String getUrl(TypedModel? item) {
    if (item == null) return '';
    try {
      final children = item.children != null ? item.children![0] : null;
      if (children != null) {
        return children.sampleUrl ?? children.largerUrl ?? children.originUrl ?? '';
      }
      return item.sampleUrl ?? item.largerUrl ?? item.originUrl ?? '';
    } catch (e) {
      print('ERROR: $e');
    }
    return '';
  }

  @override
  void initState() {
    getChildren();

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
              Flexible(
                  child: _children != null
                      ? MasonryGridView.count(
                          padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
                          crossAxisCount: 3,
                          mainAxisSpacing: 8.0,
                          crossAxisSpacing: 8.0,
                          itemCount: _children?.length,
                          itemBuilder: (context, index) {
                            return Material(
                                elevation: 2.0,
                                borderRadius: const BorderRadius.all(Radius.circular(4.0)),
                                child: InkWell(
                                    onTap: () {},
                                    child: Column(
                                      children: [
                                        ExtendedImage.network(getUrl(_children?[index]),
                                            // width: ScreenUtil.instance.setWidth(400),
                                            // height: ScreenUtil.instance.setWidth(400),
                                            // width: _heights[index],
                                            height: _heightCache[index],
                                            fit: BoxFit.cover,
                                            cache: true,
                                            handleLoadingProgress: true,
                                    gaplessPlayback: true,
                                            // border: Border.all(color: Colors.red, width: 1.0),
                                            // shape: boxShape,
                                            borderRadius: const BorderRadius.all(Radius.circular(4.0)),
                                            //cancelToken: cancellationToken,
                                            afterPaintImage: (Canvas canvas, Rect rect, image, Paint paint) {
                                              if (_heightCache[index] == null) {
                                                _heightCache[index] = rect.height;
                                              }
                                            },
                                        ),
                                        Container(
                                          padding: const EdgeInsets.all(8.0),
                                          child: Text(_children?[index].title ?? ''),
                                        )
                                      ],
                                    )));
                          })
                      : Container()),
            ])));
  }
}
