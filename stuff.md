# Microblog Deployed to EC2 Instance


## Purpose

In our past two projects, we utilized AWS Managed Services, specifically Elastic Beanstalk, to provision the infrastructure for our applications. Elastic Beanstalk comes with many features out of the box, such as EC2 instances, monitoring and logging, security groups, and preconfigured platforms like Node.js and, in our case, Python. The purpose of this workload is to introduce provisioning our own infrastructure and deploying an application.

Let's get started!!

## Clone Repository

Clone [this](https://github.com/kura-labs-org/C5-Deployment-Workload-3) github repository to your Github account. The steps for this have been outlined in the past two workloads. If you get stuck you can refer back to workload 2 [here](https://github.com/tjwkura5/retail-banking-app-deployed-elastic-beanstalk-2).

## Jenkins and Application Server

**Setting Up the CI Server (Jenkins):**

Create an Ubuntu EC2 instance (t3.micro) named "Jenkins". Be sure to configure the security group to allow for SSH and HTTP traffic in addition to the ports required for Jenkins and any other services needed (Security Groups can always be modified afterward). We have gone over this step in the past two workloads so it should be familar if you need a refresher you can take a look at the instructions [here](https://github.com/kura-labs-org/AWS-EC2-Quick-Start-Guide/blob/main/AWS%20EC2%20Quick%20Start%20Guide.pdf).

We are going to be doing something different this time for installing jenkins. Instead of installing jenkins manually we will be creating a script to do this for us.

1. The first thing we want to do in our script is check if jenkins is already installed. We can use the dkpg command to list out all of the installed packages on our system and then pipe this over to our grep command to searches for the word "jenkins" in the list. The -q flag makes grep run in quiet mode. 

    ```
    if dpkg -l | grep -q jenkins; then
    ```
2. If Jenkins is installed we want to check if jenkins is running.

    ```
    if systemctl is-active --quiet jenkins; then
    ```
    * **systemctl is-active jenkins:** Checks if the Jenkins service is running.

    * **--quiet:** Suppresses output. It only returns the exit status (0 if active, non-zero otherwise).
3. If Jenkins is running we can print an output message letting the user know. Otherwise, we will want to start Jenkins if it's not running.

    ```
    else
        echo "Jenkins is not running."
        echo "Starting jenkins.."
        sudo systemctl start jenkins
        sudo systemctl status jenkins
    fi
    ```
4. Ok if jenkins is not installed in the first place we will need to install it.

5. Update System and Install Dependencies

    ```
    sudo apt update && sudo apt install fontconfig openjdk-17-jre software-properties-common -y
    ```
    * **apt update:** Updates the list of available packages.
    * **apt install fontconfig openjdk-17-jre software-properties-common:** Installs necessary dependencies for Jenkins (e.g., Java).
6. Add a repository to install Python 3.9.
Install Python 3.9 and its venv module for virtual environments
    ```
    sudo add-apt-repository ppa:deadsnakes/ppa -y
    sudo apt install python3.9 python3.9-venv -y
    ```
7. Download the Jenkins GPG key, required to verify the authenticity of the Jenkins package.

    ```
    sudo wget -O /usr/share/keyrings/jenkins-keyring.asc https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key
    ```
8. Add Jenkins to the Package List

    ```
    echo "deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc]" https://pkg.jenkins.io/debian-stable binary/ | sudo tee /etc/apt/sources.list.d/jenkins.list > /dev/null
    ```
9. Install jenkins

    ```
    sudo apt-get update
    sudo apt-get install jenkins -y
    ```
10. Start the Jenkins service and print its status to the console.

    ```
    sudo systemctl start jenkins
    sudo systemctl status jenkins
    ```

If everything looks good then we should be able to move on. If you like to see the final script (jenkins_install.sh) it is located in the root directory of the project. 

**Configure Application Server:**

We should already have python, venv installed from running the jenkins_install script but lets make sure we have the correct verions set. 

1. Run the following command to check the version.

    ```
    python3 --version
    ```
2. If python Python 3.9 is not the default version you need to update the alternatives system: 

    ```
    sudo update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.9 2
    ```
3. Then, configure the default Python version:

    ```
    sudo update-alternatives --config python3
    ```
4. Check the Python version to ensure it's now set to Python 3.9:

    ```
    python3 --version
    ```
5. Once Python 3.9 is installed, you might need to install pip for Python 3.9:

    ```
    sudo apt install python3.9-distutils
    wget https://bootstrap.pypa.io/get-pip.py
    python3.9 get-pip.py
    ```
6. You can check that you have the correct version of pip by running the following:

    ```
    pip3 --version
    ```
Now that we have 'python3.9', 'python3.9-venv' and 'python3-pip' installed let's install and configure Nginx. If you recall from the last workload Nginx is a web server and reverse proxy server. We will need to run Nginx to forward client requests to our backend gunicorn server. Our gunicorn server is our application server that actually processes the request. 

1. Update the Package List: Before installing, update your package list to ensure you get the latest version of Nginx:

    ```
    sudo apt update
    ```
2. Install Nginx: Install Nginx with the following command:

    ```
    sudo apt install nginx -y
    ```
3. Edit the NginX configuration file at "/etc/nginx/sites-enabled/default" so that "location" reads as below.

    ```
    location / {
    proxy_pass http://127.0.0.1:5000;
    proxy_set_header Host $host;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }
    ```

The Nginx configuration file defines the default behavior of the Nginx web server, such as which directory to serve static files from, how to handle HTTP requests, and how to forward requests to other services like gunicorn. In the preceding block of code we are setting up a reverse proxy. Nginx will accept incoming HTTP requests and forward them to another server—in this case, our Flask app running on http://127.0.0.1:5000 (localhost on port 5000). The Flask app will process the request and send the response back to Nginx, which in turn sends it back to the client.

4. Start Nginx:

    ```
    sudo systemctl start nginx
    ```
5. Enable Nginx to Start at Boot: To ensure Nginx starts automatically when the server is rebooted, enable the service:

    ```
    sudo systemctl enable nginx
    ```
6. Check Nginx Status: You can check if Nginx is running with:

    ```
    sudo systemctl status nginx
    ```

**Write Our Unit test:**

1. Create a python script called test_app.py to run a unit test of the application source code. IMPORTANT: Put the script in a directory called "tests/unit/" of the GitHub repository.

2. Set up our imports:

    ```
    import pytest
    from microblog import app
    from app import db
    from app.models import User
    ```

* **import pytest:** Imports the pytest testing framework, which is used to create and run unit tests.
* **from microblog import app:** Imports the Flask app object from the microblog module.
* **from app import db:** Imports the db object, which is the SQLAlchemy instance used for database interactions.
* **from app.models import User:** Imports the User model from the app.models module, representing users in our app.

3. Setup Test Client Fixture. The client fixture creates a test client for sending HTTP requests to the Flask application.

    ```
    @pytest.fixture
    def client():
    app.config['SQLALCHEMY_DATABASE_URI'] = 'sqlite:///:memory:'
    app.config['TESTING'] = True
    with app.test_client() as client:
        with app.app_context():
            db.create_all()  # Create tables for the database
            yield client      # Provide the test client to the tests
            db.session.rollback()  # Clean up after the test
            db.drop_all()          # Drop all tables after test completes
    ```

* **SQLite In-Memory Database:** Configures the app to use an in-memory SQLite database for isolated testing.
* **Testing Mode:** Enables the TESTING mode in Flask, which provides better error handling.
* **Database Setup:** Creates and drops the database schema before and after each test to ensure a clean environment.

4. Let's Write our first test!

    ```
    def test_redirect(client):
        response = client.get('/', follow_redirects=True)
        assert response.status_code == 200
        assert b'<title>Sign In - Microblog</title>' in response.data
    ```
* **GET Request:** Sends a GET request to the root URL (/) of the app.
* **Follow Redirects:** Ensures that any redirects are followed.
* **Assertions:** Verifies that the status code is 200 and the HTML response contains the expected page title (Sign In).

This should be good for now. If you take a look at the test_app.py module in the project, you’ll notice I have an additional test with some helper methods. In the test client fixture, we are setting up an in-memory database using SQLite. This allows us to write tests that involve adding and retrieving records from a database, similar to how our application would behave in production.

Using an in-memory database removes the dependency on an actual database instance. Since in-memory databases like SQLite are created and run entirely in memory, they are much faster. Additionally, tests are isolated because each test run gets a fresh, empty database. This ensures that tests don’t interfere with one another.

For more details, feel free to explore the test_app.py module. Otherwise, go through the following step to run the test we create together:

1. Clone your GH repository to the server, cd into the directory, create and activate a python virtual environment with:

    ```
    $python3.9 -m venv venv
    $source venv/bin/activate
    ```
2. While in the python virtual environment, install the application dependencies and other packages by running:

    ```
    $pip install -r requirements.txt
    $pip install gunicorn pymysql cryptography
    ```
3. Set the Pythonpath environment variable 
    ```
    export PYTHONPATH=$(pwd)
    ```

    The export PYTHONPATH=$(pwd) command is necessary to ensure that Python can find our project's modules when running scripts or tests from the command line.

4. From the root directory of the project run the test.
    ```
    pytest -s tests/unit/test_app.py
    ```

    We are incorporating the -s flag because it allows pytest to output to the console anything that your tests print, such as print() statements, which is useful for debugging. Normally, pytest captures and suppresses output, but the -s flag disables that capture, allowing you to see all printed output while running tests.

## Create Multibranch Pipeline

**Write Our Jenkins PipelineScript:**

The first step in creating our jenkins pipeline is creating our jenkins pipeline script. We can see that some of the work is already done for us but we will be responsible for filling out the build and deploy stages. 

**The build Stage**

The build stage should include all of the commands required to prepare the environment for the application. This includes creating the virtual environment and installing all the dependencies, setting variables, and setting up the databases. In order to do this we will need the following:

```
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
```
Most of these commands should be familiar from the previous workloads but there are some differences.

* **pip install gunicorn pymysql cryptography:** Installs additional packages not listed in requirements.txt.

* **export FLASK_APP=microblog.py:**
    * **export:** Sets an environment variable for the current shell session.
    * **FLASK_APP=microblog.py:** Specifies the entry point for the Flask application. This tells Flask to use microblog.py as the main application file.
* **flask translate compile:** If our Flask app supports multiple languages and you have translation files (like .po files) that need to be turned into a format Flask can use (like .mo files), this command does that job. It "compiles" the translation files so your app can display text in different languages correctly.

* **flask db upgrade**: If there are changes to how our app stores data (like adding new tables or fields), this command applies those changes to the actual database. It makes sure the database is up-to-date with the latest structure and ready to use.

**The Test Stage**

The test stage in our pipeline script can stay the same for the most part. We do need to activate our virtual environment and create an environment variable for the python path before running our test. Our test stage will end up looking like this:

```
sh '''#!/bin/bash
source venv/bin/activate
export PYTHONPATH=$(pwd)
py.test ./tests/unit/ --verbose --junit-xml test-reports/results.xml
'''
```

**The OWASP FS SCAN Stage**

The OWASP Dependency-Check plugin is used for identifying known vulnerabilities in the libraries and dependencies that your software project uses. It looks at the libraries and frameworks your project uses and compares them against a database of known vulnerabilities (e.g., from the National Vulnerability Database (NVD)). If any of the dependencies have known vulnerabilities, it alerts you so you can address them.

**Benefits**

* **Improved Security:** Helps you identify and address security vulnerabilities in your project’s dependencies before they can be exploited.

* **Proactive Risk Management:** Enables you to manage risks by staying informed about the security status of your dependencies.

* **Compliance:** Helps ensure compliance with security standards and best practices by integrating vulnerability checks into your development workflow.

1. Access the Jenkins web interface. We have done this a few times now but if you need a refresher you can refer back to workload 1 [here](https://github.com/tjwkura5/retail-banking-app-deployed-elastic-beanstalk).
2. In Jenkins, install the "OWASP Dependency-Check" plug-in

    a. Navigate to "Manage Jenkins" > "Plugins" > "Available plugins" > Search and install

    b. Then configure it by navigating to "Manage Jenkins" > "Tools" > "Add Dependency-Check > Name: "DP-Check" > check "install automatically" > Add Installer: "Install from github.com"

3. Vist the National Vulnerability Database [website](https://nvd.nist.gov/developers/request-an-api-key) and sign up for an API key. This will save you a lot of time later on. The NVD public API, has very strict rate limits for anonymous users. As a result, it will take a long time to get updates. Sigining up for an API key is quick and free and it will make this stage much faster.

4. Add your API key to the jenkins pipeline script.

    ```
    dependencyCheck additionalArguments: '--scan ./ --disableYarnAudit --disableNodeAudit --nvdApiKey <API_KEY>', odcInstallation: 'DP-Check'
    dependencyCheckPublisher pattern: '**/dependency-check-report.xml'
    ```

**The Clean Stage**

So for this stage we just want a script to find and stop a running gunicorn process. This script should first locate the process ID using pgrep, checks if a valid PID is found, save the PID to a file, and then terminate the process. If no gunicorn process is found, just print a corresponding message.

```
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
```

**The Deploy Stage**

This stage is trickiest, we need to run the commands required to deploy the application so that it is available to the internet.

## Setting up Prometheus and Grafana

## Issues/Troubleshooting

## Optimization

## Conclusion 
