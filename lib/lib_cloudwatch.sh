# lib/lib_cloudwatch.sh
#
# Library of functions to work with Amazon CloudWatch.
#
# Project URL:
#   - https://github.com/AlexGidarakos/aws-cli-scripts
# Authors:
#   - Alexandros Gidarakos <algida79@gmail.com>
#     http://linkedin.com/in/alexandrosgidarakos
# Dependencies:
#   - Bash
#   - GNU coreutils
#   - AWS CLI
#   - jq
# Standards:
#   - Google Shell Style Guide
#     https://google.github.io/styleguide/shellguide.html
#   - Conventional Commits
#     https://www.conventionalcommits.org
# Tested on:
#   - Ubuntu 22.04.5 LTS, Bash 5.1.16, coreutils 8.32, aws-cli 2.26.2, jq 1.6
# Copyright 2025, Alexandros Gidarakos
# SPDX-License-Identifier: MIT

# ShellCheck directives
# shellcheck shell=bash  # because of no shebang in a Bash library

# Source other libraries
source "$(dirname "${BASH_SOURCE[0]}")/lib_common.sh"

########################################################
# Send query to CloudWatch Metrics and save results.
# Globals:
#   None
# Arguments:
#   - Path to JSON query file for input
#   - Start date in UTC ISO 8601 format
#   - End date in UTC ISO 8601 format
#   - Interval, e.g. "2 months", "3 hours", "10 minutes"
# Outputs:
#   - Writes query results in CSV format to STDOUT
#   - Writes error messages to STDERR
# Returns:
#   0 on success, non-zero on error
########################################################
cloudwatch::get_metric_data() {
  local -r query_file="$1"
  local start_date="$2"
  local end_date="$3"
  local interval="$4"
  local output=""
  local return_code=""
  local -a dates=()
  local temp_file=""

  # Check if there are sufficient arguments
  if [[ "$#" -lt 4 ]]; then
    common::log error "Arguments are missing"

    return $ERROR_MISSING_ARGS
  fi

  # Check if query file exists
  if [[ ! -f "$query_file" ]]; then
    common::log error "Query file \"$query_file\" not found"

    return $ERROR_CW_QUERY_FILE_NOT_FOUND
  fi

  # Call split date range function
  output="$(common::split_date_range "$start_date" "$end_date" "$interval")"
  return_code=$?

  # Check if function returned error
  if [[ $return_code -ne 0 ]]; then
    return $return_code
  fi

  # Convert split date range output back to array
  IFS=" " read -r -a dates < <(echo "$output")

  # Output CSV header to STDOUT
  echo '"Date","Successful connections"'

  # Create temporary JSON file
  temp_file="$(mktemp /tmp/results.json.XXXXXX)"

  # Loop over the dates array and send the CloudWatch Metrics query
  for ((i=0; i<${#dates[@]}-1; i++)); do
    start_date="${dates[i]}"
    end_date="${dates[i+1]}"
    aws cloudwatch get-metric-data \
      --metric-data-queries "file://${query_file}" \
      --start-time "$start_date" \
      --end-time "$end_date" \
      > "$temp_file"
    return_code=$?

    # Check if query returned error
    if [[ $return_code -ne 0 ]]; then
      common::log error "CloudWatch Metrics query failed"

      return $ERROR_CW_QUERY_FAILED
    fi

    # Convert results from JSON to CSV and output to STDOUT
    jq -r '.MetricDataResults[]
      | .Timestamps as $ts
      |.Values as $vs
      | [$ts, $vs]
      | transpose[]
      | @csv' "$temp_file" \
      | sort
    return_code=$?

    # Check if results conversion returned error
    if [[ $return_code -ne 0 ]]; then
      common::log error "Conversion from JSON to CSV failed"

      return $ERROR_JSON2CSV_FAILED
    fi
  done

  # Cleanup: delete temporary JSON file
  rm "$temp_file"
}
