// ============================================================
// Application Constants
// Centralized configuration to avoid magic numbers and strings
// ============================================================

// --- Network ---
export const WS_URL = import.meta.env.VITE_WS_URL || 'http://localhost:8080/ws';
export const API_TIMEOUT = 30000; // 30 seconds

// --- Scheduling ---
export const MIN_SLOT_DURATION_MINUTES = 90;
export const MAX_SCHEDULE_DAYS_AHEAD = 21;
export const MIN_AVAILABILITY_SLOTS = 3;
export const CHAT_UNLOCK_HOURS_BEFORE = 4;

// --- UI ---
export const MODAL_Z_INDEX = 9999;
export const TOAST_Z_INDEX = 99999;

// --- Helpers ---
export const getDefaultAvatar = (id) => `https://i.pravatar.cc/300?u=${id}`;

// --- Date Formatting ---
export const DATE_FORMAT_OPTIONS = {
    full: {
        weekday: 'long',
        year: 'numeric',
        month: 'long',
        day: 'numeric',
        hour: '2-digit',
        minute: '2-digit',
    },
    short: {
        weekday: 'short',
        day: 'numeric',
        month: 'numeric',
    },
    timeOnly: {
        hour: '2-digit',
        minute: '2-digit',
    },
    dateOnly: {
        weekday: 'long',
        day: 'numeric',
        month: 'long',
    },
};

export const formatDate = (dateStr, format = 'full') => {
    return new Date(dateStr).toLocaleString('en-US', DATE_FORMAT_OPTIONS[format]);
};

export const formatTime = (dateStr) => {
    return new Date(dateStr).toLocaleTimeString('en-US', DATE_FORMAT_OPTIONS.timeOnly);
};
