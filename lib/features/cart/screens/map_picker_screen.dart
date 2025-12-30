import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class MapPickerResult {
  final LatLng location;
  final String addressName;

  MapPickerResult({
    required this.location,
    required this.addressName,
  });
}

class MapPickerScreen extends StatefulWidget {
  const MapPickerScreen({
    super.key,
    required this.initialLocation,
    this.initialAddressName,
  });

  final LatLng initialLocation;
  final String? initialAddressName;

  @override
  State<MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<MapPickerScreen> {
  late LatLng _tempLocation;
  late MapController _mapController;

  final TextEditingController _searchCtrl = TextEditingController();

  String _addressName = "Chưa chọn vị trí";
  bool _isLoadingAddress = false;

  @override
  void initState() {
    super.initState();
    _tempLocation = widget.initialLocation;
    _mapController = MapController();

    _addressName = (widget.initialAddressName ?? '').trim().isNotEmpty
        ? widget.initialAddressName!.trim()
        : "Chưa chọn vị trí";
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  // =========================
  // SEARCH + REVERSE GEOCODE
  // =========================

  Future<LatLng?> _searchPlace(String query) async {
    if (query.trim().isEmpty) return null;
    try {
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/search?q=${Uri.encodeComponent(query)}&format=json&limit=1',
      );
      final response = await http.get(url, headers: {
        'User-Agent': 'com.nhom4.muasamthoitrang',
      });

      if (response.statusCode == 200) {
        final List data = json.decode(response.body);
        if (data.isNotEmpty) {
          final item = data[0];
          final lat = double.tryParse(item['lat'].toString());
          final lon = double.tryParse(item['lon'].toString());
          if (lat != null && lon != null) {
            return LatLng(lat, lon);
          }
        }
      }
    } catch (_) {}
    return null;
  }

  Future<void> _getAddressFromLatLng(LatLng point) async {
    setState(() {
      _isLoadingAddress = true;
      _addressName = "Đang tìm vị trí...";
    });

    try {
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?format=json&lat=${point.latitude}&lon=${point.longitude}&zoom=18&addressdetails=1',
      );

      final response = await http.get(url, headers: {
        'User-Agent': 'com.nhom4.muasamthoitrang',
      });

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final display =
            (data['display_name'] ?? "Không tìm thấy tên đường").toString();

        if (!mounted) return;
        setState(() {
          _addressName = display;
          _isLoadingAddress = false;
        });
      } else {
        if (!mounted) return;
        setState(() {
          _addressName = "Lỗi kết nối máy chủ bản đồ";
          _isLoadingAddress = false;
        });
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _addressName =
            "Vị trí: ${point.latitude.toStringAsFixed(4)}, ${point.longitude.toStringAsFixed(4)}";
        _isLoadingAddress = false;
      });
    }
  }

  Future<Position?> _determinePosition(BuildContext context) async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng bật GPS trên điện thoại')),
      );
      return null;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bạn đã từ chối quyền vị trí')),
        );
        return null;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Quyền vị trí bị chặn vĩnh viễn, hãy mở cài đặt để cấp quyền'),
        ),
      );
      return null;
    }

    return await Geolocator.getCurrentPosition();
  }

  // =========================
  // UI
  // =========================

  void _confirm() {
    Navigator.pop(
      context,
      MapPickerResult(location: _tempLocation, addressName: _addressName),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Chọn vị trí giao hàng", style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // SEARCH BAR
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            color: Colors.black,
            child: Column(
              children: [
                TextField(
                  controller: _searchCtrl,
                  textInputAction: TextInputAction.search,
                  onSubmitted: (value) async {
                    FocusScope.of(context).unfocus();
                    final result = await _searchPlace(value);
                    if (result != null) {
                      setState(() => _tempLocation = result);
                      _mapController.move(result, 17.0);
                      _getAddressFromLatLng(result);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Không tìm thấy địa điểm')),
                      );
                    }
                  },
                  decoration: InputDecoration(
                    hintText: 'Tìm kiếm địa điểm, ví dụ: 123 Đường A',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.arrow_circle_right_outlined),
                      onPressed: () async {
                        FocusScope.of(context).unfocus();
                        final value = _searchCtrl.text;
                        final result = await _searchPlace(value);
                        if (result != null) {
                          setState(() => _tempLocation = result);
                          _mapController.move(result, 17.0);
                          _getAddressFromLatLng(result);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Không tìm thấy địa điểm')),
                          );
                        }
                      },
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // ADDRESS INFO
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.place, color: Colors.white),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _isLoadingAddress
                          ? const Text(
                              "Đang lấy tên địa điểm...",
                              style: TextStyle(color: Colors.white70, fontStyle: FontStyle.italic),
                            )
                          : Text(
                              _addressName,
                              style: const TextStyle(color: Colors.white),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // MAP
          Expanded(
            child: Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _tempLocation,
                    initialZoom: 16.0,
                    onTap: (tapPosition, point) {
                      setState(() => _tempLocation = point);
                      _getAddressFromLatLng(point);
                    },
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}.png',
                      subdomains: const ['a', 'b', 'c', 'd'],
                      userAgentPackageName: 'com.nhom4.muasamthoitrang',
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          width: 50,
                          height: 50,
                          point: _tempLocation,
                          child: const Icon(Icons.location_on, color: Colors.red, size: 50),
                        ),
                      ],
                    ),
                  ],
                ),

                // MY LOCATION
                Positioned(
                  bottom: 20,
                  right: 20,
                  child: FloatingActionButton(
                    backgroundColor: Colors.white,
                    onPressed: () async {
                      final position = await _determinePosition(context);
                      if (position == null) return;

                      final newPos = LatLng(position.latitude, position.longitude);
                      setState(() => _tempLocation = newPos);
                      _mapController.move(newPos, 17.0);
                      _getAddressFromLatLng(newPos);
                    },
                    child: const Icon(Icons.my_location, color: Colors.blue),
                  ),
                ),
              ],
            ),
          ),

          // CONFIRM BUTTON
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(15),
            child: SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: _confirm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                ),
                child: const Text(
                  "XÁC NHẬN VỊ TRÍ NÀY",
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
