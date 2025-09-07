let allOrders = []; // Cache lại danh sách đơn hàng để lọc và tìm kiếm ở phía client

// =========================================================
//                  KHỞI TẠO TRANG
// =========================================================
document.addEventListener('DOMContentLoaded', () => {
    // Logic bảo vệ (kiểm tra token) đã được xử lý bởi main-admin.js hoặc các file khác
    // Ở đây chỉ cần tải dữ liệu và gán sự kiện
    loadOrders();
    initializeEventListeners();
});

function initializeEventListeners() {
    document.getElementById('statusFilter').addEventListener('change', filterOrders);
    document.getElementById('orderSearch').addEventListener('input', filterOrders);
    // Gắn một event listener duy nhất vào tbody để xử lý tất cả các click
    document.getElementById('ordersTableBody').addEventListener('click', handleTableClick);
}
// =========================================================
//                  LOAD VÀ RENDER DANH SÁCH
// =========================================================
async function loadOrders() {
    const token = localStorage.getItem('jwtToken');
    const tableBody = document.getElementById('ordersTableBody');
    tableBody.innerHTML = '<tr><td colspan="6" style="text-align: center;">Đang tải...</td></tr>';

    try {
        const response = await fetch(`${API_BASE_URL}/api/admin/orders`, {
            headers: { 'Authorization': `Bearer ${token}` }
        });
        if (!response.ok) throw new Error('Không thể tải danh sách đơn hàng');

        allOrders = await response.json(); // Nhận về List<OrderListViewDTO>
        renderOrdersTable(allOrders);
    } catch(err) {
        tableBody.innerHTML = `<tr><td colspan="6" class="error">${err.message}</td></tr>`;
    }
}

function renderOrdersTable(orders) {
    const tableBody = document.getElementById('ordersTableBody');
    tableBody.innerHTML = '';
    if (orders.length === 0) {
        tableBody.innerHTML = '<tr><td colspan="6" style="text-align: center;">Không có đơn hàng nào khớp.</td></tr>';
        return;
    }
    orders.forEach(order => {
        // Cải tiến: Chỉ hiển thị ngày tháng cho gọn
        const orderDate = new Date(order.orderDate).toLocaleDateString('vi-VN');
        const statusKey = order.status.toUpperCase(); // Đảm bảo key luôn viết hoa
        
        const row = document.createElement('tr');
        row.dataset.orderId = order.id;
        row.innerHTML = `
            <td><strong>#${order.id}</strong></td>
            <td>${order.customerName}</td>
            <td>${orderDate}</td>
            <td class="order-total">${formatCurrency(order.totalAmount)}</td>
            <td><span class="status-badge status-${statusKey}">${order.status}</span></td>
            <td class="action-buttons">
                <!-- Cải tiến: Dùng icon button thay vì text button -->
                <button class="view-btn" data-id="${order.id}" title="Xem chi tiết">
                    <i class="fa-solid fa-eye"></i>
                </button>
            </td>
        `;
        tableBody.appendChild(row);
    });
}
function filterOrders() {
    const status = document.getElementById('statusFilter').value;
    const searchTerm = document.getElementById('orderSearch').value.toLowerCase();
    
    let filteredOrders = allOrders;

    if (status) {
        filteredOrders = filteredOrders.filter(order => order.status === status);
    }
    if (searchTerm) {
        filteredOrders = filteredOrders.filter(order => 
            order.id.toString().includes(searchTerm) ||
            order.customerName.toLowerCase().includes(searchTerm)
        );
    }
    renderOrdersTable(filteredOrders);
}

// =========================================================
//                  XEM CHI TIẾT & CẬP NHẬT
// =========================================================
// Hàm này nằm trong file admin/js/orders.js

