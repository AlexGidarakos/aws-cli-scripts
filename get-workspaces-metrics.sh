#!/bin/bash
#
# get-workspaces-metrics.sh
# Query CloudWatch for WorkSpaces-related Metrics.
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
# Arguments:
#   - Path to JSON query file for input (optional)
#   - Path to CSV results file for output (optional)
#   - Start date in UTC ISO 8601 format
#   - End date in UTC ISO 8601 format
#   - Interval, e.g. "2 months", "3 hours", "10 minutes" (optional)
# Outputs:
#   - Writes query results in CSV format to STDOUT
#   - Writes error messages to STDERR
# Returns:
#   0 on success, non-zero on error
# Copyright 2025, Alexandros Gidarakos
# SPDX-License-Identifier: MIT

# Source other libraries
source "$(dirname "${BASH_SOURCE[0]}")/lib/lib_cloudwatch.sh"

# Initialise option values to avoid contamination from environment
query_file=""
results_file=""
start_date=""
end_date=""
interval="1 month"

# Function to display usage
usage() {
  echo "Usage: $0 [-q|--query-file FILE] [-r|--results-file FILE] -s|--start-date DATE -e|--end-date DATE [-i|--interval EXPR]"
}

# Parse arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    -h|--help)
      usage
      exit
      ;;
    -q|--query-file)
      if [[ "$2" ]]; then
        query_file="$2"
        shift 2
      else
        common::log error "Option \"-q|--query-file\" must be followed by a value"
        exit "$ERROR_MISSING_ARG_VALUE"
      fi
      ;;
    -r|--results-file)
      if [[ "$2" ]]; then
        results_file="$2"
        shift 2
      else
        common::log error "Option \"-r|--results-file\" must be followed by a value"
        exit "$ERROR_MISSING_ARG_VALUE"
      fi
      ;;
    -s|--start-date)
      if [[ "$2" ]]; then
        start_date="$2"
        shift 2
      else
        common::log error "Option \"-s|--start-date\" must be followed by a value"
        exit "$ERROR_MISSING_ARG_VALUE"
      fi
      ;;
    -e|--end-date)
      if [[ "$2" ]]; then
        end_date="$2"
        shift 2
      else
        common::log error "Option \"-e|--end-date\" must be followed by a value"
        exit "$ERROR_MISSING_ARG_VALUE"
      fi
      ;;
    -i|--interval)
      if [[ "$2" ]]; then
        interval="$2"
        shift 2
      else
        common::log error "Option \"-i|--interval\" must be followed by a value"
        exit "$ERROR_MISSING_ARG_VALUE"
      fi
      ;;
    *)
      common::log error "Invalid option: $1"
      exit "$ERROR_INVALID_OPTION"
  esac
done

# Check mandatory arguments
if [[ -z "$start_date" ]] || [[ -z "$end_date" ]]; then
  common::log error "Arguments are missing"
  exit "$ERROR_MISSING_ARGS"
fi

# Create file descriptor for script output
if [[ "$results_file" ]]; then
  exec 3> "$results_file"
else
  exec 3>&1
fi

# If JSON query file not provided, create a temporary with default query
if [[ ! "$query_file" ]]; then
  query_file="$(mktemp /tmp/query.json.XXXXXX)"
  trap 'rm -f "$query_file"' EXIT
  cat > "$query_file" << EOF
[
  {
    "Id": "m1",
    "Expression": "SUM(SEARCH('{AWS/WorkSpaces,RunningMode} MetricName=ConnectionSuccess', 'Sum', 3600))",
    "Label": "Successful connections"
  }
]
EOF
fi

# Call CloudWatch get metric data function
cloudwatch::get_metric_data "$query_file" "$start_date" "$end_date" "$interval" >&3
