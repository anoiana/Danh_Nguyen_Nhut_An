import React, { useEffect, useState } from 'react';
import { useLocation, useNavigate } from 'react-router-dom';
import { CheckCircle, XCircle, MapPin, Calendar, Clock } from 'lucide-react';
import { getBookingById } from '../features/matching/api/matchApi';
import { verifyPayment } from '../features/payment/api/paymentApi';
import { formatDate } from '../lib/constants';

const PaymentResult = () => {
    const location = useLocation();
    const navigate = useNavigate();
    const [status, setStatus] = useState('processing');
    const [bookingDetails, setBookingDetails] = useState(null);

    useEffect(() => {
        const searchParams = new URLSearchParams(location.search);
        const params = Object.fromEntries(searchParams.entries());
        const responseCode = params.vnp_ResponseCode;
        const bookingId = params.bookingId;

        if (responseCode === '00') {
            // Step 1: Tell backend to verify the hash and update DB immediately
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
            }
        } catch (error) {
            console.error("Verification error:", error);
            setStatus('error');
        }
    };

    return (
        <div className="min-h-screen flex items-center justify-center pt-[72px] pb-[100px] px-4">
            <div className="bg-white/70 backdrop-blur-xl border border-slate-200/50 p-8 rounded-3xl shadow-xl w-full max-w-md text-center">
                {status === 'success' ? (
                    <>
                        <div className="w-20 h-20 bg-emerald-100 rounded-full flex items-center justify-center mx-auto mb-6">
                            <CheckCircle className="w-10 h-10 text-emerald-500" />
                        </div>
                        <h2 className="text-2xl font-bold text-slate-800 mb-2">Payment Successful!</h2>
                        <p className="text-slate-500 mb-6 text-sm">
                            Your payment has been processed! Once your partner also pays, the date will be finalized.
                        </p>

                        {bookingDetails && (
                            <div className="bg-gradient-to-br from-pink-50/50 to-purple-50/50 border border-pink-100 rounded-3xl p-6 mb-8 text-left relative overflow-hidden group">
                                <div className="absolute top-0 right-0 p-3 opacity-10 group-hover:opacity-20 transition-opacity">
                                    <span className="text-6xl">🎫</span>
                                </div>
                                <div className="relative z-10 space-y-4">
                                    <div className="flex items-center gap-3">
                                        <div className="w-8 h-8 bg-white rounded-xl shadow-sm flex items-center justify-center">
                                            <MapPin className="w-4 h-4 text-pink-500" />
                                        </div>
                                        <div>
                                            <p className="text-[10px] font-black text-slate-400 uppercase tracking-widest leading-none mb-1">Venue</p>
                                            <p className="text-slate-800 font-bold text-sm">{bookingDetails.venue}</p>
                                        </div>
                                    </div>
                                    <div className="grid grid-cols-2 gap-4">
                                        <div className="flex items-center gap-3">
                                            <div className="w-8 h-8 bg-white rounded-xl shadow-sm flex items-center justify-center">
                                                <Calendar className="w-4 h-4 text-pink-500" />
                                            </div>
                                            <div>
                                                <p className="text-[10px] font-black text-slate-400 uppercase tracking-widest leading-none mb-1">Date</p>
                                                <p className="text-slate-800 font-bold text-xs">
                                                    {new Date(bookingDetails.startTime).toLocaleDateString()}
                                                </p>
                                            </div>
                                        </div>
                                        <div className="flex items-center gap-3">
                                            <div className="w-8 h-8 bg-white rounded-xl shadow-sm flex items-center justify-center">
                                                <Clock className="w-4 h-4 text-pink-500" />
                                            </div>
                                            <div>
                                                <p className="text-[10px] font-black text-slate-400 uppercase tracking-widest leading-none mb-1">Time</p>
                                                <p className="text-slate-800 font-bold text-xs">
                                                    {new Date(bookingDetails.startTime).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })}
                                                </p>
                                            </div>
                                        </div>
                                    </div>
                                </div>
                                {/* Punch hole effect */}
                                <div className="absolute -left-3 top-1/2 -translate-y-1/2 w-6 h-6 bg-white rounded-full border border-pink-50 shadow-inner" />
                                <div className="absolute -right-3 top-1/2 -translate-y-1/2 w-6 h-6 bg-white rounded-full border border-pink-50 shadow-inner" />
                            </div>
                        )}

                        <button
                            onClick={() => navigate('/?tab=bookings')}
                            className="w-full py-4 rounded-xl font-bold shadow-lg shadow-pink-500/20 bg-gradient-to-r from-pink-500 to-rose-500 text-white transition-all duration-300 hover:scale-[1.02] hover:shadow-xl hover:shadow-pink-500/30 active:scale-[0.98]"
                        >
                            Go to Your Bookings 📅
                        </button>
                    </>
                ) : status === 'error' ? (
                    <>
                        <div className="w-20 h-20 bg-red-100 rounded-full flex items-center justify-center mx-auto mb-6">
                            <XCircle className="w-10 h-10 text-red-500" />
                        </div>
                        <h2 className="text-2xl font-bold text-slate-800 mb-2">Payment Failed</h2>
                        <p className="text-slate-500 mb-8">
                            Your transaction was cancelled or an error occurred. Please try again later.
                        </p>
                        <button
                            onClick={() => navigate('/')}
                            className="w-full py-4 rounded-xl font-bold bg-slate-100 text-slate-700 hover:bg-slate-200 transition-colors"
                        >
                            Back to Home
                        </button>
                    </>
                ) : (
                    <div className="py-12">
                        <div className="w-12 h-12 border-4 border-pink-500 border-t-transparent rounded-full animate-spin mx-auto mb-4"></div>
                        <p className="text-slate-500">Processing payment results...</p>
                    </div>
                )}
            </div>
        </div>
    );
};

export default PaymentResult;
