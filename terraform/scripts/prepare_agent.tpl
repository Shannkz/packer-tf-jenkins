<powershell>
#######################
# WINRM

write-output "Running User Data Script"
write-host "(host) Running User Data Script"

Set-ExecutionPolicy Unrestricted -Scope LocalMachine -Force -ErrorAction Ignore

# Don't set this before Set-ExecutionPolicy as it throws an error
$ErrorActionPreference = "stop"

# Remove HTTP listener
Remove-Item -Path WSMan:\Localhost\listener\listener* -Recurse

$Cert = New-SelfSignedCertificate -CertstoreLocation Cert:\LocalMachine\My -DnsName "packer"
New-Item -Path WSMan:\LocalHost\Listener -Transport HTTPS -Address * -CertificateThumbPrint $Cert.Thumbprint -Force

# WinRM
write-output "Setting up WinRM"
write-host "(host) setting up WinRM"

cmd.exe /c winrm quickconfig -q
cmd.exe /c winrm set "winrm/config" '@{MaxTimeoutms="1800000"}'
cmd.exe /c winrm set "winrm/config/winrs" '@{MaxMemoryPerShellMB="1024"}'
cmd.exe /c winrm set "winrm/config/service" '@{AllowUnencrypted="true"}'
cmd.exe /c winrm set "winrm/config/client" '@{AllowUnencrypted="true"}'
cmd.exe /c winrm set "winrm/config/service/auth" '@{Basic="true"}'
cmd.exe /c winrm set "winrm/config/client/auth" '@{Basic="true"}'
cmd.exe /c winrm set "winrm/config/service/auth" '@{CredSSP="true"}'
cmd.exe /c winrm set "winrm/config/listener?Address=*+Transport=HTTPS" "@{Port=`"5986`";Hostname=`"packer`";CertificateThumbprint=`"$($Cert.Thumbprint)`"}"
cmd.exe /c netsh advfirewall firewall set rule group="remote administration" new enable=yes
cmd.exe /c netsh firewall add portopening TCP 5986 "Port 5986"
cmd.exe /c net stop winrm
cmd.exe /c sc config winrm start= auto
cmd.exe /c net start winrm

###################
# Disable UAC
Write-Host "Disabling UAC..."
New-ItemProperty -Path HKLM:Software\Microsoft\Windows\CurrentVersion\Policies\System -Name EnableLUA -PropertyType DWord -Value 0 -Force
New-ItemProperty -Path HKLM:Software\Microsoft\Windows\CurrentVersion\Policies\System -Name ConsentPromptBehaviorAdmin -PropertyType DWord -Value 0 -Force

###################
# Install windows packages
# Setting Up machine for Jenkins
# Jenkins root directory
$jenkins_slave_path = "C:\Jenkins"
If(!(test-path $jenkins_slave_path))
{
    New-Item -ItemType Directory -Force -Path $jenkins_slave_path
}

# Install Chocolatey for managing installations
Set-ExecutionPolicy Bypass -Scope Process -Force; iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))

# Installing required packages
# "visualstudio2017-workload-webbuildtools" this will install a lot of packages including "visualstudiobuildtool"
# and "IIS"(and IIS will get you msdeploy) and "Microsoft Web Deploy 4" but make sure you configure IIS
# before installation, if you are doing deployment on same machine. Also install WebDeploy manually beforehand to match configuration with IIS
# You have been warned!

choco install git netcat openjdk11 nuget.commandline -y

# Make `refreshenv` available right away, by defining the $env:ChocolateyInstall
# variable and importing the Chocolatey profile module.
# Note: Using `. $PROFILE` instead *may* work, but isn't guaranteed to.
$env:ChocolateyInstall = Convert-Path "$((Get-Command choco).Path)\..\.."   
Import-Module "$env:ChocolateyInstall\helpers\chocolateyProfile.psm1"

# refreshenv is now an alias for Update-SessionEnvironment
# (rather than invoking refreshenv.cmd, the *batch file* for use with cmd.exe)
# This should make git.exe accessible via the refreshed $env:PATH, so that it
# can be called by name only.
refreshenv

