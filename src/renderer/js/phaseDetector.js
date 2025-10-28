class PhaseDetector {
    constructor() {
        this.currentPhase = 'Idle';
        this.phaseStart = new Date();
        this.history = [];
    }

    detect(metrics) {
        const { cpu, mem, diskQ, netTotal } = metrics;

        let phase = 'Idle';
        let confidence = 0.5;

        // Rule-based heuristics for phase detection
        if (netTotal > 5 && cpu < 30) {
            phase = 'Downloading';
            confidence = 0.9;
        } else if (cpu > 40 && diskQ > 3) {
            phase = 'Installing';
            confidence = 0.85;
        } else if (diskQ > 5 && cpu > 30 && netTotal < 1) {
            phase = 'Configuring';
            confidence = 0.8;
        } else if (cpu > 20 && netTotal < 1) {
            phase = 'Processing';
            confidence = 0.7;
        } else if (cpu < 10 && netTotal < 1 && diskQ < 2) {
            phase = 'Idle';
            confidence = 0.95;
        }

        // Track phase change
        if (phase !== this.currentPhase) {
            const duration = (new Date() - this.phaseStart) / 1000;
            this.history.push({
                phase: this.currentPhase,
                duration: Math.round(duration),
                end: new Date()
            });

            this.currentPhase = phase;
            this.phaseStart = new Date();
        }

        return {
            phase: phase,
            confidence: confidence,
            duration: Math.round((new Date() - this.phaseStart) / 1000),
            history: this.history.slice(-10) // Keep last 10 phase changes
        };
    }

    getPhaseColor(phase) {
        const colors = {
            'Idle': '#718096',
            'Downloading': '#4299e1',
            'Installing': '#ed8936',
            'Configuring': '#9f7aea',
            'Processing': '#48bb78'
        };
        return colors[phase] || '#718096';
    }

    reset() {
        this.currentPhase = 'Idle';
        this.phaseStart = new Date();
        this.history = [];
    }
}
