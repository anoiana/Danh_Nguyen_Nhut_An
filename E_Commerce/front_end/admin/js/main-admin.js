
function showLoader() {
    const loader = document.getElementById('loading-overlay');
    if (loader) {
        loader.style.display = 'flex';
    }
}

function hideLoader() {
    const loader = document.getElementById('loading-overlay');
    if (loader) {
        loader.style.display = 'none';
    }
}
document.addEventListener('DOMContentLoaded', function () {
    // Tải sidebar vào tất cả các trang admin
    loadHTML('partials/_sidebar.html', document.body, true)
        .then(() => {
            // Sau khi sidebar được tải, cập nhật trạng thái user và link active
            updateSidebarUser();
            setActiveNavLink();
        });
});

async function loadHTML(url, element, prepend = false) {
    try {
        const response = await fetch(url);
        if (!response.ok) throw new Error(`Could not load ${url}`);
        const html = await response.text();
        if (prepend) {
            element.insertAdjacentHTML('afterbegin', html);
        } else {
            element.insertAdjacentHTML('beforeend', html);
        }
    } catch (error) {
        console.error("Lỗi khi tải partial HTML:", error);
        console.warn("Hãy đảm bảo rằng bạn đang chạy trang web qua một server (ví dụ: Live Server của VS Code) chứ không phải mở file trực tiếp (file://).");
    }
}

function updateSidebarUser() {
    const user = JSON.parse(localStorage.getItem('user'));
    const userInfoDiv = document.getElementById('user-info-sidebar');
    if (user && userInfoDiv) {
        userInfoDiv.innerHTML = `
            <p style="margin:0; font-weight: 500;">${user.username}</p>
            <a href="#" id="admin-logout" style="font-size: 0.8rem; color: #777;">Đăng xuất</a>
        `;
        document.getElementById('admin-logout').addEventListener('click', (e) => {
            e.preventDefault();
            localStorage.clear();
            window.location.href = '../login.html'; // Quay về trang login ở thư mục cha
        });
    }
}

/**
 * Cập nhật hàm này để xử lý các trang con như product-edit.html
 */
function setActiveNavLink() {
    const currentPage = window.location.pathname.split('/').pop();
    let navId;

    switch (currentPage) {
        case 'products.html':
        case 'product-edit.html': // <-- THAY ĐỔI QUAN TRỌNG
            // Khi ở trang products.html hoặc product-edit.html,
            // đều coi như đang ở mục "Sản phẩm".
            navId = 'nav-products';
            break;
        case 'customers.html':
        case 'customer-add.html':
        case 'customer-detail.html': // <-- THÊM DÒNG NÀY
            navId = 'nav-customers';
            break;
        case 'orders.html':
            navId = 'nav-orders';
            break;
        case 'promotions.html':
        case 'promotion-edit.html': // <-- THÊM DÒNG NÀY
            navId = 'nav-promotions';
            break;
        case 'coupons.html':
        case 'coupon-edit.html':
            navId = 'nav-coupons'; // Giả sử id của link là nav-coupons
            break;
        case 'index.html':
        default:
            navId = 'nav-dashboard';
            break;
    }

    const activeLink = document.getElementById(navId);
    if (activeLink) {
        // Xóa class 'active' khỏi tất cả các link trước
        document.querySelectorAll('.sidebar-nav a.active').forEach(link => link.classList.remove('active'));
        // Thêm class 'active' vào link đúng
        activeLink.classList.add('active');
    }
}