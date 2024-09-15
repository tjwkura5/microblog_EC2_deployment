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
                FLASK_APP=microblog.py
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
                script {
                    // Run Dependency-Check in the background
                    sh 'nohup dependencyCheck --scan ./ --disableYarnAudit --disableNodeAudit --purge --nvdApiKey 835c57e7-963c-467b-8458-55db3aaa6f8c > dep-check.log 2>&1 &'
                    
                    // Wait for the process to complete 
                    sleep 180 

                    // Check if the process is finished
                    sh 'tail -f dep-check.log'
                }
                // Now publish the results
                dependencyCheckPublisher pattern: '**/dependency-check-report.xml'
            }
        }
      stage ('Clean') {
            steps {
                sh '''#!/bin/bash
                if [[ $(ps aux | grep -i "gunicorn" | tr -s " " | head -n 1 | cut -d " " -f 2) != 0 ]]
                then
                ps aux | grep -i "gunicorn" | tr -s " " | head -n 1 | cut -d " " -f 2 > pid.txt
                kill $(cat pid.txt)
                exit 0
                fi
                '''
            }
        }
      stage ('Deploy') {
            steps {
                sh '''#!/bin/bash
                # Restart Nginx to ensure it picks up the latest configuration
                sudo systemctl restart nginx

                # Start Flask application
                gunicorn -b :5000 microblog:app &
                '''
            }
        }
    }
}
