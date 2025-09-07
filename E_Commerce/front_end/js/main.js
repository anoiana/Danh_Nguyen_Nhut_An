// =========================================================
//                  KHỞI TẠO CHUNG
// =========================================================
document.addEventListener('DOMContentLoaded', function() {
    // Dùng Promise.all để có thể thực hiện các hành động sau khi cả hai đã tải xong
    Promise.all([
        loadHTML('partials/_header.html', document.body, true),
        loadHTML('partials/_footer.html', document.body, false)
    ]).then(() => {
        // Sau khi header và footer đã tải xong, kiểm tra trang hiện tại
        routePage();
    });
});

// =========================================================
//              BỘ ĐỊNH TUYẾN ĐƠN GIẢN (ROUTER)
// =========================================================
function routePage() {
    const path = window.location.pathname;

    // Nếu đang ở trang chi tiết sản phẩm
    if (path.includes('product-detail.html')) {
        // Kiểm tra xem hàm initProductDetailPage đã tồn tại chưa (để chắc chắn script đã được tải)
        if (typeof initProductDetailPage === 'function') {
            initProductDetailPage();
        } else {
            console.error('Lỗi: Hàm initProductDetailPage không được tìm thấy. Script product-detail.js có thể chưa được tải.');
        }
    }

    // Bạn có thể thêm các điều kiện else if cho các trang khác ở đây
    // Ví dụ:
    // else if (path.includes('products.html')) {
    //     if (typeof initProductsPage === 'function') {
    //         initProductsPage();
    //     }
    // }
}


// =========================================================
//            HÀM TẢI CÁC THÀNH PHẦN HTML
// =========================================================
async function loadHTML(url, element, prepend = false) {
    try {
        const response = await fetch(url);
        if (!response.ok) {
            throw new Error(`Network response was not ok for ${url}`);
        }
        const html = await response.text();
        if (prepend) {
            element.insertAdjacentHTML('afterbegin', html);
        } else {
            element.insertAdjacentHTML('beforeend', html);
        }

        // Sau khi header đã được tải xong, MỚI cập nhật trạng thái user
        if (url.includes('_header.html')) {
            updateHeaderUserStatus();
             loadCategoriesIntoHeader();
        }
    } catch (error) {
        console.error(`Failed to load ${url}:`, error);
    }
}


function updateHeaderUserStatus() {
    const token = localStorage.getItem('jwtToken');
    const user = JSON.parse(localStorage.getItem('user'));
    
    const userActionsDiv = document.getElementById('user-actions');
    const userInfoHeaderDiv = document.getElementById('user-info-header');
    
    if (!userActionsDiv || !userInfoHeaderDiv) {
        console.warn("Header elements not found. Skipping user status update.");
        return;
    }
    
    if (token && user) {
        // --- Đã đăng nhập ---
        userActionsDiv.style.display = 'none';
        userInfoHeaderDiv.style.display = 'flex';
        
        document.getElementById('welcome-message').textContent = `Xin chào, ${user.username}`;
        
        const logoutLink = document.getElementById('logout-link');
        logoutLink.addEventListener('click', (e) => {
            e.preventDefault();
            localStorage.clear();
            window.location.href = 'login.html';
        });

        if (user.roles && user.roles.includes('ROLE_ADMIN')) {
            const adminLink = document.getElementById('admin-link');
            if (adminLink) adminLink.style.display = 'block';
        }

        // Cập nhật avatar và số lượng giỏ hàng
        updateHeaderAvatar();
        updateCartIconCount();

        // **GỌI HÀM KHỞI TẠO DROPDOWN TẠI ĐÂY**
        initializeDropdowns();

    } else {
        // --- Chưa đăng nhập ---
        userActionsDiv.style.display = 'flex';
        userInfoHeaderDiv.style.display = 'none';
    }
}

async function updateHeaderAvatar() {
    const token = localStorage.getItem('jwtToken');
    const headerAvatarContainer = document.getElementById('header-avatar');
    if (!token || !headerAvatarContainer) return;

    try {
        const response = await fetch(`${API_BASE_URL}/api/user/me`, {
            headers: { 'Authorization': `Bearer ${token}` }
        });
        if (response.ok) {
            const userProfile = await response.json();
            const defaultHeaderSvg = `<svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="currentColor"><path d="M12 12c2.21 0 4-1.tr9 4-4s-1.79-4-4-4-4 1.79-4 4 1.79 4 4 4zm0 2c-2.67 0-8 1.34-8 4v2h16v-2c0-2.66-5.33-4-8-4z"/></svg>`;

            if (userProfile.avatarUrl) {
                headerAvatarContainer.innerHTML = `<img src="${userProfile.avatarUrl}" alt="Avatar">`;
            } else {
                headerAvatarContainer.innerHTML = defaultHeaderSvg;
            }
        }
    } catch (error) {
        console.error("Failed to fetch user profile for avatar:", error);
    }
}

