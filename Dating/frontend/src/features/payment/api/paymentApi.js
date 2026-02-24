import { client } from '../../../lib/axios';

export const createPaymentUrl = async (bookingId) => {
    return client.get('/payments/create-url', {
        params: { bookingId }
    });
};

export const verifyPayment = async (params) => {
    return client.get('/payments/verify-payment', { params });
};
