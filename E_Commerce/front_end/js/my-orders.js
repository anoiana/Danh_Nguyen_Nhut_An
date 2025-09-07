const API_BASE_URL = 'http://localhost:8080';

document.addEventListener('DOMContentLoaded', () => {
    const token = localStorage.getItem('jwtToken');
    if (!token) {
        window.location.href = 'login.html';
        return;
    }
    loadMyOrders();
});

async function loadMyOrders() {
    const token = localStorage.getItem('jwtToken');
    const container = document.getElementById('orders-list-container');
    container.innerHTML = '<p>Đang tải lịch sử đơn hàng...</p>';

    try {
        const response = await fetch(`${API_BASE_URL}/api/user/orders`, {
            headers: { 'Authorization': `Bearer ${token}` }
        });
        if (!response.ok) throw new Error('Không thể tải lịch sử đơn hàng.');
        
        const orders = await response.json(); // Nhận về List<OrderListViewDTO>
        renderOrders(orders);
    } catch (err) {
        container.innerHTML = `<p class="message error">${err.message}</p>`;
    }
}

function renderOrders(orders) {
    const container = document.getElementById('orders-list-container');
    if (orders.length === 0) {
        container.innerHTML = '<p>Bạn chưa có đơn hàng nào.</p>';
        return;
    }

    container.innerHTML = orders.map(order => createOrderCardHTML(order)).join('');

    container.querySelectorAll('.order-card-header').forEach(header => {
        header.addEventListener('click', () => {
            toggleOrderDetail(header.parentElement);
        });
    });
}

function createOrderCardHTML(order) {
    return `
        <div class="order-card" id="order-${order.id}">
            <div class="order-card-header" data-order-id="${order.id}">
                <div class="order-info">
                    <span>Mã đơn hàng:</span>
                    <strong>#${order.id}</strong>
                </div>
                <div class="order-info">
                    <span>Ngày đặt:</span>
                    <strong>${new Date(order.orderDate).toLocaleDateString('vi-VN')}</strong>
                </div>
                <div class="order-status">
                    <span class="status-badge status-${order.status}">${order.status}</span>
                </div>
            </div>
            <div class="order-card-body">
                <p class="loading-details">Đang tải chi tiết...</p>
            </div>
            <div class="order-card-footer">
                <span>Tổng tiền:</span>
                <strong>${formatCurrency(order.totalAmount)}</strong>
            </div>
        </div>
    `;
}

async function toggleOrderDetail(orderCardElement) {
    const orderId = orderCardElement.querySelector('.order-card-header').dataset.orderId;
    const body = orderCardElement.querySelector('.order-card-body');
    
    orderCardElement.classList.toggle('open');

    if (orderCardElement.classList.contains('open') && !body.hasAttribute('data-loaded')) {
        const token = localStorage.getItem('jwtToken');
        try {
            const response = await fetch(`${API_BASE_URL}/api/user/orders/${orderId}`, {
                headers: { 'Authorization': `Bearer ${token}` }
            });
            if (!response.ok) throw new Error('Không thể tải chi tiết đơn hàng.');
            
            const orderDetail = await response.json(); // Nhận về OrderDetailViewDTO
            
            let itemsHTML = (orderDetail.items || []).map(item => `
                <a href="product-detail.html?id=${item.productId}" class="order-item-link" target="_blank">
                    <div class="order-item">
                        <img src="${item.imageUrl}" alt="${item.productName}">
                        <div class="item-details">
                            <p class="item-name">${item.productName}</p>
                            <p class="item-variant">${item.variantName} / ${item.sizeName}</p>
                        </div>
                        <div class="item-price-details">
                            <p class="item-price">${formatCurrency(item.price)}</p>
                            <p>Số lượng: ${item.quantity}</p>
                        </div>
                    </div>
                </a>
            `).join('');

            let discountRowHTML = '';
            if (orderDetail.discountAmount && orderDetail.discountAmount > 0) {
                discountRowHTML = `
                    <div class="summary-row">
                        <span>Giảm giá (${orderDetail.couponCode || 'N/A'}):</span>
                        <span class="discount">- ${formatCurrency(orderDetail.discountAmount)}</span>
                    </div>
                `;
            }

            body.innerHTML = `
                <div class="order-detail-layout">
                    <div class="order-detail-section">
                        <h4>Sản phẩm trong đơn (${orderDetail.items.length})</h4>
                        ${itemsHTML}
                    </div>
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
                            <div class="summary-row">
                                <span>Tạm tính:</span>
                                <span>${formatCurrency(orderDetail.subtotal)}</span>
                            </div>
                            <div class="summary-row">
                                <span>Phí vận chuyển:</span>
                                <span>${formatCurrency(orderDetail.shippingFee)}</span>
                            </div>
                            ${discountRowHTML}
                            <div class="summary-row total">
                                <span>Tổng cộng:</span>
                                <span>${formatCurrency(orderDetail.totalAmount)}</span>
                            </div>
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

// Hàm tiện ích
function formatCurrency(number) {
    if (typeof number !== 'number') return '0 ₫';
    return new Intl.NumberFormat('vi-VN', { style: 'currency', currency: 'VND' }).format(number);
}