async function updateCartIconCount() {
    const token = localStorage.getItem('jwtToken');
    const cartCountEl = document.getElementById('cart-item-count');

    if (!token || !cartCountEl) {
        if(cartCountEl) cartCountEl.style.display = 'none';
        return;
    }

    try {
        const response = await fetch(`${API_BASE_URL}/api/cart`, {
            headers: { 'Authorization': `Bearer ${token}` }
        });
        
        if (response.ok) {
            const cart = await response.json();
            const totalItems = (cart.items && Array.isArray(cart.items))
                ? cart.items.reduce((sum, item) => sum + item.quantity, 0)
                : 0;
            
            cartCountEl.textContent = totalItems;
            cartCountEl.style.display = totalItems > 0 ? 'flex' : 'none';
        } else {
            cartCountEl.style.display = 'none';
        }
    } catch (error) {
        console.error("Failed to fetch cart count:", error);
        cartCountEl.style.display = 'none';
    }
}

function initializeDropdowns() {
    const dropdownBtn = document.querySelector('.dropdown-btn');
    const dropdownContent = document.querySelector('.dropdown-content');
    
    // Nếu không tìm thấy các phần tử thì thoát
    if (!dropdownBtn || !dropdownContent) {
        return;
    }

    // Gán sự kiện click cho nút dropdown
    dropdownBtn.addEventListener('click', function(event) {
        // Ngăn sự kiện click lan ra ngoài ( quan trọng cho logic "click outside")
        event.stopPropagation();
        // Bật/tắt class 'show' để hiện/ẩn menu
        dropdownContent.classList.toggle('show');
    });

    // Thêm sự kiện để đóng menu khi click ra ngoài
    window.addEventListener('click', function(event) {
        // Nếu menu đang mở và người dùng không click vào menu
        if (dropdownContent.classList.contains('show')) {
            // Tìm phần tử .dropdown bao ngoài cùng
            const dropdownContainer = dropdownBtn.closest('.dropdown');
            // Nếu click không nằm trong khu vực dropdown, hãy đóng nó lại
            if (dropdownContainer && !dropdownContainer.contains(event.target)) {
                dropdownContent.classList.remove('show');
            }
        }
    });
}
async function loadCategoriesIntoHeader() {
    const dropdownMenu = document.getElementById('categories-dropdown');
    if (!dropdownMenu) return;

    try {
        // Luôn hiển thị thông báo tải ban đầu
        dropdownMenu.innerHTML = '<li><a href="#">Đang tải...</a></li>';

        const response = await fetch(`${API_BASE_URL}/api/home/categories`);
        if (!response.ok) throw new Error('Không thể tải danh mục.');

        const categories = await response.json();
        
        // Xóa thông báo tải
        dropdownMenu.innerHTML = '';

        // -- BẮT ĐẦU PHẦN THÊM MỚI --

        // 1. Thêm mục "Tất cả sản phẩm"
        const allProductsLi = document.createElement('li');
        // Link này sẽ trỏ đến trang products.html mà không có tham số category
        // Trang products.js sẽ cần được cập nhật để xử lý trường hợp này
        allProductsLi.innerHTML = `<a href="products.html" style="font-weight: bold;">Tất cả sản phẩm</a>`;
        dropdownMenu.appendChild(allProductsLi);

        // 2. Thêm mục "Sản phẩm khuyến mãi"
        const promoProductsLi = document.createElement('li');
        // Link này sẽ có một tham số đặc biệt, ví dụ ?filter=promotion
        promoProductsLi.innerHTML = `<a href="products.html?filter=promotion" style="color: #dc3545;">Sản phẩm khuyến mãi</a>`;
        dropdownMenu.appendChild(promoProductsLi);
        
        // 3. Thêm một đường kẻ ngang để phân tách
        const divider = document.createElement('li');
        divider.innerHTML = '<hr style="margin: 5px 0; border-color: #f0f0f0;">';
        dropdownMenu.appendChild(divider);

        // -- KẾT THÚC PHẦN THÊM MỚI --
        
        // 4. Lặp qua và thêm các danh mục từ API
        categories.forEach(category => {
            const li = document.createElement('li');
            li.innerHTML = `<a href="products.html?category=${category.id}">${category.name}</a>`;
            dropdownMenu.appendChild(li);
        });

    } catch (error) {
        console.error("Không thể tải danh mục:", error);
        dropdownMenu.innerHTML = '<li><a href="#">Lỗi tải danh mục</a></li>';
    }
}