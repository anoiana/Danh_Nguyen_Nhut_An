document.addEventListener('DOMContentLoaded', function () {
    // Chờ một chút để logic gốc (promotion-edit-logic.js) tải xong sản phẩm
    // rồi mới khởi tạo giao diện nâng cao
    setTimeout(initializePromotionUI, 200);

    const activeSwitch = document.getElementById('isActive');
    if(activeSwitch) {
        activeSwitch.addEventListener('change', updateStatusLabel);
    }
});

function initializePromotionUI() {
    const hiddenSelect = document.getElementById('productIds');
    if (!hiddenSelect) return;

    // Thiết lập giao diện Transfer List
    setupTransferList();

    // Gắn sự kiện cho các nút chuyển và thanh tìm kiếm
    const transferButtons = document.querySelector('.transfer-buttons');
    if (transferButtons) {
        transferButtons.addEventListener('click', handleTransferButtonClick);
    }
    
    document.querySelectorAll('.product-search').forEach(input => {
        input.addEventListener('keyup', handleSearch);
    });

    // Cập nhật nhãn trạng thái ban đầu
    updateStatusLabel();
}

function setupTransferList() {
    const hiddenSelect = document.getElementById('productIds');
    const availableList = document.getElementById('availableProductsList');
    const appliedList = document.getElementById('appliedProductsList');

    if (!availableList || !appliedList) return;

    availableList.innerHTML = '';
    appliedList.innerHTML = '';

    Array.from(hiddenSelect.options).forEach(option => {
        const li = document.createElement('li');
        li.dataset.value = option.value;
        
        // Tách tên và ID để hiển thị đẹp hơn
        const nameMatch = option.textContent.match(/(.*)\s\(ID:\s(\d+)\)/);
        if (nameMatch) {
            li.innerHTML = `
                <span>${nameMatch[1]}</span>
                <span class="product-id">#${nameMatch[2]}</span>
            `;
        } else {
            li.textContent = option.textContent;
        }

        li.addEventListener('click', () => li.classList.toggle('selected'));

        if (option.selected) {
            appliedList.appendChild(li);
        } else {
            availableList.appendChild(li);
        }
    });

    updateTransferListCounters(); // Cập nhật bộ đếm
}

function handleTransferButtonClick(event) {
    const button = event.target.closest('.transfer-btn');
    if (!button) return;

    const action = button.dataset.action;
    const availableList = document.getElementById('availableProductsList');
    const appliedList = document.getElementById('appliedProductsList');

    const selectedAvailable = Array.from(availableList.querySelectorAll('.selected'));
    const selectedApplied = Array.from(appliedList.querySelectorAll('.selected'));
    const allAvailable = Array.from(availableList.children);
    const allApplied = Array.from(appliedList.children);

    switch (action) {
        case 'add-selected':
            selectedAvailable.forEach(item => appliedList.appendChild(item));
            break;
        case 'add-all':
            allAvailable.forEach(item => appliedList.appendChild(item));
            break;
        case 'remove-selected':
            selectedApplied.forEach(item => availableList.appendChild(item));
            break;
        case 'remove-all':
            allApplied.forEach(item => availableList.appendChild(item));
            break;
    }
    
    syncHiddenSelect();
}

function syncHiddenSelect() {
    const hiddenSelect = document.getElementById('productIds');
    const appliedListItems = document.getElementById('appliedProductsList').children;
    const appliedIds = new Set(Array.from(appliedListItems).map(li => li.dataset.value));

    Array.from(hiddenSelect.options).forEach(option => {
        option.selected = appliedIds.has(option.value);
    });
    
    document.querySelectorAll('.product-list li.selected').forEach(li => li.classList.remove('selected'));
    updateTransferListCounters();
}

function handleSearch(event) {
    const searchTerm = event.target.value.toLowerCase();
    const targetListId = event.target.dataset.target === 'available' ? 'availableProductsList' : 'appliedProductsList';
    const list = document.getElementById(targetListId);

    Array.from(list.children).forEach(li => {
        const text = li.textContent.toLowerCase();
        li.style.display = text.includes(searchTerm) ? '' : 'none';
    });
}

function updateStatusLabel() {
    const statusLabel = document.getElementById('statusLabel');
    const isActive = document.getElementById('isActive').checked;
    if (statusLabel) {
        statusLabel.textContent = isActive ? 'Đang hoạt động' : 'Tạm dừng';
    }
}

function updateTransferListCounters() {
    const availableCount = document.getElementById('availableProductsList').children.length;
    const appliedCount = document.getElementById('appliedProductsList').children.length;

    document.getElementById('availableCount').textContent = `(${availableCount})`;
    document.getElementById('appliedCount').textContent = `(${appliedCount})`;
}

// Ghi đè các hàm gốc để cập nhật UI sau khi logic chạy
if (typeof populateFormForEdit !== 'undefined') {
    const originalPopulateForm = window.populateFormForEdit;
    window.populateFormForEdit = function(...args) {
        originalPopulateForm.apply(this, args);
        setTimeout(setupTransferList, 50); 
        updateStatusLabel();
    };
}

if (typeof resetForm !== 'undefined') {
    const originalResetForm = window.resetForm;
    window.resetForm = function(...args) {
        originalResetForm.apply(this, args);
        setTimeout(setupTransferList, 50);
        updateStatusLabel();
    };
}