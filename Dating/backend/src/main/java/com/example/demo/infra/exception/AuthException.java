package com.example.demo.infra.exception;

public class AuthException extends BusinessLogicException {
    public AuthException(String message) {
        super(message);
    }
}
