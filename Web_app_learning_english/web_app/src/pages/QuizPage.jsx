import { useState, useMemo, useEffect } from 'react';
import { gameAPI, gameResultAPI } from '../services/api';
import { useAuth } from '../context/AuthContext';

export default function QuizPage({ vocabs, folderId, onBack }) { // pass folderId if possible
    const { user } = useAuth();
    const [currentIndex, setCurrentIndex] = useState(0);
    const [score, setScore] = useState(0);
    const [selectedAnswer, setSelectedAnswer] = useState(null);
    const [showResult, setShowResult] = useState(false);
    const [completed, setCompleted] = useState(false);
    const [wrongAnswers, setWrongAnswers] = useState([]);
    const [gameResultId, setGameResultId] = useState(null);

    // Bắt đầu 1 game session trên Server
    useEffect(() => {
        const initGame = async () => {
            try {
                const session = await gameAPI.startGame({
                    userId: user.userId,
                    folderId: folderId || 1, // Fallback if not injected
                    gameType: 'quiz'
                });
                if (session && session.gameResultId) {
                    setGameResultId(session.gameResultId);
                }
            } catch (err) {
                console.error("Lỗi khi tạo game quiz session:", err);
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

    // Generate quiz questions from vocabulary
    const questions = useMemo(() => {
        if (vocabs.length < 2) return [];
        return vocabs.map((vocab) => {
            const correctAnswer = getMeaning(vocab);
            // Get 3 random wrong answers
            const otherVocabs = vocabs.filter((v) => v.id !== vocab.id);
            const shuffled = [...otherVocabs].sort(() => Math.random() - 0.5);
            const wrongOptions = shuffled.slice(0, Math.min(3, shuffled.length)).map(getMeaning);
            // Combine and shuffle
            const options = [...wrongOptions, correctAnswer].sort(() => Math.random() - 0.5);
            return { vocab, correctAnswer, options };
        });
    }, [vocabs]);

    if (vocabs.length < 2) {
        return (
            <div className="fade-in">
                <div className="results-card">
                    <div className="results-icon">⚠️</div>
                    <h2>Cần ít nhất 2 từ vựng</h2>
                    <p>Hãy thêm nhiều từ vựng hơn để chơi quiz</p>
                    <button className="btn btn-primary" onClick={onBack}>← Quay lại</button>
                </div>
            </div>
        );
    }

    const current = questions[currentIndex];
    const total = questions.length;

    const handleSelect = (option) => {
        if (showResult) return;
        setSelectedAnswer(option);
        setShowResult(true);
        if (option === current.correctAnswer) {
            setScore((s) => s + 1);
        } else {
            setWrongAnswers((w) => [...w, current.vocab]);
        }
    };

    const handleNext = async () => {
        setSelectedAnswer(null);
        setShowResult(false);
        if (currentIndex < total - 1) {
            setCurrentIndex((i) => i + 1);
        } else {
            setCompleted(true);
            // Gửi dữ liệu về backend khi hoàn thành
            if (gameResultId) {
                try {
                    await gameResultAPI.update(gameResultId, {
                        correctCount: score + (selectedAnswer === current.correctAnswer ? 1 : 0),
                        wrongCount: total - (score + (selectedAnswer === current.correctAnswer ? 1 : 0)),
                        wrongAnswers: JSON.stringify(wrongAnswers.map(w => w.id))
                    });
                } catch (err) {
                    console.error("Lỗi khi lưu kết quả:", err);
                }
            }
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
                    <p>Bạn trả lời đúng {percentage}% câu hỏi</p>
                    {wrongAnswers.length > 0 && (
                        <div style={{ textAlign: 'left', marginTop: 20 }}>
                            <p style={{ fontWeight: 600, marginBottom: 8, color: 'var(--text-primary)' }}>
                                Từ cần ôn lại:
                            </p>
                            {wrongAnswers.map((w) => (
                                <div key={w.id} style={{
                                    padding: '8px 12px',
                                    background: 'var(--danger-light)',
                                    borderRadius: 8,
                                    marginBottom: 6,
                                    fontSize: 14
                                }}>
                                    <strong>{w.word}</strong> — {getMeaning(w)}
                                </div>
                            ))}
                        </div>
                    )}
                    <div style={{ display: 'flex', gap: 12, justifyContent: 'center', marginTop: 24 }}>
                        <button className="btn btn-secondary" onClick={onBack}>← Quay lại</button>
                        <button className="btn btn-primary" onClick={() => {
                            setCurrentIndex(0);
                            setScore(0);
                            setSelectedAnswer(null);
                            setShowResult(false);
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
                    <h2>{current.vocab.word}</h2>
                    {current.vocab.phoneticText && <p>{current.vocab.phoneticText}</p>}
                    <p style={{ marginTop: 8 }}>Chọn nghĩa đúng:</p>
                </div>

                <div className="quiz-options">
                    {current.options.map((option, idx) => {
                        let className = 'quiz-option';
                        if (showResult) {
                            className += ' disabled';
                            if (option === current.correctAnswer) className += ' correct';
                            else if (option === selectedAnswer) className += ' incorrect';
                        }
                        return (
                            <button key={idx} className={className} onClick={() => handleSelect(option)}>
                                <span style={{ marginRight: 12, fontWeight: 700, color: 'var(--text-muted)' }}>
                                    {String.fromCharCode(65 + idx)}.
                                </span>
                                {option}
                            </button>
                        );
                    })}
                </div>

                {showResult && (
                    <div style={{ textAlign: 'center', marginTop: 24 }}>
                        <button className="btn btn-primary" onClick={handleNext}>
                            {currentIndex === total - 1 ? '📊 Xem kết quả' : 'Câu tiếp →'}
                        </button>
                    </div>
                )}
            </div>
        </div>
    );
}
