// =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
//                  KHỞI TẠO TRANG
// =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
document.addEventListener('DOMContentLoaded', function () {
    initializePage();
});

async function initializePage() {
    const urlParams = new URLSearchParams(window.location.search);
    const id = urlParams.get('id');

    if (!id) {
        showToast("Không tìm thấy ID khách hàng trên URL.", 'error');
        setTimeout(() => window.location.href = 'customers.html', 2000);
        return;
    }

    showLoader();
    try {
        const token = localStorage.getItem('jwtToken');
        const [userResponse, ordersResponse] = await Promise.all([
            fetch(`${API_BASE_URL}/api/admin/customers/${id}`, { headers: { 'Authorization': `Bearer ${token}` } }),
            fetch(`${API_BASE_URL}/api/admin/orders/user/${id}`, { headers: { 'Authorization': `Bearer ${token}` } })
        ]);

        if (!userResponse.ok) throw new Error('Không thể tải thông tin khách hàng.');
        if (!ordersResponse.ok) throw new Error('Không thể tải lịch sử đơn hàng.');

        const customer = await userResponse.json();
        const orders = await ordersResponse.json();

        populateAllData(customer, orders);
        initializeEventListeners(id);
        await populateAddressDropdowns(customer);

    } catch (err) {
        showToast(err.message, 'error');
    } finally {
        hideLoader();
    }
}

function initializeEventListeners(id) {
    document.getElementById('customerForm').addEventListener('submit', (e) => {
        e.preventDefault();
        updateCustomer(id);
    });
    document.getElementById('deleteCustomerBtn').addEventListener('click', () => deleteCustomer(id));
    document.getElementById('provinceSelect').addEventListener('change', handleProvinceChange);
    document.getElementById('districtSelect').addEventListener('change', handleDistrictChange);
}

// =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
//                  RENDER DỮ LIỆU LÊN GIAO DIỆN
// =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
function populateAllData(customer, orders) {
    document.getElementById('formTitle').textContent = `Chi tiết: ${customer.username}`;

    document.getElementById('customerUsername').value = customer.username || '';
    document.getElementById('customerEmail').value = customer.email || '';
    document.getElementById('customerPhone').value = customer.phoneNumber || '';
    document.getElementById('customerAddress').value = customer.address || '';
    document.getElementById('customerNotes').value = customer.notes || '';

    // ▼▼▼ CẬP NHẬT TRẠNG THÁI TÀI KHOẢN ▼▼▼
    const statusToggle = document.getElementById('customerStatus');
    const statusLabel = document.getElementById('statusLabel');
    
    // 1. Cập nhật trạng thái của công tắc dựa trên dữ liệu từ API
    statusToggle.checked = customer.enabled;

    // 2. Cập nhật nhãn văn bản tương ứng
    const updateStatusLabel = () => {
        statusLabel.textContent = statusToggle.checked ? 'Hoạt động' : 'Vô hiệu hóa';
    };
    updateStatusLabel();

    // 3. Thêm sự kiện để khi admin bấm vào công tắc, nhãn sẽ tự thay đổi
    statusToggle.addEventListener('change', updateStatusLabel);
    // ▲▲▲ KẾT THÚC CẬP NHẬT TRẠNG THÁI ▲▲▲

    const totalSpent = orders.reduce((sum, order) => sum + order.totalAmount, 0);
    const dateValue = customer.joinDate || customer.createdAt;
    const joinDateDisplay = dateValue ? new Date(dateValue).toLocaleDateString('vi-VN') : '';

    document.getElementById('customerSummaryCard').innerHTML = `
        <div class="customer-summary-avatar">${getInitials(customer.username)}</div>
        <h4 class="customer-summary-name">${customer.username}</h4>
        <p class="customer-summary-email">${customer.email}</p>
        <hr class="form-divider">
        <div class="summary-stat"><span>Tổng chi tiêu</span><strong>${formatCurrency(totalSpent)}</strong></div>
        <div class="summary-stat"><span>Tổng số đơn hàng</span><strong>${orders.length}</strong></div>
        <div class="summary-stat"><span>Ngày tham gia</span><strong>${joinDateDisplay}</strong></div>
    `;

    const orderHistoryBody = document.getElementById('orderHistoryBody');
    orderHistoryBody.innerHTML = '';
    if (orders.length > 0) {
        orders.forEach(order => {
            orderHistoryBody.innerHTML += `
                <tr>
                    <td><strong>#${order.id}</strong></td>
                    <td>${new Date(order.orderDate).toLocaleDateString('vi-VN')}</td>
                    <td><span class="status-badge status-${(order.status || 'N/A').toUpperCase()}">${order.status || 'N/A'}</span></td>
                    <td style="text-align: right; font-weight: 500;">${formatCurrency(order.totalAmount)}</td>
                </tr>
            `;
        });
    } else {
        orderHistoryBody.innerHTML = '<tr><td colspan="4" style="text-align: center;">Chưa có đơn hàng nào.</td></tr>';
    }
}

// =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
//         CÁC HÀM XỬ LÝ API VÀ DROPDOWN ĐỊA CHỈ
// =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

async function fetchProvinces() {
    const response = await fetch(`${HOST_PROVINCE_API}?depth=1`);
    if (!response.ok) throw new Error("Không thể tải danh sách Tỉnh/Thành.");
    return await response.json();
}

async function fetchDistricts(provinceCode) {
    const response = await fetch(`${HOST_PROVINCE_API}p/${provinceCode}?depth=2`);
    if (!response.ok) throw new Error("Không thể tải danh sách Quận/Huyện.");
    return (await response.json()).districts;
}

