package com.argusoft.meetwise.exception;

public class MeetwiseException extends RuntimeException {
    public MeetwiseException(String message) {
        super(message);
    }
    public MeetwiseException(String message, Throwable cause) {
        super(message, cause);
    }
}
