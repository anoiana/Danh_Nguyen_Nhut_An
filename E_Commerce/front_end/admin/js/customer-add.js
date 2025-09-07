
document.addEventListener('DOMContentLoaded', () => {
    document.getElementById('addCustomerForm').addEventListener('submit', handleAddCustomer);
});

async function handleAddCustomer(event) {
    event.preventDefault();
    showLoader();
    const token = localStorage.getItem('jwtToken');
    const userData = {
        username: document.getElementById('newUsername').value,
        email: document.getElementById('newEmail').value,
        password: document.getElementById('newPassword').value
    };

    try {
        const response = await fetch(`${API_BASE_URL}/api/admin/customers`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json', 'Authorization': `Bearer ${token}` },
            body: JSON.stringify(userData)
        });

        if (response.ok) {
            localStorage.setItem('toastMessage', 'Thêm khách hàng mới thành công!');
            window.location.href = 'customers.html'; // Chuyển hướng về trang danh sách
        } else {
            const errorText = await response.text();
            throw new Error(errorText || 'Không thể thêm khách hàng.');
        }
    } catch (err) {
        showToast(`Lỗi: ${err.message}`, 'error');
    } finally {
        hideLoader();
    }
}