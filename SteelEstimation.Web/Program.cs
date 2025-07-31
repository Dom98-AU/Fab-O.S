using Microsoft.EntityFrameworkCore;
using SteelEstimation.Infrastructure.Data;
using SteelEstimation.Core.Interfaces;
using SteelEstimation.Infrastructure.Interfaces;
using SteelEstimation.Web.Services;
using Serilog;
using Azure.Identity;
using Azure.Security.KeyVault.Secrets;
using FluentValidation;
using FluentValidation.AspNetCore;
using Azure.Extensions.AspNetCore.Configuration.Secrets;
using Microsoft.AspNetCore.Components.Authorization;
using Microsoft.AspNetCore.Components.Server.Circuits;
using Microsoft.AspNetCore.Authentication.Cookies;
using SteelEstimation.Web.Authentication;
using SteelEstimation.Infrastructure.Services;
using System.Security.Claims;

var builder = WebApplication.CreateBuilder(args);

// Configure Kestrel for local development - CloudDev version uses different ports
// Skip this configuration when running in Docker (Docker sets ASPNETCORE_URLS)
var isRunningInDocker = Environment.GetEnvironmentVariable("DOTNET_RUNNING_IN_CONTAINER") == "true";
if (builder.Environment.IsDevelopment() && !isRunningInDocker)
{
    builder.WebHost.ConfigureKestrel(serverOptions =>
    {
        // Listen on both IPv4 and IPv6 - CloudDev ports
        serverOptions.Listen(System.Net.IPAddress.Any, 5002); // IPv4 HTTP
        serverOptions.Listen(System.Net.IPAddress.Any, 5003, listenOptions =>
        {
            listenOptions.UseHttps(); // IPv4 HTTPS
        });
        serverOptions.Listen(System.Net.IPAddress.IPv6Any, 5002); // IPv6 HTTP
        serverOptions.Listen(System.Net.IPAddress.IPv6Any, 5003, listenOptions =>
        {
            listenOptions.UseHttps(); // IPv6 HTTPS
        });
    });
}

// Configure Serilog
var loggerConfig = new LoggerConfiguration()
    .ReadFrom.Configuration(builder.Configuration)
    .Enrich.FromLogContext()
    .WriteTo.Console();

// Only write to file in development
if (builder.Environment.IsDevelopment())
{
    loggerConfig.WriteTo.File("logs/steelestimation-.log", rollingInterval: RollingInterval.Day);
}

Log.Logger = loggerConfig.CreateLogger();

builder.Host.UseSerilog();

// Add Azure Key Vault configuration if in production or staging
if (builder.Environment.IsProduction() || builder.Environment.IsStaging())
{
    var keyVaultUrl = builder.Configuration["KeyVault:Url"];
    if (!string.IsNullOrEmpty(keyVaultUrl))
    {
        var secretClient = new SecretClient(new Uri(keyVaultUrl), new DefaultAzureCredential());
        builder.Configuration.AddAzureKeyVault(secretClient, new AzureKeyVaultConfigurationOptions());
    }
}

// Add services to the container.
builder.Services.AddRazorPages();
builder.Services.AddServerSideBlazor()
    .AddHubOptions(options =>
    {
        // Increase buffer size for larger state
        options.MaximumReceiveMessageSize = 64 * 1024; // 64KB
        // Configure timeouts
        options.ClientTimeoutInterval = TimeSpan.FromSeconds(60);
        options.HandshakeTimeout = TimeSpan.FromSeconds(30);
        options.KeepAliveInterval = TimeSpan.FromSeconds(15);
    });
builder.Services.AddControllers();

// Configure Cookie Authentication for CloudDev
builder.Services.AddAuthentication(options =>
{
    options.DefaultScheme = "Cookies";
    options.DefaultChallengeScheme = "Cookies";
})
.AddCookie("Cookies", options =>
{
    var cookieConfig = builder.Configuration.GetSection("Authentication:Cookie");
    
    options.Cookie.Name = cookieConfig.GetValue<string>("Name") ?? ".SteelEstimation.Auth";
    options.LoginPath = "/Account/Login";
    options.LogoutPath = "/Account/Logout";
    options.AccessDeniedPath = "/Account/AccessDenied";
    options.ExpireTimeSpan = TimeSpan.FromHours(cookieConfig.GetValue<int>("ExpireHours", 8));
    options.SlidingExpiration = cookieConfig.GetValue<bool>("SlidingExpiration", true);
    options.Cookie.HttpOnly = cookieConfig.GetValue<bool>("HttpOnly", true);
    
    // Set secure policy based on environment
    if (builder.Environment.IsProduction())
    {
        options.Cookie.SecurePolicy = CookieSecurePolicy.Always;
        options.Cookie.SameSite = SameSiteMode.Strict;
    }
    else
    {
        options.Cookie.SecurePolicy = CookieSecurePolicy.SameAsRequest;
        options.Cookie.SameSite = SameSiteMode.Lax;
    }
});

