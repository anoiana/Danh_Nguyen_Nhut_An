import React, { useEffect, useState } from 'react';
import { getMatches } from '../api/matchApi';
import AvailabilityModal from './AvailabilityModal';
import { useNotification } from '../../../context/NotificationContext';
import LoadingSpinner from '../../../components/common/LoadingSpinner';
import EmptyState from '../../../components/common/EmptyState';
import { getDefaultAvatar } from '../../../lib/constants';

const MatchesList = ({ currentUser }) => {
    const [matches, setMatches] = useState([]);
    const [loading, setLoading] = useState(true);
    const [selectedUserForAvailability, setSelectedUserForAvailability] = useState(null);
    const { showNotification } = useNotification();

    useEffect(() => {
        const fetchMatches = async () => {
            try {
                const response = await getMatches(currentUser.id);
                setMatches(response.data);
            } catch (error) {
                console.error("Error fetching matches:", error);
            } finally {
                setLoading(false);
            }
        };
        fetchMatches();
    }, [currentUser.id]);

    if (loading) {
        return <LoadingSpinner message="Searching for your soulmate..." />;
    }

    return (
        <div className="w-full max-w-6xl mx-auto space-y-12 p-4 animate-fade-in mb-20">
            {/* Header Section */}
            <div className="flex flex-col md:flex-row md:items-end justify-between gap-6 px-4">
                <div className="space-y-4">
                    <div className="inline-flex items-center gap-2 bg-pink-50 px-4 py-1.5 rounded-full border border-pink-100">
                        <span className="text-pink-500 text-xs animate-pulse">●</span>
                        <span className="text-[10px] font-black text-pink-600 uppercase tracking-widest">Current Connections</span>
                    </div>
                    <h2 className="text-5xl md:text-7xl font-black text-slate-800 tracking-tight italic leading-[1.1] px-2 overflow-visible">
                        Your <span className="bg-clip-text text-transparent bg-gradient-to-r from-pink-500 to-purple-600 pb-1 pr-3">Matches</span>
                    </h2>
                    <p className="text-slate-400 font-medium max-w-md">
                        These are the people you've connected with. Let's schedule your first date! 🥂
                    </p>
                </div>

                <div className="glass-card px-8 py-4 rounded-[2rem] border-white/60 shadow-xl shadow-pink-100/20 flex items-center gap-6">
                    <div className="flex flex-col text-center">
                        <span className="text-3xl font-black text-slate-800 leading-none">{matches.length}</span>
                        <span className="text-[8px] font-black text-slate-400 uppercase tracking-widest mt-1">Matches found</span>
                    </div>
                </div>
            </div>

            {matches.length === 0 ? (
                <EmptyState
                    icon="💝"
                    title="Still waiting..."
                    description="The best things take time. Keep exploring to find your perfect match!"
                />
            ) : (
                <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-2 gap-10">
                    {matches.map((match) => {
                        // Backend DTO returns flat fields: user1Id/user1Name/user1Avatar, user2Id/user2Name/user2Avatar
                        const isUser1 = match.user1Id === currentUser.id;
                        const otherUser = {
                            id: isUser1 ? match.user2Id : match.user1Id,
                            name: isUser1 ? match.user2Name : match.user1Name,
                            avatarUrl: isUser1 ? match.user2Avatar : match.user1Avatar,
                            photos: isUser1 ? match.user2Photos : match.user1Photos,
                        };

                        if (!otherUser.id) return null;

                        return (
                            <div key={match.id} className="glass-card rounded-[3.5rem] p-8 md:p-10 hover:shadow-[0_40px_80px_rgba(236,72,153,0.15)] transition-all duration-500 group border-white/80 relative overflow-hidden flex flex-col justify-between">
                                <div className="flex items-center gap-8">
                                    <div className="relative shrink-0">
                                        <div className="w-24 h-24 md:w-32 md:h-32 rounded-[2.5rem] overflow-hidden border-[6px] border-white shadow-2xl transform rotate-3 group-hover:rotate-0 transition-transform duration-500">
                                            <img
                                                src={otherUser.avatarUrl || (otherUser.photos ? otherUser.photos.split(',')[0] : null) || getDefaultAvatar(otherUser.id)}
                                                alt={otherUser.name}
                                                className="w-full h-full object-cover"
                                            />
                                        </div>
                                    </div>

                                    <div className="flex-1 min-w-0 space-y-2">
                                        <div className="flex items-baseline gap-2">
                                            <h3 className="text-3xl font-black text-slate-800 tracking-tight truncate">
                                                {otherUser.name}
                                            </h3>
                                        </div>
                                        <p className="text-slate-400 text-sm font-medium line-clamp-2 italic leading-relaxed">
                                            "This user prefers to keep a bit of mystery... ✨"
                                        </p>
                                    </div>
                                </div>

                                <div className="grid grid-cols-1 gap-4 mt-10">
                                    {match.status === 'SCHEDULED' || match.status === 'PROPOSED' ? (
                                        <button
                                            onClick={() => {
                                                if (match.status === 'SCHEDULED') {
                                                    const params = new URLSearchParams(window.location.search);
                                                    params.set('tab', 'bookings');
                                                    window.history.replaceState({}, '', `${window.location.pathname}?${params.toString()}`);
                                                    window.dispatchEvent(new Event('popstate'));
                                                    window.location.reload();
                                                } else {
                                                    setSelectedUserForAvailability(otherUser);
                                                }
                                            }}
                                            className="h-16 rounded-[1.5rem] bg-slate-900 text-white font-black text-[10px] uppercase tracking-[0.2em] flex items-center justify-center gap-3 shadow-xl hover:bg-slate-800 transition-all active:scale-95 group/btn"
                                        >
                                            <span className="text-xl group-hover/btn:scale-125 transition">🎫</span>
                                            <span>{match.status === 'SCHEDULED' ? 'View Ticket' : 'Check Schedule'}</span>
                                        </button>
                                    ) : (
                                        <button
                                            onClick={() => setSelectedUserForAvailability(otherUser)}
                                            className="h-16 rounded-[1.5rem] bg-gradient-to-r from-pink-500 to-purple-600 text-white font-black text-[10px] uppercase tracking-[0.2em] flex items-center justify-center gap-3 shadow-xl hover:shadow-pink-300 transition-all active:scale-95 group/btn"
                                        >
                                            <span className="text-xl group-hover/btn:scale-125 transition">🗓️</span>
                                            <span>Schedule Now</span>
                                        </button>
                                    )}
                                </div>
                            </div>
                        );
                    })}
                </div>
            )}

            {/* Availability Modal */}
            {selectedUserForAvailability && (
                <AvailabilityModal
                    isOpen={!!selectedUserForAvailability}
                    onClose={() => setSelectedUserForAvailability(null)}
                    currentUser={currentUser}
                    matchedUser={selectedUserForAvailability}
                />
            )}
        </div>
    );
};

export default MatchesList;
