import { useState, useEffect, useCallback } from 'react';
import { folderAPI } from '../services/api';
import { useAuth } from '../context/AuthContext';

export default function FoldersPage({ onSelectFolder }) {
    const { user } = useAuth();
    const [folders, setFolders] = useState([]);
    const [loading, setLoading] = useState(true);
    const [search, setSearch] = useState('');
    const [page, setPage] = useState(0);
    const [totalPages, setTotalPages] = useState(0);
    const [showModal, setShowModal] = useState(false);
    const [editFolder, setEditFolder] = useState(null);
    const [folderName, setFolderName] = useState('');
    const [error, setError] = useState('');

    const fetchFolders = useCallback(async () => {
        if (!user) return;
        setLoading(true);
        try {
            const data = await folderAPI.getByUser(user.userId, page, 15, search);
            setFolders(data.content || []);
            setTotalPages(data.totalPages || 0);
        } catch {
            setError('Không thể tải danh sách thư mục');
        } finally {
            setLoading(false);
        }
    }, [user, page, search]);

    useEffect(() => {
        fetchFolders();
    }, [fetchFolders]);

    const handleCreateOrUpdate = async (e) => {
        e.preventDefault();
        if (!folderName.trim()) return;
        try {
            if (editFolder) {
                await folderAPI.update(editFolder.id, folderName);
            } else {
                await folderAPI.create(folderName, user.userId);
            }
            setShowModal(false);
            setFolderName('');
            setEditFolder(null);
            fetchFolders();
        } catch (err) {
            setError(err.message);
        }
    };

    const handleDelete = async (folderId, e) => {
        e.stopPropagation();
        if (!confirm('Bạn có chắc muốn xóa thư mục này?')) return;
        try {
            await folderAPI.delete(folderId);
            fetchFolders();
        } catch (err) {
            setError(err.message);
        }
    };

    const openEdit = (folder, e) => {
        e.stopPropagation();
        setEditFolder(folder);
        setFolderName(folder.name);
        setShowModal(true);
    };

    return (
        <div className="fade-in">
            <div className="page-header">
                <h1 className="page-title">
                    📁 Thư mục <span>{folders.length > 0 && `(${folders.length})`}</span>
                </h1>
                <div className="page-actions">
                    <div className="search-bar">
                        <span className="search-icon">🔍</span>
                        <input
                            placeholder="Tìm kiếm thư mục..."
                            value={search}
                            onChange={(e) => { setSearch(e.target.value); setPage(0); }}
                        />
                    </div>
                    <button className="btn btn-primary" onClick={() => { setShowModal(true); setEditFolder(null); setFolderName(''); }}>
                        ➕ Tạo mới
                    </button>
                </div>
            </div>

            {error && <div className="error-message">{error} <button className="btn-ghost btn-sm" onClick={() => setError('')}>✕</button></div>}

            {loading ? (
                <div className="loading"><span className="spinner"></span> Đang tải...</div>
            ) : folders.length === 0 ? (
                <div className="empty-state">
                    <div className="empty-icon">📂</div>
                    <h3>Chưa có thư mục nào</h3>
                    <p>Tạo thư mục đầu tiên để bắt đầu học từ vựng</p>
                    <button className="btn btn-primary" onClick={() => setShowModal(true)}>
                        ➕ Tạo thư mục
                    </button>
                </div>
            ) : (
                <>
                    <div className="cards-grid">
                        {folders.map((folder) => (
                            <div key={folder.id} className="card" onClick={() => onSelectFolder(folder)}>
                                <div className="card-icon">📁</div>
                                <div className="card-title">{folder.name}</div>
                                <div className="card-subtitle">
                                    {folder.vocabularyCount || 0} từ vựng
                                </div>
                                <div className="card-actions">
                                    <button className="btn btn-ghost btn-sm" onClick={(e) => openEdit(folder, e)}>
                                        ✏️ Sửa
                                    </button>
                                    <button className="btn btn-ghost btn-sm" onClick={(e) => handleDelete(folder.id, e)} style={{ color: 'var(--danger)' }}>
                                        🗑️ Xóa
                                    </button>
                                </div>
                            </div>
                        ))}
                    </div>
                    {totalPages > 1 && (
                        <div className="pagination">
                            <button disabled={page === 0} onClick={() => setPage(p => p - 1)}>← Trước</button>
                            <span className="page-info">Trang {page + 1} / {totalPages}</span>
                            <button disabled={page >= totalPages - 1} onClick={() => setPage(p => p + 1)}>Sau →</button>
                        </div>
                    )}
                </>
            )}

            {showModal && (
                <div className="modal-overlay" onClick={() => setShowModal(false)}>
                    <div className="modal" onClick={(e) => e.stopPropagation()}>
                        <div className="modal-header">
                            <h3 className="modal-title">{editFolder ? '✏️ Sửa thư mục' : '📁 Tạo thư mục mới'}</h3>
                            <button className="modal-close" onClick={() => setShowModal(false)}>✕</button>
                        </div>
                        <form onSubmit={handleCreateOrUpdate}>
                            <div className="form-group">
                                <label>Tên thư mục</label>
                                <input
                                    className="form-input"
                                    placeholder="Ví dụ: IELTS Vocabulary"
                                    value={folderName}
                                    onChange={(e) => setFolderName(e.target.value)}
                                    autoFocus
                                />
                            </div>
                            <div className="modal-footer">
                                <button type="button" className="btn btn-secondary" onClick={() => setShowModal(false)}>Hủy</button>
                                <button type="submit" className="btn btn-primary">{editFolder ? 'Cập nhật' : 'Tạo mới'}</button>
                            </div>
                        </form>
                    </div>
                </div>
            )}
        </div>
    );
}
