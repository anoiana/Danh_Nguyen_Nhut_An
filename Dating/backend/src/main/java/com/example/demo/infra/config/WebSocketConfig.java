package com.example.demo.infra.config;

import org.springframework.context.annotation.Configuration;
import org.springframework.messaging.simp.config.MessageBrokerRegistry;
import org.springframework.web.socket.config.annotation.EnableWebSocketMessageBroker;
import org.springframework.web.socket.config.annotation.StompEndpointRegistry;
import org.springframework.web.socket.config.annotation.WebSocketMessageBrokerConfigurer;

/**
 * Configures STOMP messaging for real-time bidirectional communication.
 * Enables features like live chat notifications and scheduling updates.
 */
@Configuration
@EnableWebSocketMessageBroker
public class WebSocketConfig implements WebSocketMessageBrokerConfigurer {

    @Override
    public void configureMessageBroker(@org.springframework.lang.NonNull MessageBrokerRegistry config) {
        // Defines the routing for messages:
        // /topic: General broadcasts (e.g., system alerts).
        // /queue: Direct messages (though we often use user-specific topics).
        config.enableSimpleBroker("/topic", "/queue");

        // Prefix for messages originating from the client to be handled by
        // @MessageMapping.
        config.setApplicationDestinationPrefixes("/app");

        config.setUserDestinationPrefix("/user");
    }

    @Override
    public void registerStompEndpoints(@org.springframework.lang.NonNull StompEndpointRegistry registry) {
        // Exposed endpoint for the initial WebSocket handshake.
        registry.addEndpoint("/ws")
                .setAllowedOriginPatterns("*")
                .withSockJS(); // SockJS fallback for browsers that don't support WebSockets.
    }
}
