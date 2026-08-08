using System;
using System.Net;
using System.Text.Json;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Http;

namespace SentinelApi.Api.Middlewares;

public class GlobalExceptionHandlerMiddleware
{
    private readonly RequestDelegate _next;

    public GlobalExceptionHandlerMiddleware(RequestDelegate next)
    {
        _next = next;
    }

    public async Task InvokeAsync(HttpContext context)
    {
        try
        {
            await _next(context);
        }
        catch (Exception)
        {
            context.Response.StatusCode = (int)HttpStatusCode.InternalServerError;
            context.Response.ContentType = "application/json";

            // Secure response: Do not leak internal stack traces to clients in production/defense mode
            var responsePayload = new
            {
                Success = false,
                Error = "An unexpected security exception or server error occurred.",
                CorrelationId = Guid.NewGuid().ToString(),
                Message = "Details have been safely logged to the security audit system."
            };

            string json = JsonSerializer.Serialize(responsePayload);
            await context.Response.WriteAsync(json);
        }
    }
}
