import { useState, useEffect, useCallback } from 'react';
import { useWebSocket } from '../../../hooks/useWebSocket';
import { useLoading } from '../../../context/LoadingContext';
import { useNotification } from '../../../context/NotificationContext';
import {
    addAvailability,
    submitAvailability,
    confirmBooking,
    getUserAvailabilities,
    deleteAvailability,
    getBooking,
    getMatchStatus,
    cancelBooking,
} from '../api/matchApi';
import { createPaymentUrl } from '../../payment/api/paymentApi';
import { MIN_SLOT_DURATION_MINUTES, MAX_SCHEDULE_DAYS_AHEAD, MIN_AVAILABILITY_SLOTS } from '../../../lib/constants';

/**
 * Custom hook encapsulating ALL availability/scheduling business logic.
 * This was extracted from AvailabilityModal (499 lines → ~120 lines of pure logic).
 *
 * Responsibilities:
 * - Manage availability slots (CRUD)
 * - Submit availability to trigger matching
 * - Listen for real-time scheduling updates via WebSocket
 * - Handle booking proposal confirmation/cancellation
 */
export const useAvailability = (currentUser, matchedUser, isOpen) => {
    const [date, setDate] = useState('');
    const [startTime, setStartTime] = useState('09:00');
    const [endTime, setEndTime] = useState('17:00');
    const [proposedBooking, setProposedBooking] = useState(null);
    const [userAvailabilities, setUserAvailabilities] = useState([]);
    const [submissionStatus, setSubmissionStatus] = useState(null); // 'PENDING' | 'SUCCESS' | null
    const { showLoading, hideLoading } = useLoading();
    const { showNotification } = useNotification();

    // --- Date Range Calculation ---
    const today = new Date();
    const minDateStr = today.toISOString().split('T')[0];
    const maxDate = new Date();
    maxDate.setDate(today.getDate() + MAX_SCHEDULE_DAYS_AHEAD);
    const maxDateStr = maxDate.toISOString().split('T')[0];

    // --- Data Fetching ---
    const fetchUserAvailabilities = useCallback(async () => {
        if (!currentUser?.id || !matchedUser?.id) return;
        try {
            const res = await getUserAvailabilities(currentUser.id);
            setUserAvailabilities(res.data || []);

            const matchRes = await getMatchStatus(currentUser.id, matchedUser.id);
            const match = matchRes.data;
            if (match) {
                const isUser1 = match.user1Id === currentUser.id;
                if ((isUser1 && match.status === 'PENDING_USER1_AVAIL') ||
                    (!isUser1 && match.status === 'PENDING_USER2_AVAIL')) {
                    setSubmissionStatus('PENDING');
                } else if (match.status === 'PROPOSED' || match.status === 'SCHEDULED') {
                    setSubmissionStatus('SUCCESS');
                    const bookingRes = await getBooking(currentUser.id, matchedUser.id);
                    if (bookingRes.data) setProposedBooking(bookingRes.data);
                }
            }
        } catch (error) {
            console.error('Error fetching initial data:', error);
        }
    }, [currentUser?.id, matchedUser?.id]);

    useEffect(() => {
        if (isOpen && currentUser) {
            fetchUserAvailabilities();
        }
    }, [isOpen, fetchUserAvailabilities]);

    // --- WebSocket: Real-time Scheduling Updates ---
    const handleSchedulingUpdate = useCallback((notification) => {
        if (notification.type === 'BOOKING_PROPOSED') {
            setProposedBooking(notification.data);
            setSubmissionStatus('SUCCESS');
        } else if (notification.type === 'BOOKING_UPDATE') {
            setProposedBooking(notification.data);
        } else if (notification.type === 'MATCHING_FAILED') {
            setProposedBooking(null);
            setSubmissionStatus(null);
            setUserAvailabilities([]);
        }
    }, []);

    useWebSocket(
        currentUser ? `/topic/scheduling/${currentUser.id}` : null,
        handleSchedulingUpdate,
        isOpen && !!currentUser
    );

    // --- Slot Management ---
    const handleAddAvailability = async () => {
        if (!date) return showNotification('Please select a date!', 'error');
        if (date < minDateStr || date > maxDateStr) {
            return showNotification('Please select a date within the next 3 weeks!', 'error');
        }

        const start = new Date(`${date}T${startTime}:00`);
        const end = new Date(`${date}T${endTime}:00`);

        if (date === minDateStr && start < new Date()) {
            return showNotification('Availability cannot be in the past!', 'error');
        }
        if (start >= end) {
            return showNotification('Start time must be before end time!', 'error');
        }

        const durationMinutes = (end - start) / (1000 * 60);
        if (durationMinutes < MIN_SLOT_DURATION_MINUTES) {
            return showNotification(`Each slot must be at least ${MIN_SLOT_DURATION_MINUTES} minutes! 🕒`, 'error');
        }

        const isOverlap = userAvailabilities.some(avail => {
            const existingStart = new Date(avail.startTime);
            const existingEnd = new Date(avail.endTime);
            return (start < existingEnd) && (end > existingStart);
        });

        if (isOverlap) {
            return showNotification('This slot overlaps with an existing one! ⚠️', 'warning');
        }

        const startStr = start.toISOString();
        const endStr = end.toISOString();

        showLoading();
        try {
            await addAvailability({ userId: currentUser.id, startTime: startStr, endTime: endStr });
            await fetchUserAvailabilities();
            showNotification(`Saved! Add at least ${MIN_AVAILABILITY_SLOTS} slots. ✨`, 'success');
        } catch (error) {
            console.error(error);
            showNotification('Error saving availability.', 'error');
        } finally {
            hideLoading();
        }
    };

    const handleSubmitAvailability = async () => {
        if (userAvailabilities.length < MIN_AVAILABILITY_SLOTS) {
            return showNotification(
                `You've only picked ${userAvailabilities.length} slots. Please pick at least ${MIN_AVAILABILITY_SLOTS}!`,
                'info'
            );
        }
        showLoading();
        try {
            const response = await submitAvailability(currentUser.id, matchedUser.id);
            setSubmissionStatus(response.data);
        } catch (error) {
            console.error(error);
            showNotification('Error submitting availability.', 'error');
        } finally {
            hideLoading();
        }
    };

    const handleConfirmBooking = async () => {
        if (!proposedBooking) return;
        showLoading();
        try {
            const response = await createPaymentUrl(proposedBooking.id);
            if (response.data && response.data.url) {
                window.location.href = response.data.url;
            }
        } catch (error) {
            console.error(error);
            showNotification('Error connecting to VNPay.', 'error');
        } finally {
            hideLoading();
        }
    };

    const handleCancelBooking = async () => {
        if (!proposedBooking) return;

        showLoading();
        try {
            await cancelBooking(proposedBooking.id, currentUser.id);
            setProposedBooking(null);
            setSubmissionStatus(null);
            setUserAvailabilities([]);
            showNotification('Proposal cancelled.', 'info');
        } catch (error) {
            console.error('Cancel booking error:', error);
            showNotification('Error cancelling.', 'error');
        } finally {
            hideLoading();
        }
    };

    const handleDeleteAvailability = async (id) => {
        showLoading();
        try {
            await deleteAvailability(id);
            await fetchUserAvailabilities();
            showNotification('Slot deleted.', 'info');
        } catch (error) {
            console.error(error);
            showNotification('Error deleting.', 'error');
        } finally {
            hideLoading();
        }
    };

    // --- Derived State ---
    const isConfirmedByMe = proposedBooking && (
        (proposedBooking.requesterId === currentUser?.id && proposedBooking.requesterConfirmed) ||
        (proposedBooking.recipientId === currentUser?.id && proposedBooking.recipientConfirmed)
    );

    return {
        // State
        date, setDate,
        startTime, setStartTime,
        endTime, setEndTime,
        proposedBooking,
        userAvailabilities,
        submissionStatus,
        isConfirmedByMe,
        minDateStr,
        maxDateStr,

        // Actions
        handleAddAvailability,
        handleSubmitAvailability,
        handleConfirmBooking,
        handleCancelBooking,
        handleDeleteAvailability,
    };
};
