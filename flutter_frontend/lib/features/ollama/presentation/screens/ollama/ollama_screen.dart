import 'package:flutter/material.dart';
import 'package:flutter_frontend/features/dashboard/presentation/screens/dashboard/components/header.dart';
import 'package:flutter_frontend/features/dashboard/presentation/constants.dart';

class OllamaScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        primary: false,
        padding: EdgeInsets.all(defaultPadding),
        child: Column(
          children: [
            Header(),
            SizedBox(height: defaultPadding),
            Container(
              padding: EdgeInsets.all(defaultPadding),
              decoration: BoxDecoration(
                color: secondaryColor,
                borderRadius: const BorderRadius.all(Radius.circular(10)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Vista Ollama",
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  SizedBox(height: defaultPadding),
                  Center(
                    child: Column(
                      children: [
                        Icon(Icons.auto_awesome, size: 80, color: primaryColor),
                        SizedBox(height: defaultPadding),
                        Text(
                          "Estas en vista ollama en rol administrador",
                          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: defaultPadding / 2),
                        Text(
                          "Aquí se integrará la lógica de Ollama próximamente.",
                          style: TextStyle(color: Colors.white54),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
