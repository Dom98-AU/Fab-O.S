// Simple toast notification helper
window.showToast = function(message, type = 'info') {
    // Remove any existing toasts
    const existingToasts = document.querySelectorAll('.toast-notification');
    existingToasts.forEach(toast => toast.remove());
    
    // Create toast element
    const toast = document.createElement('div');
    toast.className = `toast-notification toast-${type}`;
    toast.textContent = message;
    
    // Add to container or create one
    let container = document.querySelector('.toast-container');
    if (!container) {
        container = document.createElement('div');
        container.className = 'toast-container';
        document.body.appendChild(container);
    }
    
    container.appendChild(toast);
    
    // Animate in
    setTimeout(() => toast.classList.add('show'), 10);
    
    // Remove after 3 seconds
    setTimeout(() => {
        toast.classList.remove('show');
        setTimeout(() => toast.remove(), 300);
    }, 3000);
};

// Add styles if not already present
if (!document.getElementById('toast-styles')) {
    const style = document.createElement('style');
    style.id = 'toast-styles';
    style.textContent = `
        .toast-container {
            position: fixed;
            bottom: 20px;
            right: 20px;
            z-index: 1050;
        }
        
        .toast-notification {
            background-color: #333;
            color: white;
            padding: 12px 20px;
            border-radius: 4px;
            margin-bottom: 10px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.2);
            opacity: 0;
            transform: translateX(100%);
            transition: all 0.3s ease;
            max-width: 350px;
        }
        
        .toast-notification.show {
            opacity: 1;
            transform: translateX(0);
        }
        
        .toast-notification.toast-success {
            background-color: #28a745;
        }
        
        .toast-notification.toast-error {
            background-color: #dc3545;
        }
        
        .toast-notification.toast-warning {
            background-color: #ffc107;
            color: #333;
        }
        
        .toast-notification.toast-info {
            background-color: #17a2b8;
        }
    `;
    document.head.appendChild(style);
}