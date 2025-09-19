# Manage your Shell history thanks to LLM with Shellm

⚠️ This project is only for poc purpose

## Getting started

* Get a Scaleway GenerativeAPI API KEY (around 2 minutes needed)
> https://www.scaleway.com/en/developers/api/generative-apis/

* Export in your secret key in ENV var `$SCW_SECRET_KEY`

* For zsh users: Add `preexec` method in your `~/.zshrc` file
```
export LLHM_HISTFILE="$HOME/.shellm/history.log"
# Function to log command before execution
preexec() {
   # Skip logging empty commands or internal use
  [[ -n "$2" ]] || return
  local cmd="$2"
  local ts=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
  local cwd=$(pwd)
  local exit_code=$?
  echo "[$ts] $cmd | $cwd | (exit_code: $exit_code)" >> "$LLHM_HISTFILE"
}
```

* Clone project in `$HOME/.shellm` directory

* Create history logs file `touch $HOME/.shellm/history.log`

🚀 Tool is ready to use

## Usage

```
$ ./llm-history
```
