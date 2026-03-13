import { useState, useEffect } from 'react';
import { gameAPI, gameResultAPI } from '../services/api';
import { useAuth } from '../context/AuthContext';

export default function SentenceGamePage({ folder, vocabs, onBack }) {
    const { user } = useAuth();
    const [currentIndex, setCurrentIndex] = useState(0);
    const [answer, setAnswer] = useState('');
    const [analyzing, setAnalyzing] = useState(false);
    const [feedback, setFeedback] = useState(null);
    const [score, setScore] = useState(0);
    const [completed, setCompleted] = useState(false);
    const [gameResultId, setGameResultId] = useState(null);
    const [wrongAnswerIds, setWrongAnswerIds] = useState([]);

    const total = vocabs.length;
    const currentVocab = vocabs[currentIndex];

    // Start a game session on backend first
    useEffect(() => {
        const initGame = async () => {
            try {
                const session = await gameAPI.startGame({
                    userId: user.userId,
                    folderId: folder.id,
                    gameType: 'sentence',
                });
                if (session && session.gameResultId) {
                    setGameResultId(session.gameResultId);
                }
            } catch (err) {
                console.error("Lỗi khi tạo game session:", err);
            }
        };
        initGame();
    }, [user.userId, folder.id]);

    const handleCheck = async () => {
        if (!answer.trim()) return;
        setAnalyzing(true);
        setFeedback(null);
        try {
            const res = await gameAPI.checkSentence({
                vocabularyId: currentVocab.id,
                userAnswer: answer,
            });
            setFeedback(res);
            if (res.correct) {
                setScore(s => s + 1);
            } else {
                setWrongAnswerIds(prev => [...prev, currentVocab.id]);
            }
        } catch (err) {
            setFeedback({ correct: false, feedback: err.message || 'Lỗi kết nối AI', correctedSentence: null });
            setWrongAnswerIds(prev => [...prev, currentVocab.id]);
        } finally {
            setAnalyzing(false);
        }
    };

    const handleNext = async () => {
        setAnswer('');
        setFeedback(null);
        if (currentIndex < total - 1) {
            setCurrentIndex(i => i + 1);
        } else {
            // Hoàn thành game -> update GameResult trên server
            handleFinishGame();
        }
    };

    const handleFinishGame = async () => {
        setCompleted(true);
        if (gameResultId) {
            try {
                await gameResultAPI.update(gameResultId, {
                    correctCount: score,
                    wrongCount: total - score,
                    wrongAnswers: JSON.stringify(wrongAnswerIds),
                });
            } catch (err) {
                console.error("Lỗi khi lưu kết quả:", err);
            }
        }
    };

    if (completed) {
        const percentage = Math.round((score / total) * 100);
        return (
            <div className="fade-in">
                <div className="results-card">
                    <div className="results-icon">📝</div>
                    <h2>Hoàn thành Luyện Viết!</h2>
                    <div className="score">{score}/{total}</div>
                    <p>AI đã kiểm tra {total} câu của bạn</p>
                    <div style={{ display: 'flex', gap: 12, justifyContent: 'center', marginTop: 24 }}>
                        <button className="btn btn-secondary" onClick={onBack}>← Quay lại trang chủ</button>
                    </div>
                </div>
            </div>
        );
    }

    return (
        <div className="fade-in">
            <div className="breadcrumb"><a onClick={onBack}>← Quay lại</a></div>

            <div className="quiz-container">
                <div className="flashcard-progress" style={{ justifyContent: 'center', marginBottom: 24 }}>
                    <span>Câu {currentIndex + 1} / {total}</span>
                    <div className="progress-bar" style={{ width: 200 }}>
                        <div className="progress-fill" style={{ width: `${((currentIndex + 1) / total) * 100}%` }}></div>
                    </div>
                    <span>✅ {score}</span>
                </div>

                <div className="quiz-question">
                    <h2>{currentVocab.word}</h2>
                    {currentVocab.userDefinedMeaning && <p>Nghĩa: {currentVocab.userDefinedMeaning}</p>}
                    <p style={{ marginTop: 12, color: 'var(--text-accent)' }}>
                        ✍️ Hãy đặt một câu tiếng Anh có chứa từ này:
                    </p>
                </div>

                <div style={{ marginBottom: 20 }}>
                    <textarea
                        className="form-input"
                        placeholder="Type your sentence here..."
                        value={answer}
                        onChange={(e) => setAnswer(e.target.value)}
                        disabled={analyzing || feedback}
                        style={{ minHeight: 120, fontSize: 16, resize: 'vertical' }}
                    />
                </div>

                {feedback && (
                    <div className="fade-in" style={{
                        padding: 20,
                        borderRadius: 12,
                        marginBottom: 20,
                        background: feedback.correct ? 'var(--success-light)' : 'var(--danger-light)',
                        border: `1px solid ${feedback.correct ? 'var(--success)' : 'var(--danger)'}`,
                    }}>
                        <h3 style={{
                            color: feedback.correct ? 'var(--success)' : 'var(--danger)',
                            marginBottom: 8,
                            fontSize: 18
                        }}>
                            {feedback.correct ? '✅ Câu chuẩn ngữ pháp!' : '❌ Câu cần chỉnh sửa'}
                        </h3>
                        <p style={{ lineHeight: 1.5, marginBottom: feedback.correctedSentence ? 12 : 0 }}>
                            <strong>Nhận xét AI:</strong> {feedback.feedback}
                        </p>
                        {feedback.correctedSentence && (
                            <div style={{
                                background: 'rgba(0,0,0,0.2)', padding: 12, borderRadius: 8,
                                borderLeft: '4px solid var(--primary-light)'
                            }}>
                                <span style={{ color: 'var(--text-muted)', fontSize: 13 }}>Câu gợi ý của AI:</span><br />
                                <strong>{feedback.correctedSentence}</strong>
                            </div>
                        )}
                    </div>
                )}

                <div style={{ textAlign: 'center' }}>
                    {!feedback ? (
                        <button className="btn btn-primary" onClick={handleCheck} disabled={!answer.trim() || analyzing}>
                            {analyzing ? <span className="spinner" style={{ width: 16, height: 16, display: 'inline-block' }} /> : '🔍 Kiểm tra với AI'}
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
