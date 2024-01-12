import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HasarTespitHaritası',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MapSample(),
    );
  }
}

class MapSample extends StatefulWidget {
  @override
  State<MapSample> createState() => MapSampleState();
}

class MapSampleState extends State<MapSample> {
  final Completer<GoogleMapController> _controller = Completer();
  List<LatLng> polygonCoordinates = [];
  Map<PolygonId, Polygon> polygons = {};
  Map<PolygonId, String> polygonDamageLevels = {};
  Map<PolygonId, String> buildingNames = {};
  bool isDialogShown = false;

  void _onMapCreated(GoogleMapController controller) {
    _controller.complete(controller);
  }

  void _onTap(LatLng position) {
    if (!isDialogShown) {
      setState(() {
        polygonCoordinates.add(position);
        if (polygonCoordinates.length == 4) {
          _createPolygon();
          polygonCoordinates = [];
        }
      });
    }
  }

  void _createPolygon() {
    final String polygonIdVal = 'polygon_${polygons.length}';
    final PolygonId polygonId = PolygonId(polygonIdVal);

    final Polygon polygon = Polygon(
      polygonId: polygonId,
      points: polygonCoordinates,
      strokeWidth: 2,
      fillColor: Colors.blue.withOpacity(0.5),
      onTap: () => _showPolygonDetailsDialog(polygonId),
    );

    setState(() {
      polygons[polygonId] = polygon;
      polygonDamageLevels[polygonId] = 'Hafif';
      buildingNames[polygonId] = '';
    });
  }

  void _showPolygonDetailsDialog(PolygonId polygonId) {
    isDialogShown = true;
    String currentDamageLevel = polygonDamageLevels[polygonId] ?? 'Hafif';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Bina ve Hasar Detayları'),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    decoration: const InputDecoration(labelText: 'Bina Adı'),
                    onChanged: (value) {
                      buildingNames[polygonId] = value;
                    },
                  ),
                  ...['Ağır', 'Orta', 'Hafif'].map((String level) {
                    return RadioListTile<String>(
                      title: Text(level),
                      value: level,
                      groupValue: currentDamageLevel,
                      onChanged: (String? value) {
                        setState(() {
                          polygonDamageLevels[polygonId] = value!;
                          _updatePolygonColor(polygonId, value);
                        });
                        Navigator.of(context).pop();
                      },
                    );
                  }).toList(),
                ],
              );
            },
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Tamam'),
              onPressed: () {
                Navigator.of(context).pop();
                isDialogShown = false;
              },
            ),
          ],
        );
      },
    ).then((_) {
      isDialogShown = false; // Diyalog kapandığında
    });
  }

  void _updatePolygonColor(PolygonId polygonId, String damageLevel) {
    final Polygon polygon = polygons[polygonId]!;
    setState(() {
      polygons[polygonId] = polygon.copyWith(
        fillColorParam: _getColorByDamageLevel(damageLevel).withOpacity(0.5),
      );
    });
  }

Color _getColorByDamageLevel(String level) {
  switch (level) {
    case 'Ağır':
      return Color.fromARGB(255, 255, 0, 0); // Daha canlı kırmızı
    case 'Orta':
      return Color.fromARGB(255, 217, 95, 8); // Daha canlı turuncu
    case 'Hafif':
      return Color.fromARGB(255, 0, 128, 0); // Daha canlı yeşil
    default:
      return Color.fromARGB(255, 0, 0, 255); // Daha canlı mavi
  }
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('HasarTespitHaritası'),
        actions: [
          IconButton(
            icon: Icon(Icons.save),
            onPressed: () {
              // TODO: Firebase'e kaydetme işlemi
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(100.0),
        child: GoogleMap(
          onMapCreated: _onMapCreated,
          initialCameraPosition: CameraPosition(
            target: LatLng(38.349444, 38.318056),
            zoom: 14.4746,
          ),
          polygons: Set<Polygon>.of(polygons.values),
          onTap: _onTap,
        ),
      ),
    );
  }
}