import 'dart:convert';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:nai_casrand/data/models/template_model.dart';

/// 模板卡片
class TemplateCard extends StatelessWidget {
  final Template template;
  final VoidCallback onTap;
  final VoidCallback onFavoriteToggle;
  
  const TemplateCard({
    super.key,
    required this.template,
    required this.onTap,
    required this.onFavoriteToggle,
  });
  
  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 模板图片
            Stack(
              children: [
                if (template.imageB64.isNotEmpty)
                  Image.memory(
                    base64Decode(template.imageB64),
                    height: 150,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  )
                else
                  Container(
                    height: 150,
                    width: double.infinity,
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                    child: Icon(
                      _getIconForTemplateType(template.type),
                      size: 64,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                // 类型标签
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      tr('template_type_${template.type.name}'),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                // 内置标签
                if (template.isBuiltIn)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        tr('built_in'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            // 模板信息
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 标题和收藏按钮
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          template.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          template.isFavorite 
                              ? Icons.favorite 
                              : Icons.favorite_border,
                          color: template.isFavorite 
                              ? Colors.red 
                              : null,
                        ),
                        onPressed: onFavoriteToggle,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  // 描述
                  Text(
                    template.description,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                      fontSize: 12,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  // 创建时间
                  Text(
                    DateFormat.yMMMd().format(template.createdAt),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  /// 根据模板类型获取图标
  IconData _getIconForTemplateType(TemplateType type) {
    switch (type) {
      case TemplateType.character:
        return Icons.person;
      case TemplateType.scene:
        return Icons.landscape;
      case TemplateType.style:
        return Icons.brush;
      case TemplateType.custom:
        return Icons.category;
      default:
        return Icons.description;
    }
  }
}
