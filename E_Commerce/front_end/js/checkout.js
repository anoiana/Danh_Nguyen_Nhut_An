// =========================================================
//            KHỞI TẠO VÀ CÁC BIẾN TOÀN CỤC
// =========================================================
let cartSubtotal = 0;
let shippingFee = 0;
let discountAmount = 0;
let appliedCoupon = null;

document.addEventListener('DOMContentLoaded', () => {
    // Logic bảo vệ: Nếu chưa đăng nhập, chuyển về trang login
    const token = localStorage.getItem('jwtToken');
    if (!token) {
        window.location.href = 'login.html';
        return;
    }

    loadCheckoutPageData();
    initializeEventListeners();
});

// =========================================================
//                LOGIC TẢI DỮ LIỆU CHÍNH
// =========================================================
async function loadCheckoutPageData() {
    try {
        // Gọi song song API lấy giỏ hàng và thông tin người dùng
        const [cart, user] = await Promise.all([
            fetchCartData(),
            fetchUserData()
        ]);

        // Kiểm tra giỏ hàng có rỗng không
        if (!cart || !cart.items || cart.items.length === 0) {
            alert("Giỏ hàng của bạn đang trống. Đang chuyển về trang chủ...");
            window.location.href = 'home.html';
            return;
        }
        
        // Hiển thị dữ liệu lên giao diện
        populateOrderSummary(cart);
        populateUserInfo(user);
        
        // Bắt đầu chuỗi tải địa chỉ và tự động chọn địa chỉ đã lưu của người dùng
        await loadProvinces(user.province, user.district, user.ward);

    } catch (error) {
        console.error("Lỗi khi tải trang checkout:", error);
        document.querySelector('.checkout-main').innerHTML = `<p class="message error">${error.message}</p>`;
    }
}

function initializeEventListeners() {
    document.getElementById('province').addEventListener('change', () => loadDistricts());
    document.getElementById('district').addEventListener('change', () => loadWards());
    document.getElementById('ward').addEventListener('change', calculateShipping);

    const promoInput = document.getElementById('promo-code-input');
    const promoBtn = document.getElementById('apply-promo-btn');
    promoInput.addEventListener('input', () => {
        promoBtn.classList.toggle('active', promoInput.value.trim() !== '');
    });
    promoBtn.addEventListener('click', applyCoupon);

    document.getElementById('checkout-form').addEventListener('submit', placeOrder);
}

// =========================================================
//                CÁC HÀM GỌI API
// =========================================================
async function fetchCartData() {
    const token = localStorage.getItem('jwtToken');
    const response = await fetch(`${API_BASE_URL}/api/cart`, { headers: { 'Authorization': `Bearer ${token}` } });
    if (!response.ok) throw new Error('Không thể tải giỏ hàng.');
    return response.json();
}

async function fetchUserData() {
    const token = localStorage.getItem('jwtToken');
    // API này sẽ trả về UserProfileDTO
    const response = await fetch(`${API_BASE_URL}/api/user/me`, { headers: { 'Authorization': `Bearer ${token}` } });
    if (!response.ok) throw new Error('Không thể tải thông tin người dùng.');
    return response.json();
}

// =========================================================
//             HIỂN THỊ DỮ LIỆU LÊN GIAO DIỆN
// =========================================================
function populateOrderSummary(cart) {
    const itemsContainer = document.getElementById('summary-items-container');
    const itemsCountEl = document.getElementById('total-items-count');
    
    itemsContainer.innerHTML = '';
    cartSubtotal = 0;
    let totalItems = 0;

    cart.items.forEach(item => {
        const itemTotal = item.price * item.quantity;
        cartSubtotal += itemTotal;
        totalItems += item.quantity;

        // Cấu trúc HTML được tối ưu lại
        itemsContainer.innerHTML += `
            <div class="summary-item">
                <div class="summary-item-image">
                    <img src="${item.imageUrl}" alt="${item.productName}">
                    <span class="summary-item-quantity">${item.quantity}</span>
                </div>
                <div class="summary-item-info">
                    <p class="item-name">${item.productName}</p>
                    <p class="item-variant">${item.variantName} / ${item.sizeName}</p>
                </div>
                <p class="summary-item-price">${formatCurrency(itemTotal)}</p>
            </div>
        `;
    });

    itemsCountEl.textContent = totalItems;
    document.getElementById('summary-subtotal').textContent = formatCurrency(cartSubtotal);
    updateFinalTotal();
}

