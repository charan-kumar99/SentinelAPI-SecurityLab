using System.Net;
using Ganss.Xss;

namespace ApiSecurityLab.Core.Security;

public class XssSanitizerService : IXssSanitizer
{
    private readonly HtmlSanitizer _sanitizer;

    public XssSanitizerService()
    {
        _sanitizer = new HtmlSanitizer();
    }

    public string SanitizeHtml(string input)
    {
        if (string.IsNullOrWhiteSpace(input)) return string.Empty;
        return _sanitizer.Sanitize(input);
    }

    public string HtmlEncode(string input)
    {
        if (string.IsNullOrWhiteSpace(input)) return string.Empty;
        return WebUtility.HtmlEncode(input);
    }
}
