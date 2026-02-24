import React from 'react';
import { getDefaultAvatar } from '../../../../lib/constants';
import { PREDEFINED_INTERESTS } from '../../hooks/useProfileEditor';

/**
 * Live preview card showing how the user's profile will look.
 * Extracted from ProfileEditor.
 */
const LivePreview = ({ name, age, gender, bio, avatarUrl, photos, interests, currentUser }) => {
    return (
        <div className="space-y-6">
            <label className="block text-[10px] font-black text-slate-400 uppercase tracking-[0.3em] ml-2">
                Live Preview Card
            </label>
            <div className="glass-card rounded-[3.5rem] overflow-hidden border-2 border-white shadow-[0_40px_80px_rgba(236,72,153,0.15)] group transition-all duration-500 hover:-translate-y-2">
                <div className="aspect-[3/4] relative">
                    <img
                        src={photos[0] || avatarUrl || getDefaultAvatar(currentUser.id)}
                        className="w-full h-full object-cover transition-transform duration-[2000ms] group-hover:scale-110"
                        alt="Preview"
                    />
                    <div className="absolute inset-0 bg-gradient-to-t from-slate-900 via-transparent to-transparent opacity-60" />
                    <div className="absolute bottom-0 left-0 p-10 w-full space-y-2">
                        <div className="flex items-baseline gap-3">
                            <h4 className="text-4xl font-black text-white italic tracking-tighter">
                                {name || 'Your Name'}
                            </h4>
                            <span className="text-3xl font-light italic text-white/80">{age || '??'}</span>
                        </div>
                        <div className="flex items-center gap-3">
                            <span className="px-3 py-1 bg-white/20 backdrop-blur-md rounded-full text-[10px] font-black text-white uppercase tracking-widest border border-white/20">
                                {gender}
                            </span>
                            <div className="flex -space-x-2">
                                {interests.slice(0, 3).map((it, i) => (
                                    <div
                                        key={i}
                                        className="w-8 h-8 bg-white/30 backdrop-blur-md rounded-full flex items-center justify-center text-sm border border-white/20 shadow-lg"
                                    >
                                        {PREDEFINED_INTERESTS.find(p => p.name === it)?.icon || '✨'}
                                    </div>
                                ))}
                            </div>
                        </div>
                        <p className="text-white/70 text-sm font-medium italic mt-2 line-clamp-2">
                            {bio || "Your aura is mystery right now. Share a bit of your story!"}
                        </p>
                    </div>
                </div>
                <div className="p-6 bg-white/40 text-center">
                    <p className="text-[10px] font-black text-pink-500 uppercase tracking-widest">Profile Score: 85% 🔥</p>
                </div>
            </div>
            <div className="p-8 rounded-[2rem] bg-indigo-50 border border-indigo-100 space-y-4">
                <p className="text-[10px] font-black text-indigo-400 uppercase tracking-widest">Pro Tip 💡</p>
                <p className="text-sm font-bold text-indigo-900 italic leading-relaxed">
                    Profiles with at least 4 lifestyle photos and 5 selected interests get 3x more matches! 🚀
                </p>
            </div>
        </div>
    );
};

export default LivePreview;
