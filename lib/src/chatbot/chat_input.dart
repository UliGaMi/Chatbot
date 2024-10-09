import 'package:flutter/material.dart';

class ChatInput extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;
  final bool isOnline;  // Recibe el estado de la conexión

  const ChatInput({
    required this.controller,
    required this.onSend,
    required this.isOnline,  // Añadimos el parámetro isOnline
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 12.0),
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Row(
        children: [
          // Campo de texto para el mensaje
          Expanded(
            child: TextField(
              controller: controller,
              maxLines: 3,
              style: TextStyle(
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
              decoration: InputDecoration(
                contentPadding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                filled: true,
                fillColor: Theme.of(context).brightness == Brightness.dark
                    ? Colors.grey[800]
                    : Colors.grey[200],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30.0),
                  borderSide: BorderSide.none,
                ),
                hintText: 'Escribe un mensaje...',
                hintStyle: TextStyle(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.grey[400]
                      : Colors.grey[600],
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Botón de enviar, se desactiva cuando no hay conexión
          GestureDetector(
            onTap: isOnline ? onSend : null,  // Solo funciona si hay conexión
            child: Container(
              padding: const EdgeInsets.all(10.0),
              decoration: BoxDecoration(
                color: isOnline ? Colors.blueAccent : Colors.grey,  // Cambia el color según la conexión
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.send,
                color: Colors.white,
                size: 24.0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}


