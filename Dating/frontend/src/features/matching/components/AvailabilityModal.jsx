import React from 'react';
import { createPortal } from 'react-dom';
import { useAvailability } from '../hooks/useAvailability';

// Sub-components (each < 80 lines, single responsibility)
import SlotPicker from './availability/SlotPicker';
import SlotList from './availability/SlotList';
import WaitingState from './availability/WaitingState';
import ProposedBookingCard from './availability/ProposedBookingCard';
import ConfirmedTicket from './availability/ConfirmedTicket';
import ConfirmModal from '../../../components/common/ConfirmModal';
import { useState } from 'react';

/**
 * AvailabilityModal — Thin orchestrator component.
 *
 * BEFORE refactor: 499 lines (logic + UI + WebSocket all mixed together)
 * AFTER refactor:  ~90 lines (pure rendering, delegates to hook + sub-components)
 *
 * Architecture:
 *   useAvailability (hook)  → All business logic, API calls, WebSocket
 *   SlotPicker               → Date/time input form
 *   SlotList                  → Saved slots display
 *   WaitingState              → "Waiting for partner" UI
 *   ProposedBookingCard       → Proposed booking with confirm/cancel
 *   ConfirmedTicket           → Confirmed date e-ticket
 */
const AvailabilityModal = ({ isOpen, onClose, currentUser, matchedUser }) => {
    const {
        date, setDate,
        startTime, setStartTime,
        endTime, setEndTime,
        proposedBooking,
        userAvailabilities,
        submissionStatus,
        isConfirmedByMe,
        minDateStr, maxDateStr,
        handleAddAvailability,
        handleSubmitAvailability,
        handleConfirmBooking,
        handleCancelBooking,
        handleDeleteAvailability,
    } = useAvailability(currentUser, matchedUser, isOpen);

    const [showCancelConfirm, setShowCancelConfirm] = useState(false);

    if (!isOpen) return null;

    const headerTitle = proposedBooking?.status === 'CONFIRMED' ? 'Date Ticket' : 'Schedule a Date';
    const headerSub = proposedBooking?.status === 'CONFIRMED'
        ? 'Congratulations! You have a date!'
        : `Find a time to meet ${matchedUser.name}`;

    const showSlotPicker = !proposedBooking && submissionStatus !== 'PENDING';
    const showWaiting = !proposedBooking && submissionStatus === 'PENDING';
    const showProposed = proposedBooking?.status === 'PROPOSED';
    const showConfirmed = proposedBooking?.status === 'CONFIRMED';

    const modalContent = (
        <div className="fixed inset-0 z-[9999] flex items-center justify-center bg-black/60 backdrop-blur-md p-4 animate-fade-in">
            <div className="bg-white rounded-[3rem] p-10 max-w-xl w-full shadow-[0_30px_100px_-20px_rgba(0,0,0,0.3)] border border-white relative max-h-[90vh] overflow-y-auto transform animate-bounce-in scrollbar-premium">

                {/* Header */}
                <div className="flex justify-between items-start mb-10">
                    <div className="flex items-center gap-5">
                        <div className="w-14 h-14 bg-pink-100 rounded-3xl flex items-center justify-center shadow-inner shrink-0 transform -rotate-6">
                            <span className="text-3xl">📅</span>
                        </div>
                        <div>
                            <h3 className="text-3xl font-black text-slate-800 tracking-tighter italic">{headerTitle}</h3>
                            <p className="text-gray-400 font-bold mt-1 text-xs uppercase tracking-[0.2em] leading-none">{headerSub}</p>
                        </div>
                    </div>
                    <button
                        onClick={onClose}
                        className="w-12 h-12 flex items-center justify-center bg-gray-50 hover:bg-gray-100 rounded-2xl transition-all text-gray-400 hover:text-gray-800 shadow-sm"
                    >
                        ✕
                    </button>
                </div>

                {/* Content — conditionally rendered based on state */}
                <div className="space-y-8">
                    {showSlotPicker && (
                        <>
                            <SlotPicker
                                date={date} setDate={setDate}
                                startTime={startTime} setStartTime={setStartTime}
                                endTime={endTime} setEndTime={setEndTime}
                                minDateStr={minDateStr} maxDateStr={maxDateStr}
                                onAdd={handleAddAvailability}
                            />

                            <SlotList
                                availabilities={userAvailabilities}
                                onDelete={handleDeleteAvailability}
                            />

                            {/* Divider */}
                            <div className="relative py-2">
                                <div className="absolute inset-0 flex items-center">
                                    <div className="w-full border-t border-slate-100" />
                                </div>
                                <div className="relative flex justify-center text-[10px] font-black uppercase tracking-[0.4em]">
                                    <span className="bg-white px-6 text-slate-300 italic">Magic matching</span>
                                </div>
                            </div>

                            {/* Submit Button */}
                            <button
                                onClick={handleSubmitAvailability}
                                className="w-full py-6 bg-gradient-to-r from-pink-500 to-purple-600 text-white font-black text-sm uppercase tracking-[0.3em] rounded-[1.8rem] shadow-xl shadow-pink-200/50 hover:shadow-pink-300/50 transition-all transform hover:-translate-y-1 active:scale-95 flex items-center justify-center gap-4 group"
                            >
                                <span className="text-2xl group-hover:scale-125 transition-transform duration-500">📤</span>
                                Submit My Availability
                            </button>
                        </>
                    )}

                    {showWaiting && (
                        <WaitingState partnerName={matchedUser.name} onClose={onClose} />
                    )}

                    {showProposed && (
                        <ProposedBookingCard
                            booking={proposedBooking}
                            isConfirmedByMe={isConfirmedByMe}
                            onConfirm={handleConfirmBooking}
                            onCancel={() => setShowCancelConfirm(true)}
                        />
                    )}

                    {showConfirmed && (
                        <ConfirmedTicket booking={proposedBooking} onClose={onClose} />
                    )}
                </div>

                {/* Confirm Cancel Modal */}
                <ConfirmModal
                    isOpen={showCancelConfirm}
                    onClose={() => setShowCancelConfirm(false)}
                    onConfirm={handleCancelBooking}
                    title="Cancel this date?"
                    message="Are you sure you want to cancel and reschedule? This will clear your currently selected time slots."
                    confirmText="Yes, Cancel"
                    cancelText="Keep Date"
                    type="danger"
                />

                {/* Decorative blurs */}
                <div className="absolute -top-20 -right-20 w-48 h-48 bg-pink-100/30 rounded-full blur-3xl -z-10" />
                <div className="absolute -bottom-20 -left-20 w-48 h-48 bg-purple-100/30 rounded-full blur-3xl -z-10" />
            </div>
        </div>
    );

    return createPortal(modalContent, document.body);
};

export default AvailabilityModal;