function populateUserInfo(user) {
    // Điền các thông tin cơ bản từ UserProfileDTO
    document.getElementById('email').value = user.email || '';
    document.getElementById('fullName').value = user.username || '';
    document.getElementById('phone').value = user.phoneNumber || '';
    document.getElementById('address').value = user.address || '';
}

// =========================================================
//          XỬ LÝ ĐỊA CHỈ TỰ ĐỘNG VÀ VẬN CHUYỂN
// =========================================================
async function loadProvinces(savedProvinceName, savedDistrictName, savedWardName) {
    const response = await fetch('https://provinces.open-api.vn/api/p/');
    const provinces = await response.json();
    const select = document.getElementById('province');
    select.innerHTML = '<option value="">Tỉnh / Thành</option>';
    provinces.forEach(p => {
        const option = new Option(p.name, p.code);
        select.add(option);
    });

    // Tự động chọn tỉnh/thành phố đã lưu
    if (savedProvinceName) {
        const provinceOption = Array.from(select.options).find(opt => opt.text === savedProvinceName);
        if (provinceOption) {
            select.value = provinceOption.value;
            // Sau khi chọn tỉnh, tự động tải và chọn quận/huyện
            await loadDistricts(savedDistrictName, savedWardName);
        }
    }
}

async function loadDistricts(savedDistrictName, savedWardName) {
    const provinceCode = document.getElementById('province').value;
    const select = document.getElementById('district');
    const wardSelect = document.getElementById('ward');
    select.innerHTML = '<option value="">Quận / Huyện</option>';
    wardSelect.innerHTML = '<option value="">Phường / Xã</option>';
    
    if (!provinceCode) return;

    const response = await fetch(`https://provinces.open-api.vn/api/p/${provinceCode}?depth=2`);
    const data = await response.json();
    data.districts.forEach(d => select.add(new Option(d.name, d.code)));

    // Tự động chọn quận/huyện đã lưu
    if (savedDistrictName) {
        const districtOption = Array.from(select.options).find(opt => opt.text === savedDistrictName);
        if (districtOption) {
            select.value = districtOption.value;
            // Sau khi chọn quận, tự động tải và chọn phường/xã
            await loadWards(savedWardName);
        }
    }
}

async function loadWards(savedWardName) {
    const districtCode = document.getElementById('district').value;
    const select = document.getElementById('ward');
    select.innerHTML = '<option value="">Phường / Xã</option>';
    
    if (!districtCode) return;

    const response = await fetch(`https://provinces.open-api.vn/api/d/${districtCode}?depth=2`);
    const data = await response.json();
    data.wards.forEach(w => select.add(new Option(w.name, w.code)));
    
    // Tự động chọn phường/xã đã lưu
    if (savedWardName) {
        const wardOption = Array.from(select.options).find(opt => opt.text === savedWardName);
        if (wardOption) {
            select.value = wardOption.value;
            // Khi đã chọn xong địa chỉ cuối cùng, tính phí vận chuyển
            calculateShipping();
        }
    }
}

function calculateShipping() {
    shippingFee = 30000; // Phí cố định
    const shippingContainer = document.getElementById('shipping-method-container');
    shippingContainer.innerHTML = `
        <div class="option-box selected">
            <div class="shipping-method-info">
                <input type="radio" name="shipping" value="30000" checked>
                <label>Giao hàng tận nơi</label>
            </div>
            <span class="shipping-price">${formatCurrency(shippingFee)}</span>
        </div>
    `;
    document.getElementById('summary-shipping').textContent = formatCurrency(shippingFee);
    updateFinalTotal();
}

