import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/design_system.dart';
import '../services/api_service.dart';
import 'package:geolocator/geolocator.dart';
import 'clinic_doctors_page.dart';

class SearchClinicsPage extends StatefulWidget {
  const SearchClinicsPage({super.key});

  @override
  _SearchClinicsPageState createState() => _SearchClinicsPageState();
}

class _SearchClinicsPageState extends State<SearchClinicsPage> {
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _clinics = [];
  bool _isLoading = true;
  Position? _currentPosition;

  @override
  void initState() {
    super.initState();
    _determinePosition().then((pos) {
      _currentPosition = pos;
      _fetchClinics();
    }).catchError((e) {
      print('Location Error: $e');
      _fetchClinics();
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

  Future<void> _fetchClinics([String query = ""]) async {
    setState(() => _isLoading = true);
    print('Searching Clinics: $query');
    try {
      final response = await ApiService.getClinics(
        search: query,
        lat: _currentPosition?.latitude,
        lng: _currentPosition?.longitude,
      );
      print('Clinics Status: ${response.statusCode}');
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          setState(() {
            _clinics = data['data'];
            _isLoading = false;
          });
        }
      } else {
        print('Error status code: ${response.statusCode}');
        setState(() => _isLoading = false);
      }
    } catch (e) {
      print('Error fetching clinics exception: $e');
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
        title: Text('Search Clinics', style: DesignSystem.h2),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: DesignSystem.textMain),
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
                : _clinics.isEmpty
                    ? Center(child: Text('No elite clinics found in range.', style: TextStyle(color: DesignSystem.textSub.withOpacity(0.5), fontWeight: FontWeight.bold)))
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        itemCount: _clinics.length,
                        itemBuilder: (context, index) {
                          final clinic = _clinics[index];
                          return _buildClinicCard(clinic, Icons.local_hospital);
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
        border: Border.all(color: Colors.white.withOpacity(0.6), width: 1.5),
        boxShadow: [DesignSystem.softShadow],
      ),
      child: TextField(
        controller: _searchController,
        onSubmitted: (val) => _fetchClinics(val),
        style: TextStyle(color: DesignSystem.textMain),
        decoration: InputDecoration(
          hintText: 'Search centers, diagnostics...',
          hintStyle: TextStyle(color: DesignSystem.textSub.withOpacity(0.5)),
          prefixIcon: const Icon(Icons.location_on, color: DesignSystem.secondaryAccent),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 15),
        ),
      ),
    );
  }

  Widget _buildClinicCard(Map<String, dynamic> clinic, IconData icon) {
    final String name = clinic['name'] ?? 'Clinic';
    final String location = clinic['location'] ?? 'Location Syncing...';
    final String distance = clinic['distance'] ?? 'Nearby';

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ClinicDoctorsPage(
              clinicId: clinic['id'] ?? '',
              clinicName: name,
              location: location,
            ),
          ),
        );
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: DesignSystem.glassWhite,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.6), width: 1.5),
              boxShadow: [DesignSystem.softShadow],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: DesignSystem.secondaryAccent.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: DesignSystem.secondaryAccent, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: DesignSystem.bodyBold),
                      Text(location, style: DesignSystem.bodyMain),
                    ],
                  ),
                ),
                Text(distance, style: DesignSystem.bodyBold.copyWith(fontSize: 12, color: DesignSystem.primaryAccent)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
