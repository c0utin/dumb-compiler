#!/bin/sh

set -e

PASS=0
FAIL=0
TOTAL=0

red='\033[0;31m'
green='\033[0;32m'
yellow='\033[1;33m'
cyan='\033[0;36m'
bold='\033[1m'
dim='\033[2m'
reset='\033[0m'

# Build the compiler
printf "\n${dim}Building compiler...${reset}\n"
cabal build -v0 2>&1
COMPILER=$(cabal list-bin compiler 2>/dev/null)

if [ ! -x "$COMPILER" ]; then
    printf "${red}ERROR: could not find compiler binary${reset}\n"
    exit 1
fi
printf "${dim}Done.${reset}\n\n"

# Collect AST/error output per file for the detail section
AST_LOG=$(mktemp)
ERR_LOG=$(mktemp)
trap 'rm -f "$AST_LOG" "$ERR_LOG"' EXIT

# run_suite <file> <expect_lex> <expect_parse> <expect_ast>
#   expect values: "pass" or "fail"
run_suite() {
    file="$1"
    expect_lex="$2"
    expect_parse="$3"
    expect_ast="$4"
    name=$(basename "$file")

    lex_out=$("$COMPILER" --lex "$file" 2>&1) && lex_rc=0 || lex_rc=$?
    parse_out=$("$COMPILER" --parse "$file" 2>&1) && parse_rc=0 || parse_rc=$?
    ast_out=$("$COMPILER" --ast "$file" 2>&1) && ast_rc=0 || ast_rc=$?

    # Check results
    lex_ok=0; parse_ok=0; ast_ok=0

    if [ "$expect_lex" = "pass" ] && [ "$lex_rc" -eq 0 ]; then lex_ok=1
    elif [ "$expect_lex" = "fail" ] && [ "$lex_rc" -ne 0 ]; then lex_ok=1; fi

    if [ "$expect_parse" = "pass" ] && [ "$parse_rc" -eq 0 ]; then parse_ok=1
    elif [ "$expect_parse" = "fail" ] && [ "$parse_rc" -ne 0 ]; then parse_ok=1; fi

    if [ "$expect_ast" = "pass" ] && [ "$ast_rc" -eq 0 ]; then ast_ok=1
    elif [ "$expect_ast" = "fail" ] && [ "$ast_rc" -ne 0 ]; then ast_ok=1; fi

    # Format mode results as compact badges
    if [ "$lex_ok" -eq 1 ]; then lex_badge="${green}lex${reset}"
    else lex_badge="${red}lex${reset}"; fi

    if [ "$parse_ok" -eq 1 ]; then parse_badge="${green}parse${reset}"
    else parse_badge="${red}parse${reset}"; fi

    if [ "$ast_ok" -eq 1 ]; then ast_badge="${green}ast${reset}"
    else ast_badge="${red}ast${reset}"; fi

    all_ok=$((lex_ok + parse_ok + ast_ok))
    TOTAL=$((TOTAL + 3))

    if [ "$all_ok" -eq 3 ]; then
        status="${green}PASS${reset}"
        PASS=$((PASS + 3))
    else
        status="${red}FAIL${reset}"
        PASS=$((PASS + lex_ok + parse_ok + ast_ok))
        FAIL=$((FAIL + 3 - all_ok))
    fi

    printf "  ${status}  %-28s  %b  %b  %b\n" "$name" "$lex_badge" "$parse_badge" "$ast_badge"

    # Save AST output (only first line, skip Haskell noise)
    if [ -n "$ast_out" ]; then
        first_line=$(printf "%s" "$ast_out" | head -1)
        case "$first_line" in
            Program*)
                printf "  %-28s  %s\n" "$name" "$first_line" >> "$AST_LOG"
                ;;
            *"parse error"*|*"compiler:"*)
                # Extract just the error message, strip callstack
                err=$(printf "%s" "$ast_out" | head -1 | sed 's/^compiler: //')
                printf "  %-28s  %s\n" "$name" "$err" >> "$ERR_LOG"
                ;;
        esac
    fi
}

# ── Header ───────────────────────────────────────────────────────────────────
printf "${bold}normie-c compiler test suite${reset}\n"
printf "${dim}────────────────────────────────────────────────────────${reset}\n\n"

# ── Valid programs ───────────────────────────────────────────────────────────
printf "${yellow}Valid programs${reset}\n"
for file in c-code/return_0.c \
            c-code/return_42.c \
            c-code/return_max.c \
            c-code/return_large.c \
            c-code/main.c \
            c-code/with_line_comment.c \
            c-code/with_block_comment.c \
            c-code/multi_line_comments.c \
            c-code/extra_spaces.c \
            c-code/no_newlines.c; do
    [ -f "$file" ] && run_suite "$file" "pass" "pass" "pass"
done

# ── Parse errors ─────────────────────────────────────────────────────────────
printf "\n${yellow}Invalid programs (parse errors)${reset}\n"
for file in c-code/invalid_missing_return.c \
            c-code/invalid_missing_semi.c \
            c-code/invalid_missing_brace.c \
            c-code/invalid_empty.c; do
    [ -f "$file" ] && run_suite "$file" "pass" "fail" "fail"
done

# ── Lex errors ───────────────────────────────────────────────────────────────
printf "\n${yellow}Invalid programs (lex errors)${reset}\n"
for file in c-code/invalid_bad_token.c \
            c-code/invalid_bad_char.c; do
    [ -f "$file" ] && run_suite "$file" "fail" "fail" "fail"
done

# ── Summary ──────────────────────────────────────────────────────────────────
printf "\n${dim}────────────────────────────────────────────────────────${reset}\n"
if [ "$FAIL" -eq 0 ]; then
    printf "${green}${bold}All %d tests passed${reset}\n" "$TOTAL"
else
    printf "${bold}Total: %d${reset}  |  ${green}Passed: %d${reset}  |  ${red}Failed: %d${reset}\n" "$TOTAL" "$PASS" "$FAIL"
fi

# ── AST output ───────────────────────────────────────────────────────────────
if [ -s "$AST_LOG" ]; then
    printf "\n${cyan}${bold}AST output${reset}\n"
    while IFS= read -r line; do
        printf "${dim}%s${reset}\n" "$line"
    done < "$AST_LOG"
fi

# ── Error output ─────────────────────────────────────────────────────────────
if [ -s "$ERR_LOG" ]; then
    printf "\n${red}${bold}Error output${reset}\n"
    while IFS= read -r line; do
        printf "${dim}%s${reset}\n" "$line"
    done < "$ERR_LOG"
fi

printf "\n"

if [ "$FAIL" -ne 0 ]; then
    exit 1
fi
