/**
 * Hiển thị một thông báo "toast" ở góc trên bên phải màn hình.
 * @param {string} message - Nội dung thông báo cần hiển thị.
 * @param {string} type - Loại thông báo ('success' hoặc 'error'). Mặc định là 'success'.
 * @param {number} duration - Thời gian hiển thị (tính bằng mili giây). Mặc định là 3000ms.
 */
function showToast(message, type = 'success', duration = 3000) {
    const container = document.getElementById('toast-container');
    if (!container) {
        console.error('Không tìm thấy #toast-container trong DOM.');
        return;
    }

    // Tạo phần tử toast
    const toast = document.createElement('div');
    toast.className = `toast ${type}`;

    // Chọn icon dựa trên loại thông báo
    const iconClass = type === 'success' 
        ? 'fa-solid fa-circle-check' 
        : 'fa-solid fa-circle-xmark';
    
    // Tạo cấu trúc HTML cho toast
    toast.innerHTML = `
        <i class="${iconClass} toast-icon"></i>
        <div class="toast-message">${message}</div>
    `;

    // Thêm toast vào container
    container.appendChild(toast);

    // Tự động xóa toast sau một khoảng thời gian
    setTimeout(() => {
        // Thêm class để kích hoạt animation fade-out
        toast.classList.add('fade-out');
        // Xóa hẳn phần tử khỏi DOM sau khi animation kết thúc
        toast.addEventListener('animationend', () => {
            toast.remove();
        });
    }, duration);
}