import React, { useState } from 'react';
import { createPortal } from 'react-dom';
import { submitFeedback } from '../api/matchApi';
import { useNotification } from '../../../context/NotificationContext';

const FeedbackModal = ({ booking, currentUser, onClose, onSuccess }) => {
    const [attended, setAttended] = useState(true);
    const [wantsContact, setWantsContact] = useState(true);
    const [submitting, setSubmitting] = useState(false);
    const { showNotification } = useNotification();

    const isRequester = booking.requesterId === currentUser.id;
    const otherUser = {
        id: isRequester ? booking.recipientId : booking.requesterId,
        name: isRequester ? booking.recipientName : booking.requesterName,
    };

    const handleSubmit = async () => {
        setSubmitting(true);
        try {
            await submitFeedback(booking.id, currentUser.id, attended, wantsContact);
            showNotification("Thank you for your feedback! ✨", "success");
            onSuccess();
            onClose();
        } catch (error) {
            showNotification("Error submitting feedback.", "error");
        } finally {
            setSubmitting(false);
        }
    };

    const modalContent = (
        <div className="fixed inset-0 z-[9999] flex items-center justify-center bg-slate-900/60 backdrop-blur-xl p-4 animate-fade-in overflow-y-auto">
            <div className="my-auto bg-white rounded-[3rem] p-10 max-w-md w-full shadow-2xl space-y-8 animate-bounce-in border border-pink-50 relative">
                <div className="text-center space-y-4">
                    <div className="w-20 h-20 bg-pink-100 rounded-3xl flex items-center justify-center mx-auto shadow-inner">
                        <span className="text-4xl">💌</span>
                    </div>
                    <h2 className="text-3xl font-black text-slate-800 italic tracking-tight">How was the date?</h2>
                    <p className="text-slate-500 font-medium">Be honest! Your feedback helps us create better matches.</p>
                </div>

                <div className="space-y-6">
                    {/* Attendance */}
                    <div className="space-y-3">
                        <label className="text-[10px] font-black text-slate-400 uppercase tracking-widest block">Did you meet {otherUser.name}?</label>
                        <div className="grid grid-cols-2 gap-4">
                            <button
                                onClick={() => setAttended(true)}
                                className={`py-4 rounded-2xl font-black transition-all ${attended ? 'bg-pink-500 text-white shadow-lg shadow-pink-200' : 'bg-slate-50 text-slate-400 hover:bg-slate-100'}`}
                            >
                                YES
                            </button>
                            <button
                                onClick={() => setAttended(false)}
                                className={`py-4 rounded-2xl font-black transition-all ${!attended ? 'bg-slate-800 text-white shadow-lg shadow-slate-200' : 'bg-slate-50 text-slate-400 hover:bg-slate-100'}`}
                            >
                                NO
                            </button>
                        </div>
                    </div>

                    {/* Contact Exchange */}
                    {attended && (
                        <div className="space-y-3 animate-fade-in">
                            <label className="text-[10px] font-black text-slate-400 uppercase tracking-widest block">Exchange contact info?</label>
                            <p className="text-[10px] text-pink-400 italic">Only revealed if both of you say YES! 🤫</p>
                            <div className="grid grid-cols-2 gap-4">
                                <button
                                    onClick={() => setWantsContact(true)}
                                    className={`py-4 rounded-2xl font-black transition-all ${wantsContact ? 'bg-purple-600 text-white shadow-lg shadow-purple-200' : 'bg-slate-50 text-slate-400 hover:bg-slate-100'}`}
                                >
                                    OF COURSE
                                </button>
                                <button
                                    onClick={() => setWantsContact(false)}
                                    className={`py-4 rounded-2xl font-black transition-all ${!wantsContact ? 'bg-slate-800 text-white shadow-lg shadow-slate-200' : 'bg-slate-50 text-slate-400 hover:bg-slate-100'}`}
                                >
                                    NOT NOW
                                </button>
                            </div>
                        </div>
                    )}
                </div>

                <div className="flex gap-4 pt-4">
                    <button
                        onClick={onClose}
                        className="flex-1 py-4 text-slate-400 font-black text-[10px] uppercase tracking-widest hover:text-slate-600 transition-colors"
                    >
                        Skip
                    </button>
                    <button
                        onClick={handleSubmit}
                        disabled={submitting}
                        className="flex-[2] bg-gradient-to-r from-pink-500 to-purple-600 text-white py-4 rounded-2xl font-black text-[10px] uppercase tracking-[0.2em] shadow-xl hover:shadow-pink-200 transition-all active:scale-95 disabled:opacity-50"
                    >
                        {submitting ? 'Submitting...' : 'Send Feedback ✨'}
                    </button>
                </div>
            </div>
        </div>
    );

    return createPortal(modalContent, document.body);
};

export default FeedbackModal;
