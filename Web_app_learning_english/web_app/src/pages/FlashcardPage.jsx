import { useState } from 'react';

export default function FlashcardPage({ vocabs, onBack }) {
    const [currentIndex, setCurrentIndex] = useState(0);
    const [flipped, setFlipped] = useState(false);
    const [completed, setCompleted] = useState(false);

    const total = vocabs.length;
    const current = vocabs[currentIndex];

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

    const handleNext = () => {
        setFlipped(false);
        if (currentIndex < total - 1) {
            setTimeout(() => setCurrentIndex(i => i + 1), 200);
        } else {
            setCompleted(true);
        }
    };

    const handlePrev = () => {
        if (currentIndex > 0) {
            setFlipped(false);
            setTimeout(() => setCurrentIndex(i => i - 1), 200);
        }
    };

    const handleRestart = () => {
        setCurrentIndex(0);
        setFlipped(false);
        setCompleted(false);
    };

    if (completed) {
        return (
            <div className="fade-in">
                <div className="results-card">
                    <div className="results-icon">🎉</div>
                    <h2>Hoàn thành!</h2>
                    <div className="score">{total}/{total}</div>
                    <p>Bạn đã xem qua tất cả {total} từ vựng</p>
                    <div style={{ display: 'flex', gap: 12, justifyContent: 'center' }}>
                        <button className="btn btn-secondary" onClick={onBack}>← Quay lại</button>
                        <button className="btn btn-primary" onClick={handleRestart}>🔄 Học lại</button>
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

            <div className="flashcard-container">
                <div className="flashcard-progress">
                    <span>{currentIndex + 1} / {total}</span>
                    <div className="progress-bar">
                        <div className="progress-fill" style={{ width: `${((currentIndex + 1) / total) * 100}%` }}></div>
                    </div>
                </div>

                <div className={`flashcard ${flipped ? 'flipped' : ''}`} onClick={() => setFlipped(!flipped)}>
                    <div className="flashcard-inner">
                        <div className="flashcard-front">
                            <div className="flashcard-word">{current.word}</div>
                            {current.phoneticText && (
                                <div className="flashcard-hint" style={{ marginTop: 8 }}>
                                    {current.phoneticText}
                                </div>
                            )}
                            <div className="flashcard-hint">Nhấn để lật thẻ</div>
                        </div>
                        <div className="flashcard-back">
                            {getPartOfSpeech(current) && (
                                <span className="pos" style={{ marginBottom: 12 }}>{getPartOfSpeech(current)}</span>
                            )}
                            <div className="flashcard-definition">{getMeaning(current)}</div>
                        </div>
                    </div>
                </div>

                {current.audioUrl && (
                    <button
                        className="btn btn-secondary"
                        onClick={(e) => { e.stopPropagation(); new Audio(current.audioUrl).play(); }}
                    >
                        🔊 Phát âm
                    </button>
                )}

                <div className="flashcard-controls">
                    <button
                        className="btn btn-secondary"
                        onClick={handlePrev}
                        disabled={currentIndex === 0}
                    >
                        ← Trước
                    </button>
                    <button className="btn btn-primary" onClick={handleNext}>
                        {currentIndex === total - 1 ? '✅ Hoàn thành' : 'Tiếp →'}
                    </button>
                </div>
            </div>
        </div>
    );
}