// Configure Microsoft Account authentication (if enabled)
var microsoftConfig = builder.Configuration.GetSection("Authentication:Microsoft");
if (microsoftConfig.Exists() && microsoftConfig.GetValue<bool>("Enabled", false))
{
    builder.Services.AddAuthentication()
        .AddMicrosoftAccount("Microsoft", options =>
        {
            options.ClientId = microsoftConfig["ClientId"] ?? "";
            options.ClientSecret = microsoftConfig["ClientSecret"] ?? "";
            options.SaveTokens = true;
            
            options.Events = new Microsoft.AspNetCore.Authentication.OAuth.OAuthEvents
            {
                OnRemoteFailure = context =>
                {
                    context.HandleResponse();
                    context.Response.Redirect("/Account/Login?error=external");
                    return Task.CompletedTask;
                },
                OnTicketReceived = async context =>
                {
                    // Handle the social login in our system
                    var multiAuthService = context.HttpContext.RequestServices.GetRequiredService<IMultiAuthService>();
                    var result = await multiAuthService.SignUpWithSocialAsync("Microsoft", context.Principal);
                    
                    if (!result.Success)
                    {
                        context.Fail(result.ErrorMessage ?? "Authentication failed");
                    }
                }
            };
        });
    
    Log.Information("Microsoft authentication configured");
}

// Configure Google authentication (if enabled)
var googleConfig = builder.Configuration.GetSection("Authentication:Google");
if (googleConfig.Exists() && googleConfig.GetValue<bool>("Enabled", false))
{
    builder.Services.AddAuthentication()
        .AddGoogle("Google", options =>
        {
            options.ClientId = googleConfig["ClientId"] ?? "";
            options.ClientSecret = googleConfig["ClientSecret"] ?? "";
            options.SaveTokens = true;
            
            options.Events = new Microsoft.AspNetCore.Authentication.OAuth.OAuthEvents
            {
                OnRemoteFailure = context =>
                {
                    context.HandleResponse();
                    context.Response.Redirect("/Account/Login?error=external");
                    return Task.CompletedTask;
                },
                OnTicketReceived = async context =>
                {
                    // Handle the social login in our system
                    var multiAuthService = context.HttpContext.RequestServices.GetRequiredService<IMultiAuthService>();
                    var result = await multiAuthService.SignUpWithSocialAsync("Google", context.Principal);
                    
                    if (!result.Success)
                    {
                        context.Fail(result.ErrorMessage ?? "Authentication failed");
                    }
                }
            };
        });
    
    Log.Information("Google authentication configured");
}

// Configure LinkedIn authentication (if enabled)
var linkedInConfig = builder.Configuration.GetSection("Authentication:LinkedIn");
if (linkedInConfig.Exists() && linkedInConfig.GetValue<bool>("Enabled", false))
{
    builder.Services.AddAuthentication()
        .AddOAuth("LinkedIn", "LinkedIn", options =>
        {
            options.ClientId = linkedInConfig["ClientId"] ?? "";
            options.ClientSecret = linkedInConfig["ClientSecret"] ?? "";
            options.SaveTokens = true;
            
            options.AuthorizationEndpoint = "https://www.linkedin.com/oauth/v2/authorization";
            options.TokenEndpoint = "https://www.linkedin.com/oauth/v2/accessToken";
            options.UserInformationEndpoint = "https://api.linkedin.com/v2/me?projection=(id,localizedFirstName,localizedLastName,profilePicture(displayImage~digitalmediaAsset))";
            
            options.Scope.Add("r_liteprofile");
            options.Scope.Add("r_emailaddress");
            
            options.Events = new Microsoft.AspNetCore.Authentication.OAuth.OAuthEvents
            {
                OnRemoteFailure = context =>
                {
                    context.HandleResponse();
                    context.Response.Redirect("/Account/Login?error=external");
                    return Task.CompletedTask;
                },
                OnTicketReceived = async context =>
                {
                    // Handle the social login in our system
                    var multiAuthService = context.HttpContext.RequestServices.GetRequiredService<IMultiAuthService>();
                    var result = await multiAuthService.SignUpWithSocialAsync("LinkedIn", context.Principal);
                    
                    if (!result.Success)
                    {
                        context.Fail(result.ErrorMessage ?? "Authentication failed");
                    }
                }
            };
        });
    
    Log.Information("LinkedIn authentication configured");
}

