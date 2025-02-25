#!/usr/bin/env bats
#shellcheck disable

load 'test_helper/bats-support/load'
load 'test_helper/bats-file/load'
load 'test_helper/bats-assert/load'

######## SETUP TESTS ########
ROOTDIR="$(git rev-parse --show-toplevel)"
ALERTS="${ROOTDIR}/utilities/alerts.bash"

if test -f "${ALERTS}" >&2; then
  source "${ALERTS}"
else
  echo "Sourcefile not found: ${ALERTS}" >&2
  printf "Can not run tests.\n" >&2
  exit 1
fi

setup() {

  TESTDIR="$(temp_make)"
  curPath="${PWD}"

  BATSLIB_FILE_PATH_REM="#${TEST_TEMP_DIR}"
  BATSLIB_FILE_PATH_ADD='<temp>'

  pushd "${TESTDIR}" >&2

  ######## DEFAUL FLAGS ########
  LOGFILE="${TESTDIR}/logs/log.txt"
  QUIET=false
  LOGLEVEL=ERROR
  VERBOSE=false
  FORCE=false
  DRYRUN=false
}

teardown() {
  popd >&2
  temp_del "${TESTDIR}"
}


######## RUN TESTS ########
@test "Sanity..." {
  run true

  assert_success
  assert_output ""
}

@test "_alert_: success" {
  run success "testing"
  assert_output --regexp "\[success\] testing"
}

@test "_alert_: quiet" {
  QUIET=true
  run notice "testing"
  assert_success
  refute_output --partial "testing"
}

@test "_alert_: verbose" {
  run verbose "testing"
  refute_output --regexp "\[  debug\] testing"

  VERBOSE=true
  run verbose "testing"
  assert_output --regexp "\[  debug\] testing"
}

@test "_alert_: warning" {
  run warning "testing"
  assert_output --regexp "\[warning\] testing"
}

@test "_alert_: notice" {
  run notice "testing"
  assert_output --regexp "\[ notice\] testing"
}

@test "_alert_: notice: with LINE" {
  run notice "testing" "$LINENO"
  assert_output --regexp ".*\[ notice\] testing \(line: [0-9]{1,3}\)"
}

@test "_alert_: refute debug" {
  run debug "testing"
  refute_output --partial "[  debug] testing"
}

@test "_alert_: assert debug" {
  VERBOSE=true
  run debug "testing"
  assert_output --partial "[  debug] testing"
}

@test "_alert_: header" {
  run header "testing"
  assert_output --regexp "\[ header\] == testing =="
}

@test "_alert_: info" {
  run info "testing"
  assert_output --regexp "[0-9]+:[0-9]+:[0-9]+ (AM|PM) \[   info\] testing"
}

@test "_alert_: fatal: with LINE" {
  run fatal "testing" "$LINENO"
  assert_line --index 0 --regexp ".*\[  fatal\] testing \(line: [0-9]{1,3}\) \( run:.*\)"
}

@test "_alert_: error" {
  run error "testing"
  assert_output --regexp  ".*\[  error\] testing \( run:.*\)"
}

@test "_alert_: input" {
  run input "testing"
  assert_output --partial "[  input] testing"
}

@test "_alert_: logging FATAL" {
  LOGLEVEL=FATAL
  run error "testing error"
  run error "testing error 2"
  run warning "testing warning"
  run notice "testing notice"
  run info "testing info"
  run debug "testing debug"
  run fatal "testing fatal"

  assert_file_exist "${LOGFILE}"
  run cat "${LOGFILE}"
  assert_line --index 0 --regexp "[0-9]+:[0-9]+:[0-9]+ \[  fatal\] \[.*\] testing fatal \("
  assert_line --index 1 ""
  assert_line --index 2 ""
  assert_line --index 3 ""
  assert_line --index 4 ""
  assert_line --index 5 ""
}

