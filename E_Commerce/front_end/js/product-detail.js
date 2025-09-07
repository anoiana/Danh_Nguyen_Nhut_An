let currentProductData = null;
let currentProductId = null;
let allReviews = [];

let relatedProductsSwiper;
let relatedCurrentPage = 0;
let relatedTotalPages = 1;
let isRelatedLoading = false;

function initProductDetailPage() {
    const params = new URLSearchParams(window.location.search);
    currentProductId = params.get('id');
    
    if (!currentProductId) {
        const container = document.getElementById('product-detail-container');
        if (container) container.innerHTML = '<p class="message error">Lỗi: Không tìm thấy ID sản phẩm trong URL.</p>';
        const reviewsSection = document.querySelector('.reviews-section');
        if (reviewsSection) reviewsSection.style.display = 'none';
        return;
    }
    
    relatedProductsSwiper = null;
    relatedCurrentPage = 0;
    relatedTotalPages = 1;
    isRelatedLoading = false;

    Promise.all([
        fetchProductDetails(currentProductId),
        loadReviewsAndStats(currentProductId),
        loadRelatedProducts(currentProductId, 0)
    ]);
    
    checkUserReviewAbility(currentProductId);
}

async function fetchProductDetails(id) {
    const container = document.getElementById('product-detail-container');
    const loadingMessage = document.getElementById('loading-message');
    try {
        const response = await fetch(`${API_BASE_URL}/api/products/${id}`);
        if (!response.ok) throw new Error(`Sản phẩm không tồn tại (Status: ${response.status})`);
        
        currentProductData = await response.json();
        renderProductDetails(currentProductData);
        if (loadingMessage) loadingMessage.style.display = 'none';
    } catch (error) {
        if(container) container.innerHTML = `<p class="message error">${error.message}</p>`;
        if (loadingMessage) loadingMessage.style.display = 'none';
    }
}

function renderProductDetails(product) {
    const container = document.getElementById('product-detail-container');
    if (!container) return;
    document.title = product.name;

    const primaryImageUrl = (product.imageUrls && product.imageUrls.length > 0) 
                            ? product.imageUrls[0] 
                            : 'img/placeholder.png'; 

    container.innerHTML = `
        <div class="product-layout">
            <div class="product-images">
                <div class="main-image-container">
                    <img src="${primaryImageUrl}" alt="${product.name}" class="main-image" id="main-product-image">
                </div>
                <div class="thumbnail-gallery" id="thumbnail-gallery"></div>
            </div>
            <div class="product-info">
                <h1>${product.name}</h1>
                <span class="product-sku">SKU: SP00${product.id}</span>
                <div class="price-section" id="price-section-container"></div>
                <div class="options-group" id="variants-section" style="display: none;">
                    <span class="option-label">Màu Sắc / Lựa chọn</span>
                    <div class="variant-options" id="variant-options-container"></div>
                </div>
                <div class="options-group" id="sizes-section" style="display: none;">
                    <span class="option-label">Size</span>
                    <div class="size-options" id="size-options-container"></div>
                </div>
                <div class="options-group quantity-selector">
                    <span class="option-label">Số Lượng</span>
                    <div>
                        <button id="decrease-qty">-</button>
                        <input type="text" value="1" id="quantity-input" readonly>
                        <button id="increase-qty">+</button>
                    </div>
                </div>
                <div class="action-buttons">
                    <button class="btn btn-secondary btn-add-to-cart">Thêm Vào Giỏ Hàng</button>
                    <button class="btn btn-primary btn-buy-now">Mua Ngay</button>
                </div>
            </div>
        </div>
        <div class="product-description" id="product-long-description-container">
            <h3>Mô tả sản phẩm</h3>
            <p id="product-long-description"></p>
        </div>
    `;

    initializeActionButtons();
    renderThumbnails(product.imageUrls); 
    renderVariants(product.variants);

    const variantsArray = [...(product.variants || [])];
    if (variantsArray.length > 0) {
        selectVariant(variantsArray[0]);
    } else {
        updatePriceDisplay(null);
    }
    
    const descriptionContainer = document.getElementById('product-long-description');
    if (descriptionContainer && product.description) {
        descriptionContainer.innerHTML = product.description.replace(/\n/g, '<br>');
    }
}

