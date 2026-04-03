import 'dart:convert';
import 'package:flutter/material.dart';
import '../theme/design_system.dart';
import '../services/api_service.dart';
import 'package:geolocator/geolocator.dart';

class SearchDoctorsPage extends StatefulWidget {
  const SearchDoctorsPage({super.key});

  @override
  _SearchDoctorsPageState createState() => _SearchDoctorsPageState();
}

class _SearchDoctorsPageState extends State<SearchDoctorsPage> {
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _doctors = [];
  bool _isLoading = true;
  Position? _currentPosition;

  @override
  void initState() {
    super.initState();
    _determinePosition().then((pos) {
      _currentPosition = pos;
      _fetchDoctors();
    }).catchError((e) {
      print('Location Error: $e');
      _fetchDoctors();
    });
  }

  Future<Position?> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return null;

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return null;
    }
    
    if (permission == LocationPermission.deniedForever) return null;

    return await Geolocator.getCurrentPosition();
  }

  Future<void> _fetchDoctors([String query = ""]) async {
    setState(() => _isLoading = true);
    print('Searching Doctors: $query');
    try {
      final response = await ApiService.getDoctors(
        search: query,
        lat: _currentPosition?.latitude,
        lng: _currentPosition?.longitude,
      );
      print('Doctors Status: ${response.statusCode}');
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          setState(() {
            _doctors = data['data'];
            _isLoading = false;
          });
        }
      } else {
        print('Error status code: ${response.statusCode}');
        setState(() => _isLoading = false);
      }
    } catch (e) {
      print('Error fetching doctors exception: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignSystem.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Find Specialists', style: DesignSystem.h2),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: _buildSearchBar(),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: DesignSystem.primaryAccent))
                : _doctors.isEmpty
                    ? const Center(child: Text('No elite specialists found.', style: TextStyle(color: Colors.white24)))
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        itemCount: _doctors.length,
                        itemBuilder: (context, index) {
                          final doc = _doctors[index];
                          return _buildDoctorCard(
                              doc['name'] ?? 'Doctor',
                              doc['specialty'] ?? 'Healthcare',
                              doc['rating']?.toString() ?? '4.5',
                              doc['photoURL'] ?? '',
                              doc['distance'] ?? 'Nearby');
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: DesignSystem.glassWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: TextField(
        controller: _searchController,
        onSubmitted: (val) => _fetchDoctors(val),
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: 'Search doctors, specialties...',
          hintStyle: TextStyle(color: DesignSystem.textSub.withOpacity(0.5)),
          prefixIcon: const Icon(Icons.search, color: DesignSystem.primaryAccent),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 15),
        ),
      ),
    );
  }

  Widget _buildDoctorCard(String name, String specialty, String rating, String img, String distance) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: DesignSystem.glassWhite,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: DesignSystem.primaryAccent.withOpacity(0.1),
            backgroundImage: img.isNotEmpty ? NetworkImage(img) : null,
            child: img.isEmpty ? const Icon(Icons.person, color: DesignSystem.primaryAccent) : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: DesignSystem.bodyBold),
                Text(specialty, style: DesignSystem.bodyMain),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.location_on, color: DesignSystem.primaryAccent, size: 12),
                    const SizedBox(width: 4),
                    Text(distance, style: TextStyle(color: DesignSystem.textSub.withOpacity(0.7), fontSize: 11)),
                  ],
                ),
              ],
            ),
          ),
          Column(
            children: [
              Row(
                children: [
                  const Icon(Icons.star, color: Colors.amber, size: 16),
                  const SizedBox(width: 4),
                  Text(rating, style: DesignSystem.bodyBold.copyWith(fontSize: 12)),
                ],
              ),
              const SizedBox(height: 8),
              Text('BOOK', style: TextStyle(color: DesignSystem.primaryAccent, fontWeight: FontWeight.bold, fontSize: 10)),
            ],
          ),
        ],
      ),
    );
  }
}
