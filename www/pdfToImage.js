// <reference path="../../typings/bundle.d.ts" />
"use strict";
var exec = require("cordova/exec");

function getPageCount(successCallback, errorCallback, filePath) {
    exec(successCallback, errorCallback, "PDFToImage", "getPageCount", [filePath]);
}
exports.getPageCount = getPageCount;

function convertToImage(successCallback, errorCallback, source, target, shouldUseJpeg, pages, minWidth) {
    exec(successCallback, errorCallback, "PDFToImage", "convertToImage", [source, target, Number(shouldUseJpeg), pages, minWidth]);
}
exports.convertToImage = convertToImage;
