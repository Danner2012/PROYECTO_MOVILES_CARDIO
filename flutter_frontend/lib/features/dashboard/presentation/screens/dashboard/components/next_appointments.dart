import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_frontend/features/dashboard/logic/dashboard_doctor_provider.dart';
import 'package:flutter_frontend/features/dashboard/data/models/dashboard_doctor_model.dart';
import '../../../constants.dart';
import 'storage_info_card.dart';

class NextAppointments extends StatelessWidget {
  const NextAppointments({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final dashboardProvider = Provider.of<DashboardDoctorProvider>(context);
    final appointments = dashboardProvider.data?.proximasConsultas ?? [];

    return Container(
      padding: EdgeInsets.all(defaultPadding),
      decoration: BoxDecoration(
        color: secondaryColor,
        borderRadius: const BorderRadius.all(Radius.circular(10)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Próximas Consultas",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: defaultPadding),
          if (appointments.isEmpty && !dashboardProvider.isLoading)
            Center(child: Text("No hay consultas programadas"))
          else
            ...List.generate(
              appointments.length,
              (index) => AppointmentCard(appointment: appointments[index]),
            ),
        ],
      ),
    );
  }
}

class AppointmentCard extends StatelessWidget {
  const AppointmentCard({
    Key? key,
    required this.appointment,
  }) : super(key: key);

  final ProximaConsulta appointment;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(top: defaultPadding),
      padding: EdgeInsets.all(defaultPadding),
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
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.calendar_today, color: Colors.green, size: 20),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: defaultPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    appointment.pacienteNombre,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    appointment.motivo,
                    style: Theme.of(context).textTheme.bodySmall!.copyWith(color: Colors.white70),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
          Text(appointment.fecha)
        ],
      ),
    );
  }
}
