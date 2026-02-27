import React from 'react';
import { formatDate } from '../../../../lib/constants';

/**
 * Displays the proposed booking with confirm/cancel actions.
 * Highly polished UI with glassmorphism and clear visual hierarchy.
 */
const ProposedBookingCard = ({ booking, isConfirmedByMe, onConfirm, onCancel }) => {
    return (
        <div className="relative group animate-fade-in px-2">

            {/* Soft Ambient Glow */}
            <div className="absolute -inset-2 bg-gradient-to-r from-pink-500/10 to-purple-600/10 rounded-[3rem] blur-2xl group-hover:from-pink-500/20 group-hover:to-purple-600/20 transition-all duration-1000"></div>

            <div className="relative bg-white/90 backdrop-blur-2xl border border-white rounded-[3rem] p-8 md:p-12 shadow-[0_30px_70px_-20px_rgba(236,72,153,0.15)] flex flex-col gap-8 overflow-hidden">

                {/* Decorative Pattern */}
                <div className="absolute top-0 right-0 w-40 h-40 bg-pink-50 rounded-full blur-3xl -z-10 opacity-60"></div>

                {/* Header Icon & Tag */}
                <div className="flex items-center gap-6 relative z-10">
                    <div className="w-16 h-16 bg-gradient-to-br from-blue-500 to-indigo-600 text-white rounded-[1.8rem] flex items-center justify-center text-3xl shadow-xl shadow-blue-200/50 transform rotate-3 group-hover:rotate-0 transition-transform">
                        📍
                    </div>
                    <div>
                        <div className="inline-flex items-center gap-2 bg-blue-50 px-3 py-1 rounded-full border border-blue-100 mb-1.5">
                            <span className="w-1.5 h-1.5 rounded-full bg-blue-500 animate-pulse"></span>
                            <span className="text-[9px] font-black text-blue-600 uppercase tracking-widest">Venue Proposal</span>
                        </div>
                        <p className="text-slate-800 font-black text-2xl tracking-tighter">Smart Midpoint Match</p>
                    </div>
                </div>

                {/* Details Section - Stacked for clarity */}
                <div className="space-y-6 relative z-10">
                    <div className="flex items-start gap-4 p-5 rounded-3xl bg-slate-50/80 border border-white/60">
                        <span className="text-xl mt-0.5">📅</span>
                        <div>
                            <p className="text-[10px] font-black text-slate-400 uppercase tracking-widest leading-none mb-2">Selected Time</p>
                            <p className="text-slate-800 font-black text-lg leading-tight uppercase tracking-tight">
                                {formatDate(booking.startTime)}
                            </p>
                        </div>
                    </div>

                    <div className="flex items-start gap-4 p-5 rounded-3xl bg-pink-50/50 border border-pink-100/30">
                        <span className="text-xl mt-0.5">☕</span>
                        <div className="flex-1">
                            <p className="text-[10px] font-black text-pink-400 uppercase tracking-widest leading-none mb-2">Recommended Venue</p>
                            <p className="text-pink-600 font-black text-lg leading-tight italic underline decoration-pink-200 underline-offset-4">
                                {booking.venue}
                            </p>
                        </div>
                    </div>
                </div>

                {/* Help Text */}
                <p className="text-slate-400 text-[10px] font-bold leading-relaxed px-4 text-center italic">
                    Both parties need to confirm and pay a commitment fee (100k drinks) to reserve the spot and receive the date ticket.
                </p>

                {/* Actions */}
                <div className="pt-2 relative z-10 space-y-5">
                    <button
                        disabled={isConfirmedByMe}
                        onClick={onConfirm}
                        className={`w-full py-6 font-black text-sm uppercase tracking-[0.3em] rounded-[2rem] transition-all relative overflow-hidden group/btn ${isConfirmedByMe
                            ? 'bg-emerald-50 text-emerald-500 border-2 border-emerald-100 shadow-emerald-100'
                            : 'bg-gradient-to-r from-pink-500 via-rose-500 to-purple-600 text-white shadow-2xl shadow-pink-200/50 hover:shadow-pink-300 hover:-translate-y-1 active:scale-95'
                            }`}
                    >
                        <span className="relative z-10 flex items-center justify-center gap-3">
                            {isConfirmedByMe ? (
                                <>
                                    <span>PAID - WAITING FOR PARTNER</span>
                                    <span className="text-xl">⌛</span>
                                </>
                            ) : (
                                <>
                                    <span>PAYMENT (100K)</span>
                                    <span className="text-xl group-hover/btn:translate-x-3 transition-transform">💳</span>
                                </>
                            )}
                        </span>
                    </button>

                    <button
                        onClick={onCancel}
                        className="w-full py-3 text-slate-300 hover:text-rose-500 font-black text-[10px] uppercase tracking-[0.3em] transition-all flex items-center justify-center gap-3 group/cancel"
                    >
                        <span className="group-hover/cancel:rotate-90 transition-transform">✕</span>
                        NOT SUITABLE? CANCEL & RESCHEDULE
                    </button>

                    {/* Progress Tracker */}
                    <div className="flex justify-center items-center gap-12 pt-4">
                        <div className="flex flex-col items-center gap-2.5">
                            <div className={`w-3.5 h-3.5 rounded-full border-4 border-white shadow-lg ${booking.requesterConfirmed ? 'bg-emerald-500 shadow-emerald-200 animate-pulse' : 'bg-slate-200'}`} />
                            <p className="text-[8px] font-black text-slate-400 uppercase tracking-widest">You</p>
                        </div>

                        <div className="w-12 h-[2px] bg-slate-100 rounded-full" />

                        <div className="flex flex-col items-center gap-2.5">
                            <div className={`w-3.5 h-3.5 rounded-full border-4 border-white shadow-lg ${booking.recipientConfirmed ? 'bg-emerald-500 shadow-emerald-200 animate-pulse' : 'bg-slate-200'}`} />
                            <p className="text-[8px] font-black text-slate-400 uppercase tracking-widest">Partner</p>
                        </div>
                    </div>
                </div>

                {/* Ticket Notch Effects */}
                <div className="absolute -left-5 top-[55%] w-10 h-10 bg-[#f8fafc] rounded-full shadow-inner border border-slate-100" />
                <div className="absolute -right-5 top-[55%] w-10 h-10 bg-[#f8fafc] rounded-full shadow-inner border border-slate-100" />
            </div>
        </div>
    );
};

export default ProposedBookingCard;
