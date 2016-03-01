// <reference path="../../typings/bundle.d.ts" />

"use strict";

import * as exec from "cordova/exec";

export function getPageCount(successCallback: (pageCount: number) => void, errorCallback: (error: string) => void, filePath: string) {
    exec(successCallback, errorCallback, "PDFToImage", "getPageCount", [filePath]);
}

export function convertToImage(successCallback: (urls: string[]) => void, errorCallback: (error: string) => void, source: string, target?: string, shouldUseJpeg?: boolean, pages?: number[]) {
    exec(successCallback, errorCallback, "PDFToImage", "convertToImage", [source, target, Number(shouldUseJpeg), pages]);
}
