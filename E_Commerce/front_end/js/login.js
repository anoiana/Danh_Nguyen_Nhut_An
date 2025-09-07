document.getElementById('loginForm').addEventListener('submit', async function (event) {
    event.preventDefault();

    const email = document.getElementById('email').value;
    const password = document.getElementById('password').value;
    const messageEl = document.getElementById('message');

    try {
        const response = await fetch('http://localhost:8080/api/auth/login', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ email, password })
        });

        const data = await response.json();

        if (response.ok) {
            // Lưu token và thông tin người dùng vào localStorage
            localStorage.setItem('jwtToken', data.token);
            localStorage.setItem('user', JSON.stringify({
                id: data.id,
                email: data.email,
                username: data.username,
                roles: data.roles
            }));

            // Chuyển hướng đến trang home
            window.location.href = 'home.html';
        } else {
            messageEl.textContent = data.message || 'Email hoặc mật khẩu không đúng.';
            messageEl.className = 'message error';
        }
    } catch (error) {
        messageEl.textContent = 'Lỗi kết nối đến server. Vui lòng thử lại sau.';
        messageEl.className = 'message error';
    }
});