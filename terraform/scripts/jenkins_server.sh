#!/bin/bash

set -x

# Declare the admin pass var
jenkins_admin_password=""

# Check if the admin pass has been generated
INITIAL_PASS_FILE="/var/lib/jenkins/secrets/initialAdminPassword"

# Jenkins configuration file
jenkins_config_file="/etc/default/jenkins"

function wait_for_jenkins()
{
  while (( 1 )); do
      echo "waiting for Jenkins to launch on port [8080] ..."
      
      nc -zv 127.0.0.1 8080
      if (( $? == 0 )); then
          break
      fi

      sleep 10
  done

  echo "Jenkins launched"
}

function updating_jenkins_master_password ()
{
  cat > /tmp/jenkinsHash.py <<EOF
import bcrypt
import sys

if not sys.argv[1]:
  sys.exit(10)

encoded_string=sys.argv[1].encode('utf-8')
plaintext_pwd=sys.argv[1].encode('utf-8')
encrypted_pwd=bcrypt.hashpw(encoded_string, bcrypt.gensalt(rounds=10, prefix=b"2a"))
isCorrect=bcrypt.checkpw(plaintext_pwd, encrypted_pwd)

if not isCorrect:
  sys.exit(20);

print("{}".format(encrypted_pwd))
EOF

  chmod +x /tmp/jenkinsHash.py
  
  # Wait till /var/lib/jenkins/users/admin* folder gets created
  sleep 10

  cd /var/lib/jenkins/users/admin*
  pwd
  while (( 1 )); do
      echo "Waiting for Jenkins to generate admin user's config file ..."

      if [[ -f "./config.xml" ]]; then
          break
      fi

      sleep 10
  done

  echo "Admin config file created"

  # admin_password=$(python3 /tmp/jenkinsHash.py ${jenkins_admin_password} 2>&1)
  
  # Please do not remove alter quote as it keeps the hash syntax intact or else while substitution, $<character> will be replaced by null
  # xmlstarlet -q ed --inplace -u "/user/properties/hudson.security.HudsonPrivateSecurityRealm_-Details/passwordHash" -v '#jbcrypt:'"$admin_password" config.xml

  # Restart
  systemctl restart jenkins
  sleep 10
}

function install_packages ()
{
  wget -q -O - https://pkg.jenkins.io/debian-stable/jenkins.io.key | sudo apt-key add -
  sudo sh -c 'echo deb http://pkg.jenkins.io/debian-stable binary/ > /etc/apt/sources.list.d/jenkins.list'
  sudo apt-get update
  sudo apt-get install jenkins -y

  # firewall
  #firewall-cmd --permanent --new-service=jenkins
  #firewall-cmd --permanent --service=jenkins --set-short="Jenkins Service Ports"
  #firewall-cmd --permanent --service=jenkins --set-description="Jenkins Service firewalld port exceptions"
  #firewall-cmd --permanent --service=jenkins --add-port=8080/tcp
  #firewall-cmd --permanent --add-service=jenkins
  #firewall-cmd --zone=public --add-service=http --permanent
  #firewall-cmd --reload
  # systemctl enable jenkins
  # systemctl restart jenkins

  # Skip the wizard otherwise we cannot install plugins via CLI
  echo "
JAVA_ARGS=\"-Djenkins.install.runSetupWizard=false\"" >> $jenkins_config_file

  # cat $jenkins_config_file

  sudo systemctl start jenkins
  sleep 15

  while (( 1 )); do
    echo "waiting for initial password..."
    
    if [ -f "$INITIAL_PASS_FILE" ]; then
      echo '------------------------'
      echo 'Getting the initial Admin password...'
      jenkins_admin_password=$(cat /var/lib/jenkins/secrets/initialAdminPassword)
      break
    fi

    echo "${INITIAL_PASS_FILE} file not ready yet..."
    sleep 10
  done
}

function configure_jenkins_server ()
{
  # cp /var/cache/jenkins/war/WEB-INF/jenkins-cli.jar /var/lib/jenkins/jenkins-cli.jar

  # Getting initial password
  # PASSWORD=$(cat /var/lib/jenkins/secrets/initialAdminPassword)
  PASSWORD="${jenkins_admin_password}"
  sleep 10

  jenkins_dir="/var/lib/jenkins"
  plugins_dir="$jenkins_dir/plugins"

  cd $jenkins_dir

  # Jenkins cli
  echo "installing the Jenkins cli ..."
  wget http://localhost:8080/jnlpJars/jenkins-cli.jar

  # Open JNLP port
  xmlstarlet -q ed --inplace -u "/hudson/slaveAgentPort" -v 33453 config.xml

  cd $plugins_dir || { echo "unable to chdir to [$plugins_dir]"; exit 1; }

  # List of plugins that are needed to be installed 
  plugin_list="git-client git github-api github-oauth github MSBuild ssh-slaves workflow-aggregator ws-cleanup"

  # remove existing plugins, if any ...
  rm -rfv $plugin_list

  for plugin in $plugin_list; do
      echo "installing plugin [$plugin] ..."
      java -jar $jenkins_dir/jenkins-cli.jar -s http://127.0.0.1:8080/ -auth admin:$PASSWORD install-plugin $plugin
  done

  # Restart jenkins after installing plugins
  java -jar $jenkins_dir/jenkins-cli.jar -s http://127.0.0.1:8080 -auth admin:$PASSWORD safe-restart
}

### script starts here ###

install_packages

wait_for_jenkins

updating_jenkins_master_password

wait_for_jenkins

configure_jenkins_server

echo "Done"
exit 0