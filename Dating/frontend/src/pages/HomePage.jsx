import React, { useEffect } from 'react';
import { useSearchParams, useNavigate } from 'react-router-dom';
import { useAuth } from '../features/auth/hooks/useAuth';
import LoginForm from '../features/auth/components/LoginForm';
import MatchFeed from '../features/matching/components/MatchFeed';
import MatchesList from '../features/matching/components/MatchesList';
import ProfileEditor from '../features/auth/components/ProfileEditor';
import BookingsList from '../features/matching/components/BookingsList';
import OnboardingFlow from '../features/auth/components/OnboardingFlow';
import { useNotification } from '../context/NotificationContext';
import GlobalMatchPopup from '../components/layout/GlobalMatchPopup';

const HomePage = () => {
    const {
        currentUser,
        handleLogin,
        handleGoogleLogin,
        handleLogout,
        handleRegister,
        handleUpdateProfile,
        loading: authLoading,
        error: authError
    } = useAuth();
    const navigate = useNavigate();
    const { showNotification } = useNotification();

    const [searchParams, setSearchParams] = useSearchParams();
    const activeTab = searchParams.get('tab') || 'feed';

    const setActiveTab = (tab) => {
        setSearchParams({ tab });
    };

    if (!currentUser) {
        return (
            <LoginForm
                onLogin={handleLogin}
                onRegister={handleRegister}
                onGoogleLogin={handleGoogleLogin}
                loading={authLoading}
                error={authError}
            />
        );
    }

    const needsOnboarding = !currentUser.photos || currentUser.photos.split(',').length < 2;

    if (needsOnboarding) {
        return (
            <OnboardingFlow
                currentUser={currentUser}
                onUpdate={handleUpdateProfile}
                onComplete={() => {
                    navigate('/?tab=feed', { replace: true });
                    window.location.reload();
                }}
            />
        );
    }

    return (
        <main className="flex-1">
            {/* Mobile Navigation (Bottom) */}
            <div className="md:hidden fixed bottom-6 left-4 right-4 z-50 glass-card rounded-3xl p-2 flex justify-around items-center">
                {[
                    { id: 'feed', icon: '✨' },
                    { id: 'matches', icon: '❤️' },
                    { id: 'bookings', icon: '📅' },
                    { id: 'profile', icon: '👤' }
                ].map(tab => (
                    <button
                        key={tab.id}
                        onClick={() => setActiveTab(tab.id)}
                        className={`w-12 h-12 rounded-2xl flex items-center justify-center text-2xl transition-all ${activeTab === tab.id ? 'bg-gradient-to-br from-pink-500 to-purple-600 text-white shadow-lg scale-110 -translate-y-2' : 'text-gray-400'}`}
                    >
                        {tab.icon}
                    </button>
                ))}
            </div>

            {/* Content Area */}
            <div className="max-w-7xl mx-auto w-full p-6 md:p-8 pb-32 animate-fade-in">
                {activeTab === 'feed' && (
                    <div className="space-y-8">
                        <MatchFeed currentUser={currentUser} />
                    </div>
                )}

                {activeTab === 'matches' && (
                    <div className="animate-fade-in">
                        <MatchesList currentUser={currentUser} />
                    </div>
                )}

                {activeTab === 'bookings' && (
                    <div className="animate-fade-in">
                        <BookingsList currentUser={currentUser} />
                    </div>
                )}


                {activeTab === 'profile' && (
                    <div className="max-w-7xl mx-auto">
                        <ProfileEditor
                            currentUser={currentUser}
                            onUpdate={handleUpdateProfile}
                            loading={authLoading}
                            error={authError}
                        />
                    </div>
                )}
            </div>
            <GlobalMatchPopup currentUser={currentUser} />
        </main>
    );
};

export default HomePage;
