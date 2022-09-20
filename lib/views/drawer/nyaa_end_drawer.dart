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

import 'package:flutter/material.dart';

import '../../app/config.dart';
import '../../library/mio/model/site.dart';
import '../../widget/simple_network_image.dart';

class NyaaEndDrawer extends StatelessWidget {
  const NyaaEndDrawer({Key? key, required this.sites, required this.onItemTap})
      : super(key: key);
  final List<Site> sites;
  final void Function(Site site)? onItemTap;

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
    return Drawer(
        elevation: 8,
        child: ListView.builder(
            padding: const EdgeInsets.all(0),
            itemCount: group.length + 1,
            itemBuilder: (ctx, i) {
              final index = i - 1;
              if (index < 0) return _buildHeader();
              final groupItem = group[index];
              return ExpansionTile(
                leading: Icon(
                  _getIconDataByType(groupItem.key),
                  size: 32,
                ),
                title: Text('${groupItem.key}s'.toUpperCase(),
                    style: const TextStyle(fontSize: 16)),
                children: List.generate(groupItem.value.length, (index) {
                  final site = groupItem.value[index];
                  return ListTile(
                    dense: true,
                    contentPadding: const EdgeInsets.only(left: 32, right: 8),
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
                          fontFamily: Config.uiFontFamily,
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
                          const TextStyle(fontSize: 14, color: Colors.black26),
                    ),
                  );
                }),
              );
            }));
  }

  Widget _buildHeader() {
    return const Padding(
        padding: EdgeInsets.only(bottom: 8),
        child: Material(
            elevation: 4,
            child: SimpleNetworkImage(
              'https://cdn.jsdelivr.net/gh/nyarray/LoliHost/images/7c4f1d7ea2dadd3ca835b9b2b9219681.webp',
              fit: BoxFit.cover,
              height: 160 + kToolbarHeight,
            )));
  }
}
