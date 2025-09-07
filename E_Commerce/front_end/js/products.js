/* ========================================================= */
/*       NỘI DUNG MỚI VÀ HOÀN CHỈNH CHO PRODUCTS.JS          */
/* ========================================================= */

document.addEventListener('DOMContentLoaded', function() {
    loadProductsPageData();
});

async function loadProductsPageData() {
    const params = new URLSearchParams(window.location.search);
    const categoryId = params.get('category');
    const filter = params.get('filter');
    const page = parseInt(params.get('page') || '1') - 1; // API tính page từ 0, người dùng thấy từ 1
    const size = 12; // Số sản phẩm mỗi trang

    const titleEl = document.getElementById('category-title');
    const gridEl = document.getElementById('product-list-grid');

    let url = '';
    let pageTitle = '';
    let isCategoryPage = false;

    // 1. Xác định API cần gọi và tiêu đề trang dựa trên tham số URL
    if (categoryId) {
        url = `${API_BASE_URL}/api/categories/${categoryId}/products?page=${page}&size=${size}`;
        isCategoryPage = true;
    } else if (filter === 'promotion') {
        url = `${API_BASE_URL}/api/products-page/promotional?page=${page}&size=${size}`;
        pageTitle = 'Sản phẩm Khuyến mãi';
    } else {
        url = `${API_BASE_URL}/api/products-page/all?page=${page}&size=${size}`;
        pageTitle = 'Tất cả sản phẩm';
    }
    
    // 2. Cập nhật giao diện với trạng thái "Đang tải"
    titleEl.textContent = pageTitle || 'Đang tải...';
    document.title = pageTitle || 'Đang tải sản phẩm...';
    gridEl.innerHTML = '<p style="text-align: center; grid-column: 1 / -1;">Đang tải danh sách sản phẩm...</p>';

    try {
        const response = await fetch(url);
        if (!response.ok) throw new Error('Không thể tải dữ liệu sản phẩm.');
        
        const data = await response.json();
        
        let pageData;
        
        // 3. Xử lý các cấu trúc JSON trả về khác nhau
        if (isCategoryPage) {
            // Cập nhật tiêu đề từ thông tin category trong response
            titleEl.textContent = data.category.name;
            document.title = data.category.name;
            pageData = data.productPage; // Lấy đối tượng Page từ response
        } else {
            pageData = data; // API /all và /promotional trả về trực tiếp đối tượng Page
        }

        const products = pageData.content;

        // 4. Render sản phẩm ra lưới
        gridEl.innerHTML = '';
        if (products.length === 0) {
            gridEl.innerHTML = '<p style="text-align: center; grid-column: 1 / -1;">Không có sản phẩm nào phù hợp.</p>';
        } else {
            products.forEach(product => {
                gridEl.innerHTML += createProductCardHTML(product);
            });
        }
        
        // 5. Render các nút phân trang
        renderPagination(pageData);

    } catch (error) {
        titleEl.textContent = "Đã xảy ra lỗi";
        gridEl.innerHTML = `<p class="message error" style="text-align: center; grid-column: 1 / -1;">${error.message}</p>`;
    }
}

function renderPagination(pageData) {
    const paginationContainer = document.getElementById('pagination-container');
    if (!paginationContainer) return;
    
    paginationContainer.innerHTML = '';

    const totalPages = pageData.totalPages;
    const currentPage = pageData.number + 1;

    if (totalPages <= 1) return;

    // Nút "Trước"
    let prevDisabled = currentPage === 1 ? 'disabled' : '';
    paginationContainer.innerHTML += `
        <li class="page-item ${prevDisabled}">
            <a class="page-link" href="${prevDisabled ? '#' : buildPageUrl(currentPage - 1)}" aria-label="Previous">
                <span aria-hidden="true">&laquo;</span>
            </a>
        </li>
    `;

    // Các nút số trang
    for (let i = 1; i <= totalPages; i++) {
        let activeClass = i === currentPage ? 'active' : '';
        paginationContainer.innerHTML += `
            <li class="page-item ${activeClass}">
                <a class="page-link" href="${buildPageUrl(i)}">${i}</a>
            </li>
        `;
    }

    // Nút "Sau"
    let nextDisabled = currentPage === totalPages ? 'disabled' : '';
    paginationContainer.innerHTML += `
        <li class="page-item ${nextDisabled}">
            <a class="page-link" href="${nextDisabled ? '#' : buildPageUrl(currentPage + 1)}" aria-label="Next">
                <span aria-hidden="true">&raquo;</span>
            </a>
        </li>
    `;
}

function buildPageUrl(pageNumber) {
    const params = new URLSearchParams(window.location.search);
    params.set('page', pageNumber);
    return `products.html?${params.toString()}`;
}

function createProductCardHTML(product) {
    let priceDisplayHTML = `<span class="new-price">${formatCurrency(product.salePrice)}</span>`;
    let badgeHTML = '';

    if (product.salePrice < product.originalPrice) {
        priceDisplayHTML += `<span class="old-price">${formatCurrency(product.originalPrice)}</span>`;
        if(product.discountPercentage){
            badgeHTML = `<div class="badge">-${product.discountPercentage}%</div>`;
        }
    }
    
    let ratingHTML = '';
    if (product.reviewCount > 0) {
        const fullStars = '★'.repeat(Math.round(product.averageRating));
        const emptyStars = '☆'.repeat(5 - Math.round(product.averageRating));
        ratingHTML = `
            <div class="rating">
                <span class="stars">${fullStars}${emptyStars}</span>
                <span class="review-count">(${product.reviewCount})</span>
            </div>
        `;
    } else {
        ratingHTML = `<div class="rating no-reviews">Chưa có đánh giá</div>`;
    }

    return `
        <div class="product-card" data-product-id="${product.id}">
            <div class="image-container">
                ${badgeHTML}
                <a href="product-detail.html?id=${product.id}">
                    <img src="${product.imageUrl}" alt="${product.name}" class="product-image">
                </a>
            </div>
            <div class="product-card-content">
                <h3><a href="product-detail.html?id=${product.id}">${product.name}</a></h3>
                ${ratingHTML}
                <div class="price">${priceDisplayHTML}</div>
            </div>
        </div>
    `;
}

function formatCurrency(number) {
    if (typeof number !== 'number') return '';
    return new Intl.NumberFormat('vi-VN', { style: 'currency', currency: 'VND' }).format(number);
}