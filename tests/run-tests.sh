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

while getopts "v" o "$@"; do
    case $o in
        v)  verbose=true ;;
        *)  echo "Usage: run-tests.sh [-v] [testset...]"
            echo "   -v       Allow Vim to output to screen (Neovim runs headless anyway)."
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

echo "Testing vim"
run_tests vim --not-a-term

# to be removed once a working neovim is available
if [ -n "$TRAVIS" ]; then
    echo "Neovim skipped on travis"
    exit $exit_code
fi

if command -v nvim >/dev/null 2>&1; then
    echo "Testing nvim"
    run_tests nvim --headless
else
    echo "Neovim not available"
fi

exit $exit_code

