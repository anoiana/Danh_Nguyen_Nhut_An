import React, { useEffect } from 'react';
import { BrowserRouter as Router, Routes, Route } from 'react-router-dom';
import HomePage from './pages/HomePage';
import ProfileDetailsPage from './pages/ProfileDetailsPage';
import PaymentResult from './pages/PaymentResult';
import { NotificationProvider } from './context/NotificationContext';
import { Toaster } from 'react-hot-toast';
import Header from './components/layout/Header';
import Footer from './components/layout/Footer';

import { AuthProvider } from './features/auth/context/AuthContext';
import { LoadingProvider, useLoading } from './context/LoadingContext';

import ErrorBoundary from './components/common/ErrorBoundary';

const AppContent = () => {
    const { showLoading, hideLoading } = useLoading();

    useEffect(() => {
        showLoading();
        const timer = setTimeout(() => {
            hideLoading();
        }, 1500);
        return () => clearTimeout(timer);
    }, []);

    return (
        <ErrorBoundary>
            <div className="min-h-screen flex flex-col relative">
                {/* Background decorative circles */}
                <div className="fixed -top-[10%] -left-[10%] w-[40%] h-[40%] bg-pink-200/30 rounded-full blur-[120px] -z-10 animate-pulse-soft"></div>
                <div className="fixed -bottom-[10%] -right-[10%] w-[40%] h-[40%] bg-purple-200/30 rounded-full blur-[120px] -z-10 animate-float"></div>

                {/* Common Header */}
                <Header />

                {/* Main Content Area with padding for fixed header */}
                <div className="flex-1 pt-[72px]">
                    <Routes>
                        <Route path="/" element={<HomePage />} />
                        <Route path="/profile/:id" element={<ProfileDetailsPage />} />
                        <Route path="/payment-result" element={<PaymentResult />} />
                    </Routes>
                </div>

                {/* Common Footer */}
                <Footer />

                <Toaster
                    position="bottom-right"
                    containerStyle={{
                        zIndex: 99999, // Ensure it's above modals (which are 9999)
                    }}
                    toastOptions={{
                        duration: 5000,
                        className: 'rounded-2xl shadow-[0_20px_50px_rgba(0,0,0,0.15)] border border-slate-100',
                        style: {
                            padding: '16px 24px',
                            color: '#1e293b',
                            background: '#ffffff', // Solid background for clarity over blurs
                            fontSize: '14px',
                            fontWeight: '600',
                            maxWidth: '400px',
                        },
                        success: {
                            iconTheme: {
                                primary: '#10b981',
                                secondary: '#fff',
                            },
                        },
                        error: {
                            iconTheme: {
                                primary: '#ef4444',
                                secondary: '#fff',
                            },
                        },
                    }}
                />
            </div>
        </ErrorBoundary>
    );
};

function App() {
    return (
        <Router>
            <AuthProvider>
                <LoadingProvider>
                    <NotificationProvider>
                        <AppContent />
                    </NotificationProvider>
                </LoadingProvider>
            </AuthProvider>
        </Router>
    );
}

export default App
