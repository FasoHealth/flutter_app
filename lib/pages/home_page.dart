import 'package:flutter/material.dart';
import '../models/incident_model.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import 'incident_detail_page.dart';
import 'report_incident_page.dart';
import 'login_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late Future<List<IncidentModel>> _incidentsFuture;

  @override
  void initState() {
    super.initState();
    _refreshIncidents();
  }

  void _refreshIncidents() {
    setState(() {
      _incidentsFuture = ApiService.getIncidents();
    });
  }

  void _handleLogout() async {
    await ApiService.logout();
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
      );
    }
  }

  Color _getSeverityColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'critical': return AppTheme.dangerRed;
      case 'high': return Colors.orange;
      case 'medium': return Colors.yellow;
      default: return AppTheme.neonBlue;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('CSA Mobile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshIncidents,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _handleLogout,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => _refreshIncidents(),
        child: FutureBuilder<List<IncidentModel>>(
          future: _incidentsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Text(
                    'Erreur: ${snapshot.error}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppTheme.dangerRed),
                  ),
                ),
              );
            }

            final incidents = snapshot.data ?? [];

            if (incidents.isEmpty) {
              return const Center(
                child: Text('Aucun incident signalé pour le moment.'),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: incidents.length,
              itemBuilder: (context, index) {
                final incident = incidents[index];
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => IncidentDetailPage(incident: incident),
                      ),
                    );
                  },
                  child: Card(
                    color: AppTheme.accentBlue,
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (incident.images.isNotEmpty)
                          ClipRRect(
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                            child: Image.network(
                              incident.images[0],
                              height: 150,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          ),
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      incident.title,
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.textLight,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: _getSeverityColor(incident.severity).withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(color: _getSeverityColor(incident.severity)),
                                    ),
                                    child: Text(
                                      incident.severity.toUpperCase(),
                                      style: TextStyle(
                                        color: _getSeverityColor(incident.severity),
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                incident.description,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(color: AppTheme.textDim),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  const Icon(Icons.location_on, size: 14, color: AppTheme.dangerRed),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      incident.location['address'] ?? 'Lieu non spécifié',
                                      style: const TextStyle(fontSize: 12, color: AppTheme.textDim),
                                    ),
                                  ),
                                  const Icon(Icons.thumb_up_alt_outlined, size: 14, color: AppTheme.textDim),
                                  const SizedBox(width: 4),
                                  Text('${incident.upvoteCount}', style: const TextStyle(fontSize: 12, color: AppTheme.textDim)),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ReportIncidentPage()),
          ).then((_) => _refreshIncidents());
        },
        backgroundColor: AppTheme.dangerRed,
        icon: const Icon(Icons.add_alert, color: Colors.white),
        label: const Text('SIGNALER', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
      ),
    );
  }
}
