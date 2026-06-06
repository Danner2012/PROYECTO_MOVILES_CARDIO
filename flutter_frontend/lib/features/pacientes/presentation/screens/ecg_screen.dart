import 'dart:convert';
import 'dart:async'; // Añadido para el manejo de Timers en tiempo real
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fl_chart/fl_chart.dart';

class EcgScreen extends StatefulWidget {
  const EcgScreen({super.key});

  @override
  State<EcgScreen> createState() => _EcgScreenState();
}

class _EcgScreenState extends State<EcgScreen> with SingleTickerProviderStateMixin {
  List<Map<String, String>> _tableData = [];
  List<FlSpot> _chartPoints = []; 
  bool _isLoading = true;
  
  // Variables controladoras para los KPIs destacados
  String _currentBpm = '--';
  String _currentHrv = '--';
  String _deviceStatus = 'Desconectado';
  String _generalDiagnostic = 'Calculando...';
  
  // Controladores de tiempo real y ciclo de actualización
  Timer? _pollingTimer;
  DateTime? _lastRecordTime;
  bool _isHardwareConnected = false;

  // Animación para el icono del corazón latiente
  late AnimationController _heartAnimationController;
  late Animation<double> _heartScaleAnimation;

  @override
  void initState() {
    super.initState();
    
    // Inicialización del efecto de latido clínico
    _heartAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
    
    _heartScaleAnimation = Tween<double>(begin: 1.0, end: 1.25).animate(
      CurvedAnimation(parent: _heartAnimationController, curve: Curves.elasticOut)
    );

    // Primera carga manual
    _fetchEcgMetrics();

    // =========================================================================
    // TIMER DE ACTUALIZACIÓN CONTINUA (Sondeo cada 2 segundos)
    // =========================================================================
    _pollingTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      _fetchEcgMetrics();
      _checkWatchdogTimeout();
    });
  }

  @override
  void dispose() {
    _pollingTimer?.cancel(); // IMPORTANTE: Cancelar el timer para evitar fugas de memoria
    _heartAnimationController.dispose();
    super.dispose();
  }

  // =========================================================================
  // DETECTOR DE INACTIVIDAD (Watchdog de 5 segundos)
  // =========================================================================
  void _checkWatchdogTimeout() {
    if (_lastRecordTime == null) return;

    final difference = DateTime.now().difference(_lastRecordTime!).inSeconds;

    // Si pasaron más de 5 segundos sin actualizaciones reales en la BD
    if (difference > 5 && _isHardwareConnected) {
      setState(() {
        _isHardwareConnected = false;
        _deviceStatus = 'Desconectado';
        _currentBpm = '--';
        _currentHrv = '--';
        _generalDiagnostic = 'Sin Señal';
        
        // Al desconectarse, aplanamos la onda del ECG (Flatline con micro-ruido muerto)
        _generateFlatlinePoints(); 
      });
    }
  }

  // =========================================================================
  // CONSUMO DE API Y PARSEO PROFESIONAL DE DATOS
  // =========================================================================
  Future<void> _fetchEcgMetrics() async {
    final url = Uri.parse('http://127.0.0.1:8000/api/pacientes/ecg-metrics/');

    try {
      final prefs = await SharedPreferences.getInstance();
      final String? tokenJWT = prefs.getString('jwt_token') ?? prefs.getString('token'); 

      if (tokenJWT == null || tokenJWT.isEmpty) {
        return; // Evita romper la app si expira la sesión en segundo plano
      }

      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $tokenJWT',
        },
      );

      if (!mounted) return;

      // ... (dentro de tu método _fetchEcgMetrics, reemplaza el bloque del setState)

      if (response.statusCode == 200) {
        final List<dynamic> decodedData = json.decode(response.body);

        if (decodedData.isEmpty) {
          if (_isLoading) setState(() => _isLoading = false);
          return;
        }

        // ====== REVISIÓN Y PARSEO SEGURO DE LA MARCA DE TIEMPO PRINCIPAL ======
        final dynamic latestRawItem = decodedData.first;
        DateTime latestRecordUtc;
        
        try {
          if (latestRawItem['created_at'] != null && latestRawItem['created_at'].toString().isNotEmpty) {
            latestRecordUtc = DateTime.parse(latestRawItem['created_at'].toString());
          } else {
            latestRecordUtc = DateTime.now().toUtc(); // Fallback si es nulo o vacío
          }
        } catch (e) {
          latestRecordUtc = DateTime.now().toUtc(); // Fallback si el string no tiene formato ISO válido
          debugPrint('Aviso: Formato de fecha del backend no ISO, usando hora actual.');
        }
        
        _lastRecordTime = latestRecordUtc.toLocal();

        // Calcular la antigüedad del registro respecto a la hora local actual
        final int ageInSeconds = DateTime.now().difference(_lastRecordTime!).inSeconds.abs();
        
        setState(() {
          _tableData = decodedData.map((item) {
            String fechaFormateada = '---';
            String horaFormateada = '';
            
            // ====== PARSEO INDIVIDUAL SEGURO DE FILAS ======
            if (item['created_at'] != null && item['created_at'].toString().isNotEmpty) {
              try {
                // ... dentro de tu map en _fetchEcgMetrics
DateTime dateTime = DateTime.parse(item['created_at'].toString()).toLocal();

// Formato deseado: 2026-06-05 y 09:39:44
String fechaFormateada = "${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')}";
String horaFormateada = "${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}:${dateTime.second.toString().padLeft(2, '0')}";

// ... más abajo, en el return del map:
return {
  // ...
  'fecha': fechaFormateada,
  'hora': horaFormateada,
  // ...
};
              } catch (e) {
                // Si una fila tiene error de formato, evitamos el crash asignando valores por defecto
                fechaFormateada = '---';
                horaFormateada = '--:--:--';
              }
            }

            double bpmValue = double.tryParse(item['bpm']?.toString() ?? '0') ?? 0.0;
            String bpmDisplay = bpmValue < 10 ? 'Calibrando' : bpmValue.toStringAsFixed(1);

            String estadoCalculado = 'Normal';
            if (bpmValue > 100) {
              estadoCalculado = 'Taquicardia';
            } else if (bpmValue > 0 && bpmValue < 60) {
              estadoCalculado = 'Bradicardia';
            } else if (bpmValue <= 0 || bpmDisplay == 'Calibrando') {
              estadoCalculado = 'Inestable';
            }

            return {
              'id': item['id']?.toString() ?? '',
              'fecha': fechaFormateada,
              'hora': horaFormateada,
              'bpm': bpmDisplay,
              'bpm_average': item['bpm_average']?.toString() ?? '--',
              'hrv': item['hrv']?.toString() ?? '--',
              'beat_detected': (item['beat_detected'] == true || item['beat_detected'] == 'true') ? 'Sí' : 'No',
              'electrodes_connected': (item['electrodes_connected'] == true || item['electrodes_connected'] == 'true') ? 'Conectado' : 'Desconectado',
              'estado': estadoCalculado,
            };
          }).toList();

          // Evaluar conectividad de hardware real vs el Watchdog temporal
          if (ageInSeconds <= 5) {
            _isHardwareConnected = true;
            final latest = _tableData.first;
            _currentBpm = latest['bpm']!;
            _currentHrv = latest['hrv'] != '--' ? "${latest['hrv']} ms" : '--';
            _deviceStatus = latest['electrodes_connected']!;
            _generalDiagnostic = latest['estado']!;
            
            _generateEcgWavePoints(); // Dibujar el pulso activo
          } else {
            _isHardwareConnected = false;
            _deviceStatus = 'Desconectado';
            _currentBpm = '--';
            _currentHrv = '--';
            _generalDiagnostic = 'Sin Señal';
            
            _generateFlatlinePoints(); // Dibujar línea muerta
          }

          _isLoading = false;
        });
      }