#####################
# Agent setup
function Wait-For-Jenkins {

  Write-Host "Waiting jenkins to launch on 8080..."

  Do {
    Write-Host "Waiting for Jenkins"

    Nc -zv ${server_ip} 8080
    If( $? -eq $true ) {
      Break
    }
    Sleep 10

  } While (1)

  Do {
   Write-Host "Waiting for JNLP"
      
   Nc -zv ${server_ip} 33453
   If( $? -eq $true ) {
    Break
   }
   Sleep 10

  } While (1)      

  Write-Host "Jenkins launched"
}

function Slave-Setup()
{
  # Register_slave
  $JENKINS_URL="http://${server_ip}:8080"

  $USERNAME="${jenkins_username}"
  
  $PASSWORD="${jenkins_password}"

  $AUTH = -join ("$USERNAME", ":", "$PASSWORD")
  echo $AUTH

  # Below IP collection logic works for Windows Server 2016 edition and needs testing for windows server 2008 edition
  $SLAVE_IP=(ipconfig | findstr /r "[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*" | findstr "IPv4 Address").substring(39) | findstr /B "10.4"
  
  $NODE_NAME="jenkins-slave-windows-$SLAVE_IP"
  
  $NODE_SLAVE_HOME="C:\Jenkins\"
  $EXECUTORS=2
  $JNLP_PORT=33453

  $CRED_ID="$NODE_NAME"
  $LABELS="build windows"
  
  # Creating CMD utility for jenkins-cli commands
  # This is not working in windows therefore specify full path
  $jenkins_cmd = "java -jar C:\Jenkins\jenkins-cli.jar -s $JENKINS_URL -auth admin:$PASSWORD"

  Sleep 20

  Write-Host "Downloading jenkins-cli.jar file"
  (New-Object System.Net.WebClient).DownloadFile("$JENKINS_URL/jnlpJars/jenkins-cli.jar", "C:\Jenkins\jenkins-cli.jar")

  Write-Host "Downloading agent.jar file"
  (New-Object System.Net.WebClient).DownloadFile("$JENKINS_URL/jnlpJars/agent.jar", "C:\Jenkins\agent.jar")

  Sleep 10

  # Waiting for Jenkins to load all plugins
  Do {
  
    $count=(java -jar C:\Jenkins\jenkins-cli.jar -s $JENKINS_URL -auth $AUTH list-plugins | Measure-Object -line).Lines
    $ret=$?

    Write-Host "count [$count] ret [$ret]"

    If ( $count -gt 0 ) {
        Break
    }

    sleep 30
  } While ( 1 )

  # For Deleting Node, used when testing
  Write-Host "Deleting Node $NODE_NAME if present"
  java -jar C:\Jenkins\jenkins-cli.jar -s $JENKINS_URL -auth $AUTH delete-node $NODE_NAME
  
  # Generating node.xml for creating node on Jenkins server
  $NodeXml = @"
<slave>
<name>$NODE_NAME</name>
<description>Windows Slave</description>
<remoteFS>$NODE_SLAVE_HOME</remoteFS>
<numExecutors>$EXECUTORS</numExecutors>
<mode>NORMAL</mode>
<retentionStrategy class="hudson.slaves.RetentionStrategy`$Always`"/>
<launcher class="hudson.slaves.JNLPLauncher">
  <workDirSettings>
    <disabled>false</disabled>
    <internalDir>remoting</internalDir>
    <failIfWorkDirIsMissing>false</failIfWorkDirIsMissing>
  </workDirSettings>
</launcher>
<label>$LABELS</label>
<nodeProperties/>
</slave>
"@
  $NodeXml | Out-File -FilePath C:\Jenkins\node.xml 

  type C:\Jenkins\node.xml

  # Creating node using node.xml
  Write-Host "Creating $NODE_NAME"
  Get-Content -Path C:\Jenkins\node.xml | java -jar C:\Jenkins\jenkins-cli.jar -s $JENKINS_URL -auth $AUTH create-node $NODE_NAME

  Write-Host "Registering Node $NODE_NAME via JNLP"
  Start-Process java -ArgumentList "-jar C:\Jenkins\agent.jar -jnlpCredentials $AUTH -jnlpUrl $JENKINS_URL/computer/$NODE_NAME/slave-agent.jnlp"
}

### script begins here ###

Wait-For-Jenkins

Slave-Setup

echo "Done"
</powershell>