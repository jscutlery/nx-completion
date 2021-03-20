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
  local def=$(_workspace_def)
  local -a json

  # Parse JSON and acces to projects name: def.projects[project_name]
  json=$(< $def | jq '.projects' | jq -r 'keys[]')

  echo $json
}

_run_command_completion() {
  # Only run on `nx run ?`
  [[ ! "$(_count_args)" = "3" ]] && return

  # List projects
  _values $(_list_projects)
}

_nx_commands_completion() {
  _values \
    'subcommand' \
      'run[Run a target for a project (e.g., nx run myapp:serve:production)]'
      # 'generate[Generate code (e.g., nx generate @nrwl/web:app myapp)]'
}

_nx_completion() {
  # Show nx commands if not typed yet.
  [[ $(_count_args) -le 2 ]] && _nx_commands_completion && return

  # Display an error if no workspace definition found.
  [[ $(_check_workspace_def) -eq 1 ]] && echo "error: workspace definition not found" && return
  
  # Load completion commands
  case "$(_nx_command)" in
    run)
      _run_command_completion
      ;;
    g|generate)
      # @todo
      ;;
  esac
}
compdef _nx_completion nx
