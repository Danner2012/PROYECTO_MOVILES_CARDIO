import 'dart:convert';
import 'dart:async'; 
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

class _EcgScreenState extends State<EcgScreen> with TickerProviderStateMixin {
  List<Map<String, String>> _tableData = [];
  final List<FlSpot> _chartPoints = []; 
  bool _isLoading = true;
  
  String _currentBpm = '--';
  String _currentHrv = '--';
  String _deviceStatus = 'Desconectado';
  String _generalDiagnostic = 'Calculando...';
  
  Timer? _pollingTimer;
  Timer? _waveformTimer; // Timer acelerado para la fluidez de la onda
  DateTime? _lastRecordTime;
  bool _isHardwareConnected = false;
  String _lastProcessedId = ''; 

  late AnimationController _heartAnimationController;
  late Animation<double> _heartScaleAnimation;

  // Variables para simular el barrido del electrocardiógrafo
  double _tickCounter = 0;
  final int _maxVisiblePoints = 150; // Puntos visibles concurrentes en pantalla

  @override
  void initState() {
    super.initState();
    
    _heartAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);
    
    _heartScaleAnimation = Tween<double>(begin: 1.0, end: 1.22).animate(
      CurvedAnimation(parent: _heartAnimationController, curve: Curves.easeInOut)
    );

    _fetchEcgMetrics();