function renderThumbnails(imageUrls) {
    const gallery = document.getElementById('thumbnail-gallery');
    const mainImage = document.getElementById('main-product-image');
    if (!gallery || !mainImage || !imageUrls || imageUrls.length === 0) {
        if (gallery) gallery.style.display = 'none';
        return;
    }
    gallery.style.display = 'grid';
    gallery.innerHTML = '';
    imageUrls.forEach((url, index) => {
        const thumbWrapper = document.createElement('div');
        thumbWrapper.className = 'thumbnail-item';
        thumbWrapper.innerHTML = `<img src="${url}" alt="Thumbnail ${index + 1}">`;
        thumbWrapper.addEventListener('click', () => {
            mainImage.src = url;
            document.querySelectorAll('.thumbnail-item.active').forEach(item => item.classList.remove('active'));
            thumbWrapper.classList.add('active');
            document.querySelectorAll('.variant-item.active').forEach(item => item.classList.remove('active'));
        });
        gallery.appendChild(thumbWrapper);
    });
    if (gallery.firstChild) {
        gallery.firstChild.classList.add('active');
    }
}

function renderVariants(variants) {
    const variantContainer = document.getElementById('variant-options-container');
    const variantsSection = document.getElementById('variants-section');
    if (!variantContainer || !variantsSection) return;
    const variantsArray = [...(variants || [])];
    if (variantsArray.length === 0) {
        variantsSection.style.display = 'none';
        return;
    }
    variantsSection.style.display = 'flex';
    variantContainer.innerHTML = '';
    variantsArray.forEach(variant => {
        const variantEl = document.createElement('div');
        variantEl.className = 'variant-item';
        variantEl.dataset.variantId = variant.id;
        variantEl.innerHTML = `
            <img src="${variant.imageUrl}" class="variant-thumbnail" alt="${variant.name}">
            <span>${variant.name}</span>
        `;
        variantEl.addEventListener('click', () => selectVariant(variant));
        variantContainer.appendChild(variantEl);
    });
}

function selectVariant(selectedVariant) {
    document.getElementById('main-product-image').src = selectedVariant.imageUrl;
    document.querySelectorAll('.thumbnail-item.active').forEach(thumb => thumb.classList.remove('active'));
    document.querySelectorAll('.variant-item').forEach(item => {
        item.classList.toggle('active', item.dataset.variantId == selectedVariant.id);
    });
    renderSizes(selectedVariant.sizes);
    updatePriceDisplay(selectedVariant);
    const firstAvailableSize = [...(selectedVariant.sizes || [])].find(s => s.quantityInStock > 0);
    if (firstAvailableSize) {
        setTimeout(() => document.querySelector(`.size-item[data-size-id='${firstAvailableSize.id}']`)?.click(), 0);
    } else {
        document.querySelectorAll('.size-item.active').forEach(item => item.classList.remove('active'));
    }
}

function renderSizes(sizes) {
    const sizeContainer = document.getElementById('size-options-container');
    const sizesSection = document.getElementById('sizes-section');
    if (!sizeContainer || !sizesSection) return;
    sizeContainer.innerHTML = '';
    const sizesArray = [...(sizes || [])];
    if (sizesArray.length === 0) {
        sizesSection.style.display = 'none';
        return;
    }
    sizesSection.style.display = 'flex';
    sizesArray.forEach(size => {
        const sizeEl = document.createElement('button');
        sizeEl.className = 'size-item';
        sizeEl.textContent = size.sizeName;
        sizeEl.dataset.sizeId = size.id;
        if (size.quantityInStock === 0) {
            sizeEl.disabled = true;
        } else {
            sizeEl.addEventListener('click', () => {
                document.querySelectorAll('.size-item.active').forEach(item => item.classList.remove('active'));
                sizeEl.classList.add('active');
            });
        }
        sizeContainer.appendChild(sizeEl);
    });
}

function initializeActionButtons() {
    document.querySelector('.btn-add-to-cart')?.addEventListener('click', () => addToCart(false));
    document.querySelector('.btn-buy-now')?.addEventListener('click', () => addToCart(true));
    document.getElementById('increase-qty')?.addEventListener('click', () => updateQuantity(1));
    document.getElementById('decrease-qty')?.addEventListener('click', () => updateQuantity(-1));
}

