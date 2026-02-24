import React from 'react';

/**
 * "Waiting for partner..." state display.
 * Extracted from AvailabilityModal.
 */
const WaitingState = ({ partnerName, onClose }) => {
    return (
        <div className="py-12 flex flex-col items-center gap-8 justify-center animate-fade-in">
            <div className="relative">
                <div className="w-24 h-24 bg-blue-100 rounded-full animate-ping absolute opacity-20" />
                <div className="w-24 h-24 bg-blue-50 rounded-full flex items-center justify-center relative shadow-inner">
                    <span className="text-4xl animate-bounce">⏳</span>
                </div>
            </div>
            <div className="text-center space-y-3">
                <h4 className="text-xl font-black text-slate-800">Waiting for partner...</h4>
                <p className="text-slate-500 font-bold text-sm max-w-[280px] leading-relaxed">
                    {partnerName} is still picking their slots. We'll notify you as soon as there's a match! 🥂
                </p>
            </div>
            <div className="w-full space-y-4">
                <div className="bg-slate-50 p-6 rounded-3xl border border-dashed border-slate-200">
                    <div className="flex justify-center gap-2">
                        {[...Array(3)].map((_, i) => (
                            <div
                                key={i}
                                className="w-2 h-2 rounded-full bg-blue-300 animate-pulse"
                                style={{ animationDelay: `${i * 200}ms` }}
                            />
                        ))}
                    </div>
                </div>
                <button
                    onClick={onClose}
                    className="w-full py-5 bg-slate-100 hover:bg-slate-200 text-slate-600 font-black text-xs uppercase tracking-[0.2em] rounded-2xl transition-all"
                >
                    Keep Exploring
                </button>
            </div>
        </div>
    );
};

export default WaitingState;
