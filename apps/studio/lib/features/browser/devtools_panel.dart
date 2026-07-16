import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:html/dom.dart' as html_dom;

class DevToolsPanel extends StatefulWidget {
  final String pageSource;
  final List<String> consoleLogs;
  final List<Map<String, dynamic>> networkRequests;
  final Map<String, String> cookies;
  final Map<String, String> localStorage;
  final Function(String) onExecuteJS;
  final VoidCallback? onClearConsole;
  final VoidCallback? onClearNetwork;
  final Function(String, String)? onUpdateCookie;
  final Function(String)? onDeleteCookie;
  final Function(String, String)? onUpdateLocalStorage;
  final Function(String)? onDeleteLocalStorage;

  final bool isMinimized;
  final VoidCallback onToggleMinimize;

  const DevToolsPanel({
    super.key,
    required this.isMinimized,
    required this.onToggleMinimize,
    required this.pageSource,
    required this.consoleLogs,
    required this.networkRequests,
    required this.cookies,
    required this.localStorage,
    required this.onExecuteJS,
    this.onClearConsole,
    this.onClearNetwork,
    this.onUpdateCookie,
    this.onDeleteCookie,
    this.onUpdateLocalStorage,
    this.onDeleteLocalStorage,
  });

  @override
  State<DevToolsPanel> createState() => _DevToolsPanelState();
}

class _DevToolsPanelState extends State<DevToolsPanel> {
  // Edit states for Application tab
  String? _editingCookieKey;
  final TextEditingController _editCookieValController =
      TextEditingController();

  String? _editingLocalStorageKey;
  final TextEditingController _editLocalStorageValController =
      TextEditingController();

  bool _addingCookie = false;
  final TextEditingController _newCookieKeyController = TextEditingController();
  final TextEditingController _newCookieValController = TextEditingController();

  bool _addingLocalStorage = false;
  final TextEditingController _newLocalStorageKeyController =
      TextEditingController();
  final TextEditingController _newLocalStorageValController =
      TextEditingController();
  String _formatJson(dynamic raw) {
    if (raw == null) return '';
    final rawStr = raw.toString().trim();
    try {
      final decoded = jsonDecode(rawStr);
      return const JsonEncoder.withIndent('  ').convert(decoded);
    } catch (_) {
      return rawStr;
    }
  }

  int _activeTabIndex = 0;
  final TextEditingController _consoleInputController = TextEditingController();
  String _activeNetworkFilter = 'All';
  Map<String, dynamic>? _selectedNetworkRequest;
  String _activeNetworkDetailTab = 'Headers';

  final List<String> _tabs = ['Elements', 'Console', 'Network', 'Application'];
  final List<String> _networkFilters = [
    'All',
    'Fetch/XHR',
    'Doc',
    'CSS',
    'JS',
    'Img',
    'Media',
  ];
  final List<String> _networkDetailTabs = ['Headers', 'Payload', 'Response'];

