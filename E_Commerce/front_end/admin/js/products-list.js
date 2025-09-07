
document.addEventListener('DOMContentLoaded', function() {
    loadProductsForAdmin();
    document.getElementById('productsTableBody').addEventListener('click', handleProductTableClick);
    document.getElementById('searchInput').addEventListener('keyup', filterTable);
});

async function loadProductsForAdmin() {
    const token = localStorage.getItem('jwtToken');
    const tableBody = document.getElementById('productsTableBody');
    const table = document.getElementById('productsTable');
    const loadingDiv = document.getElementById('productsTableLoading');

    loadingDiv.style.display = 'block';
    table.style.display = 'none';
    tableBody.innerHTML = '';

    try {
        const response = await fetch(`${API_BASE_URL}/api/admin/products`, { headers: { 'Authorization': `Bearer ${token}` } });
        if (!response.ok) throw new Error(await response.text() || 'Không thể tải danh sách sản phẩm');
        
        const products = await response.json();
        if (products.length === 0) {
            tableBody.innerHTML = '<tr><td colspan="3">Chưa có sản phẩm nào. Bấm "Thêm Sản Phẩm Mới" để bắt đầu.</td></tr>';
        } else {
            products.forEach(product => {
                const row = `
                    <tr>
                        <td>${product.id}</td>
                        <td>${product.name}</td>
                        <td class="action-buttons" style="text-align: right;">
                            <button class="edit-btn" data-id="${product.id}" title="Sửa sản phẩm"><i class="fa-solid fa-pencil"></i></button>
                            <button class="delete-btn" data-id="${product.id}" title="Xóa sản phẩm"><i class="fa-solid fa-trash-can"></i></button>
                        </td>
                    </tr>
                `;
                tableBody.innerHTML += row;
            });
        }
        loadingDiv.style.display = 'none';
        table.style.display = 'table';
    } catch (error) {
        loadingDiv.textContent = `Lỗi: ${error.message}`;
    }
}

function filterTable() {
    // 1. Lấy giá trị tìm kiếm và chuyển thành chữ thường
    const searchTerm = document.getElementById('searchInput').value.toLowerCase();

    // 2. Lấy tất cả các dòng <tr> trong tbody của bảng
    const tableRows = document.querySelectorAll('#productsTableBody tr');
    
    // 3. Lặp qua từng dòng để quyết định ẩn hay hiện
    tableRows.forEach(row => {
        // Lấy nội dung text của ô thứ 2 (cell index 1) - là cột "Tên sản phẩm"
        const productNameCell = row.cells[1];
        if (productNameCell) {
            const productName = productNameCell.textContent.toLowerCase();

            // 4. So sánh và thực hiện ẩn/hiện
            if (productName.includes(searchTerm)) {
                row.style.display = ''; // Hiện dòng nếu khớp
            } else {
                row.style.display = 'none'; // Ẩn dòng nếu không khớp
            }
        }
    });
}

async function handleProductTableClick(event) {
    const target = event.target.closest('button');
    if (!target) return;
    
    const productId = target.dataset.id;
    const token = localStorage.getItem('jwtToken');

    if (target.classList.contains('edit-btn')) {
        // CHUYỂN HƯỚNG SANG TRANG SỬA VỚI ID SẢN PHẨM
        window.location.href = `product-edit.html?id=${productId}`;
    }

    if (target.classList.contains('delete-btn')) {
        if (confirm(`Bạn có chắc muốn xóa sản phẩm ID: ${productId}?`)) {
            try {
                const response = await fetch(`${API_BASE_URL}/api/admin/products/${productId}`, { method: 'DELETE', headers: { 'Authorization': `Bearer ${token}` } });
                if (response.ok) {
                    alert('Xóa thành công!');
                    loadProductsForAdmin(); // Tải lại danh sách
                } else {
                    alert('Lỗi khi xóa sản phẩm.');
                }
            } catch (error) {
                alert('Lỗi kết nối khi xóa.');
            }
        }
    }
}