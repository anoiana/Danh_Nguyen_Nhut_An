import { client } from '../../../lib/axios';

export const login = async (credentials) => {
    return client.post('/auth/login', credentials);
};

export const register = async (userData) => {
    return client.post('/auth/register', userData);
};

export const loginWithGoogle = async (idToken) => {
    return client.post('/auth/google', { idToken });
};

export const updateProfile = async (userId, userData) => {
    return client.put(`/users/${userId}`, userData);
};

export const getUserById = async (userId) => {
    return client.get(`/users/${userId}`);
};
