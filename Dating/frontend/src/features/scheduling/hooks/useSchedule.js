import { useState } from 'react';
import { submitSlots, checkCommonTime } from '../api/scheduleApi';

export const useSchedule = (userId) => {
    // Current user's slots to add
    const [slots, setSlots] = useState([]);

    // Check match feature
    const [matchResult, setMatchResult] = useState(null);
    const [loading, setLoading] = useState(false);
    const [error, setError] = useState(null);

    const addSlot = (start, end) => {
        setSlots([...slots, { startTime: start, endTime: end, id: Date.now() }]);
    };

    const removeSlot = (id) => {
        setSlots(slots.filter(s => s.id !== id));
    };

    const handleSubmit = async () => {
        if (slots.length === 0) return;
        setLoading(true);
        setError(null);
        try {
            await Promise.all(slots.map(slot => submitSlots(userId, {
                startTime: slot.startTime,
                endTime: slot.endTime
            })));
            setSlots([]);
            return true;
        } catch (err) {
            console.error(err);
            setError('Failed to submit slots.');
            return false;
        } finally {
            setLoading(false);
        }
    };

    const handleCheckMatch = async (otherUserId) => {
        setLoading(true);
        setMatchResult(null);
        try {
            const response = await checkCommonTime(userId, otherUserId);
            // Response might be a Slot { startTime, endTime } or "No common availability found."
            if (response.data && response.data.startTime) {
                setMatchResult(response.data);
            } else {
                setMatchResult(null);
                // Maybe set a "Not found" message state?
                setError("No common time found."); // Using error state for message
            }
        } catch (err) {
            console.error(err);
            setError('Error checking match time.');
        } finally {
            setLoading(false);
        }
    };

    return {
        slots,
        addSlot,
        handleSubmit,
        handleCheckMatch,
        matchResult,
        loading,
        error
    };
};
