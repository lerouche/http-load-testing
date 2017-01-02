const fs = require('fs');

let timeStarted;
let times = {};
(function() {
    let lines = fs.readFileSync(__dirname + '/times.log', 'utf8').split(/[\r\n]+/).map(line => line.trim()).filter(line => !!line);
    timeStarted = Number.parseInt(lines.splice(0, 1)[0]);
    let currentTest;
    lines.forEach(function(line) {
        if (line[0] == '#') {
            currentTest = line.slice(1);
            times[currentTest] = {};
        } else {
            let parts = line.split(';');
            times[currentTest][parts[0]] = {
                started: Number.parseInt(parts[1]),
                ended: Number.parseInt(parts[2]),
            };
        }
    });
})();

let systemLoadData = [];
(function() {
    let lines = fs.readFileSync(__dirname + '/system-load.csv', 'utf8').split(/[\r\n]+/).map(line => line.trim()).filter(line => !!line);
    lines.splice(0, 7);
    lines.forEach(function(line, lineNo) {
        let parts = line.split(',');
        systemLoadData.push({
            timestamp: timeStarted + (1000 * lineNo),
            totalCpuUsage: Number.parseFloat(parts[0]),
            memoryUsage: Number.parseFloat(parts[6]) / 1024 / 1024,
        });
    });
})();

let values = Object.create(null);
let errors = Object.create(null);

fs.readdirSync(__dirname + '/results').forEach(testName => {
    let results = values[testName] = Object.create(null);
    let currentTestErrors = errors[testName] = Object.create(null);

    fs.readdirSync(__dirname + '/results/' + testName).forEach(testSubject => {
        testSubject = testSubject.slice(0, -4);
        let file = fs.readFileSync(`${__dirname}/results/${testName}/${testSubject}.log`, {encoding: 'utf8'});
        let regexpMatches;

        regexpMatches = /^Requests per second:\s+([0-9.]+)/m.exec(file);
        let requestsPerSecond = (regexpMatches && regexpMatches[1]) | 0; // Will be zero if not found

        regexpMatches = /^Non-2xx responses:\s+([0-9]+)/m.exec(file);
        let totalErrors = (regexpMatches && regexpMatches[1]) | 0; // Will be zero if not found

        regexpMatches = /^Failed requests:\s+([0-9]+)/m.exec(file);
        totalErrors += (regexpMatches && regexpMatches[1]) | 0; // Will be zero if not found

        results[testSubject] = requestsPerSecond;
        currentTestErrors[testSubject] = totalErrors;
    });
});

let chartColors = JSON.stringify({
    PHP: '#8892bf',
    Express: '#353535',
    OpenResty: '#518451',
});

let html = `
    <!DOCTYPE html>
    <html>
        <head>
            <title>Here are your results</title>

            <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/c3/0.4.11/c3.min.css">
            <style>
                * {
                    box-sizing: border-box;
                }
                #chart-requests, #chart-errors, .charts-group-test-sysload {
                    margin: 0 auto;
                    width: calc(100% - 40px);
                }
                main {
                    background: rgb(230, 230, 230);
                }
                .charts-group-test-sysload-container {
                    background: rgb(240, 240, 240);
                }
                .charts-group-test-sysload-container > h2 {
                    background: rgba(0, 49, 100, 0.9);
                    color: white;
                    margin: 0;
                    padding: 10px;
                }
                .charts-group-test-sysload {
                    display: flex;
                    width: 100%;
                }
                .chart-sysload-container {
                    flex-grow: 1;
                }
                body {
                    margin: 0;
                    font-family: -apple-system, BlinkMacSystemFont, Segoe UI, Roboto, Helvetica Neue, Ubuntu, Cantarell, Oxygen, Droid Sans, Fira Sans, sans-serif;
                }
                #title {
                    background: rgb(0, 49, 100);
                    color: white;
                    font-size: 24px;
                    font-weight: 400;

                    margin: 0;
                    padding: 0 12px;
                    height: 50px;
                    line-height: 50px;

                    white-space: nowrap;
                    overflow: hidden;
                    text-overflow: ellipsis;
                }
                #controls {
                    display: flex;
                    flex-direction: row-reverse;
                    align-items: center;
                    height: 30px;
                    padding: 0 10px;
                }
            </style>

            <script src="https://cdnjs.cloudflare.com/ajax/libs/d3/3.5.17/d3.min.js"></script>
            <script src="https://cdnjs.cloudflare.com/ajax/libs/c3/0.4.11/c3.min.js"></script>
            <script>
                var sysloadCharts = [];
                function resizeCharts() {
                    requestsChart.resize({
                        height: document.documentElement.clientHeight - 80,
                    });
                    sysloadCharts.forEach(function(chart) {
                        chart.resize({
                            width: (document.documentElement.clientWidth - 40) / 2,
                        })
                    });
                }
            </script>
        </head>

        <body onresize="resizeCharts()" onorientationchange="resizeCharts()">
            <h1 id="title">Load testing on </h1>
            <main>
                <div id="controls">
                    <button onclick="normaliseChart()">Normalise</button>
                </div>`;

