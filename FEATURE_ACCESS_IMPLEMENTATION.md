# Feature Access Implementation Guide

## Overview
This implementation provides a flexible, API-based feature access control system that allows a separate Admin Portal to manage which features/modules are available to each company in the Steel Estimation Platform.

## Architecture

### 1. API-Based Communication
- Steel Estimation exposes admin API endpoints secured with API key authentication
- Admin Portal manages features centrally and communicates via REST API
- Features are cached locally for performance

### 2. Components Created

#### Backend Components:
- **DTOs** (`/SteelEstimation.Core/DTOs/Admin/`)
  - `FeatureAccessDto.cs` - Feature access information
  - `TenantFeatureUpdateDto.cs` - Update feature access
  - `UsageMetricDto.cs` - Usage tracking
  - `ApiAuthenticationDto.cs` - API authentication

- **Entities** (`/SteelEstimation.Core/Entities/`)
  - `FeatureCache.cs` - Local cache of features
  - `FeatureGroup.cs` - Group related features
  - `ApiKey.cs` - API key management

- **Services**
  - `IFeatureAccessService.cs` - Feature access interface
  - `FeatureAccessService.cs` - Implementation with caching

- **Authentication**
  - `ApiKeyAuthenticationHandler.cs` - Custom authentication handler
  - `ApiKeyAttribute.cs` - Attribute for API endpoints

- **API Controllers** (`/Controllers/Api/`)
  - `FeatureAccessController.cs` - Manage feature access
  - `UsageMetricsController.cs` - Track usage

#### Frontend Components:
- **Blazor Components** (`/Components/Features/`)
  - `FeatureGate.razor` - Conditionally render based on features
  - `FeatureUpgradePrompt.razor` - Show upgrade prompts
  - `FeatureNavLink.razor` - Feature-aware navigation

- **Configuration**
  - `FeatureConfiguration.cs` - Central feature code definitions

### 3. Database Changes
- Migration: `AddFeatureAccessTables.sql`
- Tables: `FeatureCache`, `FeatureGroups`, `ApiKeys`

## Usage Examples

### 1. Basic Feature Gate
```razor
<FeatureGate Feature="@FeatureConfiguration.AdvancedReports">
    <NavLink href="reports/advanced">Advanced Reports</NavLink>
    <NotAuthorized>
        <FeatureUpgradePrompt Feature="Advanced Reports" />
    </NotAuthorized>
</FeatureGate>
```

### 2. Feature-Aware Navigation
```razor
<FeatureNavLink RequiredFeature="@FeatureConfiguration.TimeAnalytics" Href="time-analytics">
    <i class="fas fa-stopwatch nav-icon"></i>
    <span class="nav-text">Time Analytics</span>
</FeatureNavLink>
```

### 3. In Code
```csharp
@inject IFeatureAccessService FeatureService

@code {
    protected override async Task OnInitializedAsync()
    {
        if (!await FeatureService.HasAccessAsync(FeatureConfiguration.WeldingAnalytics))
        {
            NavigationManager.NavigateTo("/upgrade");
        }
    }
}
```

## Admin Portal Integration

### API Endpoints
- `GET /api/admin/featureaccess/{companyId}` - Get features for company
- `POST /api/admin/featureaccess/update` - Update features
- `POST /api/admin/featureaccess/bulk-update` - Bulk update
- `GET /api/admin/usagemetrics/{companyId}` - Get usage metrics

### API Authentication
Headers required:
- `X-API-Key: {your-api-key}`
- Optional: `X-API-Signature`, `X-API-Timestamp`, `X-API-Nonce` for enhanced security

## Next Steps

### 1. Create Admin Portal
Create a separate ASP.NET Core application with:
- Tenant management
- Feature definition and assignment
- Subscription plans
- Usage analytics
- Billing integration

### 2. Define Features
In the Admin Portal, define features like:
- Core Features (always enabled)
- Premium Features (subscription-based)
- Add-on Features (individually purchasable)

### 3. Update NavMenu
Replace static navigation with feature-aware components:
```razor
<!-- Before -->
<NavLink href="reports">Reports</NavLink>

<!-- After -->
<FeatureNavLink RequiredFeature="@FeatureConfiguration.BasicReports" Href="reports">
    <i class="fas fa-chart-bar nav-icon"></i>
    <span class="nav-text">Reports</span>
</FeatureNavLink>
```

### 4. Protect Controllers/Pages
Add feature checks to controllers and pages:
```csharp
public class AdvancedReportsController : Controller
{
    private readonly IFeatureAccessService _featureService;
    
    public async Task<IActionResult> Index()
    {
        if (!await _featureService.HasAccessAsync(FeatureConfiguration.AdvancedReports))
        {
            return RedirectToAction("Upgrade", "Subscription");
        }
        
        return View();
    }
}
```

## Benefits
- **Flexibility**: Define features/modules without code changes
- **Scalability**: Admin Portal can manage multiple products
- **Performance**: Local caching minimizes API calls
- **Security**: API key authentication with optional signatures
- **Analytics**: Built-in usage tracking
- **User Experience**: Graceful degradation with upgrade prompts

## Testing
1. Run the migration to create tables
2. Add an API key to the database
3. Test API endpoints with Postman/curl
4. Create test features in FeatureCache table
5. Verify feature gates work in UI