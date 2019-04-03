#!/bin/bash

listCluster() {
    declare -g CLUSTER=$(kubectl config -o=name get-contexts | select_from_list)
    local STATUS=$?

    # Check if user selected something
    if [ $STATUS == 0 ]; then
        echo "context/cluster selected by user: $CLUSTER"
        echo "Loading Namespace(s)... "
        listNamespaces

    else
        echo "Cancelled!"
    fi
}

listNamespaces() {
    kubectl config use-context $CLUSTER
    declare -g NAMESPACES=$(kubectl get namespace -o=name | cut -d/ -f2 | select_from_list)
    local STATUS=$?

    # Check if user selected something
    if [ $STATUS == 0 ]; then
        echo "Namespace selected by user: $NAMESPACES"
        echo "Loading MicroService(s)... "
        listApps

    else
        echo "Cancelled!"
    fi
}

listApps() {
    declare -g APPS=$(kubectl get pods --namespace $NAMESPACES -o jsonpath="{..image}" | tr -s '[[:space:]]' '\n' | cut -d: -f1 | cut -d/ -f2 | sort -u | select_from_list)
    local STATUS=$?

    # Check if user selected something
    if [ $STATUS == 0 ]; then
        echo "MicroService selected by user: $APPS"
        echo "---Loading export options---"
        exportSelectedAppLog

    else

        echo "Cancelled!"
    fi

}

exportSelectedAppLog() {

    echo "1. Last Hour"
    echo "2. Last Day (24h)"
    echo "3. All"
    read -p "Please select an item: " TIME

    case "$TIME" in
    1)

        kubectl --namespace=$NAMESPACES logs -lapp=$APPS --since=1h >$CLUSTER-$NAMESPACES-$APPS-1H-$(date +%F_%R).log
        echo "All $APPS logs exported and available here - > $PWD/$CLUSTER-$NAMESPACES-$APPS-1H-$(date +%F_%R).log"
        ;;
    2)

        kubectl --namespace=$NAMESPACES logs -lapp=$APPS --since=24h >$CLUSTER-$NAMESPACES-$APPS-1D-$(date +%F_%R).log
        echo "All $APPS logs exported and available here - > $PWD/$CLUSTER-$NAMESPACES-$APPS-1D-$(date +%F_%R).log"
        ;;
    3)

        kubectl --namespace=$NAMESPACES logs -lapp=$APPS >$CLUSTER-$NAMESPACES-$APPS-ALL-$(date +%F_%R).log
        echo "All $APPS logs exported and available here - > $PWD/$CLUSTER-$NAMESPACES-$APPS-ALL-$(date +%F_%R).log"
        ;;
    *)
        echo "Please provide correct application name!"
        ;;
    esac

}

select_from_list() {
    prompt="Please select an item:"

    options=()

    if [ -z "$1" ]; then
        # Get options from PIPE
        input=$(cat /dev/stdin)
        while read -r line; do
            options+=("$line")
        done <<<"$input"
    else
        # Get options from command line
        for var in "$@"; do
            options+=("$var")
        done
    fi

    # Close stdin
    0<&-
    # open /dev/tty as stdin
    exec 0</dev/tty

    PS3="$prompt "
    select opt in "${options[@]}" "Quit"; do
        if ((REPLY == 1 + ${#options[@]})); then
            exit 1

        elif ((REPLY > 0 && REPLY <= ${#options[@]})); then
            break

        else
            echo "Invalid option. Try another one."
        fi
    done
    echo $opt
}

# Ask the user for their os
echo welcome, $USER
echo what\'s your operating system?
echo 1. Mac
echo 2. Ubuntu

read -p "Please select an item: " os
if [[ $os == "1" || $os == "mac" ]]; then
    listCluster
elif [[ $os == "2" || $os == "ubuntu" ]]; then
    listCluster
else
    echo wrong input!

fi
