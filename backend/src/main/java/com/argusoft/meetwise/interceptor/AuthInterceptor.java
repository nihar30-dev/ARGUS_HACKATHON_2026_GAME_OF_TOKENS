package com.argusoft.meetwise.interceptor;

import com.argusoft.meetwise.entity.AppUser;
import com.argusoft.meetwise.service.AuthService;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;
import org.springframework.web.servlet.HandlerInterceptor;

@Component
@RequiredArgsConstructor
public class AuthInterceptor implements HandlerInterceptor {

    private final AuthService authService;

    @Override
    public boolean preHandle(HttpServletRequest request,
                             HttpServletResponse response,
                             Object handler) {
        String header = request.getHeader("Authorization");
        if (header != null) {
            AppUser user = authService.validateToken(header);
            if (user != null) {
                request.setAttribute("currentUser", user);
            }
        }
        // Never blocks — endpoints that require auth check the attribute themselves.
        return true;
    }
}
