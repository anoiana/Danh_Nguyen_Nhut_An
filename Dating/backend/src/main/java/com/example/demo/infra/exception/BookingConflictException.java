package com.example.demo.infra.exception;

/**
 * Thrown when a booking request overlaps with an existing schedule.
 */
public class BookingConflictException extends BusinessLogicException {
    public BookingConflictException(String message) {
        super(message);
    }
}
