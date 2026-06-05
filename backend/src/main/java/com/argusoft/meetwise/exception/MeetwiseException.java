package com.argusoft.meetwise.exception;

public class MeetwiseException extends RuntimeException {

    private final int httpStatus;

    public MeetwiseException(String message) {
        super(message);
        this.httpStatus = 500;
    }

    public MeetwiseException(String message, int httpStatus) {
        super(message);
        this.httpStatus = httpStatus;
    }

    public MeetwiseException(String message, Throwable cause) {
        super(message, cause);
        this.httpStatus = 500;
    }

    public int getHttpStatus() {
        return httpStatus;
    }
}
