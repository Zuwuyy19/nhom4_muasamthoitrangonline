import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;

/// Model cho MoMo Payment Response
class MomoPaymentResponse {
  final String partnerCode;
  final String requestId;
  final int amount;
  final String orderId;
  final int responseTime;
  final int resultCode;
  final String resultMessage;
  final String? payUrl;
  final String? deeplink;
  final String? appLink;
  final String? qrCodeUrl;

  MomoPaymentResponse({
    required this.partnerCode,
    required this.requestId,
    required this.amount,
    required this.orderId,
    required this.responseTime,
    required this.resultCode,
    required this.resultMessage,
    this.payUrl,
    this.deeplink,
    this.appLink,
    this.qrCodeUrl,
  });

  factory MomoPaymentResponse.fromJson(Map<String, dynamic> json) {
    return MomoPaymentResponse(
      partnerCode: json['partnerCode'] ?? '',
      requestId: json['requestId'] ?? '',
      amount: json['amount'] ?? 0,
      orderId: json['orderId'] ?? '',
      responseTime: json['responseTime'] ?? 0,
      resultCode: json['resultCode'] ?? -1,
      resultMessage: json['resultMessage'] ?? json['message'] ?? '',
      payUrl: json['payUrl'],
      deeplink: json['deeplink'],
      appLink: json['appLink'],
      qrCodeUrl: json['qrCodeUrl'],
    );
  }

  /// Kiểm tra thanh toán thành công
  bool isSuccess() => resultCode == 0;

  /// Lấy URL thanh toán
  String? getPaymentUrl() => payUrl ?? deeplink ?? appLink;
}

/// Service để tương tác với MoMo API
class MomoApiService {
  // MoMo Sandbox/Test Environment
  static const String partnerCode = "MOMOBKUN20130131";
  static const String accessKey = "M8brj9K7La7fBRVv";
  static const String secretKey = "NFcpIflJiIFhUsnPJp2qHSHvROXdMaKg";
  static const String endpoint = "https://test-payment.momo.vn/v2/gateway/api/create";

  // Production Environment (uncomment when ready)
  // static const String partnerCode = "YOUR_PARTNER_CODE";
  // static const String accessKey = "YOUR_ACCESS_KEY";
  // static const String secretKey = "YOUR_SECRET_KEY";
  // static const String endpoint = "https://payment.momo.vn/v2/gateway/api/create";

  /// Tạo chữ ký HMAC SHA256
  static String _generateSignature(String data, String secretKey) {
    return Hmac(sha256, utf8.encode(secretKey))
        .convert(utf8.encode(data))
        .toString();
  }

  /// Gọi API MoMo để tạo đơn thanh toán
  static Future<MomoPaymentResponse?> createPayment({
    required String orderId,
    required int amount,
    required String orderInfo,
    required String customerName,
    required String customerPhone,
    required String notifyUrl,
    required String returnUrl,
  }) async {
    try {
      // requestId khuyến nghị khác orderId nhưng giữ duy nhất cho log
      final requestId = "REQ_$orderId";
      const requestType = "captureWallet";
      const extraData = ""; // base64 string nếu cần gửi thêm thông tin

      // Tạo request signature theo MoMo v2 create
      final rawSignature =
          "accessKey=$accessKey"
          "&amount=$amount"
          "&extraData=$extraData"
          "&ipnUrl=$notifyUrl"
          "&orderId=$orderId"
          "&orderInfo=$orderInfo"
          "&partnerCode=$partnerCode"
          "&redirectUrl=$returnUrl"
          "&requestId=$requestId"
          "&requestType=$requestType";

      final signature = _generateSignature(rawSignature, secretKey);

      // Chuẩn bị payload
      Map<String, dynamic> payload = {
        "partnerCode": partnerCode,
        "partnerName": "HUTECH Fashion",
        "storeId": "HUTECHStore",
        "requestId": requestId,
        "amount": amount,
        "orderId": orderId,
        "orderInfo": orderInfo,
        "redirectUrl": returnUrl,
        "ipnUrl": notifyUrl,
        "extraData": extraData,
        "requestType": requestType,
        "signature": signature,
        "customerName": customerName,
        "customerPhone": customerPhone,
        "lang": "vi",
      };

      // Gửi request
      final response = await http.post(
        Uri.parse(endpoint),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(payload),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return MomoPaymentResponse.fromJson(data);
      } else {
        print('MoMo API Error: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('MoMo API Exception: $e');
      return null;
    }
  }

  /// Xác minh kết quả thanh toán từ callback
  static bool verifyPaymentSignature({
    required String signature,
    required Map<String, dynamic> data,
  }) {
    try {
      // Tạo lại signature từ dữ liệu
      List<String> keys = data.keys.toList()..sort();
      String rawSignature = keys
          .where((key) => key != 'signature')
          .map((key) => "$key=${data[key]}")
          .join("&");

      String expectedSignature = _generateSignature(rawSignature, secretKey);
      return signature == expectedSignature;
    } catch (e) {
      print('Verify Signature Error: $e');
      return false;
    }
  }
}
