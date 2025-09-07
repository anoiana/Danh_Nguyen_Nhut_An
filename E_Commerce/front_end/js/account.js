const API_BASE_URL = 'http://localhost:8080';
const HOST_PROVINCE_API = 'https://provinces.open-api.vn/api/';
let allUserOrders = [];

// =========================================================
//                  KHỞI TẠO CHUNG
// =========================================================
document.addEventListener('DOMContentLoaded', () => {
    const token = localStorage.getItem('jwtToken');
    if (!token) { 
        alert("Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.");
        window.location.href = 'login.html'; 
        return; 
    }
    
    // Xử lý điều hướng SPA (Single Page Application)
    window.addEventListener('hashchange', navigate);
    navigate(); // Tải trang ban đầu dựa trên hash hoặc mặc định

    // Gán sự kiện click cho các link trong sidebar
    document.querySelectorAll('.account-nav .nav-link').forEach(link => {
        link.addEventListener('click', function(e) {
            e.preventDefault();
            window.location.hash = this.getAttribute('href');
        });
    });

    // Điền tên user vào sidebar
    const user = JSON.parse(localStorage.getItem('user'));
    if (user) document.getElementById('sidebar-username').textContent = user.username;
});

// =========================================================
//               LOGIC ĐIỀU HƯỚNG SPA
// =========================================================
async function navigate() {
    const hash = window.location.hash || '#profile';
    const links = document.querySelectorAll('.account-nav .nav-link');
    const contentEl = document.getElementById('account-content');

    const activeLink = [...links].find(link => link.getAttribute('href') === hash);
    if (!activeLink) {
        window.location.hash = '#profile';
        return;
    }

    links.forEach(link => link.classList.remove('active'));
    activeLink.classList.add('active');

    const pageUrl = activeLink.dataset.page;
    contentEl.innerHTML = '<p>Đang tải trang...</p>';
    try {
        const response = await fetch(pageUrl);
        if (!response.ok) throw new Error('Không thể tải nội dung trang.');
        contentEl.innerHTML = await response.text();

        // Chạy các hàm khởi tạo tương ứng với từng trang
        if (pageUrl.includes('account-profile.html')) {
            initProfilePage();
        } else if (pageUrl.includes('account-orders.html')) {
            initOrdersPage();
        } else if (pageUrl.includes('account-change-password.html')) {
            initChangePasswordPage();
        }
    } catch (error) {
        contentEl.innerHTML = `<p class="message error">${error.message}</p>`;
    }
}

// =========================================================
//                  LOGIC TRANG HỒ SƠ
// =========================================================
async function initProfilePage() {
    initializeAvatarEvents();
    initializeProfileAddressListeners();
    document.getElementById('profile-form').addEventListener('submit', handleUpdateProfile);

    const token = localStorage.getItem('jwtToken');
    try {
        const response = await fetch(`${API_BASE_URL}/api/user/me`, { headers: { 'Authorization': `Bearer ${token}` } });
        if(!response.ok) throw new Error("Không thể tải thông tin hồ sơ.");
        const user = await response.json();
        await populateProfileForm(user);
    } catch (error) {
        console.error("Lỗi tải hồ sơ:", error);
    }
}

async function populateProfileForm(user) {
    document.getElementById('profile-username').value = user.username || '';
    document.getElementById('profile-email').value = user.email || '';
    document.getElementById('profile-phone').value = user.phoneNumber || '';
    document.getElementById('profile-address').value = user.address || '';
    document.getElementById('profile-avatar-preview').src = user.avatarUrl || 'https://via.placeholder.com/100';
    document.querySelector('.user-avatar img').src = user.avatarUrl || 'https://via.placeholder.com/100';
    
    if (!user.province) {
        await loadProvincesForProfile();
        return;
    }

    await loadProvincesForProfile();
    const provinceSelect = document.getElementById('profile-province');
    const provinceOption = [...provinceSelect.options].find(opt => opt.text === user.province);
    
    if (provinceOption) {
        provinceSelect.value = provinceOption.value;
        await loadDistrictsForProfile(provinceSelect.value);
        const districtSelect = document.getElementById('profile-district');
        const districtOption = [...districtSelect.options].find(opt => opt.text === user.district);
        
        if (districtOption) {
            districtSelect.value = districtOption.value;
            await loadWardsForProfile(districtSelect.value);
            const wardSelect = document.getElementById('profile-ward');
            const wardOption = [...wardSelect.options].find(opt => opt.text === user.ward);
            if (wardOption) {
                wardSelect.value = wardOption.value;
            }
        }
    }
}

