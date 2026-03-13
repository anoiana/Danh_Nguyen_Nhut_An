import { useState, useEffect } from 'react';
import { gameAPI, gameResultAPI } from '../services/api';
import { useAuth } from '../context/AuthContext';

export default function TypingPage({ vocabs, folderId, onBack }) { // Use folderId if provided
    const { user } = useAuth();
    const [currentIndex, setCurrentIndex] = useState(0);
    const [userInput, setUserInput] = useState('');
    const [score, setScore] = useState(0);
    const [showResult, setShowResult] = useState(false);
    const [isCorrect, setIsCorrect] = useState(false);
    const [completed, setCompleted] = useState(false);

    // Tracking for backend
    const [wrongAnswers, setWrongAnswers] = useState([]);
    const [gameResultId, setGameResultId] = useState(null);

    const total = vocabs.length;
    const current = vocabs[currentIndex];

    // Initial game session
    useEffect(() => {
        const initGame = async () => {
            try {
                const session = await gameAPI.startGame({
                    userId: user.userId,
                    folderId: folderId || 1, // Fallback if missing
                    gameType: 'writing' // usually typing maps to writing/quiz, choose an appropriate string
                });
                if (session && session.gameResultId) {
                    setGameResultId(session.gameResultId);
                }
            } catch (err) {
                console.error("Lỗi khi tạo game session:", err);
            }
        };
        initGame();
    }, [user.userId, folderId]);

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

    const handleCheck = () => {
        if (!userInput.trim()) return;
        const correct = userInput.trim().toLowerCase() === current.word.toLowerCase();
        setIsCorrect(correct);
        setShowResult(true);
        if (correct) {
            setScore((s) => s + 1);
        } else {
            setWrongAnswers((prev) => [...prev, current]);
        }
    };

    const handleNext = async () => {
        setUserInput('');
        setShowResult(false);
        setIsCorrect(false);
        if (currentIndex < total - 1) {
            setCurrentIndex((i) => i + 1);
        } else {
            setCompleted(true);

            // Gửi dữ liệu về backend khi hoàn thành
            if (gameResultId) {
                try {
                    await gameResultAPI.update(gameResultId, {
                        correctCount: score + (isCorrect ? 1 : 0),
                        wrongCount: total - (score + (isCorrect ? 1 : 0)),
                        wrongAnswers: JSON.stringify(wrongAnswers.map(w => w.id))
                    });
                } catch (err) {
                    console.error("Lỗi khi lưu kết quả:", err);
                }
            }
        }
    };

    const handleKeyDown = (e) => {
        if (e.key === 'Enter') {
            if (showResult) handleNext();
            else handleCheck();
        }
    };

    if (completed) {
        const percentage = Math.round((score / total) * 100);
        return (
            <div className="fade-in">
                <div className="results-card">
                    <div className="results-icon">{percentage >= 80 ? '🏆' : percentage >= 50 ? '👍' : '💪'}</div>
                    <h2>{percentage >= 80 ? 'Xuất sắc!' : percentage >= 50 ? 'Tốt lắm!' : 'Cần cố gắng thêm!'}</h2>
                    <div className="score">{score}/{total}</div>
                    <p>Bạn gõ đúng {percentage}% từ vựng</p>

                    {wrongAnswers.length > 0 && (
                        <div style={{ textAlign: 'left', marginTop: 20 }}>
                            <p style={{ fontWeight: 600, marginBottom: 8, color: 'var(--text-primary)' }}>
                                Từ sai cần chú ý:
                            </p>
                            {wrongAnswers.map((w) => (
                                <div key={w.id} style={{
                                    padding: '8px 12px',
                                    background: 'var(--danger-light)',
                                    borderRadius: 8,
                                    marginBottom: 6,
                                    fontSize: 14
                                }}>
                                    <strong style={{ color: 'var(--primary-light)' }}>{w.word}</strong> — {getMeaning(w)}
                                </div>
                            ))}
                        </div>
                    )}
                    <div style={{ display: 'flex', gap: 12, justifyContent: 'center', marginTop: 24 }}>
                        <button className="btn btn-secondary" onClick={onBack}>← Quay lại</button>
                        <button className="btn btn-primary" onClick={() => {
                            setCurrentIndex(0);
                            setScore(0);
                            setUserInput('');
                            setShowResult(false);
                            setIsCorrect(false);
                            setCompleted(false);
                            setWrongAnswers([]);
                        }}>🔄 Chơi lại</button>
                    </div>
                </div>
            </div>
        );
    }

    return (
        <div className="fade-in">
            <div className="breadcrumb">
                <a onClick={onBack}>← Quay lại</a>
            </div>

            <div className="quiz-container">
                <div className="flashcard-progress" style={{ justifyContent: 'center', marginBottom: 24 }}>
                    <span>Câu {currentIndex + 1} / {total}</span>
                    <div className="progress-bar" style={{ width: 200 }}>
                        <div className="progress-fill" style={{ width: `${((currentIndex + 1) / total) * 100}%` }}></div>
                    </div>
                    <span>✅ {score}</span>
                </div>

                <div className="quiz-question">
                    <p style={{ fontSize: 14, color: 'var(--text-muted)', marginBottom: 12 }}>Gõ từ tiếng Anh có nghĩa:</p>
                    <h2 style={{ fontSize: 22, background: 'none', WebkitTextFillColor: 'var(--text-primary)' }}>
                        {getMeaning(current)}
                    </h2>
                    {current.phoneticText && (
                        <p style={{ marginTop: 8, color: 'var(--text-muted)', fontStyle: 'italic' }}>
                            Gợi ý: {current.phoneticText}
                        </p>
                    )}
                </div>

                <div style={{ marginBottom: 20 }}>
                    <input
                        className="form-input"
                        placeholder="Gõ từ tiếng Anh..."
                        value={userInput}
                        onChange={(e) => setUserInput(e.target.value)}
                        onKeyDown={handleKeyDown}
                        disabled={showResult}
                        autoFocus
                        style={{
                            fontSize: 20,
                            textAlign: 'center',
                            padding: 18,
                            borderColor: showResult
                                ? isCorrect
                                    ? 'var(--success)'
                                    : 'var(--danger)'
                                : undefined,
                        }}
                    />
                </div>

                {showResult && (
                    <div style={{
                        padding: 16,
                        borderRadius: 12,
                        marginBottom: 20,
                        background: isCorrect ? 'var(--success-light)' : 'var(--danger-light)',
                        border: `1px solid ${isCorrect ? 'rgba(16,185,129,0.3)' : 'rgba(239,68,68,0.3)'}`,
                        textAlign: 'center',
                    }}>
                        <p style={{ fontWeight: 700, fontSize: 16, marginBottom: 4 }}>
                            {isCorrect ? '✅ Chính xác!' : '❌ Chưa đúng!'}
                        </p>
                        {!isCorrect && (
                            <p style={{ fontSize: 14 }}>
                                Đáp án đúng: <strong style={{ color: 'var(--primary-light)' }}>{current.word}</strong>
                            </p>
                        )}
                    </div>
                )}

                <div style={{ textAlign: 'center' }}>
                    {!showResult ? (
                        <button className="btn btn-primary" onClick={handleCheck} disabled={!userInput.trim()}>
                            ✓ Kiểm tra
                        </button>
                    ) : (
                        <button className="btn btn-primary" onClick={handleNext}>
                            {currentIndex === total - 1 ? '📊 Xem kết quả' : 'Câu tiếp →'}
                        </button>
                    )}
                </div>
            </div>
        </div>
    );
}