function updatePriceDisplay(variant) {
    const priceContainer = document.getElementById('price-section-container');
    if (!priceContainer || !currentProductData) return;
    let basePrice = (variant && variant.variantPrice > 0) ? variant.variantPrice : currentProductData.originalPrice;
    let finalPrice = basePrice;
    let originalPriceHTML = '';
    let discountBadgeHTML = '';
    if (currentProductData.discountPercentage) {
        finalPrice = basePrice * (1 - currentProductData.discountPercentage / 100);
        originalPriceHTML = `<span class="old-price">${formatCurrency(basePrice)}</span>`;
        discountBadgeHTML = `<span class="discount-badge">-${currentProductData.discountPercentage}%</span>`;
    }
    priceContainer.innerHTML = `
        ${originalPriceHTML}
        <span class="new-price">${formatCurrency(finalPrice)}</span>
        ${discountBadgeHTML}
    `;
    priceContainer.dataset.finalPrice = finalPrice;
}

function updateQuantity(amount) {
    const qtyInput = document.getElementById('quantity-input');
    if (!qtyInput) return;
    let currentValue = parseInt(qtyInput.value);
    currentValue += amount;
    if (currentValue < 1) currentValue = 1;
    qtyInput.value = currentValue;
}

async function addToCart(redirectToCart) {
    const finalPrice = parseFloat(document.getElementById('price-section-container').dataset.finalPrice);
    const token = localStorage.getItem('jwtToken');
    if (!token) {
        alert('Vui lòng đăng nhập để thực hiện thao tác này.');
        window.location.href = 'login.html';
        return;
    }
    const selectedVariantEl = document.querySelector('.variant-item.active');
    const selectedSizeEl = document.querySelector('.size-item.active');
    const quantity = parseInt(document.getElementById('quantity-input').value);
    if (!selectedVariantEl || !selectedSizeEl) {
        alert('Vui lòng chọn đầy đủ màu sắc và size!');
        return;
    }
    const itemData = {
        productId: currentProductData.id,
        variantId: parseInt(selectedVariantEl.dataset.variantId),
        sizeId: parseInt(selectedSizeEl.dataset.sizeId),
        quantity: quantity,
        price: finalPrice
    };
    try {
        const response = await fetch(`${API_BASE_URL}/api/cart/items`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json', 'Authorization': `Bearer ${token}` },
            body: JSON.stringify(itemData)
        });
        if (response.ok) {
            if (typeof updateCartIconCount === 'function') updateCartIconCount();
            if (redirectToCart) {
                window.location.href = 'cart.html';
            } else {
                alert(`Đã thêm thành công vào giỏ hàng!`);
            }
        } else {
            const error = await response.text();
            alert(`Lỗi khi thêm vào giỏ: ${error}`);
        }
    } catch (error) {
        console.error('Lỗi kết nối khi thêm vào giỏ hàng:', error);
        alert('Lỗi kết nối đến server.');
    }
}

async function loadReviewsAndStats(productId) {
    await loadReviewStats(productId);
    await loadReviews(productId);
}

async function loadReviewStats(productId) {
    try {
        const response = await fetch(`${API_BASE_URL}/api/products/${productId}/reviews/stats`);
        if (!response.ok) return;
        const stats = await response.json();
        const avgRatingEl = document.getElementById('avg-rating');
        const avgStarsEl = document.getElementById('avg-stars');
        if (avgRatingEl) avgRatingEl.textContent = stats.averageRating.toFixed(1);
        if (avgStarsEl) {
            avgStarsEl.innerHTML = '★'.repeat(Math.round(stats.averageRating)) + '☆'.repeat(5 - Math.round(stats.averageRating));
        }
        for (const rating in stats.ratingCounts) {
            const countEl = document.querySelector(`.filter-btn[data-filter="${rating}"] [data-count]`);
            if (countEl) {
                countEl.textContent = stats.ratingCounts[rating];
            }
        }
    } catch (error) {
        console.error("Lỗi khi tải thống kê đánh giá:", error);
    }
}

