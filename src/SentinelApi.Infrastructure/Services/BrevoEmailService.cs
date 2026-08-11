using System;
using System.Net.Http;
using System.Text;
using System.Text.Json;
using System.Threading.Tasks;
using SentinelApi.Core.Services;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;

namespace SentinelApi.Infrastructure.Services;

public class BrevoEmailService : IEmailService
{
    private readonly HttpClient _httpClient;
    private readonly string _apiKey;
    private readonly string _senderEmail;
    private readonly string _senderName;
    private readonly ILogger<BrevoEmailService> _logger;

    public BrevoEmailService(IConfiguration configuration, ILogger<BrevoEmailService> logger)
    {
        _httpClient = new HttpClient();
        _apiKey = configuration["Brevo:ApiKey"] ?? throw new InvalidOperationException("Brevo:ApiKey is not configured in appsettings.json");
        _senderEmail = configuration["Brevo:SenderEmail"] ?? "sentinelapi.security@gmail.com";
        _senderName = configuration["Brevo:SenderName"] ?? "SentinelAPI Security Lab";
        _logger = logger;
    }

    public async Task<bool> SendOtpEmailAsync(string toEmail, string toName, string otpCode)
    {
        try
        {
            var emailPayload = new
            {
                sender = new { name = _senderName, email = _senderEmail },
                to = new[] { new { email = toEmail, name = toName } },
                subject = "🔐 SentinelAPI — Your Email Verification Code",
                htmlContent = BuildOtpEmailHtml(otpCode, toName)
            };

            var json = JsonSerializer.Serialize(emailPayload);
            var content = new StringContent(json, Encoding.UTF8, "application/json");

            var request = new HttpRequestMessage(HttpMethod.Post, "https://api.brevo.com/v3/smtp/email");
            request.Headers.Add("api-key", _apiKey);
            request.Content = content;

            var response = await _httpClient.SendAsync(request);

            if (response.IsSuccessStatusCode)
            {
                _logger.LogInformation("OTP email sent successfully to {Email}", toEmail);
                return true;
            }

            var errorBody = await response.Content.ReadAsStringAsync();
            _logger.LogError("Brevo API error ({StatusCode}): {Error}", response.StatusCode, errorBody);
            return false;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to send OTP email to {Email}", toEmail);
            return false;
        }
    }

    public async Task<bool> SendClientCredentialsEmailAsync(string toEmail, string toName, string appName, string clientId)
    {
        try
        {
            var emailPayload = new
            {
                sender = new { name = _senderName, email = _senderEmail },
                to = new[] { new { email = toEmail, name = toName } },
                subject = $"🛡️ SentinelAPI — Your App Client Credentials for {appName}",
                htmlContent = BuildClientCredentialsHtml(toName, appName, clientId)
            };

            var json = JsonSerializer.Serialize(emailPayload);
            var content = new StringContent(json, Encoding.UTF8, "application/json");

            var request = new HttpRequestMessage(HttpMethod.Post, "https://api.brevo.com/v3/smtp/email");
            request.Headers.Add("api-key", _apiKey);
            request.Content = content;

            var response = await _httpClient.SendAsync(request);

            if (response.IsSuccessStatusCode)
            {
                _logger.LogInformation("Client credentials email sent successfully to {Email} for ClientId {ClientId}", toEmail, clientId);
                return true;
            }

            var errorBody = await response.Content.ReadAsStringAsync();
            _logger.LogError("Brevo API error on credentials email ({StatusCode}): {Error}", response.StatusCode, errorBody);
            return false;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to send credentials email to {Email}", toEmail);
            return false;
        }
    }

    private static string BuildOtpEmailHtml(string otpCode, string userName)
    {
        return $@"
<!DOCTYPE html>
<html>
<head>
    <meta charset='utf-8'>
    <meta name='viewport' content='width=device-width, initial-scale=1.0'>
</head>
<body style='margin:0; padding:0; background-color:#0a0e1a; font-family:Segoe UI, Arial, sans-serif;'>
    <div style='max-width:500px; margin:40px auto; background:linear-gradient(135deg, #0d1117 0%, #161b22 100%); border-radius:16px; border:1px solid #00e5ff33; overflow:hidden;'>
        
        <!-- Header -->
        <div style='background:linear-gradient(90deg, #00e5ff22, #7c4dff22); padding:32px 32px 24px; text-align:center; border-bottom:1px solid #00e5ff22;'>
            <div style='font-size:28px; font-weight:800; color:#00e5ff; letter-spacing:2px;'>🛡️ SENTINEL API</div>
            <div style='font-size:12px; color:#8b949e; margin-top:6px; letter-spacing:1px;'>SECURITY VERIFICATION SYSTEM</div>
        </div>

        <!-- Body -->
        <div style='padding:32px;'>
            <p style='color:#c9d1d9; font-size:15px; margin:0 0 8px;'>Hello <strong style='color:#00e5ff;'>{userName}</strong>,</p>
            <p style='color:#8b949e; font-size:14px; margin:0 0 28px; line-height:1.6;'>
                Your email verification code for SentinelAPI Security Lab is ready. Enter this code to complete your registration:
            </p>

            <!-- OTP Code Box -->
            <div style='background:#0a0e1a; border:2px solid #00e5ff44; border-radius:12px; padding:24px; text-align:center; margin-bottom:28px;'>
                <div style='font-size:36px; font-weight:900; color:#00e5ff; letter-spacing:12px; font-family:Consolas, monospace;'>{otpCode}</div>
                <div style='font-size:11px; color:#8b949e; margin-top:10px; letter-spacing:1px;'>VERIFICATION CODE • EXPIRES IN 10 MINUTES</div>
            </div>

            <!-- Security Notice -->
            <div style='background:#f8514911; border:1px solid #f8514933; border-radius:8px; padding:14px 16px; margin-bottom:24px;'>
                <p style='color:#f85149; font-size:12px; margin:0; font-weight:600;'>⚠️ SECURITY NOTICE</p>
                <p style='color:#8b949e; font-size:12px; margin:6px 0 0; line-height:1.5;'>
                    Never share this code with anyone. SentinelAPI team will never ask for your verification code. If you didn't request this, ignore this email.
                </p>
            </div>

            <p style='color:#484f58; font-size:12px; margin:0; text-align:center;'>
                This is an automated message from SentinelAPI Security Lab.
            </p>
        </div>

        <!-- Footer -->
        <div style='background:#0a0e1a55; padding:16px 32px; border-top:1px solid #21262d; text-align:center;'>
            <span style='color:#484f58; font-size:11px;'>🔒 Secured with AES-256-GCM • Argon2id • JWT HS256</span>
        </div>
    </div>
</body>
</html>";
    }

