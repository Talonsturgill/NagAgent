from fastapi import Request, Response
from fastapi.middleware.base import BaseHTTPMiddleware
import time
import uuid


class SecurityHeadersMiddleware(BaseHTTPMiddleware):
    """Add security headers to all responses"""
    
    async def dispatch(self, request: Request, call_next):
        # Generate request ID for tracing
        request_id = str(uuid.uuid4())
        request.state.request_id = request_id
        
        response = await call_next(request)
        
        # Add security headers
        security_headers = {
            # Prevent clickjacking
            "X-Frame-Options": "DENY",
            
            # Prevent MIME type sniffing
            "X-Content-Type-Options": "nosniff",
            
            # Enable XSS protection
            "X-XSS-Protection": "1; mode=block",
            
            # Referrer policy
            "Referrer-Policy": "strict-origin-when-cross-origin",
            
            # Content Security Policy for API
            "Content-Security-Policy": "default-src 'none'; frame-ancestors 'none';",
            
            # Prevent caching of sensitive endpoints
            "Cache-Control": "no-cache, no-store, must-revalidate",
            "Pragma": "no-cache",
            "Expires": "0",
            
            # Add request ID for tracing
            "X-Request-ID": request_id,
            
            # Server identification
            "X-Powered-By": "NagAgent-API",
        }
        
        # Add HSTS header for HTTPS (only in production)
        if request.url.scheme == "https":
            security_headers["Strict-Transport-Security"] = "max-age=31536000; includeSubDomains"
        
        # Add all security headers to response
        for header, value in security_headers.items():
            response.headers[header] = value
        
        return response


class RequestLoggingMiddleware(BaseHTTPMiddleware):
    """Log all requests for monitoring and debugging"""
    
    async def dispatch(self, request: Request, call_next):
        start_time = time.time()
        
        # Log request
        print(f"🔍 {request.method} {request.url.path} - Start")
        
        response = await call_next(request)
        
        # Calculate processing time
        process_time = time.time() - start_time
        
        # Log response
        print(f"✅ {request.method} {request.url.path} - {response.status_code} - {process_time:.3f}s")
        
        # Add processing time header
        response.headers["X-Process-Time"] = str(process_time)
        
        return response


class UserContextMiddleware(BaseHTTPMiddleware):
    """Add user context to request state for rate limiting and logging"""
    
    async def dispatch(self, request: Request, call_next):
        # Extract user info from Authorization header if present
        auth_header = request.headers.get("authorization")
        if auth_header and auth_header.startswith("Bearer "):
            try:
                from app.services.auth_service import AuthService
                token = auth_header.split(" ")[1]
                token_data = AuthService.verify_token(token)
                
                if token_data and token_data.email:
                    # Store user email in request state
                    request.state.user_email = token_data.email
                    
                    # Get user ID for rate limiting (would need DB query)
                    # For now, we'll use email hash as user identifier
                    import hashlib
                    user_hash = hashlib.md5(token_data.email.encode()).hexdigest()[:8]
                    request.state.user_id = user_hash
            except Exception:
                # If token verification fails, continue without user context
                pass
        
        response = await call_next(request)
        return response