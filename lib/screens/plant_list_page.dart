import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/plant.dart';
import '../config/api_config.dart';
import '../theme/app_theme.dart';

class PlantListPage extends StatefulWidget {
  @override
  _PlantListPageState createState() => _PlantListPageState();
}

class _PlantListPageState extends State<PlantListPage> {
  List<Plant> plants = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchPlants();
  }

  Future<void> fetchPlants() async {
    try {
      final response = await http.get(Uri.parse(ApiConfig.getKendraPlantPhotosEndpoint('1')));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          List<dynamic> plantsJson = data['data']['plants'];
          setState(() {
            plants = plantsJson.map((p) => Plant.fromJson(p)).toList();
            isLoading = false;
          });
        }
      } else {
        throw Exception("Failed to load plants");
      }
    } catch (e) {
      print("Error: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  Widget buildPhotoGrid(List<String> photos) {
    if (photos.isEmpty) {
      return Center(
        child: Icon(Icons.image_not_supported, size: 60, color: Colors.grey),
      );
    }
    return GridView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: photos.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 5,
        mainAxisSpacing: 5,
      ),
      itemBuilder: (context, index) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            photos[index],
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                color: Colors.grey[300],
                child: Icon(Icons.broken_image, color: Colors.grey),
              );
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Plant Photos"),
        backgroundColor: AppTheme.primaryGreen,
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryGreen),
            ))
          : plants.isEmpty
              ? Center(child: Text("No plants found"))
              : ListView.builder(
                  itemCount: plants.length,
                  itemBuilder: (context, index) {
                    final plant = plants[index];
                    return Card(
                      margin: EdgeInsets.all(12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      elevation: 5,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "${plant.name} (No. ${plant.plantNumber})",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text("Last Photo: ${plant.lastPhotoDate}"),
                            Text("Next Photo: ${plant.nextPhotoDate}"),
                            SizedBox(height: 10),
                            buildPhotoGrid(plant.photos),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
