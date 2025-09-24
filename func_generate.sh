# generate(filename)
# Generate a file from a template
# templates are located in templates/ of the SERVICE_DIR
# generated files are located in the generated/ of the SERVICE_DIR
# template variables are in the form of ${VAR}

# $1: from/template/path.yml
# $2: to/path.yml


with_spaces() {
  if [ "$#" -ne 2 ]; then
    echo "Illegal number of parameters"
    echo "Remember to put the text in quotes"
    exit 1
  fi
  spaces="$1"
  text="$2"
  if ! [[ "$spaces" =~ ^[0-9]+$ ]]; then
    echo "First argument must be a number"
    exit 1
  fi
  # remove empty lines
  text=$(echo "$text" | sed '/^$/d')
  # add spaces on all new lines
  echo "$text" | sed "s/^/$(printf "%${spaces}s")/"
}
export -f with_spaces

generate() {
  local template="$1"
  local generated="$2"

  if [[ ! -f $template ]]; then
    echo "Template file not found"
    exit 1
  fi

  if [[ -z $generated ]]; then
    echo "Generated path not provided"
    exit 1
  fi

  local path=$(dirname $generated)
  local filename=$(basename $generated)
  echo "Generating $filename"
  mkdir -p $path

  local error_output
  error_output=$( {
eval "cat <<EOF
$(<"$template")
EOF
" | envsubst > "$generated"; } 2>&1)

  # Check if error_output contains anything
  if [[ -n "$error_output" ]]; then
    echo "Error occurred during template generation:"
    echo "$error_output"
    exit 1
  fi
}
