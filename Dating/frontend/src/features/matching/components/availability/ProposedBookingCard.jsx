import React from 'react';
import { formatDate } from '../../../../lib/constants';

/**
 * Displays the proposed booking with confirm/cancel actions.
 * Extracted from AvailabilityModal.
 */
const ProposedBookingCard = ({ booking, isConfirmedByMe, onConfirm, onCancel }) => {
    return (
        <div className="bg-gradient-to-br from-blue-50 to-indigo-50 border-2 border-blue-200/50 p-8 rounded-[2.5rem] animate-fade-in shadow-xl relative overflow-hidden">
            <div className="relative z-10 space-y-4">
                <div className="flex items-center gap-4">
                    <div className="w-10 h-10 bg-blue-600 text-white rounded-full flex items-center justify-center text-xl shadow-lg ring-4 ring-white">
                        📍
                    </div>
                    <h4 className="text-blue-800 font-black uppercase text-xs tracking-[0.2em]">Venue Proposal</h4>
                </div>
                <div className="space-y-1">
                    <p className="text-slate-500 font-bold text-xs uppercase">Time:</p>
                    <p className="text-slate-800 font-black text-lg">{formatDate(booking.startTime)}</p>
                </div>
                <div className="space-y-1">
                    <p className="text-slate-500 font-bold text-xs uppercase">Venue:</p>
                    <p className="text-blue-700 font-black text-xl italic underline decoration-2">{booking.venue}</p>
                </div>
                <div className="pt-4 border-t border-blue-100">
                    <p className="text-slate-500 text-[10px] mb-4 leading-tight">
                        Both parties need to confirm and pay a commitment fee (100k drinks) to reserve the spot and receive the date ticket.
                    </p>
                    <button
                        disabled={isConfirmedByMe}
                        className={`w-full py-5 font-black text-sm uppercase tracking-widest rounded-2xl transition-all shadow-lg ${isConfirmedByMe
                            ? 'bg-slate-200 text-slate-400 cursor-not-allowed'
                            : 'bg-gradient-to-r from-pink-500 to-purple-600 text-white hover:scale-105 shadow-pink-200'
                            }`}
                        onClick={onConfirm}
                    >
                        {isConfirmedByMe ? 'Đã thanh toán - Đợi đối phương ⏳' : 'Thanh Toán (100k) 💳'}
                    </button>

                    <button
                        onClick={onCancel}
                        className="w-full mt-4 py-3 text-slate-400 hover:text-red-500 font-bold text-[10px] uppercase tracking-widest transition-colors flex items-center justify-center gap-2 group/cancel text-center"
                    >
                        <span className="group-hover/cancel:rotate-90 transition-transform">✕</span>
                        Not suitable? Cancel & Reschedule
                    </button>

                    <div className="mt-4 flex justify-center gap-2">
                        <div className={`w-3 h-3 rounded-full ${booking.requesterConfirmed ? 'bg-green-500' : 'bg-slate-200'}`} />
                        <div className={`w-3 h-3 rounded-full ${booking.recipientConfirmed ? 'bg-green-500' : 'bg-slate-200'}`} />
                    </div>
                </div>
            </div>
        </div>
    );
};

export default ProposedBookingCard;
