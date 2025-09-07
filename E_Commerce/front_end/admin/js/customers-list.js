// Giả sử API_BASE_URL đã được định nghĩa trong config.js

document.addEventListener('DOMContentLoaded', function() {
    const toastMessage = localStorage.getItem('toastMessage');
    if (toastMessage) {
        showToast(toastMessage);
        localStorage.removeItem('toastMessage');
    }

    loadCustomers();
    document.getElementById('searchInput').addEventListener('input', filterTable);
    document.getElementById('customersTableBody').addEventListener('click', handleTableClick);
});

async function loadCustomers() {
    showLoader();
    const token = localStorage.getItem('jwtToken');
    const tableBody = document.getElementById('customersTableBody');
    // Cập nhật colspan thành 6
    tableBody.innerHTML = '<tr><td colspan="6" style="text-align:center;">Đang tải...</td></tr>';
    
    try {
        const response = await fetch(`${API_BASE_URL}/api/admin/customers`, {
            headers: { 'Authorization': `Bearer ${token}` }
        });
        if (!response.ok) throw new Error('Không thể tải danh sách khách hàng');
        
        const customers = await response.json();
        renderTable(customers);
    } catch(err) {
        // Cập nhật colspan thành 6
        tableBody.innerHTML = `<tr><td colspan="6" style="text-align:center;">Lỗi: ${err.message}</td></tr>`;
    } finally {
        hideLoader();
    }
}

function renderTable(customers) {
    const tableBody = document.getElementById('customersTableBody');
    tableBody.innerHTML = '';
    if (customers.length === 0) {
        // Cập nhật colspan thành 6
        tableBody.innerHTML = '<tr><td colspan="6" style="text-align:center;">Không có khách hàng nào.</td></tr>';
        return;
    }

    customers.forEach(customer => {
        const joinDateDisplay = customer.joinDate 
            ? new Date(customer.joinDate).toLocaleDateString('vi-VN') 
            : '';
        
        // ▼▼▼ LOGIC MỚI CHO TRẠNG THÁI ▼▼▼
        const statusHtml = customer.enabled 
            ? '<span class="status-badge status-ACTIVE">Hoạt động</span>'
            : '<span class="status-badge status-DISABLED">Vô hiệu hóa</span>';
        // ▲▲▲ KẾT THÚC LOGIC MỚI ▲▲▲

        const row = document.createElement('tr');
        row.dataset.customerId = customer.id;
        // Cập nhật innerHTML của hàng để thêm cột trạng thái
        row.innerHTML = `
            <td>
                <div class="customer-cell">
                    <div class="customer-avatar">${getInitials(customer.username)}</div>
                    <div>
                        <strong class="name">${customer.username}</strong>
                    </div>
                </div>
            </td>
            <td>${customer.email || 'Chưa có'}</td>
            <td>${formatCurrency(customer.totalSpent || 0)}</td>
            <td>${joinDateDisplay}</td>
            <td>${statusHtml}</td> <!-- Thêm ô trạng thái vào đây -->
            <td class="action-buttons" style="text-align: right;">
                <a href="customer-detail.html?id=${customer.id}" class="edit-btn" title="Xem & Sửa chi tiết">
                    <i class="fa-solid fa-pencil"></i>
                </a>
            </td>
        `;
        tableBody.appendChild(row);
    });
}

function handleTableClick(event) {
    // Hiện tại hàm này chưa cần thiết
}

function filterTable(event) {
    const searchTerm = event.target.value.toLowerCase();
    const tableRows = document.querySelectorAll('#customersTableBody tr');
    tableRows.forEach(row => {
        const customerName = row.cells[0].textContent.toLowerCase();
        const customerEmail = row.cells[1].textContent.toLowerCase();
        row.style.display = customerName.includes(searchTerm) || customerEmail.includes(searchTerm) ? '' : 'none';
    });
}

// Hàm tiện ích
function formatCurrency(n) { 
    if (typeof n !== 'number') return '0 ₫';
    return new Intl.NumberFormat('vi-VN', { style: 'currency', currency: 'VND' }).format(n); 
}

function getInitials(n) { 
    if (!n) return '?'; 
    const w = n.trim().split(/\s+/); 
    return (w.length > 1 ? `${w[0][0]}${w[w.length - 1][0]}` : n.substring(0, 2)).toUpperCase(); 
}