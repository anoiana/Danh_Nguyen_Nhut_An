let variantIndex = 0;
let newMainImageFiles = [];

document.addEventListener('DOMContentLoaded', initializeForm);

function initializeForm() {
    const urlParams = new URLSearchParams(window.location.search);
    const productId = urlParams.get('id');

    initializeSharedEventListeners();

    if (productId) {
        setupEditMode(productId);
    } else {
        setupAddMode();
    }
}

async function setupAddMode() {
    document.getElementById('form-title').textContent = 'Tạo sản phẩm mới';
    document.querySelector('#submitProductBtn .btn-text').textContent = 'Lưu Sản Phẩm';
    document.getElementById('productForm').addEventListener('submit', handleAddProductSubmit);
    await loadCategories();
}

async function handleAddProductSubmit(event) {
    event.preventDefault();
    
    const submitBtn = document.getElementById('submitProductBtn');
    enableSubmitButton(submitBtn, 'Đang lưu...', true);

    const formData = new FormData();
    const productData = buildProductData();
    
    if (newMainImageFiles.length === 0) {
        alert('Vui lòng chọn ít nhất một ảnh chính cho sản phẩm.');
        enableSubmitButton(submitBtn, 'Lưu Sản Phẩm');
        return;
    }
    newMainImageFiles.forEach(file => {
        formData.append('mainImages', file);
    });

    document.querySelectorAll('.variant-group').forEach(variantEl => {
        const variantImageInput = variantEl.querySelector('.variantImage');
        if (variantImageInput.files[0]) {
            formData.append('variantImages', variantImageInput.files[0]);
        }
    });

    formData.append('productData', JSON.stringify(productData));

    try {
        const token = localStorage.getItem('jwtToken');
        const response = await fetch(`${API_BASE_URL}/api/admin/products`, { 
            method: 'POST', 
            headers: { 'Authorization': `Bearer ${token}` }, 
            body: formData
        });

        if (response.ok) {
            alert('Thêm sản phẩm thành công!');
            window.location.href = 'products.html';
        } else {
            const errorText = await response.text();
            alert('Lỗi: ' + errorText);
            enableSubmitButton(submitBtn, 'Lưu Sản Phẩm');
        }
    } catch (e) {
        alert('Lỗi kết nối: ' + e.message);
        enableSubmitButton(submitBtn, 'Lưu Sản Phẩm');
    }
}

async function setupEditMode(productId) {
    document.querySelector('#submitProductBtn .btn-text').textContent = 'Cập Nhật Sản Phẩm';
    document.getElementById('productForm').addEventListener('submit', handleUpdateProductSubmit);
    await loadCategories();
    await loadProductForEditing(productId);
}

async function loadProductForEditing(productId) {
    const token = localStorage.getItem('jwtToken');
    try {
        const response = await fetch(`${API_BASE_URL}/api/admin/products/${productId}`, { headers: { 'Authorization': `Bearer ${token}` } });
        if (!response.ok) throw new Error('Không thể lấy thông tin sản phẩm.');
        const product = await response.json();
        populateFormForEdit(product);
    } catch (error) {
        alert(error.message);
        window.location.href = 'products.html';
    }
}

function populateFormForEdit(product) {
    document.getElementById('form-title').textContent = `Chỉnh sửa sản phẩm: ${product.name}`;
    document.getElementById('productId').value = product.id;
    document.getElementById('productName').value = product.name;
    document.getElementById('productDescription').value = product.description;
    document.getElementById('productCategorySelect').value = product.category.id;
    document.getElementById('productSalePrice').value = product.salePrice;
    document.getElementById('productImportPrice').value = product.importPrice;
    
    if (product.imageUrls && product.imageUrls.length > 0) {
        product.imageUrls.forEach(url => {
            addMainImagePreview(url);
        });
    }

    document.getElementById('variantsContainer').innerHTML = '';
    variantIndex = 0;
    product.variants.forEach(variant => {
        addVariantField(variant);
    });
}

