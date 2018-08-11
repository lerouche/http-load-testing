"use strict";

const FileSystem = require("fs");
const Path = require("path");

class ReportGenerator {
  static sortChartColumns (chartColumns) {
    chartColumns.sort((colA, colB) => {
      let a = ReportGenerator.CHART_COLUMN_ORDER.indexOf(colA[0]);
      let b = ReportGenerator.CHART_COLUMN_ORDER.indexOf(colB[0]);
      if (a < b) {
        return -1;
      } else if (a == b) {
        return 0;
      } else {
        return 1;
      }
    });
    return chartColumns;
  }

  constructor (rootPath) {
    this.rootPath = rootPath;

    this.systemInfo = undefined;
    this.reportName = undefined;

    this.subjectsList = undefined;
    this.testsList = undefined;

    this.benchmarkData = {};
    this.systemLoadData = {};

    this.requestsChart = undefined;
    this.testSysloadCharts = {};
    this.totalSysloadCharts = undefined;
  }

  getSystemInfo () {
    if (this.systemInfo) {
      return this.systemInfo;
    }

    let lines = FileSystem.readFileSync(Path.join(this.rootPath, "system.info"), "utf8")
      .split(/[\r\n]+/)
      .map(line => line.trim())
      .filter(line => !!line);
    let data = {};
    lines.forEach(line => {
      let parts = line.split("=");
      data[parts[0]] = Number.parseFloat(parts[1]);
    });
    return this.systemInfo = data;
  }

  getReportName () {
    if (this.reportName) {
      return this.reportName;
    }

    return this.reportName = process.argv.slice(2).find(arg => /^--name=/.test(arg)).slice(7).trim();
  }

  getTestsList () {
    if (this.testsList) {
      return this.testsList;
    }

    let dirlist = FileSystem.readdirSync(Path.join(this.rootPath, "results"))
      .filter(file => FileSystem.lstatSync(Path.join(this.rootPath, "results", file)).isDirectory());
    return this.testsList = dirlist;
  }

  getSubjectsList () {
    if (this.subjectsList) {
      return this.subjectsList;
    }

    let tests = this.getTestsList();
    let subjects;
    tests.forEach(test => {
      let dirlist = FileSystem.readdirSync(Path.join(this.rootPath, "results", test))
        .filter(file => FileSystem.lstatSync(Path.join(this.rootPath, "results", test, file)).isDirectory());
      if (!dirlist.length) {
        throw new Error(`Test "${test}" has no subjects`);
      }
      // Assume first test has correct subjects
      // All other tests must have the exact same subjects
      if (subjects) {
        subjects.forEach(subj => {
          if (!dirlist.includes(subj)) {
            throw new Error(`Test "${test}" has unknown subject "${subj}"`);
          }
        });
        dirlist.forEach(subj => {
          if (!subjects.has(subj)) {
            throw new Error(`Test "${test}" has unknown subject "${subj}"`);
          }
        });
      } else {
        subjects = new Set(dirlist);
      }
    });
    return this.subjectsList = Array.from(subjects);
  }

  getSystemLoadData (test, subject) {
    if (!this.systemLoadData[test]) {
      this.systemLoadData[test] = {};
    }
    if (this.systemLoadData[test][subject]) {
      return this.systemLoadData[test][subject];
    }

    let folder = Path.join(this.rootPath, "results", test, subject);

    let systemLoadData = [];

    let timestamps = FileSystem.readFileSync(Path.join(folder, "timestamps.txt"), "utf8").trim().split(";");
    let timeStarted = Number.parseInt(timestamps[0], 10);

    let lines = FileSystem.readFileSync(Path.join(folder, "system-load.csv"), "utf8")
      .split(/[\r\n]+/)
      .map(line => line.trim())
      .filter(line => !!line);
    lines.slice(7).forEach((line, lineNo) => {
      let parts = line.split(",");
      systemLoadData.push({
        timestamp: timeStarted + (1000 * lineNo),
        totalCpuUsage: Number.parseFloat(parts[0]),
        memoryUsage: Number.parseInt(parts[6], 10) / 1024 / 1024, // This is converting to MiB (i.e. binary, not decimal)
      });
    });

    return this.systemLoadData[test][subject] = systemLoadData;
  }

