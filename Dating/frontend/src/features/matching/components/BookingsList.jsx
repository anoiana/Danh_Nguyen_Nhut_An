import React, { useEffect, useState } from 'react';
import { getMyBookings, cancelBooking as cancelBookingApi } from '../api/matchApi';
import { createPaymentUrl } from '../../payment/api/paymentApi';
import { useNotification } from '../../../context/NotificationContext';
import ChatWindow from './ChatWindow';
import FeedbackModal from './FeedbackModal';
import LoadingSpinner from '../../../components/common/LoadingSpinner';
import EmptyState from '../../../components/common/EmptyState';
import BookingCard from './bookings/BookingCard';

/**
 * BookingsList — Refactored with extracted BookingCard sub-component.
 *
 * BEFORE: 271 lines with massive inline card rendering
 * AFTER:  ~90 lines — clean orchestrator with LoadingSpinner, EmptyState, BookingCard
 */
const BookingsList = ({ currentUser }) => {
    const [bookings, setBookings] = useState([]);
    const [loading, setLoading] = useState(true);
    const [selectedChatUser, setSelectedChatUser] = useState(null);
    const [feedbackBooking, setFeedbackBooking] = useState(null);
    const { showNotification } = useNotification();

    const fetchBookings = async () => {
        try {
            const response = await getMyBookings(currentUser.id);
            setBookings(response.data);
        } catch (error) {
            console.error("Error fetching bookings:", error);
        } finally {
            setLoading(false);
        }
    };

    useEffect(() => {
        fetchBookings();
    }, [currentUser.id]);

    const handleConfirm = async (bookingId) => {
        try {
            showNotification('Opening VNPay Secure Portal...', 'success');
            const response = await createPaymentUrl(bookingId);
            if (response.data && response.data.url) {
                window.location.href = response.data.url;
            }
        } catch (error) {
            showNotification("VNPay connection error.", 'error');
        }
    };

    const handleCancel = async (bookingId) => {
        if (!window.confirm("Are you sure? Cancelling a confirmed date will penalize your account for 24h. ⚠️")) return;
        try {
            await cancelBookingApi(bookingId, currentUser.id);
            showNotification("Date cancelled. Penalty applied.", "warning");
            fetchBookings();
        } catch (error) {
            showNotification("Error cancelling.", "error");
        }
    };

    if (loading) {
        return <LoadingSpinner message="Checking dates..." />;
    }

    return (
        <div className="w-full max-w-5xl mx-auto space-y-8">
            {/* Header */}
            <div className="flex items-center justify-between px-4 mb-2">
                <div className="flex items-center gap-4">
                    <div className="w-12 h-12 bg-pink-100 rounded-2xl flex items-center justify-center shadow-inner">
                        <span className="text-2xl">🥂</span>
                    </div>
                    <h2 className="text-4xl font-black text-slate-800 tracking-tight italic px-2 leading-tight">
                        Your <span className="text-pink-600">Date Tickets</span>
                    </h2>
                </div>
                <div className="bg-white px-5 py-2.5 rounded-2xl border border-slate-100 shadow-sm flex items-center gap-3">
                    <span className="w-2 h-2 rounded-full bg-pink-500 animate-pulse" />
                    <span className="text-slate-800 font-black text-sm">{bookings.length}</span>
                    <span className="text-slate-400 font-bold text-[10px] uppercase tracking-[0.2em]">Total</span>
                </div>
            </div>

            {/* Content */}
            {bookings.length === 0 ? (
                <EmptyState
                    icon="😴"
                    title="No date tickets yet!"
                    description="Start sharing your availability with matches to book a date. ✨"
                />
            ) : (
                <div className="grid gap-6">
                    {bookings.map(booking => (
                        <BookingCard
                            key={booking.id}
                            booking={booking}
                            currentUser={currentUser}
                            onConfirm={handleConfirm}
                            onCancel={handleCancel}
                            onChat={setSelectedChatUser}
                            onFeedback={setFeedbackBooking}
                        />
                    ))}
                </div>
            )}

            {/* Modals */}
            {selectedChatUser && (
                <ChatWindow
                    currentUser={currentUser}
                    otherUser={selectedChatUser}
                    onClose={() => setSelectedChatUser(null)}
                />
            )}

            {feedbackBooking && (
                <FeedbackModal
                    booking={feedbackBooking}
                    currentUser={currentUser}
                    onClose={() => setFeedbackBooking(null)}
                    onSuccess={fetchBookings}
                />
            )}
        </div>
    );
};

export default BookingsList;
