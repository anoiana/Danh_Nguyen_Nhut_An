import React, { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { getDefaultAvatar } from '../../../lib/constants';

const FeedCard = ({ profile, onLike, onSkip, currentUserInterests = "", currentUserAge = 25 }) => {
    const navigate = useNavigate();
    const [imgIndex, setImgIndex] = useState(0);

    // Parse photos: Priority to profile.photos list, then avatarUrl
    let photos = profile.photos ? profile.photos.split(',').filter(p => p) : [];
    if (photos.length === 0 && profile.avatarUrl) {
        photos = [profile.avatarUrl];
    }
    // Safeguard for empty photos
    if (photos.length === 0) photos = [getDefaultAvatar(profile.id)];

    // Navigation logic
    const nextImg = (e) => {
        e.stopPropagation();
        setImgIndex((prev) => (prev + 1) % photos.length);
    };

    const prevImg = (e) => {
        e.stopPropagation();
        setImgIndex((prev) => (prev - 1 + photos.length) % photos.length);
    };

    // Simplified FeedCard for Breeze flow
    const userInts = currentUserInterests ? currentUserInterests.split(',').map(i => i.trim().toLowerCase()) : [];
    const profileInts = profile.interests ? profile.interests.split(',').map(i => i.trim().toLowerCase()) : [];

    return (
        <div
            onClick={() => navigate(`/profile/${profile.id}`)}
            className="glass-card rounded-[2.5rem] overflow-hidden w-full transform transition duration-500 hover:-translate-y-3 relative group border-white/60 flex flex-col h-full bg-white/70 cursor-pointer"
        >
            {/* Photo Section with Navigation */}
            <div className="h-96 bg-gray-200 relative overflow-hidden shrink-0 group/photo">
                <div
                    className="flex h-full transition-transform duration-700 ease-in-out"
                    style={{ transform: `translateX(-${imgIndex * 100}%)` }}
                >
                    {photos.map((photo, i) => (
                        <div key={i} className="w-full h-full shrink-0 relative">
                            <img
                                src={photo}
                                alt={`${profile.name} ${i + 1}`}
                                className={`w-full h-full object-cover transition-transform duration-[2000ms] ease-out ${i === imgIndex ? 'scale-105' : 'scale-100'}`}
                            />
                        </div>
                    ))}
                </div>

                {/* Photo Navigation Overlays */}
                {photos.length > 1 && (
                    <>
                        {/* Progress bars at the top */}
                        <div className="absolute top-4 left-0 right-0 px-4 flex gap-1.5 z-20">
                            {photos.map((_, i) => (
                                <div
                                    key={i}
                                    className={`h-1 flex-1 rounded-full transition-all duration-300 ${i === imgIndex ? 'bg-white shadow-lg scale-y-125' : 'bg-white/30'}`}
                                ></div>
                            ))}
                        </div>

                        {/* Navigation Buttons */}
                        <button
                            onClick={prevImg}
                            className="absolute left-3 top-1/2 -translate-y-1/2 w-10 h-10 rounded-full bg-black/20 backdrop-blur-md border border-white/30 flex items-center justify-center text-white opacity-0 group-hover/photo:opacity-100 transition-all hover:bg-black/40 active:scale-95 z-30"
                        >
                            <svg xmlns="http://www.w3.org/2000/svg" className="h-6 w-6" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={3} d="M15 19l-7-7 7-7" />
                            </svg>
                        </button>
                        <button
                            onClick={nextImg}
                            className="absolute right-3 top-1/2 -translate-y-1/2 w-10 h-10 rounded-full bg-black/20 backdrop-blur-md border border-white/30 flex items-center justify-center text-white opacity-0 group-hover/photo:opacity-100 transition-all hover:bg-black/40 active:scale-95 z-30"
                        >
                            <svg xmlns="http://www.w3.org/2000/svg" className="h-6 w-6" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={3} d="M9 5l7 7-7 7" />
                            </svg>
                        </button>

                        {/* Clickable regions for faster navigation */}
                        <div className="absolute inset-y-0 left-0 w-1/3 z-10 cursor-pointer" onClick={prevImg}></div>
                        <div className="absolute inset-y-0 right-0 w-1/3 z-10 cursor-pointer" onClick={nextImg}></div>
                    </>
                )}

                <div className="absolute inset-0 bg-gradient-to-t from-black/90 via-black/20 to-transparent pointer-events-none"></div>

                <div className="absolute bottom-0 left-0 right-0 p-8 pt-20">
                    <div className="flex items-baseline space-x-3">
                        <h3 className="text-white text-4xl font-black tracking-tighter">{profile.name}</h3>
                        <span className="text-white/80 text-2xl font-light italic">{profile.age}</span>
                    </div>
                </div>
            </div>

            <div className="p-8 flex flex-col flex-1 space-y-6">
                <div className="min-h-[4rem] relative">
                    <p className="text-gray-500 text-sm leading-relaxed font-semibold italic line-clamp-3">
                        {profile.bio || "This user is keeping a bit of mystery... ✨"}
                    </p>
                </div>

                {/* Interests Section */}
                <div className="space-y-4 flex-1">
                    <div className="flex items-center justify-between px-1">
                        <h4 className="text-[10px] font-black uppercase tracking-widest text-gray-400">Interests</h4>
                    </div>
                    <div className="flex flex-wrap gap-2">
                        {profileInts.slice(0, 5).map((interest, i) => (
                            <span
                                key={i}
                                className={`px-3 py-1.5 rounded-xl text-[10px] font-black uppercase tracking-wider transition-all duration-300 ${userInts.includes(interest)
                                    ? 'bg-pink-500 text-white shadow-lg shadow-pink-100 scale-105'
                                    : 'bg-gray-100 text-gray-400 group-hover:bg-gray-200 group-hover:text-gray-600'
                                    }`}
                            >
                                {interest}
                            </span>
                        ))}
                    </div>
                </div>

                {/* Action Buttons */}
                <div className="flex items-center gap-4 pt-4">
                    <button
                        onClick={(e) => {
                            e.stopPropagation();
                            onSkip();
                        }}
                        className="flex-1 py-4 rounded-2xl border-2 border-gray-100 text-gray-400 font-bold hover:bg-gray-50 hover:border-gray-200 transition-all flex items-center justify-center gap-2 active:scale-95"
                    >
                        SKIP
                    </button>
                    <button
                        onClick={(e) => {
                            e.stopPropagation();
                            onLike();
                        }}
                        className="flex-[2] py-4 rounded-2xl bg-gradient-to-r from-pink-500 to-purple-600 text-white font-black shadow-lg shadow-pink-200 hover:shadow-xl hover:shadow-pink-300 transition-all transform hover:-translate-y-1 active:scale-95 flex items-center justify-center gap-2"
                    >
                        <span>LIKE</span>
                        <span className="text-xl">❤️</span>
                    </button>
                </div>
            </div>
        </div>
    );
};

export default FeedCard;
