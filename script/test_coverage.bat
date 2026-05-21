@echo off
setlocal

echo Cleaning old coverage...
if exist coverage rmdir /s /q coverage
mkdir coverage

echo Running unit/widget tests...
call flutter test --coverage

move coverage\lcov.info coverage\unit_lcov.info

echo Running integration tests...
call flutter test integration_test --flavor dev --coverage

move coverage\lcov.info coverage\integration_lcov.info

echo Merging coverage reports...

call dart run tool/merge_coverage.dart

echo.
echo Combined coverage generated:
echo coverage\lcov.info

endlocal