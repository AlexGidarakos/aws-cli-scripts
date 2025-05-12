# lib/lib_error_codes.sh
#
# Library of error codes for the rest of the project.
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

# ShellCheck directives
# shellcheck shell=bash  # because of no shebang in a Bash library
# shellcheck disable=SC2034  # because error codes are only used externally

# Error codes
readonly ERROR_MISSING_ARGS=1
readonly ERROR_INVALID_LOG_LEVEL=2
readonly ERROR_INVALID_START=3
readonly ERROR_INVALID_END=4
readonly ERROR_START_AFTER_END=5
readonly ERROR_START_EQUALS_END=6
readonly ERROR_INVALID_INTERVAL=7
readonly ERROR_CW_QUERY_FILE_NOT_FOUND=8
readonly ERROR_EMPTY_CSV_FAILED=9
readonly ERROR_CW_QUERY_FAILED=10
readonly ERROR_JSON2CSV_FAILED=11
