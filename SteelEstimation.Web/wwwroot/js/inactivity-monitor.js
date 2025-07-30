window.inactivityMonitor = {
    dotNetRef: null,
    activityEvents: ['mousedown', 'mousemove', 'keypress', 'scroll', 'touchstart', 'click'],
    
    initialize: function(dotNetReference) {
        this.dotNetRef = dotNetReference;
        
        // Add event listeners for user activity
        this.activityEvents.forEach(event => {
            document.addEventListener(event, this.handleActivity, true);
        });
        
        console.log('Inactivity monitor initialized');
    },
    
    handleActivity: function() {
        if (window.inactivityMonitor.dotNetRef) {
            // Throttle the calls to .NET
            if (!window.inactivityMonitor.throttleTimer) {
                window.inactivityMonitor.throttleTimer = setTimeout(() => {
                    window.inactivityMonitor.dotNetRef.invokeMethodAsync('UpdateActivity')
                        .catch(error => console.error('Error updating activity:', error));
                    window.inactivityMonitor.throttleTimer = null;
                }, 1000); // Update at most once per second
            }
        }
    },
    
    destroy: function() {
        // Remove all event listeners
        this.activityEvents.forEach(event => {
            document.removeEventListener(event, this.handleActivity, true);
        });
        
        if (this.throttleTimer) {
            clearTimeout(this.throttleTimer);
            this.throttleTimer = null;
        }
        
        this.dotNetRef = null;
        console.log('Inactivity monitor destroyed');
    }
};