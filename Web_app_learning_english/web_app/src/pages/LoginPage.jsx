import { useState } from 'react';
import { authAPI } from '../services/api';
import { useAuth } from '../context/AuthContext';

export default function LoginPage() {
    const { login } = useAuth();
    const [isRegister, setIsRegister] = useState(false);
    const [username, setUsername] = useState('');
    const [password, setPassword] = useState('');
    const [error, setError] = useState('');
    const [success, setSuccess] = useState('');
    const [loading, setLoading] = useState(false);

    const handleSubmit = async (e) => {
        e.preventDefault();
        setError('');
        setSuccess('');

        if (!username.trim() || !password.trim()) {
            setError('Vui lòng nhập đầy đủ thông tin');
            return;
        }

        setLoading(true);
        try {
            if (isRegister) {
                await authAPI.register(username, password);
                setSuccess('Đăng ký thành công! Hãy đăng nhập.');
                setIsRegister(false);
                setPassword('');
            } else {
                const data = await authAPI.login(username, password);
                login(data);
            }
        } catch (err) {
            setError(err.message || 'Đã có lỗi xảy ra');
        } finally {
            setLoading(false);
        }
    };

    return (
        <div className="auth-container">
            <div className="auth-card">
                <div className="auth-logo">
                    <span className="logo-icon">📚</span>
                    <h1>VocabMaster</h1>
                    <p>Học từ vựng tiếng Anh hiệu quả</p>
                </div>

                {error && <div className="error-message">{error}</div>}
                {success && <div className="success-message">{success}</div>}

                <form onSubmit={handleSubmit}>
                    <div className="form-group">
                        <label htmlFor="username">Tên đăng nhập</label>
                        <input
                            id="username"
                            type="text"
                            className="form-input"
                            placeholder="Nhập tên đăng nhập"
                            value={username}
                            onChange={(e) => setUsername(e.target.value)}
                            autoComplete="username"
                        />
                    </div>
                    <div className="form-group">
                        <label htmlFor="password">Mật khẩu</label>
                        <input
                            id="password"
                            type="password"
                            className="form-input"
                            placeholder="Nhập mật khẩu"
                            value={password}
                            onChange={(e) => setPassword(e.target.value)}
                            autoComplete="current-password"
                        />
                    </div>
                    <button
                        type="submit"
                        className="btn btn-primary btn-full"
                        disabled={loading}
                    >
                        {loading ? (
                            <>
                                <span className="spinner" style={{ width: 18, height: 18, borderWidth: 2 }}></span>
                                Đang xử lý...
                            </>
                        ) : isRegister ? '🚀 Đăng ký' : '🔑 Đăng nhập'}
                    </button>
                </form>

                <div className="auth-switch">
                    {isRegister ? (
                        <>Đã có tài khoản? <a onClick={() => { setIsRegister(false); setError(''); setSuccess(''); }}>Đăng nhập</a></>
                    ) : (
                        <>Chưa có tài khoản? <a onClick={() => { setIsRegister(true); setError(''); setSuccess(''); }}>Đăng ký</a></>
                    )}
                </div>
            </div>
        </div>
    );
}
