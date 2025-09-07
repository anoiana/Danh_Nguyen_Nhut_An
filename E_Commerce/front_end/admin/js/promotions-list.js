
document.addEventListener('DOMContentLoaded', function() {
    const toastMessage = localStorage.getItem('toastMessage');
    if (toastMessage) {
        showToast(toastMessage);
        localStorage.removeItem('toastMessage');
    }

    loadPromotions();
    document.getElementById('promotionsTableBody').addEventListener('click', handleTableClick);
    document.getElementById('searchInput').addEventListener('keyup', filterTable);
});

async function loadPromotions() {
    showLoader();
    const token = localStorage.getItem('jwtToken');
    const tableBody = document.getElementById('promotionsTableBody');
    tableBody.innerHTML = '<tr><td colspan="5" style="text-align:center;">Đang tải...</td></tr>';

    try {
        const response = await fetch(`${API_BASE_URL}/api/admin/promotions`, { headers: { 'Authorization': `Bearer ${token}` } });
        if (!response.ok) throw new Error('Không thể tải danh sách khuyến mãi.');

        const promotions = await response.json();
        renderPromotionsTable(promotions);
    } catch (error) {
        tableBody.innerHTML = `<tr><td colspan="5" style="text-align:center;">${error.message}</td></tr>`;
    } finally {
        hideLoader();
    }
}

function renderPromotionsTable(promotions) {
    const tableBody = document.getElementById('promotionsTableBody');
    tableBody.innerHTML = '';
    if (promotions.length === 0) {
        tableBody.innerHTML = '<tr><td colspan="5" style="text-align:center;">Chưa có chương trình khuyến mãi nào.</td></tr>';
        return;
    }

    promotions.forEach(promo => {
        const statusClass = promo.active ? 'status-active' : 'status-inactive';
        const statusText = promo.active ? 'Hoạt động' : 'Tạm dừng';
        
        const row = document.createElement('tr');
        row.dataset.promotionId = promo.id;
        row.innerHTML = `
            <td><strong>${promo.name}</strong></td>
            <td><span class="discount-badge">${promo.discountPercentage}%</span></td>
            <td>${formatDate(promo.startDate)} - ${formatDate(promo.endDate)}</td>
            <td><span class="status-badge ${statusClass}">${statusText}</span></td>
            <td class="action-buttons" style="text-align: right;">
                <button class="edit-btn" title="Sửa"><i class="fa-solid fa-pencil"></i></button>
                <button class="delete-btn" title="Xóa"><i class="fa-solid fa-trash-can"></i></button>
            </td>
        `;
        tableBody.appendChild(row);
    });
}

function handleTableClick(event) {
    const target = event.target.closest('button');
    if (!target) return;

    const row = target.closest('tr');
    const promotionId = row.dataset.promotionId;

    if (target.classList.contains('edit-btn')) {
        window.location.href = `promotion-edit.html?id=${promotionId}`;
    }

    if (target.classList.contains('delete-btn')) {
        if (confirm(`Bạn có chắc muốn xóa khuyến mãi #${promotionId}?`)) {
            deletePromotion(promotionId, row);
        }
    }
}

async function deletePromotion(id, row) {
    const token = localStorage.getItem('jwtToken');
    row.style.opacity = '0.5';
    try {
        const response = await fetch(`${API_BASE_URL}/api/admin/promotions/${id}`, {
            method: 'DELETE',
            headers: { 'Authorization': `Bearer ${token}` }
        });
        if (response.ok) {
            showToast('Xóa khuyến mãi thành công!');
            row.remove();
        } else {
            throw new Error('Không thể xóa khuyến mãi.');
        }
    } catch (error) {
        showToast(error.message, 'error');
        row.style.opacity = '1';
    }
}

function filterTable() {
    const searchTerm = document.getElementById('searchInput').value.toLowerCase();
    const tableRows = document.querySelectorAll('#promotionsTableBody tr');
    tableRows.forEach(row => {
        const promoName = row.cells[0].textContent.toLowerCase();
        row.style.display = promoName.includes(searchTerm) ? '' : 'none';
    });
}

function formatDate(dateString) {
    if (!dateString) return '';
    return new Date(dateString).toLocaleDateString('vi-VN');
}