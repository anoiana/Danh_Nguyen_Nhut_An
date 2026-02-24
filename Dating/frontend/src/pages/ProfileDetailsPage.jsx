import React, { useEffect, useState } from 'react';
import { useParams, useNavigate, useLocation } from 'react-router-dom';
import { getUserById } from '../features/auth/api/authApi';
import { likeUser, skipUser } from '../features/matching/api/matchApi';
import { useAuth } from '../features/auth/hooks/useAuth';
import toast from 'react-hot-toast';
import { getDefaultAvatar } from '../lib/constants';

const ProfileDetailsPage = () => {
    const { id } = useParams();
    const navigate = useNavigate();
    const location = useLocation();
    const { currentUser } = useAuth();
    const [profile, setProfile] = useState(null);
    const [loading, setLoading] = useState(true);

    useEffect(() => {
        const fetchProfile = async () => {
            try {
                const response = await getUserById(id);
                setProfile(response.data);
            } catch (error) {
                console.error("Error fetching profile:", error);
                toast.error("Could not load profile");
            } finally {
                setLoading(false);
            }
        };
        fetchProfile();
    }, [id]);

    const handleLike = async () => {
        try {
            const response = await likeUser(currentUser.id, profile.id);
            if (response.data && response.data.includes("Match")) {
                // IT'S A MATCH notification is handled globally by ActivityCenter
            } else {
                toast.success(`Like sent to ${profile.name}!`);
            }
            navigate('/');
        } catch (error) {
            toast.error("Failed to like user");
        }
    };

    const handleSkip = async () => {
        try {
            await skipUser(currentUser.id, profile.id);
            toast.success("Profile skipped");
            navigate('/');
        } catch (error) {
            console.error("Error skipping user:", error);
            navigate('/');
        }
    };

    if (loading) {
        return (
            <div className="flex-1 flex flex-col items-center justify-center bg-[#f0f2f5]">
                <div className="flex flex-col items-center space-y-4">
                    <div className="w-16 h-16 border-4 border-pink-500 border-t-transparent rounded-full animate-spin"></div>
                    <p className="text-gray-500 font-bold animate-pulse">Loading profile...</p>
                </div>
            </div>
        );
    }

    if (!profile) {
        return (
            <div className="flex-1 flex flex-col items-center justify-center bg-[#f0f2f5]">
                <div className="text-center">
                    <h2 className="text-4xl font-black text-gray-800">404</h2>
                    <p className="text-gray-500 mt-2">Profile not found</p>
                    <button onClick={() => navigate('/')} className="mt-6 px-8 py-3 bg-pink-500 text-white rounded-full font-bold">Go Back</button>
                </div>
            </div>
        );
    }

    const userInts = currentUser?.interests ? currentUser.interests.split(',').map(i => i.trim().toLowerCase()) : [];
    const profileInts = profile.interests ? profile.interests.split(',').map(i => i.trim().toLowerCase()) : [];
    const commonInterests = profileInts.filter(i => userInts.includes(i));

    let photos = profile.photos ? profile.photos.split(',').filter(p => p) : [];
    if (photos.length === 0 && profile.avatarUrl) photos = [profile.avatarUrl];
    if (photos.length === 0) photos = [getDefaultAvatar(profile.id)];

    // Match score and legacy location state removed in favor of Breeze flow
    const matchScore = null;

    return (
        <main className="flex-1 pb-20 animate-fade-in">
            {/* Navigation Header */}
            <div className="max-w-6xl mx-auto px-6 mt-12 flex justify-between items-center">
                <button
                    onClick={() => navigate(-1)}
                    className="group flex items-center gap-3 px-6 py-3 bg-white/50 backdrop-blur-md rounded-2xl border border-white/60 text-slate-500 font-black text-[10px] uppercase tracking-[0.2em] transition-all hover:bg-white hover:text-pink-600 hover:shadow-xl hover:shadow-pink-100 hover:-translate-x-1"
                >
                    <span className="text-xl">←</span>
                    Return to Explore
                </button>

                <div className="flex gap-4">
                    {profile.id === currentUser.id ? (
                        <button
                            onClick={() => navigate('/?tab=profile')}
                            className="px-8 h-14 rounded-2xl bg-slate-900 text-white font-black text-[10px] uppercase tracking-[0.2em] shadow-xl hover:bg-slate-800 transition-all hover:-translate-y-1 active:scale-95 flex items-center gap-3"
                        >
                            <span>Edit My Profile</span>
                            <span className="text-xl">⚙️</span>
                        </button>
                    ) : (
                        <>
                            <button
                                onClick={handleSkip}
                                className="w-14 h-14 rounded-2xl bg-white/50 backdrop-blur-md border border-white/60 flex items-center justify-center text-slate-400 hover:text-slate-800 transition-all hover:shadow-xl active:scale-95 group"
                            >
                                <span className="text-2xl transform group-hover:rotate-90 transition-transform">✕</span>
                            </button>
                            <button
                                onClick={handleLike}
                                className="px-8 h-14 rounded-2xl bg-gradient-to-r from-pink-500 to-purple-600 text-white font-black text-[10px] uppercase tracking-[0.2em] shadow-xl shadow-pink-200/50 hover:shadow-pink-300 transition-all hover:-translate-y-1 active:scale-95 flex items-center gap-3"
                            >
                                <span>Send Heart</span>
                                <span className="text-xl">❤️</span>
                            </button>
                        </>
                    )}
                </div>
            </div>

            <div className="max-w-6xl mx-auto mt-10 px-6">
                <div className="glass-card rounded-[4rem] overflow-hidden border-2 border-white/80 shadow-[0_40px_100px_rgba(236,72,153,0.1)]">

                    {/* Hero Section */}
                    <div className="p-10 md:p-16 flex flex-col md:flex-row items-center gap-12 bg-gradient-to-b from-white/40 to-transparent">
                        <div className="relative shrink-0">
                            <div className="w-48 h-48 md:w-64 md:h-64 rounded-[3.5rem] overflow-hidden border-[8px] border-white shadow-2xl rotate-3 hover:rotate-0 transition-transform duration-700">
                                <img src={profile.avatarUrl || photos[0]} alt={profile.name} className="w-full h-full object-cover" />
                            </div>
                            {profile.id !== currentUser.id && (
                                <div className="absolute -bottom-6 -right-6 w-24 h-24 bg-white rounded-[2rem] shadow-2xl border-4 border-pink-50 flex flex-col items-center justify-center animate-bounce-soft">
                                    <span className="text-pink-600 font-black text-2xl leading-none">✨</span>
                                    <span className="text-[8px] font-black text-slate-400 uppercase tracking-widest mt-1">Profile</span>
                                </div>
                            )}
                            {profile.id === currentUser.id && (
                                <div className="absolute -bottom-6 -right-6 w-24 h-24 bg-gradient-to-br from-indigo-500 to-blue-600 rounded-[2rem] shadow-2xl border-4 border-white flex flex-col items-center justify-center animate-bounce-soft">
                                    <span className="text-white text-2xl">✨</span>
                                    <span className="text-[8px] font-black text-white uppercase tracking-widest mt-1">You</span>
                                </div>
                            )}
                        </div>

                        <div className="text-center md:text-left space-y-4">
                            <div className="inline-flex items-center gap-2 bg-green-50 px-4 py-1 rounded-full border border-green-100 mb-2">
                                <span className="w-2 h-2 rounded-full bg-green-500 animate-pulse"></span>
                                <span className="text-[10px] font-black text-green-600 uppercase tracking-widest">Active Now</span>
                            </div>
                            <h1 className="text-6xl md:text-8xl font-black text-slate-800 tracking-tight italic leading-[1.1] px-2 overflow-visible">{profile.name}</h1>
                            <div className="flex flex-wrap justify-center md:justify-start gap-3 items-center text-slate-400">
                                <span className="text-2xl font-light italic">{profile.age} years old</span>
                                <span className="w-1 h-1 rounded-full bg-slate-300"></span>
                                <span className="text-sm font-black uppercase tracking-[0.2em]">{profile.gender}</span>
                            </div>
                        </div>
                    </div>

                    {/* Gallery Strip */}
                    <div className="relative bg-white/20">
                        <div
                            id="details-gallery"
                            className="flex overflow-x-auto gap-8 p-10 md:p-16 scroll-smooth peer"
                            style={{ scrollbarWidth: 'none' }}
                        >
                            {photos.slice(0, 5).map((url, idx) => (
                                <div key={idx} className="w-[300px] h-[400px] md:w-[450px] md:h-[600px] rounded-[3rem] overflow-hidden shadow-2xl shrink-0 border-[6px] border-white relative group">
                                    <img
                                        src={url}
                                        className="w-full h-full object-cover transition-transform duration-[2000ms] group-hover:scale-110"
                                        alt={`${profile.name} ${idx + 1}`}
                                    />
                                    <div className="absolute inset-0 bg-gradient-to-t from-slate-900/40 to-transparent opacity-0 group-hover:opacity-100 transition-opacity"></div>
                                </div>
                            ))}
                        </div>

                        {/* Gallery Navigation */}
                        <div className="absolute bottom-20 left-1/2 -translate-x-1/2 flex gap-4 opacity-0 peer-hover:opacity-100 hover:opacity-100 transition-opacity">
                            <button
                                onClick={() => document.getElementById('details-gallery').scrollBy({ left: -450, behavior: 'smooth' })}
                                className="w-14 h-14 bg-white/90 backdrop-blur-md rounded-2xl shadow-xl flex items-center justify-center hover:bg-white transition-all hover:scale-110 active:scale-95"
                            >
                                <span className="text-2xl">‹</span>
                            </button>
                            <button
                                onClick={() => document.getElementById('details-gallery').scrollBy({ left: 450, behavior: 'smooth' })}
                                className="w-14 h-14 bg-white/90 backdrop-blur-md rounded-2xl shadow-xl flex items-center justify-center hover:bg-white transition-all hover:scale-110 active:scale-95"
                            >
                                <span className="text-2xl">›</span>
                            </button>
                        </div>
                    </div>

                    {/* Profile Details Grid */}
                    <div className="grid grid-cols-1 md:grid-cols-2 bg-white/40">
                        {/* Bio Section */}
                        <div className="p-12 md:p-20 space-y-12 border-b md:border-b-0 md:border-r border-white/60">
                            <div className="space-y-6">
                                <label className="text-[10px] font-black text-slate-400 uppercase tracking-[0.3em] flex items-center gap-2">
                                    <span className="text-lg">🕯️</span> The Story
                                </label>
                                <p className="text-2xl md:text-3xl text-slate-700 font-medium italic leading-relaxed">
                                    "{profile.bio || "This person prefers to let their aura speak for itself... ✨"}"
                                </p>
                            </div>

                            <div className="space-y-8">
                                <label className="text-[10px] font-black text-slate-400 uppercase tracking-[0.3em] flex items-center gap-2">
                                    <span className="text-lg">🎯</span> Interests & Vibes
                                </label>
                                <div className="flex flex-wrap gap-3">
                                    {profileInts.map(interest => (
                                        <div
                                            key={interest}
                                            className={`px-6 py-3 rounded-2xl text-xs font-black uppercase tracking-wider transition-all ${userInts.includes(interest)
                                                ? 'bg-gradient-to-r from-pink-500 to-purple-600 text-white shadow-lg shadow-pink-100 scale-105'
                                                : 'bg-white text-slate-500'
                                                }`}
                                        >
                                            {userInts.includes(interest) ? '✨ ' : ''}{interest}
                                        </div>
                                    ))}
                                </div>
                            </div>
                        </div>

                        {/* Chemistry / Stats Section */}
                        <div className="p-12 md:p-20 space-y-12 bg-white/30 backdrop-blur-sm">
                            <div className="space-y-8">
                                <label className="text-[10px] font-black text-slate-400 uppercase tracking-[0.3em] flex items-center gap-2">
                                    <span className="text-lg">{profile.id === currentUser.id ? "📊" : "🧬"}</span>
                                    {profile.id === currentUser.id ? "Profile Insights" : "Match Chemistry"}
                                </label>

                                {profile.id === currentUser.id ? (
                                    <div className="p-8 rounded-[3rem] bg-gradient-to-br from-indigo-50 to-blue-50 border border-white relative overflow-hidden group">
                                        <div className="absolute -right-10 -top-10 w-40 h-40 bg-white/40 rounded-full blur-3xl"></div>
                                        <div className="relative flex items-center gap-6">
                                            <div className="w-20 h-20 rounded-2xl bg-white shadow-xl flex items-center justify-center text-3xl">
                                                📈
                                            </div>
                                            <div className="space-y-1">
                                                <p className="text-2xl font-black text-slate-800 tracking-tight italic">Profile Reach</p>
                                                <p className="text-xs font-bold text-slate-400">High engagement today!</p>
                                            </div>
                                        </div>
                                    </div>
                                ) : (
                                    <div className="p-8 rounded-[3rem] bg-gradient-to-br from-pink-50 to-purple-50 border border-white relative overflow-hidden group">
                                        <div className="absolute -right-10 -top-10 w-40 h-40 bg-white/40 rounded-full blur-3xl transition-transform duration-1000 group-hover:scale-150"></div>
                                        <div className="relative flex items-center gap-8">
                                            <div className="flex -space-x-8">
                                                <div className="w-20 h-20 rounded-2xl border-4 border-white shadow-xl overflow-hidden transform -rotate-12 group-hover:rotate-0 transition-transform">
                                                    <img src={currentUser?.avatarUrl || getDefaultAvatar(currentUser?.id || 'me')} alt="Me" className="w-full h-full object-cover" />
                                                </div>
                                                <div className="w-20 h-20 rounded-2xl border-4 border-white shadow-xl overflow-hidden transform rotate-12 group-hover:rotate-0 transition-transform">
                                                    <img src={profile.avatarUrl || photos[0]} alt={profile.name} className="w-full h-full object-cover" />
                                                </div>
                                            </div>
                                            <div className="space-y-1">
                                                <p className="text-2xl font-black text-slate-800 tracking-tight italic">Connection</p>
                                                <p className="text-xs font-bold text-slate-400">Getting to know each other!</p>
                                            </div>
                                        </div>
                                    </div>
                                )}

                                <div className="grid grid-cols-2 gap-4">
                                    <div className="p-6 rounded-3xl bg-white border border-pink-50 space-y-2">
                                        <p className="text-[10px] font-black text-slate-400 uppercase tracking-widest">{profile.id === currentUser.id ? "Interests" : "Shared"}</p>
                                        <p className="text-3xl font-black text-pink-500 italic leading-none">
                                            {profile.id === currentUser.id ? profileInts.length : commonInterests.length}
                                        </p>
                                        <p className="text-[10px] font-bold text-slate-300">{profile.id === currentUser.id ? "Total" : "Interests"}</p>
                                    </div>
                                    <div className="p-6 rounded-3xl bg-white border border-slate-100 space-y-2">
                                        <p className="text-[10px] font-black text-slate-400 uppercase tracking-widest">{profile.id === currentUser.id ? "Photos" : "Photos"}</p>
                                        <p className="text-3xl font-black text-slate-800 italic leading-none">
                                            {photos.length}
                                        </p>
                                        <p className="text-[10px] font-bold text-slate-300">{profile.id === currentUser.id ? "Uploaded" : "Total"}</p>
                                    </div>
                                </div>

                                {/* Suggestion / Tip */}
                                <div className={`p-6 rounded-3xl text-white space-y-3 relative overflow-hidden ${profile.id === currentUser.id ? "bg-indigo-900" : "bg-slate-900"}`}>
                                    <div className="absolute top-0 right-0 p-4 opacity-20 text-4xl">💡</div>
                                    <p className="text-[10px] font-black uppercase tracking-[0.3em] text-slate-400">{profile.id === currentUser.id ? "Growth Tip" : "Match Tip"}</p>
                                    <p className="text-sm font-bold italic leading-relaxed">
                                        {profile.id === currentUser.id
                                            ? "Add more photos to increase your visibility by 40%! ✨"
                                            : commonInterests.length > 0
                                                ? `You both like ${commonInterests[0]}. It's the perfect ice breaker for your first date! ✨`
                                                : "Opposites attract! Why not ask them about their unique interests? 🌈"}
                                    </p>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </main>
    );
};

export default ProfileDetailsPage;
