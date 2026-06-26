import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_frontend/features/pacientes/logic/pacientes_provider.dart';
import 'package:flutter_frontend/features/pacientes/data/paciente_model.dart';
import '../../../constants.dart';

class PatientRecentExams extends StatelessWidget {
  const PatientRecentExams({Key? key}) : super(key: key);

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

    final examenes = perfil?.examenesMedicos ?? [];

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
          const Text(
            "Exámenes Médicos",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 5),
          const Text(
            "Resultados de tus últimos chequeos",
            style: TextStyle(fontSize: 11, color: Colors.white38),
          ),
          const SizedBox(height: defaultPadding),
          if (examenes.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: defaultPadding),
                child: Text(
                  "No hay exámenes registrados",
                  style: TextStyle(color: Colors.white38, fontSize: 13),
                ),
              ),
            )
          else
            ...List.generate(
              examenes.length > 5 ? 5 : examenes.length,
              (index) => ExamCard(exam: examenes[index]),
            ),
        ],
      ),
    );
  }
}

class ExamCard extends StatelessWidget {
  const ExamCard({
    Key? key,
    required this.exam,
  }) : super(key: key);

  final ExamenMedicoModel exam;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: defaultPadding),
      padding: const EdgeInsets.all(defaultPadding),
      decoration: BoxDecoration(
        border: Border.all(width: 2, color: primaryColor.withOpacity(0.15)),
        borderRadius: const BorderRadius.all(
          Radius.circular(defaultPadding),
        ),
      ),
      child: Row(
        children: [
          Container(
            height: 40,
            width: 40,
            decoration: BoxDecoration(
              color: Colors.teal.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.science_outlined, color: Colors.teal, size: 20),
          ),
          const SizedBox(width: defaultPadding),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  exam.tipoExamen,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const SizedBox(height: 2),
                Text(
                  exam.resultado ?? 'Resultado pendiente',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall!.copyWith(color: Colors.white54, fontSize: 11),
                ),
              ],
            ),
          ),
          const SizedBox(width: 4),
          Text(
            exam.fechaExamen,
            style: const TextStyle(fontSize: 10, color: Colors.white38),
          )
        ],
      ),
    );
  }
}
