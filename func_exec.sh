
exec_attachment() {
  local func_name="att_$1"
  if [[ $(type -t $func_name) == "function" ]]; then
    $func_name "$@"
  fi
}