async function loadReviews(productId) {
    const reviewsList = document.getElementById('reviews-list');
    if (!reviewsList) return;
    try {
        const response = await fetch(`${API_BASE_URL}/api/products/${productId}/reviews`);
        if (!response.ok) throw new Error("Không thể tải đánh giá.");
        allReviews = await response.json();
        renderReviews(allReviews);
        initializeReviewFilters();
    } catch (error) {
        reviewsList.innerHTML = `<p class="message error">Lỗi khi tải đánh giá: ${error.message}</p>`;
    }
}

function initializeReviewFilters() {
    const filterButtons = document.querySelectorAll('.filter-btn');
    filterButtons.forEach(btn => {
        btn.addEventListener('click', () => {
            filterButtons.forEach(b => b.classList.remove('active'));
            btn.classList.add('active');
            const filter = btn.dataset.filter;
            let filteredReviews = (filter === 'all') ? allReviews : allReviews.filter(r => r.rating == filter);
            renderReviews(filteredReviews);
        });
    });
}

function renderReviews(reviews) {
    const reviewsList = document.getElementById('reviews-list');
    if (!reviewsList) return;
    reviewsList.innerHTML = '';
    if (reviews.length === 0) {
        reviewsList.innerHTML = '<p>Chưa có đánh giá nào cho sản phẩm này.</p>';
        return;
    }
    const currentUser = JSON.parse(localStorage.getItem('user'));
    reviews.forEach(review => {
        let avatarHTML = `<div class="default-avatar-icon"><svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="currentColor"><path d="M12 12c2.21 0 4-1.79 4-4s-1.79-4-4-4-4 1.79-4 4 1.79 4 4 4zm0 2c-2.67 0-8 1.34-8 4v2h16v-2c0-2.66-5.33-4-8-4z"/></svg></div>`;
        if (review.avatarUrl) {
            avatarHTML = `<img src="${review.avatarUrl}" alt="${review.username}" onerror="this.style.display='none'; this.nextElementSibling.style.display='flex';">${avatarHTML.replace('class="default-avatar-icon"', 'class="default-avatar-icon" style="display:none;"')}`;
        }
        let actionsHTML = '';
        if (currentUser && currentUser.id === review.userId) {
            actionsHTML = `<div class="review-actions">
                <a href="#" class="edit-review-btn" data-review-id="${review.id}" data-rating="${review.rating}" data-comment='${JSON.stringify(review.comment || '')}'>Sửa</a>
                <a href="#" class="delete-review-btn" data-review-id="${review.id}">Xóa</a>
            </div>`;
        }
        const reviewStars = '★'.repeat(review.rating) + '☆'.repeat(5 - review.rating);
        const formattedDate = new Date(review.reviewDate).toLocaleDateString('vi-VN', { day: '2-digit', month: '2-digit', year: 'numeric' });
        reviewsList.innerHTML += `
            <div class="review-item" id="review-${review.id}">
                <div class="review-avatar">${avatarHTML}</div>
                <div class="review-content">
                    <div class="review-header">
                        <span class="review-author">${review.username}</span>
                        <span class="review-date">${formattedDate}</span>
                    </div>
                    <div class="review-stars">${reviewStars}</div>
                    <p class="review-comment">${review.comment || ''}</p>
                    ${actionsHTML}
                </div>
            </div>`;
    });
    initializeReviewActionButtons();
}

