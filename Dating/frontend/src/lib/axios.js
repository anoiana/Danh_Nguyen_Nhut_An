import axios from 'axios';

import toast from 'react-hot-toast';

// Create an instance of axios with the base URL
export const client = axios.create({
    baseURL: '/api',
    timeout: 30000, // 30 seconds timeout
});

// Add a request interceptor to add the JWT token to headers
client.interceptors.request.use(
    (config) => {
        const user = JSON.parse(localStorage.getItem('currentUser'));
        if (user && user.token) {
            config.headers.Authorization = `Bearer ${user.token}`;
        }
        return config;
    },
    (error) => Promise.reject(error)
);

// Add a response interceptor to handle errors globally
client.interceptors.response.use(
    (response) => response,
    (error) => {
        const { response } = error;

        if (!response) {
            // Network error (Server down, timeout, etc.)
            toast.error("Network problem! Please check if the server is running.", {
                id: 'network-error',
                duration: 4000
            });
        } else {
            const status = response.status;
            const message = response.data?.message || response.data || 'Something went wrong';

            switch (status) {
                case 401:
                    // Unauthorized - Clear user and redirect to login if not already there
                    if (!window.location.pathname.includes('/login') && window.location.pathname !== '/') {
                        toast.error("Session expired. Please login again.");
                        localStorage.removeItem('currentUser');
                        window.location.href = '/';
                    }
                    break;
                case 403:
                    toast.error("You don't have permission to do this.");
                    break;
                case 404:
                    // Only toast 404s for actual API calls, not profile not found which is handled by UI
                    if (error.config.url.includes('/api/')) {
                        console.error("Resource not found:", error.config.url);
                    }
                    break;
                case 413:
                    toast.error("File is too large! Please choose a smaller one.");
                    break;
                case 500:
                    toast.error("Server error! Our team is looking into it.");
                    break;
                default:
                    // Allow specific calls to handle their own minor errors, but log others
                    console.error(`API Error ${status}:`, message);
            }
        }

        return Promise.reject(error);
    }
);
