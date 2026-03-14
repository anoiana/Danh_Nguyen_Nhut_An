import { useState, useEffect, useCallback } from 'react';
import { vocabAPI } from '../services/api';

export default function VocabularyPage({ folder, onBack, onStudy }) {
    const [vocabs, setVocabs] = useState([]);
    const [loading, setLoading] = useState(true);
    const [search, setSearch] = useState('');
    const [page, setPage] = useState(0);
    const [totalPages, setTotalPages] = useState(0);
    const [totalElements, setTotalElements] = useState(0);
    const [error, setError] = useState('');
    const [editVocab, setEditVocab] = useState(null);
    const [editMeaning, setEditMeaning] = useState('');
    const [editPos, setEditPos] = useState('');
    const [editPhonetic, setEditPhonetic] = useState('');
    const [showAddModal, setShowAddModal] = useState(false);
    const [newWord, setNewWord] = useState('');
    const [newPhonetic, setNewPhonetic] = useState('');
    const [newMeaning, setNewMeaning] = useState('');
    const [newPos, setNewPos] = useState('');
    const [addLoading, setAddLoading] = useState(false);

    // Batch actions & Image state
    const [selectedIds, setSelectedIds] = useState(new Set());
    const [showMoveModal, setShowMoveModal] = useState(false);
    const [targetFolderId, setTargetFolderId] = useState('');
    const [allFolders, setAllFolders] = useState([]);
    const [imageBase64, setImageBase64] = useState('');

    // Import Excel state
    const [showImportModal, setShowImportModal] = useState(false);
    const [importFile, setImportFile] = useState(null);
    const [importLoading, setImportLoading] = useState(false);
    const [importResult, setImportResult] = useState(null);
    const [dragOver, setDragOver] = useState(false);

    const fetchVocabs = useCallback(async () => {
        setLoading(true);
        try {
            const data = await vocabAPI.getByFolder(folder.id, page, 15, search);
            setVocabs(data.content || []);
            setTotalPages(data.totalPages || 0);
            setTotalElements(data.totalElements || 0);
            setSelectedIds(new Set());
        } catch {
            setError('Không thể tải danh sách từ vựng');
        } finally {
            setLoading(false);
        }
    }, [folder.id, page, search]);

    useEffect(() => {
        fetchVocabs();
    }, [fetchVocabs]);

    // Load ALL vocabs for study (not just current page)
    const handleStudy = async () => {
        try {
            setLoading(true);
            let allVocabs = [];
            let p = 0;
            let hasMore = true;
            while (hasMore) {
                const data = await vocabAPI.getByFolder(folder.id, p, 100, '');
                allVocabs = [...allVocabs, ...(data.content || [])];
                hasMore = p < (data.totalPages - 1);
                p++;
            }
            if (allVocabs.length === 0) {
                setError('Thư mục này chưa có từ vựng nào');
                return;
            }
            onStudy(folder, allVocabs);
        } catch {
            setError('Không thể tải từ vựng để học');
        } finally {
            setLoading(false);
        }
    };

    const loadFoldersForMove = async () => {
        try {
            const res = await fetch(`https://danh-nguyen-nhut-an.onrender.com/api/folders/user/${folder.user?.id || 1}?page=0&size=100`);
            if (res.ok) {
                const data = await res.json();
                setAllFolders(data.content.filter(f => f.id !== folder.id));
            }
        } catch (e) {
            console.error(e);
        }
    };

    const handleBatchDelete = async () => {
        if (selectedIds.size === 0) return;
        if (!confirm(`Bạn có chắc muốn xóa ${selectedIds.size} từ vựng đã chọn?`)) return;
        try {
            await vocabAPI.batchDelete(Array.from(selectedIds));
            fetchVocabs();
        } catch (err) {
            setError(err.message);
        }
    };

    const handleBatchMove = async (e) => {
        e.preventDefault();
        if (selectedIds.size === 0 || !targetFolderId) return;
        try {
            await fetch(`https://danh-nguyen-nhut-an.onrender.com/api/vocabularies/batch-move`, {
                method: 'PUT',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ vocabularyIds: Array.from(selectedIds), targetFolderId: parseInt(targetFolderId) })
            });
            setShowMoveModal(false);
            fetchVocabs();
        } catch (err) {
            setError(err.message);
        }
    };

    const handleSelectAll = (e) => {
        if (e.target.checked) setSelectedIds(new Set(vocabs.map(v => v.id)));
        else setSelectedIds(new Set());
    };

    const toggleSelect = (id) => {
        const newKeys = new Set(selectedIds);
        if (newKeys.has(id)) newKeys.delete(id);
        else newKeys.add(id);
        setSelectedIds(newKeys);
    };

    const handleImageUpload = (e) => {
        const file = e.target.files[0];
        if (!file) return;
        const reader = new FileReader();
        reader.onload = (event) => setImageBase64(event.target.result);
        reader.readAsDataURL(file);
    };

    const handleDelete = async (vocabId) => {
        if (!confirm('Xóa từ vựng này?')) return;
        try {
            await vocabAPI.delete(vocabId);
            fetchVocabs();
        } catch (err) {
            setError(err.message);
        }
    };

    const handleUpdate = async (e) => {
        e.preventDefault();
        if (!editVocab) return;
        try {
            await vocabAPI.update(editVocab.id, {
                userDefinedMeaning: editMeaning,
                userDefinedPartOfSpeech: editPos,
                phoneticText: editPhonetic || null,
                userImageBase64: editVocab.userImageBase64 || '',
            });
            setEditVocab(null);
            fetchVocabs();
        } catch (err) {
            setError(err.message);
        }
    };

    const handleAdd = async (e) => {
        e.preventDefault();
        if (!newWord.trim() || !newMeaning.trim()) return;
        setAddLoading(true);
        try {
            await vocabAPI.create({
                word: newWord.trim(),
                phoneticText: newPhonetic.trim() || null,
                userDefinedMeaning: newMeaning.trim(),
                userDefinedPartOfSpeech: newPos.trim() || null,
                folderId: folder.id,
                meanings: [],
            });
            setShowAddModal(false);
            setNewWord('');
            setNewPhonetic('');
            setNewMeaning('');
            setNewPos('');
            fetchVocabs();
        } catch (err) {
            setError(err.message);
        } finally {
            setAddLoading(false);
        }
    };

    const openEdit = (vocab) => {
        setEditVocab(vocab);
        setEditMeaning(vocab.userDefinedMeaning || getMeaning(vocab));
        setEditPos(vocab.userDefinedPartOfSpeech || getPartOfSpeech(vocab));
        setEditPhonetic(vocab.phoneticText || '');
        setImageBase64(vocab.userImageBase64 || '');
    };

    const getMeaning = (vocab) => {
        if (vocab.userDefinedMeaning) return vocab.userDefinedMeaning;
        if (vocab.meanings && vocab.meanings.length > 0) {
            const m = vocab.meanings[0];
            if (m.definitions && m.definitions.length > 0) {
                return m.definitions[0].definition;
            }
        }
        return 'Chưa có nghĩa';
    };

    const getPartOfSpeech = (vocab) => {
        if (vocab.userDefinedPartOfSpeech) return vocab.userDefinedPartOfSpeech;
        if (vocab.meanings && vocab.meanings.length > 0) {
            return vocab.meanings[0].partOfSpeech;
        }
        return '';
    };

    // Import Excel handlers
    const handleImportFile = (e) => {
        const file = e.target.files[0];
        if (file) { setImportFile(file); setImportResult(null); }
    };

    const handleDrop = (e) => {
        e.preventDefault();
        setDragOver(false);
        const file = e.dataTransfer.files[0];
        if (file && file.name.endsWith('.xlsx')) {
            setImportFile(file);
            setImportResult(null);
        } else {
            setImportResult({ totalRows: 0, successCount: 0, skippedCount: 0, errors: ['Chỉ chấp nhận file .xlsx'] });
        }
    };

    const handleImportSubmit = async () => {
        if (!importFile) return;
        setImportLoading(true);
        setImportResult(null);
        try {
            const result = await vocabAPI.importExcel(folder.id, importFile);
            setImportResult(result);
            if (result.successCount > 0) {
                fetchVocabs();
            }
        } catch (err) {
            setImportResult({ totalRows: 0, successCount: 0, skippedCount: 0, errors: [err.message] });
        } finally {
            setImportLoading(false);
        }
    };

    const handleDownloadTemplate = () => {
        const header = 'Word\tMeaning\tPart of Speech\tPhonetic';
        const example1 = 'happiness\thạnh phúc\tnoun\t/ˈhæp.i.nəs/';
        const example2 = 'beautiful\tđẹp\tadjective\t/ˈbjuː.tɪ.fəl/';
        const content = [header, example1, example2].join('\n');
        const blob = new Blob([content], { type: 'text/tab-separated-values' });
        const url = URL.createObjectURL(blob);
        const a = document.createElement('a');
        a.href = url;
        a.download = 'vocabulary_template.tsv';
        a.click();
        URL.revokeObjectURL(url);
    };

    const closeImportModal = () => {
        setShowImportModal(false);
        setImportFile(null);
        setImportResult(null);
        setDragOver(false);
    };

    return (
        <div className="fade-in">
            <div className="breadcrumb">
                <a onClick={onBack}>📁 Thư mục</a>
                <span className="separator">›</span>
                <span>{folder.name}</span>
            </div>

            <div className="page-header">
                <h1 className="page-title">
                    📖 {folder.name} <span>{totalElements > 0 && `(${totalElements} từ)`}</span>
                </h1>
                <div className="page-actions">
                    <div className="search-bar">
                        <span className="search-icon">🔍</span>
                        <input
                            placeholder="Tìm kiếm từ vựng..."
                            value={search}
                            onChange={(e) => { setSearch(e.target.value); setPage(0); }}
                        />
                    </div>
                    <button className="btn btn-secondary" onClick={() => setShowAddModal(true)}>
                        ➕ Thêm từ
                    </button>
                    <button className="btn btn-secondary" onClick={() => setShowImportModal(true)} style={{ background: 'linear-gradient(135deg, #10b981, #059669)', border: 'none', color: 'white' }}>
                        📥 Import Excel
                    </button>
                    {totalElements > 0 && (
                        <button className="btn btn-primary" onClick={handleStudy}>
                            🎮 Học ngay
                        </button>
                    )}
                </div>
            </div>

            {error && <div className="error-message">{error} <button className="btn-ghost btn-sm" onClick={() => setError('')}>✕</button></div>}

            {loading ? (
                <div className="loading"><span className="spinner"></span> Đang tải...</div>
            ) : vocabs.length === 0 ? (
                <div className="empty-state">
                    <div className="empty-icon">📝</div>
                    <h3>Chưa có từ vựng</h3>
                    <p>Thêm từ vựng đầu tiên để bắt đầu học</p>
                    <div style={{ display: 'flex', gap: '12px', justifyContent: 'center', marginTop: '16px' }}>
                        <button className="btn btn-primary" onClick={() => setShowAddModal(true)}>
                            ➕ Thêm từ vựng
                        </button>
                        <button className="btn btn-primary" onClick={() => setShowImportModal(true)} style={{ background: 'linear-gradient(135deg, #10b981, #059669)', border: 'none' }}>
                            📥 Import Excel
                        </button>
                    </div>
                </div>
            ) : (
                <>
                    {/* Batch Actions Bar */}
                    {selectedIds.size > 0 && (
                        <div style={{
                            background: 'var(--bg-secondary)', padding: '12px 16px', borderRadius: 'var(--radius-md)',
                            border: '1px solid var(--border)', display: 'flex', alignItems: 'center', justifyContent: 'space-between',
                            marginBottom: 16, animation: 'fadeInDown 0.3s ease'
                        }}>
                            <span style={{ fontWeight: 600 }}>Đã chọn <b>{selectedIds.size}</b> từ vựng</span>
                            <div style={{ display: 'flex', gap: 8 }}>
                                <button className="btn btn-secondary btn-sm" onClick={() => { loadFoldersForMove(); setShowMoveModal(true); }}>
                                    📦 Chuyển thư mục
                                </button>
                                <button className="btn btn-danger btn-sm" onClick={handleBatchDelete}>
                                    🗑️ Xóa
                                </button>
                            </div>
                        </div>
                    )}

                    <div className="vocab-list">
                        {/* Header / Select All */}
                        <div style={{ display: 'flex', alignItems: 'center', gap: 16, padding: '0 24px 8px' }}>
                            <input
                                type="checkbox"
                                checked={selectedIds.size === vocabs.length && vocabs.length > 0}
                                onChange={handleSelectAll}
                                style={{ cursor: 'pointer', transform: 'scale(1.2)' }}
                            />
                            <span style={{ color: 'var(--text-muted)', fontSize: 13, textTransform: 'uppercase', letterSpacing: '0.5px' }}>
                                Chọn tất cả
                            </span>
                        </div>

                        {vocabs.map((vocab) => (
                            <div key={vocab.id} className={`vocab-item ${selectedIds.has(vocab.id) ? 'selected' : ''}`}
                                style={{
                                    border: selectedIds.has(vocab.id) ? '1px solid var(--primary-light)' : undefined,
                                    background: selectedIds.has(vocab.id) ? 'var(--primary-glow)' : undefined
                                }}
                            >
                                <div style={{ display: 'flex', alignItems: 'center', gap: 16 }}>
                                    <input
                                        type="checkbox"
                                        checked={selectedIds.has(vocab.id)}
                                        onChange={() => toggleSelect(vocab.id)}
                                        style={{ cursor: 'pointer', transform: 'scale(1.2)' }}
                                    />
                                    {vocab.userImageBase64 ? (
                                        <img src={vocab.userImageBase64} alt={vocab.word}
                                            style={{ width: 40, height: 40, objectFit: 'cover', borderRadius: 'var(--radius-sm)' }}
                                        />
                                    ) : (
                                        <div style={{
                                            width: 40, height: 40, background: 'var(--bg-secondary)', borderRadius: 'var(--radius-sm)',
                                            display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: 16
                                        }}>🖼️</div>
                                    )}
                                </div>
                                <div>
                                    <div className="vocab-word" style={{ fontSize: 16 }}>{vocab.word}</div>
                                    {vocab.phoneticText && (
                                        <div className="vocab-phonetic" style={{ fontSize: 12 }}>{vocab.phoneticText}</div>
                                    )}
                                </div>
                                <div className="vocab-meaning">
                                    {getPartOfSpeech(vocab) && (
                                        <span className="pos">{getPartOfSpeech(vocab)}</span>
                                    )}
                                    {getMeaning(vocab)}
                                </div>
                                {vocab.audioUrl && (
                                    <button
                                        className="btn btn-ghost btn-icon"
                                        title="Phát âm"
                                        onClick={() => new Audio(vocab.audioUrl).play()}
                                    >
                                        🔊
                                    </button>
                                )}
                                <div className="vocab-actions">
                                    <button
                                        className="btn btn-ghost btn-icon"
                                        title="Sửa"
                                        onClick={() => openEdit(vocab)}
                                    >
                                        ✏️
                                    </button>
                                    <button
                                        className="btn btn-ghost btn-icon"
                                        title="Xóa"
                                        onClick={() => handleDelete(vocab.id)}
                                        style={{ color: 'var(--danger)' }}
                                    >
                                        🗑️
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

            {/* Edit Vocabulary Modal */}
            {editVocab && (
                <div className="modal-overlay" onClick={() => setEditVocab(null)}>
                    <div className="modal" onClick={(e) => e.stopPropagation()}>
                        <div className="modal-header">
                            <h3 className="modal-title">✏️ Sửa từ vựng: <span style={{ color: 'var(--primary-light)' }}>{editVocab.word}</span></h3>
                            <button className="modal-close" onClick={() => setEditVocab(null)}>✕</button>
                        </div>
                        <form onSubmit={handleUpdate}>
                            <div className="form-group">
                                <label>Nghĩa tự định nghĩa</label>
                                <input
                                    className="form-input"
                                    placeholder="Nhập nghĩa của từ..."
                                    value={editMeaning}
                                    onChange={(e) => setEditMeaning(e.target.value)}
                                    autoFocus
                                />
                            </div>
                            <div className="form-group">
                                <label>Loại từ</label>
                                <input
                                    className="form-input"
                                    placeholder="noun, verb, adjective..."
                                    value={editPos}
                                    onChange={(e) => setEditPos(e.target.value)}
                                />
                            </div>
                            <div className="form-group">
                                <label>Phiên âm (tùy chọn)</label>
                                <input
                                    className="form-input"
                                    placeholder="ví dụ: /ˈhæp.i.nəs/"
                                    value={editPhonetic}
                                    onChange={(e) => setEditPhonetic(e.target.value)}
                                />
                            </div>
                            <div className="form-group">
                                <label>Hình ảnh (Tùy chọn)</label>
                                <div style={{ display: 'flex', gap: 12, alignItems: 'center', marginTop: 8 }}>
                                    {imageBase64 && <img src={imageBase64} alt="preview" style={{ width: 60, height: 60, objectFit: 'cover', borderRadius: 8 }} />}
                                    <input type="file" accept="image/*" onChange={handleImageUpload} className="form-input" style={{ padding: 8 }} />
                                </div>
                                {imageBase64 && (
                                    <button type="button" className="btn-ghost btn-sm" style={{ marginTop: 8, color: 'var(--danger)' }} onClick={() => setImageBase64('')}>
                                        Xóa ảnh
                                    </button>
                                )}
                            </div>
                            <div className="modal-footer">
                                <button type="button" className="btn btn-secondary" onClick={() => setEditVocab(null)}>Hủy</button>
                                <button type="submit" className="btn btn-primary">💾 Lưu</button>
                            </div>
                        </form>
                    </div>
                </div>
            )}

            {/* Add Vocabulary Modal */}
            {showAddModal && (
                <div className="modal-overlay" onClick={() => setShowAddModal(false)}>
                    <div className="modal" onClick={(e) => e.stopPropagation()}>
                        <div className="modal-header">
                            <h3 className="modal-title">➕ Thêm từ vựng mới</h3>
                            <button className="modal-close" onClick={() => setShowAddModal(false)}>✕</button>
                        </div>
                        <form onSubmit={handleAdd}>
                            <div className="form-group">
                                <label>Từ tiếng Anh *</label>
                                <input
                                    className="form-input"
                                    placeholder="Ví dụ: happiness"
                                    value={newWord}
                                    onChange={(e) => setNewWord(e.target.value)}
                                    autoFocus
                                />
                            </div>
                            <div className="form-group">
                                <label>Phiên âm (tùy chọn)</label>
                                <input
                                    className="form-input"
                                    placeholder="Ví dụ: /ˈhæp.i.nəs/"
                                    value={newPhonetic}
                                    onChange={(e) => setNewPhonetic(e.target.value)}
                                />
                            </div>
                            <div className="form-group">
                                <label>Nghĩa tiếng Việt *</label>
                                <input
                                    className="form-input"
                                    placeholder="Ví dụ: hạnh phúc"
                                    value={newMeaning}
                                    onChange={(e) => setNewMeaning(e.target.value)}
                                />
                            </div>
                            <div className="form-group">
                                <label>Loại từ (tùy chọn)</label>
                                <input
                                    className="form-input"
                                    placeholder="noun, verb, adjective..."
                                    value={newPos}
                                    onChange={(e) => setNewPos(e.target.value)}
                                />
                            </div>
                            <div className="modal-footer">
                                <button type="button" className="btn btn-secondary" onClick={() => setShowAddModal(false)}>Hủy</button>
                                <button type="submit" className="btn btn-primary" disabled={addLoading || !newWord.trim() || !newMeaning.trim()}>
                                    {addLoading ? 'Đang thêm...' : '➕ Thêm'}
                                </button>
                            </div>
                        </form>
                    </div>
                </div>
            )}

            {/* Move Vocabulary Modal */}
            {showMoveModal && (
                <div className="modal-overlay" onClick={() => setShowMoveModal(false)}>
                    <div className="modal" onClick={(e) => e.stopPropagation()}>
                        <div className="modal-header">
                            <h3 className="modal-title">📦 Chuyển {selectedIds.size} từ vựng</h3>
                            <button className="modal-close" onClick={() => setShowMoveModal(false)}>✕</button>
                        </div>
                        <form onSubmit={handleBatchMove}>
                            <div className="form-group">
                                <label>Chọn thư mục đích</label>
                                <select
                                    className="form-input"
                                    value={targetFolderId}
                                    onChange={(e) => setTargetFolderId(e.target.value)}
                                    style={{ background: 'var(--bg-card)' }}
                                    required
                                >
                                    <option value="" disabled>-- Chọn thư mục --</option>
                                    {allFolders.map(f => (
                                        <option key={f.id} value={f.id}>{f.name}</option>
                                    ))}
                                </select>
                            </div>
                            <div className="modal-footer">
                                <button type="button" className="btn btn-secondary" onClick={() => setShowMoveModal(false)}>Hủy</button>
                                <button type="submit" className="btn btn-primary" disabled={targetFolderId === ''}>Chuyển</button>
                            </div>
                        </form>
                    </div>
                </div>
            )}

            {/* Import Excel Modal */}
            {showImportModal && (
                <div className="modal-overlay" onClick={closeImportModal}>
                    <div className="modal" onClick={(e) => e.stopPropagation()} style={{ maxWidth: 520 }}>
                        <div className="modal-header">
                            <h3 className="modal-title">📥 Import từ vựng từ Excel</h3>
                            <button className="modal-close" onClick={closeImportModal}>✕</button>
                        </div>

                        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 16 }}>
                            <p style={{ fontSize: 13, color: 'var(--text-muted)', margin: 0 }}>
                                Cần có cột <b>Word</b> và <b>Meaning</b>. Tùy chọn: <b>Part of Speech</b>, <b>Phonetic</b>
                            </p>
                            <button className="btn btn-ghost btn-sm" onClick={handleDownloadTemplate} style={{ whiteSpace: 'nowrap' }}>
                                ⬇️ Tải mẫu
                            </button>
                        </div>

                        {/* Drag & Drop zone */}
                        <div
                            onDragOver={(e) => { e.preventDefault(); setDragOver(true); }}
                            onDragLeave={() => setDragOver(false)}
                            onDrop={handleDrop}
                            onClick={() => document.getElementById('excel-file-input').click()}
                            style={{
                                border: `2px dashed ${dragOver ? 'var(--primary-light)' : 'var(--border)'}`,
                                borderRadius: 'var(--radius-md)',
                                padding: '32px 16px',
                                textAlign: 'center',
                                cursor: 'pointer',
                                background: dragOver ? 'rgba(99,102,241,0.08)' : 'transparent',
                                transition: 'all 0.2s ease',
                                marginBottom: 16
                            }}
                        >
                            <input
                                id="excel-file-input"
                                type="file"
                                accept=".xlsx"
                                onChange={handleImportFile}
                                style={{ display: 'none' }}
                            />
                            {importFile ? (
                                <div>
                                    <div style={{ fontSize: 32, marginBottom: 8 }}>📄</div>
                                    <div style={{ fontWeight: 600, color: 'var(--primary-light)' }}>{importFile.name}</div>
                                    <div style={{ fontSize: 12, color: 'var(--text-muted)', marginTop: 4 }}>
                                        {(importFile.size / 1024).toFixed(1)} KB • Bấm để chọn file khác
                                    </div>
                                </div>
                            ) : (
                                <div>
                                    <div style={{ fontSize: 40, marginBottom: 8, opacity: 0.5 }}>📁</div>
                                    <div style={{ fontWeight: 600 }}>Kéo thả file Excel vào đây</div>
                                    <div style={{ fontSize: 13, color: 'var(--text-muted)', marginTop: 4 }}>
                                        hoặc bấm để chọn file (.xlsx)
                                    </div>
                                </div>
                            )}
                        </div>

                        {/* Import result */}
                        {importResult && (
                            <div style={{
                                background: importResult.successCount > 0 ? 'rgba(16,185,129,0.1)' : 'rgba(239,68,68,0.1)',
                                border: `1px solid ${importResult.successCount > 0 ? 'rgba(16,185,129,0.3)' : 'rgba(239,68,68,0.3)'}`,
                                borderRadius: 'var(--radius-md)', padding: 16, marginBottom: 16
                            }}>
                                <div style={{ fontWeight: 700, fontSize: 15, marginBottom: 8 }}>
                                    {importResult.successCount > 0 ? '✅' : '❌'} Kết quả Import
                                </div>
                                <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr 1fr', gap: 8, marginBottom: 8 }}>
                                    <div style={{ textAlign: 'center', padding: 8, borderRadius: 'var(--radius-sm)', background: 'rgba(255,255,255,0.05)' }}>
                                        <div style={{ fontSize: 20, fontWeight: 700 }}>{importResult.totalRows}</div>
                                        <div style={{ fontSize: 11, color: 'var(--text-muted)' }}>Tổng dòng</div>
                                    </div>
                                    <div style={{ textAlign: 'center', padding: 8, borderRadius: 'var(--radius-sm)', background: 'rgba(16,185,129,0.15)' }}>
                                        <div style={{ fontSize: 20, fontWeight: 700, color: '#10b981' }}>{importResult.successCount}</div>
                                        <div style={{ fontSize: 11, color: 'var(--text-muted)' }}>Thành công</div>
                                    </div>
                                    <div style={{ textAlign: 'center', padding: 8, borderRadius: 'var(--radius-sm)', background: 'rgba(245,158,11,0.15)' }}>
                                        <div style={{ fontSize: 20, fontWeight: 700, color: '#f59e0b' }}>{importResult.skippedCount}</div>
                                        <div style={{ fontSize: 11, color: 'var(--text-muted)' }}>Bỏ qua</div>
                                    </div>
                                </div>
                                {importResult.errors && importResult.errors.length > 0 && (
                                    <details style={{ fontSize: 12 }}>
                                        <summary style={{ cursor: 'pointer', color: 'var(--text-muted)', marginBottom: 4 }}>
                                            ⚠️ Chi tiết ({importResult.errors.length} thông báo)
                                        </summary>
                                        <div style={{ maxHeight: 120, overflowY: 'auto', padding: 8, background: 'rgba(0,0,0,0.2)', borderRadius: 'var(--radius-sm)', fontSize: 11, lineHeight: 1.6 }}>
                                            {importResult.errors.map((err, i) => (
                                                <div key={i} style={{ color: 'var(--text-muted)' }}>• {err}</div>
                                            ))}
                                        </div>
                                    </details>
                                )}
                            </div>
                        )}

                        <div className="modal-footer" style={{ padding: 0 }}>
                            <button type="button" className="btn btn-secondary" onClick={closeImportModal}>Đóng</button>
                            <button
                                className="btn btn-primary"
                                onClick={handleImportSubmit}
                                disabled={!importFile || importLoading}
                                style={{ minWidth: 140 }}
                            >
                                {importLoading ? (
                                    <><span className="spinner" style={{ width: 16, height: 16, marginRight: 8 }}></span> Đang import...</>
                                ) : '📥 Bắt đầu Import'}
                            </button>
                        </div>
                    </div>
                </div>
            )}
        </div>
    );
}
