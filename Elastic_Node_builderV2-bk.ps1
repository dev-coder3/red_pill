#Elastic Node builder
<#
VERSION Warning 8.10.2 ONLY 

Have either the elasticsearch zip unziped and stored like this C:\elasticsearch-8.10.2 with the next folder down being the config,bin and log folders.
Or allow this to download and go through the full script

Idea #2 
    Have all zips downloaded and unziped at the start ? CHECK
#>

$download = Read-Host -Prompt "Do you need to download the elasticsearch zip? yes / no"

if ($download -eq "yes"){
    Write-Host "Preparing to download and install Elasticsearch..." -ForegroundColor Cyan

    Invoke-WebRequest "https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-8.10.2-windows-x86_64.zip" -OutFile "elasticsearch-8.10.2-windows-x86_64.zip" | Out-Null 

    $foldername =  "elasticsearch-8.10.2"

    Expand-Archive -Path "elasticsearch-8.10.2-windows-x86_64.zip" -DestinationPath $foldername | Out-Null 

    $a = Get-ChildItem $foldername

    Get-Item $foldername\* -Include $a | Move-Item -Destination "$ENV:SystemDrive\$foldername"

    Write-Host "Preparing to download and install Kibana..." -ForegroundColor Cyan

    Invoke-WebRequest "https://artifacts.elastic.co/downloads/kibana/kibana-8.10.2-windows-x86_64.zip" -OutFile "kibana-8.10.2-windows-x86_64.zip" | Out-Null 

    $folder = ".\kibana-8.10.2-windows-x86_64"

    Expand-Archive -Path ".\kibana-8.10.2-windows-x86_64.zip" -DestinationPath $foldername| Out-Null 

    $a  = Get-ChildItem $folder
    
    Copy-Item "$folder\$a" -Recurse -Destination "$env:SystemDrive\$a" -ErrorAction SilentlyContinue | Out-Null # This Kina fixes the issue 
}

Write-Host "Preparing to install Elasticsearch..." -ForegroundColor Cyan

$Option = Read-Host -Prompt 'Which node are you wanting to build? master / data'

if ($Option -eq 'master') {
    Write-Host "Setting Configurations for MASTER Node" -ForegroundColor Cyan

    $clusterName = Read-Host "Enter cluster name" 
    $nodeName = Read-Host "Enter node name"
    $networkHost = Read-Host "Enter network host"
    $contentToAdd = @"
# ======================== Elasticsearch Configuration =========================
#
# NOTE: Elasticsearch comes with reasonable defaults for most settings.
#       Before you set out to tweak and tune the configuration, make sure you
#       understand what are you trying to accomplish and the consequences.
#
# The primary way of configuring a node is via this file. This template lists
# the most important settings you may want to configure for a production cluster.
#
# Please consult the documentation for further information on configuration options:
# https://www.elastic.co/guide/en/elasticsearch/reference/index.html
#
# ---------------------------------- Cluster -----------------------------------
#
# Use a descriptive name for your cluster:
#
cluster.name: $clusterName
#
# ------------------------------------ Node ------------------------------------
#
# Use a descriptive name for the node:
#
node.name: $nodeName
#
# Add custom attributes to the node:
#
#node.attr.rack: r1
#
# ----------------------------------- Paths ------------------------------------
#
# Path to directory where to store the data (separate multiple locations by comma):
#
#path.data: /path/to/data
#
# Path to log files:
#
#path.logs: /path/to/logs
#
# ----------------------------------- Memory -----------------------------------
#
# Lock the memory on startup:
#
#bootstrap.memory_lock: true
#
# Make sure that the heap size is set to about half the memory available
# on the system and that the owner of the process is allowed to use this
# limit.
#
# Elasticsearch performs poorly when the system is swapping the memory.
#
# ---------------------------------- Network -----------------------------------
#
# By default Elasticsearch is only accessible on localhost. Set a different
# address here to expose this node on the network:
#
network.host: $networkHost
#
# By default Elasticsearch listens for HTTP traffic on the first free port it
# finds starting at 9200. Set a specific HTTP port here:
#
#http.port: 9200
#
# For more information, consult the network module documentation.
#
# --------------------------------- Discovery ----------------------------------
#
# Pass an initial list of hosts to perform discovery when this node is started:
# The default list of hosts is ["127.0.0.1", "[::1]"]
#
#discovery.seed_hosts: ["host1", "host2"]
#
# Bootstrap the cluster using an initial set of master-eligible nodes:
#
cluster.initial_master_nodes: ["$nodeName"]
#
# For more information, consult the discovery and cluster formation module documentation.
#
# ---------------------------------- Various -----------------------------------
#
# Allow wildcard deletion of indices:
#
#action.destructive_requires_name: false 
"@
    $foldername =  "elasticsearch-8.10.2"
    $yamlFilePath = "$ENV:SystemDrive\$foldername\config\elasticsearch.yml"
    $contentToAdd | Set-Content -Path $yamlFilePath
    Write-Host "YAML file has been personalized."

    write-host "Now running elasticseach.bat"

    $workingDirectory = "$ENV:SystemDrive\$foldername\bin"
    
    Start-Process -FilePath "cmd.exe" -WorkingDirectory $workingDirectory -ArgumentList "/c elasticsearch.bat"
    
    Write-Host "DO NOT WORRY. This is a built in sleep for time for the installation of elasticsearch"
    start-sleep -s 120

    Write-Host "Has the Install finished from the cmd.exe window"
    write-host""
    Read-Host "If so press enter. If NOT do nothing......"

    Start-Process -FilePath "cmd.exe" -WorkingDirectory $workingDirectory -ArgumentList "/c elasticsearch-service.bat install"
    
    start-sleep -s 10
    
    Start-Process -FilePath "cmd.exe" -WorkingDirectory $workingDirectory -ArgumentList "/c elasticsearch-service.bat start"
    
    Set-Service -Name elasticsearch-service-x64 -StartupType Automatic
    
    Write-Host "Changing the auto generated password..."

    Write-Host ""

    start-sleep -s 10

    Start-Process -FilePath "cmd.exe" -WorkingDirectory $workingDirectory -ArgumentList "/c elasticsearch-reset-password.bat -u elastic -i"

    start-sleep -s 10
    Write-Host "Setting Configurations for Kibana" -ForegroundColor DarkRed
    
    $ip = Read-Host "Enter IP of elastic"

    $a = "https://" + $ip+ ":9200"

$contentToAdd = @"

"@
$foldername =  "kibana-8.10.2"
$yamlFilePath = "$ENV:SystemDrive\$foldername\config\kibana.yml"
$contentToAdd | Set-Content -Path $yamlFilePath
Write-Host "YAML file has been personalized for KIBANA."

} 
























