import React from 'react';
import { getDefaultAvatar } from '../../../../lib/constants';

/**
 * Individual booking card with ticket-stub design.
 * Extracted from BookingsList.jsx to follow SRP.
 *
 * Backend DTO (DateBookingDto) returns FLAT fields:
 *   requesterId, requesterName, recipientId, recipientName,
 *   startTime, endTime, status, venue,
 *   requesterConfirmed, recipientConfirmed,
 *   requesterWantsContact, recipientWantsContact, contactExchanged
 */
const BookingCard = ({ booking, currentUser, onConfirm, onCancel, onChat, onFeedback }) => {
    const isRequester = booking.requesterId === currentUser.id;
    const otherUser = {
        id: isRequester ? booking.recipientId : booking.requesterId,
        name: isRequester ? booking.recipientName : booking.requesterName,
    };

    const startTime = new Date(booking.startTime);
    const endTime = new Date(booking.endTime);
    const now = new Date();

    const isPast = now > endTime;
    const isHappening = now >= startTime && now <= endTime;
    const iHaveConfirmed = isRequester ? booking.requesterConfirmed : booking.recipientConfirmed;
    const theyHaveConfirmed = isRequester ? booking.recipientConfirmed : booking.requesterConfirmed;
    const iHaveGivenFeedback = isRequester
        ? booking.requesterWantsContact !== null && booking.requesterWantsContact !== undefined
        : booking.recipientWantsContact !== null && booking.recipientWantsContact !== undefined;
    const isConfirmed = booking.status === 'CONFIRMED';
    const isContactExchanged = booking.contactExchanged;

    const statusBadge = isPast
        ? { text: '📝 Completed', className: 'bg-slate-800 text-white' }
        : isHappening
            ? { text: '🔥 Happening Now', className: 'bg-pink-500 text-white animate-pulse shadow-pink-200' }
            : isConfirmed
                ? { text: '✨ Confirmed', className: 'bg-green-500 text-white shadow-green-200' }
                : { text: '⏳ Pending', className: 'bg-orange-500 text-white shadow-orange-200' };

    return (
        <div className="relative group">
            {/* Status Badge */}
            <div className={`absolute -top-3 right-6 z-10 px-4 py-1.5 rounded-full text-[10px] font-black uppercase tracking-widest shadow-lg ${statusBadge.className}`}>
                {statusBadge.text}
            </div>

            <div className={`glass-card rounded-[2.5rem] overflow-hidden hover:shadow-2xl transition-all duration-500 border-white/80 flex flex-col md:flex-row items-stretch min-h-[180px] ${isPast ? 'opacity-75 grayscale-[0.3]' : ''}`}>
                {/* Left Photo Strip */}
                <div className="w-full md:w-48 bg-gray-100 relative overflow-hidden">
                    <img
                        src={getDefaultAvatar(otherUser.id)}
                        className="w-full h-full object-cover transition-transform duration-700 group-hover:scale-110"
                        alt={otherUser.name}
                    />
                    <div className="absolute inset-0 bg-gradient-to-r from-black/20 to-transparent" />
                    {isContactExchanged && (
                        <div className="absolute top-2 left-2 animate-bounce">
                            <span className="bg-pink-500 text-white text-[8px] font-black px-2 py-1 rounded-full uppercase">
                                Contact Swap! 📱
                            </span>
                        </div>
                    )}
                </div>

                {/* Content Info */}
                <div className="flex-1 p-8 flex flex-col justify-center space-y-4">
                    <div>
                        <h3 className="text-2xl font-black text-gray-800 tracking-tight">
                            Date with <span className="text-pink-600">{otherUser.name}</span>
                        </h3>
                        <p className="text-blue-600 font-black text-sm uppercase tracking-widest mt-1">
                            📍 {booking.venue}
                        </p>
                    </div>

                    {isContactExchanged ? (
                        <div className="bg-gradient-to-r from-pink-50 to-purple-50 p-4 rounded-2xl border border-pink-100 animate-fade-in">
                            <label className="text-[10px] font-black text-pink-400 uppercase tracking-widest block mb-1">
                                Mutual Interest revealed!
                            </label>
                            <p className="text-[8px] text-slate-400 font-medium mt-1">
                                Both of you want to stay connected! ✨
                            </p>
                        </div>
                    ) : (
                        <div className="flex items-center gap-6">
                            <div className="flex flex-col">
                                <span className="text-[10px] font-black text-slate-400 uppercase tracking-widest leading-none mb-1">
                                    Date
                                </span>
                                <span className="text-slate-700 font-black text-sm">
                                    {startTime.toLocaleDateString('en-US', { weekday: 'long', day: 'numeric', month: 'long' })}
                                </span>
                            </div>
                            <div className="flex flex-col border-l border-slate-200 pl-6">
                                <span className="text-[10px] font-black text-slate-400 uppercase tracking-widest leading-none mb-1">
                                    Time
                                </span>
                                <span className="text-pink-500 font-black text-xl italic">
                                    {startTime.toLocaleTimeString('en-US', { hour: '2-digit', minute: '2-digit' })}
                                </span>
                            </div>
                        </div>
                    )}
                </div>

                {/* Side Actions (Ticket Stub) */}
                <div className={`w-full md:w-64 p-8 flex flex-col justify-center gap-3 border-t md:border-t-0 md:border-l border-dashed border-slate-200 
                    ${isHappening ? 'bg-pink-50/30' : isConfirmed ? 'bg-green-50/30' : 'bg-orange-50/30'}`}>
                    {isPast ? (
                        !iHaveGivenFeedback ? (
                            <button
                                onClick={() => onFeedback(booking)}
                                className="w-full bg-slate-900 text-white py-4 rounded-2xl text-[10px] font-black uppercase tracking-widest shadow-xl hover:bg-black transition-all flex items-center justify-center gap-2 active:scale-95 animate-pulse"
                            >
                                <span>💌</span> Rate the Date
                            </button>
                        ) : (
                            <div className="text-center space-y-4">
                                <div className="flex flex-col items-center">
                                    <span className="text-2xl">✅</span>
                                    <p className="text-[10px] font-black text-slate-400 uppercase tracking-widest mt-1">
                                        Feedback Sent
                                    </p>
                                </div>
                                {isContactExchanged && (
                                    <button
                                        onClick={() => onChat(otherUser)}
                                        className="w-full bg-slate-900 text-white py-3 rounded-2xl text-[10px] font-black uppercase tracking-widest shadow-lg hover:bg-black transition-all flex items-center justify-center gap-2 active:scale-95 animate-fade-in"
                                    >
                                        <span>💬</span> Keep Chatting
                                    </button>
                                )}
                            </div>
                        )
                    ) : (
                        <>
                            <div className="flex flex-col gap-2 mb-2">
                                <div className="flex items-center gap-2">
                                    <span className={`w-2 h-2 rounded-full ${iHaveConfirmed ? 'bg-green-500' : 'bg-slate-300'}`} />
                                    <span className="text-[10px] font-bold text-slate-500 uppercase tracking-widest">
                                        You: {iHaveConfirmed ? 'OK' : 'No'}
                                    </span>
                                </div>
                                <div className="flex items-center gap-2">
                                    <span className={`w-2 h-2 rounded-full ${theyHaveConfirmed ? 'bg-green-500' : 'bg-slate-300'}`} />
                                    <span className="text-[10px] font-bold text-slate-500 uppercase tracking-widest">
                                        {otherUser.name}: {theyHaveConfirmed ? 'OK' : 'No'}
                                    </span>
                                </div>
                            </div>

                            {!iHaveConfirmed && (
                                <button
                                    onClick={() => onConfirm(booking.id)}
                                    className="w-full bg-pink-500 text-white py-3 rounded-2xl text-[10px] font-black uppercase tracking-widest shadow-lg shadow-pink-200 hover:bg-pink-600 transition-all active:scale-95"
                                >
                                    💳 Pay Now (100k)
                                </button>
                            )}

                            {(isConfirmed || isHappening) && (
                                <div className="flex flex-col gap-2">
                                    <button
                                        onClick={() => onChat(otherUser)}
                                        className="w-full bg-slate-900 text-white py-3 rounded-2xl text-[10px] font-black uppercase tracking-widest shadow-lg hover:bg-slate-800 transition-all flex items-center justify-center gap-2 active:scale-95"
                                    >
                                        <span>💬</span> Chat Now
                                    </button>
                                    <button
                                        onClick={() => onCancel(booking.id)}
                                        className="w-full text-slate-400 py-1 text-[8px] font-black uppercase tracking-widest hover:text-red-500 transition-all text-center"
                                    >
                                        ✕ Cancel Date
                                    </button>
                                </div>
                            )}
                        </>
                    )}
                </div>
            </div>

            {/* Aesthetic Ticket Punch Hole */}
            <div className="hidden md:block absolute top-1/2 left-[calc(100%-256px)] -translate-x-1/2 -translate-y-1/2 w-6 h-6 bg-[#f8fafc] rounded-full border border-slate-100 z-10 shadow-inner" />
        </div>
    );
};

export default BookingCard;
