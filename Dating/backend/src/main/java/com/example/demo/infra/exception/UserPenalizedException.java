package com.example.demo.infra.exception;

/**
 * Thrown when a user attempts to access the feed while under a penalty.
 */
public class UserPenalizedException extends BusinessLogicException {
    public UserPenalizedException(String message) {
        super(message);
    }
}
