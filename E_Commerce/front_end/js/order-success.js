// NỘI DUNG CHO FILE: js/order-success.js

document.addEventListener('DOMContentLoaded', () => {
    const token = localStorage.getItem('jwtToken');
    if (!token) {
        // Nếu không đăng nhập mà vào trang này, chuyển về trang chủ
        window.location.href = 'home.html';
        return;
    }

    // Lấy ID đơn hàng từ tham số URL
    const params = new URLSearchParams(window.location.search);
    const orderId = params.get('id');

    if (!orderId) {
        // Nếu không có ID, hiển thị lỗi
        const container = document.querySelector('.success-container');
        if(container) {
            container.innerHTML = '<p class="message error">Lỗi: Không tìm thấy thông tin đơn hàng.</p>';
        }
        return;
    }

    // Gọi API để lấy thông tin đơn hàng và hiển thị
    fetchOrderDetails(orderId, token);
});


async function fetchOrderDetails(orderId, token) {
    try {
        // API này cần trả về chi tiết đơn hàng cho người dùng
        const response = await fetch(`${API_BASE_URL}/api/user/orders/${orderId}`, {
            headers: { 'Authorization': `Bearer ${token}` }
        });

        if (!response.ok) {
            throw new Error('Không thể tải thông tin đơn hàng.');
        }

        const order = await response.json(); // Nhận về OrderDetailViewDTO
        
        // Điền thông tin vào các thẻ span
        document.getElementById('order-id').textContent = `#${order.id}`;
        document.getElementById('order-date').textContent = new Date(order.orderDate).toLocaleString('vi-VN');
        document.getElementById('order-total').textContent = formatCurrency(order.totalAmount);
        document.getElementById('order-payment').textContent = getPaymentMethodText(order.paymentMethod);

    } catch (error) {
        console.error("Lỗi khi tải chi tiết đơn hàng:", error);
        // Có thể hiển thị thông báo lỗi chi tiết hơn nếu muốn
        document.getElementById('order-id').textContent = `Lỗi`;
        document.getElementById('order-date').textContent = `Lỗi`;
        document.getElementById('order-total').textContent = `Lỗi`;
        document.getElementById('order-payment').textContent = `Lỗi`;
    }
}

/**
 * Hàm tiện ích để chuyển đổi giá trị paymentMethod thành văn bản dễ đọc
 * @param {string} method - 'cod' hoặc 'vnpay'
 * @returns {string} - Văn bản tương ứng
 */
function getPaymentMethodText(method) {
    if (method.toLowerCase() === 'cod') {
        return 'Thanh toán khi nhận hàng (COD)';
    }
    if (method.toLowerCase() === 'vnpay') {
        return 'Thanh toán qua VNPAY-QR';
    }
    return method; // Trả về giá trị gốc nếu không khớp
}

// Hàm formatCurrency có thể đã có trong main.js, nhưng thêm vào đây để đảm bảo an toàn
function formatCurrency(number) {
    if (typeof number !== 'number') return '';
    return new Intl.NumberFormat('vi-VN', { style: 'currency', currency: 'VND' }).format(number);
}