import React, { useEffect, useState, useCallback, useRef } from 'react';
import { useWebSocket } from '../hooks/useWebSocket';
import { useLocation, useNavigate } from 'react-router-dom';
import { CheckCircle, XCircle, MapPin, Calendar, Clock } from 'lucide-react';
import { getBookingById } from '../features/matching/api/matchApi';
import { verifyPayment } from '../features/payment/api/paymentApi';
import { formatDate } from '../lib/constants';
import { useNotification } from '../context/NotificationContext';

const PaymentResult = () => {
    const location = useLocation();
    const navigate = useNavigate();
    const [status, setStatus] = useState('processing');
    const [bookingDetails, setBookingDetails] = useState(null);
    const { showNotification } = useNotification();
    const currentUser = JSON.parse(localStorage.getItem('currentUser'));
    const notifiedRef = useRef(false);

    const handleBookingUpdate = useCallback((notification) => {
        if (notification.type === 'BOOKING_UPDATE' && notification.data?.id === bookingDetails?.id) {
            setBookingDetails(notification.data);
            if (notification.data.status === 'CONFIRMED') {
                showNotification("Great news! Your partner just paid. Date is confirmed! 🥂", "success");
            }
        }
    }, [bookingDetails?.id, showNotification]);

    useWebSocket(
        currentUser ? `/topic/scheduling/${currentUser.id}` : null,
        handleBookingUpdate,
        !!currentUser
    );

    useEffect(() => {
        const searchParams = new URLSearchParams(location.search);
        const params = Object.fromEntries(searchParams.entries());
        const responseCode = params.vnp_ResponseCode;
        const bookingId = params.bookingId;

        if (responseCode === '00') {
            verifyAndFetch(params, bookingId);
        } else {
            setStatus('error');
        }
    }, [location]);

    const verifyAndFetch = async (params, bookingId) => {
        try {
            await verifyPayment(params);
            setStatus('success');
            if (bookingId) {
                const res = await getBookingById(bookingId);
                setBookingDetails(res.data);
                if (res.data.status === 'CONFIRMED') {
                    if (!notifiedRef.current) {
                        showNotification("Payment verified! Your date is officially confirmed. 🥂", "success");
                        notifiedRef.current = true;
                    }
                } else {
                    if (!notifiedRef.current) {
                        showNotification("Payment successful! Waiting for your partner... ⏳", "info");
                        notifiedRef.current = true;
                    }
                }
            }
        } catch (error) {
            console.error("Verification error:", error);
            setStatus('error');
        }
    };

    return (
        <div className="min-h-[calc(100vh-72px)] flex items-center justify-center pt-4 pb-12 px-4 overflow-hidden relative selection:bg-pink-100">
            {/* Ultra-Luxury Ambient Background */}
            <div className="absolute top-[-10%] left-[-10%] w-[40%] h-[40%] bg-gradient-to-br from-pink-400/20 to-transparent rounded-full blur-[120px] animate-pulse-soft"></div>
            <div className="absolute bottom-[-10%] right-[-10%] w-[40%] h-[40%] bg-gradient-to-tl from-purple-400/20 to-transparent rounded-full blur-[120px] animate-float"></div>

            {/* Floating Micro-Particles */}
            <div className="absolute top-1/4 right-[15%] text-2xl animate-float opacity-30 select-none">✨</div>
            <div className="absolute bottom-1/3 left-[10%] text-xl animate-float-delayed opacity-20 select-none">💖</div>
            <div className="absolute top-2/3 right-[10%] text-3xl animate-float opacity-20 select-none">🥂</div>

            <div className="w-full max-w-5xl relative z-10 animate-fade-in">
                {status === 'success' ? (
                    <div className="bg-white/30 backdrop-blur-3xl border border-white/60 p-6 md:p-14 rounded-[4rem] shadow-[0_50px_100px_-20px_rgba(0,0,0,0.12)] relative overflow-hidden group/container">

                        {/* Dynamic Sweep Glow */}
                        <div className="absolute -inset-[100%] bg-gradient-to-tr from-white/0 via-white/10 to-white/0 transform rotate-45 group-hover/container:translate-x-full transition-transform duration-[2000ms] pointer-events-none"></div>

                        <div className="flex flex-col lg:flex-row items-center gap-16">
                            {/* Left: Message Console */}
                            <div className="flex-1 text-center lg:text-left space-y-8">
                                <div className="inline-flex items-center gap-3 bg-white/80 backdrop-blur-md px-6 py-2.5 rounded-full border border-emerald-100 shadow-sm animate-bounce-soft">
                                    <div className="w-2.5 h-2.5 bg-emerald-500 rounded-full animate-pulse shadow-[0_0_10px_rgba(16,185,129,0.5)]"></div>
                                    <span className="text-[11px] font-black text-emerald-600 uppercase tracking-[0.25em]">Verified Secure</span>
                                </div>

                                <div className="space-y-4">
                                    <h2 className="text-5xl md:text-7xl font-black text-slate-900 tracking-tighter leading-[0.8] italic uppercase">
                                        {bookingDetails?.status === 'CONFIRMED' ? (
                                            <>DESTINY <span className="text-pink-500">LOCKED.</span></>
                                        ) : (
                                            <>PAYMENT <span className="text-pink-500">RECEIVED.</span></>
                                        )}
                                    </h2>
                                    <p className="text-slate-500 font-medium text-sm md:text-lg leading-relaxed max-w-sm mx-auto lg:mx-0">
                                        {bookingDetails?.status === 'CONFIRMED'
                                            ? 'The stars have aligned for you. Your physical date pass has been generated below.'
                                            : 'Your commitment is logged. We are notifying your partner to seal the deal!'}
                                    </p>
                                </div>

                                <button
                                    onClick={() => navigate('/?tab=bookings')}
                                    className="hidden lg:flex w-fit px-12 py-6 rounded-[2rem] font-black text-xs uppercase tracking-[0.4em] shadow-2xl shadow-pink-500/20 bg-slate-900 text-white transition-all duration-700 hover:bg-black hover:scale-105 active:scale-95 items-center gap-5 group"
                                >
                                    <span>Access My Dates</span>
                                    <span className="group-hover:translate-x-3 transition-transform duration-500 text-xl">✨</span>
                                </button>
                            </div>

                            {/* Right: The High-End Ticket Pass */}
                            {bookingDetails && (
                                <div className="w-full max-w-[380px] relative perspective-1000">
                                    <div className="bg-white rounded-[3rem] overflow-hidden shadow-[0_50px_100px_-20px_rgba(0,0,0,0.3)] border border-slate-100 relative group/ticket hover:rotate-1 transition-transform duration-1000">

                                        {/* Ticket Header: Brand Identity */}
                                        <div className="bg-gradient-to-br from-slate-900 via-slate-800 to-black p-8 text-white text-center relative overflow-hidden">
                                            <div className="absolute top-0 left-0 w-full h-full opacity-10 pointer-events-none bg-[radial-gradient(circle_at_50%_50%,rgba(255,255,255,0.2),transparent)]"></div>
                                            <p className="text-[10px] font-black text-pink-400 uppercase tracking-[0.5em] mb-2 relative z-10">MiniDating Reserve</p>
                                            <h4 className="text-2xl font-black italic tracking-widest relative z-10">THE PASS</h4>
                                        </div>

                                        {/* Ticket Main: Data Grid */}
                                        <div className="p-10 space-y-10 bg-white relative">
                                            <div className="space-y-6">
                                                <div className="flex items-start gap-4">
                                                    <div className="w-12 h-12 bg-pink-50 rounded-2xl flex items-center justify-center shrink-0 shadow-inner">
                                                        <MapPin className="w-6 h-6 text-pink-500" />
                                                    </div>
                                                    <div className="space-y-1">
                                                        <label className="text-[9px] font-black text-slate-400 uppercase tracking-[0.3em] block">Destination</label>
                                                        <p className="text-slate-900 font-black text-base tracking-tight leading-tight">{bookingDetails.venue}</p>
                                                    </div>
                                                </div>

                                                <div className="grid grid-cols-2 gap-8 pt-6 border-t border-slate-50">
                                                    <div className="space-y-1.5">
                                                        <label className="text-[9px] font-black text-slate-400 uppercase tracking-widest block">Calendar</label>
                                                        <p className="text-slate-800 font-bold text-sm">
                                                            {new Date(bookingDetails.startTime).toLocaleDateString(undefined, { month: 'short', day: 'numeric', weekday: 'long' })}
                                                        </p>
                                                    </div>
                                                    <div className="space-y-1.5">
                                                        <label className="text-[9px] font-black text-slate-400 uppercase tracking-widest block">Entry Time</label>
                                                        <p className="text-pink-500 font-black text-xl italic tracking-tighter">
                                                            {new Date(bookingDetails.startTime).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })}
                                                        </p>
                                                    </div>
                                                </div>
                                            </div>

                                            {/* Luxury Decoration: Separation Line */}
                                            <div className="relative py-2 flex items-center gap-3">
                                                <div className="flex-1 h-[1px] bg-slate-100"></div>
                                                <div className="text-[10px] text-slate-200 font-black tracking-widest uppercase">Cut Here</div>
                                                <div className="flex-1 h-[1px] bg-slate-100"></div>
                                            </div>

                                            {/* Ticket Footer: Verification */}
                                            <div className="flex items-center justify-between">
                                                <div className="space-y-3">
                                                    <div className="flex -space-x-3">
                                                        <div className="w-10 h-10 rounded-full border-[3px] border-white bg-gradient-to-tr from-pink-500 to-rose-500 shadow-lg flex items-center justify-center text-xs">✨</div>
                                                        <div className="w-10 h-10 rounded-full border-[3px] border-white bg-slate-900 shadow-lg"></div>
                                                    </div>
                                                    <p className="text-[8px] font-black text-slate-300 uppercase tracking-[0.2em] leading-none">Security Guaranteed</p>
                                                </div>
                                                <div className="text-right">
                                                    <div className="bg-slate-50 border border-slate-100 px-4 py-3 rounded-2xl inline-block">
                                                        <p className="text-[9px] font-mono font-bold text-slate-400 tracking-tight leading-none mb-1">AUTH-CODE</p>
                                                        <p className="text-sm font-mono font-black text-slate-900 leading-none">#{bookingDetails.id.toString().padStart(6, '0')}</p>
                                                    </div>
                                                </div>
                                            </div>
                                        </div>

                                        {/* Physical Perforation Simulation */}
                                        <div className="absolute left-0 top-[138px] -translate-x-1/2 w-10 h-10 bg-[#fbfcfd] rounded-full shadow-inner border-r border-slate-50"></div>
                                        <div className="absolute right-0 top-[138px] translate-x-1/2 w-10 h-10 bg-[#fbfcfd] rounded-full shadow-inner border-l border-slate-50"></div>
                                    </div>

                                    {/* Ultra-Soft Floor Shadow */}
                                    <div className="absolute -bottom-10 left-1/2 -translate-x-1/2 w-[90%] h-6 bg-black/[0.04] blur-2xl rounded-[100%]"></div>
                                </div>
                            )}
                        </div>

                        {/* Mobile Action Button */}
                        <button
                            onClick={() => navigate('/?tab=bookings')}
                            className="lg:hidden mt-12 w-full py-6 rounded-[2rem] font-black text-[11px] uppercase tracking-[0.4em] shadow-xl shadow-pink-500/20 bg-gradient-to-r from-pink-600 to-rose-600 text-white active:scale-95 transition-transform"
                        >
                            <span>My Booking List</span>
                        </button>
                    </div>
                ) : status === 'error' ? (
                    <div className="bg-white/40 backdrop-blur-3xl border border-white/60 p-16 rounded-[4rem] shadow-2xl text-center max-w-xl mx-auto flex flex-col items-center">
                        <div className="w-28 h-28 bg-white/50 rounded-full flex items-center justify-center mb-10 shadow-xl border border-red-50">
                            <XCircle className="w-14 h-14 text-red-400 stroke-[1.2]" />
                        </div>
                        <h2 className="text-5xl font-black text-slate-900 mb-6 italic tracking-tight leading-none">PROCESS <span className="text-red-500">VOID.</span></h2>
                        <p className="text-slate-500 font-medium mb-12 text-lg leading-relaxed max-w-sm">
                            The connection was severed before finalization. Zero funds were captured. Please retry.
                        </p>
                        <button
                            onClick={() => navigate('/')}
                            className="w-full max-w-xs py-6 rounded-[2rem] font-black text-[11px] uppercase tracking-[0.3em] bg-slate-900 text-white hover:bg-black transition-all shadow-2xl shadow-slate-200"
                        >
                            Return Home
                        </button>
                    </div>
                ) : (
                    <div className="text-center space-y-12 py-32">
                        <div className="relative mx-auto w-28 h-28">
                            <div className="absolute inset-0 border-[8px] border-pink-500/10 rounded-full"></div>
                            <div className="absolute inset-0 border-[8px] border-pink-500 border-t-transparent rounded-full animate-spin"></div>
                            <div className="absolute inset-6 border-[4px] border-purple-500/5 rounded-full"></div>
                            <div className="absolute inset-6 border-[4px] border-purple-400 border-b-transparent rounded-full animate-spin-slow"></div>
                            <div className="absolute inset-0 flex items-center justify-center text-2xl">✨</div>
                        </div>
                        <div className="space-y-4">
                            <p className="text-4xl font-black text-slate-900 italic tracking-tighter animate-pulse">SYNCHRONIZING...</p>
                            <p className="text-slate-400 font-black text-[10px] uppercase tracking-[0.6em]">Do not refresh the secure pipe</p>
                        </div>
                    </div>
                )}
            </div>
        </div>
    );
};

export default PaymentResult;
