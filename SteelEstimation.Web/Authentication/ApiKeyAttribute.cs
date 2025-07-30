using Microsoft.AspNetCore.Authorization;

namespace SteelEstimation.Web.Authentication
{
    /// <summary>
    /// Attribute to require API key authentication for controllers or actions
    /// </summary>
    public class ApiKeyAttribute : AuthorizeAttribute
    {
        public ApiKeyAttribute()
        {
            AuthenticationSchemes = ApiKeyAuthenticationExtensions.SchemeName;
        }
    }
}