import 'package:flutter/material.dart';
import 'chatbot/chat_message.dart';
import 'chatbot/chat_input.dart';
import 'settings/settings_controller.dart';
import 'about/about_page.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../services/database_helper.dart';

class MyApp extends StatefulWidget {
  const MyApp({super.key, required this.settingsController});

  final SettingsController settingsController;

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final TextEditingController _controller = TextEditingController();
  final List<ChatMessage> _messages = [];
  List<Map<String, String>> _chatHistory = [];
  bool _isOnline = true;
  bool _isLoading = false;
  int _selectedIndex = 0;
  final DatabaseHelper _dbHelper = DatabaseHelper();

  @override
  void initState() {
    super.initState();
    _checkConnectivity();
    Connectivity().onConnectivityChanged.listen((ConnectivityResult result) {
      setState(() {
        _isOnline = result != ConnectivityResult.none;
      });
    });

    _loadChatHistory();
  }

  Future<void> _loadChatHistory() async {
    final history = await _dbHelper.getChatHistory();
    setState(() {
      _messages.clear();
      _chatHistory.clear();
      for (var row in history) {
        _messages.add(ChatMessage(
          text: row['message'],
          isUser: row['is_user'] == 1,
        ));
        _chatHistory.add({
          'role': row['is_user'] == 1 ? 'user' : 'assistant',
          'content': row['message'],
        });
      }
    });
  }

  void _checkConnectivity() async {
    var connectivityResult = await (Connectivity().checkConnectivity());
    setState(() {
      _isOnline = connectivityResult != ConnectivityResult.none;
    });
  }

  Future<void> _sendMessage() async {
    if (!_isOnline) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay conexión a internet')),
      );
      return;
    }

    final text = _controller.text;
    if (text.isEmpty) return;

    setState(() {
      _messages.add(ChatMessage(text: text, isUser: true));
      _isLoading = true;
    });

    _dbHelper.insertMessage(text, true);
    _chatHistory.add({'role': 'user', 'content': text});

    _controller.clear();

    final response = await _getChatGPTResponse();

    setState(() {
      _messages.add(ChatMessage(text: response, isUser: false));
      _isLoading = false;
    });

    _dbHelper.insertMessage(response, false);

    _chatHistory.add({'role': 'assistant', 'content': response});

    if (_chatHistory.length > 4) {
      _chatHistory.removeRange(0, _chatHistory.length - 4);
    }
  }

  Future<String> _getChatGPTResponse() async {
    final apiKey = dotenv.env['OPENAI_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      return 'Error: La clave API no está configurada.';
    }

    final url = Uri.parse('https://api.openai.com/v1/chat/completions');
    final headers = {
      'Content-Type': 'application/json; charset=UTF-8',
      'Authorization': 'Bearer $apiKey',
    };

    final body = jsonEncode({
      'model': 'gpt-3.5-turbo',
      'messages': _chatHistory,
      'max_tokens': 50,
      'temperature': 0.7,
    });

    try {
      final response = await http.post(url, headers: headers, body: body);
      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        return data['choices'][0]['message']['content'].trim();
      } else {
        return 'Error: ${response.statusCode} - ${response.reasonPhrase}';
      }
    } catch (e) {
      return 'Error al conectar con la API de OpenAI: $e';
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Chatbot con ChatGPT',
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      themeMode: widget.settingsController.themeMode,
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Chatbot con ChatGPT'),
        ),
        body: IndexedStack(
          index: _selectedIndex,
          children: <Widget>[
            ChatbotPage(
              controller: _controller,
              messages: _messages,
              onSendMessage: _sendMessage,
              isOnline: _isOnline,
              isLoading: _isLoading,
              onLoadComplete: () => setState(() {}),  // Refrescar el estado después de cargar el historial
            ),
            const AboutPage(),
          ],
        ),
        bottomNavigationBar: BottomNavigationBar(
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: Icon(Icons.chat),
              label: 'Chatbot',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.info),
              label: 'Acerca de',
            ),
          ],
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
        ),
      ),
    );
  }
}

// Página del Chatbot separada con ScrollController
class ChatbotPage extends StatefulWidget {
  final TextEditingController controller;
  final List<ChatMessage> messages;
  final VoidCallback onSendMessage;
  final bool isOnline;
  final bool isLoading;
  final VoidCallback onLoadComplete;  // Callback cuando el historial se cargue

  const ChatbotPage({
    required this.controller,
    required this.messages,
    required this.onSendMessage,
    required this.isOnline,
    required this.isLoading,
    required this.onLoadComplete,
    super.key,
  });

  @override
  _ChatbotPageState createState() => _ChatbotPageState();
}

class _ChatbotPageState extends State<ChatbotPage> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());  // Scroll inicial
  }

  @override
  void didUpdateWidget(covariant ChatbotPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.messages.length > oldWidget.messages.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            itemCount: widget.messages.length,
            itemBuilder: (context, index) {
              final message = widget.messages[index];
              final messageBackground = message.isUser
                  ? Theme.of(context).brightness == Brightness.dark
                  ? Colors.blue[300]
                  : Colors.blue[100]
                  : Theme.of(context).brightness == Brightness.dark
                  ? Colors.grey[700]
                  : Colors.grey[300];

              return ListTile(
                title: Align(
                  alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    padding: const EdgeInsets.all(8.0),
                    decoration: BoxDecoration(
                      color: messageBackground,
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: Text(message.text),
                  ),
                ),
              );
            },
          ),
        ),
        if (widget.isLoading) const CircularProgressIndicator(),
        ChatInput(
          controller: widget.controller,
          onSend: widget.onSendMessage,
          isOnline: widget.isOnline,
        ),
      ],
    );
  }
}