builder.Services.AddAuthorization();
builder.Services.AddHttpContextAccessor();

// Cookie Authentication Services (Cloud-Ready)
builder.Services.AddScoped<ICookieAuthenticationService, CookieAuthenticationService>();
builder.Services.AddScoped<IFabOSAuthenticationService, FabOSAuthenticationService>();
builder.Services.AddScoped<IMultiAuthService, MultiAuthService>();
builder.Services.AddScoped<AuthenticationStateProvider, CookieAuthenticationStateProvider>();
builder.Services.AddScoped<CookieAuthenticationStateProvider>();

// Add API Key Authentication
builder.Services.AddAuthentication()
    .AddApiKey(options =>
    {
        options.RequireSignature = false; // Can be enabled for enhanced security
    });

Log.Information("Using Cookie authentication (cloud-ready)");

// Add sidebar service
builder.Services.AddScoped<SidebarService>();

// Add deployment services
builder.Services.AddHttpClient<GitHubService>();
builder.Services.AddScoped<DeploymentService>();

// Add circuit handler for authentication state management
builder.Services.AddScoped<CircuitHandler, AuthenticationCircuitHandler>();

// Add session monitoring services
builder.Services.AddScoped<InactivityMonitor>();
builder.Services.AddScoped<SessionTimeoutMonitor>();

// Configure Entity Framework
// Add DbContextFactory for Blazor components (to avoid concurrency issues)
builder.Services.AddDbContextFactory<ApplicationDbContext>(options =>
{
    var connectionString = builder.Configuration.GetConnectionString("DefaultConnection");
    
    // Log the connection string for debugging (mask sensitive parts)
    if (!string.IsNullOrEmpty(connectionString))
    {
        var maskedConn = connectionString.Replace("Password=", "Password=***");
        Log.Information("Using connection string: {ConnectionString}", maskedConn);
    }
    
    options.UseSqlServer(connectionString, sqlOptions =>
    {
        sqlOptions.EnableRetryOnFailure(
            maxRetryCount: 5,
            maxRetryDelay: TimeSpan.FromSeconds(30),
            errorNumbersToAdd: null);
        sqlOptions.UseQuerySplittingBehavior(QuerySplittingBehavior.SplitQuery);
    });
    
    // Enable detailed errors in staging
    if (builder.Environment.IsStaging())
    {
        options.EnableDetailedErrors();
        options.EnableSensitiveDataLogging();
    }
});

// Also add scoped DbContext for services that need it
builder.Services.AddScoped<ApplicationDbContext>(p => 
    p.GetRequiredService<IDbContextFactory<ApplicationDbContext>>().CreateDbContext());

// Configure Multi-Tenant Support (disabled by default)
var enableMultiTenant = builder.Configuration.GetValue<bool>("MultiTenant:EnableDatabasePerTenant", false);
if (enableMultiTenant)
{
    Log.Information("Multi-tenant mode is ENABLED");
    
    // Add master database context for tenant registry
    builder.Services.AddDbContext<MasterDbContext>(options =>
    {
        var masterConnectionString = builder.Configuration.GetConnectionString("MasterDatabase") 
            ?? builder.Configuration.GetConnectionString("DefaultConnection");
        options.UseSqlServer(masterConnectionString, sqlOptions =>
        {
            sqlOptions.UseQuerySplittingBehavior(QuerySplittingBehavior.SplitQuery);
        });
    });
    
    // Add tenant services
    builder.Services.AddScoped<IKeyVaultService, SteelEstimation.Infrastructure.Services.KeyVaultService>();
    builder.Services.AddScoped<ITenantService, SteelEstimation.Infrastructure.Services.TenantService>();
    builder.Services.AddScoped<ITenantProvisioningService, SteelEstimation.Infrastructure.Services.TenantProvisioningService>();
    builder.Services.AddScoped<ITenantDbContextFactory<TenantDbContext>, SteelEstimation.Infrastructure.Services.TenantDbContextFactory>();
    
    // Add tenant database context factory
    builder.Services.AddDbContextFactory<TenantDbContext>((serviceProvider, options) =>
    {
        // This would be configured per-request based on tenant ID
        // For now, use default connection
        var connectionString = builder.Configuration.GetConnectionString("DefaultConnection");
        options.UseSqlServer(connectionString, sqlOptions =>
        {
            sqlOptions.UseQuerySplittingBehavior(QuerySplittingBehavior.SplitQuery);
        });
    });
}
else
{
    Log.Information("Multi-tenant mode is DISABLED (single-tenant mode)");
    
    // Register stub implementations that return single-tenant defaults
    builder.Services.AddSingleton<IKeyVaultService>(new SteelEstimation.Infrastructure.Services.KeyVaultService(
        builder.Configuration, 
        new Logger<SteelEstimation.Infrastructure.Services.KeyVaultService>(LoggerFactory.Create(b => b.AddSerilog()))));
}

