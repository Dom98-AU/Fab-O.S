// Time Analytics Chart Functions

window.renderTrendsChart = (chartData) => {
    const ctx = document.getElementById('trendsChart');
    if (!ctx) return;

    // Destroy existing chart if it exists
    if (window.trendsChart) {
        window.trendsChart.destroy();
    }

    window.trendsChart = new Chart(ctx, {
        type: 'line',
        data: chartData,
        options: {
            responsive: true,
            interaction: {
                mode: 'index',
                intersect: false,
            },
            plugins: {
                title: {
                    display: true,
                    text: 'Time Efficiency Trends (Last 30 Days)'
                },
                legend: {
                    display: true,
                    position: 'top'
                }
            },
            scales: {
                x: {
                    display: true,
                    title: {
                        display: true,
                        text: 'Date'
                    }
                },
                y: {
                    type: 'linear',
                    display: true,
                    position: 'left',
                    title: {
                        display: true,
                        text: 'Hours'
                    }
                },
                y1: {
                    type: 'linear',
                    display: true,
                    position: 'right',
                    title: {
                        display: true,
                        text: 'Hours per Tonne'
                    },
                    grid: {
                        drawOnChartArea: false,
                    },
                }
            }
        }
    });
};

// Initialize Chart.js when the page loads
document.addEventListener('DOMContentLoaded', function() {
    // Chart.js is loaded via CDN in the layout
    console.log('Time Analytics charts initialized');
});