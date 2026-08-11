using System.Threading.Tasks;

namespace SentinelApi.Core.Services;

public interface IEmailService
{
    /// <summary>
    /// Sends an OTP verification email to the specified address.
    /// </summary>
    /// <param name="toEmail">Recipient email address</param>
    /// <param name="toName">Recipient display name</param>
    /// <param name="otpCode">The 6-digit OTP code</param>
    /// <returns>True if email was sent successfully</returns>
    Task<bool> SendOtpEmailAsync(string toEmail, string toName, string otpCode);

    /// <summary>
    /// Sends an email containing the generated unique Client ID and integration instructions.
    /// </summary>
    Task<bool> SendClientCredentialsEmailAsync(string toEmail, string toName, string appName, string clientId);
}
