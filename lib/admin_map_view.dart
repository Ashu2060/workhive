import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as ll;

import 'main.dart';

class AdminMapView extends StatefulWidget {
  const AdminMapView({super.key});

  @override
  State<AdminMapView> createState() => _AdminMapViewState();
}

class _AdminMapViewState extends State<AdminMapView> {
  @override
  Widget build(BuildContext context) {
    final workers = workerManager.workers.where((w) => w.isApproved).toList();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF3B0068),
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Real-Time Worker Map',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: Stack(
        children: [
          // ------------------ FLUTTER MAP ------------------ //
          FlutterMap(
            options: MapOptions(
              initialCenter: workers.isEmpty
                  ? const ll.LatLng(28.6588928, 77.4373376)
                  : ll.LatLng(
                  workers.first.latitude, workers.first.longitude),
              initialZoom: 14,
            ),
            children: [
              TileLayer(
                urlTemplate:
                "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                userAgentPackageName: "com.workhive.app",
              ),

              // ---------- ALL WORKER MARKERS ---------- //
              MarkerLayer(
                markers: workers.map((worker) {
                  // Marker color by status
                  Color markerColor;
                  switch (worker.status) {
                    case "Tracking":
                      markerColor = Colors.green;
                      break;
                    case "Held":
                      markerColor = Colors.orange;
                      break;
                    default:
                      markerColor = Colors.red;
                  }

                  return Marker(
                    point: ll.LatLng(worker.latitude, worker.longitude),
                    width: 40,
                    height: 40,
                    child: GestureDetector(
                      onTap: () => _showWorkerDetailsDialog(worker),
                      child: Icon(
                        Icons.location_on,
                        color: markerColor,
                        size: 40,
                      ),
                    ),
                  );
                }).toList(),
              ),

              // ---------- GEOFENCE CIRCLE ---------- //
              CircleLayer(
                circles: [
                  CircleMarker(
                    point: const ll.LatLng( 28.6588928, 77.4373376),
                    radius: 500,
                    color: Colors.blue.withOpacity(0.2),
                    borderStrokeWidth: 2,
                    borderColor: Colors.blue,
                  )
                ],
              ),
            ],
          ),

          // ------------------ LEGEND ------------------ //
          Positioned(
            bottom: 20,
            left: 20,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF2C2D43),
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Legend",
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  _legendItem(Colors.green, "Tracking"),
                  const SizedBox(height: 4),
                  _legendItem(Colors.orange, "Held"),
                  const SizedBox(height: 4),
                  _legendItem(Colors.red, "Stopped"),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          border:
                          Border.all(color: Colors.blue, width: 2),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        "Geofence (500m)",
                        style:
                        TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ],
                  )
                ],
              ),
            ),
          ),

          // WORKER COUNT BADGE
          Positioned(
            top: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF6A0DAD),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(Icons.people,
                      color: Colors.white, size: 18),
                  const SizedBox(width: 6),
                  Text(
                    "${workers.length} Workers",
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ------------- WORKER DETAILS POPUP ------------- //
  void _showWorkerDetailsDialog(Worker worker) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2C2D43),
        title: Text(worker.name,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _detail("Email", worker.email),
            _detail("Status", worker.status),
            _detail("Latitude", worker.latitude.toStringAsFixed(6)),
            _detail("Longitude", worker.longitude.toStringAsFixed(6)),
            _detail(
                "Geofence",
                worker.isInsideGeofence
                    ? "INSIDE RANGE"
                    : "OUTSIDE RANGE"),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child:
            const Text("Close", style: TextStyle(color: Colors.white70)),
          )
        ],
      ),
    );
  }

  Widget _detail(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text("$label: ",
              style: const TextStyle(
                  color: Colors.white54, fontWeight: FontWeight.bold)),
          Expanded(
            child: Text(value,
                style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _legendItem(Color color, String text) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration:
          BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(text,
            style: const TextStyle(color: Colors.white, fontSize: 12)),
      ],
    );
  }
}
