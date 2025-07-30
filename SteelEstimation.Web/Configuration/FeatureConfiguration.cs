namespace SteelEstimation.Web.Configuration
{
    /// <summary>
    /// Central configuration for feature codes used throughout the application
    /// These codes should match what's configured in the Admin Portal
    /// </summary>
    public static class FeatureConfiguration
    {
        // Core Features
        public const string Dashboard = "CORE.DASHBOARD";
        public const string BasicEstimations = "CORE.ESTIMATIONS";
        public const string CustomerManagement = "CORE.CUSTOMERS";
        
        // Advanced Estimation Features
        public const string TimeTracking = "ESTIMATION.TIME_TRACKING";
        public const string EfficiencyRates = "ESTIMATION.EFFICIENCY_RATES";
        public const string PackBundles = "ESTIMATION.PACK_BUNDLES";
        public const string WeldingAnalytics = "ESTIMATION.WELDING_ANALYTICS";
        
        // Analytics & Reporting
        public const string BasicReports = "ANALYTICS.BASIC_REPORTS";
        public const string AdvancedReports = "ANALYTICS.ADVANCED_REPORTS";
        public const string TimeAnalytics = "ANALYTICS.TIME_ANALYTICS";
        public const string ExportData = "ANALYTICS.EXPORT_DATA";
        
        // Integration Features
        public const string ImportExport = "INTEGRATION.IMPORT_EXPORT";
        public const string ExcelImport = "INTEGRATION.EXCEL_IMPORT";
        public const string ApiAccess = "INTEGRATION.API_ACCESS";
        
        // Workflow Features
        public const string WorksheetTemplates = "WORKFLOW.WORKSHEET_TEMPLATES";
        public const string CustomWorkflows = "WORKFLOW.CUSTOM_WORKFLOWS";
        public const string Automation = "WORKFLOW.AUTOMATION";
        
        // Administration
        public const string UserManagement = "ADMIN.USER_MANAGEMENT";
        public const string CompanySettings = "ADMIN.COMPANY_SETTINGS";
        public const string SystemSettings = "ADMIN.SYSTEM_SETTINGS";
    }
}