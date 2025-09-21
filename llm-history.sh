#!/bin/zsh

# ~/.shell-llm/llm-history
# Smart shell history powered by LLM

HISTFILE="$HOME/.shellm/history.log"
LLM_MODEL="qwen3-235b-a22b-instruct-2507"
API_ENDPOINT="https://api.scaleway.ai/v1/chat/completions"

# Usage
if [[ $# -eq 0 ]]; then
  cat << 'EOF'
🌟 LLM-Enhanced Shell History

Usage:
  llm-history search "what was that command to tar a directory?"
  llm-history explain "tar -czf archive.tar.gz folder/"
  llm-history suggest "git push failed"
  llm-history recent     # Show last 10 commands
  llm-history help
EOF
  exit 0
fi

# Fetch recent history
recent() {
  if [[ -f "$HISTFILE" ]]; then
    echo "📌 Recent commands:"
    tail -n 20 "$HISTFILE" | cut -d'|' -f1,2 | sed 's/].*/]/' | sort -u | tail -n 10
  else
    echo "📭 No history yet. Run some commands."
  fi
}

# Search with LLM (natural language query)
search() {
  local query="$1"

  local history_snippet=$(tail -n 200 "$HISTFILE")
  echo "🔍 Asking LLM to find relevant commands..."

  local prompt=$(printf "%s\n\n---\nShell history:\n%s\n---\nQuestion: %s\nAnswer concisely based on the given shell history, use context around if necessary:\n" \
    "You are a helpful shell assistant. Use only real Unix commands." \
    "$history_snippet" \
    "$query")

  local llm_response=$(curl -s $API_ENDPOINT \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $SCW_SECRET_KEY" \
  -d @<(jq -nc \
    --arg prompt_val "$prompt" \
    --arg model_name "$LLM_MODEL" \
    '{
      model: $model_name,
      messages: [
        {
          role: "system",
          content: "You are a software engineer specialized on UNIX systems"
        },
        {
          role: "user",
          content: $prompt_val
        }
      ]
    }'))
    echo "$llm_response" | jq -r '.choices[0].message.content'
}

# Explain a command using LLM
explain() {
  local cmd="$1"
  echo "💬 Explaining: $cmd"
  local prompt=$(echo "Explain this shell command in simple terms: $cmd. Include a short example if relevant.")
  local llm_response=$(curl -s $API_ENDPOINT \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $SCW_SECRET_KEY" \
  -d @<(jq -nc \
    --arg prompt_val "$prompt" \
    --arg model_name "$LLM_MODEL" \
    '{
      model: $model_name,
      messages: [
        {
          role: "system",
          content: "You are a software engineer specialized on UNIX systems and also teacher. Output must be fully parseable using JQ shell command"
        },
        {
          role: "user",
          content: $prompt_val
        }
      ]
    }'))
    echo "$llm_response" | jq -r '.choices[0].message.content'
}

# Suggest similar or corrected commands
suggest() {
  local error_context="$1"
  local recent=$(tail -n 10 "$HISTFILE" | grep -i "git\|push\|error" || true)
  
  echo "💡 Suggesting fix for: $error_context"

  local prompt="I ran a command that failed with an error related to: '$error_context'.
Recent commands:
$recent

Suggest a corrected or alternative command. Be concise."
  
  local llm_response=$(curl -s $API_ENDPOINT \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $SCW_SECRET_KEY" \
  -d @<(jq -nc \
    --arg prompt_val "$prompt" \
    --arg model_name "$LLM_MODEL" \
    '{
      model: $model_name,
      messages: [
        {
          role: "system",
          content: "You are a software engineer specialized on UNIX systems, provide shell commands to answer the user request."
        },
        {
          role: "user",
          content: $prompt_val
        }
      ]
    }'))
  echo "$llm_response" | jq -r '.choices[0].message.content'
}

# Dispatch
case "$1" in
  search) shift; search "$*" ;;
  explain) shift; explain "$*" ;;
  suggest) shift; explain "how to fix: $*" ;; # or use suggest func
  recent) recent ;;
  *) echo "❌ Unknown command. Try 'llm-history help'" ;;
esac

