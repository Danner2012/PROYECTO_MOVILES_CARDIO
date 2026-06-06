// features/pacientes/presentation/screens/ecg_screen.dart

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
// ✅ Importación añadida para resolver el error de SharedPreferences
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math' as math;
class EcgScreen extends StatefulWidget {
  const EcgScreen({super.key});

  @override
  State<EcgScreen> createState() => _EcgScreenState();
}

class _EcgScreenState extends State<EcgScreen> {
  bool isDeviceActive = true;
  List<Map<String, String>> _tableData = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchEcgMetrics(); 
  }

  // =========================================================================
  // FUNCIÓN ASÍNCRONA: CONEXIÓN AL ENDPOINT PROTEGIDO DE DJANGO
  // =========================================================================
  Future<void> _fetchEcgMetrics() async {
  if (!mounted) return;
  setState(() => _isLoading = true);

  print('=== [1] INICIANDO _fetchEcgMetrics ===');
  final url = Uri.parse('http://127.0.0.1:8000/api/pacientes/ecg-metrics/');
try {
    // 1. EXTRAER EL TOKEN
    final prefs = await SharedPreferences.getInstance();
    
    print('=== [DEBUG] LLAVES DISPONIBLES EN SHAREDPREFERENCES ===');
    final Set<String> keys = prefs.getKeys();
    if (keys.isEmpty) {
      print('¡Alerta! SharedPreferences está completamente vacío en este navegador.');
    } else {
      for (String key in keys) {
        print('-> Llave encontrada: "$key" = ${prefs.get(key)}');
      }
    }
    print('======================================================');

    // Intentamos buscar por las llaves conocidas o agrega aquí la que descubras en la consola
    final String? tokenJWT = prefs.getString('jwt_token') ?? 
                             prefs.getString('token') ?? 
                             prefs.getString('access'); // Agregada por si usas Simple JWT de Django

    print('=== [2] BUSCANDO TOKEN ===');
    print('Token encontrado: ${tokenJWT != null ? "SÍ (empieza con ${tokenJWT.substring(0, math.min(10, tokenJWT.length))}...)" : "NO (NULL)"}');

    if (tokenJWT == null || tokenJWT.isEmpty) {
      throw Exception('No se encontró un token de sesión válido. Por favor, inicia sesión de nuevo.');
    }    // 2. ENVIANDO PETICIÓN
    print('=== [3] ENVIANDO PETICIÓN HTTP GET A: $url ===');
    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $tokenJWT',
      },
    );

    print('=== [4] RESPUESTA RECIBIDA ===');
    print('Código de estado HTTP: ${response.statusCode}');
    print('Cuerpo de la respuesta (Raw Body): ${response.body}');

    if (!mounted) {
      print('=== [!] EL COMPONENTE YA NO ESTÁ MONTADO (Se cerró la pantalla) ===');
      return;
    }

    if (response.statusCode == 200) {
      final List<dynamic> decodedData = json.decode(response.body);
      print('Cantidad de registros decodificados: ${decodedData.length}');

      setState(() {
        _tableData = decodedData.map((item) {
          String fechaFormateada = 'Sin fecha';
          String horaFormateada = 'Sin hora';
          
          if (item['created_at'] != null) {
            try {
              DateTime dateTime = DateTime.parse(item['created_at'].toString()).toLocal();
              fechaFormateada = "${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')}";
              horaFormateada = "${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}:${dateTime.second.toString().padLeft(2, '0')}";
            } catch (e) {
              fechaFormateada = 'Error formato';
            }
          }

          double bpmValue = double.tryParse(item['bpm']?.toString() ?? '0') ?? 0.0;
          String estadoCalculado = 'Normal';
          if (bpmValue > 100) {
            estadoCalculado = 'Taquicardia';
          } else if (bpmValue < 60 && bpmValue > 0) {
            estadoCalculado = 'Bradicardia';
          }

          return {
            'id': item['id']?.toString() ?? '',
            'fecha': fechaFormateada,
            'hora': horaFormateada,
            'bpm': item['bpm']?.toString() ?? '0',
            'bpm_average': item['bpm_average']?.toString() ?? '0',
            'hrv': item['hrv']?.toString() ?? '0',
            'beat_detected': (item['beat_detected'] == true || item['beat_detected'] == 'true') ? 'Sí' : 'No',
            'electrodes_connected': (item['electrodes_connected'] == true || item['electrodes_connected'] == 'true') ? 'Conectado' : 'Desconectado',
            'estado': estadoCalculado,
          };
        }).toList();
        
        _isLoading = false;
      });
      
      print('=== [5] MAPEO EXITOSO: _tableData actualizado con ${_tableData.length} filas ===');

    } else {
      final Map<String, dynamic> errorResponse = json.decode(response.body);
      throw Exception(errorResponse['detail'] ?? 'Error del servidor (Código ${response.statusCode})');
    }
  } catch (e) {
    print('=== [X] ERROR CAPTURADO EN EL CATCH ===');
    print('Detalle del error: $e');
    
    if (!mounted) return;
    setState(() => _isLoading = false);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Error de Telemetría: $e'),
        backgroundColor: Colors.redAccent,
        duration: const Duration(seconds: 4),
      ),
    );
  }
}
  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF1E1E26), 
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Monitoreo de Electrocardiograma',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh, color: Colors.tealAccent),
                  onPressed: _fetchEcgMetrics,
                  tooltip: 'Refrescar Datos',
                ),
              ],
            ),
            const SizedBox(height: 20),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    _buildStatusIndicator(isDeviceActive),
                    const SizedBox(width: 12),
                    Text(
                      isDeviceActive ? 'Dispositivo: ACTIVO' : 'Dispositivo: DESCONECTADO',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white70),
                    ),
                  ],
                ),

                SizedBox(
                  width: 160,
                  height: 40,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        isDeviceActive = !isDeviceActive;
                      });
                      _fetchEcgMetrics(); 
                    },
                    icon: const Icon(Icons.sync),
                    label: const Text('Reconectar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 32, color: Colors.white24),

            const Text(
              'Señal ECG en Tiempo Real',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.tealAccent),
            ),
            const SizedBox(height: 12),
            Container(
              height: 220,
              width: double.infinity,
              padding: const EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                color: Colors.black, 
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.teal.shade700, width: 2),
              ),
              child: isDeviceActive
                  ? _buildEcgChartPlaceholder()
                  : const Center(
                      child: Text(
                        'Sin señal - Dispositivo desconectado',
                        style: TextStyle(color: Colors.red, fontSize: 16),
                      ),
                    ),
            ),
            const Divider(height: 32, color: Colors.white24),

            const Text(
              'Historial de Análisis y Métricas',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.tealAccent),
            ),
            const SizedBox(height: 12),

            _isLoading
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 40.0),
                    child: Center(child: CircularProgressIndicator(color: Colors.tealAccent)),
                  )
                : _tableData.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.symmetric(vertical: 40.0),
                        child: Center(
                          child: Text(
                            'No hay registros biométricos en ecg_db.',
                            style: TextStyle(color: Colors.white60),
                          ),
                        ),
                      )
                    : _buildMetricsTable(),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // MÉTODOS AUXILIARES DE RENDERIZADO
  // ==========================================
  Widget _buildStatusIndicator(bool active) {
    return Container(
      width: 16,
      height: 16,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: active ? Colors.green : Colors.red,
        boxShadow: [
          BoxShadow(
            color: active ? Colors.green.withOpacity(0.6) : Colors.red.withOpacity(0.6),
            blurRadius: 8,
            spreadRadius: 2,
          ),
        ],
      ),
    );
  }

  Widget _buildEcgChartPlaceholder() {
    return CustomPaint(
      painter: EcgPainter(), // ✅ Ahora es visible al estar ambas clases al mismo nivel top-level
      child: Container(),
    );
  }

  Widget _buildMetricsTable() {
    return Container(
      width: MediaQuery.of(context).size.width,
      decoration: BoxDecoration(
        color: const Color(0xFF292933),
        borderRadius: BorderRadius.circular(8),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(Colors.teal.shade700.withOpacity(0.3)),
          columns: const [
            DataColumn(label: Text('N°', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.tealAccent))),
            DataColumn(label: Text('Fecha', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.tealAccent))),
            DataColumn(label: Text('Hora', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.tealAccent))),
            DataColumn(label: Text('BPM', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.tealAccent))),
            DataColumn(label: Text('Prom. BPM', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.tealAccent))),
            DataColumn(label: Text('HRV (ms)', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.tealAccent))),
            DataColumn(label: Text('Latido', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.tealAccent))),
            DataColumn(label: Text('Electrodos', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.tealAccent))),
            DataColumn(label: Text('Estado', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.tealAccent))),
          ],
          rows: _tableData.map((data) {
            final isTaquicardia = data['estado'] == 'Taquicardia';
            return DataRow(
              cells: [
                DataCell(Text(data['id'] ?? '', style: const TextStyle(color: Colors.white))),
                DataCell(Text(data['fecha'] ?? '', style: const TextStyle(color: Colors.white70))),
                DataCell(Text(data['hora'] ?? '', style: const TextStyle(color: Colors.white70))),
                DataCell(Text(data['bpm'] ?? '', style: const TextStyle(color: Colors.white))),
                DataCell(Text(data['bpm_average'] ?? '', style: const TextStyle(color: Colors.white70))),
                DataCell(Text(data['hrv'] ?? '', style: const TextStyle(color: Colors.white70))),
                DataCell(Text(data['beat_detected'] ?? '', style: const TextStyle(color: Colors.white70))),
                DataCell(Text(data['electrodes_connected'] ?? '', style: const TextStyle(color: Colors.white70))),
                DataCell(
                  Text(
                    data['estado'] ?? 'Normal',
                    style: TextStyle(
                      color: isTaquicardia ? Colors.redAccent : Colors.greenAccent,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
} // 👈 ¡Aquí cierra correctamente la clase _EcgScreenState!

// ==========================================
// PINTOR PERSONALIZADO: CUADRÍCULA Y ONDA ECG (Ubicado en el Top-Level)
// ==========================================
class EcgPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paintGrid = Paint()
      ..color = Colors.teal.withOpacity(0.15)
      ..strokeWidth = 1.0;

    double step = 15;
    for (double i = 0; i < size.width; i += step) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paintGrid);
    }
    for (double i = 0; i < size.height; i += step) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paintGrid);
    }

    final paintLine = Paint()
      ..color = Colors.greenAccent
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round;

    final path = Path();
    path.moveTo(0, size.height * 0.5);

    double mid = size.height * 0.5;

    for (double x = 0; x < size.width; x++) {
      double cycleX = x % 120;
      double y = mid;

      if (cycleX > 20 && cycleX <= 30) {
        y = mid - 8 * (1 - ((cycleX - 25).abs() / 5));
      } else if (cycleX > 40 && cycleX <= 44) {
        y = mid + 10 * ((cycleX - 40) / 4);
      } else if (cycleX > 44 && cycleX <= 48) {
        y = mid - 70 * (1 - ((cycleX - 48).abs() / 4));
      } else if (cycleX > 48 && cycleX <= 54) {
        y = mid + 20 * (1 - ((cycleX - 51).abs() / 3));
      } else if (cycleX > 70 && cycleX <= 90) {
        y = mid - 15 * (1 - ((cycleX - 80).abs() / 10));
      }

      path.lineTo(x, y);
    }

    canvas.drawPath(path, paintLine);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}