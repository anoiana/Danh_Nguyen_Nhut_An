// NỘI DUNG MỚI CHO: admin/js/coupons-list.js

document.addEventListener('DOMContentLoaded', function() {
    const toastMessage = localStorage.getItem('toastMessage');
    if (toastMessage) {
        showToast(toastMessage);
        localStorage.removeItem('toastMessage');
    }

    loadCoupons();
    initializeEventListeners();
});

function initializeEventListeners() {
    document.getElementById('searchInput').addEventListener('input', filterTable);
    document.getElementById('couponsTableBody').addEventListener('click', handleTableClick);
}


async function loadCoupons() {
    showLoader();
    const token = localStorage.getItem('jwtToken');
    const tableBody = document.getElementById('couponsTableBody');
    if (!tableBody) {
        console.error("Lỗi nghiêm trọng: Không tìm thấy #couponsTableBody");
        hideLoader();
        return;
    }
    tableBody.innerHTML = '<tr><td colspan="6" style="text-align:center;">Đang tải...</td></tr>';
    
    try {
        const response = await fetch(`${API_BASE_URL}/api/admin/coupons`, {
            headers: { 'Authorization': `Bearer ${token}` }
        });
        if (!response.ok) throw new Error('Không thể tải mã giảm giá');
        
        const coupons = await response.json();
        renderTable(coupons);
    } catch(err) {
        tableBody.innerHTML = `<tr><td colspan="6" style="text-align:center;">Lỗi: ${err.message}</td></tr>`;
    } finally {
        hideLoader();
    }
}

function renderTable(coupons) {
    const tableBody = document.getElementById('couponsTableBody');
    tableBody.innerHTML = '';
    if (coupons.length === 0) {
        tableBody.innerHTML = '<tr><td colspan="6" style="text-align:center;">Chưa có mã giảm giá nào.</td></tr>';
        return;
    }

    coupons.forEach(coupon => {
        const valueDisplay = coupon.type === 'PERCENTAGE' 
            ? `${coupon.value}%` 
            : formatCurrency(coupon.value);
        
        const isExpired = new Date(coupon.expiryDate) < new Date().setHours(0,0,0,0);
        const statusText = coupon.active && !isExpired ? 'Hoạt động' : 'Hết hạn/Khóa';
        const statusClass = coupon.active && !isExpired ? 'status-active' : 'status-inactive';

        const row = document.createElement('tr');
        row.innerHTML = `
            <td><strong>${coupon.code}</strong></td>
            <td>${valueDisplay}</td>
            <td>${coupon.usedCount} / ${coupon.quantity}</td>
            <td>${new Date(coupon.expiryDate).toLocaleDateString('vi-VN')}</td>
            <td><span class="status-badge ${statusClass}">${statusText}</span></td>
            <td class="action-buttons" style="text-align: right;">
                <a href="coupon-edit.html?id=${coupon.id}" class="btn btn-secondary btn-sm edit-btn" title="Sửa">
                    <i class="fa-solid fa-pencil"></i>
                </a>
                <button class="btn btn-danger btn-sm delete-btn" data-id="${coupon.id}" title="Xóa">
                    <i class="fa-solid fa-trash"></i>
                </button>
            </td>
        `;
        tableBody.appendChild(row);
    });
}

function handleTableClick(event) {
    const deleteButton = event.target.closest('.delete-btn');
    if (deleteButton) {
        const id = deleteButton.dataset.id;
        deleteCoupon(id);
    }
}

async function deleteCoupon(id) {
    if (confirm(`Bạn có chắc muốn xóa mã giảm giá #${id}?`)) {
        showLoader();
        const token = localStorage.getItem('jwtToken');
        try {
            const response = await fetch(`${API_BASE_URL}/api/admin/coupons/${id}`, {
                method: 'DELETE',
                headers: { 'Authorization': `Bearer ${token}` }
            });
            if (response.ok) {
                showToast('Xóa thành công!');
                loadCoupons();
            } else {
                throw new Error(await response.text() || 'Lỗi khi xóa mã giảm giá.');
            }
        } catch(err) {
            showToast(`Lỗi: ${err.message}`, 'error');
        } finally {
            hideLoader();
        }
    }
}

function filterTable(event) {
    const searchTerm = event.target.value.toLowerCase();
    const tableRows = document.querySelectorAll('#couponsTableBody tr');
    tableRows.forEach(row => {
        const couponCode = row.cells[0].textContent.toLowerCase();
        row.style.display = couponCode.includes(searchTerm) ? '' : 'none';
    });
}

// Hàm tiện ích
function formatCurrency(n) { return new Intl.NumberFormat('vi-VN', { style: 'currency', currency: 'VND' }).format(n || 0); }