async function checkUserReviewAbility(productId) {
    const token = localStorage.getItem('jwtToken');
    const statusMessageEl = document.getElementById('review-status-message');
    const formContainer = document.getElementById('review-form-container');
    const reviewForm = document.getElementById('review-form');
    if (!statusMessageEl || !formContainer || !reviewForm) return;
    reviewForm.addEventListener('submit', handleReviewSubmit);
    if (!token) {
        statusMessageEl.innerHTML = '<p>Vui lòng <a href="login.html">đăng nhập</a> để để lại đánh giá.</p>';
        statusMessageEl.style.display = 'block';
        formContainer.style.display = 'none';
        return;
    }
    try {
        const response = await fetch(`${API_BASE_URL}/api/products/${productId}/reviews/check`, { headers: { 'Authorization': `Bearer ${token}` } });
        if (!response.ok) {
            statusMessageEl.innerHTML = '<p>Đã xảy ra lỗi khi kiểm tra quyền đánh giá. Vui lòng thử lại.</p>';
            statusMessageEl.style.display = 'block';
            formContainer.style.display = 'none';
            return;
        }
        const data = await response.json();
        if (data.canReview) {
            statusMessageEl.style.display = 'none';
            formContainer.style.display = 'block';
        } else {
            statusMessageEl.innerHTML = '<p>Bạn đã đánh giá sản phẩm này rồi. Bạn có thể sửa hoặc xóa đánh giá của mình bên dưới.</p>';
            statusMessageEl.style.display = 'block';
            formContainer.style.display = 'none';
        }
    } catch (error) {
        console.error("Lỗi khi kiểm tra quyền đánh giá:", error);
        statusMessageEl.innerHTML = '<p>Lỗi kết nối khi kiểm tra quyền đánh giá.</p>';
        statusMessageEl.style.display = 'block';
        formContainer.style.display = 'none';
    }
}

function initializeReviewActionButtons() {
    document.querySelectorAll('.edit-review-btn').forEach(btn => btn.addEventListener('click', handleEditReviewClick));
    document.querySelectorAll('.delete-review-btn').forEach(btn => btn.addEventListener('click', handleDeleteReviewClick));
}

function handleEditReviewClick(event) {
    event.preventDefault();
    const btn = event.target;
    const reviewId = btn.dataset.reviewId;
    const rating = btn.dataset.rating;
    const comment = JSON.parse(btn.dataset.comment);
    document.getElementById('review-form-title').textContent = 'Chỉnh sửa đánh giá của bạn';
    document.getElementById('review-id').value = reviewId;
    document.getElementById('review-comment').value = comment;
    document.querySelector(`.star-rating input[type="radio"][value="${rating}"]`).checked = true;
    document.getElementById('review-status-message').style.display = 'none';
    document.getElementById('review-form-container').style.display = 'block';
    const cancelBtn = document.getElementById('cancel-edit-review-btn');
    if (cancelBtn) cancelBtn.style.display = 'inline-block';
    document.getElementById('review-form-container').scrollIntoView({ behavior: 'smooth' });
    if (cancelBtn) {
        cancelBtn.onclick = () => {
            document.getElementById('review-form-title').textContent = 'Viết đánh giá của bạn';
            document.getElementById('review-form').reset();
            document.getElementById('review-id').value = '';
            cancelBtn.style.display = 'none';
            checkUserReviewAbility(currentProductId);
        };
    }
}

async function handleDeleteReviewClick(event) {
    event.preventDefault();
    const reviewId = event.target.dataset.reviewId;
    if (confirm('Bạn có chắc muốn xóa đánh giá này?')) {
        const token = localStorage.getItem('jwtToken');
        try {
            const response = await fetch(`${API_BASE_URL}/api/reviews/${reviewId}`, {
                method: 'DELETE',
                headers: { 'Authorization': `Bearer ${token}` }
            });
            if (!response.ok) throw new Error('Không thể xóa đánh giá.');
            alert('Xóa đánh giá thành công!');
            loadReviewsAndStats(currentProductId);
            checkUserReviewAbility(currentProductId);
        } catch (error) {
            alert(`Lỗi: ${error.message}`);
        }
    }
}

async function handleReviewSubmit(event) {
    event.preventDefault();
    const token = localStorage.getItem('jwtToken');
    const reviewId = document.getElementById('review-id').value;
    const ratingEl = document.querySelector('.star-rating input[type="radio"]:checked');
    if (!ratingEl) {
        alert('Vui lòng chọn số sao đánh giá.');
        return;
    }
    const reviewData = {
        rating: parseInt(ratingEl.value),
        comment: document.getElementById('review-comment').value
    };
    const isEditing = !!reviewId;
    const method = isEditing ? 'PUT' : 'POST';
    const url = isEditing ? `${API_BASE_URL}/api/reviews/${reviewId}` : `${API_BASE_URL}/api/products/${currentProductId}/reviews`;
    try {
        const response = await fetch(url, {
            method: method,
            headers: { 'Content-Type': 'application/json', 'Authorization': `Bearer ${token}` },
            body: JSON.stringify(reviewData)
        });
        if (!response.ok) throw new Error(await response.text());
        alert(`Đã ${isEditing ? 'cập nhật' : 'gửi'} đánh giá thành công!`);
        document.getElementById('review-form').reset();
        document.getElementById('review-id').value = '';
        const cancelBtn = document.getElementById('cancel-edit-review-btn');
        if (cancelBtn) cancelBtn.style.display = 'none';
        document.getElementById('review-form-title').textContent = 'Viết đánh giá của bạn';
        loadReviewsAndStats(currentProductId);
        checkUserReviewAbility(currentProductId);
    } catch (error) {
        alert(`Lỗi: ${error.message}`);
    }
}