async function handleUpdateProductSubmit(event) {
    event.preventDefault();
    
    const submitBtn = document.getElementById('submitProductBtn');
    enableSubmitButton(submitBtn, 'Đang cập nhật...', true);

    const formData = new FormData();
    const productId = document.getElementById('productId').value;
    const productData = buildProductData();
    
    if (productData.imageUrls.length === 0 && newMainImageFiles.length === 0) {
        alert('Sản phẩm phải có ít nhất một ảnh chính.');
        enableSubmitButton(submitBtn, 'Cập Nhật Sản Phẩm');
        return;
    }

    newMainImageFiles.forEach(file => {
        formData.append('newMainImages', file);
    });

    document.querySelectorAll('.variant-group').forEach(variantEl => {
        const variantImageInput = variantEl.querySelector('.variantImage');
        if (variantImageInput.files[0]) {
            formData.append('newVariantImages', variantImageInput.files[0]);
        }
    });

    formData.append('productData', JSON.stringify(productData));

    try {
        const token = localStorage.getItem('jwtToken');
        const response = await fetch(`${API_BASE_URL}/api/admin/products/${productId}`, { 
            method: 'PUT', 
            headers: { 'Authorization': `Bearer ${token}` }, 
            body: formData 
        });

        if (response.ok) {
            alert('Cập nhật sản phẩm thành công!');
            window.location.href = 'products.html';
        } else {
            const errorText = await response.text();
            alert('Lỗi: ' + errorText);
            enableSubmitButton(submitBtn, 'Cập Nhật Sản Phẩm');
        }
    } catch (e) {
        alert('Lỗi kết nối: ' + e.message);
        enableSubmitButton(submitBtn, 'Cập Nhật Sản Phẩm');
    }
}

function initializeSharedEventListeners() {
    const mainImageInput = document.getElementById('mainImageInput');
    const mainImageDropzone = document.getElementById('main-image-dropzone');
    const galleryContainer = document.getElementById('main-image-gallery-container');

    mainImageDropzone.addEventListener('click', () => mainImageInput.click());

    mainImageInput.addEventListener('change', (event) => {
        handleNewMainImages(event.target.files);
    });

    galleryContainer.addEventListener('click', (event) => {
        const removeBtn = event.target.closest('.btn-remove-image');
        
        if (removeBtn) {
            const wrapper = removeBtn.parentElement;
            const fileIdentifier = wrapper.dataset.fileIdentifier;

            if (fileIdentifier) {
                newMainImageFiles = newMainImageFiles.filter(file => file.name !== fileIdentifier);
            }
            
            wrapper.remove();
        }
    });
    
    document.getElementById('addVariantBtn').addEventListener('click', () => addVariantField());
    document.getElementById('variantsContainer').addEventListener('click', handleVariantContainerClick);
    document.getElementById('cancelEditBtn').addEventListener('click', () => {
        if (confirm('Bạn có chắc muốn hủy bỏ các thay đổi và quay lại trang danh sách?')) {
            window.location.href = 'products.html';
        }
    });
}

function handleNewMainImages(files) {
    for (const file of files) {
        if (!newMainImageFiles.some(f => f.name === file.name)) {
            newMainImageFiles.push(file);
            const reader = new FileReader();
            reader.onload = (e) => {
                addMainImagePreview(e.target.result, file.name);
            };
            reader.readAsDataURL(file);
        }
    }
    document.getElementById('mainImageInput').value = '';
}

