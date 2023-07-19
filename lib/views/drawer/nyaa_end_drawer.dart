/*
 * Copyright (C) 2022. TsukiSeele
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */

import 'package:comic_nyaa/utils/public_api.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../app/app_config.dart';
import '../../library/mio/model/site.dart';
import '../../widget/simple_network_image.dart';

class _NyaaEndController extends GetxController {
  var expandState = <int, bool>{0: true}.obs;
  var scrollPosition = 0.0.obs;
  var banner = ''.obs;
}

class NyaaEndDrawer extends StatelessWidget {
  NyaaEndDrawer({Key? key, required this.sites, this.onItemTap})
      : super(key: key);

  final List<Site> sites;
  final void Function(Site site)? onItemTap;
  final _scrollController = ScrollController();

  IconData _getIconDataByType(String type) {
    switch (type) {
      case 'comic':
        return Icons.photo_library;
      case 'image':
        return Icons.image;
      case 'video':
        return Icons.video_collection;
      default:
        return Icons.quiz;
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(_NyaaEndController());
    if (controller.banner.value.isEmpty) {
      apiRandomImage().then((value) => controller.banner.value = value);
    }
    final siteTypeMap = <String, List<Site>>{};
    for (final site in sites) {
      final type = site.type ?? 'unknown';
      if (siteTypeMap.containsKey(site.type)) {
        siteTypeMap[type]!.add(site);
      } else {
        siteTypeMap[type] = [site];
      }
    }
    final group = siteTypeMap.entries.toList();
    final drawer = Drawer(
        elevation: 8,
        child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(0),
            itemCount: group.length + 1,
            itemBuilder: (ctx, i) {
              final index = i - 1;
              if (index < 0) return _buildHeader(controller);
              final groupItem = group[index];
              return ExpansionTile(
                leading: Icon(
                  _getIconDataByType(groupItem.key),
                  size: 32,
                ),
                initiallyExpanded: controller.expandState[index] ?? false,
                onExpansionChanged: (isExpand) =>
                    controller.expandState[index] = isExpand,
                title: Text(groupItem.key.toUpperCase(),
                    style: const TextStyle(fontSize: 18)),
                children: List.generate(groupItem.value.length, (index) {
                  final site = groupItem.value[index];
                  return ListTile(
                    dense: true,
                    contentPadding: const EdgeInsets.only(left: 32),
                    onTap: () => onItemTap?.call(site),
                    leading: SizedBox(
                        width: 32,
                        height: 32,
                        child: Material(
                            borderRadius: BorderRadius.circular(8),
                            clipBehavior: Clip.hardEdge,
                            child: SimpleNetworkImage(
                              site.icon ?? '',
                              fit: BoxFit.cover,
                              error: const Icon(Icons.image_not_supported,
                                  size: 32),
                            ))),
                    title: Text(
                      site.name ?? '',
                      style: const TextStyle(
                          fontFamily: AppConfig.uiFontFamily,
                          fontSize: 18,
                          fontWeight: FontWeight.bold),
                      textAlign: TextAlign.start,
                      maxLines: 1,
                      softWrap: false,
                      overflow: TextOverflow.fade,
                    ),
                    subtitle: Text(
                      site.details ?? '',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style:
                          const TextStyle(fontSize: 12, color: Colors.black26),
                    ),
                  );
                }),
              );
            }));
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      if (_scrollController.positions.isNotEmpty) {
        _scrollController.jumpTo(controller.scrollPosition.value);
        _scrollController.addListener(() {
          controller.scrollPosition.value = _scrollController.position.pixels;
        });
      }
    });
    return drawer;
  }

  Widget _buildHeader(_NyaaEndController controller) {
    return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Material(
            elevation: 4,
            child: Obx(() => controller.banner.value.isNotEmpty
                    ? SimpleNetworkImage(controller.banner.value,
                        animationDuration: Duration.zero,
                        fit: BoxFit.cover, height: 160 + kToolbarHeight)
                    : Container(height: 160 + kToolbarHeight))));
  }
}