@test "_alert_: logging ERROR" {
  LOGLEVEL=ERROR
  run error "testing error"
  run error "testing error 2"
  run warning "testing warning"
  run notice "testing notice"
  run info "testing info"
  run debug "testing debug"

  assert_file_exist "${LOGFILE}"
  run cat "${LOGFILE}"
  assert_line --index 0 --regexp "[0-9]+:[0-9]+:[0-9]+ \[  error\] \[.*\] testing error"
  assert_line --index 1 --regexp "[0-9]+:[0-9]+:[0-9]+ \[  error\] \[.*\] testing error 2"
  assert_line --index 2 ""
  assert_line --index 3 ""
  assert_line --index 4 ""
  assert_line --index 5 ""
}

@test "_alert_: logging WARN" {
  LOGLEVEL=WARN
  run error "testing error"
  run error "testing error 2"
  run warning "testing warning"
  run notice "testing notice"
  run info "testing info"
  run debug "testing debug"

  assert_file_exist "${LOGFILE}"
  run cat "${LOGFILE}"
  assert_line --index 0 --regexp "[0-9]+:[0-9]+:[0-9]+ \[  error\] \[.*\] testing error"
  assert_line --index 1 --regexp "[0-9]+:[0-9]+:[0-9]+ \[  error\] \[.*\] testing error 2"
  assert_line --index 2 --regexp "[0-9]+:[0-9]+:[0-9]+ \[warning\] \[.*\] testing warning"
  assert_line --index 3 ""
  assert_line --index 4 ""
  assert_line --index 5 ""
}

@test "_alert_: logging INFO" {
  LOGLEVEL=INFO
  run error "testing error"
  run error "testing error 2"
  run warning "testing warning"
  run notice "testing notice"
  run info "testing info"
  run debug "testing debug"

  assert_file_exist "${LOGFILE}"
  run cat "${LOGFILE}"
  assert_line --index 0 --regexp "[0-9]+:[0-9]+:[0-9]+ \[  error\] \[.*\] testing error"
  assert_line --index 1 --regexp "[0-9]+:[0-9]+:[0-9]+ \[  error\] \[.*\] testing error 2"
  assert_line --index 2 --regexp "[0-9]+:[0-9]+:[0-9]+ \[warning\] \[.*\] testing warning"
  assert_line --index 3 --regexp "[0-9]+:[0-9]+:[0-9]+ \[ notice\] \[.*\] testing notice"
  assert_line --index 4 --regexp "[0-9]+:[0-9]+:[0-9]+ \[   info\] \[.*\] testing info"
  assert_line --index 5 ""
}

@test "_alert_: logging DEBUG" {
  LOGLEVEL=DEBUG
  run error "testing error"
  run error "testing error 2"
  run warning "testing warning"
  run notice "testing notice"
  run info "testing info"
  run debug "testing debug"

  assert_file_exist "${LOGFILE}"
  run cat "${LOGFILE}"
  assert_line --index 0 --regexp "[0-9]+:[0-9]+:[0-9]+ \[  error\] \[.*\] testing error"
  assert_line --index 1 --regexp "[0-9]+:[0-9]+:[0-9]+ \[  error\] \[.*\] testing error 2"
  assert_line --index 2 --regexp "[0-9]+:[0-9]+:[0-9]+ \[warning\] \[.*\] testing warning"
  assert_line --index 3 --regexp "[0-9]+:[0-9]+:[0-9]+ \[ notice\] \[.*\] testing notice"
  assert_line --index 4 --regexp "[0-9]+:[0-9]+:[0-9]+ \[   info\] \[.*\] testing info"
  assert_line --index 5 --regexp "[0-9]+:[0-9]+:[0-9]+ \[  debug\] \[.*\] testing debug"
}

@test "_alert_: logging OFF" {
  LOGLEVEL=OFF
  run error "testing error"
  run error "testing error 2"
  run warning "testing warning"
  run notice "testing notice"
  run info "testing info"
  run debug "testing debug"

  assert_file_not_exist "${LOGFILE}"
}