  getBenchmarkData (test, subject) {
    if (!this.benchmarkData[test]) {
      this.benchmarkData[test] = {};
    }
    if (this.benchmarkData[test][subject]) {
      return this.benchmarkData[test][subject];
    }

    let file = FileSystem.readFileSync(Path.join(this.rootPath, "results", test, subject, "benchmark.log"), "utf8")
      .trim();
    let regexpMatches, requestsPerSecond, totalErrors;

    regexpMatches = /^Requests per second:\s+([0-9.]+)/m.exec(file);
    requestsPerSecond = (regexpMatches && regexpMatches[1]) | 0; // Will be zero if not found

    regexpMatches = /^Non-2xx responses:\s+([0-9]+)/m.exec(file);
    totalErrors = (regexpMatches && regexpMatches[1]) | 0; // Will be zero if not found

    regexpMatches = /^Failed requests:\s+([0-9]+)/m.exec(file);
    totalErrors += (regexpMatches && regexpMatches[1]) | 0; // Will be zero if not found

    return this.benchmarkData[test][subject] = {
      requestsPerSecond: requestsPerSecond,
      totalErrors: totalErrors,
    };
  }

  generateRequestsChart () {
    if (this.requestsChart) {
      return this.requestsChart;
    }

    let tests = this.getTestsList();
    let subjects = this.getSubjectsList();

    let chartColumns = [];
    let chartXTickLabels = [];

    tests.forEach((testName, i) => {
      chartXTickLabels[i] = testName;

      subjects.forEach(testSubject => {
        let chartColumn = chartColumns.find(col => col[0] == testSubject);
        if (!chartColumn) {
          chartColumn = chartColumns[chartColumns.length] = [testSubject];
        }

        chartColumn[i + 1] = this.getBenchmarkData(testName, testSubject).requestsPerSecond;
      });
    });

    this.constructor.sortChartColumns(chartColumns);
    chartColumns.unshift(["Test", ...chartXTickLabels]);

    return this.requestsChart = {
      data: {
        x: "Test",
        columns: chartColumns,
        type: "bar",
        labels: true,
        colors: this.constructor.CHART_COLOURS,
      },
      axis: {
        x: {
          type: "category"
        },
        y: {
          label: {
            text: "Requests per second (mean)",
            position: "outer-middle"
          }
        }
      },
    };
  }

  generateTestSysloadChart (test) {
    if (this.testSysloadCharts[test]) {
      return this.testSysloadCharts[test];
    }

    let cpuChartColumns = [];
    let memoryChartColumns = [];

    this.getSubjectsList().forEach(subject => {
      let relevantSystemLoadData = this.getSystemLoadData(test, subject);

      cpuChartColumns.push([
        subject,
        ...relevantSystemLoadData.map(d => d.totalCpuUsage),
      ]);

      memoryChartColumns.push([
        subject,
        ...relevantSystemLoadData.map(d => d.memoryUsage),
      ]);
    });

    [cpuChartColumns, memoryChartColumns].forEach(c => this.constructor.sortChartColumns(c));

    return this.testSysloadCharts = {
      cpu: {
        data: {
          columns: cpuChartColumns,
          colors: this.constructor.CHART_COLOURS,
        },
        axis: {
          y: {
            min: 0,
            max: 100,
            padding: 0,
            label: {
              text: "Total CPU usage (%)",
              position: "outer-middle",
            },
          },
        },
      },
      memory: {
        data: {
          columns: memoryChartColumns,
          colors: this.constructor.CHART_COLOURS,
        },
        axis: {
          y: {
            min: 0,
            padding: 0,
            label: {
              text: "Memory usage (MiB)",
              position: "outer-middle",
            },
          },
        },
      },
    };
  }

