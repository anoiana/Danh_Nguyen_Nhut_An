import React from 'react';

/**
 * Reusable modal wrapper with consistent overlay, animation, and close behavior.
 * Replaces repeated modal boilerplate across AvailabilityModal, ChatWindow, FeedbackModal.
 *
 * @param {boolean} isOpen - Whether the modal is visible
 * @param {function} onClose - Callback to close the modal
 * @param {React.ReactNode} children - Modal body content
 * @param {string} maxWidth - Tailwind max-width class. Default: 'max-w-xl'
 * @param {boolean} closeOnOverlay - Whether clicking the overlay closes the modal. Default: true
 */
const ModalOverlay = ({ isOpen, onClose, children, maxWidth = 'max-w-xl', closeOnOverlay = true }) => {
    if (!isOpen) return null;

    const handleOverlayClick = (e) => {
        if (closeOnOverlay && e.target === e.currentTarget) {
            onClose();
        }
    };

    return (
        <div
            className="fixed inset-0 z-[9999] flex items-center justify-center bg-black/60 backdrop-blur-md p-4 animate-fade-in"
            onClick={handleOverlayClick}
        >
            <div className={`bg-white rounded-[3rem] ${maxWidth} w-full shadow-[0_30px_100px_-20px_rgba(0,0,0,0.3)] border border-white relative max-h-[90vh] overflow-y-auto transform animate-bounce-in scrollbar-premium`}>
                {children}
            </div>
        </div>
    );
};

export default ModalOverlay;
