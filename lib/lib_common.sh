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
# Standards:
#   - Google Shell Style Guide
#     https://google.github.io/styleguide/shellguide.html
#   - Conventional Commits
#     https://www.conventionalcommits.org
# Tested on:
#   - Ubuntu 22.04.5 LTS, Bash 5.1.16
# Copyright 2025, Alexandros Gidarakos
# SPDX-License-Identifier: MIT
# shellcheck shell=bash

# Error codes
readonly ERROR_MISSING_ARGS=1
readonly ERROR_INVALID_START=2
readonly ERROR_INVALID_END=3
readonly ERROR_INVALID_INTERVAL=4
readonly ERROR_START_AFTER_END=5

#####################################################
# Split a date range into smaller chunks.
# Globals:
#   None
# Arguments:
#   Start date, in UTC ISO 8601 format
#   End date, in UTC ISO 8601 format
#   Interval, e.g. "2 months" or "3 hours"
# Outputs:
#   Writes an array of UTC ISO 8601 dates to STDOUT
#   Writes error messages to STDERR
# Returns:
#   0 on success, non-zero on error
#####################################################
function shared::split_date_range() {
  local start_date="$1"
  local end_date="$2"
  local interval="$3"
  local -a dates=()
  local current_date=""

  if [[ "$#" -ne 3 ]]; then
    echo "Error: missing arguments" >&2
    echo "Usage: ${FUNCNAME[0]} <START_DATE> <END_DATE> <INTERVAL>" >&2
    echo "Examples:" >&2
    echo "  ${FUNCNAME[0]} 2025-03-02T00:00:00Z 2025-05-09T00:00:00Z \"10 days\"" >&2
    echo "  ${FUNCNAME[0]} 2023-01-01 2025-01-01 \"3 months\"" >&2

    return $ERROR_MISSING_ARGS
  fi

  # Normalise short form (e.g. 2024-01-01) start date and check if valid date
  if ! start_date=$(date -u -d "$start_date" +"%Y-%m-%dT%H:%M:%SZ"); then
    echo "Error: \"$1\" not a valid date" >&2

    return $ERROR_INVALID_START
  fi

  # Normalise short form (e.g. 2024-01-01) end date and check if valid date
  if ! end_date=$(date -u -d "$end_date" +"%Y-%m-%dT%H:%M:%SZ"); then
    echo "Error: \"$2\" not a valid date" >&2

    return $ERROR_INVALID_END
  fi

  # Check if interval is a valid expression
  if ! date -u -d "$start_date + $interval"  > /dev/null; then
    echo "Error: \"$3\" not a valid expression" >&2

    return $ERROR_INVALID_INTERVAL
  fi

  if [[ "$start_date" > "$end_date" ]]; then
    echo "Error: start date \"$1\" after end date \"$2\"" >&2

    return $ERROR_START_AFTER_END
  fi

  current_date="$start_date"

  while [[ "$current_date" < "$end_date" ]]; do
    dates+=("$current_date")
    current_date=$(date -u -d "$current_date + $interval" +"%Y-%m-%dT%H:%M:%SZ")
  done

  dates+=("$end_date")
  echo "${dates[@]}"
}
