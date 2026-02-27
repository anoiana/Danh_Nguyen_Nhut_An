import React, { useEffect, useState, useCallback } from 'react';
import { getWaitingMatches } from '../../features/matching/api/matchApi';
import AvailabilityModal from '../../features/matching/components/AvailabilityModal';
import { useWebSocket } from '../../hooks/useWebSocket';
import { getDefaultAvatar } from '../../lib/constants';

const GlobalMatchPopup = ({ currentUser }) => {
    const [isMatchPopupOpen, setIsMatchPopupOpen] = useState(false);
    const [matchedUser, setMatchedUser] = useState(null);
    const [isAvailabilityOpen, setIsAvailabilityOpen] = useState(false);

    const checkWaitingMatches = async () => {
        if (!currentUser?.id) return;
        try {
            const response = await getWaitingMatches(currentUser.id);
            const waitingMatches = response.data;
            if (waitingMatches && waitingMatches.length > 0) {
                const match = waitingMatches[0];
                const otherUser = {
                    id: match.user1Id === currentUser.id ? match.user2Id : match.user1Id,
                    name: match.user1Id === currentUser.id ? match.user2Name : match.user1Name,
                    avatarUrl: match.user1Id === currentUser.id ? match.user2Avatar : match.user1Avatar,
                    photos: match.user1Id === currentUser.id ? match.user2Photos : match.user1Photos,
                };
                setMatchedUser(otherUser);
                setIsMatchPopupOpen(true);
            }
        } catch (error) {
            // Silently ignore - matches will be caught on next poll
        }
    };

    useEffect(() => {
        checkWaitingMatches();
    }, [currentUser?.id]);

    // --- WebSocket: Listen for match events ---
    const handleMatchEvent = useCallback((data) => {
        if (data.type === 'MATCH') {
            checkWaitingMatches();
        }
    }, [currentUser?.id]);

    useWebSocket(
        currentUser ? `/topic/matches/${currentUser.id}` : null,
        handleMatchEvent,
        !!currentUser
    );

    const handleOpenAvailability = () => {
        setIsMatchPopupOpen(false);
        setIsAvailabilityOpen(true);
    };

    const handleDismissMatch = () => {
        setIsMatchPopupOpen(false);
        setMatchedUser(null);
    };

    if (!currentUser) return null;

    return (
        <>
            {/* Match Popup */}
            {isMatchPopupOpen && matchedUser && (
                <div className="fixed inset-0 z-[9999] flex items-center justify-center bg-black/60 backdrop-blur-md animate-fade-in">
                    <div className="bg-white rounded-[3rem] p-10 max-w-md w-full mx-4 shadow-2xl animate-bounce-in text-center space-y-8 relative overflow-hidden">
                        {/* Decorative background */}
                        <div className="absolute -top-10 -right-10 w-40 h-40 bg-pink-200/30 rounded-full blur-3xl" />
                        <div className="absolute -bottom-10 -left-10 w-40 h-40 bg-purple-200/30 rounded-full blur-3xl" />

                        <div className="relative space-y-6">
                            <div className="text-6xl animate-bounce">💖</div>
                            <h2 className="text-4xl font-black text-slate-800 tracking-tighter italic">
                                It's a Match!
                            </h2>
                            <p className="text-slate-500 font-medium">
                                You and <span className="text-pink-600 font-black">{matchedUser.name}</span> liked each other!
                            </p>

                            <div className="flex justify-center -space-x-6">
                                <img
                                    src={currentUser.avatarUrl || (currentUser.photos ? currentUser.photos.split(',')[0] : null) || getDefaultAvatar(currentUser.id)}
                                    alt="You"
                                    className="w-24 h-24 rounded-full border-4 border-white shadow-xl object-cover"
                                />
                                <img
                                    src={matchedUser.avatarUrl || (matchedUser.photos ? matchedUser.photos.split(',')[0] : null) || getDefaultAvatar(matchedUser.id)}
                                    alt={matchedUser.name}
                                    className="w-24 h-24 rounded-full border-4 border-white shadow-xl object-cover"
                                />
                            </div>

                            <div className="space-y-4 pt-4">
                                <button
                                    onClick={handleOpenAvailability}
                                    className="w-full py-5 bg-gradient-to-r from-pink-500 to-purple-600 text-white font-black text-sm uppercase tracking-[0.2em] rounded-2xl shadow-xl shadow-pink-200/50 hover:scale-[1.02] active:scale-95 transition-all"
                                >
                                    Schedule a Date 📅
                                </button>
                                <button
                                    onClick={handleDismissMatch}
                                    className="w-full py-3 text-slate-400 font-black text-[10px] uppercase tracking-widest hover:text-slate-600 transition-colors"
                                >
                                    Do this later
                                </button>
                            </div>
                        </div>
                    </div>
                </div>
            )}

            {/* Availability Modal */}
            <AvailabilityModal
                isOpen={isAvailabilityOpen}
                onClose={() => setIsAvailabilityOpen(false)}
                currentUser={currentUser}
                matchedUser={matchedUser}
            />
        </>
    );
};

export default GlobalMatchPopup;
