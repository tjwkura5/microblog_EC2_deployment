#!/bin/bash

# Check if Jenkins is installed
# dpkg -l: Lists all installed packages on the system. 
# The -l option provides a detailed list of packages including their names, versions, and descriptions.

# grep -q jenkins: Searches the input for the string jenkins. 
# The -q option stands for "quiet" and tells grep to not produce any output. It only returns an exit status:

if dpkg -l | grep -q jenkins; then
    echo "Jenkins is already installed."

    # Check if Jenkins is running

    # The line systemctl is-active --quiet jenkins is used to check the status of the 
    # Jenkins service on a system that uses systemd for service management. 
   
    #is-active: This option checks whether the specified service is currently active (running).

    # The --quiet option suppresses the output of the command. 
    # Instead of printing the status to the console, it only returns an exit status (0 for active and 3 for inactive).

    if systemctl is-active --quiet jenkins; then
        echo "Jenkins is running."
    else
        echo "Jenkins is not running."

        echo "Starting jenkins.." 

        # Start Jenkins service
        sudo systemctl start jenkins

        sudo systemctl status jenkins
    fi

else
    echo "Jenkins is not installed. Installing Jenkins..."

    # Install Jenkins and friends 
    sudo apt update && sudo apt install fontconfig openjdk-17-jre software-properties-common -y

    sudo add-apt-repository ppa:deadsnakes/ppa -y

    sudo apt install python3.9 python3.9-venv -y

    sudo wget -O /usr/share/keyrings/jenkins-keyring.asc https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key

    echo "deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc]" https://pkg.jenkins.io/debian-stable binary/ | sudo tee /etc/apt/sources.list.d/jenkins.list > /dev/null
    
    sudo apt-get update
    
    sudo apt-get install jenkins -y

    # Start Jenkins service
    sudo systemctl start jenkins

    sudo systemctl status jenkins
fi