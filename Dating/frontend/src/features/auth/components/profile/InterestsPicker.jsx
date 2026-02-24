import React from 'react';
import { PREDEFINED_INTERESTS } from '../../hooks/useProfileEditor';

/**
 * Interest selection grid.
 * Extracted from ProfileEditor.
 */
const InterestsPicker = ({ interests, onToggle }) => {
    return (
        <div className="glass-card rounded-[3.5rem] p-12 border-white/80 shadow-2xl space-y-10">
            <div>
                <h4 className="text-3xl font-black text-slate-800 italic tracking-tight">Passions & Sparks</h4>
                <p className="text-[10px] font-black text-slate-400 uppercase tracking-widest mt-1">
                    Select the topics that make your heart beat faster
                </p>
            </div>
            <div className="flex flex-wrap gap-4">
                {PREDEFINED_INTERESTS.map(interest => (
                    <button
                        key={interest.name}
                        type="button"
                        onClick={() => onToggle(interest.name)}
                        className={`px-6 py-4 rounded-2xl text-[11px] font-black uppercase tracking-wider transition-all flex items-center gap-3 border-2 ${interests.includes(interest.name)
                            ? "bg-gradient-to-r from-pink-500 to-purple-600 text-white border-transparent shadow-xl shadow-pink-200/50 scale-110"
                            : "bg-white text-slate-500 border-slate-50 hover:border-pink-100 hover:text-slate-700"
                            }`}
                    >
                        <span className="text-xl">{interest.icon}</span>
                        <span>{interest.name}</span>
                    </button>
                ))}
            </div>
        </div>
    );
};

export default InterestsPicker;
