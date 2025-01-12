#!/usr/bin/env bash

set -e

dir=$(cd "$(dirname "${BASH_SOURCE[0]}")"; pwd)

TEST_MORE_PATH=$dir/../test-more-bash
BASHLIB="`
    find $TEST_MORE_PATH -type d |
    grep -E '/(bin|lib)$' |
    xargs -n1 printf "%s:"`"
PATH=$BASHLIB$PATH

source bash+ :std
use Test::More
plan tests 12

source _common

client_output=''
mock-client() {
    client_output+="client_call $@"$'\n'
}

nl=$'\n'
client_call=(mock-client "${client_call[@]}")
logfile1=$dir/data/01-os-autoinst.txt.1
logfile2=$dir/data/01-os-autoinst.txt.2

rc=0
comment_on_job 123 Label || rc=$?
is "$rc" 0 'successful comment_on_job'
is "$client_output" "client_call -X POST jobs/123/comments text=Label$nl" 'comment_on_job works'

rc=0
search_log 123 'foo.*bar' "$logfile1" || rc=$?
is "$rc" 0 'successful search_log'

rc=0
search_log 123 'foo.*bar' "$logfile2" || rc=$?
is "$rc" 1 'failing search_log'

rc=0
output=$(search_log 123 'foo [z-a]' "$logfile2" 2>&1) || rc=$?
is "$rc" 2 'search_log with invalid pattern'
like "$output" 'range out of order in character class' 'correct error message'

rc=0
client_output=''
out=$logfile1
label_on_issue 123 'foo.*bar' Label 1 softfailed || rc=$?
expected="client_call -X POST jobs/123/comments text=label:force_result:softfailed:Label
client_call -X POST jobs/123/restart
"
is "$rc" 0 'successful label_on_issue'
is "$client_output" "$expected" 'label_on_issue with restart and force_result'

rc=0
client_output=''
out=$logfile1
label_on_issue 123 'foo.*bar' Label || rc=$?
expected="client_call -X POST jobs/123/comments text=Label
"
is "$rc" 0 'successful label_on_issue'
is "$client_output" "$expected" 'label_on_issue with restart and force_result'

rc=0
client_output=''
out=$logfile1
label_on_issue 123 'foo bar' Label || rc=$?
is "$rc" 1 'label_on_issue did not find search term'
is "$client_output" "" 'label_on_issue with restart and force_result'