// =========================================================
//                  XỬ LÝ MÃ GIẢM GIÁ
// =========================================================
async function applyCoupon() {
    const token = localStorage.getItem('jwtToken');
    const code = document.getElementById('promo-code-input').value.trim().toUpperCase();
    if (!code) return;
    
    const messageEl = document.getElementById('promo-message');
    try {
        const response = await fetch(`${API_BASE_URL}/api/coupons/validate/${code}`, {
            method: 'GET',
            headers: { 'Authorization': `Bearer ${token}` }
        });
        
        if (!response.ok) {
            const errorText = await response.text();
            throw new Error(errorText || 'Mã giảm giá không hợp lệ.');
        }
        const data = await response.json();
        
        appliedCoupon = data;
        messageEl.textContent = `Áp dụng mã "${data.code}" thành công!`;
        messageEl.className = 'message success';
        updateFinalTotal();
        
    } catch (error) {
        appliedCoupon = null;
        messageEl.textContent = error.message;
        messageEl.className = 'message error';
        updateFinalTotal();
    }
}

// =========================================================
//            TÍNH TOÁN VÀ ĐẶT HÀNG
// =========================================================
function updateFinalTotal() {
    discountAmount = 0;
    const discountRow = document.querySelector('.discount-row');
    
    if (appliedCoupon) {
        if (appliedCoupon.type === 'PERCENTAGE') {
            discountAmount = cartSubtotal * (appliedCoupon.value / 100);
        } else { // FIXED_AMOUNT
            discountAmount = appliedCoupon.value;
        }
        document.getElementById('discount-code-text').textContent = appliedCoupon.code;
        document.getElementById('summary-discount').textContent = `- ${formatCurrency(discountAmount)}`;
        discountRow.style.display = 'flex';
    } else {
        discountRow.style.display = 'none';
    }
    
    const finalTotal = cartSubtotal - discountAmount + shippingFee;
    document.getElementById('summary-total').textContent = formatCurrency(finalTotal > 0 ? finalTotal : 0);
}

async function placeOrder(event) {
    event.preventDefault();
    const token = localStorage.getItem('jwtToken');
    
    // Thu thập dữ liệu từ form
    const orderData = {
        customerName: document.getElementById('fullName').value,
        email: document.getElementById('email').value,
        phoneNumber: document.getElementById('phone').value,
        shippingAddress: document.getElementById('address').value,
        shippingProvince: document.getElementById('province').options[document.getElementById('province').selectedIndex].text,
        shippingDistrict: document.getElementById('district').options[document.getElementById('district').selectedIndex].text,
        shippingWard: document.getElementById('ward').options[document.getElementById('ward').selectedIndex].text,
        note: document.getElementById('note').value,
        paymentMethod: document.querySelector('input[name="payment"]:checked').value,
        shippingFee: shippingFee,
        couponCode: appliedCoupon ? appliedCoupon.code : null
    };

    // Kiểm tra xem các trường địa chỉ đã được chọn chưa
    if (!orderData.shippingProvince || orderData.shippingProvince === "Tỉnh / Thành" ||
        !orderData.shippingDistrict || orderData.shippingDistrict === "Quận / Huyện" ||
        !orderData.shippingWard || orderData.shippingWard === "Phường / Xã") {
        alert("Vui lòng chọn đầy đủ thông tin Tỉnh/Thành, Quận/Huyện, và Phường/Xã.");
        return;
    }

    try {
        const response = await fetch(`${API_BASE_URL}/api/orders`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json', 'Authorization': `Bearer ${token}` },
            body: JSON.stringify(orderData)
        });
        
        if (!response.ok) {
            throw new Error(await response.text());
        }

        const savedOrder = await response.json();
        alert('Đặt hàng thành công! Mã đơn hàng của bạn là #' + savedOrder.id);
        
        if (typeof updateCartIconCount === 'function') {
            updateCartIconCount();
        }
        
        window.location.href = 'order-success.html?id=' + savedOrder.id;

    } catch (error) {
        alert('Lỗi khi đặt hàng: ' + error.message);
    }
}

// =========================================================
//                  HÀM TIỆN ÍCH
// =========================================================
function formatCurrency(number) {
    if (typeof number !== 'number') return '0 ₫';
    return new Intl.NumberFormat('vi-VN', { style: 'currency', currency: 'VND' }).format(number);
}