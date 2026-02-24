import { useEffect, useRef } from 'react';
import SockJS from 'sockjs-client';
import Stomp from 'stompjs';
import { WS_URL } from '../lib/constants';

/**
 * Custom hook for WebSocket connections via SockJS + Stomp.
 * Eliminates duplicate WebSocket setup code across components.
 *
 * @param {string} topic - The STOMP topic to subscribe to (e.g., `/topic/messages/123`)
 * @param {function} onMessage - Callback when a message is received. Receives parsed JSON.
 * @param {boolean} enabled - Whether the connection should be active. Defaults to true.
 * @returns {{ clientRef: React.RefObject }} Reference to the STOMP client (if needed).
 *
 * @example
 * useWebSocket(`/topic/activities/${userId}`, (data) => {
 *     console.log('Received:', data);
 * }, !!userId);
 */
export const useWebSocket = (topic, onMessage, enabled = true) => {
    const stompClientRef = useRef(null);
    const onMessageRef = useRef(onMessage);

    // Keep callback ref updated without re-subscribing
    useEffect(() => {
        onMessageRef.current = onMessage;
    }, [onMessage]);

    useEffect(() => {
        if (!enabled || !topic) return;

        const socket = new SockJS(WS_URL);
        const stompClient = Stomp.over(socket);
        stompClient.debug = null; // Disable noisy STOMP debug logs

        stompClientRef.current = stompClient;

        stompClient.connect({}, () => {
            // Guard against stale connections (e.g., strict mode double-mount)
            if (stompClientRef.current !== stompClient) {
                stompClient.disconnect();
                return;
            }

            stompClient.subscribe(topic, (message) => {
                try {
                    const parsed = JSON.parse(message.body);
                    onMessageRef.current(parsed);
                } catch (error) {
                    console.error('[useWebSocket] Failed to parse message:', error);
                }
            });
        });

        return () => {
            stompClientRef.current = null;
            if (stompClient.connected) {
                stompClient.disconnect();
            }
        };
    }, [topic, enabled]);

    return { clientRef: stompClientRef };
};
