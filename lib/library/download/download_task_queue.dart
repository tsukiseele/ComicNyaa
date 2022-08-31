import '../../models/typed_model.dart';
import 'download_task.dart';
import 'downloadable.dart';

class DownloadTaskQueue extends DownloadableQueue<DownloadTask> {
  DownloadTaskQueue(this.items);

  List<TypedModel> items;

  @override
  Future<void> start() async {

  }

  @override
  Future<void> stop() async {

  }
}
