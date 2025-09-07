// NỘI DUNG MỚI CHO: admin/js/coupon-edit.js

document.addEventListener('DOMContentLoaded', () => {
    initializePage();
    initializeEventListeners();
});

function initializeEventListeners() {
    document.getElementById('couponForm').addEventListener('submit', handleFormSubmit);
    document.getElementById('cancelBtn').addEventListener('click', () => window.location.href = 'coupons.html');
    document.getElementById('generateCodeBtn').addEventListener('click', generateRandomCode);
}

async function initializePage() {
    const urlParams = new URLSearchParams(window.location.search);
    const id = urlParams.get('id');

    if (id) {
        showLoader();
        try {
            const token = localStorage.getItem('jwtToken');
            const response = await fetch(`${API_BASE_URL}/api/admin/coupons/${id}`, {
                headers: { 'Authorization': `Bearer ${token}` }
            });
            if (!response.ok) throw new Error('Không thể tải thông tin mã giảm giá.');
            
            const coupon = await response.json();
            populateForm(coupon);
        } catch (err) {
            showToast(err.message, 'error');
        } finally {
            hideLoader();
        }
    }
}

function populateForm(coupon) {
    document.getElementById('formTitle').textContent = `Sửa mã giảm giá: ${coupon.code}`;
    document.getElementById('couponId').value = coupon.id;
    document.getElementById('couponCode').value = coupon.code;
    document.getElementById('couponDescription').value = coupon.description;
    document.getElementById('couponType').value = coupon.type;
    document.getElementById('couponValue').value = coupon.value;
    document.getElementById('couponQuantity').value = coupon.quantity;
    // Chuyển đổi ngày tháng từ API (ví dụ: "2025-08-24") sang định dạng mà input[type=date] hiểu
    document.getElementById('couponExpiryDate').value = coupon.expiryDate.split('T')[0];
}

async function handleFormSubmit(event) {
    event.preventDefault();
    showLoader();
    const token = localStorage.getItem('jwtToken');
    const id = document.getElementById('couponId').value;
    
    const couponData = {
        code: document.getElementById('couponCode').value.toUpperCase().trim(),
        description: document.getElementById('couponDescription').value,
        type: document.getElementById('couponType').value,
        value: parseFloat(document.getElementById('couponValue').value),
        quantity: parseInt(document.getElementById('couponQuantity').value),
        expiryDate: document.getElementById('couponExpiryDate').value,
        active: true // Mặc định là active khi tạo/sửa
    };

    const method = id ? 'PUT' : 'POST';
    const url = id ? `${API_BASE_URL}/api/admin/coupons/${id}` : `${API_BASE_URL}/api/admin/coupons`;

    try {
        const response = await fetch(url, {
            method,
            headers: { 'Content-Type': 'application/json', 'Authorization': `Bearer ${token}` },
            body: JSON.stringify(couponData)
        });
        if (!response.ok) throw new Error(await response.text());
        
        localStorage.setItem('toastMessage', `Đã ${id ? 'cập nhật' : 'thêm'} mã giảm giá thành công!`);
        window.location.href = 'coupons.html';
    } catch(err) {
        hideLoader();
        showToast('Lỗi: ' + err.message, 'error');
    }
}

function generateRandomCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    let result = '';
    for (let i = 0; i < 8; i++) {
        result += chars.charAt(Math.floor(Math.random() * chars.length));
    }
    document.getElementById('couponCode').value = result;
}