async function handleUpdateProfile(event) {
    event.preventDefault();
    const token = localStorage.getItem('jwtToken');
    const profileData = {
        username: document.getElementById('profile-username').value,
        phoneNumber: document.getElementById('profile-phone').value,
        address: document.getElementById('profile-address').value,
        province: document.getElementById('profile-province').options[document.getElementById('profile-province').selectedIndex].text,
        district: document.getElementById('profile-district').options[document.getElementById('profile-district').selectedIndex].text,
        ward: document.getElementById('profile-ward').options[document.getElementById('profile-ward').selectedIndex].text,
    };
    
    try {
        const response = await fetch(`${API_BASE_URL}/api/user/me`, {
            method: 'PUT',
            headers: { 'Content-Type': 'application/json', 'Authorization': `Bearer ${token}` },
            body: JSON.stringify(profileData)
        });
        if (!response.ok) throw new Error(await response.text());
        alert('Cập nhật hồ sơ thành công!');
        const user = JSON.parse(localStorage.getItem('user'));
        user.username = profileData.username;
        localStorage.setItem('user', JSON.stringify(user));
        document.getElementById('sidebar-username').textContent = user.username;
        if(typeof updateHeaderUserStatus === 'function') updateHeaderUserStatus();
    } catch (error) {
        alert(`Lỗi: ${error.message}`);
    }
}

function initializeAvatarEvents() {
    const changeBtn = document.getElementById('change-avatar-btn');
    const fileInput = document.getElementById('avatar-file-input');
    if (!changeBtn || !fileInput) return;
    changeBtn.addEventListener('click', () => fileInput.click());
    fileInput.addEventListener('change', () => {
        const file = fileInput.files[0];
        if (file) handleAvatarUpload(file);
    });
}

async function handleAvatarUpload(file) {
    const token = localStorage.getItem('jwtToken');
    const formData = new FormData();
    formData.append('file', file);
    try {
        alert("Đang tải ảnh lên, vui lòng chờ...");
        const response = await fetch(`${API_BASE_URL}/api/user/avatar`, {
            method: 'POST',
            headers: { 'Authorization': `Bearer ${token}` },
            body: formData
        });
        if (!response.ok) throw new Error(await response.text());
        const data = await response.json();
        const newAvatarUrl = data.avatarUrl;
        document.getElementById('profile-avatar-preview').src = newAvatarUrl;
        document.querySelector('.user-avatar img').src = newAvatarUrl;
        if (typeof updateHeaderUserStatus === 'function') updateHeaderUserStatus();
        alert('Cập nhật ảnh đại diện thành công!');
    } catch (error) {
        alert(`Lỗi: ${error.message}`);
    }
}

function initializeProfileAddressListeners() {
    const provinceSelect = document.getElementById('profile-province');
    const districtSelect = document.getElementById('profile-district');
    if (provinceSelect) {
        provinceSelect.addEventListener('change', function() {
            if (this.value) loadDistrictsForProfile(this.value);
        });
    }
    if (districtSelect) {
        districtSelect.addEventListener('change', function() {
            if (this.value) loadWardsForProfile(this.value);
        });
    }
}

async function loadProvincesForProfile() {
    const provinceSelect = document.getElementById('profile-province');
    if (!provinceSelect || provinceSelect.options.length > 1) return;
    try {
        const response = await fetch(HOST_PROVINCE_API + '?depth=1');
        const provinces = await response.json();
        provinces.forEach(p => { provinceSelect.innerHTML += `<option value="${p.code}">${p.name}</option>`; });
    } catch (error) { console.error('Lỗi tải tỉnh/thành:', error); }
}

async function loadDistrictsForProfile(provinceCode) {
    const districtSelect = document.getElementById('profile-district');
    if (!districtSelect) return;
    districtSelect.innerHTML = '<option value="">-- Chọn Quận/Huyện --</option>';
    document.getElementById('profile-ward').innerHTML = '<option value="">-- Chọn Phường/Xã --</option>';
    try {
        const response = await fetch(`${HOST_PROVINCE_API}p/${provinceCode}?depth=2`);
        const data = await response.json();
        data.districts.forEach(d => { districtSelect.innerHTML += `<option value="${d.code}">${d.name}</option>`; });
    } catch (error) { console.error('Lỗi tải quận/huyện:', error); }
}

async function loadWardsForProfile(districtCode) {
    const wardSelect = document.getElementById('profile-ward');
    if (!wardSelect) return;
    wardSelect.innerHTML = '<option value="">-- Chọn Phường/Xã --</option>';
    try {
        const response = await fetch(`${HOST_PROVINCE_API}d/${districtCode}?depth=2`);
        const data = await response.json();
        data.wards.forEach(w => { wardSelect.innerHTML += `<option value="${w.code}">${w.name}</option>`; });
    } catch (error) { console.error('Lỗi tải phường/xã:', error); }
}

