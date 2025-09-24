
print_help() { # $1: prefix, $2: command_list
  local prefix="$1"
  local -n cmds="$2"

  commandlist=$(printf "%s|" "${!cmds[@]}")
  commandlist=${commandlist%?}

  echo "Usage: $0 $prefix<${commandlist}>"
  echo
  echo "Commands:"

  # calculate max len
  max_len=0
  for cmd in "${!cmds[@]}"; do
    arg_desc="${cmds[$cmd]}"
    arguments=$(echo "$arg_desc" | cut -d':' -f1)
    len=$((${#cmd} + ${#arguments} + 2))
    [[ $len -gt $max_len ]] && max_len=$len
  done

  for cmd in "${!cmds[@]}"; do
    arg_desc="${cmds[$cmd]}"
    arguments=$(echo "$arg_desc" | cut -d':' -f1)
    description=$(echo "$arg_desc" | cut -d':' -f2)
    printf "  %-${max_len}s %s\n" "$cmd $arguments" "$description"
  done
}
