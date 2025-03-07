import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';

/// 导入模板对话框
class ImportTemplateDialog extends StatefulWidget {
  final Function(String) onImportTemplate;

  const ImportTemplateDialog({Key? key, required this.onImportTemplate}) : super(key: key);

  @override
  State<ImportTemplateDialog> createState() => _ImportTemplateDialogState();
}

class _ImportTemplateDialogState extends State<ImportTemplateDialog> {
  final TextEditingController _shareCodeController = TextEditingController();
  bool _isCodeValid = false;

  @override
  void initState() {
    super.initState();
    _shareCodeController.addListener(_validateShareCode);
  }

  @override
  void dispose() {
    _shareCodeController.removeListener(_validateShareCode);
    _shareCodeController.dispose();
    super.dispose();
  }

  /// 验证分享码是否有效
  void _validateShareCode() {
    setState(() {
      // 最简单的验证：检查是否是Base64字符串
      _isCodeValid = _shareCodeController.text.trim().isNotEmpty &&
          RegExp(r'^[A-Za-z0-9+/=]+$').hasMatch(_shareCodeController.text.trim());
    });
  }

  /// 从剪贴板粘贴
  Future<void> _pasteFromClipboard() async {
    final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
    if (clipboardData != null && clipboardData.text != null) {
      _shareCodeController.text = clipboardData.text!.trim();
    }
  }

  /// 扫描二维码
  Future<void> _scanQRCode() async {
    try {
      String barcodeScanRes = await FlutterBarcodeScanner.scanBarcode(
        '#ff6666', 
        tr('cancel'), 
        true, 
        ScanMode.QR,
      );
      
      if (barcodeScanRes != '-1') { // -1 表示取消扫描
        _shareCodeController.text = barcodeScanRes.trim();
      }
    } catch (e) {
      // 显示扫描错误
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr('qr_scan_failed'))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 标题
            Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: Text(
                tr('import_template'),
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
            ),
            
            // 分享码输入框
            TextField(
              controller: _shareCodeController,
              decoration: InputDecoration(
                labelText: tr('share_code'),
                hintText: tr('paste_share_code_here'),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixIcon: const Icon(Icons.code),
              ),
              maxLines: 3,
            ),
            
            // 操作按钮
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // 粘贴按钮
                  ElevatedButton.icon(
                    onPressed: _pasteFromClipboard,
                    icon: const Icon(Icons.paste),
                    label: Text(tr('paste')),
                  ),
                  
                  // 扫描按钮
                  ElevatedButton.icon(
                    onPressed: _scanQRCode,
                    icon: const Icon(Icons.qr_code_scanner),
                    label: Text(tr('scan')),
                  ),
                ],
              ),
            ),
            
            // 导入说明
            Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: Text(
                tr('import_template_hint'),
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ),
            
            // 底部按钮
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(tr('cancel')),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _isCodeValid 
                      ? () => widget.onImportTemplate(_shareCodeController.text.trim())
                      : null,
                  child: Text(tr('import')),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
