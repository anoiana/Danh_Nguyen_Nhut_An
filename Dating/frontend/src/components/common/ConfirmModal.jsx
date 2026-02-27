import React from 'react';
import ModalOverlay from './ModalOverlay';

/**
 * A beautiful, premium confirmation modal.
 * 
 * @param {boolean} isOpen 
 * @param {function} onClose 
 * @param {function} onConfirm 
 * @param {string} title 
 * @param {string} message 
 * @param {string} confirmText 
 * @param {string} cancelText 
 * @param {string} type - 'danger' | 'info' | 'success'
 */
const ConfirmModal = ({
    isOpen,
    onClose,
    onConfirm,
    title = "Are you sure?",
    message = "This action cannot be undone.",
    confirmText = "Confirm",
    cancelText = "Cancel",
    type = "danger"
}) => {

    const colors = {
        danger: {
            bg: "bg-rose-50",
            icon: "text-rose-500",
            button: "bg-gradient-to-r from-rose-500 to-pink-600 shadow-rose-200",
            border: "border-rose-100"
        },
        info: {
            bg: "bg-blue-50",
            icon: "text-blue-500",
            button: "bg-gradient-to-r from-blue-500 to-indigo-600 shadow-blue-200",
            border: "border-blue-100"
        }
    }[type] || colors.danger;

    return (
        <ModalOverlay isOpen={isOpen} onClose={onClose} maxWidth="max-w-md">
            <div className="p-8 md:p-10 flex flex-col items-center text-center gap-6">

                {/* Visual Icon */}
                <div className={`w-20 h-20 ${colors.bg} ${colors.icon} rounded-[2rem] flex items-center justify-center text-4xl shadow-inner border-2 border-white`}>
                    {type === 'danger' ? '⚠️' : '❓'}
                </div>

                <div className="space-y-2">
                    <h3 className="text-2xl font-black text-slate-800 tracking-tight italic">
                        {title}
                    </h3>
                    <p className="text-slate-500 font-medium text-sm leading-relaxed">
                        {message}
                    </p>
                </div>

                <div className="w-full flex flex-col gap-3 mt-4">
                    <button
                        onClick={() => {
                            onConfirm();
                            onClose();
                        }}
                        className={`w-full py-5 ${colors.button} text-white font-black text-xs uppercase tracking-[0.2em] rounded-2xl shadow-xl transition-all hover:-translate-y-1 active:scale-95`}
                    >
                        {confirmText}
                    </button>

                    <button
                        onClick={onClose}
                        className="w-full py-4 bg-slate-100 hover:bg-slate-200 text-slate-400 font-black text-[10px] uppercase tracking-[0.2em] rounded-2xl transition-all"
                    >
                        {cancelText}
                    </button>
                </div>
            </div>
        </ModalOverlay>
    );
};

export default ConfirmModal;
