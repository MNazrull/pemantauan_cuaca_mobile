import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class SensorScreen extends StatefulWidget {
  const SensorScreen({super.key});

  @override
  State<SensorScreen> createState() => _SensorScreenState();
}

class _SensorScreenState extends State<SensorScreen> with TickerProviderStateMixin {
  final DatabaseReference _sensorRef = FirebaseDatabase.instance.ref('sensor');
  
  // Animation controllers
  late AnimationController _pulseController;
  late AnimationController _slideController;
  late Animation<double> _pulseAnimation;
  late Animation<Offset> _slideAnimation;

  // Sensor data
  double suhu = 0;
  double kelembapan = 0;
  double lux = 0;
  bool hujan = false;
  String statusAtap = 'unknown';
  
  // Connection status
  bool isConnected = false;
  DateTime? lastUpdate;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _listenToSensorData();
  }

  void _initAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.elasticOut,
    ));

    _slideController.forward();
  }

  void _listenToSensorData() {
    _sensorRef.onValue.listen(
      (DatabaseEvent event) {
        final data = event.snapshot.value as Map?;
        if (data != null) {
          setState(() {
            suhu = (data['suhu'] ?? 0).toDouble();
            kelembapan = (data['kelembapan'] ?? 0).toDouble();
            lux = (data['lux'] ?? 0).toDouble();
            hujan = (data['hujan'] ?? false) as bool;
            
            // Logika baru: status atap berdasarkan intensitas cahaya
            statusAtap = _getAtapStatusByLight(lux);
            
            isConnected = true;
            lastUpdate = DateTime.now();
          });
        }
      },
      onError: (error) {
        setState(() {
          isConnected = false;
        });
      },
    );
  }

  // Fungsi baru untuk menentukan status atap berdasarkan cahaya
  String _getAtapStatusByLight(double luxValue) {
    if (luxValue <= 160) {
      return 'tertutup'; // Gelap
    } else {
      return 'terbuka'; // Terang
    }
  }

  Color _getTemperatureColor(double temp) {
    if (temp < 20) return Colors.blue[300]!;
    if (temp < 25) return Colors.green[300]!;
    if (temp < 30) return Colors.orange[300]!;
    return Colors.red[300]!;
  }

  Color _getHumidityColor(double humidity) {
    if (humidity < 30) return Colors.brown[300]!;
    if (humidity < 60) return Colors.lightBlue[300]!;
    return Colors.indigo[300]!;
  }

  Color _getLightColor(double lightLevel) {
    if (lightLevel <= 160) return Colors.grey[700]!;  // Gelap (≤ 160 lux)
    return Colors.amber[600]!;  // Terang (> 160 lux)
  }

  // Fungsi untuk mendapatkan warna status atap
  Color _getAtapColor(String status) {
    if (status.toLowerCase() == 'tertutup') {
      return Colors.red[400]!; // Merah untuk tertutup
    } else if (status.toLowerCase() == 'terbuka') {
      return Colors.green[400]!; // Hijau untuk terbuka
    }
    return Colors.grey[400]!; // Abu-abu untuk unknown
  }

  Widget _buildConnectionStatus() {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isConnected ? Colors.green[100] : Colors.red[100],
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isConnected ? Colors.green : Colors.red,
          width: 2,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ScaleTransition(
            scale: _pulseAnimation,
            child: Icon(
              isConnected ? Icons.wifi : Icons.wifi_off,
              color: isConnected ? Colors.green[700] : Colors.red[700],
              size: 20,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            isConnected ? 'Terhubung' : 'Terputus',
            style: TextStyle(
              color: isConnected ? Colors.green[700] : Colors.red[700],
              fontWeight: FontWeight.bold,
            ),
          ),
          if (lastUpdate != null && isConnected) ...[
            const SizedBox(width: 8),
            Text(
              '• ${_formatTime(lastUpdate!)}',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}:${time.second.toString().padLeft(2, '0')}';
  }

  Widget _buildEnhancedSensorCard({
    required String title,
    required String value,
    required String unit,
    required IconData icon,
    required Color color,
    String? subtitle,
    Widget? trailing,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(24),
        shadowColor: Colors.black26,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [color.withOpacity(0.8), color.withOpacity(0.6)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withOpacity(0.3)),
                ),
                child: Icon(
                  icon,
                  size: 32,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          value,
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          unit,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.white.withOpacity(0.8),
                          ),
                        ),
                      ],
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (trailing != null) trailing,
            ],
          ),
        ),
      ),
    );
  }

  String _getTemperatureCategory(double temp) {
    if (temp < 20) return 'Dingin';
    if (temp < 25) return 'Sejuk';
    if (temp < 30) return 'Hangat';
    return 'Panas';
  }

  String _getHumidityCategory(double humidity) {
    if (humidity < 30) return 'Kering';
    if (humidity < 60) return 'Normal';
    return 'Lembap';
  }

  String _getLightCategory(double light) {
    if (light <= 160) return 'Gelap';
    return 'Terang';
  }

  // Fungsi untuk mendapatkan deskripsi status atap
  String _getAtapDescription(String status) {
    if (status.toLowerCase() == 'tertutup') {
      return 'Atap tertutup - Cahaya gelap (≤160 lux)';
    } else if (status.toLowerCase() == 'terbuka') {
      return 'Atap terbuka - Cahaya terang (>160 lux)';
    }
    return 'Status tidak diketahui';
  }

  Widget _buildProgressIndicator(double value, double max, Color color) {
    return Container(
      width: 60,
      height: 6,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.3),
        borderRadius: BorderRadius.circular(3),
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: (value / max).clamp(0.0, 1.0),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'Sensor Monitoring',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black87,
        elevation: 0,
        centerTitle: true,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF667eea), Color(0xFF764ba2)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          // Simulate refresh
          await Future.delayed(const Duration(seconds: 1));
        },
        child: SlideTransition(
          position: _slideAnimation,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              children: [
                _buildConnectionStatus(),
                const SizedBox(height: 10),
                _buildEnhancedSensorCard(
                  title: 'Suhu',
                  value: suhu.toStringAsFixed(1),
                  unit: '°C',
                  icon: Icons.thermostat_rounded,
                  color: _getTemperatureColor(suhu),
                  subtitle: _getTemperatureCategory(suhu),
                  trailing: _buildProgressIndicator(suhu, 50, Colors.white),
                ),
                _buildEnhancedSensorCard(
                  title: 'Kelembapan',
                  value: kelembapan.toStringAsFixed(0),
                  unit: '%',
                  icon: Icons.water_drop_rounded,
                  color: _getHumidityColor(kelembapan),
                  subtitle: _getHumidityCategory(kelembapan),
                  trailing: _buildProgressIndicator(kelembapan, 100, Colors.white),
                ),
                _buildEnhancedSensorCard(
                  title: 'Intensitas Cahaya',
                  value: lux.toStringAsFixed(0),
                  unit: 'lux',
                  icon: Icons.wb_sunny_rounded,
                  color: _getLightColor(lux),
                  subtitle: _getLightCategory(lux),
                  trailing: _buildProgressIndicator(lux, 2000, Colors.white),
                ),
                _buildEnhancedSensorCard(
                  title: 'Deteksi Hujan',
                  value: hujan ? 'BASAH' : 'KERING',
                  unit: '',
                  icon: hujan ? Icons.grain_rounded : Icons.wb_sunny_outlined,
                  color: hujan ? Colors.blue[400]! : Colors.purple[400]!,
                  subtitle: hujan ? 'Kondisi basah' : 'Kondisi kering',
                  trailing: Icon(
                    hujan ? Icons.check_circle : Icons.cancel,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
                _buildEnhancedSensorCard(
                  title: 'Status Atap',
                  value: statusAtap.toUpperCase(),
                  unit: '',
                  icon: Icons.roofing_rounded,
                  color: _getAtapColor(statusAtap),
                  subtitle: _getAtapDescription(statusAtap),
                  trailing: Icon(
                    statusAtap.toLowerCase() == 'terbuka' 
                        ? Icons.lock_open 
                        : statusAtap.toLowerCase() == 'tertutup'
                            ? Icons.lock
                            : Icons.help_outline,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}