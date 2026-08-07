using System.Threading.Tasks;
using Microsoft.AspNetCore.Http;

namespace ApiSecurityLab.Api.Middlewares;

public class SecurityHeadersMiddleware
{
    private readonly RequestDelegate _next;

    public SecurityHeadersMiddleware(RequestDelegate next)
    {
        _next = next;
    }

    public async Task InvokeAsync(HttpContext context)
    {
        // Enforce Content-Security-Policy (CSP) supporting Flutter Web CanvasKit & WASM
        context.Response.Headers["Content-Security-Policy"] =
            "default-src 'self' 'unsafe-inline' 'unsafe-eval' 'wasm-unsafe-eval' https://cdn.jsdelivr.net https://www.gstatic.com https://fonts.gstatic.com https://fonts.googleapis.com; script-src 'self' 'unsafe-inline' 'unsafe-eval' 'wasm-unsafe-eval' https://cdn.jsdelivr.net https://www.gstatic.com https://*.gstatic.com; style-src 'self' 'unsafe-inline' https://fonts.googleapis.com; font-src 'self' data: https://fonts.gstatic.com; img-src 'self' data: blob:; connect-src 'self' https://www.gstatic.com https://*.gstatic.com https://fonts.googleapis.com; worker-src 'self' blob:;";

        // Prevent MIME type sniffing
        context.Response.Headers["X-Content-Type-Options"] = "nosniff";

        // Prevent Clickjacking (Iframe embedding)
        context.Response.Headers["X-Frame-Options"] = "DENY";

        // Enable XSS protection filter in legacy browsers
        context.Response.Headers["X-XSS-Protection"] = "1; mode=block";

        // Control referrer header leakages
        context.Response.Headers["Referrer-Policy"] = "strict-origin-when-cross-origin";

        // HTTP Strict Transport Security (HSTS)
        context.Response.Headers["Strict-Transport-Security"] = "max-age=31536000; includeSubDomains";

        // Permissions Policy
        context.Response.Headers["Permissions-Policy"] = "camera=(), microphone=(), geolocation=()";

        await _next(context);
    }
}
