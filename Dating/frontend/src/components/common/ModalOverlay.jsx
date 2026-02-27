import { createPortal } from 'react-dom';

/**
 * Reusable modal wrapper with consistent overlay, animation, and close behavior.
 * Uses React Portal to ensure it always renders at the top level of the DOM.
 */
const ModalOverlay = ({ isOpen, onClose, children, maxWidth = 'max-w-xl', closeOnOverlay = true }) => {
    if (!isOpen) return null;

    const handleOverlayClick = (e) => {
        if (closeOnOverlay && e.target === e.currentTarget) {
            onClose();
        }
    };

    const modalContent = (
        <div
            className="fixed inset-0 z-[200000] flex items-center justify-center bg-black/60 backdrop-blur-md p-4 animate-fade-in"
            onClick={handleOverlayClick}
        >
            <div className={`bg-white rounded-[3rem] ${maxWidth} w-full shadow-[0_30px_100px_-20px_rgba(0,0,0,0.4)] border border-white relative max-h-[95vh] overflow-y-auto transform animate-bounce-in scrollbar-premium`}>
                {children}
            </div>
        </div>
    );

    return createPortal(modalContent, document.body);
};

export default ModalOverlay;
