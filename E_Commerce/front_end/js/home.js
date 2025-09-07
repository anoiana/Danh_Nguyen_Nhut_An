// =========================================================
//            NỘI DUNG MỚI VÀ HOÀN CHỈNH CHO HOME.JS
// =========================================================

document.addEventListener('DOMContentLoaded', function() {
    loadHomePageData();
});

// TRONG FILE: js/home.js

async function loadHomePageData() {
    const sectionsContainer = document.getElementById('home-product-sections');
    
    try {
        const response = await fetch(`${API_BASE_URL}/api/home/data`);
        if (!response.ok) throw new Error('Không thể tải dữ liệu trang chủ.');
        
        const data = await response.json();
        sectionsContainer.innerHTML = ''; // Xóa thông báo tải

        // 1. Render khu vực sản phẩm khuyến mãi
        if (data.promotionalProducts && data.promotionalProducts.length > 0) {
            sectionsContainer.appendChild(createProductSectionHTML('Sản phẩm Khuyến mãi', data.promotionalProducts));
        }

        // 2. Render khu vực sản phẩm mới
        if (data.newProducts && data.newProducts.length > 0) {
            sectionsContainer.appendChild(createProductSectionHTML('Sản phẩm Mới', data.newProducts));
        }

        // 3. **THAY ĐỔI Ở ĐÂY:** Lặp qua danh sách `categorySections`
        if (data.categorySections && data.categorySections.length > 0) {
            data.categorySections.forEach(categorySection => {
                sectionsContainer.appendChild(
                    createProductSectionHTML(categorySection.categoryName, categorySection.products)
                );
            });
        }
        
        // Khởi tạo tất cả các slider sau khi đã render xong
        initSliders();

    } catch (error) {
        sectionsContainer.innerHTML = `<p class="message error">${error.message}</p>`;
    }
}

/**
 * Tạo một khu vực (section) hoàn chỉnh với cấu trúc slider của Swiper.
 */
function createProductSectionHTML(title, products) {
    const section = document.createElement('section');
    section.className = 'product-section';

    const titleEl = document.createElement('h2');
    titleEl.className = 'section-title';
    titleEl.textContent = title;

    // Map qua mảng sản phẩm để tạo các slide
    const slidesHTML = products.map(product => `
        <div class="swiper-slide">
            ${createProductCardHTML(product)}
        </div>
    `).join('');

    // Tạo cấu trúc HTML mà Swiper yêu cầu
    section.innerHTML = `
        <h2 class="section-title">${title}</h2>
        <div class="product-slider-container">
            <!-- Swiper -->
            <div class="swiper product-slider">
                <div class="swiper-wrapper">
                    ${slidesHTML}
                </div>
            </div>
            <!-- Nút điều hướng -->
            <div class="swiper-button-next"></div>
            <div class="swiper-button-prev"></div>
        </div>
    `;
    
    return section;
}

/**
 * Khởi tạo tất cả các slider trên trang bằng SwiperJS.
 */
function initSliders() {
    const sliders = document.querySelectorAll('.product-slider');
    sliders.forEach(sliderElement => {
        new Swiper(sliderElement, {
            // Cấu hình của Swiper
            slidesPerView: 2, // Hiển thị 2 sản phẩm trên mobile
            spaceBetween: 20, // Khoảng cách giữa các sản phẩm
            
            // Các nút điều hướng
            navigation: {
                nextEl: sliderElement.parentElement.querySelector('.swiper-button-next'),
                prevEl: sliderElement.parentElement.querySelector('.swiper-button-prev'),
            },

            // Responsive breakpoints
            breakpoints: {
                // Khi chiều rộng màn hình >= 768px
                768: {
                  slidesPerView: 3,
                  spaceBetween: 25,
                },
                // Khi chiều rộng màn hình >= 1024px
                1024: {
                  slidesPerView: 4,
                  spaceBetween: 30,
                },
            },
        });
    });
}


/**
 * Tạo chuỗi HTML cho một thẻ sản phẩm (giữ nguyên).
 */
function createProductCardHTML(product) {
    let priceDisplayHTML = `<span class="new-price">${formatCurrency(product.salePrice)}</span>`;
    let badgeHTML = '';

    if (product.salePrice < product.originalPrice) {
        priceDisplayHTML += `<span class="old-price">${formatCurrency(product.originalPrice)}</span>`;
        badgeHTML = `<div class="badge">-${product.discountPercentage}%</div>`;
    }

    // --- PHẦN LOGIC MỚI ĐỂ HIỂN THỊ SAO ---
    let ratingHTML = '';
    if (product.reviewCount > 0) {
        // Tạo chuỗi các ngôi sao
        const fullStars = '★'.repeat(Math.round(product.averageRating));
        const emptyStars = '☆'.repeat(5 - Math.round(product.averageRating));
        
        ratingHTML = `
            <div class="rating">
                <span class="stars">${fullStars}${emptyStars}</span>
                <span class="review-count">(${product.reviewCount})</span>
            </div>
        `;
    } else {
        // Hiển thị thông báo nếu chưa có đánh giá
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
                ${ratingHTML} <!-- Thêm phần đánh giá vào đây -->
                <div class="price">${priceDisplayHTML}</div>
            </div>
        </div>
    `;
}

function formatCurrency(number) {
    if (typeof number !== 'number') return '';
    return new Intl.NumberFormat('vi-VN', { style: 'currency', currency: 'VND' }).format(number);
}