// THAY THẾ TOÀN BỘ HÀM CŨ BẰNG HÀM NÀY
async function showOrderDetail(id) {
    const token = localStorage.getItem('jwtToken');
    const modal = document.getElementById('orderDetailModal');
    const modalContent = document.getElementById('modalContent');
    
    modal.style.display = 'flex';
    modalContent.innerHTML = '<div class="spinner-container"><div class="spinner"></div></div>';

    try {
        const response = await fetch(`${API_BASE_URL}/api/admin/orders/${id}`, { 
            headers: {'Authorization': `Bearer ${token}`}
        });
        
        if (!response.ok) {
            const errorText = await response.text();
            throw new Error(errorText || 'Không thể tải chi tiết đơn hàng');
        }
        
        const order = await response.json();
        
        // --- CÁC CẢI TIẾN BẮT ĐẦU TỪ ĐÂY ---

        // 1. Cải tiến Header: Thêm badge trạng thái
        const statusKey = order.status.toUpperCase();
        const headerHTML = `
            <header class="modal-header">
                <h2>Chi tiết Đơn hàng #${order.id}</h2>
                <span class="status-badge status-${statusKey}">${order.status}</span>
                <button class="close-modal-btn" aria-label="Đóng">&times;</button>
            </header>
        `;

        // 2. Cải tiến Danh sách sản phẩm
        let itemsHTML = (order.items || []).map(item => `
            <div class="order-item">
                <img src="${item.imageUrl}" alt="${item.productName}" class="item-image">
                <div class="item-details">
                    <strong class="item-name">${item.productName}</strong>
                    <small class="item-variant">${item.variantName} / Size: ${item.sizeName}</small>
                </div>
                <div class="item-price-info">
                    <span class="item-quantity">x ${item.quantity}</span>
                    <span class="item-price">${formatCurrency(item.price)}</span>
                </div>
            </div>
        `).join('');

        // 3. Cải tiến Thông tin khách hàng với Icons
        const customerInfoHTML = `
            <div class="detail-items">
                <p><i class="fa-solid fa-user"></i><strong>Tên:</strong> <span>${order.customerName || 'N/A'}</span></p>
                <p><i class="fa-solid fa-envelope"></i><strong>Email:</strong> <span>${order.email || 'N/A'}</span></p>
                <p><i class="fa-solid fa-phone"></i><strong>SĐT:</strong> <span>${order.phoneNumber || 'N/A'}</span></p>
                <p><i class="fa-solid fa-map-marker-alt"></i><strong>Địa chỉ:</strong> <span>${order.fullAddress || 'N/A'}</span></p>
                <p><i class="fa-solid fa-sticky-note"></i><strong>Ghi chú:</strong> <span>${order.note || 'Không có'}</span></p>
            </div>
        `;

        // 4. Cải tiến Tổng kết đơn hàng
        let discountRowHTML = order.discountAmount > 0 ? `
            <tr>
                <td>Giảm giá (${order.couponCode || 'N/A'}):</td>
                <td align="right" style="color: #dc2626;">- ${formatCurrency(order.discountAmount)}</td>
            </tr>` : '';
        const summaryHTML = `
            <table class="order-summary-table">
                <tbody>
                    <tr><td>Tạm tính:</td><td align="right">${formatCurrency(order.subtotal)}</td></tr>
                    <tr><td>Phí vận chuyển:</td><td align="right">${formatCurrency(order.shippingFee)}</td></tr>
                    ${discountRowHTML}
                    <tr class="total"><td><strong>Tổng cộng:</strong></td><td align="right"><strong>${formatCurrency(order.totalAmount)}</strong></td></tr>
                </tbody>
            </table>
        `;
        
        // 5. Cải tiến Footer: Chứa phần cập nhật trạng thái
        const footerHTML = `
            <footer class="modal-footer">
                <label for="newStatusSelect">Cập nhật trạng thái:</label>
                <select id="newStatusSelect" class="form-control">
                    <option value="PENDING">Chờ xác nhận</option>
                    <option value="PROCESSING">Đang xử lý</option>
                    <option value="SHIPPED">Đang giao</option>
                    <option value="DELIVERED">Đã giao</option>
                    <option value="CANCELED">Đã hủy</option>
                </select>
                <button class="btn btn-primary" id="updateStatusBtn">Cập nhật</button>
            </footer>
        `;
        
        // 6. Ghép tất cả lại
        modalContent.innerHTML = `
            ${headerHTML}
            <div class="modal-body">
                <div class="order-detail-layout">
                    <div class="order-detail-section">
                        <h4>Sản phẩm trong đơn (${(order.items || []).length})</h4>
                        <div class="order-items-container">${itemsHTML}</div>
                    </div>
                    <div class="order-detail-section">
                        <h4>Thông tin khách hàng</h4>
                        ${customerInfoHTML}
                        <hr class="form-divider">
                        <h4>Tổng kết đơn hàng</h4>
                        ${summaryHTML}
                    </div>
                </div>
            </div>
            ${footerHTML}
        `;

        // 7. Gán giá trị và sự kiện
        document.getElementById('newStatusSelect').value = order.status;
        modal.querySelector('.close-modal-btn').addEventListener('click', () => modal.style.display = 'none');
        document.getElementById('updateStatusBtn').addEventListener('click', () => updateStatus(id));

    } catch(err) {
        modalContent.innerHTML = `
            <header class="modal-header">
                <h2>Lỗi</h2>
                <button class="close-modal-btn">&times;</button>
            </header>
            <div class="modal-body"><p class="message error">${err.message}</p></div>`;
        modal.querySelector('.close-modal-btn').addEventListener('click', () => modal.style.display = 'none');
    }
}
async function updateStatus(id) {
    const token = localStorage.getItem('jwtToken');
    const newStatus = document.getElementById('newStatusSelect').value;
    if (!newStatus) return;

    try {
        const response = await fetch(`${API_BASE_URL}/api/admin/orders/${id}/status`, {
            method: 'PUT',
            headers: { 'Content-Type': 'application/json', 'Authorization': `Bearer ${token}` },
            body: JSON.stringify({ status: newStatus })
        });
        if (response.ok) {
            alert('Cập nhật trạng thái thành công!');
            document.getElementById('orderDetailModal').style.display = 'none';
            loadOrders(); // Tải lại danh sách để cập nhật trạng thái
        } else {
            throw new Error('Không thể cập nhật trạng thái');
        }
    } catch (err) {
        alert(`Lỗi: ${err.message}`);
    }
}
function handleTableClick(event) {
    const target = event.target.closest('button');
    if (target && target.classList.contains('view-btn')) {
        const orderId = target.dataset.id;
        showOrderDetail(orderId);
    }
}