    // Sondeo de API REST de fondo cada 3 segundos
    _pollingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _fetchEcgMetrics();
      _checkWatchdogTimeout();
    });

    // =========================================================================
    // TIMER DE ALTA VELOCIDAD: Genera el desplazamiento fluido por milisegundos
    // =========================================================================
    _waveformTimer = Timer.periodic(const Duration(milliseconds: 40), (timer) {
      if (!mounted) return;
      _updateLiveOscilloscope();
    });
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _waveformTimer?.cancel();
    _heartAnimationController.dispose();
    super.dispose();
  }

  // Actualiza los puntos uno a uno recreando la señal fisiológica
  void _updateLiveOscilloscope() {
    setState(() {
      _tickCounter++;
      double yValue = 0.0;

      if (_isHardwareConnected) {
        // Ciclo plano e invariable ajustado a la velocidad del timer (40ms)
        const double cycleLength = 25.0; 
        double phase = _tickCounter % cycleLength;

        // Complejo P-Q-R-S-T con proporciones rígidas e inmunes al movimiento
        if (phase >= 0 && phase < 2.5) {
          yValue = 0.35 * math.sin((phase / 2.5) * math.pi); // Onda P
        } else if (phase >= 3.5 && phase < 4.5) {
          yValue = -0.5; // Onda Q
        } else if (phase >= 4.5 && phase < 6.0) {
          yValue = 5.0; // Complejo R (Voltaje máximo estable)
        } else if (phase >= 6.0 && phase < 7.2) {
          yValue = -1.5; // Onda S
        } else if (phase >= 9.5 && phase < 13.0) {
          yValue = 0.75 * math.sin(((phase - 9.5) / 3.5) * math.pi); // Onda T
        } else {
          yValue = (math.Random().nextDouble() - 0.5) * 0.015; // Ruido base mínimo uniforme
        }
      } else {
        // Línea base con micro-interferencia electromagnética lineal uniforme
        yValue = (math.Random().nextDouble() - 0.5) * 0.03;
      }

      // Agrega el nuevo punto en el extremo derecho
      _chartPoints.add(FlSpot(_tickCounter, yValue));
      
      // Mantenemos un búfer extendido (el doble del tamaño visible) fuera de la pantalla.
      // Esto evita que la gráfica "salte" o se moche bruscamente al eliminar puntos del inicio.
      if (_chartPoints.length > (_maxVisiblePoints * 2)) {
        _chartPoints.removeAt(0);
      }
    });
  }

  Future<void> _fetchEcgMetrics() async {
    final url = Uri.parse('http://127.0.0.1:8000/api/pacientes/ecg-metrics/');

    try {
      final prefs = await SharedPreferences.getInstance();
      final String? tokenJWT = prefs.getString('jwt_token') ?? prefs.getString('token'); 

      if (tokenJWT == null || tokenJWT.isEmpty) return; 

      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $tokenJWT',
        },
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final List<dynamic> decodedData = json.decode(response.body);

        if (decodedData.isEmpty) {
          if (_isLoading) setState(() => _isLoading = false);
          return;
        }

        final dynamic latestRawItem = decodedData.first;
        final String currentLatestId = latestRawItem['id']?.toString() ?? '';
        
        bool hasNewData = _lastProcessedId.isEmpty || (currentLatestId != _lastProcessedId);
        _lastProcessedId = currentLatestId;

        setState(() {
          _tableData = decodedData.map((item) {
            String fechaDisplay = item['fecha']?.toString() ?? '---';
            String horaDisplay = item['hora']?.toString() ?? '--:--:--';
            double bpmValue = double.tryParse(item['bpm']?.toString() ?? '0') ?? 0.0;
            String bpmDisplay = bpmValue < 10 ? 'Calibrando' : bpmValue.toStringAsFixed(1);

            String estadoCalculado = 'Normal';
            if (bpmValue > 100) estadoCalculado = 'Taquicardia';
            else if (bpmValue > 0 && bpmValue < 60) estadoCalculado = 'Bradicardia';
            else if (bpmValue <= 0 || bpmDisplay == 'Calibrando') estadoCalculado = 'Inestable';

            return {
              'id': item['id']?.toString() ?? '',
              'fecha': fechaDisplay,
              'hora': horaDisplay,
              'bpm': bpmDisplay,
              'bpm_average': item['bpm_average']?.toString() ?? '--',
              'hrv': item['hrv']?.toString() ?? '--',
              'beat_detected': item['beat_detected']?.toString() ?? 'No',
              'electrodes_connected': (item['electrodes_connected'] == true || item['electrodes_connected'] == 'Conectado') ? 'Conectado' : 'Desconectado',
              'estado': item['estado']?.toString() ?? estadoCalculado,
            };
          }).toList();

          if (hasNewData) {
            _isHardwareConnected = true;
            _lastRecordTime = DateTime.now();
            
            final latest = _tableData.first;
            _currentBpm = latest['bpm']!;
            _currentHrv = latest['hrv'] != '--' ? "${latest['hrv']} ms" : '--';
            _deviceStatus = latest['electrodes_connected']!;
            _generalDiagnostic = latest['estado']!;
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('🚨 Error ECG: $e');
    }
  }

  void _checkWatchdogTimeout() {
    if (_lastRecordTime == null) return;
    final int difference = DateTime.now().difference(_lastRecordTime!).inSeconds;

    if (difference > 6 && _isHardwareConnected) {
      setState(() {
        _isHardwareConnected = false;
        _deviceStatus = 'Desconectado';
        _currentBpm = '---';
        _currentHrv = '---';
        _generalDiagnostic = 'Sin Señal';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0C14), 
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.monitor_heart, color: _isHardwareConnected ? Colors.greenAccent : Colors.redAccent),
            const SizedBox(width: 10),
            const Text('CENTRAL DE MONITOREO ECG', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 0.5)),
          ],
        ),
        backgroundColor: const Color(0xFF111424),
        elevation: 1,
        actions: [_buildStatusBadge()],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.greenAccent))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildKpiGrid(),
                  const SizedBox(height: 20),
                  _buildSectionHeader('TRAZADO DE ONDA EN TIEMPO REAL (PAPEL MILIMETRADO)'),
                  const SizedBox(height: 8),
                  _buildOscilloscopeContainer(),
                  const SizedBox(height: 24),
                  _buildSectionHeader('HISTORIAL DE REGISTROS DE TELEMETRÍA'),
                  const SizedBox(height: 8),
                  _buildDataTable(),
                ],
              ),
            ),
    );
  }

  Widget _buildStatusBadge() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(right: 16.0),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: _isHardwareConnected ? Colors.greenAccent.withOpacity(0.08) : Colors.redAccent.withOpacity(0.08),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: _isHardwareConnected ? Colors.greenAccent : Colors.redAccent, width: 1)
          ),
          child: Row(
            children: [
              Icon(Icons.circle, size: 8, color: _isHardwareConnected ? Colors.greenAccent : Colors.redAccent),
              const SizedBox(width: 6),
              Text(
                _isHardwareConnected ? 'LIVE FEED' : 'NO SIGNAL',
                style: TextStyle(color: _isHardwareConnected ? Colors.greenAccent : Colors.redAccent, fontSize: 10, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2),
    );
  }

  Widget _buildKpiGrid() {
    return GridView.count(
      crossAxisCount: MediaQuery.of(context).size.width > 800 ? 4 : 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.4,
      children: [
        _buildCard(
          title: 'FRECUENCIA CARDÍACA',
          value: _isHardwareConnected ? '$_currentBpm BPM' : '--',
          icon: _isHardwareConnected 
            ? ScaleTransition(scale: _heartScaleAnimation, child: const Icon(Icons.favorite, color: Colors.redAccent, size: 24))
            : const Icon(Icons.favorite_border, color: Colors.grey, size: 24),
          color: Colors.redAccent,
        ),
        _buildCard(
          title: 'VARIABILIDAD (HRV)',
          value: _currentHrv,
          icon: const Icon(Icons.analytics_outlined, color: Colors.blueAccent, size: 24),
          color: Colors.blueAccent,
        ),
        _buildCard(
          title: 'HARDWARE wifi',
          value: _deviceStatus,
          icon: Icon(Icons.router, color: _isHardwareConnected ? Colors.greenAccent : Colors.redAccent, size: 24),
          color: Colors.greenAccent,
        ),
        _buildCard(
          title: 'DIAGNÓSTICO',
          value: _generalDiagnostic,
          icon: const Icon(Icons.healing, color: Colors.amberAccent, size: 24),
          color: Colors.amberAccent,
        ),
      ],
    );
  }

  Widget _buildCard({required String title, required String value, required Widget icon, required Color color}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF111424),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.03)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold)),
              icon,
            ],
          ),
          Text(value, style: TextStyle(color: _isHardwareConnected ? Colors.white : Colors.white38, fontSize: 20, fontWeight: FontWeight.bold, fontFamily: 'monospace')),
        ],
      ),
    );
  }

  // =========================================================================
  // EL OSCILOSCOPIO CLÍNICO PROFESIONAL
  // =========================================================================
  Widget _buildOscilloscopeContainer() {
    Color traceColor = _isHardwareConnected ? const Color(0xFF00FF66) : const Color(0xFFFF3333);
    Color gridColorMajor = const Color(0xFFFF8888).withOpacity(0.20); 
    Color gridColorMinor = const Color(0xFFFF8888).withOpacity(0.06);

    // CRÍTICO: Ventana deslizante estricta acoplada milimétricamente al incremento del tiempo
    double currentMaxX = _tickCounter;
    double currentMinX = _tickCounter - _maxVisiblePoints;
    
    // Control inicial para cuando la app arranca de cero
    if (currentMinX < 0) {
      currentMinX = 0;
      currentMaxX = _maxVisiblePoints.toDouble();
    }

    return Container(
      height: 260,
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF04060A), // Fondo ultra oscuro de monitor médico LCD
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withOpacity(0.06), width: 1.5),
      ),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: true,
            horizontalInterval: 0.5, 
            verticalInterval: 5.0, // Forzamos intervalos enteros para que la grilla no parpadee ni vibre
            getDrawingHorizontalLine: (value) {
              bool isMajor = (value % 2.5 == 0);
              return FlLine(color: isMajor ? gridColorMajor : gridColorMinor, strokeWidth: isMajor ? 1.2 : 0.6);
            },
            getDrawingVerticalLine: (value) {
              bool isMajor = (value % 25.0 == 0);
              return FlLine(color: isMajor ? gridColorMajor : gridColorMinor, strokeWidth: isMajor ? 1.2 : 0.6);
            },
          ),
          titlesData: const FlTitlesData(
            leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          
          // BLOQUEO ABSOLUTO DE EJES: Mueve el lienzo horizontal de forma perfecta
          minX: currentMinX,
          maxX: currentMaxX,
          minY: -2.0,
          maxY: 5.5,
          
          lineBarsData: [
            LineChartBarData(
              spots: _chartPoints,
              isCurved: false, // ¡IMPRESCINDIBLE!: En modo recto lineal eliminas por completo las deformaciones al avanzar
              color: traceColor, 
              barWidth: 2.2, 
              isStrokeCapRound: true,
              dotData: const FlDotData(show: false),
              shadow: Shadow(blurRadius: 5, color: traceColor.withOpacity(0.4)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataTable() {
    if (_tableData.isEmpty) {
      return const Center(child: Padding(
        padding: EdgeInsets.all(24.0),
        child: Text("Esperando sincronización de base de datos...", style: TextStyle(color: Colors.white24, fontSize: 13)),
      ));
    }
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF111424), 
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.02)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(const Color(0xFF171B30)),
          horizontalMargin: 16,
          columnSpacing: 10,
          columns: const [
            DataColumn(label: Text('Muestra Temporal', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Métrica', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Estado', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold))),
          ],
          rows: _tableData.take(5).map((item) {
            Color statusColor = Colors.greenAccent;
            if (item['estado'] == 'Taquicardia' || item['estado'] == 'Bradicardia') {
              statusColor = Colors.redAccent;
            } else if (item['estado'] == 'Inestable') {
              statusColor = Colors.amberAccent;
            }

            return DataRow(cells: [
              DataCell(Text('${item['fecha']}   ${item['hora']}', style: const TextStyle(color: Colors.white54, fontSize: 12, fontFamily: 'monospace'))),
              // CORREGIDO: Usamos white con opacidad manual en lugar de white80 para evitar el error de compilación
              DataCell(Text('${item['bpm']} BPM', style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12, fontWeight: FontWeight.w600))),
              DataCell(
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: statusColor.withOpacity(0.08), borderRadius: BorderRadius.circular(4)),
                  child: Text(item['estado']!.toUpperCase(), style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 10, letterSpacing: 0.5)),
                ),
              ),
            ]);
          }).toList(),
        ),
      ),
    );
  }
}