function formatCurrency(number) {
    if (typeof number !== 'number') return '';
    return new Intl.NumberFormat('vi-VN', { style: 'currency', currency: 'VND' }).format(number);
}

async function loadRelatedProducts(productId, pageToLoad) {
    if (isRelatedLoading || (pageToLoad > 0 && pageToLoad >= relatedTotalPages)) {
        return;
    }
    isRelatedLoading = true;
    const section = document.getElementById('related-products-section');
    const wrapper = document.getElementById('related-products-grid');
    if (!section || !wrapper) {
        isRelatedLoading = false;
        return;
    }
    try {
        const response = await fetch(`${API_BASE_URL}/api/products-page/${productId}/related?page=${pageToLoad}&size=5`);
        if (!response.ok) throw new Error('Không thể tải thêm sản phẩm.');
        const pageData = await response.json();
        const newProducts = pageData.content;
        relatedTotalPages = pageData.totalPages;
        relatedCurrentPage = pageData.number;
        if (newProducts.length > 0) {
            const slidesHTML = newProducts.map(product => `<div class="swiper-slide">${createProductCardHTML(product)}</div>`).join('');
            wrapper.insertAdjacentHTML('beforeend', slidesHTML);
            section.style.display = 'block';
            if (!relatedProductsSwiper) {
                initRelatedProductsSlider(productId);
            } else {
                relatedProductsSwiper.update();
            }
        } else if (pageToLoad === 0) {
            section.style.display = 'none';
        }
    } catch (error) {
        console.error("Lỗi khi tải sản phẩm tương tự:", error);
    } finally {
        isRelatedLoading = false;
    }
}

function initRelatedProductsSlider(productId) {
    const sliderContainer = document.querySelector('#related-products-section .product-slider-container');
    if (!sliderContainer) return;
    const swiperElement = sliderContainer.querySelector('.related-products-slider');
    if (!swiperElement) return;
    if (swiperElement.swiper) {
        swiperElement.swiper.destroy(true, true);
    }
    relatedProductsSwiper = new Swiper(swiperElement, {
        slidesPerView: 2,
        spaceBetween: 20,
        navigation: {
            nextEl: sliderContainer.querySelector('.swiper-button-next'),
            prevEl: sliderContainer.querySelector('.swiper-button-prev'),
            disabledClass: 'swiper-button-disabled-custom' 
        },
        breakpoints: {
            768: { slidesPerView: 3, spaceBetween: 25 },
            1024: { slidesPerView: 4, spaceBetween: 30 },
        },
        on: {
            reachEnd: function () {
                loadRelatedProducts(productId, relatedCurrentPage + 1);
            }
        }
    });
}

function createProductCardHTML(product) {
    let priceDisplayHTML = `<span class="new-price">${formatCurrency(product.salePrice)}</span>`;
    let badgeHTML = '';
    if (product.salePrice < product.originalPrice) {
        priceDisplayHTML += `<span class="old-price">${formatCurrency(product.originalPrice)}</span>`;
        if (product.discountPercentage) {
            badgeHTML = `<div class="badge">-${product.discountPercentage}%</div>`;
        }
    }
    let ratingHTML = '';
    if (product.reviewCount > 0) {
        const fullStars = '★'.repeat(Math.round(product.averageRating));
        const emptyStars = '☆'.repeat(5 - Math.round(product.averageRating));
        ratingHTML = `<div class="rating"><span class="stars">${fullStars}${emptyStars}</span><span class="review-count">(${product.reviewCount})</span></div>`;
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