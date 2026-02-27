import React from 'react';

/**
 * "Waiting for partner..." state display.
 * Improved with Premium Aesthetics (Glassmorphism, Animations, Better Colors)
 */
const WaitingState = ({ partnerName, onClose }) => {
    return (
        <div className="py-12 flex flex-col items-center gap-10 justify-center animate-fade-in relative overflow-hidden">

            {/* Animated Sphere Background */}
            <div className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-64 h-64 bg-pink-100/20 rounded-full blur-3xl animate-pulse-soft -z-10" />

            {/* Central Visual */}
            <div className="relative group">
                {/* Rotating ring */}
                <div className="absolute inset-[-15px] border-4 border-dashed border-pink-200 rounded-full animate-[spin_10s_linear_infinite] opacity-50" />

                <div className="w-32 h-32 bg-white rounded-[2.5rem] flex items-center justify-center shadow-[0_20px_50px_rgba(0,0,0,0.05)] border border-white relative group-hover:scale-110 transition-transform duration-500">
                    <span className="text-5xl animate-[bounce_2s_infinite]">⏳</span>

                    {/* Pulsing Dot */}
                    <div className="absolute -top-1 -right-1 w-6 h-6 bg-pink-500 rounded-full border-4 border-white animate-pulse" />
                </div>
            </div>

            <div className="text-center space-y-4 max-w-[320px] relative z-10">
                <div className="inline-flex items-center gap-2 bg-pink-50 px-4 py-1.5 rounded-full border border-pink-100 mb-2">
                    <span className="w-2 h-2 rounded-full bg-pink-500 animate-ping"></span>
                    <span className="text-[10px] font-black text-pink-600 uppercase tracking-widest">Awaiting Response</span>
                </div>

                <h4 className="text-3xl font-black text-slate-800 tracking-tight italic">Waiting for partner...</h4>

                <div className="bg-white/40 backdrop-blur-md p-6 rounded-3xl border border-white/60 shadow-sm mt-4">
                    <p className="text-slate-500 font-bold text-sm leading-relaxed">
                        <span className="text-slate-800">{partnerName}</span> is still picking their slots. We'll notify you as soon as there's a match! 💖
                    </p>
                </div>
            </div>

            <div className="w-full space-y-6">
                {/* Horizontal Progress Indicator */}
                <div className="flex justify-center gap-3">
                    {[...Array(3)].map((_, i) => (
                        <div
                            key={i}
                            className="w-12 h-1.5 rounded-full bg-slate-100 relative overflow-hidden shadow-inner"
                        >
                            <div
                                className="absolute inset-0 bg-gradient-to-r from-pink-500 to-purple-500 animate-[shimmer_2s_infinite]"
                                style={{ animationDelay: `${i * 300}ms` }}
                            />
                        </div>
                    ))}
                </div>

                <button
                    onClick={onClose}
                    className="w-full py-5 bg-white border-2 border-slate-50 text-slate-400 hover:text-pink-500 hover:border-pink-100 hover:bg-pink-50 rounded-2xl font-black text-xs uppercase tracking-[0.2em] transition-all shadow-sm hover:shadow-md active:scale-95 flex items-center justify-center gap-3"
                >
                    <span>Keep Exploring</span>
                    <span className="text-lg">✨</span>
                </button>
            </div>
        </div>
    );
};

export default WaitingState;