(function() {
    let chartColumns = [];
    let chartXTickLabels = [];

    Object.keys(values).forEach((testName, i) => {

        chartXTickLabels.push(testName);

        Object.keys(values[testName]).forEach(testSubject => {

            let chartColumn = chartColumns.find(col => col[0] == testSubject);
            if (!chartColumn) chartColumn = chartColumns[chartColumns.length] = [testSubject];

            chartColumn[i + 1] = values[testName][testSubject];
        });

    });

    chartColumns.unshift(['testNames', ...chartXTickLabels]);
    chartColumns = JSON.stringify(chartColumns);

    html += `
        <div id="chart-requests"></div>
        <script>
            function normaliseChart() {
                requestsChart.axis.max(30000);
            }
            var requestsChart = c3.generate({
                bindto: '#chart-requests',
                data: {
                    x: 'testNames',
                    columns: ${chartColumns},
                    type: 'bar',
                    colors: ${chartColors}
                },
                axis: {
                    x: {
                        type: 'category'
                    },
                    y: {
                        label: {
                            text: 'Requests per second (mean)',
                            position: 'outer-middle'
                        }
                    }
                },
            });
            setTimeout(resizeCharts, 1000);
        </script>
    `;
})();

(function() {
    let chartColumns = [];
    let chartXTickLabels = [];

    Object.keys(errors).forEach((testName, i) => {

        chartXTickLabels.push(testName);

        Object.keys(errors[testName]).forEach(testSubject => {

            let chartColumn = chartColumns.find(col => col[0] == testSubject);
            if (!chartColumn) chartColumn = chartColumns[chartColumns.length] = [testSubject];

            chartColumn[i + 1] = errors[testName][testSubject];
        });

    });

    chartColumns.unshift(['testNames', ...chartXTickLabels]);
    chartColumns = JSON.stringify(chartColumns);

    html += `
        <div id="chart-errors"></div>
        <script>
            var errorsChart = c3.generate({
                bindto: '#chart-errors',
                data: {
                    x: 'testNames',
                    columns: ${chartColumns},
                    type: 'bar',
                    colors: ${chartColors}
                },
                axis: {
                    x: {
                        type: 'category'
                    },
                    y: {
                        label: {
                            text: 'Total errors',
                            position: 'outer-middle'
                        }
                    }
                }
            });
        </script>
    `;
})();

html += '</main>';

Object.keys(times).forEach(function(test) {
    let timeData = times[test];
    let cpuChartColumns = [];
    let memoryChartColumns = [];
    Object.keys(timeData).forEach(function(subject) {
        let {started, ended} = timeData[subject];
        
        let systemLoadDataStart, systemLoadDataEnd;
        for (let i = 0; i < systemLoadData.length; i++) {
            let data = systemLoadData[i];
            if (data.timestamp >= started) {
                systemLoadDataStart = i - 1;
                break;
            }
        }
        for (let i = systemLoadData.length - 1; i >= 0; i--) {
            let data = systemLoadData[i];
            if (data.timestamp <= ended) {
                systemLoadDataEnd = i + 1;
                break;
            }
        }
        let relevantSystemLoadData = systemLoadData.slice(systemLoadDataStart, systemLoadDataEnd + 1);

        let ticksCount = systemLoadDataEnd - systemLoadDataStart + 1;

        cpuChartColumns.push([
            subject,
            ...relevantSystemLoadData.map(d => d.totalCpuUsage),
        ]);

        memoryChartColumns.push([
            subject,
            ...relevantSystemLoadData.map(d => d.memoryUsage),
        ]);
    });
    [cpuChartColumns, memoryChartColumns] = [cpuChartColumns, memoryChartColumns].map(c => JSON.stringify(c));

    html += `
        <div class="charts-group-test-sysload-container">
            <h2>${test}</h2>
            <div class="charts-group-test-sysload">
                <div class="chart-sysload-container">
                    <h3>CPU</h3>
                    <div class="chart-sysload-cpu" data-test="${test.toLowerCase()}"></div>
                    <script>
                        sysloadCharts[sysloadCharts.length] = c3.generate({
                            bindto: '.chart-sysload-cpu[data-test="${test.toLowerCase()}"]',
                            data: {
                                columns: ${cpuChartColumns},
                                colors: ${chartColors},
                            }
                        });
                    </script>
                </div>

                <div class="chart-sysload-container">
                    <h3>Memory</h3>
                    <div class="chart-sysload-ram" data-test="${test.toLowerCase()}"></div>
                    <script>
                        sysloadCharts[sysloadCharts.length] = c3.generate({
                            bindto: '.chart-sysload-ram[data-test="${test.toLowerCase()}"]',
                            data: {
                                columns: ${memoryChartColumns},
                                colors: ${chartColors},
                            }
                        });
                    </script>
                </div>
            </div>
        </div>
    `;
});

fs.writeFileSync(__dirname + '/report.html', html);