elseif ($Option -eq 'data') {

    Write-Host "Setting Configurations DATA Node" -ForegroundColor Cyan
    write-host ""
    Write-Host "Creating ONLY ELASTICSEARCH" -ForegroundColor DarkRed
    Write-Host ""
    $clusterName = Read-Host "Enter cluster name" 
    $nodeName = Read-Host "Enter node name"
    $networkHost = Read-Host "Enter network host"
    #Only for data node
    $masterNode = Read-Host "Master node name"
    $contentToAdd = @"

# ======================== Elasticsearch Configuration =========================
#
# NOTE: Elasticsearch comes with reasonable defaults for most settings.
#       Before you set out to tweak and tune the configuration, make sure you
#       understand what are you trying to accomplish and the consequences.
#
# The primary way of configuring a node is via this file. This template lists
# the most important settings you may want to configure for a production cluster.
#
# Please consult the documentation for further information on configuration options:
# https://www.elastic.co/guide/en/elasticsearch/reference/index.html
#
# ---------------------------------- Cluster -----------------------------------
#
# Use a descriptive name for your cluster:
#
cluster.name: $clusterName
#
# ------------------------------------ Node ------------------------------------
#
# Use a descriptive name for the node:
#
node.name: $nodeName
#
# Add custom attributes to the node:
#
#node.attr.rack: r1
#
# ----------------------------------- Paths ------------------------------------
#
# Path to directory where to store the data (separate multiple locations by comma):
#
#path.data: /path/to/data
#
# Path to log files:
#
#path.logs: /path/to/logs
#
# ----------------------------------- Memory -----------------------------------
#
# Lock the memory on startup:
#
#bootstrap.memory_lock: true
#
# Make sure that the heap size is set to about half the memory available
# on the system and that the owner of the process is allowed to use this
# limit.
#
# Elasticsearch performs poorly when the system is swapping the memory.
#
# ---------------------------------- Network -----------------------------------
#
# By default Elasticsearch is only accessible on localhost. Set a different
# address here to expose this node on the network:
#
network.host: $networkHost
#
# By default Elasticsearch listens for HTTP traffic on the first free port it
# finds starting at 9200. Set a specific HTTP port here:
#
#http.port: 9200
#
# For more information, consult the network module documentation.
#
# --------------------------------- Discovery ----------------------------------
#
# Pass an initial list of hosts to perform discovery when this node is started:
# The default list of hosts is ["127.0.0.1", "[::1]"]
#
#discovery.seed_hosts: ["host1", "host2"]
#
# Bootstrap the cluster using an initial set of master-eligible nodes:
#
cluster.initial_master_nodes: ["$masterNode"]
#
# For more information, consult the discovery and cluster formation module documentation.
#
# ---------------------------------- Various -----------------------------------
#
# Allow wildcard deletion of indices:
#
#action.destructive_requires_name: false 
"@
    $foldername =  "elasticsearch-8.10.2"
    $yamlFilePath = "$ENV:SystemDrive\$foldername\config\elasticsearch.yml"
    $contentToAdd | Set-Content -Path $yamlFilePath

    Write-Host "YAML file has been personalized."

    write-host "Now running elasticseach.bat"

    $workingDirectory = "$ENV:SystemDrive\elasticsearch-8.10.2\bin"
    
    Start-Process -FilePath "cmd.exe" -WorkingDirectory $workingDirectory -ArgumentList "/c elasticsearch.bat"
    
    start-sleep -s 30
    
    Start-Process -FilePath "cmd.exe" -WorkingDirectory $workingDirectory -ArgumentList "/c elasticsearch-service.bat install"
    
    start-sleep -s 5
    
    Start-Process -FilePath "cmd.exe" -WorkingDirectory $workingDirectory -ArgumentList "/c elasticsearch-service.bat start"
    
    Set-Service -Name elasticsearch-service-x64 -StartupType Automatic
    
    Write-Host "Changing the auto generated password..."

    Start-Process -FilePath "cmd.exe" -WorkingDirectory $workingDirectory -ArgumentList "/c elasticsearch-reset-password.bat -u elastic -i"
        
}
