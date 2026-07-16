import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';
import 'devtools_panel.dart';

class BrowserWorkspace extends StatefulWidget {
  const BrowserWorkspace({super.key});

  @override
  State<BrowserWorkspace> createState() => _BrowserWorkspaceState();
}

class _BrowserWorkspaceState extends State<BrowserWorkspace> {
  late final WebViewController _controller;
  final TextEditingController _urlController = TextEditingController(text: 'https://flutter.dev');
  bool _isLoading = true;
  double _progress = 0;
  
  // DevTools states
  List<String> _consoleLogs = [];
  String _pageSource = '';
  List<Map<String, dynamic>> _networkRequests = [];
  Map<String, String> _cookies = {};
  Map<String, String> _localStorage = {};
  bool _isDevToolsMinimized = true;

  @override
  void initState() {
    super.initState();
    if (!kIsWeb && Platform.isMacOS) {
      WebViewPlatform.instance = WebKitWebViewPlatform();
    }

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFF1E1E1E))
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            if (!mounted) return;
            setState(() {
              _progress = progress / 100;
            });
          },
          onPageStarted: (String url) {
            if (!mounted) return;
            setState(() {
              _isLoading = true;
              _urlController.text = (url.startsWith('data:text/html') || url == 'about:blank') ? 'rpl://browser' : url;
              _consoleLogs.clear();
              _networkRequests.add({
                'url': url,
                'method': 'GET',
                'status': 'Pending',
                'time': DateTime.now().toString(),
              });
            });
          },
          onPageFinished: (String url) async {
            if (!mounted) return;
            setState(() {
              _isLoading = false;
              if (_networkRequests.isNotEmpty) {
                _networkRequests.last['status'] = '200 OK';
              }
            });
            _extractDevToolsData();
          },
          onWebResourceError: (WebResourceError error) {
            if (!mounted) return;
            setState(() {
              _isLoading = false;
              _consoleLogs.add('[ERROR] ${error.description}');
            });
          },
        ),
      )
      ..addJavaScriptChannel(
        'ConsoleChannel',
        onMessageReceived: (JavaScriptMessage message) {
          if (!mounted) return;
          setState(() {
            _consoleLogs.add(message.message);
          });
        },
      )
      ..loadHtmlString(_getDefaultHtml());
  }

  Future<void> _extractDevToolsData() async {
    try {
      // Inject console override to capture logs
      await _controller.runJavaScript('''
        if (!window._consoleOverridden) {
          window._consoleOverridden = true;
          const oldLog = console.log;
          const oldError = console.error;
          const oldWarn = console.warn;
          console.log = function(...args) {
            ConsoleChannel.postMessage('[LOG] ' + args.join(' '));
            oldLog.apply(console, args);
          };
          console.error = function(...args) {
            ConsoleChannel.postMessage('[ERROR] ' + args.join(' '));
            oldError.apply(console, args);
          };
          console.warn = function(...args) {
            ConsoleChannel.postMessage('[WARN] ' + args.join(' '));
            oldWarn.apply(console, args);
          };
        }
      ''');

      // Get page source
      final html = await _controller.runJavaScriptReturningResult('document.documentElement.outerHTML');
      setState(() {
        _pageSource = html.toString();
      });

      // Get cookies
      final cookiesStr = await _controller.runJavaScriptReturningResult('document.cookie');
      if (cookiesStr != null && cookiesStr.toString() != '""' && cookiesStr.toString().isNotEmpty) {
        final Map<String, String> parsedCookies = {};
        final parts = cookiesStr.toString().replaceAll('"', '').split(';');
        for (var part in parts) {
          if (part.contains('=')) {
            final kv = part.split('=');
            parsedCookies[kv[0].trim()] = kv[1].trim();
          }
        }
        setState(() {
          _cookies = parsedCookies;
        });
      }

      // Get local storage
      final lsStr = await _controller.runJavaScriptReturningResult('JSON.stringify(localStorage)');
      if (lsStr != null && lsStr.toString() != '""' && lsStr.toString() != '{}') {
        // Simplified parsing for mockup
        setState(() {
          _localStorage = {'data': lsStr.toString()};
        });
      }
    } catch (e) {
      debugPrint('Failed to extract devtools data: $e');
    }
  }

  void _loadUrl(String url) {
    url = url.trim();
    if (url.isEmpty) return;
    if (url == 'rpl://browser') {
      _controller.loadHtmlString(_getDefaultHtml());
      FocusScope.of(context).unfocus();
      return;
    }
    
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      if (url.contains('.') && !url.contains(' ')) {
        url = 'https://$url';
      } else {
        url = 'https://www.google.com/search?q=${Uri.encodeComponent(url)}';
      }
    }
    _controller.loadRequest(Uri.parse(url));
    FocusScope.of(context).unfocus();
  }

  String _getDefaultHtml() {
    return '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>RPL Browser</title>
  <style>
    body {
      background-color: #1e1e1e;
      color: #ffffff;
      font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
      display: flex;
      flex-direction: column;
      align-items: center;
      justify-content: center;
      height: 100vh;
      margin: 0;
      overflow: hidden;
    }
    .container {
      text-align: center;
      animation: fadeIn 0.8s ease-out;
    }
    @keyframes fadeIn {
      from { opacity: 0; transform: translateY(15px); }
      to { opacity: 1; transform: translateY(0); }
    }
    .logo-container {
      margin-bottom: 12px;
      display: flex;
      flex-direction: column;
      align-items: center;
    }
    .rakoda-logo {
      width: 54px;
      height: auto;
      margin-bottom: 16px;
      filter: drop-shadow(0 0 12px rgba(37, 104, 231, 0.5));
      animation: logoPulse 2s infinite alternate;
    }
    @keyframes logoPulse {
      from { transform: scale(1); filter: drop-shadow(0 0 10px rgba(37, 104, 231, 0.4)); }
      to { transform: scale(1.05); filter: drop-shadow(0 0 18px rgba(37, 104, 231, 0.7)); }
    }
    .logo-text {
      font-size: 48px;
      font-weight: 900;
      letter-spacing: 6px;
      color: #007acc;
      text-shadow: 0 0 20px rgba(0, 122, 204, 0.4);
      margin: 0;
      background: linear-gradient(135deg, #2568e7, #00bfff);
      -webkit-background-clip: text;
      -webkit-text-fill-color: transparent;
    }
    .sub-logo {
      font-size: 13px;
      color: #858585;
      letter-spacing: 5px;
      text-transform: uppercase;
      margin-top: 8px;
      font-weight: 600;
    }
    .title {
      font-size: 18px;
      color: #cccccc;
      margin-bottom: 36px;
      font-weight: 300;
    }
    .search-box {
      display: flex;
      width: 85%;
      max-width: 520px;
      margin: 0 auto;
      background-color: #252526;
      border: 1px solid #3c3c3c;
      border-radius: 28px;
      padding: 10px 20px;
      box-shadow: 0 8px 16px rgba(0, 0, 0, 0.2);
      transition: all 0.3s;
    }
    .search-box:hover {
      border-color: #555555;
      box-shadow: 0 8px 24px rgba(0, 0, 0, 0.3);
    }
    .search-box:focus-within {
      border-color: #007acc;
      box-shadow: 0 8px 24px rgba(0, 122, 204, 0.2);
    }
    .search-input {
      flex: 1;
      background: none;
      border: none;
      color: #ffffff;
      font-size: 15px;
      outline: none;
    }
    .search-button {
      background: none;
      border: none;
      color: #858585;
      cursor: pointer;
      outline: none;
      font-size: 16px;
      transition: color 0.2s;
    }
    .search-button:hover {
      color: #ffffff;
    }
    .shortcuts {
      display: flex;
      gap: 32px;
      margin-top: 50px;
      justify-content: center;
    }
    .shortcut-item {
      display: flex;
      flex-direction: column;
      align-items: center;
      color: #aaaaaa;
      text-decoration: none;
      font-size: 12px;
      transition: all 0.2s;
      width: 70px;
    }
    .shortcut-item:hover {
      color: #007acc;
      transform: translateY(-2px);
    }
    .shortcut-icon {
      width: 52px;
      height: 52px;
      background-color: #252526;
      border: 1px solid #3c3c3c;
      border-radius: 16px;
      display: flex;
      align-items: center;
      justify-content: center;
      margin-bottom: 10px;
      font-size: 22px;
      transition: all 0.2s;
      box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1);
    }
    .shortcut-item:hover .shortcut-icon {
      background-color: #2d2d2d;
      border-color: #007acc;
      box-shadow: 0 6px 12px rgba(0, 122, 204, 0.15);
    }
  </style>
</head>
<body>
  <div class="container">
    <div class="logo-container">
      <svg class="rakoda-logo" viewBox="0 0 344 464" fill="none" xmlns="http://www.w3.org/2000/svg">
        <rect width="104" height="104" rx="52" fill="#2568E7"/>
        <rect width="104" height="104" fill="#2568E7"/>
        <rect y="120" width="104" height="104" rx="52" fill="#2568E7"/>
        <rect y="120" width="104" height="104" fill="#2568E7"/>
        <rect y="240" width="104" height="104" rx="52" fill="#2568E7"/>
        <rect y="240" width="104" height="104" fill="#2568E7"/>
        <rect x="120" y="240" width="104" height="104" rx="52" fill="#2568E7"/>
        <rect x="120" y="240" width="104" height="104" fill="#2568E7"/>
        <rect x="120" width="104" height="104" rx="52" fill="#2568E7"/>
        <rect x="120" width="104" height="104" fill="#2568E7"/>
        <rect x="240" y="360" width="104" height="104" rx="52" fill="#2568E7"/>
        <rect x="240" y="360" width="104" height="104" fill="#2568E7"/>
        <rect x="240" y="120" width="104" height="104" rx="52" fill="#2568E7"/>
        <rect x="240" y="120" width="104" height="104" fill="#2568E7"/>
        <rect y="360" width="104" height="104" rx="52" fill="#2568E7"/>
        <rect y="360" width="104" height="104" fill="#2568E7"/>
      </svg>
      <h1 class="logo-text">RPL STUDIO</h1>
    </div>
    <div class="title">RPL Browser</div>
    <form class="search-box" action="https://www.google.com/search" method="get">
      <input class="search-input" type="text" name="q" placeholder="Cari di Google atau ketik URL..." required autocomplete="off">
      <button class="search-button" type="submit">🔍</button>
    </form>
    <div class="shortcuts">
      <a class="shortcut-item" href="https://www.google.com/search?q=Indonesia">
        <div class="shortcut-icon">🇮🇩</div>
        <span>Indonesia</span>
      </a>
      <a class="shortcut-item" href="https://www.google.com/search?q=Belajar+Coding+Pemula">
        <div class="shortcut-icon">🌱</div>
        <span>Beginner</span>
      </a>
      <a class="shortcut-item" href="https://www.google.com/search?q=RPL+Studio">
        <div class="shortcut-icon">❤️</div>
        <span>Love</span>
      </a>
    </div>
  </div>
</body>
</html>
''';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Address Bar
        Container(
          height: 48,
          color: const Color(0xFF333333),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, size: 20, color: Colors.white70),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32),
                onPressed: () => _controller.goBack(),
              ),
              IconButton(
                icon: const Icon(Icons.arrow_forward, size: 20, color: Colors.white70),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32),
                onPressed: () => _controller.goForward(),
              ),
              IconButton(
                icon: const Icon(Icons.refresh, size: 20, color: Colors.white70),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32),
                onPressed: () => _controller.reload(),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF252526),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFF434343)),
                  ),
                  child: TextField(
                    controller: _urlController,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    decoration: const InputDecoration(
                      filled: false,
                      hintText: 'Cari atau masukkan alamat website...',
                      hintStyle: TextStyle(color: Colors.white38),
                      border: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      isDense: true,
                    ),
                    onSubmitted: _loadUrl,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (_isLoading)
          LinearProgressIndicator(
            value: _progress,
            backgroundColor: Colors.transparent,
            color: const Color(0xFF007ACC),
            minHeight: 2,
          ),
        
        // Split View: Webview & DevTools
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 800;
              return Flex(
                direction: isWide ? Axis.horizontal : Axis.vertical,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Browser View
                  Expanded(
                    flex: 3,
                    child: WebViewWidget(controller: _controller),
                  ),
                  Container(
                    width: isWide ? 1 : null,
                    height: isWide ? null : 1,
                    color: const Color(0xFF333333),
                  ),
                  // DevTools View
                  if (_isDevToolsMinimized)
                    SizedBox(
                      width: isWide ? 40 : double.infinity, // Minimal width if horizontal split
                      height: isWide ? double.infinity : 35,
                      child: DevToolsPanel(
                        isMinimized: true,
                        onToggleMinimize: () => setState(() => _isDevToolsMinimized = false),
                        pageSource: _pageSource,
                        consoleLogs: _consoleLogs,
                        networkRequests: _networkRequests,
                        cookies: _cookies,
                        localStorage: _localStorage,
                        onExecuteJS: (code) async {},
                      ),
                    )
                  else
                    Expanded(
                      flex: 2,
                      child: DevToolsPanel(
                        isMinimized: false,
                        onToggleMinimize: () => setState(() => _isDevToolsMinimized = true),
                        pageSource: _pageSource,
                        consoleLogs: _consoleLogs,
                        networkRequests: _networkRequests,
                        cookies: _cookies,
                        localStorage: _localStorage,
                        onExecuteJS: (code) async {
                          try {
                            final result = await _controller.runJavaScriptReturningResult(code);
                            if (mounted) {
                              setState(() {
                                _consoleLogs.add('> $code');
                                _consoleLogs.add('< $result');
                              });
                            }
                          } catch (e) {
                            if (mounted) {
                              setState(() {
                                _consoleLogs.add('> $code');
                                _consoleLogs.add('[ERROR] $e');
                              });
                            }
                          }
                        },
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}
