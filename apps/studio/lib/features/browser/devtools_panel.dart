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
  });

  @override
  State<DevToolsPanel> createState() => _DevToolsPanelState();
}

class _DevToolsPanelState extends State<DevToolsPanel> {
  int _activeTabIndex = 0;
  final TextEditingController _consoleInputController = TextEditingController();

  final List<String> _tabs = ['Elements', 'Console', 'Network', 'Application'];

  @override
  void dispose() {
    _consoleInputController.dispose();
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
                              onTap: () => setState(() => _activeTabIndex = idx),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                decoration: BoxDecoration(
                                  border: Border(
                                    top: BorderSide(
                                      color: isActive ? const Color(0xFF007ACC) : Colors.transparent,
                                      width: 2,
                                    ),
                                    right: const BorderSide(color: Color(0xFF333333)),
                                  ),
                                  color: isActive ? const Color(0xFF1E1E1E) : Colors.transparent,
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  title,
                                  style: TextStyle(
                                    color: isActive ? Colors.white : Colors.white54,
                                    fontSize: 11,
                                    fontWeight: isActive ? FontWeight.w500 : FontWeight.normal,
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
                      child: Text('DevTools', style: TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                    const Spacer(),
                  ],
                  InkWell(
                    onTap: widget.onToggleMinimize,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      alignment: Alignment.center,
                      child: Icon(
                        widget.isMinimized ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
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
        child: Text('<html>...</html> (Loading or empty)', style: TextStyle(color: Colors.white38, fontSize: 12)),
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
            children: document.nodes.map((n) => DomNodeViewer(node: n)).toList(),
          ),
        ),
      );
    } catch (e) {
      return Center(
        child: Text('Error parsing HTML: $e', style: const TextStyle(color: Colors.redAccent)),
      );
    }
  }

  Widget _buildConsoleTab() {
    return Column(
      children: [
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
              const Icon(Icons.chevron_right, size: 16, color: Color(0xFF007ACC)),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _consoleInputController,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                    color: Colors.white,
                  ),
                  decoration: const InputDecoration(
                    hintText: 'Enter JavaScript code...',
                    hintStyle: TextStyle(color: Colors.white38),
                    border: InputBorder.none,
                    isDense: true,
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
    if (widget.networkRequests.isEmpty) {
      return const Center(
        child: Text('No requests recorded', style: TextStyle(color: Colors.white38)),
      );
    }
    
    return ListView.separated(
      itemCount: widget.networkRequests.length + 1,
      separatorBuilder: (context, index) => const Divider(height: 1, color: Color(0xFF333333)),
      itemBuilder: (context, index) {
        if (index == 0) {
          // Header
          return Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: const [
                Expanded(flex: 3, child: Text('Name', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold))),
                Expanded(flex: 1, child: Text('Method', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold))),
                Expanded(flex: 1, child: Text('Status', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold))),
              ],
            ),
          );
        }

        final req = widget.networkRequests[index - 1];
        final isError = req['status'] != '200 OK' && req['status'] != 'Pending';
        
        return Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              Expanded(
                flex: 3,
                child: Text(
                  req['url'] ?? '',
                  style: TextStyle(
                    color: isError ? const Color(0xFFF48771) : Colors.white,
                    fontSize: 12,
                    fontFamily: 'monospace'
                  ),
                  overflow: TextOverflow.ellipsis,
                )
              ),
              Expanded(
                flex: 1,
                child: Text(
                  req['method'] ?? '',
                  style: const TextStyle(color: Colors.white54, fontSize: 12)
                )
              ),
              Expanded(
                flex: 1,
                child: Text(
                  req['status'] ?? '',
                  style: TextStyle(
                    color: isError ? const Color(0xFFF48771) : Colors.white54,
                    fontSize: 12
                  )
                )
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildApplicationTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('Cookies', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        if (widget.cookies.isEmpty)
          const Text('No cookies found', style: TextStyle(color: Colors.white38, fontSize: 12))
        else
          ...widget.cookies.entries.map((e) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: SelectableText('${e.key}: ${e.value}', style: const TextStyle(color: Color(0xFF9CDCFE), fontSize: 12, fontFamily: 'monospace')),
          )),
          
        const SizedBox(height: 24),
        const Text('Local Storage', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        if (widget.localStorage.isEmpty)
          const Text('No local storage found', style: TextStyle(color: Colors.white38, fontSize: 12))
        else
          ...widget.localStorage.entries.map((e) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: SelectableText('${e.key}: ${e.value}', style: const TextStyle(color: Color(0xFF9CDCFE), fontSize: 12, fontFamily: 'monospace')),
          )),
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
      if (el.localName == 'html' || el.localName == 'head' || el.localName == 'body') {
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
        child: SelectableText(text, style: const TextStyle(color: Color(0xFFD4D4D4), fontSize: 12, fontFamily: 'monospace')),
      );
    } else if (widget.node is html_dom.Element) {
      final element = widget.node as html_dom.Element;
      final hasChildren = element.nodes.where((n) => n is html_dom.Element || (n is html_dom.Text && (n.text?.trim().isNotEmpty ?? false))).isNotEmpty;
      
      final tagColor = const Color(0xFF569CD6);
      final attrNameColor = const Color(0xFF9CDCFE);
      final attrValColor = const Color(0xFFCE9178);

      List<TextSpan> spans = [
        const TextSpan(text: '<', style: TextStyle(color: Colors.white54)),
        TextSpan(text: element.localName, style: TextStyle(color: tagColor)),
      ];

      element.attributes.forEach((key, value) {
        spans.add(const TextSpan(text: ' '));
        spans.add(TextSpan(text: key.toString(), style: TextStyle(color: attrNameColor)));
        spans.add(const TextSpan(text: '="', style: TextStyle(color: Colors.white54)));
        spans.add(TextSpan(text: value, style: TextStyle(color: attrValColor)));
        spans.add(const TextSpan(text: '"', style: TextStyle(color: Colors.white54)));
      });

      spans.add(const TextSpan(text: '>', style: TextStyle(color: Colors.white54)));

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
            children: [
              header,
            ],
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
            ...element.nodes.map((n) => DomNodeViewer(node: n, depth: widget.depth + 1)),
          if (_isExpanded)
            Padding(
              padding: EdgeInsets.only(left: widget.depth * 12.0 + 16.0),
              child: RichText(
                text: TextSpan(
                  style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
                  children: [
                    const TextSpan(text: '</', style: TextStyle(color: Colors.white54)),
                    TextSpan(text: element.localName, style: TextStyle(color: tagColor)),
                    const TextSpan(text: '>', style: TextStyle(color: Colors.white54)),
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
          style: TextStyle(color: Colors.white54, fontSize: 12, fontFamily: 'monospace'),
        ),
      );
    }

    return const SizedBox.shrink();
  }
}
