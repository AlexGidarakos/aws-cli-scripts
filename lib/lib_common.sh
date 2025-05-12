# lib/lib_common.sh
#
# Library of utility functions for the rest of the project.
#
# Project URL:
#   - https://github.com/AlexGidarakos/aws-cli-scripts
# Authors:
#   - Alexandros Gidarakos <algida79@gmail.com>
#     http://linkedin.com/in/alexandrosgidarakos
# Dependencies:
#   - Bash
#   - GNU coreutils
# Standards:
#   - Google Shell Style Guide
#     https://google.github.io/styleguide/shellguide.html
#   - Conventional Commits
#     https://www.conventionalcommits.org
# Tested on:
#   - Ubuntu 22.04.5 LTS, Bash 5.1.16, coreutils 8.32
# Copyright 2025, Alexandros Gidarakos
# SPDX-License-Identifier: MIT

# ShellCheck directives
# shellcheck shell=bash  # because of no shebang in a Bash library

# Error codes
readonly ERROR_MISSING_ARGS=1
readonly ERROR_INVALID_LOG_LEVEL=2
readonly ERROR_INVALID_START=3
readonly ERROR_INVALID_END=4
readonly ERROR_INVALID_INTERVAL=5
readonly ERROR_START_AFTER_END=6

#######################################################
# A simple console logging function.
# Globals:
#   None
# Arguments:
#   - Log level, one of debug, info, warn, error, fatal
#   - Message
# Outputs:
#   - Writes a formatted log message to STDOUT
#   - Writes error messages to STDERR
# Returns:
#   0 on success, non-zero on error
#######################################################
common::log() {
  local -r LOG_LEVEL="${1^^}"
  local -r CALLER="${FUNCNAME[1]}"
  local -r LOG_MESSAGE="$(date +"%Y-%m-%dT%H:%M:%S.%3N%:z") [$LOG_LEVEL] [${CALLER:-${FUNCNAME[0]}}] $2"

  # Check if there are sufficient arguments
  if [[ "$#" -lt 2 ]]; then
    echo "$(date +"%Y-%m-%dT%H:%M:%S.%3N%:z") [ERROR] [${CALLER:-${FUNCNAME[0]}}] Arguments are missing" >&2

    return $ERROR_MISSING_ARGS
  fi

  # Print the formatted log message to the appropriate output stream
  # Also check if the log level argument is valid
  case "$1" in
    debug | info | warn) echo "$LOG_MESSAGE";;
    error | fatal) echo "$LOG_MESSAGE" >&2;;
    *) echo "$(date +"%Y-%m-%dT%H:%M:%S.%3N%:z") [ERROR] [${CALLER:-${FUNCNAME[0]}}] \"$1\" is not a valid log level" >&2; return $ERROR_INVALID_LOG_LEVEL;;
  esac
}

########################################################
# Split a date range into smaller chunks.
# Globals:
#   None
# Arguments:
#   - Start date in UTC ISO 8601 format
#   - End date in UTC ISO 8601 format
#   - Interval, e.g. "2 months", "3 hours", "10 minutes"
# Outputs:
#   - Writes an array of UTC ISO 8601 dates to STDOUT
#   - Writes error messages to STDERR
# Returns:
#   0 on success, non-zero on error
########################################################
common::split_date_range() {
  local start_date="$1"
  local end_date="$2"
  local interval="$3"
  local -a dates=()
  local current_date=""

  # Check if there are sufficient arguments
  if [[ "$#" -lt 3 ]]; then
    common::log error "Arguments are missing"

    return $ERROR_MISSING_ARGS
  fi

  # Normalise short form (e.g. 2024-01-01) start date and check if valid date
  if ! start_date="$(date -u -d "$start_date" +"%Y-%m-%dT%H:%M:%SZ" 2> /dev/null)"; then
    common::log error "\"$1\" is not a valid date"

    return $ERROR_INVALID_START
  fi

  # Normalise short form (e.g. 2024-01-01) end date and check if valid date
  if ! end_date=$(date -u -d "$end_date" +"%Y-%m-%dT%H:%M:%SZ" 2> /dev/null); then
    common::log error "\"$2\" is not a valid date"

    return $ERROR_INVALID_END
  fi

  # Check if interval is a valid expression
  if ! date -u -d "$start_date + $interval" &> /dev/null; then
    common::log error "\"$3\" is not a valid expression"

    return $ERROR_INVALID_INTERVAL
  fi

  # Check if start date is chronologically before end date
  if [[ "$start_date" > "$end_date" ]]; then
    common::log error "Start date \"$1\" is after end date \"$2\""

    return $ERROR_START_AFTER_END
  fi

  # Initialise current date before the upcoming loop
  current_date="$start_date"

  # Loop to build the array of dates
  while [[ "$current_date" < "$end_date" ]]; do
    dates+=("$current_date")
    current_date="$(date -u -d "$current_date + $interval" +"%Y-%m-%dT%H:%M:%SZ")"
  done

  # Add the last date to the array and print it to STDOUT
  dates+=("$end_date")
  echo "${dates[@]}"
}
