import React from 'react';
import { getDefaultAvatar } from '../../../lib/constants';

const ProfileDetailModal = ({ profile, isOpen, onClose, onLike, onSkip, currentUser }) => {
    if (!isOpen || !profile) return null;

    const userInts = currentUser?.interests ? currentUser.interests.split(',').map(i => i.trim().toLowerCase()) : [];
    const profileInts = profile.interests ? profile.interests.split(',').map(i => i.trim().toLowerCase()) : [];
    const commonInterests = profileInts.filter(i => userInts.includes(i));

    // Parse photos
    let photos = profile.photos ? profile.photos.split(',').filter(p => p) : [];
    if (photos.length === 0 && profile.avatarUrl) {
        photos = [profile.avatarUrl];
    }
    if (photos.length === 0) photos = [getDefaultAvatar(profile.id)];

    let matchScore = 0;
    if (profile.matchScore !== undefined && profile.matchScore !== null) {
        matchScore = Math.min(99, Math.max(10, Math.round(profile.matchScore / 2)));
    } else {
        // Fallback calculation if matchScore is missing (frontend only)
        let score = 20;
        score += (commonInterests.length * 15);
        matchScore = Math.min(99, score);
    }

    return (
        <div className="fixed inset-0 z-[150] flex items-center justify-center p-4 bg-black/60 backdrop-blur-sm animate-fade-in overflow-y-auto">
            {/* Backdrop */}
            <div className="absolute inset-0" onClick={onClose}></div>

            {/* Modal Container */}
            <div className="relative bg-[#f0f2f5] w-full max-w-4xl rounded-xl shadow-2xl overflow-hidden animate-scale-up my-auto">

                {/* 1. Main Header Card */}
                <div className="bg-white p-6 border-b border-gray-100 flex flex-col md:flex-row items-center justify-between gap-6">
                    <div className="flex items-center gap-6">
                        <div>
                            <h2 className="text-3xl font-black text-[#1a1a1a] tracking-tight">{profile.name}</h2>
                            <p className="text-gray-500 font-bold mt-1">
                                {profile.age} years old • {profile.gender}
                            </p>
                        </div>

                        {/* Compatibility Circle */}
                        <div className="w-16 h-16 rounded-full border-2 border-blue-600 flex items-center justify-center relative shadow-sm">
                            <span className="text-blue-600 font-black text-lg">{matchScore}%</span>
                            <div className="absolute inset-[-4px] border-4 border-blue-100 rounded-full -z-10"></div>
                        </div>
                    </div>

                    <div className="flex items-center gap-3">
                        <button
                            onClick={onSkip}
                            className="px-8 py-3 rounded-full border-2 border-gray-800 text-gray-800 font-black text-sm uppercase tracking-widest hover:bg-gray-50 transition-all flex items-center gap-2"
                        >
                            <span className="text-xl">✕</span> PASS
                        </button>
                        <button
                            onClick={onLike}
                            className="px-8 py-3 rounded-full bg-[#ec4899] text-white font-black text-sm uppercase tracking-widest hover:bg-[#db2777] transition-all flex items-center gap-2 shadow-lg shadow-pink-200"
                        >
                            <span className="text-xl">❤️</span> LIKE
                        </button>
                    </div>
                </div>

                {/* 2. Photo Grid Section */}
                <div className="p-6 bg-white overflow-x-auto">
                    <div className="flex gap-4 min-w-max pb-2">
                        {photos.map((url, idx) => (
                            <div key={idx} className="w-[340px] h-[450px] rounded-lg overflow-hidden relative shadow-md shrink-0 group">
                                <img
                                    src={url}
                                    alt={`${profile.name} ${idx}`}
                                    className="w-full h-full object-cover group-hover:scale-105 transition-transform duration-700"
                                />
                                <div className="absolute bottom-4 left-4 bg-white/90 backdrop-blur-md px-4 py-1.5 rounded-full flex items-center gap-2 shadow-lg">
                                    <span className="text-blue-800 text-xs">💬</span>
                                    <span className="text-blue-800 font-black text-[10px] uppercase tracking-wider">INTRO</span>
                                </div>
                            </div>
                        ))}
                    </div>
                </div>

                {/* 3. Bottom Comparison & Details Grid */}
                <div className="p-6 grid grid-cols-1 md:grid-cols-2 gap-6">

                    {/* Comparison Card */}
                    <div className="bg-white rounded-xl shadow-sm border border-gray-100 overflow-hidden">
                        <div className="bg-[#1a1a1a] p-3">
                            <h3 className="text-white text-xs font-black uppercase tracking-widest">You & {profile.name}</h3>
                        </div>
                        <div className="p-6 flex flex-col md:flex-row items-center gap-8">
                            <div className="relative">
                                <div className="flex -space-x-8">
                                    <div className="w-24 h-24 rounded-full border-4 border-white shadow-xl overflow-hidden bg-gray-200">
                                        <img src={currentUser?.avatarUrl || getDefaultAvatar(currentUser?.id)} className="w-full h-full object-cover" alt="Me" />
                                    </div>
                                    <div className="w-24 h-24 rounded-full border-4 border-white shadow-xl overflow-hidden bg-gray-200">
                                        <img src={profile.avatarUrl || photos[0]} className="w-full h-full object-cover" alt={profile.name} />
                                    </div>
                                </div>
                                <div className="absolute -bottom-2 left-1/2 -translate-x-1/2 bg-white w-14 h-14 rounded-full border-2 border-blue-600 flex items-center justify-center shadow-lg">
                                    <span className="text-blue-600 font-black text-sm">{matchScore}%</span>
                                </div>
                            </div>

                            <div className="flex-1 w-full space-y-4">
                                <div className="flex justify-between items-center border-b border-gray-50 pb-2">
                                    <span className="text-blue-900 font-black text-sm uppercase tracking-wider">AGREE (SAME INTERESTS) 😊</span>
                                    <span className="font-bold text-gray-700">{commonInterests.length}</span>
                                </div>
                                <div className="flex justify-between items-center border-b border-gray-50 pb-2">
                                    <span className="text-blue-900 font-black text-sm uppercase tracking-wider">Total Interests 🙃</span>
                                    <span className="font-bold text-gray-700">{profileInts.length}</span>
                                </div>
                            </div>
                        </div>
                    </div>

                    {/* Details Card */}
                    <div className="bg-white rounded-xl shadow-sm border border-gray-100 overflow-hidden">
                        <div className="bg-[#1a1a1a] p-3">
                            <h3 className="text-white text-xs font-black uppercase tracking-widest">Details</h3>
                        </div>
                        <div className="p-6 space-y-6">
                            <div className="flex items-start gap-4">
                                <span className="text-2xl">👤</span>
                                <p className="text-gray-700 font-medium leading-relaxed">
                                    {profile.gender} | {profile.age} years old
                                </p>
                            </div>
                            <div className="flex items-start gap-4">
                                <span className="text-2xl">🎯</span>
                                <p className="text-gray-700 font-medium leading-relaxed">
                                    Interested in {debunkInterests(profile)}
                                </p>
                            </div>
                            <div className="flex items-start gap-4">
                                <span className="text-2xl">✨</span>
                                <p className="text-gray-700 font-medium leading-relaxed italic">
                                    {profile.bio || "No biography provided."}
                                </p>
                            </div>
                        </div>
                    </div>
                </div>

                <div className="p-4 text-center">
                    <button className="text-gray-400 text-xs font-bold hover:text-gray-600 transition underline underline-offset-4">
                        Remove ads
                    </button>
                </div>
            </div>
        </div>
    );
};

// Helper to show some interests as "Details"
function debunkInterests(profile) {
    if (!profile.interests) return "Everything!";
    const ints = profile.interests.split(',');
    return ints.slice(0, 3).join(', ') + (ints.length > 3 ? '...' : '');
}

export default ProfileDetailModal;