async function fetchWards(districtCode) {
    const response = await fetch(`${HOST_PROVINCE_API}d/${districtCode}?depth=2`);
    if (!response.ok) throw new Error("Không thể tải danh sách Phường/Xã.");
    return (await response.json()).wards;
}

function renderOptions(selectElement, data, placeholder, selectedValue = null) {
    selectElement.innerHTML = `<option value="">-- ${placeholder} --</option>`;
    data.forEach(item => {
        const option = document.createElement('option');
        option.value = item.code;
        option.textContent = item.name;
        if (item.name === selectedValue) {
            option.selected = true;
        }
        selectElement.appendChild(option);
    });
}

async function populateAddressDropdowns(customer) {
    const provinceSelect = document.getElementById('provinceSelect');
    const districtSelect = document.getElementById('districtSelect');
    const wardSelect = document.getElementById('wardSelect');

    const provinces = await fetchProvinces();
    renderOptions(provinceSelect, provinces, 'Chọn Tỉnh/Thành', customer.province);

    if (customer.province) {
        const selectedProvince = provinces.find(p => p.name === customer.province);
        if (selectedProvince) {
            const districts = await fetchDistricts(selectedProvince.code);
            renderOptions(districtSelect, districts, 'Chọn Quận/Huyện', customer.district);

            if (customer.district) {
                const selectedDistrict = districts.find(d => d.name === customer.district);
                if (selectedDistrict) {
                    const wards = await fetchWards(selectedDistrict.code);
                    renderOptions(wardSelect, wards, 'Chọn Phường/Xã', customer.ward);
                }
            }
        }
    }
}

async function handleProvinceChange() {
    const provinceCode = this.value;
    const districtSelect = document.getElementById('districtSelect');
    const wardSelect = document.getElementById('wardSelect');
    districtSelect.innerHTML = '<option value="">-- Chọn Quận/Huyện --</option>';
    wardSelect.innerHTML = '<option value="">-- Chọn Phường/Xã --</option>';
    if (provinceCode) {
        const districts = await fetchDistricts(provinceCode);
        renderOptions(districtSelect, districts, 'Chọn Quận/Huyện');
    }
}

async function handleDistrictChange() {
    const districtCode = this.value;
    const wardSelect = document.getElementById('wardSelect');
    wardSelect.innerHTML = '<option value="">-- Chọn Phường/Xã --</option>';
    if (districtCode) {
        const wards = await fetchWards(districtCode);
        renderOptions(wardSelect, wards, 'Chọn Phường/Xã');
    }
}

async function updateCustomer(id) {
    showLoader();
    const token = localStorage.getItem('jwtToken');

    const getSelectedText = (el) => {
        if (el.selectedIndex <= 0) return "";
        return el.options[el.selectedIndex].text;
    }

    // ▼▼▼ THÊM TRƯỜNG 'enabled' VÀO DỮ LIỆU GỬI ĐI ▼▼▼
    const updatedData = {
        username: document.getElementById('customerUsername').value,
        email: document.getElementById('customerEmail').value,
        phoneNumber: document.getElementById('customerPhone').value,
        address: document.getElementById('customerAddress').value,
        province: getSelectedText(document.getElementById('provinceSelect')),
        district: getSelectedText(document.getElementById('districtSelect')),
        ward: getSelectedText(document.getElementById('wardSelect')),
        notes: document.getElementById('customerNotes').value,
        // Đọc trạng thái hiện tại của công tắc và gửi đi
        enabled: document.getElementById('customerStatus').checked 
    };
    // ▲▲▲ KẾT THÚC THÊM TRƯỜNG 'enabled' ▲▲▲

    try {
        const response = await fetch(`${API_BASE_URL}/api/admin/customers/${id}`, {
            method: 'PUT',
            headers: { 'Content-Type': 'application/json', 'Authorization': `Bearer ${token}` },
            body: JSON.stringify(updatedData)
        });
        if (response.ok) {
            showToast('Cập nhật thông tin khách hàng thành công!');
        } else {
            const errorData = await response.json();
            throw new Error(errorData.message || 'Không thể cập nhật thông tin.');
        }
    } catch (err) {
        showToast(`Lỗi: ${err.message}`, 'error');
    } finally {
        hideLoader();
    }
}

async function deleteCustomer(id) {
    if (confirm(`Bạn có chắc muốn xóa vĩnh viễn khách hàng #${id}? Hành động này sẽ xóa toàn bộ thông tin và không thể hoàn tác.`)) {
        showLoader();
        const token = localStorage.getItem('jwtToken');
        try {
            const response = await fetch(`${API_BASE_URL}/api/admin/customers/${id}`, {
                method: 'DELETE',
                headers: { 'Authorization': `Bearer ${token}` }
            });
            if (response.ok) {
                localStorage.setItem('toastMessage', 'Xóa khách hàng thành công!');
                window.location.href = 'customers.html';
            } else {
                throw new Error('Không thể xóa khách hàng.');
            }
        } catch (err) {
            showToast(`Lỗi: ${err.message}`, 'error');
        } finally {
            hideLoader();
        }
    }
}

// =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
//                  HÀM TIỆN ÍCH
// =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
function formatCurrency(number) {
    if (typeof number !== 'number') return '0 ₫';
    return new Intl.NumberFormat('vi-VN', { style: 'currency', currency: 'VND' }).format(number);
}

function getInitials(name) {
    if (!name) return '?';
    const words = name.trim().split(/\s+/);
    if (words.length > 1) {
        return `${words[0][0]}${words[words.length - 1][0]}`.toUpperCase();
    }
    return name.substring(0, 2).toUpperCase();
}