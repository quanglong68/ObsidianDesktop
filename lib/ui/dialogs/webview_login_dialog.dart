import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

import '../../providers/app_provider.dart';
import 'flm_sync_dialog.dart';

class WebViewLoginDialog extends StatefulWidget {
  final AppProvider provider;

  const WebViewLoginDialog({super.key, required this.provider});

  @override
  State<WebViewLoginDialog> createState() => _WebViewLoginDialogState();
}

class _WebViewLoginDialogState extends State<WebViewLoginDialog> {
  bool _isLoading = true;
  InAppWebViewController? webViewController;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF1E293B),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: const BorderSide(color: Colors.cyanAccent),
      ),
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "1. Đăng nhập FLM",
                style: TextStyle(
                  color: Colors.cyanAccent,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                "(Hệ thống tự động ghi nhớ tài khoản)",
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
          TextButton.icon(
            style: TextButton.styleFrom(
              backgroundColor: Colors.redAccent.withOpacity(0.1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            icon: const Icon(Icons.logout, color: Colors.redAccent, size: 18),
            label: const Text(
              "Đăng xuất / Đổi User",
              style: TextStyle(
                color: Colors.redAccent,
                fontWeight: FontWeight.bold,
              ),
            ),
            onPressed: () async {
              CookieManager cookieManager = CookieManager.instance();
              await cookieManager.deleteAllCookies();
              if (webViewController != null) {
                webViewController!.loadUrl(
                  urlRequest: URLRequest(
                    url: WebUri("https://flm.fpt.edu.vn/"),
                  ),
                );
              }
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Đã xóa phiên đăng nhập cũ!")),
                );
              }
            },
          ),
        ],
      ),
      content: SizedBox(
        width: 1000,
        height: 600,
        child: Stack(
          children: [
            InAppWebView(
              initialUrlRequest: URLRequest(
                url: WebUri("https://flm.fpt.edu.vn/"),
              ),
              onWebViewCreated: (controller) {
                webViewController = controller;
              },
              onLoadStop: (controller, url) {
                setState(() {
                  _isLoading = false;
                });
              },
            ),
            if (_isLoading)
              const Center(
                child: CircularProgressIndicator(color: Colors.cyanAccent),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Hủy bỏ", style: TextStyle(color: Colors.grey)),
        ),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF064E3B),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          ),
          icon: const Icon(Icons.arrow_forward, color: Colors.cyanAccent),
          label: const Text(
            "TIẾP TỤC CHỌN MÃ CHƯƠNG TRÌNH",
            style: TextStyle(
              color: Colors.cyanAccent,
              fontWeight: FontWeight.bold,
            ),
          ),
          onPressed: () async {
            try {
              CookieManager cookieManager = CookieManager.instance();
              List<Cookie> cookies = await cookieManager.getCookies(
                url: WebUri("https://flm.fpt.edu.vn/"),
              );
              String cookieStr = cookies
                  .map((c) => "${c.name}=${c.value}")
                  .join("; ");

              await widget.provider.saveFlmCookie(cookieStr);
              if (context.mounted) {
                Navigator.pop(context);
                showFlmSyncDialog(context, widget.provider);
              }
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text("Lỗi lấy Cookie: $e")));
              }
            }
          },
        ),
      ],
    );
  }
}

// ĐÂY LÀ HÀM MÀ SIDEBAR ĐANG TÌM KIẾM
void showWebViewLoginDialog(BuildContext context, AppProvider provider) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => WebViewLoginDialog(provider: provider),
  );
}
