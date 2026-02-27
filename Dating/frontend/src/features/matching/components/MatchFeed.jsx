import React, { useEffect, useState, useMemo, useCallback } from 'react';
import { useFeed } from '../hooks/useFeed';
import { useWebSocket } from '../../../hooks/useWebSocket';
import { useNotification } from '../../../context/NotificationContext';
import SkeletonCard from './SkeletonCard';
import FeedCard from './FeedCard';

const MatchFeed = ({ currentUser }) => {
    const [genderFilter, setGenderFilter] = useState('All');
    const [minAge, setMinAge] = useState(18);
    const [maxAge, setMaxAge] = useState(50);
    const [debouncedAgeRange, setDebouncedAgeRange] = useState({ min: 18, max: 50 });
    const [interestSearch, setInterestSearch] = useState('');
    const [debouncedInterest, setDebouncedInterest] = useState('');
    const [isGenderOpen, setIsGenderOpen] = useState(false);

    useEffect(() => {
        const timer = setTimeout(() => {
            setDebouncedInterest(interestSearch);
        }, 800); // Increased to 800ms for better typing flow
        return () => clearTimeout(timer);
    }, [interestSearch]);

    useEffect(() => {
        const timer = setTimeout(() => {
            setDebouncedAgeRange({ min: minAge, max: maxAge });
        }, 500); // Wait for dragging to stop
        return () => clearTimeout(timer);
    }, [minAge, maxAge]);

    const feedFilters = useMemo(() => ({
        gender: genderFilter,
        minAge: debouncedAgeRange.min,
        maxAge: debouncedAgeRange.max,
        interest: debouncedInterest
    }), [genderFilter, debouncedAgeRange, debouncedInterest]);

    const {
        profiles,
        handleLike,
        handleSkip,
        loading,
        error,
        fetchFeed,
        addProfile
    } = useFeed(currentUser.id, feedFilters);

    const { showNotification } = useNotification();

    const handleNewUser = useCallback((newUser) => {
        // 1. Don't show yourself
        if (newUser.id === currentUser.id) return;

        // 2. Check filters
        const matchesGender = feedFilters.gender === 'All' || newUser.gender === feedFilters.gender;
        const matchesAge = newUser.age >= feedFilters.minAge && newUser.age <= feedFilters.maxAge;
        const matchesInterest = !feedFilters.interest || (newUser.interests && newUser.interests.toLowerCase().includes(feedFilters.interest.toLowerCase()));

        if (matchesGender && matchesAge && matchesInterest) {
            addProfile(newUser);
            showNotification(`✨ A new potential match just joined: ${newUser.name}!`, 'success');
        }
    }, [currentUser.id, feedFilters, addProfile, showNotification]);

    useWebSocket('/topic/public/new-users', handleNewUser, true);

    if (loading && profiles.length === 0) {
        return (
            <div className="flex flex-col items-center p-8 space-y-8">
                <div className="h-10 w-48 bg-gray-200 animate-pulse rounded-lg"></div>
                <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6 w-full max-w-4xl">
                    {[1, 2, 3].map(i => <SkeletonCard key={i} />)}
                </div>
            </div>
        );
    }

    return (
        <div className="flex flex-col items-center justify-center space-y-12 p-4 md:p-8 min-h-[600px] animate-fade-in mb-20">
            {/* Discover Header */}
            <div className="text-center space-y-6 max-w-2xl mx-auto">
                <div className="inline-flex items-center gap-3 bg-pink-50 px-6 py-2 rounded-full border border-pink-100 shadow-sm animate-bounce-soft">
                    <span className="text-xl">✨</span>
                    <span className="text-xs font-black text-pink-500 uppercase tracking-[0.3em]">Today's views: 7 profiles. Choose wisely!</span>
                </div>
                <h2 className="text-4xl md:text-6xl font-black text-slate-800 tracking-tight italic leading-[1.1] px-4 overflow-visible">
                    Find Your <span className="bg-clip-text text-transparent bg-gradient-to-r from-pink-500 to-purple-600 pb-1 pr-2">Soulmate</span>
                </h2>
                <p className="text-slate-400 font-medium max-w-lg mx-auto leading-relaxed border-b border-transparent pb-1">
                    We've brought you 7 interesting people today. Don't swipe too fast! 💖
                </p>
            </div>

            {/* Horizontal Filter Bar */}
            <div className="w-full max-w-6xl mx-auto mb-16 px-4 relative z-30">
                <div className="bg-white/80 backdrop-blur-xl rounded-[2.5rem] p-4 lg:p-6 shadow-[0_30px_60px_-15px_rgba(0,0,0,0.05)] border border-white flex flex-col lg:flex-row items-center gap-6 lg:gap-0 animate-fade-in divide-y lg:divide-y-0 lg:divide-x divide-slate-100">

                    {/* Seeking Section - Dropdown */}
                    <div className="w-full lg:w-1/4 px-6 py-2 lg:py-0 relative">
                        <label className="block text-[9px] font-black text-slate-400 uppercase tracking-[0.2em] mb-3">Seeking</label>
                        <button
                            onClick={() => setIsGenderOpen(!isGenderOpen)}
                            className={`w-full flex items-center justify-between bg-slate-50/50 hover:bg-slate-100 px-5 py-2.5 rounded-xl border border-transparent transition-all duration-300 ${isGenderOpen ? 'ring-2 ring-pink-100/50 bg-white shadow-sm' : ''}`}
                        >
                            <span className="text-[10px] font-black text-slate-700 uppercase tracking-widest">{genderFilter}</span>
                            <span className={`text-[8px] text-slate-400 transition-transform duration-500 ${isGenderOpen ? 'rotate-180' : ''}`}>▼</span>
                        </button>

                        {/* Dropdown Menu */}
                        {isGenderOpen && (
                            <>
                                <div className="fixed inset-0 z-40" onClick={() => setIsGenderOpen(false)}></div>
                                <div className="absolute top-[calc(100%+8px)] left-6 right-6 lg:left-6 lg:right-6 bg-white/95 backdrop-blur-xl border border-pink-50 rounded-2xl shadow-2xl z-50 overflow-hidden animate-bounce-in py-1.5 ring-1 ring-black/5">
                                    {['All', 'Male', 'Female', 'Other'].map(g => (
                                        <button
                                            key={g}
                                            onClick={() => {
                                                setGenderFilter(g);
                                                setIsGenderOpen(false);
                                            }}
                                            className={`w-full text-left px-5 py-2.5 text-[10px] font-black uppercase tracking-widest transition-all ${genderFilter === g ? 'bg-pink-50 text-pink-600' : 'text-slate-500 hover:bg-slate-50 hover:text-pink-500'}`}
                                        >
                                            {g}
                                        </button>
                                    ))}
                                </div>
                            </>
                        )}
                    </div>

                    {/* Age Range Section */}
                    <div className="w-full lg:flex-1 px-8 py-4 lg:py-0">
                        <div className="flex justify-between items-center mb-3">
                            <label className="text-[9px] font-black text-slate-400 uppercase tracking-[0.2em]">Age Range</label>
                            <span className="text-[10px] font-black text-pink-500 bg-pink-50/50 px-3 py-0.5 rounded-full">{minAge} — {maxAge}</span>
                        </div>
                        <div className="flex items-center gap-4">
                            <div className="flex-1 relative">
                                <input
                                    type="number"
                                    placeholder="Min"
                                    value={minAge}
                                    onChange={(e) => setMinAge(e.target.value)}
                                    className="w-full text-xs font-bold p-3 bg-slate-50/50 rounded-xl border-none focus:ring-2 focus:ring-pink-100/50 outline-none transition-all"
                                />
                                <span className="absolute right-3 top-1/2 -translate-y-1/2 text-[8px] font-bold text-slate-300">MIN</span>
                            </div>
                            <div className="w-4 h-[1px] bg-slate-200"></div>
                            <div className="flex-1 relative">
                                <input
                                    type="number"
                                    placeholder="Max"
                                    value={maxAge}
                                    onChange={(e) => setMaxAge(e.target.value)}
                                    className="w-full text-xs font-bold p-3 bg-slate-50/50 rounded-xl border-none focus:ring-2 focus:ring-pink-100/50 outline-none transition-all"
                                />
                                <span className="absolute right-3 top-1/2 -translate-y-1/2 text-[8px] font-bold text-slate-300">MAX</span>
                            </div>
                        </div>
                    </div>

                    {/* Interests Section */}
                    <div className="w-full lg:w-1/3 px-8 py-4 lg:py-0">
                        <label className="block text-[9px] font-black text-slate-400 uppercase tracking-[0.2em] mb-3">Search Interests</label>
                        <div className="relative">
                            <input
                                type="text"
                                placeholder="What are you into?..."
                                value={interestSearch}
                                onChange={(e) => setInterestSearch(e.target.value)}
                                className="w-full text-xs font-bold p-3.5 pl-10 bg-slate-50/50 rounded-xl border-none focus:ring-2 focus:ring-pink-100/50 outline-none transition-all"
                            />
                            <span className="absolute left-3.5 top-1/2 -translate-y-1/2 text-sm opacity-40">🔍</span>
                            {interestSearch && (
                                <button
                                    type="button"
                                    onClick={() => setInterestSearch('')}
                                    className="absolute right-3 top-1/2 -translate-y-1/2 w-6 h-6 bg-white hover:bg-slate-100 text-[10px] rounded-full flex items-center justify-center transition-all shadow-sm"
                                >
                                    ✕
                                </button>
                            )}
                        </div>
                    </div>
                </div>
            </div>

            {
                profiles.length === 0 ? (
                    <div className="w-full max-w-4xl text-center p-20 glass-card rounded-[3rem] border-2 border-dashed border-slate-200/50 bg-white/20 animate-fade-in">
                        <div className="relative inline-block mb-10">
                            <div className="text-8xl animate-float">{error ? '🚫' : '😴'}</div>
                            {error && <div className="absolute -top-4 -right-4 text-4xl animate-pulse">⚠️</div>}
                        </div>
                        <div className="space-y-3">
                            <h3 className="text-3xl font-black text-slate-800 italic">
                                {error ? 'Access Restricted' : "You're out of turns today!"}
                            </h3>
                            <p className="text-slate-500 font-medium max-w-md mx-auto">
                                {error || "Take some time to rest or care for yourself. New people will appear tomorrow! ✨"}
                            </p>
                            <button
                                type="button"
                                onClick={() => window.location.reload()}
                                className="mt-8 text-xs font-black text-pink-500 uppercase tracking-widest border-b-2 border-pink-100 hover:border-pink-500 transition-all pb-1"
                            >
                                Check again 🔄
                            </button>
                        </div>
                    </div>
                ) : (
                    <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-10 w-full max-w-7xl animate-fade-in items-stretch px-4">
                        {profiles.map(profile => (
                            <FeedCard
                                key={profile.id}
                                profile={profile}
                                onLike={() => handleLike(profile.id)}
                                onSkip={() => handleSkip(profile.id)}
                                currentUserInterests={currentUser.interests}
                                currentUserAge={currentUser.age}
                            />
                        ))}
                    </div>
                )
            }
        </div >
    );
};

export default MatchFeed;
