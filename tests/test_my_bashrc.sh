#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BASHRC="$ROOT_DIR/my_bashrc"

fail() {
    echo "FAIL: $*" >&2
    exit 1
}

assert_eq() {
    local expected="$1"
    local actual="$2"
    local message="$3"
    [[ "$actual" == "$expected" ]] || fail "$message: expected '$expected', got '$actual'"
}

with_temp_env() {
    local body="$1"
    local tmpdir
    tmpdir="$(mktemp -d)"
    mkdir -p "$tmpdir/bin" "$tmpdir/home/.kube"

    cat > "$tmpdir/bin/kubectl" <<'STUB'
#!/usr/bin/env bash
case "$1 $2" in
    "cluster-info") exit 1 ;;
    "config get-contexts") exit 0 ;;
    *) exit 1 ;;
esac
STUB
    chmod +x "$tmpdir/bin/kubectl"

    (
        export HOME="$tmpdir/home"
        export PATH="$tmpdir/bin:/usr/bin:/bin"
        export TEST_TMPDIR="$tmpdir"
        export BASHRC
        cd "$tmpdir"
        bash --noprofile --norc -c "$body"
    )
    local status=$?
    rm -rf "$tmpdir"
    return "$status"
}

test_source_is_quiet_and_preserves_directory() {
    with_temp_env '
        before_pwd=$PWD
        output="$(source "$BASHRC" 2>&1)"
        after_pwd=$PWD
        [[ -z "$output" ]] || { printf "%s\n" "$output"; exit 1; }
        [[ "$after_pwd" == "$before_pwd" ]] || exit 2
    ' || fail "sourcing my_bashrc should be quiet and should not cd"
}

test_ek_without_configs_has_no_basename_error() {
    with_temp_env '
        source "$BASHRC" >/dev/null 2>&1
        output="$(ek 2>&1)"
        [[ "$output" == *"Current kubeconfig:"* ]] || exit 1
        [[ "$output" == *"Available configs:"* ]] || exit 2
        [[ "$output" != *"basename:"* ]] || { printf "%s\n" "$output"; exit 3; }
    ' || fail "ek should handle an empty ~/.kube without basename errors"
}

test_reposync_does_not_rewrite_source_files() {
    with_temp_env '
        cat > "$TEST_TMPDIR/bin/dos2unix" <<STUB
#!/usr/bin/env bash
echo dos2unix-called >> "$TEST_TMPDIR/dos2unix.log"
exit 0
STUB
        chmod +x "$TEST_TMPDIR/bin/dos2unix"
        cat > "$TEST_TMPDIR/bin/rsync" <<STUB
#!/usr/bin/env bash
exit 0
STUB
        chmod +x "$TEST_TMPDIR/bin/rsync"

        mkdir -p "$TEST_TMPDIR/source"
        printf "hello\r\n" > "$TEST_TMPDIR/source/file.txt"

        source "$BASHRC" >/dev/null 2>&1
        LOCAL_REPO="$TEST_TMPDIR/source"
        HOST="example"
        REMOTE_REPO="/remote"
        SYNC_EXCLUDES=(".git")

        reposync >/dev/null
        [[ ! -e "$TEST_TMPDIR/dos2unix.log" ]] || exit 1
    ' || fail "reposync should not run dos2unix against source files"
}

test_source_is_quiet_and_preserves_directory
test_ek_without_configs_has_no_basename_error
test_reposync_does_not_rewrite_source_files

echo "All my_bashrc tests passed"
