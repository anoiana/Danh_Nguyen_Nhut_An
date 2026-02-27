import React from 'react';
import { getDefaultAvatar } from '../../../../lib/constants';

/**
 * Avatar and cover photo section of the profile editor.
 * Handles avatar display and upload trigger.
 */
const AvatarSection = ({ avatarUrl, currentUser, name, onFileChange }) => {
    return (
        <div className="glass-card rounded-[3.5rem] overflow-hidden border-white/80 shadow-2xl relative">
            {/* Decorative Cover */}
            <div className="h-48 bg-gradient-to-br from-pink-400 via-purple-500 to-indigo-600 relative overflow-hidden">
                <div className="absolute inset-0 bg-white/10 backdrop-blur-[1px]" />
                <div className="absolute -top-20 -right-20 w-64 h-64 bg-white/20 rounded-full blur-3xl" />
                <div className="absolute -bottom-20 -left-20 w-64 h-64 bg-pink-300/30 rounded-full blur-3xl" />
            </div>

            <div className="px-10 pb-12 -mt-20 relative">
                <div className="flex flex-col md:flex-row items-end gap-8">
                    <div className="relative group shrink-0">
                        <div className="w-40 h-40 md:w-48 md:h-48 rounded-[3rem] overflow-hidden border-[8px] border-white shadow-2xl rotate-3 group-hover:rotate-0 transition-transform duration-500">
                            <img
                                src={avatarUrl || (currentUser.photos ? currentUser.photos.split(',')[0] : null) || getDefaultAvatar(currentUser.id)}
                                alt="Avatar"
                                className="w-full h-full object-cover"
                            />
                        </div>
                        <label className="absolute bottom-2 -right-2 w-14 h-14 bg-white rounded-2xl shadow-2xl border border-slate-100 flex items-center justify-center text-2xl cursor-pointer hover:scale-110 active:scale-95 transition-all animate-bounce-soft">
                            <input
                                type="file"
                                className="hidden"
                                onChange={(e) => onFileChange(e, true)}
                                accept="image/*"
                            />
                            <span>📸</span>
                        </label>
                    </div>

                    <div className="flex-1 space-y-2 pb-2">
                        <h3 className="text-3xl font-black text-slate-800 tracking-tight italic">
                            {name || 'Your Name'}
                        </h3>
                        <p className="text-slate-400 text-sm font-bold uppercase tracking-widest">
                            {currentUser.email}
                        </p>
                    </div>
                </div>
            </div>
        </div>
    );
};

export default AvatarSection;
