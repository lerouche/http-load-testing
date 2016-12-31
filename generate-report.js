const fs = require('fs');

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

        results[testSubject] = requestsPerSecond;
        currentTestErrors[testSubject] = totalErrors;
    });
});

let chartColors = JSON.stringify({
    php: '#8892bf',
    express: '#353535',
    openresty: '#518451',
});

let html = `
    <!DOCTYPE html>
    <html>
        <head>
            <title>Here are your results</title>

            <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/c3/0.4.11/c3.min.css">
            <style>
                #title, #background {
                    box-sizing: border-box;
                }
                #chart-requests, #chart-errors {
                    margin: 0 auto;
                    width: calc(100% - 40px);
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

                    white-space: no-wrap;
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
        </head>

        <body onresize="resizeChart()" onorientationchange="resizeChart()">
            <h1 id="title">Load testing on </h1>
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
            function resizeChart() {
                requestsChart.resize({
                    height: document.documentElement.clientHeight - 80,
                });
            }
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
            setTimeout(resizeChart, 1000);
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

fs.writeFileSync(__dirname + '/report.html', html);