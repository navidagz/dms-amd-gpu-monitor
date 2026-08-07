pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// amdgpu_top reports every GPU in a single document, and DankBar builds one bar
// per screen, so polling here keeps it at one call per tick instead of one per
// widget per screen.
Singleton {
    id: root

    readonly property int defaultInterval: 4000

    property var devices: []
    property var suspendedDevices: []
    property bool statsError: false

    // Keyed by widget so the copies of a variant mirrored across screens hold a
    // slot each, and releasing one never cancels the others.
    property var subscribers: []

    function request(widget, interval) {
        const entry = subscribers.find(s => s.widget === widget);
        if (entry)
            entry.interval = Math.max(1000, interval || defaultInterval);
        else
            subscribers.push({ widget: widget, interval: Math.max(1000, interval || defaultInterval) });
        sync();
    }

    function release(widget) {
        subscribers = subscribers.filter(s => s.widget !== widget);
        sync();
    }

    // The fastest widget sets the pace, so a widget at 1s still updates at 1s.
    function sync() {
        updateTimer.interval = subscribers.length
            ? Math.min(...subscribers.map(s => s.interval))
            : defaultInterval;
        updateTimer.running = subscribers.length > 0;
    }

    function deviceByPci(pci) {
        return pci ? devices.find(d => d["Info"]?.["PCI"] === pci) || null : null;
    }

    function suspendedByPci(pci) {
        return pci ? suspendedDevices.find(d => d.pci === pci) || null : null;
    }

    // Kept for variants created before GPUs were addressed by PCI.
    function deviceByIndex(index) {
        return devices[index] || devices[0] || null;
    }

    Timer {
        id: updateTimer
        interval: root.defaultInterval
        running: false
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            if (!pollProcess.running)
                pollProcess.running = true;
        }
    }

    Process {
        id: pollProcess
        command: ["amdgpu_top", "-J", "-n", "1"]
        running: false

        onExited: exitCode => {
            if (exitCode !== 0) {
                root.statsError = true;
                console.warn(`amdGpuMonitor: amdgpu_top exited with code ${exitCode}`);
            }
        }

        stderr: StdioCollector {
            onStreamFinished: {
                const errorText = text.trim();
                if (errorText.length > 0) {
                    root.statsError = true;
                    console.warn(`amdGpuMonitor: ${errorText}`);
                }
            }
        }

        stdout: StdioCollector {
            onStreamFinished: {
                let data;
                try {
                    data = JSON.parse(text.trim());
                } catch (e) {
                    root.statsError = true;
                    console.warn(`amdGpuMonitor: failed to parse amdgpu_top output: ${e}`);
                    return;
                }

                root.statsError = false;
                root.devices = Array.isArray(data.devices) ? data.devices : [];
                root.suspendedDevices = Array.isArray(data.suspended_devices) ? data.suspended_devices : [];
            }
        }
    }
}
