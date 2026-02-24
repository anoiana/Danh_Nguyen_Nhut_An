import React, { createContext, useContext, useState, useEffect } from 'react';
import { login, register, updateProfile, loginWithGoogle } from '../api/authApi';

const AuthContext = createContext();

export const AuthProvider = ({ children }) => {
    const [currentUser, setCurrentUser] = useState(() => {
        const storedUser = localStorage.getItem('currentUser');
        return storedUser ? JSON.parse(storedUser) : null;
    });
    const [loading, setLoading] = useState(false);
    const [error, setError] = useState(null);

    const handleLogin = async (credentials) => {
        setLoading(true);
        setError(null);
        try {
            const response = await login(credentials);
            const user = response.data;
            setCurrentUser(user);
            localStorage.setItem('currentUser', JSON.stringify(user));
            return user;
        } catch (err) {
            setError(err.response?.data || 'Login failed');
            throw err;
        } finally {
            setLoading(false);
        }
    };

    const handleGoogleLogin = async (idToken) => {
        setLoading(true);
        setError(null);
        try {
            const response = await loginWithGoogle(idToken);
            const user = response.data;
            setCurrentUser(user);
            localStorage.setItem('currentUser', JSON.stringify(user));
            return user;
        } catch (err) {
            setError(err.response?.data || 'Google Login failed');
            throw err;
        } finally {
            setLoading(false);
        }
    };

    const handleRegister = async (userData) => {
        setLoading(true);
        setError(null);
        try {
            await register(userData);
            return handleLogin({ email: userData.email, password: userData.password });
        } catch (err) {
            setError(err.response?.data || 'Registration failed');
            throw err;
        } finally {
            setLoading(false);
        }
    };

    const handleUpdateProfile = async (userData) => {
        setLoading(true);
        try {
            const response = await updateProfile(currentUser.id, userData);
            const updatedUser = { ...currentUser, ...response.data };
            setCurrentUser(updatedUser);
            localStorage.setItem('currentUser', JSON.stringify(updatedUser));
            return updatedUser;
        } catch (err) {
            console.error("Update profile error:", err);
            throw err;
        } finally {
            setLoading(false);
        }
    };

    const handleLogout = () => {
        setCurrentUser(null);
        localStorage.removeItem('currentUser');
    };

    return (
        <AuthContext.Provider value={{
            currentUser,
            loading,
            error,
            handleLogin,
            handleGoogleLogin,
            handleRegister,
            handleLogout,
            handleUpdateProfile
        }}>
            {children}
        </AuthContext.Provider>
    );
};

export const useAuthContext = () => {
    const context = useContext(AuthContext);
    if (!context) {
        throw new Error('useAuthContext must be used within an AuthProvider');
    }
    return context;
};
