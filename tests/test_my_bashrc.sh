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

test_central_venv_helpers_create_activate_and_list() {
    with_temp_env '
        cat > "$TEST_TMPDIR/bin/python3" <<STUB
#!/usr/bin/env bash
if [[ "\$1" == "--version" ]]; then
    echo "Python 3.12.0"
    exit 0
fi
if [[ "\$1" == "-m" && "\$2" == "venv" ]]; then
    target="\$3"
    mkdir -p "\$target/bin"
    cat > "\$target/bin/activate" <<ACTIVATE
VIRTUAL_ENV="\$target"
export VIRTUAL_ENV
deactivate() {
    unset VIRTUAL_ENV
    unset CENTRAL_VENV_AUTO_ACTIVATED
    unset -f deactivate
}
ACTIVATE
    exit 0
fi
exit 1
STUB
        chmod +x "$TEST_TMPDIR/bin/python3"

        mkdir -p "$HOME/project-one"
        source "$BASHRC" >/dev/null 2>&1

        cd "$HOME/project-one"
        create_central_venv >/dev/null
        [[ "$VIRTUAL_ENV" == "$HOME/.venvs/project-one" ]] || exit 1
        [[ "$(central_venv_path project-one)" == "$HOME/.venvs/project-one" ]] || exit 2
        [[ "$(list_central_venvs)" == "project-one" ]] || exit 3

        deactivate
        activate_central_venv project-one >/dev/null
        [[ "$VIRTUAL_ENV" == "$HOME/.venvs/project-one" ]] || exit 4
    ' || fail "central venv helpers should create, activate, and list project venvs"
}

test_auto_activate_central_venv_switches_and_deactivates() {
    with_temp_env '
        make_fake_venv() {
            local target="$1"
            mkdir -p "$target/bin"
            cat > "$target/bin/activate" <<ACTIVATE
VIRTUAL_ENV="$target"
export VIRTUAL_ENV
deactivate() {
    unset VIRTUAL_ENV
    unset CENTRAL_VENV_AUTO_ACTIVATED
    unset -f deactivate
}
ACTIVATE
        }

        mkdir -p "$HOME/project-a" "$HOME/project-b"
        make_fake_venv "$HOME/.venvs/project-a"
        make_fake_venv "$HOME/.venvs/project-b"

        source "$BASHRC" >/dev/null 2>&1
        [[ "$PROMPT_COMMAND" == *"auto_activate_central_venv"* ]] || exit 1

        cd "$HOME/project-a"
        auto_activate_central_venv
        [[ "$VIRTUAL_ENV" == "$HOME/.venvs/project-a" ]] || exit 2
        [[ "$CENTRAL_VENV_AUTO_ACTIVATED" == "1" ]] || exit 3

        cd "$HOME/project-b"
        auto_activate_central_venv
        [[ "$VIRTUAL_ENV" == "$HOME/.venvs/project-b" ]] || exit 4

        cd "$HOME"
        auto_activate_central_venv
        [[ -z "${VIRTUAL_ENV:-}" ]] || exit 5
        [[ -z "${CENTRAL_VENV_AUTO_ACTIVATED:-}" ]] || exit 6
    ' || fail "auto activation should switch project venvs and deactivate outside projects"
}

test_auto_activate_central_venv_preserves_manual_venv() {
    with_temp_env '
        make_fake_venv() {
            local target="$1"
            mkdir -p "$target/bin"
            cat > "$target/bin/activate" <<ACTIVATE
VIRTUAL_ENV="$target"
export VIRTUAL_ENV
deactivate() {
    unset VIRTUAL_ENV
    unset -f deactivate
}
ACTIVATE
        }

        mkdir -p "$HOME/project-a"
        make_fake_venv "$HOME/.venvs/project-a"
        make_fake_venv "$TEST_TMPDIR/manual-venv"

        source "$BASHRC" >/dev/null 2>&1
        source "$TEST_TMPDIR/manual-venv/bin/activate"

        cd "$HOME/project-a"
        auto_activate_central_venv
        [[ "$VIRTUAL_ENV" == "$TEST_TMPDIR/manual-venv" ]] || exit 1
        [[ -z "${CENTRAL_VENV_AUTO_ACTIVATED:-}" ]] || exit 2
    ' || fail "auto activation should not replace a manually activated venv"
}

test_source_is_quiet_and_preserves_directory
test_ek_without_configs_has_no_basename_error
test_reposync_does_not_rewrite_source_files
test_central_venv_helpers_create_activate_and_list
test_auto_activate_central_venv_switches_and_deactivates
test_auto_activate_central_venv_preserves_manual_venv

echo "All my_bashrc tests passed"
