import { useState, useEffect } from 'react';
import { getFeed, likeUser as likeUserApi, skipUser, getWaitingMatches } from '../api/matchApi';

export const useFeed = (userId, filters = {}) => {
    const [profiles, setProfiles] = useState([]);
    const [loading, setLoading] = useState(false);
    const [error, setError] = useState(null);

    useEffect(() => {
        if (userId) {
            fetchFeed();
        }
    }, [userId, filters.gender, filters.minAge, filters.maxAge, filters.interest]);

    const fetchFeed = async () => {
        setLoading(true);
        setError(null);
        try {
            const response = await getFeed(userId, filters);
            setProfiles(response.data);
        } catch (err) {
            console.error('Error fetching feed:', err);
            if (err.response?.data?.errorCode === 'USER_PENALIZED') {
                setError(err.response.data.message);
                setProfiles([]);
            }
        } finally {
            setLoading(false);
        }
    };

    const handleLike = async (toUserId) => {
        try {
            await likeUserApi(userId, toUserId);
            // Remove the liked profile from the feed locally
            setProfiles(prev => prev.filter(p => p.id !== toUserId));
        } catch (error) {
            console.error('Error liking user:', error);
        }
    };

    const handleSkip = async (toUserId) => {
        try {
            await skipUser(userId, toUserId);
            // Remove from local state
            setProfiles(prev => prev.filter(p => p.id !== toUserId));
        } catch (error) {
            console.error('Error skipping user:', error);
            // Even if API fails, remove from UI to provide immediate feedback
            setProfiles(prev => prev.filter(p => p.id !== toUserId));
        }
    };

    const addProfile = (profile) => {
        setProfiles(prev => {
            if (prev.find(p => p.id === profile.id)) return prev;
            return [profile, ...prev];
        });
    };

    return {
        profiles,
        handleLike,
        handleSkip,
        loading,
        error,
        fetchFeed,
        addProfile
    };
};
