import React from 'react';

/**
 * Photo gallery grid with upload and delete capabilities.
 * Extracted from ProfileEditor.
 */
const PhotoGallery = ({ photos, onFileChange, onRemovePhoto }) => {
    return (
        <div className="glass-card rounded-[3.5rem] p-12 border-white/80 shadow-2xl space-y-10">
            <div className="flex items-center justify-between px-2">
                <div>
                    <h4 className="text-3xl font-black text-slate-800 italic tracking-tight">Vibe Gallery</h4>
                    <p className="text-[10px] font-black text-slate-400 uppercase tracking-widest mt-1">
                        Showcase your lifestyle and energy
                    </p>
                </div>
                <label className="group h-14 bg-slate-900 text-white px-8 rounded-2xl flex items-center justify-center gap-3 cursor-pointer hover:bg-slate-800 transition-all active:scale-95 shadow-xl shadow-slate-200">
                    <input
                        type="file"
                        className="hidden"
                        multiple
                        onChange={(e) => onFileChange(e)}
                        accept="image/*"
                    />
                    <span className="text-xl">➕</span>
                    <span className="text-[10px] font-black uppercase tracking-widest">Add Vision</span>
                </label>
            </div>

            <div className="grid grid-cols-2 md:grid-cols-4 gap-6">
                {photos.map((url, idx) => (
                    <div
                        key={idx}
                        className="relative group aspect-[3/4] rounded-[2.5rem] overflow-hidden border-4 border-white shadow-xl transition-all hover:-translate-y-2 hover:shadow-pink-200/50"
                    >
                        <img src={url} alt={`Photo ${idx + 1}`} className="w-full h-full object-cover" />
                        <div className="absolute inset-0 bg-gradient-to-t from-slate-900/40 to-transparent opacity-0 group-hover:opacity-100 transition-opacity flex items-end justify-center pb-6">
                            <button
                                type="button"
                                onClick={() => onRemovePhoto(idx)}
                                className="w-12 h-12 bg-white/90 backdrop-blur-md text-red-500 rounded-2xl flex items-center justify-center text-2xl hover:bg-white hover:scale-110 transition-all"
                            >
                                ✕
                            </button>
                        </div>
                    </div>
                ))}
                {photos.length === 0 && (
                    <div className="col-span-full py-20 text-center border-4 border-dashed border-slate-100 rounded-[3rem] bg-slate-50/50 space-y-4">
                        <span className="text-6xl grayscale opacity-30">🖼️</span>
                        <p className="text-slate-400 font-black italic">Your gallery is currently a blank canvas.</p>
                    </div>
                )}
            </div>
        </div>
    );
};

export default PhotoGallery;
