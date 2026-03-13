import { useState, useEffect } from 'react';
import { gameAPI, gameResultAPI } from '../services/api';

export default function AIComprehensionPage({ folder, gameType, onBack }) {
    const [loading, setLoading] = useState(true);
    const [content, setContent] = useState(null);
    const [error, setError] = useState('');
    const [selectedAnswers, setSelectedAnswers] = useState({});
    const [showResults, setShowResults] = useState(false);
    const [score, setScore] = useState(0);

    // AI Generation state
    const [topic, setTopic] = useState('Daily life');
    const [level, setLevel] = useState(1); // 1: Beginner, 2: Intermediate, 3: Advanced

    useEffect(() => {
        if (!content) generateContent();
    }, [folder.id]);

    const generateContent = async () => {
        setLoading(true);
        setError('');
        try {
            let data;
            if (gameType === 'listening') {
                data = await gameAPI.generateListening({
                    folderId: folder.id,
                    level,
                    topic,
                    gameSubType: 'listening',
                });
            } else {
                data = await gameAPI.generateReading({
                    folderId: folder.id,
                    level,
                    topic,
                });
            }
            setContent(data);
            setSelectedAnswers({});
            setShowResults(false);
            setScore(0);
        } catch (err) {
            setError(err.message || "Lỗi khi gọi AI. Có thể vượt quá giới hạn hoặc thư mục trống.");
        } finally {
            setLoading(false);
        }
    };

    const handleSelectOption = (questionId, optionId) => {
        if (showResults) return;
        setSelectedAnswers(prev => ({ ...prev, [questionId]: optionId }));
    };

    const handleSubmit = async () => {
        if (Object.keys(selectedAnswers).length < content.questions.length) {
            alert("Vui lòng trả lời tất cả câu hỏi");
            return;
        }
        setShowResults(true);

        let correct = 0;
        let wrongAnswers = [];

        content.questions.forEach((q) => {
            if (selectedAnswers[q.id] === q.correctOptionId) {
                correct++;
            } else {
                wrongAnswers.push(q.id);
            }
        });
        setScore(correct);

        // Update Game Result
        if (content.gameResultId) {
            try {
                await gameResultAPI.update(content.gameResultId, {
                    correctCount: correct,
                    wrongCount: content.questions.length - correct,
                    wrongAnswers: JSON.stringify(wrongAnswers), // currently we track question IDs for comprehension
                });
            } catch (err) {
                console.error("Lỗi lưu game result", err);
            }
        }
    };

    if (error) {
        return (
            <div className="fade-in">
                <div className="results-card">
                    <div className="results-icon">❌</div>
                    <h2>Lỗi tích hợp AI</h2>
                    <p>{error}</p>
                    <button className="btn btn-primary" onClick={onBack}>← Quay lại</button>
                    <button className="btn btn-secondary" onClick={generateContent} style={{ marginLeft: 12 }}>
                        🔄 Thử Lại
                    </button>
                </div>
            </div>
        );
    }

    if (loading) {
        return (
            <div className="fade-in loading" style={{ flexDirection: 'column', gap: 24, textAlign: 'center', minHeight: '60vh' }}>
                <div className="spinner" style={{ width: 48, height: 48, borderWidth: 4 }}></div>
                <h3 style={{ fontSize: 24 }}>AI đang chạy... 🧠</h3>
                <p style={{ color: 'var(--text-muted)' }}>
                    Groq đang phân tích từ vựng trong mục <strong>{folder.name}</strong><br />
                    để tạo riêng cho bạn một phần thi {gameType === 'listening' ? 'Luyện Nghe' : 'Luyện Đọc'}.<br />
                    Vui lòng chờ khoảng 5-10 giây...
                </p>
            </div>
        );
    }

    return (
        <div className="fade-in">
            <div className="breadcrumb"><a onClick={onBack}>← Quay lại trang chủ</a></div>

            <div className="page-header" style={{ marginBottom: 24 }}>
                <h1 className="page-title" style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
                    {gameType === 'listening' ? '🎧 Bài Nghe AI Tạo' : '📖 Bài Đọc AI Tạo'}
                    <span style={{ fontSize: 13, background: 'var(--primary-glow)', color: 'var(--primary-light)', padding: '4px 12px', borderRadius: 20 }}>
                        Được sinh tự động từ thư mục {folder.name}
                    </span>
                </h1>
                <div className="page-actions" style={{ gap: 8 }}>
                    <button className="btn btn-ghost btn-sm" onClick={() => generateContent()} disabled={loading}>
                        🔄 Tạo bài mới
                    </button>
                </div>
            </div>

            <div style={{ display: 'flex', gap: 24, flexWrap: 'wrap' }}>
                {/* Content Section */}
                <div style={{ flex: '1 1 400px', minWidth: 0 }}>
                    <div style={{
                        background: 'var(--bg-card)',
                        border: '1px solid var(--border)',
                        borderRadius: 'var(--radius-lg)',
                        padding: 24,
                        marginBottom: 24,
                        position: 'sticky',
                        top: 24
                    }}>
                        <h2 style={{ fontSize: 20, marginBottom: 16, color: 'var(--text-primary)' }}>
                            {content.title}
                        </h2>

                        {gameType === 'listening' ? (
                            <div style={{ fontSize: 16, lineHeight: 1.8, color: 'var(--text-secondary)' }}>
                                {content.conversation.map((line, idx) => (
                                    <p key={idx} style={{ marginBottom: 12 }}>
                                        <strong style={{ color: 'var(--primary-light)' }}>{line.speaker}:</strong> {line.text}
                                    </p>
                                ))}
                            </div>
                        ) : (
                            <div style={{ fontSize: 16, lineHeight: 1.8, color: 'var(--text-secondary)', textAlign: 'justify' }}>
                                {content.passage}
                            </div>
                        )}
                    </div>
                </div>

                {/* Questions Section */}
                <div style={{ flex: '1 1 500px', minWidth: 0 }}>
                    {content.questions.map((q, qIndex) => (
                        <div key={q.id} style={{
                            background: 'var(--bg-secondary)',
                            border: '1px solid var(--border)',
                            borderRadius: 'var(--radius-lg)',
                            padding: 24,
                            marginBottom: 20
                        }}>
                            <h3 style={{ fontSize: 16, marginBottom: 16 }}>
                                Câu {qIndex + 1}: {q.questionText}
                            </h3>
                            <div style={{ display: 'flex', flexDirection: 'column', gap: 12 }}>
                                {q.options.map((opt) => {
                                    let bg = 'var(--bg-card)';
                                    let borderColor = 'var(--border)';

                                    if (selectedAnswers[q.id] === opt.id) {
                                        bg = 'var(--primary-glow)';
                                        borderColor = 'var(--primary)';
                                    }

                                    if (showResults) {
                                        if (opt.id === q.correctOptionId) {
                                            bg = 'var(--success-light)';
                                            borderColor = 'var(--success)';
                                        } else if (selectedAnswers[q.id] === opt.id && opt.id !== q.correctOptionId) {
                                            bg = 'var(--danger-light)';
                                            borderColor = 'var(--danger)';
                                        }
                                    }

                                    return (
                                        <div
                                            key={opt.id}
                                            onClick={() => handleSelectOption(q.id, opt.id)}
                                            style={{
                                                padding: '16px 20px',
                                                background: bg,
                                                border: `2px solid ${borderColor}`,
                                                borderRadius: 'var(--radius-md)',
                                                cursor: showResults ? 'default' : 'pointer',
                                                transition: 'all 0.2s',
                                                opacity: (showResults && opt.id !== q.correctOptionId && selectedAnswers[q.id] !== opt.id) ? 0.5 : 1
                                            }}
                                        >
                                            {opt.optionLetter}. {opt.optionText}
                                        </div>
                                    )
                                })}
                            </div>
                            {showResults && (
                                <div style={{
                                    marginTop: 16,
                                    padding: '12px 16px',
                                    borderRadius: 8,
                                    background: selectedAnswers[q.id] === q.correctOptionId ? 'var(--success-light)' : 'var(--danger-light)',
                                    color: selectedAnswers[q.id] === q.correctOptionId ? 'var(--success)' : 'var(--danger)'
                                }}>
                                    <strong>Giải thích: </strong> {q.explanation}
                                </div>
                            )}
                        </div>
                    ))}

                    <div style={{ textAlign: 'center', marginBottom: 40, marginTop: 32 }}>
                        {!showResults ? (
                            <button
                                className="btn btn-primary"
                                style={{ padding: '16px 32px', fontSize: 18, width: '100%' }}
                                onClick={handleSubmit}
                            >
                                🏁 Nộp bài
                            </button>
                        ) : (
                            <div className="fade-in" style={{
                                background: 'var(--bg-card)',
                                padding: 32,
                                borderRadius: 'var(--radius-xl)',
                                border: '2px solid var(--primary-light)',
                            }}>
                                <h3 style={{ fontSize: 24, marginBottom: 8 }}>Kết Quả 🏆</h3>
                                <p style={{ fontSize: 48, fontWeight: 800, color: 'var(--primary-light)', margin: '16px 0' }}>
                                    {score} / {content.questions.length}
                                </p>
                                <button className="btn btn-secondary" onClick={() => generateContent()} style={{ marginTop: 16 }}>
                                    🔄 Làm bài khác cùng thư mục
                                </button>
                            </div>
                        )}
                    </div>
                </div>
            </div>
        </div>
    );
}
