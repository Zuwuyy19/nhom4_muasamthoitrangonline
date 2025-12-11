import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart'; // Thư viện GPS
import '../../home/screens/home_screen.dart';
import 'momo_payment_screen.dart'; 

class CheckoutScreen extends StatefulWidget {
  final int totalAmount;

  const CheckoutScreen({super.key, required this.totalAmount});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  int _paymentMethod = 1; 
  
  // Tọa độ mặc định (Ví dụ: HUTECH - TPHCM)
  LatLng _selectedLocation = const LatLng(10.801657, 106.714247);
  String _addressName = "Chưa chọn vị trí";
  bool _isLoadingAddress = false;
  // Controller cho trường 'Địa chỉ chi tiết' để có thể tự động điền
  final TextEditingController _addressController = TextEditingController();
  // Controller cho thanh tìm kiếm trong popup bản đồ
  final TextEditingController _mapSearchController = TextEditingController();
  // Controllers cho tên và số điện thoại
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text("Thanh toán", style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. THÔNG TIN GIAO HÀNG
              const Text("Địa chỉ nhận hàng", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 15),
              
              _buildTextField("Họ và tên", Icons.person, "Vui lòng nhập tên", controller: _nameController),
              const SizedBox(height: 15),
              _buildTextField("Số điện thoại", Icons.phone, "Vui lòng nhập số điện thoại", isNumber: true, controller: _phoneController),
              const SizedBox(height: 15),
              _buildTextField("Địa chỉ chi tiết", Icons.location_on, "Vui lòng nhập số nhà...", controller: _addressController),
              
              const SizedBox(height: 15),

              // --- NÚT CHỌN BẢN ĐỒ ---
              InkWell(
                onTap: _showMapPicker,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 15),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.withOpacity(0.5)),
                    boxShadow: [BoxShadow(color: Colors.blue.withOpacity(0.05), blurRadius: 10)],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.map_outlined, color: Colors.blue),
                          const SizedBox(width: 8),
                          const Text(
                            "Vị trí trên bản đồ:",
                            style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Hiển thị tên đường
                      _isLoadingAddress 
                        ? const Padding(
                            padding: EdgeInsets.only(left: 32.0),
                            child: Text("Đang lấy tên địa điểm...", style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic)),
                          )
                        : Padding(
                            padding: const EdgeInsets.only(left: 32.0),
                            child: Text(
                              _addressName,
                              style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w500),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                    ],
                  ),
                ),
              ),
              // -----------------------

              const SizedBox(height: 30),

              // 2. PHƯƠNG THỨC THANH TOÁN & TÓM TẮT (Giữ nguyên)
              const Text("Phương thức thanh toán", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 15),
              _buildPaymentOption(1, "Thanh toán khi nhận hàng (COD)", Icons.money, Colors.green),
              const SizedBox(height: 10),
              _buildPaymentOption(2, "Ví điện tử MoMo", Icons.account_balance_wallet, Colors.pink),
              const SizedBox(height: 10),
              _buildPaymentOption(3, "Thanh toán qua VNPay", Icons.payment, Colors.blue),
              const SizedBox(height: 30),

              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10)],
                ),
                child: Column(
                  children: [
                    _buildSummaryRow("Tạm tính", widget.totalAmount),
                    const SizedBox(height: 10),
                    _buildSummaryRow("Phí vận chuyển", 30000),
                    const Divider(height: 30),
                    _buildSummaryRow("Tổng thanh toán", widget.totalAmount + 30000, isTotal: true),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, -5))],
        ),
        child: SizedBox(
          height: 55,
          child: ElevatedButton(
            onPressed: _handleOrder,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            ),
            child: const Text("XÁC NHẬN ĐẶT HÀNG", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _addressController.dispose();
    _mapSearchController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  // Tìm địa điểm (forward geocoding) bằng Nominatim và trả về LatLng nếu tìm thấy
  Future<LatLng?> _searchPlace(String query) async {
    if (query.trim().isEmpty) return null;
    try {
      final url = Uri.parse('https://nominatim.openstreetmap.org/search?q=${Uri.encodeComponent(query)}&format=json&limit=1');
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
    } catch (e) {
      // ignore errors, caller can show message
    }
    return null;
  }

  // --- HÀM LẤY TÊN TỪ TOẠ ĐỘ ---
  Future<void> _getAddressFromLatLng(LatLng point) async {
    setState(() {
      _isLoadingAddress = true;
      _addressName = "Đang tìm vị trí...";
    });

    try {
      final url = Uri.parse(
          'https://nominatim.openstreetmap.org/reverse?format=json&lat=${point.latitude}&lon=${point.longitude}&zoom=18&addressdetails=1');
      
      final response = await http.get(url, headers: {
        'User-Agent': 'com.nhom4.muasamthoitrang', 
      });

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _addressName = data['display_name'] ?? "Không tìm thấy tên đường";
          _isLoadingAddress = false;
          // Cập nhật vào trường địa chỉ chi tiết nếu có controller
          _addressController.text = _addressName;
        });
      } else {
        setState(() {
          _addressName = "Lỗi kết nối máy chủ bản đồ";
          _isLoadingAddress = false;
          _addressController.text = _addressName;
        });
      }
    } catch (e) {
      setState(() {
        _addressName = "Vị trí: ${point.latitude.toStringAsFixed(4)}, ${point.longitude.toStringAsFixed(4)}";
        _isLoadingAddress = false;
        _addressController.text = _addressName;
      });
    }
  }

  // --- HÀM LẤY VỊ TRÍ GPS HIỆN TẠI ---
  Future<Position?> _determinePosition(BuildContext context) async {
    bool serviceEnabled;
    LocationPermission permission;

    // Kiểm tra GPS có bật không
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng bật GPS trên điện thoại')));
      return null;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Bạn đã từ chối quyền vị trí')));
        return null;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Quyền vị trí bị chặn vĩnh viễn, hãy mở cài đặt để cấp quyền')));
      return null;
    }

    return await Geolocator.getCurrentPosition();
  }

  // --- HÀM HIỂN THỊ POPUP BẢN ĐỒ VỚI NÚT CURRENT LOCATION ---
  void _showMapPicker() {
    LatLng tempLocation = _selectedLocation;
    // Controller để điều khiển bản đồ di chuyển
    final MapController mapController = MapController(); 

    showDialog(
      context: context,
      builder: (context) {
        final size = MediaQuery.of(context).size;
        
        return StatefulBuilder( 
          builder: (context, setStateMap) {
            return AlertDialog(
              contentPadding: EdgeInsets.zero,
              insetPadding: const EdgeInsets.all(10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              content: SizedBox(
                width: size.width, 
                height: size.height * 0.8,
                child: Column(
                  children: [
                    // Header (title + search field)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      color: Colors.black,
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text("Chọn vị trí giao hàng", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                              IconButton(
                                icon: const Icon(Icons.close, color: Colors.white),
                                onPressed: () => Navigator.pop(context),
                              )
                            ],
                          ),
                          const SizedBox(height: 8),
                          // Search field inside map dialog
                          TextField(
                            controller: _mapSearchController,
                            textInputAction: TextInputAction.search,
                            onSubmitted: (value) async {
                              FocusScope.of(context).unfocus();
                              final result = await _searchPlace(value);
                              if (result != null) {
                                setStateMap(() {
                                  tempLocation = result;
                                });
                                mapController.move(result, 17.0);
                                // Cập nhật tên địa chỉ và ô chi tiết luôn
                                _getAddressFromLatLng(result);
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Không tìm thấy địa điểm')));
                              }
                            },
                            decoration: InputDecoration(
                              hintText: 'Tìm kiếm địa điểm, ví dụ: 123 Đường A',
                              prefixIcon: const Icon(Icons.search),
                              suffixIcon: IconButton(
                                icon: const Icon(Icons.arrow_circle_right_outlined),
                                onPressed: () async {
                                  FocusScope.of(context).unfocus();
                                  final value = _mapSearchController.text;
                                  final result = await _searchPlace(value);
                                  if (result != null) {
                                    setStateMap(() {
                                      tempLocation = result;
                                    });
                                    mapController.move(result, 17.0);
                                    _getAddressFromLatLng(result);
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Không tìm thấy địa điểm')));
                                  }
                                },
                              ),
                              filled: true,
                              fillColor: Colors.white,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Stack(
                        children: [
                          FlutterMap(
                            mapController: mapController, // Gắn controller vào đây
                            options: MapOptions(
                              initialCenter: tempLocation,
                              initialZoom: 16.0,
                              onTap: (tapPosition, point) {
                                setStateMap(() {
                                  tempLocation = point;
                                });
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
                                    width: 50.0,
                                    height: 50.0,
                                    point: tempLocation,
                                    child: const Icon(Icons.location_on, color: Colors.red, size: 50),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          // --- NÚT VỊ TRÍ HIỆN TẠI (Góc dưới phải) ---
                          Positioned(
                            bottom: 20,
                            right: 20,
                            child: FloatingActionButton(
                              backgroundColor: Colors.white,
                              onPressed: () async {
                                // Gọi hàm lấy GPS
                                Position? position = await _determinePosition(context);
                                if (position != null) {
                                  LatLng newPos = LatLng(position.latitude, position.longitude);
                                  setStateMap(() {
                                    tempLocation = newPos; // Cập nhật marker đỏ
                                  });
                                  // Di chuyển bản đồ đến vị trí mới
                                  mapController.move(newPos, 17.0);
                                }
                              },
                              child: const Icon(Icons.my_location, color: Colors.blue),
                            ),
                          ),
                          // ------------------------------------------
                        ],
                      ),
                    ),
                    // Footer Button
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(15),
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _selectedLocation = tempLocation;
                          });
                            // Đóng dialog trước, sau đó lấy tên địa chỉ và cập nhật cả hiển thị và field chi tiết
                            Navigator.pop(context);
                            _getAddressFromLatLng(tempLocation);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                        ),
                        child: const Text("XÁC NHẬN VỊ TRÍ NÀY", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // --- CÁC WIDGET PHỤ TRỢ (Text Field, Payment Option...) ---
  Widget _buildTextField(String label, IconData icon, String errorMsg, {bool isNumber = false, TextEditingController? controller}) {
    return TextFormField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.phone : TextInputType.text,
      validator: (value) => (value == null || value.isEmpty) ? errorMsg : null,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.grey),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      ),
    );
  }

  Widget _buildPaymentOption(int value, String title, IconData icon, Color color) {
    return GestureDetector(
      onTap: () => setState(() => _paymentMethod = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _paymentMethod == value ? Colors.black : Colors.transparent, width: 2),
          boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 5)],
        ),
        child: Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 15),
            Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.w500))),
            if (_paymentMethod == value) const Icon(Icons.check_circle, color: Colors.black),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, int amount, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: isTotal ? 16 : 14, fontWeight: isTotal ? FontWeight.bold : FontWeight.normal)),
        Text(
          "${amount.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}đ",
          style: TextStyle(fontSize: isTotal ? 18 : 14, fontWeight: isTotal ? FontWeight.bold : FontWeight.normal, color: isTotal ? Colors.orange : Colors.black),
        ),
      ],
    );
  }

  void _handleOrder() {
    if (_formKey.currentState!.validate()) {
      // Lấy dữ liệu từ TextEditingController
      final String customerName = _nameController.text.trim();
      final String phoneNumber = _phoneController.text.trim();
      
      if (_paymentMethod == 1) {
        // COD - Hiển thị dialog xác nhận
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_circle, color: Colors.green, size: 80),
                const SizedBox(height: 20),
                const Text("Đặt hàng thành công!", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                 const SizedBox(height: 10),
                 const Text("Giao đến:", style: TextStyle(color: Colors.grey)),
                 const SizedBox(height: 5),
                 Text(_addressName, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.black),
                    onPressed: () {
                      Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const HomeScreen()), (route) => false);
                    },
                    child: const Text("Tiếp tục mua sắm", style: TextStyle(color: Colors.white)),
                  ),
                )
              ],
            ),
          ),
        );
      } else if (_paymentMethod == 2) {
        // MoMo - Điều hướng tới MoMo payment screen
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MomoPaymentScreen(
              totalAmount: widget.totalAmount + 30000, // Tổng tiền + phí vận chuyển
              customerName: customerName,
              phoneNumber: phoneNumber,
            ),
          ),
        );
      } else if (_paymentMethod == 3) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Tính năng VNPay đang phát triển...")));
      }
    }
  }
}