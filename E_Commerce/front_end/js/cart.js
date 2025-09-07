// =========================================================
//                  KHỞI TẠO TRANG GIỎ HÀNG
// =========================================================
document.addEventListener('DOMContentLoaded', function() {
    const token = localStorage.getItem('jwtToken');
    if (!token) {
        // Nếu chưa đăng nhập, hiển thị thông báo và dừng lại
        document.getElementById('cart-content-wrapper').innerHTML = `
            <div class="empty-cart-container">
                <p>Vui lòng <a href="login.html">đăng nhập</a> để xem giỏ hàng của bạn.</p>
            </div>
        `;
        document.querySelector('.cart-title').style.display = 'none';
        return;
    }
    loadCart();
});

// =========================================================
//            TẢI VÀ HIỂN THỊ DỮ LIỆU GIỎ HÀNG
// =========================================================
async function loadCart() {
    const token = localStorage.getItem('jwtToken');
    const cartWrapper = document.getElementById('cart-content-wrapper');

    try {
        const response = await fetch(`${API_BASE_URL}/api/cart`, {
            headers: { 'Authorization': `Bearer ${token}` }
        });
        if (!response.ok) {
            throw new Error('Không thể tải giỏ hàng. Vui lòng thử lại.');
        }

        const cart = await response.json();

        if (!cart || !cart.items || cart.items.length === 0) {
            renderEmptyCart(cartWrapper);
        } else {
            renderCartContent(cartWrapper, cart);
        }

    } catch (error) {
        cartWrapper.innerHTML = `<p class="message error">${error.message}</p>`;
    }
}

// =========================================================
//            CÁC HÀM RENDER (TẠO HTML)
// =========================================================

function renderEmptyCart(container) {
    container.innerHTML = `
        <div class="empty-cart-container">
            <p>Giỏ hàng của bạn đang trống.</p>
            <a href="home.html" class="btn btn-primary">Bắt đầu mua sắm</a>
        </div>
    `;
}

function renderCartContent(container, cart) {
    const items = cart.items;
    const totalAmount = items.reduce((sum, item) => sum + (item.price * item.quantity), 0);
    
    // Sửa lại logic onclick: chỉ truyền vào itemId và sự thay đổi (+1 hoặc -1)
    const itemsHTML = items.map(item => `
        <div class="cart-item" data-item-id="${item.id}">
            <div class="product-details">
                <img src="${item.imageUrl}" alt="${item.productName}">
                <div class="product-info">
                    <h4>${item.productName}</h4>
                    <p>${item.variantName} / ${item.sizeName}</p>
                    <p class="item-price">${formatCurrency(item.price)}</p>
                </div>
            </div>
            <div class="item-quantity">
                <button class="qty-btn" onclick="updateQuantity(${item.id}, -1)">-</button>
                <input type="text" class="qty-input" value="${item.quantity}" readonly>
                <button class="qty-btn" onclick="updateQuantity(${item.id}, 1)">+</button>
            </div>
            <div class="item-total">${formatCurrency(item.price * item.quantity)}</div>
            <div class="item-remove">
                <button class="remove-btn" onclick="removeItem(${item.id})">
                    <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><polyline points="3 6 5 6 21 6"></polyline><path d="M19 6v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6m3 0V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2"></path><line x1="10" y1="11" x2="10" y2="17"></line><line x1="14" y1="11" x2="14" y2="17"></line></svg>
                </button>
            </div>
        </div>
    `).join('');

    container.innerHTML = `
        <div class="cart-layout">
            <div class="cart-items-list">
                <div class="cart-header">
                    <div class="header-product">Sản phẩm</div>
                    <div class="header-quantity">Số lượng</div>
                    <div class="header-total">Tổng tiền</div>
                    <div class="header-remove">Xóa</div>
                </div>
                ${itemsHTML}
                <a href="home.html" class="btn-continue">Tiếp tục mua sắm</a>
            </div>

            <div class="cart-summary">
                <h3>Tóm tắt đơn hàng</h3>
                <div class="summary-row">
                    <span>Tổng tiền</span>
                    <span id="summary-total">${formatCurrency(totalAmount)}</span>
                </div>
                <button class="btn-checkout" onclick="goToCheckout()">Thanh Toán</button>
            </div>
        </div>
    `;
}

// =========================================================
//            HÀM XỬ LÝ SỰ KIỆN (CẬP NHẬT, XÓA)
// =========================================================

async function updateQuantity(itemId, change) {
    const token = localStorage.getItem('jwtToken');
    
    // Tìm số lượng hiện tại từ giao diện
    const itemRow = document.querySelector(`.cart-item[data-item-id='${itemId}']`);
    const currentQtyInput = itemRow.querySelector('.qty-input');
    const currentQty = parseInt(currentQtyInput.value);
    
    const newQty = currentQty + change;

    // Nếu giảm số lượng xuống 0 hoặc thấp hơn, hãy xóa sản phẩm
    if (newQty < 1) {
        removeItem(itemId);
        return;
    }

    try {
        const response = await fetch(`${API_BASE_URL}/api/cart/items/${itemId}`, {
            method: 'PUT',
            headers: {
                'Content-Type': 'application/json',
                'Authorization': `Bearer ${token}`
            },
            body: JSON.stringify({ quantity: newQty })
        });

        if (response.ok) {
            // Thay vì render lại toàn bộ, chỉ tải lại giỏ hàng để cập nhật
            loadCart();
            // Cập nhật số lượng trên icon header (hàm này từ main.js)
            updateCartIconCount();
        } else {
            const error = await response.text();
            alert(`Lỗi khi cập nhật số lượng: ${error}`);
        }
    } catch (error) {
        alert('Lỗi kết nối. Không thể cập nhật giỏ hàng.');
    }
}

async function removeItem(itemId) {
    if (!confirm('Bạn có chắc muốn xóa sản phẩm này khỏi giỏ hàng?')) {
        return;
    }
    const token = localStorage.getItem('jwtToken');
    try {
        const response = await fetch(`${API_BASE_URL}/api/cart/items/${itemId}`, {
            method: 'DELETE',
            headers: { 'Authorization': `Bearer ${token}` }
        });

        if (response.ok) {
            loadCart();
            updateCartIconCount();
        } else {
            const error = await response.text();
            alert(`Lỗi khi xóa sản phẩm: ${error}`);
        }
    } catch (error) {
        alert('Lỗi kết nối. Không thể xóa sản phẩm.');
    }
}

function goToCheckout() {
    window.location.href = 'checkout.html';
}

// =========================================================
//                  HÀM TIỆN ÍCH
// =========================================================
function formatCurrency(number) {
    if (typeof number !== 'number') return '';
    return new Intl.NumberFormat('vi-VN', { style: 'currency', currency: 'VND' }).format(number);
}