async function loadCategories() {
    const token = localStorage.getItem('jwtToken');
    const categorySelect = document.getElementById('productCategorySelect');
    try {
        const response = await fetch(`${API_BASE_URL}/api/admin/categories`, {
            headers: { 'Authorization': `Bearer ${token}` }
        });
        if (!response.ok) throw new Error('Không thể tải danh sách loại sản phẩm.');
        const categories = await response.json();
        while (categorySelect.options.length > 1) categorySelect.remove(1);
        categories.forEach(category => {
            const option = new Option(category.name, category.id);
            categorySelect.appendChild(option);
        });
    } catch (error) {
        console.error(error);
        alert(error.message);
    }
}

function addMainImagePreview(src, fileIdentifier = null) {
    const galleryContainer = document.getElementById('main-image-gallery-container');
    const dropzone = document.getElementById('main-image-dropzone');
    const wrapper = document.createElement('div');
    wrapper.className = 'gallery-image-wrapper';

    if (fileIdentifier) {
        wrapper.dataset.fileIdentifier = fileIdentifier;
    } else {
        wrapper.dataset.existingUrl = src;
    }

    wrapper.innerHTML = `
        <img src="${src}" alt="Xem trước">
        <button type="button" class="btn-remove-image" title="Xóa ảnh này">
            <i class="fa-solid fa-times"></i>
        </button>
    `;
    galleryContainer.insertBefore(wrapper, dropzone);
}

function buildProductData() {
    const productData = {
        name: document.getElementById('productName').value,
        description: document.getElementById('productDescription').value,
        category: { id: parseInt(document.getElementById('productCategorySelect').value) },
        importPrice: parseFloat(document.getElementById('productImportPrice').value) || 0,
        salePrice: parseFloat(document.getElementById('productSalePrice').value) || 0,
        imageUrls: [],
        variants: []
    };

    document.querySelectorAll('#main-image-gallery-container .gallery-image-wrapper[data-existing-url]').forEach(wrapper => {
        productData.imageUrls.push(wrapper.dataset.existingUrl);
    });

    document.querySelectorAll('.variant-group').forEach(variantEl => {
        const variantImageInput = variantEl.querySelector('.variantImage');
        const variantImagePreview = variantEl.querySelector('.variant-image-preview');
        
        const variant = {
            name: variantEl.querySelector('.variantName').value,
            variantPrice: parseFloat(variantEl.querySelector('.variantPrice').value) || null,
            imageUrl: null,
            sizes: []
        };
        
        if (variantImageInput.files[0]) {
            variant.imageUrl = ""; 
        } 
        else if (variantImagePreview.dataset.originalUrl && variantImagePreview.dataset.originalUrl !== '#') {
            variant.imageUrl = variantImagePreview.dataset.originalUrl;
        }

        variantEl.querySelectorAll('.size-group').forEach(sizeEl => {
            variant.sizes.push({
                sizeName: sizeEl.querySelector('.sizeName').value,
                quantityInStock: parseInt(sizeEl.querySelector('.quantityInStock').value)
            });
        });
        productData.variants.push(variant);
    });
    return productData;
}

