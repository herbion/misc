# aliases

alias k='kubectl'
alias watch='watch '
alias kns='kubens'
alias klogs='stern --template "{{.Message}}({{color .PodColor .PodName}}) " --all-namespaces '
alias kw='kwatch '

# forward debug port
function kdebug() {
    podLine=$(kubectl get pod --all-namespaces | tr -s ' ' | cut -d ' ' -f 2 | grep -m1 $1)
    exitCode=$?
    if [ ! "$exitCode" -eq 0 ]; then
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