    private static string BuildClientCredentialsHtml(string userName, string appName, string clientId)
    {
        return $@"
<!DOCTYPE html>
<html>
<head>
    <meta charset='utf-8'>
    <meta name='viewport' content='width=device-width, initial-scale=1.0'>
</head>
<body style='margin:0; padding:0; background-color:#0a0e1a; font-family:Segoe UI, Arial, sans-serif;'>
    <div style='max-width:540px; margin:40px auto; background:linear-gradient(135deg, #0d1117 0%, #161b22 100%); border-radius:16px; border:1px solid #7c4dff33; overflow:hidden;'>
        
        <!-- Header -->
        <div style='background:linear-gradient(90deg, #7c4dff22, #00e5ff22); padding:32px 32px 24px; text-align:center; border-bottom:1px solid #7c4dff22;'>
            <div style='font-size:28px; font-weight:800; color:#a855f7; letter-spacing:2px;'>🛡️ SENTINEL API</div>
            <div style='font-size:12px; color:#8b949e; margin-top:6px; letter-spacing:1px;'>DEVELOPER IAM CREDENTIALS</div>
        </div>

        <!-- Body -->
        <div style='padding:32px;'>
            <p style='color:#c9d1d9; font-size:15px; margin:0 0 8px;'>Hello <strong style='color:#00e5ff;'>{userName}</strong>,</p>
            <p style='color:#8b949e; font-size:14px; margin:0 0 20px; line-height:1.6;'>
                Your application <strong style='color:#f8fafc;'>{appName}</strong> has been successfully registered and scoped in the SentinelAPI Security Gateway.
            </p>

            <!-- Client ID Box -->
            <div style='background:#0a0e1a; border:2px solid #a855f766; border-radius:12px; padding:20px; text-align:center; margin-bottom:24px;'>
                <div style='font-size:11px; color:#a855f7; font-weight:700; letter-spacing:1.5px; margin-bottom:8px;'>YOUR UNIQUE APP CLIENT ID</div>
                <div style='font-size:20px; font-weight:800; color:#00e5ff; letter-spacing:1px; font-family:Consolas, monospace; background:#161b22; padding:10px; border-radius:8px; border:1px solid #30363d;'>{clientId}</div>
                <div style='font-size:11px; color:#8b949e; margin-top:10px;'>Include this in every API request from your application</div>
            </div>

            <!-- Integration Instructions -->
            <div style='background:#111c33; border:1px solid #1e293b; border-radius:8px; padding:16px; margin-bottom:24px;'>
                <p style='color:#a855f7; font-size:13px; margin:0 0 10px; font-weight:700;'>⚡ How to integrate in your app:</p>
                <p style='color:#94a3b8; font-size:12px; margin:0 0 8px; line-height:1.5;'>
                    Attach this header to all HTTP requests from <strong style='color:#f8fafc;'>{appName}</strong>:
                </p>
                <pre style='background:#060913; color:#00f0ff; padding:10px 12px; border-radius:6px; font-family:Consolas, monospace; font-size:12px; margin:0; overflow-x:auto;'>X-Client-Id: {clientId}</pre>
            </div>

            <p style='color:#484f58; font-size:12px; margin:0; text-align:center;'>
                This is an automated developer onboarding notification from SentinelAPI.
            </p>
        </div>

        <!-- Footer -->
        <div style='background:#0a0e1a55; padding:16px 32px; border-top:1px solid #21262d; text-align:center;'>
            <span style='color:#484f58; font-size:11px;'>🔒 SentinelAPI IAM Gateway • Zero Trust Multi-Tenant Architecture</span>
        </div>
    </div>
</body>
</html>";
    }
}
