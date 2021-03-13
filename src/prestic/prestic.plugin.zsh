# RESTIC profile switch
function prestic() {
  if [[ -z "$1" ]]; then
    unset PRESTIC_PROFILE RESTIC_REPOSITORY_FILE RESTIC_REPOSITORY RESTIC_PASSWORD_FILE RESTIC_PASSWORD RESTIC_PASSWORD_COMMAND RESTIC_KEY_HINT RESTIC_CACHE_DIR RESTIC_PROGRESS_FPS
    echo RESTIC profile cleared.
    return
  fi

  local -a available_profiles
  available_profiles=($(prestic_profiles))
  if [[ -z "${available_profiles[(r)$1]}" ]]; then
    echo "${fg[red]}Profile '$1' not found in '${PRESTIC_PROFILES_FILE:-$HOME/.restic/config}'" >&2
    echo "Available profiles: ${(j:, :)available_profiles:-no profiles found}${reset_color}" >&2
    return 1
  fi

  local profile="$1"

  # Switch to RESTIC profile
  for i in $(awk -v TARGET=$profile -F ' *= *' '{ if ($0 ~ /^\[.*\]$/) { gsub(/^\[|\]$/, "", $0); SECTION=$0 } else if (($2 != "") && (SECTION==TARGET)) { print '$2' }}' ${PRESTIC_PROFILES_FILE:-$HOME/.restic/config}); do export $i; done

  export PRESTIC_PROFILE="$profile"
}

function prestic_profiles() {
  [[ -r "${PRESTIC_PROFILES_FILE:-$HOME/.restic/config}" ]] || return 1
  grep --color=never -Eo '\[.*\]' "${PRESTIC_PROFILES_FILE:-$HOME/.restic/config}" | sed -E 's/^[[:space:]]*\[(profile)?[[:space:]]*([-_[:alnum:]\.@]+)\][[:space:]]*$/\2/g'
}

function _prestic_profiles() {
  reply=($(prestic_profiles))
}
compctl -K _prestic_profiles prestic

# RESTIC prompt
function prestic_prompt_info() {
  [[ -z $PRESTIC_PROFILE ]] && return
  echo "${ZSH_THEME_PRESTIC_PREFIX:=<}${PRESTIC_PROFILE}${ZSH_THEME_PRESTIC_SUFFIX:=>}"
}

if [[ "$SHOW_PRESTIC_PROMPT" != false && "$RPROMPT" != *'$(prestic_prompt_info)'* ]]; then
  RPROMPT='$(prestic_prompt_info)'"$RPROMPT"
fi

# Load restic completions
#restic generate --zsh-completion /usr/local/share/zsh-completions/_restic
# TODO