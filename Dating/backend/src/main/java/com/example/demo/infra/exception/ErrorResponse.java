package com.example.demo.infra.exception;

import lombok.AllArgsConstructor;
import lombok.Data;
import java.time.LocalDateTime;

/**
 * Standardized error response body for all API failures.
 */
@Data
@AllArgsConstructor
public class ErrorResponse {
    private int status;
    private String message;
    private LocalDateTime timestamp;
    private String errorCode;
}