// =========================================================
//                 LOGIC TRANG ĐƠN HÀNG CỦA TÔI
// =========================================================
function initOrdersPage() {
    loadMyOrders();
}

async function loadMyOrders() {
    const token = localStorage.getItem('jwtToken');
    const container = document.getElementById('orders-list-container');
    if (!container) return;
    container.innerHTML = '<p>Đang tải lịch sử đơn hàng...</p>';

    try {
        const response = await fetch(`${API_BASE_URL}/api/user/orders`, { headers: { 'Authorization': `Bearer ${token}` } });
        if (!response.ok) throw new Error('Không thể tải lịch sử đơn hàng.');
        
        allUserOrders = await response.json();
        renderOrders(allUserOrders);
        initializeOrderTabs();
    } catch (err) {
        container.innerHTML = `<p class="message error">${err.message}</p>`;
    }
}

function initializeOrderTabs() {
    const tabs = document.querySelectorAll('.order-status-tabs .tab-link');
    tabs.forEach(tab => {
        tab.addEventListener('click', () => {
            tabs.forEach(t => t.classList.remove('active'));
            tab.classList.add('active');
            filterOrdersByStatus(tab.dataset.status);
        });
    });
}

function filterOrdersByStatus(status) {
    const filteredOrders = (status === 'ALL') 
        ? allUserOrders 
        : allUserOrders.filter(order => order.status === status);
    renderOrders(filteredOrders);
}

// Trong file js/account.js

function renderOrders(orders) {
    const container = document.getElementById('orders-list-container');
    if (!container) return;

    if (orders.length === 0) {
        container.innerHTML = '<p>Không có đơn hàng nào trong mục này.</p>';
        return;
    }

    container.innerHTML = orders.map(order => createOrderCardHTML(order)).join('');

    // Gán sự kiện cho việc xem chi tiết (giữ nguyên)
    container.querySelectorAll('.order-card-header').forEach(header => {
        header.addEventListener('click', () => {
            toggleOrderDetail(header.parentElement);
        });
    });

    // **THÊM ĐOẠN NÀY: Gán sự kiện cho các nút Hủy đơn**
    container.querySelectorAll('.cancel-order-btn').forEach(button => {
        button.addEventListener('click', (event) => {
            event.stopPropagation(); // Ngăn việc mở chi tiết đơn hàng khi bấm hủy
            const orderId = event.target.dataset.orderId;
            handleCancelOrder(orderId);
        });
    });
}

function createOrderCardHTML(order) {
    // Biến để chứa HTML của nút hủy đơn
    let cancelButtonHTML = '';

    // Nếu trạng thái là "PENDING", thêm nút Hủy
    if (order.status === 'PENDING') {
        cancelButtonHTML = `<button class="btn btn-danger btn-sm cancel-order-btn" data-order-id="${order.id}">Hủy đơn</button>`;
    }

    return `
        <div class="order-card" id="order-${order.id}">
            <div class="order-card-header" data-order-id="${order.id}">
                <div class="order-info"><span>Mã đơn hàng:</span><strong>#${order.id}</strong></div>
                <div class="order-info"><span>Ngày đặt:</span><strong>${new Date(order.orderDate).toLocaleDateString('vi-VN')}</strong></div>
                <div class="order-status"><span class="status-badge status-${order.status}">${order.status}</span></div>
            </div>
            <div class="order-card-body"><p class="loading-details">Nhấn để xem chi tiết...</p></div>
            <div class="order-card-footer">
                <span>Tổng tiền:</span>
                <strong>${formatCurrency(order.totalAmount)}</strong>
                ${cancelButtonHTML} <!-- Thêm nút vào đây -->
            </div>
        </div>
    `;
}

async function handleCancelOrder(orderId) {
    if (!confirm(`Bạn có chắc muốn hủy đơn hàng #${orderId}? Hành động này không thể hoàn tác.`)) {
        return;
    }

    const token = localStorage.getItem('jwtToken');
    try {
        const response = await fetch(`${API_BASE_URL}/api/user/orders/${orderId}/cancel`, {
            method: 'PUT',
            headers: {
                'Authorization': `Bearer ${token}`
            }
        });

        const message = await response.text();

        if (!response.ok) {
            throw new Error(message || 'Không thể hủy đơn hàng.');
        }

        alert('Hủy đơn hàng thành công!');
        
        // Tải lại danh sách đơn hàng để cập nhật giao diện
        loadMyOrders();

    } catch (error) {
        alert(`Lỗi: ${error.message}`);
    }
}

