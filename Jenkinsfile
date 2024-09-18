pipeline {
  agent any
    stages {
        stage ('Build') {
            steps {
                sh '''#!/bin/bash
                python3.9 -m venv venv
                source venv/bin/activate
                pip install pip --upgrade
                pip install -r requirements.txt
                pip install gunicorn pymysql cryptography 
                export FLASK_APP=microblog.py
                flask translate compile
                flask db upgrade
                '''
            }
        }
        stage ('Test') {
            steps {
                sh '''#!/bin/bash
                source venv/bin/activate
                export PYTHONPATH=$(pwd)
                py.test ./tests/unit/ --verbose --junit-xml test-reports/results.xml
                '''
            }
            post {
                always {
                    junit 'test-reports/results.xml'
                }
            }
        }
        stage('OWASP FS SCAN') {
            steps {
                dependencyCheck additionalArguments: '--scan ./ --disableYarnAudit --disableNodeAudit --nvdApiKey 835c57e7-963c-467b-8458-55db3aaa6f8c', odcInstallation: 'DP-Check'
                dependencyCheckPublisher pattern: '**/dependency-check-report.xml'
            }
        }
      stage ('Clean') {
            steps {
                sh '''#!/bin/bash
                # Find the process ID of gunicorn using pgrep
                pid=$(pgrep -f "gunicorn")

                # Check if PID is found and is valid (non-empty)
                if [[ -n "$pid" && "$pid" -gt 0 ]]; then
                    echo "$pid" > pid.txt
                    kill $(cat pid.txt)
                    echo "Killed gunicorn process with PID $pid"
                else
                    echo "No gunicorn process found to kill"
                fi
                '''
            }
        }
      stage ('Deploy') {
            steps {
                sh '''#!/bin/bash
                # Start Flask application
                source venv/bin/activate

                # Restart the Gunicorn service
                sudo /bin/systemctl restart gunicorn

                # Check the status of the service
                if sudo /bin/systemctl is-active --quiet gunicorn; then
                    echo "Gunicorn restarted successfully"
                else
                    echo "Failed to restart Gunicorn"
                    # Print logs for debugging
                    sudo /bin/journalctl -u gunicorn.service
                    exit 1
                fi
                '''
            }
        }
    }
}
