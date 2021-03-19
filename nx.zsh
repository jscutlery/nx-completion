_nx_command() {
  echo "${words[2]}"
}

_nx_command_arg() {
  echo "${words[3]}"
}

_count_args() {
  echo "$#words"
}

_check_workspace_def() {
  local angular_def="$PWD/angular.json"
  local workspace_def="$PWD/worspace.json"

  if [[ ! -f $angular_def && ! -f $workspace_def ]]; then 
    echo 1
  else 
    echo 0
  fi
}

_list_projects() {
  local angular_def="$PWD/angular.json"
  local workspace_def="$PWD/worspace.json"
  
  # @todo: handle workspace both def type
  json=$(< $angular_def | jq '.projects' | jq -r 'keys[]')
  echo $json
}

_run_command_completion() {
  # Only run on `nx run ?`
  [[ ! "$(_count_args)" = "3" ]] && return

  # Recommend projects
  _values $(_list_projects)

  # Make sure we don't run default completion
  custom_completion=true
}

_nx_commands_completion() {
  _values \
    'subcommand' \
      'run[Run a target for a project (e.g., nx run myapp:serve:production)]'
      # 'generate[Generate code (e.g., nx generate @nrwl/web:app myapp)]'
}

_nx() {
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
compdef _nx nx
