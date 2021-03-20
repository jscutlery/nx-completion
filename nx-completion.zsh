w_defs=(
  "$PWD/angular.json"
  "$PWD/worspace.json"
)

_nx_command() {
  echo "${words[2]}"
}

_count_args() {
  echo "$#words"
}

# Check if at least one of w_defs are present in working dir.
_check_workspace_def() {
  local a_def=${w_defs[1]}
  local w_def=${w_defs[2]}

  if [[ ! -f $a_def && ! -f $w_def ]]; then 
    echo 1
  else 
    echo 0
  fi
}

# Get workspace defition path.
# Assumes _check_workspace_def get called before.
_workspace_def() {
  local a_def=${w_defs[1]}
  local w_def=${w_defs[2]}

  if [[ -f $a_def ]]; then
    echo $a_def
  else
    echo $w_def
  fi
}

# List projects within workspace definition file,
# uses jq dependency to parse and manipulate JSON file
# instead of using a dirty grep or sed.
_list_projects() {
  [[ $PREFIX = -* ]] && return 1
  integer ret=1
  local def=$(_workspace_def)
  local -a projects
  # Parse workspace def,
  # create JSON array from projects name,
  # and transform to zsh array.
  projects=($(< $def | jq '.projects' | jq -r 'keys[]'))

  # Autocomplete projects as an option, and append ':' (eg: nx run demo:build).
  _describe -t projects "projects option" projects -qS ":" && ret=0 
  return ret
}

_nx_arguments() {
    if zstyle -t ":completion:${curcontext}:" option-stacking; then
        print -- -s
    fi
}

_nx_commands() {
  local -a lines
  # Run nx to get command list output.
  lines=(${(f)"$(_call_program commands nx 2>&1)"})
  _nx_subcommands=(${${${(M)${lines[$((${lines[(i)*Commands:]} + 1)),-1]}:# *}## #}/ ##/:})

  _describe -t nx-commands "nx command" _nx_subcommands
}

_nx_subcommand() {
    integer ret=1
    local -a opts_help

    opts_help=("--help[Show help]")

    case "$words[1]" in
      (run)
        _arguments $(_nx_arguments) \
          $opts_help \
          ": :_list_projects" && ret=0
          case
            # @todo: handle executors
            # but no clue how! shell is not far from hell

      ;;
    esac

    return ret
}

_nx_completion() {
  # Display an error if no workspace definition found.
  [[ $(_check_workspace_def) -eq 1 ]] && echo "error: workspace definition not found" && return

  integer ret=1
  typeset -A opt_args
  local curcontext="$curcontext"
  
  _arguments $(_nx_arguments) -C \
    "--help[Show help]" \
    "--version[Show version number]" \
    ": :->command" \
    "*:: :->option-or-argument" && ret=0


  case $state in
      (command)
          _nx_commands && ret=0
          ;;
      (option-or-argument)
          curcontext=${curcontext%:*:*}:nx-$words[1]:
          _nx_subcommand && ret=0
          ;;
  esac

  return ret
}
compdef _nx_completion nx