// ... (el resto del código de la función permanece igual)
    } catch (e) {
      // Manejo silencioso durante el sondeo repetitivo para evitar overlays de error molestos
      debugPrint('Error de comunicación continua: $e');
    }
  }

  void _generateEcgWavePoints() {
    _chartPoints.clear();
    double parsedBpm = double.tryParse(_currentBpm) ?? 75.0;
    if (parsedBpm < 10) parsedBpm = 75.0; 
    
    double frequencyFactor = parsedBpm / 70.0; 
    int totalPoints = 120; 

    for (int i = 0; i < totalPoints; i++) {
      double x = i.toDouble();
      double angle = (i * 0.35) * frequencyFactor;
      double y = 0.0;

      if (i % 24 == 0) {
        y = 5.0; 
      } else if (i % 24 == 23) {
        y = -1.5; 
      } else if (i % 24 == 1) {
        y = -0.8; 
      } else if (i % 24 == 6) {
        y = 0.6; 
      } else if (i % 24 == 18) {
        y = 0.3; 
      } else {
        y = math.sin(angle) * 0.05; 
      }

      _chartPoints.add(FlSpot(x, y));
    }
  }

  void _generateFlatlinePoints() {
    _chartPoints.clear();
    // Recrea una línea isoeléctrica casi horizontal (asincronía o desconexión física)
    for (int i = 0; i < 120; i++) {
      double noise = (math.Random().nextDouble() - 0.5) * 0.04; // Ruido electromagnético tenue de fondo
      _chartPoints.add(FlSpot(i.toDouble(), noise));
    }
  }

  // =========================================================================
  // VISTAS Y WIDGETS
  // =========================================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0F1D), 
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.monitor_heart, color: Colors.greenAccent),
            SizedBox(width: 10),
            Text('Estación de Monitoreo Crítico ECG', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        backgroundColor: const Color(0xFF141829),
        elevation: 0,
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _isHardwareConnected ? Colors.greenAccent.withOpacity(0.1) : Colors.redAccent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _isHardwareConnected ? Colors.greenAccent : Colors.redAccent, width: 1)
                ),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _isHardwareConnected ? Colors.greenAccent : Colors.redAccent,
                        shape: BoxShape.circle
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _isHardwareConnected ? 'TELEMETRÍA ACTIVA' : 'SISTEMA DOWN',
                      style: TextStyle(
                        color: _isHardwareConnected ? Colors.greenAccent : Colors.redAccent, 
                        fontSize: 11, 
                        fontWeight: FontWeight.bold
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.greenAccent))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildKpiGrid(),
                  const SizedBox(height: 24),
                  const Text(
                    'ONDA ELECTROCARDIOGRÁFICA EN VIVO',
                    style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.5),
                  ),
                  const SizedBox(height: 10),
                  _buildOscilloscopeContainer(),
                  const SizedBox(height: 28),
                  const Text(
                    'REGISTROS BIOMÉTRICOS RECIENTES (POSTGRESQL)',
                    style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.5),
                  ),
                  const SizedBox(height: 10),
                  _buildDataTable(),
                ],
              ),
            ),
    );
  }

  Widget _buildKpiGrid() {
    return GridView.count(
      crossAxisCount: MediaQuery.of(context).size.width > 800 ? 4 : 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _buildCard(
          title: 'FRECUENCIA CARDÍACA',
          value: _isHardwareConnected ? '$_currentBpm BPM' : '--',
          icon: _isHardwareConnected 
            ? ScaleTransition(
                scale: _heartScaleAnimation,
                child: const Icon(Icons.favorite, color: Colors.redAccent, size: 28),
              )
            : const Icon(Icons.favorite_border, color: Colors.grey, size: 28),
          color: _isHardwareConnected ? Colors.redAccent : Colors.grey,
        ),
        _buildCard(
          title: 'VARIABILIDAD (HRV)',
          value: _currentHrv,
          icon: Icon(Icons.waves, color: _isHardwareConnected ? Colors.blueAccent : Colors.grey, size: 28),
          color: _isHardwareConnected ? Colors.blueAccent : Colors.grey,
        ),
        _buildCard(
          title: 'HARDWARE (ESP32-S3)',
          value: _deviceStatus,
          icon: Icon(
            Icons.developer_board, 
            color: _isHardwareConnected ? Colors.greenAccent : Colors.redAccent, 
            size: 28
          ),
          color: _isHardwareConnected ? Colors.greenAccent : Colors.redAccent,
        ),
        _buildCard(
          title: 'DIAGNÓSTICO PRELIMINAR',
          value: _generalDiagnostic,
          icon: Icon(Icons.analytics, color: _isHardwareConnected ? Colors.purpleAccent : Colors.grey, size: 28),
          color: _isHardwareConnected ? Colors.purpleAccent : Colors.grey,
        ),
      ],
    );
  }

  Widget _buildCard({required String title, required String value, Widget? icon, required Color color}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF141829),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.15), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(title, style: const TextStyle(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.bold)),
              ),
              if (icon != null) icon,
            ],
          ),
          const SizedBox(height: 10),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }

  Widget _buildOscilloscopeContainer() {
    // Si está desconectado, cambiamos el color de la gráfica a un gris/rojo tenue en vez del verde brillante activo
    Color chartLineColor = _isHardwareConnected ? Colors.greenAccent : Colors.redAccent.withOpacity(0.4);

    return Container(
      height: 280,
      padding: const EdgeInsets.only(top: 24, bottom: 16, right: 20, left: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF090B14), 
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: chartLineColor.withOpacity(0.2), width: 2),
      ),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: true,
            horizontalInterval: 1,
            verticalInterval: 6,
            getDrawingHorizontalLine: (value) => FlLine(color: chartLineColor.withOpacity(0.04), strokeWidth: 1),
            getDrawingVerticalLine: (value) => FlLine(color: chartLineColor.withOpacity(0.04), strokeWidth: 1),
          ),
          titlesData: const FlTitlesData(
            leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          minX: 0,
          maxX: 119,
          minY: -2.5,
          maxY: 5.5,
          lineBarsData: [
            LineChartBarData(
              spots: _chartPoints,
              isCurved: _isHardwareConnected, // Solo curva el trazo si hay pulso real activo
              color: chartLineColor, 
              barWidth: _isHardwareConnected ? 3.0 : 1.5, 
              isStrokeCapRound: true,
              dotData: const FlDotData(show: false),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataTable() {
    if (_tableData.isEmpty) {
      return const Center(child: Padding(
        padding: EdgeInsets.all(20.0),
        child: Text("No hay registros biométricos.", style: TextStyle(color: Colors.white38)),
      ));
    }
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF141829), 
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(const Color(0xFF1C213A)),
          columns: const [
            DataColumn(label: Text('Fecha y Hora', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Métrica BPM', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Estado Clínico', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
          ],
          rows: _tableData.take(5).map((item) {
            Color statusColor = Colors.greenAccent;
            if (item['estado'] == 'Taquicardia' || item['estado'] == 'Bradicardia') {
              statusColor = Colors.redAccent;
            } else if (item['estado'] == 'Inestable') {
              statusColor = Colors.amberAccent;
            }

            return DataRow(cells: [
  DataCell(
    Text(
      '${item['fecha']}   ${item['hora']}', 
      style: const TextStyle(color: Colors.white70, fontSize: 13, fontFamily: 'monospace') // 'monospace' ayuda a que los números se alineen mejor
    )
  ),
  DataCell(
    Text(
      item['bpm'] != 'Calibrando' ? '${item['bpm']} bpm' : 'Calibrando', 
      style: const TextStyle(color: Colors.white70, fontSize: 13)
    )
  ),
  DataCell(
    Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        item['estado']!,
        style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12),
      ),
    )
  ),
]);
          }).toList(),
        ),
      ),
    );
  }
}