// backend/server.js

const express = require('express');
const moment = require('moment');
const querystring = require('qs');
const crypto = require('crypto');
const app = express();
const port = 3000;

app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// --- CẤU HÌNH VNPAY TEST (SANDBOX) ---
const tmnCode = 'GPU4UAVE'; 
const hashSecret = 'UB4CDNPUKM8EJH63VDGALB1LLFB0ES82'; 
const vnpUrl = 'https://sandbox.vnpayment.vn/paymentv2/vpcpay.html';
const returnUrl = 'http://localhost:8080/vnpay_return'; // URL này được VNPAY gọi về sau thanh toán.
// ------------------------------------

// Endpoint tạo URL thanh toán
app.post('/create_payment_url', (req, res) => {
    const { amount, orderId, orderInfo } = req.body;
    
    if (!amount || !orderId) {
        return res.status(400).json({ code: '400', message: 'Thiếu thông tin.' });
    }

    const vnp_Params = {};
    vnp_Params['vnp_Version'] = '2.1.0';
    vnp_Params['vnp_Command'] = 'pay';
    vnp_Params['vnp_TmnCode'] = tmnCode;
    vnp_Params['vnp_Amount'] = amount * 100; // Phải nhân 100
    vnp_Params['vnp_CurrCode'] = 'VND';
    vnp_Params['vnp_TxnRef'] = orderId;
    vnp_Params['vnp_OrderInfo'] = orderInfo || 'Thanh toan don hang test';
    vnp_Params['vnp_OrderType'] = 'billpayment';
    vnp_Params['vnp_Locale'] = 'vn';
    vnp_Params['vnp_ReturnUrl'] = returnUrl;
    vnp_Params['vnp_IpAddr'] = req.headers['x-forwarded-for'] || req.socket.remoteAddress || '127.0.0.1';
    
    const date = moment(new Date()).format('YYYYMMDDHHmmss');
    vnp_Params['vnp_CreateDate'] = date;
    vnp_Params['vnp_ExpireDate'] = moment(new Date()).add(15, 'minutes').format('YYYYMMDDHHmmss');

    const sortedParams = sortObject(vnp_Params);
    const signData = querystring.stringify(sortedParams, { encode: false });
    
    const hmac = crypto.createHmac('sha512', hashSecret);
    const secureHash = hmac.update(Buffer.from(signData, 'utf-8')).digest('hex');
    
    const finalUrl = vnpUrl + '?' + signData + '&vnp_SecureHash=' + secureHash;

    res.json({ code: '00', message: 'Success', data: finalUrl });
});

// Endpoint VNPAY gọi về sau khi thanh toán
app.get('/vnpay_return', (req, res) => {
    // Trong môi trường test, ta chỉ cần thông báo đã nhận được.
    // Trong thực tế, bạn phải kiểm tra chữ ký và cập nhật DB tại đây.
    res.send('<h1>Đã nhận kết quả thanh toán từ VNPAY!</h1>');
});

// Hàm hỗ trợ sắp xếp các thuộc tính
function sortObject(obj) {
	let sorted = {};
	let str = [];
	let key;
	for (key in obj) {
		if (obj.hasOwnProperty(key)) {
			str.push(encodeURIComponent(key));
		}
	}
	str.sort();
    for (key = 0; key < str.length; key++) {
        sorted[str[key]] = encodeURIComponent(obj[decodeURIComponent(str[key])]).replace(/%20/g, "+");
	}
    return sorted;
}

app.listen(port, () => {
    console.log(`VNPAY Backend đang chạy tại http://localhost:${port}`);
});