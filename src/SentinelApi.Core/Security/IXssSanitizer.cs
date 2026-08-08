namespace SentinelApi.Core.Security;

public interface IXssSanitizer
{
    string SanitizeHtml(string input);
    string HtmlEncode(string input);
}
