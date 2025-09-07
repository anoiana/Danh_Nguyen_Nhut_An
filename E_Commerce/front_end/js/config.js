// File này chứa các biến cấu hình chung cho toàn bộ ứng dụng frontend.

const API_BASE_URL = 'http://localhost:8080';
const HOST_PROVINCE_API = 'https://provinces.open-api.vn/api/';

// Hàm tiện ích chung có thể đặt ở đây
function formatCurrency(number) {
    if (typeof number !== 'number') return '';
    return new Intl.NumberFormat('vi-VN', { style: 'currency', currency: 'VND' }).format(number);
}