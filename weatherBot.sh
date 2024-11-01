#!/bin/bash
if [ -f ~/.bashrc ]; then
    source ~/.bashrc
fi

echo $SHELL




is_docker() {
    # Multiple methods to detect Docker
    if [ -f /.dockerenv ]; then
        return 0  # True, running in Docker
    elif grep -q 'docker\|lxc' /proc/1/cgroup 2>/dev/null; then
        return 0  # True, running in Docker
    elif grep -q 'docker\|lxc' /proc/self/cgroup 2>/dev/null; then
        return 0  # True, running in Docker
    elif [ -f /proc/1/environ ] && grep -q 'container=docker' /proc/1/environ 2>/dev/null; then
        return 0  # True, running in Docker
    fi
    return 1  # False, not running in Docker
}

if is_docker; then
    echo "Running in Docker, relying on clean system"
        APP_HOME="${APP_HOME:-/home/appuser/weatherbot}"
        CLI_HOME="${CLI_HOME:-/home/appuser/cli}"
        APP_DATA="${APP_DATA:-$APP_HOME/wx-bot-appdata}"
        which node || {
        echo "Node.js not found"
        exit 1
    }
    echo "Node.js found at: $(which node)"
    #whereis node
else
    # use or comment the following lines if you need to use nvm to set the node version for your specific environment install
    echo "Not running in Docker, setting up nvm"
    APP_HOME="${APP_HOME:-./}"
    CLI_HOME="${CLI_HOME:-$HOME/.local/bin}"
    APP_DATA="${APP_DATA:-$APP_HOME/wx-bot-appdata}"
    source ~/.nvm/nvm.sh
    nvm use 20.9.0  # Ensure the correct version is used
fi


echo Current OS user: $(whoami)
# Get current username and change directory
CURRENT_USER=$(whoami)

cd $APP_HOME

# openssl issue was due to bug in Simplex Chat install.sh logic
# whereis libcrypto.so.1.1


if is_docker; then
    echo "Running in Docker, continuing..."
else
    echo "non-dockercurrent directory: $(pwd)"
    read -p "Press [Enter] to continue..."
fi




# uncomment the while/done lines if you want to run the script in a loop to restart the applications if they exit

#while true; do
    # Load environment variables from weatherBot.env
    export $(cat weatherBot.env | grep -v '^#' | xargs)

    # Start the first application with piped input
    if [ ! -f ./initcli.flag ]; then
        echo "initcli.flag NOT found, starting wxBot first time"
        echo "wxBot" | $CLI_HOME/simplex-chat --log-file $APP_DATA/simplelog.log -l error -p ${SIMPLEX_CHAT_PORT:-5225} -d $APP_DATA/jed &
        FIRST_APP_PID=$!
        touch ./initcli.flag  # Create the flag file here
    else
        echo "Normal CLI start on port ${SIMPLEX_CHAT_PORT:-5225}"
        $CLI_HOME/simplex-chat --log-file $APP_DATA/simplelog.log -l error -p ${SIMPLEX_CHAT_PORT:-5225} -d $APP_DATA/jed &
        FIRST_APP_PID=$!
    fi

    # Wait for a few seconds
    # sleep 300
    echo "Starting wx-bot-chat.js"
    sleep 1
    # Start the second application
    node wx-bot-chat.js &
    SECOND_APP_PID=$!

    # sleep 300
    # Wait for either application to exit
    wait -n $FIRST_APP_PID $SECOND_APP_PID

    # If either application exits, kill the other and restart both
    if kill -0 $FIRST_APP_PID 2>/dev/null; then
        kill $SECOND_APP_PID
        sleep 2
    else
        kill $FIRST_APP_PID
        sleep 2
    fi
   
	if is_docker; then
	    echo "Exiting wxBot"
	    # echo "Restarting applications..."
	else
	    echo "non-docker, exiting wxBot"
        # comment out the following line if you don't want to pause the script before exiting/restarting
	    read -p "Press [Enter] to continue..."
	fi
#done

