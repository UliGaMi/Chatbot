import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({Key? key}) : super(key: key);

  // Función para abrir el enlace
  Future<void> _launchURL() async {
    final Uri url = Uri.parse('https://github.com/UliGaMi/Chatbot.git');
    if (!await launchUrl(url)) {
      throw 'No se puede abrir $url';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Acerca de'),
      ),
      body: Center(  // Asegura que todo el contenido esté centrado
        child: SingleChildScrollView(  // Permite el desplazamiento si el contenido es muy grande
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Imagen centrada con un tamaño más grande
              ClipRRect(
                borderRadius: BorderRadius.circular(75),  // Hace la imagen redonda
                child: Image.asset(
                  'assets/images/logo.png',  // Asegúrate de que la ruta sea correcta
                  width: 150,
                  height: 150,
                ),
              ),
              const SizedBox(height: 30),  // Espaciado más amplio
              const Text(
                'Ingeniería de Software',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,  // Asegura que el texto esté centrado
              ),
              const SizedBox(height: 10),
              const Text(
                'Programación para móviles',
                style: TextStyle(fontSize: 18),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              const Text(
                'Ulises Gálvez Miranda',
                style: TextStyle(fontSize: 18),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              const Text(
                '213691',
                style: TextStyle(fontSize: 18),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              const Text(
                '9B',
                style: TextStyle(fontSize: 18),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),  // Espaciado antes del botón
              ElevatedButton(
                onPressed: _launchURL,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),  // Botón con bordes redondeados
                  ),
                ),
                child: const Text(
                  'Ir al repositorio',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}



