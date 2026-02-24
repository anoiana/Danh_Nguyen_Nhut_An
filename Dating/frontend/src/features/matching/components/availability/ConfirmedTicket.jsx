import React from 'react';
import { useNavigate } from 'react-router-dom';
import { formatDate } from '../../../../lib/constants';

/**
 * Confirmed booking "e-ticket" card display.
 * Extracted from AvailabilityModal.
 */
const ConfirmedTicket = ({ booking, onClose }) => {
    const navigate = useNavigate();

    return (
        <div className="animate-bounce-in">
            <div className="bg-slate-900 rounded-[2.5rem] overflow-hidden shadow-2xl border-4 border-pink-500/20 relative">
                <div className="bg-gradient-to-r from-pink-500 to-purple-600 p-8 text-white relative overflow-hidden">
                    <div className="absolute top-0 right-0 p-4 opacity-10 text-8xl">🥂</div>
                    <h4 className="text-3xl font-black italic tracking-tighter">THE FIRST DATE</h4>
                    <p className="text-pink-100 font-black text-[10px] uppercase tracking-[0.4em] mt-1">
                        E-Ticket Verified
                    </p>
                </div>
                <div className="p-8 space-y-6 text-white bg-slate-900 border-t-4 border-dashed border-slate-800 relative">
                    <div className="grid grid-cols-2 gap-8">
                        <div className="space-y-1">
                            <p className="text-slate-500 font-black text-[10px] uppercase tracking-widest">Time</p>
                            <p className="text-sm font-bold leading-tight">{formatDate(booking.startTime)}</p>
                        </div>
                        <div className="space-y-1">
                            <p className="text-slate-500 font-black text-[10px] uppercase tracking-widest">Venue</p>
                            <p className="text-sm font-bold leading-tight">{booking.venue}</p>
                        </div>
                    </div>
                    <div className="pt-6 border-t border-slate-800 flex items-center gap-6">
                        <div className="bg-white p-3 rounded-2xl w-24 h-24 shrink-0 flex items-center justify-center">
                            <span className="text-4xl text-slate-800">🎟️</span>
                        </div>
                        <div>
                            <p className="text-pink-400 font-black text-sm italic">Support 24/7</p>
                            <p className="text-slate-500 text-[10px] font-medium leading-relaxed">
                                Present this ticket at the venue to receive our special drink offers!
                            </p>
                        </div>
                    </div>
                </div>
                {/* Ticket punch holes */}
                <div className="absolute left-0 top-[110px] -translate-x-1/2 w-8 h-8 bg-slate-900 rounded-full border-r border-slate-800" />
                <div className="absolute right-0 top-[110px] translate-x-1/2 w-8 h-8 bg-slate-900 rounded-full border-l border-slate-800" />
            </div>
            <button
                onClick={() => {
                    onClose();
                    navigate('/?tab=bookings');
                }}
                className="w-full mt-10 py-5 bg-gradient-to-r from-slate-800 to-slate-900 text-white rounded-[1.5rem] font-black text-sm uppercase tracking-[0.2em] hover:scale-[1.02] active:scale-95 transition-all shadow-xl flex items-center justify-center gap-3 group"
            >
                <span>Finish</span>
                <span className="group-hover:translate-x-1 transition-transform">✨</span>
            </button>
        </div>
    );
};

export default ConfirmedTicket;
