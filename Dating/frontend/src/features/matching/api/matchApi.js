import { client } from '../../../lib/axios';

// Mock function for getting feed, assuming API exists or using a generic implementation
export const getFeed = async (userId, filters = {}) => {
    return client.get('/users/feed', {
        params: {
            userId,
            minAge: filters.minAge,
            maxAge: filters.maxAge,
            gender: filters.gender,
            interest: filters.interest
        }
    });
};

export const likeUser = async (fromUserId, toUserId) => {
    return client.post('/likes', { fromUserId, toUserId });
};

export const skipUser = async (fromUserId, toUserId) => {
    return client.post('/likes/skip', { fromUserId, toUserId });
};

export const getMatches = async (userId) => {
    return client.get('/matches', { params: { userId } });
};

export const getWaitingMatches = (userId) => {
    return client.get('/matches/waiting', { params: { userId } });
};

export const getMatchStatus = (u1Id, u2Id) => {
    return client.get('/matches/status', { params: { u1Id, u2Id } });
};

export const addAvailability = (data) => client.post('/availabilities', data);

export const submitAvailability = (userId, targetUserId) =>
    client.post(`/availabilities/submit?userId=${userId}&targetUserId=${targetUserId}`);

export const confirmBooking = (bookingId, userId) =>
    client.post(`/availabilities/confirm?bookingId=${bookingId}&userId=${userId}`);

export const getBooking = (u1Id, u2Id) =>
    client.get(`/availabilities/booking?u1Id=${u1Id}&u2Id=${u2Id}`);

export const getBookingById = (id) =>
    client.get(`/bookings/${id}`);

export const getMyBookings = (userId) =>
    client.get(`/availabilities/my?userId=${userId}`);

export const getUserAvailabilities = (userId) =>
    client.get(`/availabilities/user/${userId}`);

export const deleteAvailability = (id) =>
    client.delete(`/availabilities/${id}`);

export const cancelBooking = (id, userId) =>
    client.delete(`/availabilities/booking/${id}?userId=${userId}`);

export const submitFeedback = (bookingId, userId, attended, wantsContact) =>
    client.post(`/bookings/${bookingId}/feedback?userId=${userId}&attended=${attended}&wantsContact=${wantsContact}`);
