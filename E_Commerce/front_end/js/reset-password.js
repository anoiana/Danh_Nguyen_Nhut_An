document.addEventListener('DOMContentLoaded', function() {
    const messageEl = document.getElementById('message');
    const form = document.getElementById('resetPasswordForm');
    
    // Lấy token từ URL query string
    const params = new URLSearchParams(window.location.search);
    const token = params.get('token');

    if (!token) {
        messageEl.textContent = 'Token không hợp lệ hoặc đã thiếu. Vui lòng thử lại từ link trong email.';
        messageEl.className = 'message error';
        form.style.display = 'none'; // Ẩn form nếu không có token
        return;
    }

    form.addEventListener('submit', async function(event) {
        event.preventDefault();
        const newPassword = document.getElementById('newPassword').value;

        try {
            const response = await fetch('http://localhost:8080/api/auth/reset-password', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ token, newPassword })
            });

            const data = await response.json();

            if (response.ok) {
                messageEl.textContent = 'Mật khẩu đã được cập nhật thành công! Đang chuyển hướng đến trang đăng nhập...';
                messageEl.className = 'message success';
                setTimeout(() => {
                    window.location.href = 'login.html';
                }, 3000); // Chờ 3 giây rồi chuyển hướng
            } else {
                messageEl.textContent = data.message || 'Token không hợp lệ hoặc đã hết hạn.';
                messageEl.className = 'message error';
            }

        } catch (error) {
            messageEl.textContent = 'Lỗi kết nối đến server.';
            messageEl.className = 'message error';
        }
    });
});