// Cookie authentication is already configured above - removed duplicate

// Add authorization
builder.Services.AddAuthorization(options =>
{
    // Existing role-based policies
    options.AddPolicy("Administrator", policy => policy.RequireRole("Administrator"));
    options.AddPolicy("ProjectManager", policy => policy.RequireRole("Administrator", "Project Manager"));
    options.AddPolicy("Estimator", policy => policy.RequireRole("Administrator", "Project Manager", "Senior Estimator", "Estimator"));
    options.AddPolicy("Viewer", policy => policy.RequireAuthenticatedUser());
    
    // New product-based policies for Fab.OS
    options.AddPolicy("Estimate.Access", policy => 
        policy.RequireClaim("Product.Estimate", "true"));
    
    options.AddPolicy("Trace.Access", policy => 
        policy.RequireClaim("Product.Trace", "true"));
    
    options.AddPolicy("Fabmate.Access", policy => 
        policy.RequireClaim("Product.Fabmate", "true"));
    
    options.AddPolicy("QDocs.Access", policy => 
        policy.RequireClaim("Product.QDocs", "true"));
    
    // Feature-specific policies
    options.AddPolicy("Estimate.TimeTracking", policy =>
        policy.RequireClaim("Feature.Estimate.TimeTracking", "true"));
    
    options.AddPolicy("Estimate.WeldingDashboard", policy =>
        policy.RequireClaim("Feature.Estimate.WeldingDashboard", "true"));
    
    options.AddPolicy("Fabmate.Production", policy =>
        policy.RequireClaim("Feature.Fabmate.Production", "true"));
    
    options.AddPolicy("QDocs.Compliance", policy =>
        policy.RequireClaim("Feature.QDocs.Compliance", "true"));
});

// Register application services
builder.Services.AddScoped<IAuthenticationService, SteelEstimation.Infrastructure.Services.AuthenticationService>();
builder.Services.AddScoped<ITokenService, SteelEstimation.Infrastructure.Services.TokenService>();
builder.Services.AddScoped<IInviteService, SteelEstimation.Infrastructure.Services.InviteService>();
builder.Services.AddScoped<IUserService, SteelEstimation.Infrastructure.Services.UserService>();
// builder.Services.AddScoped<IProjectService, ProjectService>();
// builder.Services.AddScoped<ICalculationService, CalculationService>();
builder.Services.AddScoped<IExcelService, SteelEstimation.Infrastructure.Services.ExcelService>();
builder.Services.AddScoped<SteelEstimation.Core.Services.IImageUploadService, SteelEstimation.Infrastructure.Services.ImageUploadService>();
builder.Services.AddScoped<SteelEstimation.Core.Services.IWorksheetChangeService, SteelEstimation.Infrastructure.Services.WorksheetChangeService>();
builder.Services.AddScoped<SteelEstimation.Core.Interfaces.IWorksheetColumnService, SteelEstimation.Infrastructure.Services.WorksheetColumnService>();
builder.Services.AddScoped<SteelEstimation.Core.Services.ITimeTrackingService, SteelEstimation.Infrastructure.Services.TimeTrackingService>();
builder.Services.AddScoped<SteelEstimation.Core.Services.IMaterialTypeService, SteelEstimation.Infrastructure.Services.MaterialTypeService>();
builder.Services.AddScoped<SteelEstimation.Core.Services.ICompanySettingsService, SteelEstimation.Infrastructure.Services.CompanySettingsService>();
builder.Services.AddScoped<SteelEstimation.Core.Services.IEfficiencyRateService, SteelEstimation.Infrastructure.Services.EfficiencyRateService>();
builder.Services.AddScoped<SteelEstimation.Core.Services.IDashboardMetricsService, SteelEstimation.Infrastructure.Services.DashboardMetricsService>();
builder.Services.AddScoped<SteelEstimation.Core.Services.ISettingsService, SteelEstimation.Infrastructure.Services.SettingsService>();
builder.Services.AddScoped<SteelEstimation.Core.Services.IWorksheetFieldService, SteelEstimation.Infrastructure.Services.WorksheetFieldService>();
builder.Services.AddScoped<SteelEstimation.Core.Services.IWorksheetTemplateService, SteelEstimation.Infrastructure.Services.WorksheetTemplateService>();
builder.Services.AddScoped<SteelEstimation.Core.Services.IFeatureAccessService, SteelEstimation.Infrastructure.Services.FeatureAccessService>();
// builder.Services.AddScoped<IEmailService, EmailService>();
// builder.Services.AddScoped<IAuditService, AuditService>();

