"use strict";

const fs = require("fs");
const zc = require("zcompile");

fs.writeFileSync(__dirname + "/report-template.min.html", fs.readFileSync(__dirname + "/report-template.html"));

zc({
  source: __dirname,
  destination: __dirname,

  files: ["report-template.min.html"],

  minifySelectors: false,
  minifyJS: {
    harmony: true,
  },
  minifyHTML: {
    minifyInlineJS: true,
    minifyInlineCSS: true,
  },
});

fs.writeFileSync(
  __dirname + "/report-template.min.html",
  fs.readFileSync(__dirname + "/report-template.min.html", "utf8")
    .replace(/<script src=node_modules\/(.*?)><\/script>/g, (_, file) => {
      return "<script>" + fs.readFileSync(__dirname + "/node_modules/" + file, "utf8") + "</script>";
    }));
