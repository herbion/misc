# TODO: it's getting ridiculous, refactor


# aliases
alias watch='watch '
alias klogs='stern --template "{{.Message}}({{color .PodColor .PodName}}) " --all-namespaces '
alias kw='kwatch '
alias k='kubectl'
alias kk='kubectl get pods --all-namespaces | grep -v -E "kube|default"'
alias kkk='kubectl get pods '
alias qq='watch '
alias kns='kubens'
alias klogs='stern --template "{{.Message}}({{color .PodColor .PodName}}) " --all-namespaces '

alias tree="fzf --preview 'bat --style=numbers --color=always --line-range :500 {}'"

function find_pod() {
  if [ -n "$1" ]; then
    selectionByPattern=$(kubectl get pod --all-namespaces | grep $1)
  else
    selectionByPattern=$(kubectl get pod --all-namespaces)
  fi

  if (( $(grep -c . <<<"$selectionByPattern") > 1 )); then
    podLine=$(echo $selectionByPattern | fzf --height 15% --layout reverse)
  else
    podLine=$(echo $selectionByPattern)
  fi

  retVal=$(echo $podLine | tr -s ' ' | cut -d ' ' -f 2)

  echo $retVal
}

function kdebug() {
    # set -x
    podLine=$(find_pod $1)
    
    if [ -z "$podLine" ]; then
      echo "Could not find pod matching [$1]."
      return 1;
    fi
    
    result=$(kubectl get pod --all-namespaces | grep -m1 "$podLine")

    namespace=$(echo $result | awk '{print $1}')
    podName=$(echo $result | awk '{print $2}')
    
    echo "Debugging pod -> $podName/$namespace"
  
    set -x
    kubectl port-forward -n $namespace $podName ${2:-5005}:${3:-4000}
    set +x
}

function harness_position() {
  harness_host=
  provider=$1
  station=$2
  echo Using URL: https://$harness_host/position/$station/$provider
  echo --- 
  curl -sS https://$harness_host/position/$station/$provider \
    | jq -r '(.[] | [.positionId, .stationCode, .positionType, .name, .location.name, .location.positionId]) | @tsv' \
    | sort -r -k 1 -n \
    | column -t -s "$(printf '\011')"
}

function harness_search() {
  echo "Usage 'harness_search autostradale Milan Penia'"
  harness_host=
  provider=$1
  station_from=$2
  station_to=$3
  date=$(date -v +1d +%F)

  station_from=$(harness_position $provider $station_from \
    | fzf --height 15% --layout reverse --header "Pick station from:" \
    | tr -s ' ' \
    | cut -d ' ' -f 1)
  station_to=$(harness_position $provider $station_to \
    | fzf --height 15% --layout reverse --header "Pick station to:" \
    | tr -s ' ' \
    | cut -d ' ' -f 1)

  harness_link=https://$harness_host/search/OW/$date/$station_from/$station_to/1/0/0/$provider

  echo "Searching using $harness_link"

  curl -sS "$harness_link" | jq '.'
}

# tail logs
function klogs1() {
    argument=$1
    shift;

    podLine=$(kubectl get pod --all-namespaces | tr -s ' ' | cut -d ' ' -f 2 | grep -m1 $argument)

    exitCode=$?
    if [ ! "$exitCode" -eq 0 ]; then
      echo "Could not find pod matching [$@]."
      return 1;
    fi

    result=$(kubectl get pod --all-namespaces | grep -m1 "$podLine")
    
    namespace=$(echo $result | awk '{print $1}')
    podName=$(echo $result | awk '{print $2}')
    
    echo "logs from pod -> $podName/$namespace"
  
    kubectl logs -f -n $namespace $podName $@
}

function kwatch() {
    watch --color "kubectl get pods --all-namespaces | grep -v -E 'kube|default'"
}

