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
        // stage('OWASP FS SCAN') {
        //     steps {
        //         dependencyCheck additionalArguments: '--scan ./ --disableYarnAudit --disableNodeAudit --nvdApiKey 835c57e7-963c-467b-8458-55db3aaa6f8c', odcInstallation: 'DP-Check'
        //         dependencyCheckPublisher pattern: '**/dependency-check-report.xml'
        //     }
        // }
      stage ('Clean') {
            steps {
                sh '''#!/bin/bash
                # Find the process ID of gunicorn using pgrep
                pid=$(pgrep -f "gunicorn")

                # Check if PID is found and is valid (non-empty)
                if [[ -n "$pid" && "$pid" -gt 0 ]]; then
                    echo "$pid" > pid.txt
                    kill "$pid"
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
                pkill gunicorn || true
                nohup gunicorn -b :5000 -w 4 microblog:app > gunicorn.log 2>&1 &
                disown
                sleep 30
                if pgrep -f gunicorn > /dev/null; then
                    echo "Gunicorn started successfully"
                    cat gunicorn.log

                else
                    echo "Failed to start Gunicorn"
                    cat gunicorn.log
                    exit 1
                fi
                '''
            }
        }
    }
}
