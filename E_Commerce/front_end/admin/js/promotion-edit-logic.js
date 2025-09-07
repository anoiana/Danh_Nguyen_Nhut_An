// =========================================================
//                  KHỞI TẠO TRANG
// =========================================================
document.addEventListener('DOMContentLoaded', function() {
    initializePage();
    initializeEventListeners();
});

function initializeEventListeners() {
    document.getElementById('promotionForm').addEventListener('submit', handleFormSubmit);
    document.getElementById('cancelEditBtn').addEventListener('click', () => {
        if (confirm('Bạn có chắc muốn hủy bỏ và quay lại trang danh sách?')) {
            window.location.href = 'promotions.html';
        }
    });
}

async function initializePage() {
    showLoader();
    try {
        await loadProductsIntoSelect(); // Luôn tải danh sách sản phẩm trước

        const urlParams = new URLSearchParams(window.location.search);
        const promotionId = urlParams.get('id');

        if (promotionId) {
            // Chế độ SỬA: Tải chi tiết khuyến mãi
            await loadPromotionDetails(promotionId);
        } else {
            // Chế độ THÊM MỚI
            document.getElementById('form-title').textContent = 'Tạo Khuyến mãi mới';
            // Gọi hàm setupTransferList từ file UI để khởi tạo danh sách trống
            if (window.setupTransferList) {
                window.setupTransferList();
            }
        }
    } catch (error) {
        showToast('Không thể tải dữ liệu cần thiết cho trang. ' + error.message, 'error');
    } finally {
        hideLoader();
    }
}

// =========================================================
//            TẢI DỮ LIỆU TỪ BACKEND
// =========================================================

// Tải danh sách TẤT CẢ sản phẩm và điền vào ô select ẩn
async function loadProductsIntoSelect() {
    const token = localStorage.getItem('jwtToken');
    const selectElement = document.getElementById('productIds');
    
    try {
        const response = await fetch(`${API_BASE_URL}/api/admin/products`, {
            headers: { 'Authorization': `Bearer ${token}` }
        });
        if (!response.ok) throw new Error('Không thể tải danh sách sản phẩm.');

        const products = await response.json();
        selectElement.innerHTML = ''; // Xóa thông báo tải
        products.forEach(product => {
            const option = new Option(`${product.name} (ID: ${product.id})`, product.id);
            selectElement.appendChild(option);
        });
    } catch (error) {
        console.error(error);
        throw error; // Ném lỗi ra để initializePage có thể bắt được
    }
}

// Tải chi tiết một khuyến mãi để điền vào form
async function loadPromotionDetails(id) {
    const token = localStorage.getItem('jwtToken');
    try {
        // GIẢ ĐỊNH: Bạn cần có một API endpoint để lấy chi tiết một khuyến mãi
        const response = await fetch(`${API_BASE_URL}/api/admin/promotions/${id}`, {
            headers: { 'Authorization': `Bearer ${token}` }
        });
        if (!response.ok) throw new Error('Không thể tải chi tiết khuyến mãi.');

        const promotion = await response.json();
        populateFormForEdit(promotion);

    } catch (error) {
        console.error(error);
        throw error;
    }
}

// =========================================================
//            RENDER VÀ CÁC HÀM GIAO DIỆN
// =========================================================

// Đổ dữ liệu của một khuyến mãi vào form để chỉnh sửa
// Đổ dữ liệu của một khuyến mãi vào form để chỉnh sửa
function populateFormForEdit(promotion) {
    document.getElementById('promotionId').value = promotion.id;
    document.getElementById('promotionName').value = promotion.name;
    document.getElementById('discountPercentage').value = promotion.discountPercentage;
    document.getElementById('startDate').value = promotion.startDate.split('T')[0];
    document.getElementById('endDate').value = promotion.endDate.split('T')[0];
    document.getElementById('isActive').checked = promotion.active;

    // Chọn các sản phẩm đã được áp dụng
    const productSelect = document.getElementById('productIds');

    // ▼▼▼ THAY ĐỔI QUAN TRỌNG Ở ĐÂY ▼▼▼
    // Sử dụng (promotion.products || []) để cung cấp một mảng rỗng làm giá trị dự phòng
    // nếu promotion.products không tồn tại.
    const productIdsToSelect = (promotion.products || []).map(p => p.id.toString());
    // ▲▲▲ KẾT THÚC THAY ĐỔI ▲▲▲
    
    Array.from(productSelect.options).forEach(option => {
        option.selected = productIdsToSelect.includes(option.value);
    });
    
    // Cập nhật tiêu đề và nút bấm
    document.getElementById('form-title').textContent = `Chỉnh sửa Khuyến mãi: ${promotion.name}`;
    document.querySelector('#submitPromotionBtn').textContent = 'Cập nhật';
    document.getElementById('cancelEditBtn').style.display = 'inline-flex';
    
    // Gọi hàm setupTransferList từ file UI để cập nhật giao diện
    if (window.setupTransferList) {
        window.setupTransferList();
    }
}
function resetForm() {
    document.getElementById('promotionForm').reset();
    document.getElementById('promotionId').value = '';
    document.getElementById('form-title').textContent = 'Tạo Khuyến mãi mới';
    document.querySelector('#submitPromotionBtn').textContent = 'Lưu Khuyến mãi';
    document.getElementById('cancelEditBtn').style.display = 'none';
    
    // Bỏ chọn tất cả sản phẩm
    Array.from(document.getElementById('productIds').options).forEach(option => option.selected = false);

    // Gọi hàm setupTransferList từ file UI để reset giao diện
     if (window.setupTransferList) {
        window.setupTransferList();
    }
}



async function handleFormSubmit(event) {
    event.preventDefault();
    const token = localStorage.getItem('jwtToken');
    const promotionId = document.getElementById('promotionId').value;
    
    const isEditing = !!promotionId;
    const method = isEditing ? 'PUT' : 'POST';
    const url = isEditing 
        ? `${API_BASE_URL}/api/admin/promotions/${promotionId}` 
        : `${API_BASE_URL}/api/admin/promotions`;

    // Lấy danh sách ID sản phẩm được chọn từ thẻ select ẩn
    const selectedProductIds = Array.from(document.getElementById('productIds').selectedOptions).map(option => parseInt(option.value));
    
    if (selectedProductIds.length === 0) {
        showToast('Vui lòng chọn ít nhất một sản phẩm để áp dụng.', 'error');
        return;
    }

    const promotionData = {
        name: document.getElementById('promotionName').value.trim(),
        discountPercentage: parseInt(document.getElementById('discountPercentage').value),
        startDate: document.getElementById('startDate').value,
        endDate: document.getElementById('endDate').value,
        active: document.getElementById('isActive').checked,
        productIds: selectedProductIds
    };

    // Validate dữ liệu cơ bản
    if (!promotionData.name) {
        showToast('Tên chương trình không được để trống.', 'error');
        return;
    }

    showLoader();
    try {
        const response = await fetch(url, {
            method: method,
            headers: { 
                'Content-Type': 'application/json',
                'Authorization': `Bearer ${token}` 
            },
            body: JSON.stringify(promotionData)
        });

        if (response.ok) {
            localStorage.setItem('toastMessage', `Đã ${isEditing ? 'cập nhật' : 'thêm'} khuyến mãi thành công!`);
            window.location.href = 'promotions.html'; // Chuyển hướng về trang danh sách
        } else {
            const errorText = await response.text();
            throw new Error(errorText || 'Hành động thất bại.');
        }
    } catch (error) {
        hideLoader();
        showToast('Lỗi: ' + error.message, 'error');
    }
}