import { client } from '../../../lib/axios';

// DTO expected by backend: { userId, startTime, endTime }
// We assume slots is an array, but the backend accepts single objects via POST /api/availabilities
// Here we might loop or backend might accept bulk? Backend: POST /api/availabilities only single.
// So we loop on frontend or assume submitSlots submits one by one?
// The prompt says "submitSlots(userId, slots)". "slots" plural.
// I'll implement submitSlots to handle multiple calls or assume bulk upload.
// For simplicity and backend compatibility (AvailabilityController), I loops.

export const submitSlots = async (userId, targetUserId) => {
    // POST /api/availabilities/submit?userId=...&targetUserId=...
    return client.post('/availabilities/submit', null, {
        params: { userId, targetUserId }
    });
};

export const getBooking = async (u1Id, u2Id) => {
    // GET /api/availabilities/booking?u1Id=...&u2Id=...
    return client.get('/availabilities/booking', {
        params: { u1Id, u2Id }
    });
};

export const getMyBookings = async (userId) => {
    // GET /api/availabilities/my?userId=...
    return client.get('/availabilities/my', {
        params: { userId }
    });
};
