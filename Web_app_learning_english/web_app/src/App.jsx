import { useState } from 'react';
import { AuthProvider, useAuth } from './context/AuthContext';
import LoginPage from './pages/LoginPage';
import FoldersPage from './pages/FoldersPage';
import VocabularyPage from './pages/VocabularyPage';
import StudyModePage from './pages/StudyModePage';
import FlashcardPage from './pages/FlashcardPage';
import QuizPage from './pages/QuizPage';
import TypingPage from './pages/TypingPage';
import SentenceGamePage from './pages/SentenceGamePage';
import AIComprehensionPage from './pages/AIComprehensionPage';
import DictionaryPage from './pages/DictionaryPage';
import './index.css';

function AppContent() {
  const { user, logout } = useAuth();
  const [currentView, setCurrentView] = useState('folders');
  const [selectedFolder, setSelectedFolder] = useState(null);
  const [studyVocabs, setStudyVocabs] = useState([]);
  const [sidebarOpen, setSidebarOpen] = useState(false);

  if (!user) return <LoginPage />;

  const handleSelectFolder = (folder) => {
    setSelectedFolder(folder);
    setCurrentView('vocabulary');
  };

  const handleStudy = (folder, vocabs) => {
    setSelectedFolder(folder);
    setStudyVocabs(vocabs);
    setCurrentView('study-mode');
  };

  const handleSelectMode = (mode) => {
    setCurrentView(mode);
  };

  const handleBackToFolders = () => {
    setCurrentView('folders');
    setSelectedFolder(null);
    setStudyVocabs([]);
  };

  const handleBackToVocab = () => {
    setCurrentView('vocabulary');
  };

  const handleBackToStudyMode = () => {
    setCurrentView('study-mode');
  };

  const renderContent = () => {
    switch (currentView) {
      case 'folders':
        return <FoldersPage onSelectFolder={handleSelectFolder} />;
      case 'vocabulary':
        return (
          <VocabularyPage
            folder={selectedFolder}
            onBack={handleBackToFolders}
            onStudy={handleStudy}
          />
        );
      case 'dictionary':
        return <DictionaryPage />;
      case 'study-mode':
        return (
          <StudyModePage
            folder={selectedFolder}
            vocabs={studyVocabs}
            onSelectMode={handleSelectMode}
            onBack={handleBackToVocab}
          />
        );
      case 'flashcard':
        return <FlashcardPage vocabs={studyVocabs} onBack={handleBackToStudyMode} />;
      case 'quiz':
        return <QuizPage vocabs={studyVocabs} onBack={handleBackToStudyMode} />;
      case 'typing':
        return <TypingPage vocabs={studyVocabs} onBack={handleBackToStudyMode} />;
      case 'sentence':
        return <SentenceGamePage folder={selectedFolder} vocabs={studyVocabs} onBack={handleBackToStudyMode} />;
      case 'listening':
        return <AIComprehensionPage folder={selectedFolder} gameType="listening" onBack={handleBackToStudyMode} />;
      case 'reading':
        return <AIComprehensionPage folder={selectedFolder} gameType="reading" onBack={handleBackToStudyMode} />;
      default:
        return <FoldersPage onSelectFolder={handleSelectFolder} />;
    }
  };

  return (
    <div className="app-layout">
      <button className="mobile-menu-btn" onClick={() => setSidebarOpen(!sidebarOpen)}>
        {sidebarOpen ? '✕' : '☰'}
      </button>

      {/* Overlay for mobile sidebar */}
      {sidebarOpen && (
        <div
          style={{
            position: 'fixed', top: 0, left: 0, right: 0, bottom: 0,
            background: 'rgba(0,0,0,0.5)', zIndex: 99
          }}
          onClick={() => setSidebarOpen(false)}
        />
      )}

      <aside className={`sidebar ${sidebarOpen ? 'open' : ''}`}>
        <div className="sidebar-header">
          <h2>📚 VocabMaster</h2>
          <div className="user-info">
            <div className="user-avatar">
              {user.username?.charAt(0)?.toUpperCase() || 'U'}
            </div>
            <span>{user.username}</span>
          </div>
        </div>

        <nav className="sidebar-nav">
          <button
            className={`nav-item ${currentView === 'folders' ? 'active' : ''}`}
            onClick={() => { handleBackToFolders(); setSidebarOpen(false); }}
          >
            <span className="nav-icon">📁</span>
            Thư mục
          </button>

          <button
            className={`nav-item ${currentView === 'dictionary' ? 'active' : ''}`}
            onClick={() => { setCurrentView('dictionary'); setSidebarOpen(false); }}
          >
            <span className="nav-icon">📖</span>
            Từ điển
          </button>

          {selectedFolder && (
            <>
              <div style={{
                padding: '16px 16px 8px', fontSize: 11, fontWeight: 700,
                color: 'var(--text-muted)', textTransform: 'uppercase', letterSpacing: '0.5px'
              }}>
                Đang mở
              </div>
              <button
                className={`nav-item ${currentView === 'vocabulary' ? 'active' : ''}`}
                onClick={() => { setCurrentView('vocabulary'); setSidebarOpen(false); }}
              >
                <span className="nav-icon">📂</span>
                {selectedFolder.name}
              </button>
            </>
          )}

          {studyVocabs.length > 0 && (
            <button
              className={`nav-item ${['study-mode', 'flashcard', 'quiz', 'typing', 'sentence', 'listening', 'reading'].includes(currentView) ? 'active' : ''}`}
              onClick={() => { setCurrentView('study-mode'); setSidebarOpen(false); }}
            >
              <span className="nav-icon">🎮</span>
              Chế độ học
            </button>
          )}
        </nav>

        <div className="sidebar-footer">
          <button className="nav-item" onClick={logout} style={{ color: 'var(--danger)' }}>
            <span className="nav-icon">🚪</span>
            Đăng xuất
          </button>
        </div>
      </aside>

      <main className="main-content">
        {renderContent()}
      </main>
    </div>
  );
}

export default function App() {
  return (
    <AuthProvider>
      <AppContent />
    </AuthProvider>
  );
}
