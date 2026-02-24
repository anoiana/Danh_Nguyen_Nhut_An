package com.example.demo.infra.exception;

import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.ResponseStatus;

/**
 * Base class for all business-related exceptions.
 */
@ResponseStatus(HttpStatus.BAD_REQUEST)
public class BusinessLogicException extends RuntimeException {
    public BusinessLogicException(String message) {
        super(message);
    }
}
