import React, { useState, useEffect, useRef, useCallback } from 'react';
import { useLocation, useNavigate, useSearchParams } from 'react-router-dom';
import { client } from '../../../lib/axios';
import { useWebSocket } from '../../../hooks/useWebSocket';
import { useNotification } from '../../../context/NotificationContext';

const ActivityCenter = ({ currentUser }) => {
    const { showNotification } = useNotification();
    const location = useLocation();
    const navigate = useNavigate();
    const [searchParams, setSearchParams] = useSearchParams();
    const [activities, setActivities] = useState([]);
    const [isOpen, setIsOpen] = useState(false);
    const [unreadCount, setUnreadCount] = useState(0);
    const lastNotificationRef = useRef(null);

    const fetchActivities = async () => {
        try {
            const response = await client.get('/activities', {
                params: { userId: currentUser.id }
            });
            setActivities(response.data);
            setUnreadCount(response.data.filter(a => !a.isRead).length);
        } catch (error) {
            console.error("Error fetching activities:", error);
        }
    };

    useEffect(() => {
        fetchActivities();
    }, [currentUser.id]);

    // --- Determine target tab for navigation ---
    const getTargetTab = (type) => {
        if (type === 'MATCH' || type === 'LIKE' || type === 'MESSAGE_NEW') return 'matches';
        if (type?.includes('BOOKING')) return 'bookings';
        return 'feed';
    };

    const navigateToTab = useCallback((targetTab) => {
        if (location.pathname === '/') {
            setSearchParams({ tab: targetTab });
        } else {
            navigate(`/?tab=${targetTab}`);
        }
    }, [location.pathname, setSearchParams, navigate]);

    // --- WebSocket: Real-time activity updates ---
    const handleActivityMessage = useCallback((newActivity) => {
        // Content-based deduplication (prevent identical messages within 2 seconds)
        const now = Date.now();
        if (lastNotificationRef.current?.content === newActivity.content &&
            now - lastNotificationRef.current.time < 2000) {
            return;
        }
        lastNotificationRef.current = { content: newActivity.content, time: now };

        setActivities(prev => {
            if (prev.find(a => a.id === newActivity.id)) return prev;
            return [newActivity, ...prev];
        });
        setUnreadCount(prev => prev + 1);

        const toastType = newActivity.type === 'MATCH' ? 'match' :
            newActivity.type === 'LIKE' ? 'success' : 'info';

        const targetTab = getTargetTab(newActivity.type);
        showNotification(newActivity.content, toastType, () => navigateToTab(targetTab));
    }, [showNotification, navigateToTab]);

    useWebSocket(
        `/topic/activities/${currentUser.id}`,
        handleActivityMessage,
        !!currentUser
    );

    // --- UI Handlers ---
    const handleToggle = async () => {
        setIsOpen(!isOpen);
        if (!isOpen && unreadCount > 0) {
            try {
                await client.post('/activities/mark-read', null, {
                    params: { userId: currentUser.id }
                });
                setUnreadCount(0);
                setTimeout(fetchActivities, 500);
            } catch (error) {
                console.error("Error marking as read:", error);
            }
        }
    };

    const handleActivityClick = (activity) => {
        setIsOpen(false);
        navigateToTab(getTargetTab(activity.type));
    };

    return (
        <div className="relative">
            {/* Bell Icon */}
            <button
                onClick={handleToggle}
                className="relative p-2.5 flex items-center justify-center group/bell transition-all"
                id="notification-bell"
            >
                <div className="text-2xl transform group-hover/bell:rotate-12 transition-transform duration-300">
                    <span className="filter drop-shadow-sm" style={{ fontSize: '1.5rem', filter: 'drop-shadow(0 2px 4px rgba(0,0,0,0.1))' }}>🔔</span>
                </div>
                {unreadCount > 0 && (
                    <span className="absolute top-1 right-1 h-5 w-5 bg-[#ef4444] text-white text-[10px] font-black rounded-full flex items-center justify-center shadow-lg border-2 border-white ring-2 ring-transparent group-hover/bell:ring-red-100 transition-all">
                        {unreadCount}
                    </span>
                )}
            </button>

            {/* Dropdown Panel */}
            {isOpen && (
                <>
                    <div className="fixed inset-0 z-40" onClick={() => setIsOpen(false)} />
                    <div className="absolute right-0 mt-3 w-80 bg-white rounded-2xl shadow-2xl border border-gray-100 z-50 overflow-hidden animate-slide-in-right transform origin-top-right">
                        <div className="p-4 border-b border-gray-50 flex justify-between items-center bg-gray-50/50">
                            <h3 className="font-black text-gray-800 tracking-tight">Latest Activities ⚡</h3>
                            <button onClick={() => setIsOpen(false)} className="text-gray-400 hover:text-gray-600">&times;</button>
                        </div>

                        <div className="max-h-[400px] overflow-y-auto">
                            {activities.length === 0 ? (
                                <div className="p-10 text-center text-gray-400">
                                    <div className="text-4xl mb-2">🎈</div>
                                    <p className="text-sm">No notifications yet.</p>
                                </div>
                            ) : (
                                activities.map(activity => (
                                    <div
                                        key={activity.id}
                                        onClick={() => handleActivityClick(activity)}
                                        className={`p-4 border-b border-gray-50 flex items-start gap-4 transition-all hover:bg-pink-50/50 cursor-pointer group/item ${!activity.isRead ? 'bg-pink-50/30' : ''}`}
                                    >
                                        <div className="text-2xl pt-1 group-hover/item:scale-110 transition-transform">
                                            {activity.type === 'MATCH' ? '💖' :
                                                activity.type === 'LIKE' ? '✨' :
                                                    activity.type === 'MESSAGE_NEW' ? '💬' : '📅'}
                                        </div>
                                        <div className="flex-1">
                                            <p className="text-sm text-gray-800 leading-snug font-medium group-hover/item:text-pink-600 transition-colors">{activity.content}</p>
                                            <p className="text-[10px] text-gray-400 mt-1.5 font-bold uppercase tracking-wider">
                                                {new Date(activity.createdAt).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })} • {new Date(activity.createdAt).toLocaleDateString()}
                                            </p>
                                        </div>
                                        {!activity.isRead && (
                                            <div className="h-2.5 w-2.5 bg-pink-500 rounded-full mt-2 shadow-[0_0_10px_rgba(236,72,153,0.5)]" />
                                        )}
                                    </div>
                                ))
                            )}
                        </div>

                        <div className="p-3 text-center border-t border-gray-50 bg-gray-50/30">
                            <button
                                onClick={() => { setIsOpen(false); navigate('/?tab=feed'); }}
                                className="text-[11px] font-black text-slate-400 hover:text-pink-500 uppercase tracking-widest transition-colors"
                            >
                                View all activities
                            </button>
                        </div>
                    </div>
                </>
            )}
        </div>
    );
};

export default ActivityCenter;