// Add ABN lookup service with HttpClient
builder.Services.AddHttpClient<IABNLookupService, SteelEstimation.Infrastructure.Services.ABNLookupService>(client =>
{
    client.Timeout = TimeSpan.FromSeconds(30);
});

// Add Postcode lookup service with HttpClient
builder.Services.AddHttpClient<IPostcodeLookupService, SteelEstimation.Infrastructure.Services.PostcodeLookupService>(client =>
{
    client.Timeout = TimeSpan.FromSeconds(10);
});

// Configure TimeTracker settings
builder.Services.Configure<SteelEstimation.Core.Configuration.TimeTrackerSettings>(
    builder.Configuration.GetSection("TimeTracking"));

// Configure Bundle settings
builder.Services.Configure<SteelEstimation.Core.Configuration.BundleSettings>(
    builder.Configuration.GetSection("BundleSettings"));

// Configure Material Mapping settings
builder.Services.Configure<SteelEstimation.Core.Configuration.MaterialMappingSettings>(
    builder.Configuration.GetSection("MaterialMappings"));

// Add AutoMapper with specific assemblies
builder.Services.AddAutoMapper(typeof(Program).Assembly);

// Add FluentValidation
builder.Services.AddFluentValidationAutoValidation();
builder.Services.AddFluentValidationClientsideAdapters();

// Configure CORS
builder.Services.AddCors(options =>
{
    options.AddPolicy("AllowBlazor",
        builder => builder
            .AllowAnyOrigin()
            .AllowAnyMethod()
            .AllowAnyHeader());
});

// Add HttpContextAccessor
builder.Services.AddHttpContextAccessor();

// Add memory cache
builder.Services.AddMemoryCache();

// Configure session
builder.Services.AddSession(options =>
{
    options.IdleTimeout = TimeSpan.FromHours(8);
    options.Cookie.HttpOnly = true;
    options.Cookie.IsEssential = true;
});

var app = builder.Build();

// Configure the HTTP request pipeline.
if (!app.Environment.IsDevelopment())
{
    app.UseExceptionHandler("/Error");
    app.UseHsts();
}

// Add detailed error logging for staging
if (app.Environment.IsStaging())
{
    app.Use(async (context, next) =>
    {
        try
        {
            await next();
        }
        catch (Exception ex)
        {
            Log.Error(ex, "Unhandled exception in request {Path}", context.Request.Path);
            throw;
        }
    });
}

// Only use HTTPS redirection in production
if (!app.Environment.IsDevelopment())
{
    app.UseHttpsRedirection();
}

app.UseStaticFiles();
app.UseRouting();

app.UseCors("AllowBlazor");

// Enable authentication middleware for cookie auth
app.UseAuthentication();
app.UseAuthorization();

app.UseSession();

app.MapBlazorHub();
app.MapRazorPages();
app.MapControllers();
app.MapFallbackToPage("/_Host");

// Run database migrations
try
{
    using (var scope = app.Services.CreateScope())
    {
        var dbContext = scope.ServiceProvider.GetRequiredService<ApplicationDbContext>();
        if (app.Environment.IsDevelopment())
        {
            dbContext.Database.EnsureCreated();
            // Seed development data
            await WeldingConnectionSeeder.SeedDefaultConnections(dbContext);
        }
        else if (app.Environment.IsStaging())
        {
            // Skip ALL database operations in staging
            Log.Information("Skipping database operations in staging environment");
        }
        else if (app.Environment.IsProduction())
        {
            // In production, only run migrations if NOT using Managed Identity
            // Managed Identity typically doesn't have db_ddladmin permissions
            var connectionString = builder.Configuration.GetConnectionString("DefaultConnection");
            if (connectionString != null && connectionString.Contains("Password="))
            {
                // SQL Authentication - can run migrations
                dbContext.Database.Migrate();
            }
            else
            {
                // Managed Identity - skip migrations
                Log.Information("Skipping database migrations in production with Managed Identity");
            }
        }
    }
}
catch (Exception ex)
{
    Log.Error(ex, "Error during database initialization. Application will continue without migrations.");
}

app.Run();