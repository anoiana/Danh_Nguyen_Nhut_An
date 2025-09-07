document.getElementById('forgotPasswordForm').addEventListener('submit', async function (event) {
    event.preventDefault();
    const email = document.getElementById('email').value;
    const messageEl = document.getElementById('message');
    
    messageEl.textContent = 'Đang xử lý...';
    messageEl.className = 'message';

    try {
        const response = await fetch('http://localhost:8080/api/auth/forgot-password', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ email })
        });

        const data = await response.json();
        messageEl.textContent = data.message; // "If your email is registered..."
        messageEl.className = 'message success';

    } catch (error) {
        messageEl.textContent = 'Lỗi kết nối đến server.';
        messageEl.className = 'message error';
    }
});