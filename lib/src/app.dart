import 'package:flutter/material.dart';
import 'chatbot/chat_message.dart';
import 'chatbot/chat_input.dart';
import 'settings/settings_controller.dart';
import 'about/about_page.dart'; // Nueva vista para la información personal
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:connectivity_plus/connectivity_plus.dart';  // Verificación de conexión
import 'dart:async';  // Para usar StreamSubscription

class MyApp extends StatefulWidget {
  const MyApp({super.key, required this.settingsController});

  final SettingsController settingsController;

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final TextEditingController _controller = TextEditingController();
  final List<ChatMessage> _messages = [];
  final List<Map<String, String>> _chatHistory = [];
  final int _messageHistoryLimit = 10;
  bool _isOnline = true;  // Estado de la conexión a internet
  int _selectedIndex = 0;  // Para el navbar
  late StreamSubscription<ConnectivityResult> _connectivitySubscription;

  @override
  void initState() {
    super.initState();
    _checkConnectivity();
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((ConnectivityResult result) {
      setState(() {
        _isOnline = result != ConnectivityResult.none;
      });
    });
    _chatHistory.add({
      'role': 'system',
      'content': 'Eres un asistente útil que responde en español de manera breve y asertiva.'
    });
  }

  @override
  void dispose() {
    _connectivitySubscription.cancel();  // Cancelar la suscripción cuando se destruya el widget
    super.dispose();
  }

  // Verificar la conexión a internet inicialmente
  void _checkConnectivity() async {
    var connectivityResult = await (Connectivity().checkConnectivity());
    setState(() {
      _isOnline = connectivityResult != ConnectivityResult.none;
    });
  }

  Future<void> _sendMessage() async {
    if (!_isOnline) {
      // Muestra un mensaje de error si no hay conexión
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay conexión a internet')),
      );
      return;
    }

    final text = _controller.text;
    if (text.isEmpty) return;

    // Agregar el mensaje del usuario a la interfaz de usuario
    setState(() {
      _messages.add(ChatMessage(text: text, isUser: true));
    });

    _chatHistory.add({'role': 'user', 'content': text});

    if (_chatHistory.length > _messageHistoryLimit * 2) {
      _chatHistory.removeRange(0, _chatHistory.length - _messageHistoryLimit * 2);
    }

    _controller.clear();

    // Llama a la API de OpenAI para obtener la respuesta
    final response = await _getChatGPTResponse();

    setState(() {
      _messages.add(ChatMessage(text: response, isUser: false));
    });

    _chatHistory.add({'role': 'assistant', 'content': response});
  }

  Future<String> _getChatGPTResponse() async {
    final apiKey = dotenv.env['OPENAI_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      return 'Error: La clave API no está configurada.';
    }

    final url = Uri.parse('https://api.openai.com/v1/chat/completions');
    final headers = {
      'Content-Type': 'application/json; charset=utf-8', // Usamos UTF-8
      'Authorization': 'Bearer $apiKey',
    };

    final body = jsonEncode({
      'model': 'gpt-3.5-turbo',
      'messages': _chatHistory,
      'max_tokens': 50,  // Limitar la longitud de la respuesta
      'temperature': 0.7,
    });

    try {
      final response = await http.post(url, headers: headers, body: body);
      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));  // Decodificación UTF-8
        return data['choices'][0]['message']['content'].trim();
      } else {
        return 'Error: ${response.statusCode} - ${response.reasonPhrase}';
      }
    } catch (e) {
      return 'Error al conectar con la API de OpenAI: $e';
    }
  }

  // Cambiar entre las vistas
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  // Función para cambiar entre las páginas del chatbot y la de información
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
            ChatbotPage(  // Pasamos los estados actuales al ChatbotPage
              controller: _controller,
              messages: _messages,
              onSendMessage: _sendMessage,
              isOnline: _isOnline,
            ),
            const AboutPage(),  // Página 'Acerca de'
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
          onTap: _onItemTapped,  // Cambiar entre vistas
        ),
      ),
    );
  }
}

// Página del Chatbot separada
class ChatbotPage extends StatelessWidget {
  final TextEditingController controller;
  final List<ChatMessage> messages;
  final VoidCallback onSendMessage;
  final bool isOnline;

  const ChatbotPage({
    required this.controller,
    required this.messages,
    required this.onSendMessage,
    required this.isOnline,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            itemCount: messages.length,
            itemBuilder: (context, index) {
              final message = messages[index];
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
        ChatInput(
          controller: controller,
          onSend: onSendMessage,
          isOnline: isOnline,  // Pasamos el estado de conexión
        ),
      ],
    );
  }
}






