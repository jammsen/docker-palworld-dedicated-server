// Log output styled to match includes/colors.sh so companion lines blend into docker logs
const BASE = "\x1b[97m";
const CLEAN = "\x1b[0m";
const ERROR = "\x1b[91m";
const INFO = "\x1b[38;5;68m";
const SUCCESS = "\x1b[92m";
const WARNING = "\x1b[93m";

let debugEnabled = false;

export function setDebug(enabled: boolean): void {
  debugEnabled = enabled;
}

function emit(color: string, message: string): void {
  console.log(`${color}${message}${CLEAN}`);
}

export const log = {
  base: (message: string) => emit(BASE, message),
  info: (message: string) => emit(INFO, message),
  success: (message: string) => emit(SUCCESS, message),
  warn: (message: string) => emit(WARNING, message),
  error: (message: string) => emit(ERROR, message),
  debug: (message: string) => {
    if (debugEnabled) emit(WARNING, `Debug: ${message}`);
  },
};
