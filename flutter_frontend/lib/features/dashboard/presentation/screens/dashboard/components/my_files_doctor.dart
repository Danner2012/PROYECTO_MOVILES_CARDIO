import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_frontend/features/dashboard/logic/dashboard_doctor_provider.dart';
import 'package:flutter_frontend/features/dashboard/presentation/responsive.dart';
import 'package:flutter_frontend/features/dashboard/presentation/screens/dashboard/components/file_info_card.dart';
import 'package:flutter_frontend/features/dashboard/data/models/my_files.dart';
import '../../../constants.dart';

class MyFilesDoctor extends StatelessWidget {
  const MyFilesDoctor({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final Size _size = MediaQuery.of(context).size;
    final dashboardProvider = Provider.of<DashboardDoctorProvider>(context);
    final data = dashboardProvider.data;

    if (dashboardProvider.isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    List<CloudStorageInfo> stats = [
      CloudStorageInfo(
        title: "Total Pacientes",
        numOfFiles: data?.totalPacientes ?? 0,
        svgSrc: "assets/icons/menu_profile.svg",
        totalStorage: "",
        color: Colors.blue,
        percentage: 100,
      ),
      CloudStorageInfo(
        title: "Arritmias Activas",
        numOfFiles: data?.arritmiasActivas ?? 0,
        svgSrc: "assets/icons/media.svg",
        totalStorage: "",
        color: Colors.red,
        percentage: 100,
      ),
      CloudStorageInfo(
        title: "Alertas Nuevas",
        numOfFiles: data?.totalAlertasRecientes ?? 0,
        svgSrc: "assets/icons/menu_notification.svg",
        totalStorage: "",
        color: Colors.orange,
        percentage: 100,
      ),
      CloudStorageInfo(
        title: "Consultas",
        numOfFiles: data?.proximasConsultas.length ?? 0,
        svgSrc: "assets/icons/menu_doc.svg",
        totalStorage: "",
        color: Colors.green,
        percentage: 100,
      ),
    ];

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Estadísticas Médicas",
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
        SizedBox(height: defaultPadding),
        Responsive(
          mobile: FileInfoCardGridView(
            crossAxisCount: _size.width < 650 ? 2 : 4,
            childAspectRatio: _size.width < 650 && _size.width > 350 ? 1.3 : 1,
            stats: stats,
          ),
          tablet: FileInfoCardGridView(stats: stats),
          desktop: FileInfoCardGridView(
            childAspectRatio: _size.width < 1400 ? 1.1 : 1.4,
            stats: stats,
          ),
        ),
      ],
    );
  }
}

class FileInfoCardGridView extends StatelessWidget {
  const FileInfoCardGridView({
    Key? key,
    this.crossAxisCount = 4,
    this.childAspectRatio = 1,
    required this.stats,
  }) : super(key: key);

  final int crossAxisCount;
  final double childAspectRatio;
  final List<CloudStorageInfo> stats;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      physics: NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: stats.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: defaultPadding,
        mainAxisSpacing: defaultPadding,
        childAspectRatio: childAspectRatio,
      ),
      itemBuilder: (context, index) => FileInfoCard(info: stats[index]),
    );
  }
}
