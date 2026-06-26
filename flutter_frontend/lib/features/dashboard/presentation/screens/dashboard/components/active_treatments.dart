import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_frontend/features/pacientes/logic/pacientes_provider.dart';
import 'package:flutter_frontend/features/pacientes/data/paciente_model.dart';
import '../../../constants.dart';

class ActiveTreatments extends StatelessWidget {
  const ActiveTreatments({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final pacientesProvider = Provider.of<PacientesProvider>(context);
    final perfil = pacientesProvider.perfilPaciente;

    if (pacientesProvider.isLoading) {
      return const SizedBox(
        height: 150,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final tratamientos = perfil?.tratamientos
            .where((t) => t.estado.toLowerCase() == 'activo')
            .toList() ??
        [];

    List<MedicamentoModel> medicamentos = [];
    for (var t in tratamientos) {
      medicamentos.addAll(t.medicamentos);
    }

    return Container(
      padding: const EdgeInsets.all(defaultPadding),
      decoration: BoxDecoration(
        color: secondaryColor,
        borderRadius: const BorderRadius.all(Radius.circular(10)),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Mi Plan de Medicación Activo",
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 5),
          const Text(
            "Medicamentos recetados por tu cardiólogo",
            style: TextStyle(fontSize: 11, color: Colors.white38),
          ),
          const SizedBox(height: defaultPadding),
          if (medicamentos.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: defaultPadding * 2),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.check_circle_outline, color: Colors.green, size: 40),
                    SizedBox(height: 10),
                    Text(
                      "No tienes medicamentos activos recetados.",
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                  ],
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: medicamentos.length,
              separatorBuilder: (context, index) => const Divider(color: Colors.white10),
              itemBuilder: (context, index) {
                final med = medicamentos[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.medication_outlined,
                          color: Colors.orange,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: defaultPadding),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              med.nombreMedicamento,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "Frecuencia: ${med.frecuencia} | Duración: ${med.duracion}",
                              style: const TextStyle(fontSize: 11, color: Colors.white54),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          med.dosis,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white70,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}