  @override
  void dispose() {
    _consoleInputController.dispose();
    _editCookieValController.dispose();
    _editLocalStorageValController.dispose();
    _newCookieKeyController.dispose();
    _newCookieValController.dispose();
    _newLocalStorageKeyController.dispose();
    _newLocalStorageValController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF1E1E1E),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GestureDetector(
            onTap: widget.onToggleMinimize,
            behavior: HitTestBehavior.opaque,
            child: Container(
              height: 35,
              color: const Color(0xFF252526),
              child: Row(
                children: [
                  if (!widget.isMinimized)
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: _tabs.asMap().entries.map((entry) {
                            final idx = entry.key;
                            final title = entry.value;
                            final isActive = _activeTabIndex == idx;
                            return InkWell(
                              onTap: () =>
                                  setState(() => _activeTabIndex = idx),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                                decoration: BoxDecoration(
                                  border: Border(
                                    top: BorderSide(
                                      color: isActive
                                          ? const Color(0xFF007ACC)
                                          : Colors.transparent,
                                      width: 2,
                                    ),
                                    right: const BorderSide(
                                      color: Color(0xFF333333),
                                    ),
                                  ),
                                  color: isActive
                                      ? const Color(0xFF1E1E1E)
                                      : Colors.transparent,
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  title,
                                  style: TextStyle(
                                    color: isActive
                                        ? Colors.white
                                        : Colors.white54,
                                    fontSize: 11,
                                    fontWeight: isActive
                                        ? FontWeight.w500
                                        : FontWeight.normal,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  if (widget.isMinimized) ...[
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        'DevTools',
                        style: TextStyle(
                          color: Colors.white54,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const Spacer(),
                  ],
                  InkWell(
                    onTap: widget.onToggleMinimize,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      alignment: Alignment.center,
                      child: Icon(
                        widget.isMinimized
                            ? Icons.keyboard_arrow_up
                            : Icons.keyboard_arrow_down,
                        size: 16,
                        color: Colors.white54,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Tab Content
          if (!widget.isMinimized)
            Expanded(
              child: IndexedStack(
                index: _activeTabIndex,
                children: [
                  _buildElementsTab(),
                  _buildConsoleTab(),
                  _buildNetworkTab(),
                  _buildApplicationTab(),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildElementsTab() {
    if (widget.pageSource.isEmpty) {
      return const Center(
        child: Text(
          '<html>...</html> (Loading or empty)',
          style: TextStyle(color: Colors.white38, fontSize: 12),
        ),
      );
    }

    try {
      final document = html_parser.parse(widget.pageSource);
      return SingleChildScrollView(
        padding: const EdgeInsets.all(8),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: document.nodes
                .map((n) => DomNodeViewer(node: n))
                .toList(),
          ),
        ),
      );
    } catch (e) {
      return Center(
        child: Text(
          'Error parsing HTML: $e',
          style: const TextStyle(color: Colors.redAccent),
        ),
      );
    }
  }

  Widget _buildConsoleTab() {
    return Column(
      children: [
        Container(
          height: 28,
          color: const Color(0xFF252526),
          padding: const EdgeInsets.symmetric(horizontal: 8),
          alignment: Alignment.centerLeft,
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.block, size: 14, color: Colors.white54),
                tooltip: 'Clear console',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: widget.onClearConsole,
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: Color(0xFF333333)),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: widget.consoleLogs.length,
            itemBuilder: (context, index) {
              final log = widget.consoleLogs[index];
              Color textColor = const Color(0xFFD4D4D4);
              IconData? icon;
              Color iconColor = Colors.transparent;

              if (log.startsWith('[ERROR]')) {
                textColor = const Color(0xFFF48771);
                icon = Icons.cancel;
                iconColor = const Color(0xFFF48771);
              } else if (log.startsWith('[WARN]')) {
                textColor = const Color(0xFFCCA700);
                icon = Icons.warning;
                iconColor = const Color(0xFFCCA700);
              } else if (log.startsWith('> ')) {
                textColor = const Color(0xFF9CDCFE);
                icon = Icons.chevron_right;
                iconColor = const Color(0xFF9CDCFE);
              } else if (log.startsWith('< ')) {
                textColor = const Color(0xFFD4D4D4);
                icon = Icons.arrow_back;
                iconColor = Colors.white54;
              }

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (icon != null) ...[
                      Icon(icon, size: 14, color: iconColor),
                      const SizedBox(width: 8),
                    ],
                    Expanded(
                      child: SelectableText(
                        log,
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12,
                          color: textColor,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        const Divider(height: 1, color: Color(0xFF333333)),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            children: [
              const Icon(
                Icons.chevron_right,
                size: 16,
                color: Color(0xFF007ACC),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _consoleInputController,
                  cursorColor: Colors.white,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                    color: Colors.white,
                  ),
                  decoration: const InputDecoration(
                    hintText: 'Enter JavaScript code...',
                    hintStyle: TextStyle(color: Colors.white38),
                    border: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    isDense: true,
                    fillColor: Colors.transparent,
                    filled: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 12),
                  ),
                  onSubmitted: (val) {
                    if (val.trim().isNotEmpty) {
                      widget.onExecuteJS(val);
                      _consoleInputController.clear();
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNetworkTab() {
    final filteredRequests = widget.networkRequests.where((req) {
      if (_activeNetworkFilter == 'All') return true;
      final url = (req['url'] as String? ?? '').toLowerCase();
      if (_activeNetworkFilter == 'Doc')
        return url.endsWith('.html') ||
            url.endsWith('.htm') ||
            (!url.contains('.') && !url.contains('localhost'));
      if (_activeNetworkFilter == 'CSS') return url.endsWith('.css');
      if (_activeNetworkFilter == 'JS') return url.endsWith('.js');
      if (_activeNetworkFilter == 'Img')
        return url.endsWith('.png') ||
            url.endsWith('.jpg') ||
            url.endsWith('.jpeg') ||
            url.endsWith('.gif') ||
            url.endsWith('.svg') ||
            url.endsWith('.webp');
      if (_activeNetworkFilter == 'Media')
        return url.endsWith('.mp4') ||
            url.endsWith('.mp3') ||
            url.endsWith('.wav') ||
            url.endsWith('.webm') ||
            url.endsWith('.ogg');
      if (_activeNetworkFilter == 'Fetch/XHR')
        return url.contains('/api/') || url.contains('/graphql');
      return true;
    }).toList();

    final mainList = Column(
      children: [
        Container(
          height: 30,
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: Color(0xFF333333))),
          ),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.block, size: 14, color: Colors.white54),
                tooltip: 'Clear network log',
                padding: const EdgeInsets.symmetric(horizontal: 12),
                constraints: const BoxConstraints(),
                onPressed: () {
                  if (widget.onClearNetwork != null) widget.onClearNetwork!();
                  setState(() {
                    _selectedNetworkRequest = null;
                  });
                },
              ),
              Container(width: 1, height: 20, color: const Color(0xFF333333)),
              Expanded(
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _networkFilters.length,
                  itemBuilder: (context, index) {
                    final filter = _networkFilters[index];
                    final isActive = _activeNetworkFilter == filter;
                    return InkWell(
                      onTap: () => setState(() {
                        _activeNetworkFilter = filter;
                        _selectedNetworkRequest = null;
                      }),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        alignment: Alignment.center,
                        child: Text(
                          filter,
                          style: TextStyle(
                            color: isActive ? Colors.white : Colors.white54,
                            fontSize: 11,
                            fontWeight: isActive
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: filteredRequests.isEmpty
              ? const Center(
                  child: Text(
                    'No requests found',
                    style: TextStyle(color: Colors.white38),
                  ),
                )
              : ListView.separated(
                  itemCount: filteredRequests.length + 1,
                  separatorBuilder: (context, index) =>
                      const Divider(height: 1, color: Color(0xFF333333)),
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          children: const [
                            Expanded(
                              flex: 3,
                              child: Text(
                                'Name',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 1,
                              child: Text(
                                'Method',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 1,
                              child: Text(
                                'Status',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    final req = filteredRequests[index - 1];
                    final status = req['status']?.toString() ?? '';
                    final isError =
                        !status.startsWith('2') && status != 'Pending';
                    final isSelected = _selectedNetworkRequest == req;

                    return InkWell(
                      onTap: () =>
                          setState(() => _selectedNetworkRequest = req),
                      child: Container(
                        color: isSelected
                            ? const Color(0xFF094771)
                            : Colors.transparent,
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: Text(
                                req['url']?.split('/').last.isEmpty
                                    ? req['url'] ?? ''
                                    : req['url']?.split('/').last ?? '',
                                style: TextStyle(
                                  color: isError
                                      ? const Color(0xFFF48771)
                                      : Colors.white,
                                  fontSize: 12,
                                  fontFamily: 'monospace',
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Expanded(
                              flex: 1,
                              child: Text(
                                req['method'] ?? '',
                                style: const TextStyle(
                                  color: Colors.white54,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 1,
                              child: Text(
                                req['status'] ?? '',
                                style: TextStyle(
                                  color: isError
                                      ? const Color(0xFFF48771)
                                      : Colors.white54,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        if (_selectedNetworkRequest == null) {
          return mainList;
        }

        if (constraints.maxWidth < 600) {
          return _buildNetworkDetailPanel();
        }

        return Row(
          children: [
            Expanded(flex: 1, child: mainList),
            Container(width: 1, color: const Color(0xFF333333)),
            Expanded(flex: 1, child: _buildNetworkDetailPanel()),
          ],
        );
      },
    );
  }

  Widget _buildNetworkDetailPanel() {
    final req = _selectedNetworkRequest!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          height: 30,
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: Color(0xFF333333))),
          ),
          child: Row(
            children: [
              InkWell(
                onTap: () => setState(() => _selectedNetworkRequest = null),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Icon(Icons.close, size: 16, color: Colors.white54),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _networkDetailTabs.length,
                  itemBuilder: (context, index) {
                    final tab = _networkDetailTabs[index];
                    final isActive = _activeNetworkDetailTab == tab;
                    return InkWell(
                      onTap: () =>
                          setState(() => _activeNetworkDetailTab = tab),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: isActive
                                  ? const Color(0xFF007ACC)
                                  : Colors.transparent,
                              width: 2,
                            ),
                          ),
                        ),
                        child: Text(
                          tab,
                          style: TextStyle(
                            color: isActive ? Colors.white : Colors.white54,
                            fontSize: 11,
                            fontWeight: isActive
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(12),
            child: _buildNetworkDetailContent(req),
          ),
        ),
      ],
    );
  }

  Widget _buildNetworkDetailContent(Map<String, dynamic> req) {
    if (_activeNetworkDetailTab == 'Headers') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'General',
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          _buildDetailRow('Request URL:', req['url'] ?? ''),
          _buildDetailRow('Request Method:', req['method'] ?? ''),
          _buildDetailRow('Status Code:', req['status'] ?? ''),
          const SizedBox(height: 16),
          const Text(
            'Response Headers',
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          _buildDetailRow(
            'content-type:',
            req['response_content_type'] ?? 'text/html; charset=utf-8',
          ),
          _buildDetailRow('server:', 'rpl-server'),
          const SizedBox(height: 16),
          const Text(
            'Request Headers',
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          _buildDetailRow('user-agent:', 'Mozilla/5.0 (RPL Studio)'),
          _buildDetailRow('accept:', '*/*'),
        ],
      );
    } else if (_activeNetworkDetailTab == 'Payload') {
      final payload = req['payload'];
      if (payload == null || payload.toString().isEmpty) {
        return const Center(
          child: Text(
            'No payload',
            style: TextStyle(color: Colors.white38, fontSize: 12),
          ),
        );
      }
      return SelectableText(
        payload.toString(),
        style: const TextStyle(
          color: Color(0xFFD4D4D4),
          fontFamily: 'monospace',
          fontSize: 12,
        ),
      );
    } else if (_activeNetworkDetailTab == 'Response') {
      final response = req['response'];
      if (response == null || response.toString().isEmpty) {
        return const Center(
          child: Text(
            'No response data',
            style: TextStyle(color: Colors.white38, fontSize: 12),
          ),
        );
      }
      return SelectableText(
        response.toString(),
        style: const TextStyle(
          color: Color(0xFFD4D4D4),
          fontFamily: 'monospace',
          fontSize: 12,
        ),
      );
    }
    return const SizedBox();
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: SelectableText(
              label,
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 11,
                fontFamily: 'monospace',
              ),
            ),
          ),
          Expanded(
            child: SelectableText(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontFamily: 'monospace',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildApplicationTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Cookies',
              style: TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (!_addingCookie)
              TextButton.icon(
                onPressed: () => setState(() => _addingCookie = true),
                icon: const Icon(Icons.add, size: 14, color: Color(0xFF007ACC)),
                label: const Text(
                  'Add Cookie',
                  style: TextStyle(color: Color(0xFF007ACC), fontSize: 11),
                ),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        _buildCookiesTable(),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Local Storage',
              style: TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (!_addingLocalStorage)
              TextButton.icon(
                onPressed: () => setState(() => _addingLocalStorage = true),
                icon: const Icon(Icons.add, size: 14, color: Color(0xFF007ACC)),
                label: const Text(
                  'Add Item',
                  style: TextStyle(color: Color(0xFF007ACC), fontSize: 11),
                ),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        _buildLocalStorageTable(),
      ],
    );
  }

  Widget _buildCookiesTable() {
    final entries = widget.cookies.entries.toList();

    return Table(
      columnWidths: const {
        0: FlexColumnWidth(2),
        1: FlexColumnWidth(3),
        2: FixedColumnWidth(80),
      },
      border: TableBorder.all(color: const Color(0xFF333333), width: 1),
      children: [
        // Header
        TableRow(
          decoration: const BoxDecoration(color: Color(0xFF252526)),
          children: const [
            Padding(
              padding: EdgeInsets.all(6),
              child: Text(
                'Name',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(6),
              child: Text(
                'Value',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(6),
              child: Text(
                'Actions',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),

        // Add new row input form if adding is active
        if (_addingCookie)
          TableRow(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: TextField(
                  controller: _newCookieKeyController,
                  autofocus: true,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontFamily: 'monospace',
                  ),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    hintText: 'Name...',
                    hintStyle: TextStyle(color: Colors.white30, fontSize: 11),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: TextField(
                  controller: _newCookieValController,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontFamily: 'monospace',
                  ),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    hintText: 'Value...',
                    hintStyle: TextStyle(color: Colors.white30, fontSize: 11),
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.check,
                      size: 14,
                      color: Colors.green,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () {
                      final k = _newCookieKeyController.text.trim();
                      final v = _newCookieValController.text.trim();
                      if (k.isNotEmpty && widget.onUpdateCookie != null) {
                        widget.onUpdateCookie!(k, v);
                      }
                      _newCookieKeyController.clear();
                      _newCookieValController.clear();
                      setState(() => _addingCookie = false);
                    },
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.close,
                      size: 14,
                      color: Colors.redAccent,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () {
                      _newCookieKeyController.clear();
                      _newCookieValController.clear();
                      setState(() => _addingCookie = false);
                    },
                  ),
                ],
              ),
            ],
          ),

        // List existing cookies
        if (entries.isEmpty && !_addingCookie)
          TableRow(
            children: [
              const SizedBox(),
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: Text(
                  'No cookies found',
                  style: TextStyle(color: Colors.white30, fontSize: 11),
                ),
              ),
              const SizedBox(),
            ],
          ),

        ...entries.map((entry) {
          final isEditing = _editingCookieKey == entry.key;
          return TableRow(
            children: [
              Padding(
                padding: const EdgeInsets.all(6),
                child: Text(
                  entry.key,
                  style: const TextStyle(
                    color: Color(0xFF9CDCFE),
                    fontSize: 11,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(4),
                child: isEditing
                    ? TextField(
                        controller: _editCookieValController,
                        autofocus: true,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontFamily: 'monospace',
                        ),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          isDense: true,
                        ),
                      )
                    : Text(
                        entry.value,
                        style: const TextStyle(
                          color: Color(0xFFCE9178),
                          fontSize: 11,
                          fontFamily: 'monospace',
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  if (isEditing) ...[
                    IconButton(
                      icon: const Icon(
                        Icons.check,
                        size: 14,
                        color: Colors.green,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () {
                        if (widget.onUpdateCookie != null) {
                          widget.onUpdateCookie!(
                            entry.key,
                            _editCookieValController.text,
                          );
                        }
                        setState(() => _editingCookieKey = null);
                      },
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.close,
                        size: 14,
                        color: Colors.redAccent,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () => setState(() => _editingCookieKey = null),
                    ),
                  ] else ...[
                    IconButton(
                      icon: const Icon(
                        Icons.edit,
                        size: 12,
                        color: Colors.white54,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () {
                        _editCookieValController.text = entry.value;
                        setState(() => _editingCookieKey = entry.key);
                      },
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.delete,
                        size: 12,
                        color: Colors.redAccent,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () {
                        if (widget.onDeleteCookie != null) {
                          widget.onDeleteCookie!(entry.key);
                        }
                      },
                    ),
                  ],
                ],
              ),
            ],
          );
        }).toList(),
      ],
    );
  }

  Widget _buildLocalStorageTable() {
    final entries = widget.localStorage.entries.toList();

    return Table(
      columnWidths: const {
        0: FlexColumnWidth(2),
        1: FlexColumnWidth(3),
        2: FixedColumnWidth(80),
      },
      border: TableBorder.all(color: const Color(0xFF333333), width: 1),
      children: [
        // Header
        TableRow(
          decoration: const BoxDecoration(color: Color(0xFF252526)),
          children: const [
            Padding(
              padding: EdgeInsets.all(6),
              child: Text(
                'Key',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(6),
              child: Text(
                'Value',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(6),
              child: Text(
                'Actions',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),

        // Add new row input form if adding is active
        if (_addingLocalStorage)
          TableRow(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: TextField(
                  controller: _newLocalStorageKeyController,
                  autofocus: true,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontFamily: 'monospace',
                  ),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    hintText: 'Key...',
                    hintStyle: TextStyle(color: Colors.white30, fontSize: 11),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: TextField(
                  controller: _newLocalStorageValController,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontFamily: 'monospace',
                  ),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    hintText: 'Value...',
                    hintStyle: TextStyle(color: Colors.white30, fontSize: 11),
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.check,
                      size: 14,
                      color: Colors.green,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () {
                      final k = _newLocalStorageKeyController.text.trim();
                      final v = _newLocalStorageValController.text.trim();
                      if (k.isNotEmpty && widget.onUpdateLocalStorage != null) {
                        widget.onUpdateLocalStorage!(k, v);
                      }
                      _newLocalStorageKeyController.clear();
                      _newLocalStorageValController.clear();
                      setState(() => _addingLocalStorage = false);
                    },
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.close,
                      size: 14,
                      color: Colors.redAccent,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () {
                      _newLocalStorageKeyController.clear();
                      _newLocalStorageValController.clear();
                      setState(() => _addingLocalStorage = false);
                    },
                  ),
                ],
              ),
            ],
          ),

        // List existing localStorage entries
        if (entries.isEmpty && !_addingLocalStorage)
          TableRow(
            children: [
              const SizedBox(),
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: Text(
                  'No local storage found',
                  style: TextStyle(color: Colors.white30, fontSize: 11),
                ),
              ),
              const SizedBox(),
            ],
          ),

        ...entries.map((entry) {
          final isEditing = _editingLocalStorageKey == entry.key;
          return TableRow(
            children: [
              Padding(
                padding: const EdgeInsets.all(6),
                child: Text(
                  entry.key,
                  style: const TextStyle(
                    color: Color(0xFF9CDCFE),
                    fontSize: 11,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(4),
                child: isEditing
                    ? TextField(
                        controller: _editLocalStorageValController,
                        autofocus: true,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontFamily: 'monospace',
                        ),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          isDense: true,
                        ),
                      )
                    : Text(
                        entry.value,
                        style: const TextStyle(
                          color: Color(0xFFCE9178),
                          fontSize: 11,
                          fontFamily: 'monospace',
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  if (isEditing) ...[
                    IconButton(
                      icon: const Icon(
                        Icons.check,
                        size: 14,
                        color: Colors.green,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () {
                        if (widget.onUpdateLocalStorage != null) {
                          widget.onUpdateLocalStorage!(
                            entry.key,
                            _editLocalStorageValController.text,
                          );
                        }
                        setState(() => _editingLocalStorageKey = null);
                      },
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.close,
                        size: 14,
                        color: Colors.redAccent,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () =>
                          setState(() => _editingLocalStorageKey = null),
                    ),
                  ] else ...[
                    IconButton(
                      icon: const Icon(
                        Icons.edit,
                        size: 12,
                        color: Colors.white54,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () {
                        _editLocalStorageValController.text = entry.value;
                        setState(() => _editingLocalStorageKey = entry.key);
                      },
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.delete,
                        size: 12,
                        color: Colors.redAccent,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () {
                        if (widget.onDeleteLocalStorage != null) {
                          widget.onDeleteLocalStorage!(entry.key);
                        }
                      },
                    ),
                  ],
                ],
              ),
            ],
          );
        }).toList(),
      ],
    );
  }
}

class DomNodeViewer extends StatefulWidget {
  final html_dom.Node node;
  final int depth;

  const DomNodeViewer({super.key, required this.node, this.depth = 0});

  @override
  State<DomNodeViewer> createState() => _DomNodeViewerState();
}

class _DomNodeViewerState extends State<DomNodeViewer> {
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    // Auto-expand html, head, and body tags by default
    if (widget.node is html_dom.Element) {
      final el = widget.node as html_dom.Element;
      if (el.localName == 'html' ||
          el.localName == 'head' ||
          el.localName == 'body') {
        _isExpanded = true;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.node is html_dom.Text) {
      final text = widget.node.text?.trim() ?? '';
      if (text.isEmpty) return const SizedBox.shrink();
      return Padding(
        padding: EdgeInsets.only(left: widget.depth * 12.0 + 16.0),
        child: SelectableText(
          text,
          style: const TextStyle(
            color: Color(0xFFD4D4D4),
            fontSize: 12,
            fontFamily: 'monospace',
          ),
        ),
      );
    } else if (widget.node is html_dom.Element) {
      final element = widget.node as html_dom.Element;
      final hasChildren = element.nodes
          .where(
            (n) =>
                n is html_dom.Element ||
                (n is html_dom.Text && (n.text?.trim().isNotEmpty ?? false)),
          )
          .isNotEmpty;

      final tagColor = const Color(0xFF569CD6);
      final attrNameColor = const Color(0xFF9CDCFE);
      final attrValColor = const Color(0xFFCE9178);

      List<TextSpan> spans = [
        const TextSpan(
          text: '<',
          style: TextStyle(color: Colors.white54),
        ),
        TextSpan(
          text: element.localName,
          style: TextStyle(color: tagColor),
        ),
      ];

      element.attributes.forEach((key, value) {
        spans.add(const TextSpan(text: ' '));
        spans.add(
          TextSpan(
            text: key.toString(),
            style: TextStyle(color: attrNameColor),
          ),
        );
        spans.add(
          const TextSpan(
            text: '="',
            style: TextStyle(color: Colors.white54),
          ),
        );
        spans.add(
          TextSpan(
            text: value,
            style: TextStyle(color: attrValColor),
          ),
        );
        spans.add(
          const TextSpan(
            text: '"',
            style: TextStyle(color: Colors.white54),
          ),
        );
      });

      spans.add(
        const TextSpan(
          text: '>',
          style: TextStyle(color: Colors.white54),
        ),
      );

      Widget header = RichText(
        text: TextSpan(
          style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
          children: spans,
        ),
      );

      if (!hasChildren) {
        return Padding(
          padding: EdgeInsets.only(left: widget.depth * 12.0 + 16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [header],
          ),
        );
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(width: widget.depth * 12.0),
              InkWell(
                onTap: () => setState(() => _isExpanded = !_isExpanded),
                child: SizedBox(
                  width: 16,
                  height: 16,
                  child: Icon(
                    _isExpanded ? Icons.arrow_drop_down : Icons.arrow_right,
                    size: 16,
                    color: Colors.white54,
                  ),
                ),
              ),
              InkWell(
                onTap: () => setState(() => _isExpanded = !_isExpanded),
                child: header,
              ),
            ],
          ),
          if (_isExpanded)
            ...element.nodes.map(
              (n) => DomNodeViewer(node: n, depth: widget.depth + 1),
            ),
          if (_isExpanded)
            Padding(
              padding: EdgeInsets.only(left: widget.depth * 12.0 + 16.0),
              child: RichText(
                text: TextSpan(
                  style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
                  children: [
                    const TextSpan(
                      text: '</',
                      style: TextStyle(color: Colors.white54),
                    ),
                    TextSpan(
                      text: element.localName,
                      style: TextStyle(color: tagColor),
                    ),
                    const TextSpan(
                      text: '>',
                      style: TextStyle(color: Colors.white54),
                    ),
                  ],
                ),
              ),
            ),
        ],
      );
    } else if (widget.node is html_dom.DocumentType) {
      return Padding(
        padding: EdgeInsets.only(left: widget.depth * 12.0 + 16.0),
        child: const Text(
          '<!DOCTYPE html>',
          style: TextStyle(
            color: Colors.white54,
            fontSize: 12,
            fontFamily: 'monospace',
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }
}
