document.getElementById('registerForm').addEventListener('submit', async function (event) {
    event.preventDefault();

    const username = document.getElementById('username').value;
    const email = document.getElementById('email').value;
    const password = document.getElementById('password').value;
    const messageEl = document.getElementById('message');

    try {
        const response = await fetch('http://localhost:8080/api/auth/register', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ username, email, password })
        });

        const data = await response.json();

        if (response.ok) {
            messageEl.textContent = data.message;
            messageEl.className = 'message success';
            document.getElementById('registerForm').reset(); // Xóa form sau khi thành công
        } else {
            messageEl.textContent = data.message || 'Đã có lỗi xảy ra.';
            messageEl.className = 'message error';
        }
    } catch (error) {
        messageEl.textContent = 'Lỗi kết nối đến server.';
        messageEl.className = 'message error';
    }
});