async function toggleOrderDetail(orderCardElement) {
    const orderId = orderCardElement.querySelector('.order-card-header').dataset.orderId;
    const body = orderCardElement.querySelector('.order-card-body');
    
    orderCardElement.classList.toggle('open');

    if (orderCardElement.classList.contains('open') && !body.hasAttribute('data-loaded')) {
        const token = localStorage.getItem('jwtToken');
        try {
            const response = await fetch(`${API_BASE_URL}/api/user/orders/${orderId}`, { headers: { 'Authorization': `Bearer ${token}` } });
            if (!response.ok) throw new Error('Không thể tải chi tiết đơn hàng.');
            
            const orderDetail = await response.json();
            const items = orderDetail.items || [];
            
            let itemsHTML = items.map(item => `
                <a href="product-detail.html?id=${item.productId}" class="order-item-link" target="_blank">
                    <div class="order-item">
                        <img src="${item.imageUrl}" alt="${item.productName}">
                        <div class="item-details"><p class="item-name">${item.productName}</p><p class="item-variant">${item.variantName} / ${item.sizeName}</p></div>
                        <div class="item-price-details"><p class="item-price">${formatCurrency(item.price)}</p><p>Số lượng: ${item.quantity}</p></div>
                    </div>
                </a>
            `).join('');

            let discountRowHTML = '';
            if (orderDetail.discountAmount && orderDetail.discountAmount > 0) {
                discountRowHTML = `<div class="summary-row"><span>Giảm giá (${orderDetail.couponCode || 'N/A'}):</span><span class="discount">- ${formatCurrency(orderDetail.discountAmount)}</span></div>`;
            }

            body.innerHTML = `
                <div class="order-detail-layout">
                    <div class="order-detail-section"><h4>Sản phẩm trong đơn (${items.length})</h4>${itemsHTML}</div>
                    <div class="order-detail-section">
                        <h4>Thông tin giao hàng</h4>
                        <div class="customer-details">
                            <p><strong>Tên:</strong> <span>${orderDetail.customerName}</span></p>
                            <p><strong>SĐT:</strong> <span>${orderDetail.phoneNumber}</span></p>
                            <p><strong>Địa chỉ:</strong> <span>${orderDetail.fullAddress}</span></p>
                            <p><strong>Ghi chú:</strong> <span>${orderDetail.note || 'Không có'}</span></p>
                        </div>
                        <div class="order-summary-details">
                            <h4>Tổng kết đơn hàng</h4>
                            <div class="summary-row"><span>Tạm tính:</span><span>${formatCurrency(orderDetail.subtotal)}</span></div>
                            <div class="summary-row"><span>Phí vận chuyển:</span><span>${formatCurrency(orderDetail.shippingFee)}</span></div>
                            ${discountRowHTML}
                            <div class="summary-row total"><span>Tổng cộng:</span><span>${formatCurrency(orderDetail.totalAmount)}</span></div>
                        </div>
                    </div>
                </div>
            `;
            body.setAttribute('data-loaded', 'true');
        } catch (err) {
            body.innerHTML = `<p class="message error">${err.message}</p>`;
        }
    }
}

// =========================================================
//                 LOGIC TRANG ĐỔI MẬT KHẨU
// =========================================================
function initChangePasswordPage() {
    document.getElementById('change-password-form').addEventListener('submit', async (e) => {
        e.preventDefault();
        const token = localStorage.getItem('jwtToken');
        const currentPassword = document.getElementById('current-password').value;
        const newPassword = document.getElementById('new-password').value;
        const confirmPassword = document.getElementById('confirm-password').value;

        if (newPassword.length < 6) {
            alert('Mật khẩu mới phải có ít nhất 6 ký tự.');
            return;
        }
        if (newPassword !== confirmPassword) {
            alert('Mật khẩu mới và xác nhận không khớp!');
            return;
        }

        try {
            const response = await fetch(`${API_BASE_URL}/api/user/change-password`, {
                method: 'PUT',
                headers: { 'Content-Type': 'application/json', 'Authorization': `Bearer ${token}` },
                body: JSON.stringify({ currentPassword, newPassword, confirmPassword })
            });
            const message = await response.text();
            if (!response.ok) throw new Error(message);
            alert('Đổi mật khẩu thành công!');
            e.target.reset();
        } catch (error) {
            alert(`Lỗi: ${error.message}`);
        }
    });
}

// Hàm tiện ích
function formatCurrency(number) {
    if (typeof number !== 'number') return '0 ₫';
    return new Intl.NumberFormat('vi-VN', { style: 'currency', currency: 'VND' }).format(number);
}