  generateTotalSysloadCharts () {
    if (this.totalSysloadCharts) {
      return this.totalSysloadCharts;
    }

    let cpuChartColumns = [];
    let memoryChartColumns = [];

    let allSysloadData = [];
    this.getTestsList().forEach(test => {
      this.getSubjectsList().forEach(subject => {
        Array.prototype.push.apply(allSysloadData, this.getSystemLoadData(test, subject).map(d => Object.assign(d, {
          subject: subject,
        })));
      });
    });
    allSysloadData.sort((a, b) => {
      let timestampA = a.timestamp;
      let timestampB = b.timestamp;
      return timestampA == timestampB ? 0 : timestampA < timestampB ? -1 : 1;
    });
    allSysloadData.forEach(data => {
      let cpuCol = cpuChartColumns.find(col => col[0] == data.subject);
      if (!cpuCol) {
        cpuCol = cpuChartColumns[cpuChartColumns.length] = [data.subject];
      }

      cpuCol[Math.floor(data.timestamp / 1000) - Math.floor(allSysloadData[0].timestamp / 1000) +
             1] = data.totalCpuUsage;

      let memCol = memoryChartColumns.find(col => col[0] == data.subject);
      if (!memCol) {
        memCol = memoryChartColumns[memoryChartColumns.length] = [data.subject];
      }

      memCol[Math.floor(data.timestamp / 1000) - Math.floor(allSysloadData[0].timestamp / 1000) + 1] = data.memoryUsage;
    });

    [cpuChartColumns, memoryChartColumns].forEach(c => this.constructor.sortChartColumns(c));

    return this.totalSysloadCharts = {
      cpu: {
        data: {
          columns: cpuChartColumns,
          colors: this.constructor.CHART_COLOURS,
        },
        axis: {
          y: {
            min: 0,
            max: 100,
            padding: 0,
          },
        },
      },
      memory: {
        data: {
          columns: memoryChartColumns,
          colors: this.constructor.CHART_COLOURS,
        },
        axis: {
          y: {
            min: 0,
            padding: 0,
          },
        },
      },
    };
  }
}

ReportGenerator.CHART_COLUMN_ORDER = ["Express", "PHP", "HHVM", "OpenResty"];
ReportGenerator.CHART_COLOURS = {
  PHP: "#000",
  HHVM: "#2a5696",
  Express: "#1d7044",
  OpenResty: "#d14424",
};

let report = new ReportGenerator(`${__dirname}/..`);

let json = {
  sysinfo: Object.assign({}, report.getSystemInfo(), {
    name: report.getReportName(),
  }),
  tests: report.getTestsList(),
  errors: (function () {
    let errors = {};
    report.getTestsList().forEach(test => {
      report.getSubjectsList().forEach(subj => {
        if (!errors[test]) {
          errors[test] = {};
        }
        errors[test][subj] = report.getBenchmarkData(test, subj).totalErrors;
      });
    });
    return errors;
  })(),

  requestsChart: report.generateRequestsChart(),
  testSysloadCharts: (function () {
    let charts = {};
    report.getTestsList().forEach(test => {
      charts[test] = report.generateTestSysloadChart(test);
    });
    return charts;
  })(),
  totalCpuChart: report.generateTotalSysloadCharts().cpu,
  totalMemoryChart: report.generateTotalSysloadCharts().memory,
};

// Optimisation
let jsonSerialised = JSON.stringify(json).replace(/null(,|])/g, "$1");
if (!FileSystem.existsSync(__dirname + "/report-template.min.html")) {
  require(__dirname + "/minify-report-template.js");
}
let reportHtml = FileSystem.readFileSync(__dirname + "/report-template.min.html", "utf8")
  .trim()
  .replace("GENERATED_REPORT_DATA_JSON", jsonSerialised);
FileSystem.writeFileSync(__dirname + "/../report.html", reportHtml);