function addVariantField(variantData = {}) {
    variantIndex++;
    const variantId = `variant-${variantIndex}`;
    const hasImage = variantData.imageUrl && variantData.imageUrl !== '#';
    const previewSrc = hasImage ? variantData.imageUrl : '#';
    const previewDisplay = hasImage ? 'block' : 'none';
    const dropzoneDisplay = hasImage ? 'none' : 'flex';
    const removeBtnDisplay = hasImage ? 'flex' : 'none';
    const variantHtml = `
        <div class="variant-group" id="${variantId}">
            <div class="variant-header">
                <h5>Biến thể ${variantIndex}</h5>
                <button type="button" class="btn-icon-danger remove-variant-btn" title="Xóa biến thể này"><i class="fa-solid fa-trash-can"></i></button>
            </div>
            <div class="form-grid">
                <div class="form-group">
                    <label>Tên biến thể:</label>
                    <input type="text" class="variantName" placeholder="Ví dụ: Màu Đen" required value="${variantData.name || ''}">
                </div>
                <div class="form-group">
                    <label>Giá bán riêng (nếu có):</label>
                    <input type="number" class="variantPrice" step="1000" min="0" placeholder="Bỏ trống nếu dùng giá chính" value="${variantData.variantPrice || ''}">
                </div>
                <div class="form-group full-width">
                     <label>Ảnh cho biến thể:</label>
                     <div class="image-uploader-container variant-uploader">
                        <img class="variant-image-preview" src="${previewSrc}" alt="Xem trước" style="display: ${previewDisplay};" data-original-url="${previewSrc}">
                        <div class="variant-dropzone-placeholder dropzone-placeholder" style="display: ${dropzoneDisplay};">
                            <i class="fa-solid fa-image"></i>
                            <span>Chọn ảnh cho biến thể</span>
                        </div>
                        <input type="file" class="variantImage image-input-hidden" accept="image/*">
                        <button type="button" class="btn-remove-image remove-variant-image" title="Xóa ảnh này" style="display: ${removeBtnDisplay};">
                            <i class="fa-solid fa-times"></i>
                        </button>
                    </div>
                </div>
            </div>
            <div class="sizesContainer" style="margin-top: 15px;"></div>
            <button type="button" class="addSizeBtn">+ Thêm Size</button>
        </div>
    `;
    document.getElementById('variantsContainer').insertAdjacentHTML('beforeend', variantHtml);
    const newVariantGroup = document.getElementById(variantId);
    const variantDropzone = newVariantGroup.querySelector('.variant-dropzone-placeholder');
    const variantFileInput = newVariantGroup.querySelector('.variantImage');
    variantDropzone.addEventListener('click', () => variantFileInput.click());
    const sizesContainer = newVariantGroup.querySelector('.sizesContainer');
    if (variantData.sizes && variantData.sizes.length > 0) {
        variantData.sizes.forEach(size => addSizeField(sizesContainer, size));
    }
}

function addSizeField(sizesContainer, sizeData = {}) {
    const sizeHtml = `
        <div class="size-group">
            <input type="text" class="sizeName" placeholder="Tên Size (S, M..)" required style="flex: 2;" value="${sizeData.sizeName || ''}">
            <input type="number" class="quantityInStock" placeholder="Số lượng" required style="flex: 1;" value="${sizeData.quantityInStock || 0}">
            <button type="button" class="btn-icon-danger remove-size-btn" title="Xóa size này"><i class="fa-solid fa-times"></i></button>
        </div>
    `;
    sizesContainer.insertAdjacentHTML('beforeend', sizeHtml);
}

function handleVariantContainerClick(event) {
    const target = event.target.closest('button');
    if (!target) return;
    if (target.classList.contains('addSizeBtn')) {
        addSizeField(target.previousElementSibling);
    }
    if (target.classList.contains('remove-variant-btn')) {
        if (confirm('Bạn có chắc muốn xóa biến thể này?')) {
            target.closest('.variant-group').remove();
        }
    }
    if (target.classList.contains('remove-size-btn')) {
        target.closest('.size-group').remove();
    }
     if (target.classList.contains('remove-variant-image')) {
        removeVariantImage(target);
    }
}

function removeVariantImage(buttonElement) {
    const uploader = buttonElement.closest('.image-uploader-container');
    if (!uploader) return;
    const preview = uploader.querySelector('.variant-image-preview');
    const input = uploader.querySelector('.variantImage');
    const dropzone = uploader.querySelector('.variant-dropzone-placeholder');
    preview.style.display = 'none';
    preview.src = '#';
    preview.removeAttribute('data-original-url');
    input.value = '';
    dropzone.style.display = 'flex';
    buttonElement.style.display = 'none';
}

function enableSubmitButton(button, text, isDisabled = false) {
    button.disabled = isDisabled;
    button.querySelector('.btn-text').textContent = text;
    button.querySelector('i.fa-spinner').style.display = isDisabled ? 'inline-block' : 'none';
}