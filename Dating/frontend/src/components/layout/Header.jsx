import React from 'react';
import { Link, useLocation, useNavigate, useSearchParams } from 'react-router-dom';
import ActivityCenter from '../../features/matching/components/ActivityCenter';
import { useAuth } from '../../features/auth/hooks/useAuth';
import { getDefaultAvatar } from '../../lib/constants';

const Header = () => {
    const location = useLocation();
    const navigate = useNavigate();
    const { currentUser, handleLogout } = useAuth();
    const [searchParams, setSearchParams] = useSearchParams();

    const isHomePage = location.pathname === '/';
    const activeTab = searchParams.get('tab') || 'feed';

    const tabs = [
        { id: 'feed', label: 'Explore', icon: '✨' },
        { id: 'matches', label: 'Matches', icon: '❤️' },
        { id: 'bookings', label: 'My Dates', icon: '📅' },
        { id: 'profile', label: 'Profile', icon: '👤' }
    ];

    const handleTabClick = (tabId) => {
        if (isHomePage) {
            setSearchParams({ tab: tabId });
        } else {
            navigate(`/?tab=${tabId}`);
        }
    };

    const handleLogoClick = () => {
        navigate('/');
    };

    return (
        <header className="fixed top-0 left-0 w-full z-[100] px-6 md:px-8 py-3 flex justify-between items-center bg-white/80 backdrop-blur-xl border-b border-gray-100/50 shadow-sm transition-all duration-300">
            {/* Logo */}
            <div className="flex items-center space-x-3 cursor-pointer group" onClick={handleLogoClick}>
                <div className="w-10 h-10 bg-gradient-to-br from-pink-500 to-purple-600 rounded-xl flex items-center justify-center shadow-lg shadow-pink-200/50 transform group-hover:scale-110 transition-transform">
                    <span className="text-white text-xl font-black italic">M</span>
                </div>
                <h1 className="text-2xl font-black text-[#db2777] tracking-tight">
                    MiniDating
                </h1>
            </div>

            {/* Navigation Tabs (Centered) */}
            {currentUser && (
                <div className="hidden lg:flex items-center bg-[#f8fafc] p-1 rounded-2xl border border-slate-100 shadow-inner">
                    {tabs.map(tab => (
                        <button
                            key={tab.id}
                            onClick={() => handleTabClick(tab.id)}
                            className={`px-5 py-2 rounded-xl font-bold text-[13px] transition-all duration-300 flex items-center gap-2 ${activeTab === tab.id && isHomePage
                                ? 'bg-white text-[#db2777] shadow-[0_4px_12px_rgba(0,0,0,0.08)]'
                                : 'text-slate-500 hover:text-slate-800'}`}
                        >
                            <span className="text-base">{tab.icon}</span>
                            {tab.label}
                        </button>
                    ))}
                </div>
            )}

            {/* User Actions */}
            <div className="flex items-center space-x-6">
                {currentUser ? (
                    <div className="flex items-center gap-6">
                        {/* Bell Icon */}
                        <ActivityCenter currentUser={currentUser} />

                        {/* Vertical line separator */}
                        <div className="h-10 w-[1px] bg-gray-200"></div>

                        <div className="flex items-center gap-4">
                            <div className="hidden md:block text-right">
                                <p className="text-[10px] font-black text-gray-400 uppercase tracking-[0.2em] leading-tight mb-0.5">Signed in as</p>
                                <p className="text-sm font-black text-[#1e293b] leading-tight">{currentUser.name}</p>
                            </div>
                            <div className="relative group">
                                <img
                                    src={currentUser.avatarUrl || (currentUser.photos ? currentUser.photos.split(',')[0] : null) || getDefaultAvatar(currentUser.id)}
                                    className="w-11 h-11 rounded-full border-2 border-white shadow-xl cursor-pointer hover:scale-105 transition-transform object-cover"
                                    alt="Profile"
                                />
                                {/* Dropdown menu */}
                                <div className="absolute top-full right-0 pt-3 w-56 opacity-0 translate-y-2 pointer-events-none group-hover:opacity-100 group-hover:translate-y-0 group-hover:pointer-events-auto transition-all z-[100] origin-top-right">
                                    <div className="bg-white rounded-2xl shadow-2xl border border-gray-100 p-2 overflow-hidden">
                                        <div className="p-3 border-b border-gray-50 mb-1">
                                            <p className="text-xs font-bold text-gray-400 uppercase tracking-widest">Account Settings</p>
                                        </div>
                                        <button
                                            onClick={() => navigate('/profile/' + currentUser.id)}
                                            className="w-full text-left p-3 hover:bg-gray-50 rounded-xl font-bold text-gray-600 text-sm flex items-center gap-3 transition-colors"
                                        >
                                            <span className="text-lg">👤</span> View My Profile
                                        </button>
                                        <button
                                            onClick={handleLogout}
                                            className="w-full text-left p-3 hover:bg-red-50 rounded-xl font-bold text-red-500 text-sm flex items-center gap-3 transition-colors"
                                        >
                                            <span className="text-lg">🚪</span> Logout
                                        </button>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>
                ) : (
                    <button
                        onClick={() => navigate('/')}
                        className="bg-gradient-to-r from-pink-500 to-purple-600 text-white px-8 py-3 rounded-2xl font-black text-xs uppercase tracking-widest shadow-xl shadow-pink-200 hover:shadow-2xl hover:scale-105 transition-all"
                    >
                        Login
                    </button>
                )}
            </div>
        </header>
    );
};

export default Header;
