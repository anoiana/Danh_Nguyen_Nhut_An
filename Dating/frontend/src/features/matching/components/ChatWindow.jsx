import React, { useState, useEffect, useRef, useCallback } from 'react';
import { client } from '../../../lib/axios';
import { createPortal } from 'react-dom';
import { useWebSocket } from '../../../hooks/useWebSocket';
import { CHAT_UNLOCK_HOURS_BEFORE, getDefaultAvatar } from '../../../lib/constants';

const ChatWindow = ({ currentUser, otherUser, onClose }) => {
    const [messages, setMessages] = useState([]);
    const [newMessage, setNewMessage] = useState('');
    const [loading, setLoading] = useState(true);
    const [booking, setBooking] = useState(null);
    const [isLocked, setIsLocked] = useState(true);
    const [countdown, setCountdown] = useState('');
    const messagesEndRef = useRef(null);

    const scrollToBottom = () => {
        messagesEndRef.current?.scrollIntoView({ behavior: "smooth" });
    };

    const fetchHistory = async () => {
        try {
            const response = await client.get('/messages/history', {
                params: { u1Id: currentUser.id, u2Id: otherUser.id }
            });
            setMessages(response.data);
        } catch (error) {
            console.error("Error fetching chat history:", error);
        }
    };

    // --- Lock/Unlock Logic ---
    const formatCountdown = (ms) => {
        const hours = Math.floor(ms / (1000 * 60 * 60));
        const minutes = Math.floor((ms % (1000 * 60 * 60)) / (1000 * 60));
        const seconds = Math.floor((ms % (1000 * 60)) / 1000);
        return `${hours}h ${minutes}m ${seconds}s`;
    };

    const updateLockState = useCallback((bookingData) => {
        if (!bookingData) return;
        const dateStart = new Date(bookingData.startTime).getTime();
        const unlockTime = dateStart - (CHAT_UNLOCK_HOURS_BEFORE * 60 * 60 * 1000);
        const now = Date.now();

        if (now >= unlockTime) {
            setIsLocked(false);
        } else {
            setIsLocked(true);
            setCountdown(formatCountdown(unlockTime - now));
        }
    }, []);

    const checkLockStatus = async () => {
        try {
            const { getBooking } = await import('../api/matchApi');
            const response = await getBooking(currentUser.id, otherUser.id);
            if (response.data) {
                setBooking(response.data);
                updateLockState(response.data);
            }
        } catch (error) {
            console.error("No booking found:", error);
            setIsLocked(true);
        } finally {
            setLoading(false);
        }
    };

    useEffect(() => {
        fetchHistory();
        checkLockStatus();

        const timer = setInterval(() => {
            if (booking) updateLockState(booking);
        }, 1000);

        return () => clearInterval(timer);
    }, [currentUser.id, otherUser.id]);

    useEffect(() => {
        scrollToBottom();
    }, [messages]);

    // --- WebSocket: Real-time messages ---
    const handleIncomingMessage = useCallback((receivedMsg) => {
        if (receivedMsg.sender.id === otherUser.id || receivedMsg.receiver.id === otherUser.id) {
            setMessages(prev => {
                if (prev.find(m => m.id === receivedMsg.id)) return prev;
                return [...prev, receivedMsg];
            });
        }
    }, [otherUser.id]);

    useWebSocket(
        `/topic/messages/${currentUser.id}`,
        handleIncomingMessage,
        true
    );

    // --- Send Message ---
    const handleSend = async (e) => {
        e.preventDefault();
        if (!newMessage.trim() || isLocked) return;

        try {
            const response = await client.post('/messages', {
                senderId: currentUser.id,
                receiverId: otherUser.id,
                content: newMessage
            });
            setMessages([...messages, response.data]);
            setNewMessage('');
        } catch (error) {
            console.error("Error sending message:", error);
        }
    };

    const modalContent = (
        <div className="fixed inset-0 z-[9999] flex items-center justify-center bg-black/60 backdrop-blur-md p-4 animate-fade-in">
            <div className="bg-white rounded-[2.5rem] w-full max-w-lg h-[650px] flex flex-col overflow-hidden shadow-2xl border border-gray-100 transform animate-bounce-in">
                {/* Header */}
                <div className="bg-gradient-to-r from-pink-500 to-purple-600 p-6 flex justify-between items-center text-white shrink-0 min-h-[90px]">
                    <div className="flex items-center space-x-4">
                        <div className="relative shrink-0">
                            <img
                                src={otherUser.avatarUrl || getDefaultAvatar(otherUser.id)}
                                alt={otherUser.name}
                                className="w-14 h-14 rounded-2xl border-2 border-white/30 object-cover shadow-md"
                            />
                            <div className={`absolute -bottom-1 -right-1 w-4 h-4 ${isLocked ? 'bg-orange-500' : 'bg-green-500'} border-2 border-white rounded-full shadow-lg`} />
                        </div>
                        <div className="overflow-hidden">
                            <p className="font-black text-xl tracking-tight leading-none truncate">{otherUser.name}</p>
                            <div className="flex items-center gap-2 mt-2">
                                <span className={`w-2 h-2 rounded-full ${isLocked ? 'bg-orange-300' : 'bg-green-300 animate-pulse'}`} />
                                <p className="text-[10px] font-bold text-pink-100 uppercase tracking-widest opacity-80">
                                    {isLocked ? 'Waiting for date' : 'Connected'}
                                </p>
                            </div>
                        </div>
                    </div>
                    <button
                        onClick={onClose}
                        className="w-12 h-12 rounded-2xl bg-white/10 hover:bg-white/20 flex items-center justify-center transition-all hover:rotate-90 text-3xl font-light"
                    >
                        &times;
                    </button>
                </div>

                {/* Messages Area */}
                <div className="flex-1 overflow-y-auto p-8 space-y-6 bg-gray-50/50 relative">
                    {loading ? (
                        <div className="flex flex-col items-center justify-center h-full space-y-4">
                            <div className="w-10 h-10 border-4 border-pink-500 border-t-transparent rounded-full animate-spin" />
                            <p className="text-gray-400 font-black text-[10px] uppercase tracking-widest">Checking connection...</p>
                        </div>
                    ) : messages.length === 0 && !isLocked ? (
                        <div className="flex flex-col items-center justify-center h-full opacity-30 text-center">
                            <div className="text-7xl mb-6">💌</div>
                            <h3 className="font-black text-gray-800 text-xl tracking-tight">Say hello!</h3>
                            <p className="text-gray-400 font-medium text-sm mt-2">Don't be shy, start the magic ✨</p>
                        </div>
                    ) : (
                        messages.map((m, idx) => {
                            const isMe = m.sender.id === currentUser.id;
                            return (
                                <div key={m.id || idx} className={`flex ${isMe ? 'justify-end' : 'justify-start'} items-end space-x-3 animate-fade-in`}>
                                    <div className={`max-w-[75%] rounded-[1.5rem] px-5 py-3.5 shadow-sm ${isMe
                                        ? 'bg-gradient-to-br from-pink-500 to-rose-600 text-white rounded-br-none'
                                        : 'bg-white text-gray-800 border border-gray-100 rounded-bl-none font-medium'
                                        }`}>
                                        <p className="text-[15px] leading-relaxed whitespace-pre-wrap break-words">{m.content}</p>
                                        <p className={`text-[9px] mt-2 font-black opacity-60 uppercase tracking-widest ${isMe ? 'text-white' : 'text-gray-400'}`}>
                                            {new Date(m.sentAt).toLocaleTimeString('en-US', { hour: '2-digit', minute: '2-digit' })}
                                        </p>
                                    </div>
                                </div>
                            );
                        })
                    )}
                    <div ref={messagesEndRef} />
                </div>

                {/* Input Area or Lock Overlay */}
                <div className="p-6 bg-white border-t border-gray-100 shrink-0">
                    {isLocked ? (
                        <div className="flex flex-col items-center text-center space-y-4 py-2">
                            <div className="flex items-center gap-3 text-orange-500 bg-orange-50 px-6 py-3 rounded-2xl border border-orange-100">
                                <span className="text-2xl">⏳</span>
                                <span className="font-black text-xs uppercase tracking-widest">{countdown || 'Calculating...'}</span>
                            </div>
                            <p className="text-slate-400 font-bold text-[11px] leading-relaxed max-w-[80%] uppercase tracking-tighter">
                                Chat unlocks {CHAT_UNLOCK_HOURS_BEFORE} hours before the date so you can coordinate meeting up.
                            </p>
                        </div>
                    ) : (
                        <form onSubmit={handleSend} className="flex items-center space-x-3">
                            <div className="flex-1 relative">
                                <input
                                    type="text"
                                    placeholder="Type a message..."
                                    className="w-full bg-gray-50 border-2 border-transparent px-6 py-4 rounded-[1.5rem] focus:outline-none focus:border-pink-500 focus:bg-white text-gray-700 font-semibold transition-all text-sm"
                                    value={newMessage}
                                    onChange={(e) => setNewMessage(e.target.value)}
                                />
                            </div>
                            <button
                                type="submit"
                                disabled={!newMessage.trim()}
                                className="bg-gradient-to-r from-pink-500 to-purple-600 text-white w-14 h-14 rounded-2xl flex items-center justify-center transition-all shadow-xl shadow-pink-200/50 disabled:opacity-50 disabled:grayscale transform hover:scale-110 active:scale-95"
                            >
                                <span className="text-2xl transform rotate-12">🚀</span>
                            </button>
                        </form>
                    )}
                </div>
            </div>
        </div>
    );

    return createPortal(modalContent, document.body);
};

export default ChatWindow;
