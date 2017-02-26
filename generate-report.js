const fs = require('fs');

let readline = require('readline').createInterface({
    input: process.stdin,
    output: process.stdout,
});

let sysinfo = {};

readline.question('\nEnter the name for this report: ', answer => {
    sysinfo.name = answer.toString().trim();
    readline.close();
    main();
    process.exit(0);
});

function main() {

    (function () {
        let lines = fs.readFileSync(__dirname + '/system.info', 'utf8').split(/[\r\n]+/).map(line => line.trim()).filter(line => !!line);
        lines.forEach(function (line) {
            let parts = line.split('=');
            sysinfo[parts[0]] = Number(parts[1]);
        });
    })();

    let timeStarted;
    let times = {};
    (function () {
        let lines = fs.readFileSync(__dirname + '/times.log', 'utf8').split(/[\r\n]+/).map(line => line.trim()).filter(line => !!line);
        timeStarted = Number.parseInt(lines.splice(0, 1)[0], 10);
        let currentTest;
        lines.forEach(function (line) {
            if (line[0] == '#') {
                currentTest = line.slice(1);
                times[currentTest] = {};
            } else {
                let parts = line.split(';');
                times[currentTest][parts[0]] = {
                    started: Number.parseInt(parts[1], 10),
                    ended: Number.parseInt(parts[2], 10),
                };
            }
        });
    })();

    let systemLoadData = [];
    let systemLoadDataPeriods = [];
    (function () {
        let lines = fs.readFileSync(__dirname + '/system-load.csv', 'utf8').split(/[\r\n]+/).map(line => line.trim()).filter(line => !!line);
        lines.slice(7).forEach(function (line, lineNo) {
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

    let chartColors = {
        Sleep: '#ccc',
        PHP: '#000',
        HHVM: '#2a5696',
        Express: '#1d7044',
        OpenResty: '#d14424',
    };

    let chartColumnOrder = ['Express', 'PHP', 'HHVM', 'OpenResty'];
    let sortChartColumns = function (cols) {
        cols.sort((colA, colB) => {
            let a = chartColumnOrder.indexOf(colA[0]);
            let b = chartColumnOrder.indexOf(colB[0]);
            if (a < b) {
                return -1;
            } else if (a == b) {
                return 0;
            } else {
                return 1;
            }
        });
        return cols;
    };

    let json = {};

    json.sysinfo = sysinfo;
    json.tests = Object.keys(values);
    json.errors = errors;

    (function () {
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

        sortChartColumns(chartColumns);
        chartColumns.unshift(['Test', ...chartXTickLabels]);

        json.requestsChart = {
            data: {
                x: 'Test',
                columns: chartColumns,
                type: 'bar',
                labels: true,
                colors: chartColors
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
        };
    })();

    json.testSysloadCharts = {};
    Object.keys(times).forEach(function (test) {
        let timeData = times[test];
        let cpuChartColumns = [];
        let memoryChartColumns = [];
        systemLoadDataPeriods[test] = {};

        Object.keys(timeData).forEach(function (subject) {
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
                    systemLoadDataEnd = Math.min(systemLoadData.length - 1, i + 1);
                    break;
                }
            }
            let relevantSystemLoadData = systemLoadData.slice(systemLoadDataStart, systemLoadDataEnd + 1);

            systemLoadDataPeriods[test][subject] = {
                startIdx: systemLoadDataStart,
                endIdx: systemLoadDataEnd,
            };

            cpuChartColumns.push([
                subject,
                ...relevantSystemLoadData.map(d => d.totalCpuUsage),
            ]);

            memoryChartColumns.push([
                subject,
                ...relevantSystemLoadData.map(d => d.memoryUsage),
            ]);
        });

        [cpuChartColumns, memoryChartColumns].forEach(c => sortChartColumns(c));

        json.testSysloadCharts[test] = {};
        json.testSysloadCharts[test].cpu = {
            data: {
                columns: cpuChartColumns,
                colors: chartColors,
            },
            axis: {
                y: {
                    min: 0,
                    max: 100,
                    padding: 0,
                    label: {
                        text: 'Total CPU usage (%)',
                        position: 'outer-middle',
                    },
                },
            },
        };
        json.testSysloadCharts[test].memory = {
            data: {
                columns: memoryChartColumns,
                colors: chartColors,
            },
            axis: {
                y: {
                    min: 0,
                    padding: 0,
                    label: {
                        text: 'Memory usage (MB)',
                        position: 'outer-middle',
                    },
                },
            },
        };
    });

    (function () {
        let cpuChartColumns = [
            ['Sleep', ...systemLoadData.map(d => d.totalCpuUsage)]
        ];
        let memoryChartColumns = [
            ['Sleep', ...systemLoadData.map(d => d.memoryUsage)]
        ];

        Object.keys(systemLoadDataPeriods).forEach(test => {
            Object.keys(systemLoadDataPeriods[test]).forEach(subject => {
                let startIdx = systemLoadDataPeriods[test][subject].startIdx;
                let endIdx = systemLoadDataPeriods[test][subject].endIdx;

                let cpuColumn = cpuChartColumns.find(c => c[0] == subject);
                if (!cpuColumn) {
                    cpuColumn = cpuChartColumns[cpuChartColumns.length] = Array(systemLoadData.length + 1);
                    cpuColumn[0] = subject;
                }
                let memoryColumn = memoryChartColumns.find(c => c[0] == subject);
                if (!memoryColumn) {
                    memoryColumn = memoryChartColumns[memoryChartColumns.length] = Array(systemLoadData.length + 1);
                    memoryColumn[0] = subject;
                }

                for (let i = startIdx; i <= endIdx; i++) {
                    cpuColumn[i + 1] = systemLoadData[i].totalCpuUsage;
                    memoryColumn[i + 1] = systemLoadData[i].memoryUsage;
                    if (i != startIdx && i != endIdx) {
                        delete cpuChartColumns[0][i + 1];
                        delete memoryChartColumns[0][i + 1];
                    }
                }
            });
        });

        [cpuChartColumns, memoryChartColumns].forEach(c => sortChartColumns(c));

        json.totalCpuChart = {
            data: {
                columns: cpuChartColumns,
                colors: chartColors,
            },
            axis: {
                y: {
                    min: 0,
                    max: 100,
                    padding: 0,
                },
            },
        };
        json.totalMemoryChart = {
            data: {
                columns: memoryChartColumns,
                colors: chartColors,
            },
            axis: {
                y: {
                    min: 0,
                    padding: 0,
                },
            },
        };
    })();

    fs.writeFileSync(__dirname + '/report.json', JSON.stringify(json));

    require(__dirname + '/report-template/node_modules/zcompile/src/zc.js')({
        src: __dirname + '/report-template',
        dst: __dirname + '/',

        files: ['report.html'],
        minifyHtmlJS: true,
        minifyHtmlCSS: true,
        minifyJS: {
            passes: 1
        }
    });

    fs.unlinkSync(__dirname + '/report.json');

}
