class ChartManager {
    constructor() {
        this.charts = {};
        this.maxDataPoints = 60;
    }

    createChart(canvasId, label, color) {
        const ctx = document.getElementById(canvasId).getContext('2d');

        this.charts[canvasId] = new Chart(ctx, {
            type: 'line',
            data: {
                labels: [],
                datasets: [{
                    label: label,
                    data: [],
                    borderColor: color,
                    backgroundColor: this.hexToRGBA(color, 0.2),
                    borderWidth: 2,
                    tension: 0.4,
                    fill: true,
                    pointRadius: 0
                }]
            },
            options: {
                responsive: true,
                maintainAspectRatio: false,
                animation: false,
                plugins: {
                    legend: { display: false },
                    tooltip: { enabled: true }
                },
                scales: {
                    x: { display: false },
                    y: {
                        beginAtZero: true,
                        grid: { color: '#2a2f4a' },
                        ticks: { color: '#e0e0e0' }
                    }
                }
            }
        });

        return this.charts[canvasId];
    }

    updateChart(canvasId, value) {
        const chart = this.charts[canvasId];
        if (!chart) return;

        const now = new Date().toLocaleTimeString();
        chart.data.labels.push(now);
        chart.data.datasets[0].data.push(value);

        // Keep only last N points
        if (chart.data.labels.length > this.maxDataPoints) {
            chart.data.labels.shift();
            chart.data.datasets[0].data.shift();
        }

        chart.update('none'); // No animation for performance
    }

    clearChart(canvasId) {
        const chart = this.charts[canvasId];
        if (!chart) return;

        chart.data.labels = [];
        chart.data.datasets[0].data = [];
        chart.update('none');
    }

    destroyChart(canvasId) {
        const chart = this.charts[canvasId];
        if (chart) {
            chart.destroy();
            delete this.charts[canvasId];
        }
    }

    hexToRGBA(hex, alpha) {
        const r = parseInt(hex.slice(1, 3), 16);
        const g = parseInt(hex.slice(3, 5), 16);
        const b = parseInt(hex.slice(5, 7), 16);
        return `rgba(${r}, ${g}, ${b}, ${alpha})`;
    }
}
