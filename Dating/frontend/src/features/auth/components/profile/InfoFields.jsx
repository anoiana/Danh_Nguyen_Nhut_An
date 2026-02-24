import React from 'react';

/**
 * Core profile info form fields: Name, Age, Gender, Bio.
 * Extracted from ProfileEditor.
 */
const InfoFields = ({
    name, setName,
    age, setAge,
    gender, setGender,
    bio, setBio,
    fieldErrors,
}) => {
    return (
        <div className="grid grid-cols-1 md:grid-cols-2 gap-8 p-10 bg-white/40 border-t border-white/60">
            {/* Display Name */}
            <div className="space-y-4">
                <label className="block text-[10px] font-black text-slate-400 uppercase tracking-[0.3em] ml-2">
                    Display Name
                </label>
                <div className="relative">
                    <span className="absolute left-6 top-1/2 -translate-y-1/2 text-xl opacity-30">🆔</span>
                    <input
                        type="text"
                        value={name}
                        onChange={(e) => setName(e.target.value)}
                        className={`w-full bg-white border-2 border-transparent focus:border-pink-200 rounded-[1.5rem] pl-16 pr-6 py-5 outline-none font-bold text-slate-700 transition-all shadow-sm ${fieldErrors.name ? 'border-red-200 bg-red-50/20' : ''}`}
                        required
                        placeholder="Your beautiful name"
                    />
                </div>
                {fieldErrors.name && (
                    <p className="text-red-500 text-[10px] font-bold ml-2 italic">{fieldErrors.name}</p>
                )}
            </div>

            {/* Age */}
            <div className="space-y-4">
                <label className="block text-[10px] font-black text-slate-400 uppercase tracking-[0.3em] ml-2">
                    Your Age
                </label>
                <div className="relative">
                    <span className="absolute left-6 top-1/2 -translate-y-1/2 text-xl opacity-30">🎉</span>
                    <input
                        type="number"
                        value={age}
                        onChange={(e) => setAge(e.target.value)}
                        className="w-full bg-white border-2 border-transparent focus:border-pink-200 rounded-[1.5rem] pl-16 pr-6 py-5 outline-none font-bold text-slate-700 transition-all shadow-sm"
                        required
                        min="18"
                    />
                </div>
            </div>

            {/* Gender */}
            <div className="space-y-4">
                <label className="block text-[10px] font-black text-slate-400 uppercase tracking-[0.3em] ml-2">
                    Preferred Gender Identity
                </label>
                <div className="grid grid-cols-3 gap-3 p-1.5 bg-slate-100/50 rounded-[1.8rem] border border-slate-100/50">
                    {['Male', 'Female', 'Other'].map(g => (
                        <button
                            key={g}
                            type="button"
                            onClick={() => setGender(g)}
                            className={`py-4 rounded-[1.2rem] text-[10px] font-black uppercase tracking-widest transition-all ${gender === g
                                ? 'bg-white text-pink-600 shadow-xl scale-[1.02]'
                                : 'text-slate-400 hover:text-slate-600'
                                }`}
                        >
                            {g}
                        </button>
                    ))}
                </div>
            </div>

            {/* Bio */}
            <div className="space-y-4">
                <label className="block text-[10px] font-black text-slate-400 uppercase tracking-[0.3em] ml-2">
                    Unique Bio
                </label>
                <textarea
                    value={bio}
                    onChange={(e) => setBio(e.target.value)}
                    rows={12}
                    placeholder="Tell us a story about yourself..."
                    className="w-full bg-white border-2 border-transparent focus:border-pink-200 rounded-[1.5rem] px-6 py-5 outline-none font-bold text-slate-700 transition-all shadow-sm resize-none h-[88px]"
                />
            </div>
        </div>
    );
};

export default InfoFields;
