#!/bin/bash
#
# FILE: run-tests.sh
#
# ABSTRACT: Runs editorconfig test
#

script_dir="$(cd "$(dirname "$0")" && pwd)"

cd "$script_dir" || exit 1

if [ -d "$HOME/local/neovim/bin" ]; then
    PATH="$PATH:$HOME/local/neovim/bin"
fi

VIM_TST_EXE="${VIM_TST_EXE:-vim}"
NEOVIM_TST_EXE="${NEOVIM_TST_EXE:-nvim}"

while getopts "v1" o "$@"; do
    case $o in
        v)  verbose=true ;;
        1)  fail_fast=true ;;
        *)  echo "Usage: run-tests.sh [-v] [testset...]"
            echo "   -v       Allow Vim to output to screen (Neovim runs headless anyway)."
            echo "   -1       Fail and exit on first failed testset."
            echo "   testset: Names of the testsets to execute. This it a substring match."
            echo "            E.g. 'core' will test all editorconfig-core tests."
            echo "            Unknown names are silently ignored."
            echo ""
            echo "Testsets:"
            ls testset-*.vim | sed 's/^testset-/  - /;s/\.vim$//'
            exit 1 ;;
    esac
done
shift $((OPTIND-1))

testsets=( "$@" )

exit_code=0

export log_dir="$script_dir/logs"
mkdir -p "$log_dir"
rm -f "$log_dir"/*

run_single_test()
{
    testfile="$1"
    shift

    export TEST_RESULT_FILE="$log_dir/$(basename "$testfile" ".vim").log"
    rm -f "$TEST_RESULT_FILE"

    if [ -n "$verbose" ]; then
        "$@" --clean -u test_vimrc --noplugin -N -c "source $testfile" #>/dev/null
    else
        "$@" --clean -u test_vimrc --noplugin -N -c "source $testfile" >/dev/null
    fi
    if [ $? -ne 0 ]; then
        exit_code=1
    fi
    cat "$TEST_RESULT_FILE"
    if [ $exit_code -ne 0 ] && [ -n "$fail_fast" ]; then
        exit $exit_code
    fi
}

run_tests()
{
    for fn in testset-*.vim; do
        if [ ${#testsets[@]} -ne 0 ]; then
            found=
            for ts in "${testsets[@]}"; do
                if [[ $fn = *${ts}*.vim ]]; then
                    found="true"
                    break
                fi
            done
            if [ -z "$found" ]; then
                continue
            fi
        fi
        run_single_test "$fn" "$@"
    done
}

if command -v "$VIM_TST_EXE" >/dev/null 2>&1; then
    echo "Testing vim ($(command -v "$VIM_TST_EXE"))"
    run_tests "$VIM_TST_EXE" --not-a-term
else
    echo "Vim not available"
fi

# don't run nvim in verbose mode
if [ -z "$verbose" ]; then
    if command -v "$NEOVIM_TST_EXE" >/dev/null 2>&1; then
        echo "Testing nvim ($(command -v "$NEOVIM_TST_EXE"))"
        run_tests "$NEOVIM_TST_EXE" --headless
    else
        echo "Neovim not available"
    fi
fi

exit $exit_code