spaceship_kubecontext() {
  [[ $SPACESHIP_KUBECONTEXT_SHOW == false ]] && return

  spaceship::exists kubectl || return

  local kube_context=$(kubectl config current-context 2>/dev/null)
  [[ -z $kube_context ]] && return

  if [[ $SPACESHIP_KUBECONTEXT_NAMESPACE_SHOW == true ]]; then
    local kube_namespace=$(kubectl config view --minify --output 'jsonpath={..namespace}' 2>/dev/null)
    local kube_server=$(kubectl config view --minify --output 'jsonpath={..server}' 2>/dev/null)

    kube_namespace=${kube_namespace:-unknown}
    kube_context="[$kube_context @ $kube_server] ($kube_namespace)"
  fi

  # Apply custom color to section if $kube_context matches a pattern defined in SPACESHIP_KUBECONTEXT_COLOR_GROUPS array.
  # See Options.md for usage example.
  local len=${#SPACESHIP_KUBECONTEXT_COLOR_GROUPS[@]}
  local it_to=$((len / 2))
  local 'section_color' 'i'
  for ((i = 1; i <= $it_to; i++)); do
    local idx=$(((i - 1) * 2))
    local color="${SPACESHIP_KUBECONTEXT_COLOR_GROUPS[$idx + 1]}"
    local pattern="${SPACESHIP_KUBECONTEXT_COLOR_GROUPS[$idx + 2]}"
    if [[ "$kube_context" =~ "$pattern" ]]; then
      section_color=$color
      break
    fi
  done

  [[ -z "$section_color" ]] && section_color=$SPACESHIP_KUBECONTEXT_COLOR

  spaceship::section \
    "$section_color" \
    "$SPACESHIP_KUBECONTEXT_PREFIX" \
    "${SPACESHIP_KUBECONTEXT_SYMBOL}${kube_context}" \
    "$SPACESHIP_KUBECONTEXT_SUFFIX"
}

function kdash() {
	local K8S_SERVER=$(kubectl config view --minify --output 'jsonpath={..server}' 2>/dev/null)
	local K8S_DASHBOARD_PATH="api/v1/namespaces/kube-system/services/https:kubernetes-dashboard:/proxy/#!/"
	[[ -z "$K8S_SERVER" ]] || open "$K8S_SERVER/$K8S_DASHBOARD_PATH"
}

function kvm() {
  local K8S_SERVER=$(kubectl config view --minify --output 'jsonpath={..server}' 2>/dev/null)
  local K8S_HOST=$(echo $K8S_SERVER | perl -ne 'print $1 if /:\/\/(.+):[0-9]+?/')
  local K8S_SERVER_IP=$(host $K8S_HOST | perl -ne 'print $1 if /has address (.+)/')
  [[ -z "$K8S_SERVER_IP" ]] || open "https://www.appname.com.$K8S_SERVER_IP.nip.io/"  
}

function klogsc() {
   klogs "$@" | perl -pe 's/^.*"ERROR".*$/\e[0;31m$&\e[0m/g; s/^.*"WARN".*$/\e[0;33m$&\e[0m/g; s/^.*"INFO".*$/\e[0;37m$&\e[0m/g; s/\\n/\n/g; s/\\t/\t/g;' 
}
function kblookup() {
  # kibana query parameters
  env="KIBANA_URL_HERE"
  index="9a5a3e10-8146-11e9-90ed-319970ac04c5" # hot + warm
  columns="!(message,k8s_namespace)"
  time="(from:now-24h,to:now)" # from:now%2Fw,to:now%2Fw


  level=''
  message=''
  namespace=''
  correlation_id=''

  declare -a params=()

  while getopts 'hm:n:i:-:t:l:' opt; do
    case "${opt}" in
      m) message="message: \"${OPTARG}\"" ;;
      n) namespace="k8s_namespace: \"${OPTARG}\"" ;;
      i) correlation_id="correlation_id: \"${OPTARG}\"" ;;
      l) level="level: \"${OPTARG}\"" ;;

      t) time="(${OPTARG})" ;; # maybe split into two args
      
      -) case "${OPTARG}" in
          warm) index="aff02ef0-383f-11ea-a29d-dbda815f5190" ;;
          hot) index="9a5a3e10-8146-11e9-90ed-319970ac04c5" ;;
          *) # process any additional long opt as kibana query param
            val=${OPTARG#*=}
            opt=${OPTARG%=$val}
            params+=("${opt}: \"${val}\"")
          ;;
         esac;;
      h) echo "Usage: kibana_lookup"
         echo "  [-m message] filter by message"
         echo "  [-n k8s_namespace] filter by namespace"
         echo "  [-i correlation_id] filter by correlation_id"
         echo "  [-t timeframe] filter by timeframe, default 24h"
         echo "  ex: [-t 'from:'2020-07-20',to:'2020-07-21']"
         echo "  ex: [-t 'from:'from:now-2M,to:now']"
         echo "  [-h] show this message"
         return 1 ;;
    esac
  done

  params+=($message $namespace $correlation_id $level)
  query=$(printf " AND %s" "${params[@]}")
  query=`uriencode ${query:5}`

  time=`uriencode ${time}` # remove this if causes problems
  
  if [ -z "$query" ]; then ;
    echo "No parameters provided; Check -h for help" ;
    return 1; 
  fi;

  url="$env#/discover?_g=(refreshInterval:(pause:!t,value:0),time:$time)&_a=(columns:$columns,index:'$index',interval:auto,query:(language:lucene,query:'$query'),sort:!(!('@timestamp',desc)))"

  echo "🌸 Opening generated URL -> $url 🌸";
  open $url;
}

function uriencode { jq -nr --arg v "$1" '$v|@uri'; }

