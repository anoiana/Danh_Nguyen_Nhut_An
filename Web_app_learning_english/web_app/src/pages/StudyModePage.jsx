import { useState } from 'react';

export default function StudyModePage({ folder, vocabs, onSelectMode, onBack }) {
    return (
        <div className="fade-in">
            <div className="breadcrumb">
                <a onClick={onBack}>📁 Thư mục</a>
                <span className="separator">›</span>
                <span>{folder.name}</span>
                <span className="separator">›</span>
                <span>Chế độ học</span>
            </div>

            <div className="page-header">
                <h1 className="page-title">🎮 Chọn chế độ học</h1>
            </div>

            <div className="study-modes">
                <div className="study-mode-card" onClick={() => onSelectMode('flashcard')}>
                    <div className="mode-icon">🃏</div>
                    <div className="mode-title">Flashcard</div>
                    <div className="mode-desc">Lật thẻ để ôn từ vựng. Xem từ tiếng Anh và nghĩa tiếng Việt.</div>
                </div>

                <div className="study-mode-card" onClick={() => onSelectMode('quiz')}>
                    <div className="mode-icon">❓</div>
                    <div className="mode-title">Trắc nghiệm</div>
                    <div className="mode-desc">Chọn đáp án đúng cho mỗi từ vựng. Kiểm tra kiến thức của bạn.</div>
                </div>

                <div className="study-mode-card" onClick={() => onSelectMode('typing')}>
                    <div className="mode-icon">⌨️</div>
                    <div className="mode-title">Gõ từ</div>
                    <div className="mode-desc">Nhìn nghĩa và gõ lại từ tiếng Anh. Luyện nhớ chính tả.</div>
                </div>

                <div className="study-mode-card" onClick={() => onSelectMode('sentence')} style={{ borderColor: 'var(--primary)' }}>
                    <div className="mode-icon">✍️</div>
                    <div className="mode-title">Luyện Viết (AI)</div>
                    <div className="mode-desc">Đặt câu với từ vựng. Trí tuệ nhân tạo sẽ kiểm tra ngữ pháp giúp bạn.</div>
                </div>

                <div className="study-mode-card" onClick={() => onSelectMode('listening')} style={{ borderColor: 'var(--success)' }}>
                    <div className="mode-icon">🎧</div>
                    <div className="mode-title">Luyện Nghe (AI)</div>
                    <div className="mode-desc">Nghe đoạn hội thoại/đoạn văn chứa từ vựng do AI tạo ra.</div>
                </div>

                <div className="study-mode-card" onClick={() => onSelectMode('reading')} style={{ borderColor: 'var(--warning)' }}>
                    <div className="mode-icon">📖</div>
                    <div className="mode-title">Luyện Đọc (AI)</div>
                    <div className="mode-desc">Đọc câu chuyện chứa từ vựng do AI kể và trả lời câu hỏi.</div>
                </div>
            </div>
        </div>
    );
}
