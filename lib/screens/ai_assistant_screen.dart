import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../models/ai_models.dart';
import '../prompts/ai_prompts.dart';
import '../services/ai_context_service.dart';
import '../services/ai_service.dart';
import '../services/voice_input_service.dart';
import '../widgets/ai_chat_bubble.dart';
import '../widgets/ai_task_card.dart';

const _forest = Color(0xFF2F6B45);
const _deepForest = Color(0xFF1F4F34);
const _leaf = Color(0xFFE7F1E5);
const _ink = Color(0xFF243127);
const _muted = Color(0xFF6B756D);

class AiAssistantScreen extends StatefulWidget {
  const AiAssistantScreen({super.key});

  @override
  State<AiAssistantScreen> createState() => _AiAssistantScreenState();
}

class _AiAssistantScreenState extends State<AiAssistantScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final _factory = const AiServiceFactory();
  late final AiService _service;
  late final VoiceInputService _voiceService;
  late final AiContextService _contextService;
  final _messages = <ChatMessage>[];
  List<AiTask> _tasks = [];
  String? _generatedMessage;
  String? _generatedReport;
  AiMessageType _messageType = AiMessageType.volunteer;
  AiReportType _reportType = AiReportType.daily;
  bool _isTyping = false;
  bool _isGenerating = false;

  @override
  void initState() {
    super.initState();
    _service = _factory.createLocal();
    _voiceService = LocalVoiceInputService();
    _contextService = _factory.createContext();
    _messages.add(
      const ChatMessage(text: AiPrompts.welcome, role: AiMessageRole.assistant),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _send([String? preset]) async {
    final question = (preset ?? _controller.text).trim();
    if (question.isEmpty || _isTyping) return;
    _controller.clear();
    setState(() {
      _messages.add(
        ChatMessage(
          text: question,
          role: AiMessageRole.user,
          createdAt: DateTime.now(),
        ),
      );
      _isTyping = true;
    });
    _scrollToBottom();
    final answer = await _service.answer(question, _contextService.read());
    if (!mounted) return;
    setState(() {
      _messages.add(
        ChatMessage(
          text: answer,
          role: AiMessageRole.assistant,
          createdAt: DateTime.now(),
        ),
      );
      _isTyping = false;
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _listen() async {
    final text = await _voiceService.listen();
    if (!mounted) return;
    if (text == null) {
      _showSnack(
        'Voice input अभी demo mode में है। बाद में speech-to-text जोड़ सकते हैं।',
      );
    } else {
      _controller.text = text;
    }
  }

  void _clearChat() {
    setState(() {
      _messages
        ..clear()
        ..add(
          const ChatMessage(
            text: AiPrompts.welcome,
            role: AiMessageRole.assistant,
          ),
        );
    });
  }

  Future<void> _makeTasks() async {
    setState(() => _isGenerating = true);
    final tasks = await _service.createDailyTasks(_contextService.read());
    if (!mounted) return;
    setState(() {
      _tasks = tasks;
      _isGenerating = false;
    });
  }

  Future<void> _makeMessage() async {
    setState(() => _isGenerating = true);
    final text = await _service.createMessage(
      _messageType,
      _contextService.read(),
    );
    if (!mounted) return;
    setState(() {
      _generatedMessage = text;
      _isGenerating = false;
    });
  }

  Future<void> _makeReport() async {
    setState(() => _isGenerating = true);
    final text = await _service.createReport(
      _reportType,
      _contextService.read(),
    );
    if (!mounted) return;
    setState(() {
      _generatedReport = text;
      _isGenerating = false;
    });
  }

  Future<void> _copyOrShare(String text, {required bool share}) async {
    if (share) {
      await Share.share(text);
    } else {
      await Clipboard.setData(ClipboardData(text: text));
      _showSnack('कॉपी हो गया');
    }
  }

  void _showSnack(String text) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

  @override
  Widget build(BuildContext context) => DefaultTabController(
    length: 4,
    child: Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            CircleAvatar(
              backgroundColor: _leaf,
              child: Icon(Icons.auto_awesome_rounded, color: _forest),
            ),
            SizedBox(width: 10),
            Text('AI गौसेवा सहायक'),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Chat साफ करें',
            onPressed: _clearChat,
            icon: const Icon(Icons.delete_sweep_outlined),
          ),
        ],
        bottom: const TabBar(
          isScrollable: true,
          tabs: [
            Tab(icon: Icon(Icons.chat_bubble_outline), text: 'बातचीत'),
            Tab(icon: Icon(Icons.checklist_rounded), text: 'काम'),
            Tab(icon: Icon(Icons.campaign_outlined), text: 'संदेश'),
            Tab(icon: Icon(Icons.assessment_outlined), text: 'रिपोर्ट'),
          ],
        ),
      ),
      body: TabBarView(
        children: [_chatTab(), _tasksTab(), _messagesTab(), _reportsTab()],
      ),
    ),
  );

  Widget _chatTab() => Column(
    children: [
      Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 12),
        color: _deepForest,
        child: const Text(
          'स्थानीय AI mode · आपकी app जानकारी के आधार पर सुझाव',
          style: TextStyle(color: Color(0xFFD9E8D4), fontSize: 12),
        ),
      ),
      Expanded(
        child: ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 10),
          itemCount: _messages.length + (_isTyping ? 1 : 0),
          itemBuilder: (context, index) => index < _messages.length
              ? AiChatBubble(message: _messages[index])
              : const Align(
                  alignment: Alignment.centerLeft,
                  child: AiTypingIndicator(),
                ),
        ),
      ),
      SizedBox(
        height: 52,
        child: ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          scrollDirection: Axis.horizontal,
          itemCount: AiPrompts.suggestedQuestions.length,
          separatorBuilder: (_, _) => const SizedBox(width: 8),
          itemBuilder: (context, index) => ActionChip(
            label: Text(AiPrompts.suggestedQuestions[index]),
            onPressed: () => _send(AiPrompts.suggestedQuestions[index]),
          ),
        ),
      ),
      _composer(),
    ],
  );

  Widget _composer() => SafeArea(
    top: false,
    child: Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              minLines: 1,
              maxLines: 3,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _send(),
              decoration: InputDecoration(
                hintText: 'हिंदी में अपना सवाल लिखें',
                prefixIcon: IconButton(
                  tooltip: 'Voice input',
                  onPressed: _listen,
                  icon: const Icon(Icons.mic_none_rounded),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton.filled(
            tooltip: 'भेजें',
            onPressed: _isTyping ? null : _send,
            icon: const Icon(Icons.send_rounded),
          ),
        ],
      ),
    ),
  );

  Widget _tasksTab() => _toolPage(
    title: 'आज के सेवा कार्य',
    subtitle:
        'AI आपके मौजूदा app data के आधार पर daily checklist तैयार करता है।',
    buttonLabel: 'आज की सूची बनाएं',
    icon: Icons.auto_awesome,
    onPressed: _makeTasks,
    child: _tasks.isEmpty
        ? const _EmptyToolState(
            icon: Icons.checklist_rounded,
            text: 'आज की काम की सूची बनाने के लिए ऊपर tap करें।',
          )
        : Column(
            children: _tasks
                .map(
                  (task) => AiTaskCard(
                    task: task,
                    onChanged: (value) =>
                        setState(() => task.completed = value ?? false),
                  ),
                )
                .toList(),
          ),
  );

  Widget _messagesTab() => _toolPage(
    title: 'WhatsApp संदेश',
    subtitle: 'तैयार message को कॉपी करें या share sheet से WhatsApp चुनें।',
    buttonLabel: 'संदेश बनाएं',
    icon: Icons.campaign_outlined,
    onPressed: _makeMessage,
    child: Column(
      children: [
        DropdownButtonFormField<AiMessageType>(
          initialValue: _messageType,
          decoration: const InputDecoration(labelText: 'संदेश का प्रकार'),
          items: AiMessageType.values
              .map(
                (type) =>
                    DropdownMenuItem(value: type, child: Text(type.label)),
              )
              .toList(),
          onChanged: (value) => setState(() => _messageType = value!),
        ),
        const SizedBox(height: 14),
        if (_generatedMessage != null)
          _GeneratedText(
            text: _generatedMessage!,
            onCopy: () => _copyOrShare(_generatedMessage!, share: false),
            onShare: () => _copyOrShare(_generatedMessage!, share: true),
          ),
      ],
    ),
  );

  Widget _reportsTab() => _toolPage(
    title: 'रिपोर्ट बनाएं',
    subtitle: 'उपलब्ध local records से Hindi report तैयार करें।',
    buttonLabel: 'रिपोर्ट बनाएं',
    icon: Icons.assessment_outlined,
    onPressed: _makeReport,
    child: Column(
      children: [
        DropdownButtonFormField<AiReportType>(
          initialValue: _reportType,
          decoration: const InputDecoration(labelText: 'रिपोर्ट का प्रकार'),
          items: AiReportType.values
              .map(
                (type) =>
                    DropdownMenuItem(value: type, child: Text(type.label)),
              )
              .toList(),
          onChanged: (value) => setState(() => _reportType = value!),
        ),
        const SizedBox(height: 14),
        if (_generatedReport != null)
          _GeneratedText(
            text: _generatedReport!,
            onCopy: () => _copyOrShare(_generatedReport!, share: false),
            onShare: () => _copyOrShare(_generatedReport!, share: true),
          ),
      ],
    ),
  );

  Widget _toolPage({
    required String title,
    required String subtitle,
    required String buttonLabel,
    required IconData icon,
    required VoidCallback onPressed,
    required Widget child,
  }) => ListView(
    padding: const EdgeInsets.fromLTRB(16, 18, 16, 28),
    children: [
      Text(
        title,
        style: const TextStyle(
          color: _ink,
          fontSize: 22,
          fontWeight: FontWeight.w800,
        ),
      ),
      const SizedBox(height: 6),
      Text(subtitle, style: const TextStyle(color: _muted, height: 1.4)),
      const SizedBox(height: 16),
      SizedBox(
        width: double.infinity,
        child: FilledButton.icon(
          onPressed: _isGenerating ? null : onPressed,
          icon: Icon(icon),
          label: Text(_isGenerating ? 'तैयार हो रहा है...' : buttonLabel),
          style: FilledButton.styleFrom(
            backgroundColor: _forest,
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      ),
      const SizedBox(height: 18),
      child,
    ],
  );
}

class _GeneratedText extends StatelessWidget {
  const _GeneratedText({
    required this.text,
    required this.onCopy,
    required this.onShare,
  });
  final String text;
  final VoidCallback onCopy;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: const Color(0xFFE1E9DE)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(text, style: const TextStyle(color: _ink, height: 1.55)),
        const SizedBox(height: 14),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            OutlinedButton.icon(
              onPressed: onCopy,
              icon: const Icon(Icons.copy_outlined, size: 18),
              label: const Text('कॉपी करें'),
            ),
            FilledButton.icon(
              onPressed: onShare,
              icon: const Icon(Icons.share_outlined, size: 18),
              label: const Text('WhatsApp पर भेजें'),
            ),
          ],
        ),
      ],
    ),
  );
}

class _EmptyToolState extends StatelessWidget {
  const _EmptyToolState({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(28),
    decoration: BoxDecoration(
      color: _leaf,
      borderRadius: BorderRadius.circular(18),
    ),
    child: Column(
      children: [
        Icon(icon, color: _forest, size: 42),
        const SizedBox(height: 10),
        Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(color: _muted, height: 1.4),
        ),
      ],
    ),
  );
}
