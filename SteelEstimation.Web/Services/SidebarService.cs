using Microsoft.JSInterop;

namespace SteelEstimation.Web.Services
{
    public class SidebarService
    {
        private readonly IJSRuntime _jsRuntime;
        private bool _isOpen = true; // Default to open
        
        public event Action? OnChange;
        
        public bool IsOpen 
        { 
            get => _isOpen;
            private set
            {
                if (_isOpen != value)
                {
                    _isOpen = value;
                    NotifyStateChanged();
                }
            }
        }
        
        public SidebarService(IJSRuntime jsRuntime)
        {
            _jsRuntime = jsRuntime;
        }
        
        public async Task InitializeAsync()
        {
            try
            {
                // For now, always default to open to fix the disappearing issue
                // Users can still toggle it closed if they prefer
                IsOpen = true;
                
                // Save the open state to localStorage
                await _jsRuntime.InvokeVoidAsync("localStorage.setItem", "sidebarOpen", "true");
            }
            catch
            {
                IsOpen = true; // Default to open on error
            }
        }
        
        public async Task ToggleAsync()
        {
            IsOpen = !IsOpen;
            
            try
            {
                await _jsRuntime.InvokeVoidAsync("localStorage.setItem", "sidebarOpen", IsOpen.ToString().ToLower());
                
                // Update DOM
                await UpdateDomAsync();
            }
            catch { }
        }
        
        public async Task UpdateDomAsync()
        {
            try
            {
                var script = IsOpen 
                    ? @"
                        const page = document.getElementById('main-page');
                        const sidebar = document.getElementById('main-sidebar');
                        if (page) page.classList.remove('sidebar-collapsed');
                        if (sidebar) {
                            sidebar.classList.add('sidebar-open');
                            sidebar.style.display = 'block';
                            sidebar.style.visibility = 'visible';
                        }
                        console.log('Sidebar opened');
                    "
                    : @"
                        const page = document.getElementById('main-page');
                        const sidebar = document.getElementById('main-sidebar');
                        if (page) page.classList.add('sidebar-collapsed');
                        if (sidebar) {
                            sidebar.classList.remove('sidebar-open');
                        }
                        console.log('Sidebar collapsed');
                    ";
                    
                await _jsRuntime.InvokeVoidAsync("eval", script);
            }
            catch { }
        }
        
        private void NotifyStateChanged() => OnChange?.Invoke();
    }
}