import React, { createContext, useContext, useCallback } from 'react';
import toast from 'react-hot-toast';

const NotificationContext = createContext();

export const NotificationProvider = ({ children }) => {

    const showNotification = useCallback((message, type = 'info', onClick = null) => {
        const commonOptions = {
            duration: 5000,
            className: `font-bold text-sm ${onClick ? 'cursor-pointer hover:opacity-90' : ''}`,
            onClick: () => {
                if (onClick) {
                    onClick();
                    toast.dismiss();
                }
            }
        };

        if (type === 'success') {
            toast.success(message, {
                ...commonOptions,
                icon: '✅',
            });
        } else if (type === 'error') {
            toast.error(message, {
                ...commonOptions,
                icon: '❌',
            });
        } else if (type === 'match') {
            toast(message, {
                ...commonOptions,
                icon: '💖',
                style: {
                    background: 'linear-gradient(to right, #ec4899, #8b5cf6)',
                    color: '#fff',
                },
                className: `font-extrabold text-sm shadow-pink-200 ${onClick ? 'cursor-pointer hover:opacity-90' : ''}`
            });
        } else {
            toast(message, {
                ...commonOptions,
                icon: '🔔',
            });
        }
    }, []);

    return (
        <NotificationContext.Provider value={{ showNotification }}>
            {children}
        </NotificationContext.Provider>
    );
};

export const useNotification = () => useContext(NotificationContext);
