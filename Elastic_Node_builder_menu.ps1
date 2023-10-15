#Elastic Node builder
<#
VERSION Warning 8.10.2 ONLY 

WARNING this ONLY works with a one (1) master node NOT two(2) master nodes

Have either the elasticsearch zip unziped and stored like this C:\elasticsearch-8.10.2 with the next folder down being the config,bin and log folders.

"IF YOU HAVE RUN THIS SCRIPT BEFORE"
"You require a fresh install (Overwrite the files with non used ones)"

Make sure you have openssl installed. 
https://slproweb.com/download/Win64OpenSSL_Light-3_1_3.exe
maybe using start process 
#>

using namespace System.Management.Automation.Host

function Get-Configuration_elasticsearch {
    $foldername =  "elasticsearch-8.10.2"
        $yamlFilePath = "$ENV:SystemDrive\$foldername\config\elasticsearch.yml"
        $contentToAdd | Set-Content -Path $yamlFilePath
        Write-Host "YAML file has been personalized."
    
        write-host "Now running elasticseach.bat"
    
        $workingDirectory = "$ENV:SystemDrive\$foldername\bin"
        
        Start-Process -FilePath "cmd.exe" -WorkingDirectory $workingDirectory -ArgumentList "/c elasticsearch.bat"
        # make the sleep a loop every 10 secs to print the same message
        # Trying to stop error happening with starting service that doesn't exsist
        Write-Host ""
        Write-Host "DO NOT WORRY. This is a built in sleep for time for the installation of elasticsearch"
        start-sleep -s 60
        Write-Host ""
        Write-Host "Has the Install finished from the cmd.exe window"
        write-host""
        $answer = Read-Host "If so, press Enter. If NOT, type 'no' and press Enter..."

        if ($answer -eq "no") {
            Write-Host "Waiting for 30 seconds..."
            Start-Sleep -Seconds 30
        }

    
        Start-Process -FilePath "cmd.exe" -WorkingDirectory $workingDirectory -ArgumentList "/c elasticsearch-service.bat install"
    
        start-sleep -s 10
        write-host ""
        write-host "Checking........" -ForegroundColor Yellow
        #Making sure that the service is installed. Only using if not as it saves on the code relibility
        $service_name = "elasticsearch-service-x64"
        $service_checker = get-service -name "elasticsearch-service-x64" -ErrorAction SilentlyContinue
        if (-not $service_checker) {
            $service_name + " is not installed on this computer."
            write-host "Re-trying install of the service"
            Start-Process -FilePath "cmd.exe" -WorkingDirectory $workingDirectory -ArgumentList "/c elasticsearch-service.bat install"
        }
        start-sleep -s 10
        Start-Process -FilePath "cmd.exe" -WorkingDirectory $workingDirectory -ArgumentList "/c elasticsearch-service.bat start"
        Set-Service -Name elasticsearch-service-x64 -StartupType Automatic
        Write-Host "Changing the auto generated password..."
        Write-Host ""
        start-sleep -s 10
        Start-Process -FilePath "cmd.exe" -WorkingDirectory $workingDirectory -ArgumentList "/c elasticsearch-reset-password.bat -u elastic -i" 
        # User needs to remember the password as currently I dont save outputs because I dont want too
    }

function Get-download_Elastic{
    Write-Host "Preparing to download and install Elasticsearch..." -ForegroundColor Cyan
    Invoke-WebRequest "https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-8.10.2-windows-x86_64.zip" -OutFile "elasticsearch-8.10.2-windows-x86_64.zip" | Out-Null 
    $foldername =  "elasticsearch-8.10.2"
    Expand-Archive -Path "elasticsearch-8.10.2-windows-x86_64.zip" -DestinationPath $foldername | Out-Null 
    $a = Get-ChildItem $foldername
    Get-Item $foldername\* -Include $a | Move-Item -Destination "$ENV:SystemDrive\$foldername"
    
}
function Get-download_Kibana{
    Write-Host "Preparing to download and install Kibana..." -ForegroundColor Cyan
    Invoke-WebRequest "https://artifacts.elastic.co/downloads/kibana/kibana-8.10.2-windows-x86_64.zip" -OutFile "kibana-8.10.2-windows-x86_64.zip" | Out-Null 
    $folder = ".\kibana-8.10.2-windows-x86_64"
    Expand-Archive -Path ".\kibana-8.10.2-windows-x86_64.zip" -DestinationPath $foldername| Out-Null # Error handling with the files not being found. Non-issue
    $a  = Get-ChildItem $folder
    Copy-Item "$folder\$a" -Recurse -Destination "$env:SystemDrive\$a" -ErrorAction SilentlyContinue | Out-Null # This Kina fixes the issue. Failing to copy files to new location. Non-issue
}
function Get-cleanup_action {
    Remove-Item -Path "kibana-8.10.2-windows-x86_64.zip" -ErrorAction SilentlyContinue | Out-Null
    Remove-Item -Path "elaticsearch-8.10.2-windows-x86_64.zip" -ErrorAction SilentlyContinue | Out-Null
    Remove-Item -Path "kibana-8.10.2" -Recurse -ErrorAction SilentlyContinue | Out-Null
    Remove-Item -Path "elaticsearch-8.10.2" -Recurse -ErrorAction SilentlyContinue | Out-Null
}
function Get-openssl{
    # List of potential installation paths
$opensslPaths = @(
    "C:\Program Files",
    "C:\Program Files (x86)",
    "C:\"
)
# Initialize a global variable to store the OpenSSL path
$global:opensslInstallationPath = $null
# Iterate through potential paths and search for OpenSSL
foreach ($path in $opensslPaths) {
    if (Test-Path -Path $path -PathType Container) {
        $opensslPath = Get-ChildItem $path -Recurse -Filter 'openssl.exe' | Select-Object -First 1 -ExpandProperty DirectoryName
        if ($opensslPath -ne $null) {
            $global:opensslInstallationPath = $opensslPath
            break  # Found OpenSSL, no need to continue searching
        }
    }
}
$workingDirectory = $global:opensslInstallationPath
Start-Process -FilePath "cmd.exe" -WorkingDirectory $workingDirectory -ArgumentList "/c openssl req -x509 -newkey rsa:4096 -keyout `"C:\kibana-8.10.2\config\root-ca.key`" -out `"C:\kibana-8.10.2\config\root-ca.crt`" -days 3650"


}

function Get-Cleanup {
    [CmdletBinding()]
    param(
        [string]$Question = "Do you need to clean up the system?"
    )
    $yes = [ChoiceDescription]::new('&yes', 'Cleaning up system')
    $no = [ChoiceDescription]::new('&no',  'Not cleaning Up system')
    
    $options = [ChoiceDescription[]]($yes, $no)
    $result = $host.ui.PromptForChoice($Title, $Question, $options, 1)

    switch ($result) {
        0 { 'Cleaning up System'
        #When complete clean up
        Get-cleanup_action
    }
        1 {'No cleaning up system'
        write-host "Complete" -ForegroundColor Green}
    }
}
function New-Menu {
    [CmdletBinding()]
    param(
        [string]$Question = "Building Master or Data Node?"
    )
    $master = [ChoiceDescription]::new('&Master', 'Setting up master node')
    $data = [ChoiceDescription]::new('&Data',  'Setting up Data node')
    
    $options = [ChoiceDescription[]]($master, $data)
    $result = $host.ui.PromptForChoice($Title, $Question, $options, 0)

    switch ($result) {
        0 { 'Creating Master Node'
        $download = Read-Host -Prompt "Do you need to download the elasticsearch zip? yes / no"
        if ($download -eq "yes"){Get-download_Elastic}
        $download = Read-Host -Prompt "Do you need to download the Kibana zip? yes / no"
        if ($download -eq "yes"){Get-download_Kibana}
        write-host ""
        Write-Host "Setting Configurations for MASTER Node" -ForegroundColor Cyan

        $clusterName = Read-Host "Enter cluster name 'Default(dev)'"
        if ([string]::IsNullOrWhiteSpace($clusterName)) {
            $clusterName = "dev"
        }
        $nodeName = Read-Host "Enter node name 'Default(Master01)'"
        if ([string]::IsNullOrWhiteSpace($nodeName)) {
            $nodeName = "Master01"
        }
        $networkHost = Read-Host "Enter network host 'Default(0.0.0.0)'"
        if ([string]::IsNullOrWhiteSpace($networkHost)) {
            $networkHost = "0.0.0.0"
        }
       
        Write-Host "Cluster Name: $clusterName"
        Write-Host "Node Name: $nodeName"
        Write-Host "Network Host: $networkHost"
        
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
#
# Allow wildcard deletion of indices:
#
#action.destructive_requires_name: false 
"@
Get-Configuration_elasticsearch
   
        Write-Host "SERVICE TOKEN TIME" -f Green
        Write-Host ""
        Write-Host "Are you ready to continue ?"
        write-host""
        $answer = Read-Host "If so, press Enter. If NOT, type 'no' and press Enter..."

        if ($answer -eq "no") {
            Write-Host "Waiting for 30 seconds..."
            Start-Sleep -Seconds 30
        }
        $foldername =  "elasticsearch-8.10.2"
        $workingDirectory = "$ENV:SystemDrive\$foldername\bin"
# You only have one chance to get this correct MAKE THE CHANCE COUNT
        $filePath = "$ENV:SystemDrive\Token.log"
        $command = "elasticsearch-service-tokens create elastic/kibana AuthToken"

        Start-Process -FilePath "cmd.exe" -ArgumentList "/c $command > $filePath" -WorkingDirectory $workingDirectory -Wait

# Read the content of the text file
$content = Get-Content -Path $filePath -Raw

# Define a regular expression pattern to match continuous alphanumeric strings
$pattern = "[a-zA-Z0-9]+"

# Find all matches of the pattern in the content
$matches_reg = [regex]::Matches($content, $pattern)

# Initialize variables to store the longest string and its length
$longestString = ""
$longestStringLength = 0

# Loop through the matches and find the longest one
foreach ($match in $matches_reg) {
    if ($match.Length -gt $longestStringLength) {
        $longestString = $match.Value
        $longestStringLength = $match.Length
    }
}
# Save the longest string as a variable
$longestString

    start-sleep -s 10
    $token = $longestString
   
    $ip = Read-Host "Enter IP address for kibana 'Default(0.0.0.0)'"
        if ([string]::IsNullOrWhiteSpace($ip)) {
            $ip = "0.0.0.0"
        }
    Write-Host "IP Address: $ip"
    $a = "https://" + $ip+ ":9200" 
#since the IP is a varable doesn't pass correctly
# Add the kibana.yml file once the corrected config is in place. 
# Need to get a working config first I have got 80% of what I need 
# Missing points are the SSL (https) and the external conectivity
Get-openssl
$contentToAdd = @"
# For more configuration options see the configuration guide for Kibana in
# https://www.elastic.co/guide/index.html

# =================== System: Kibana Server ===================
# Kibana is served by a back end server. This setting specifies the port to use.
server.port: 5601

# Specifies the address to which the Kibana server will bind. IP addresses and host names are both valid values.
# The default is 'localhost', which usually means remote machines will not be able to connect.
# To allow connections from remote users, set this parameter to a non-loopback address.
server.host: "$networkHost"

# Enables you to specify a path to mount Kibana at if you are running behind a proxy.
# Use the `server.rewriteBasePath` setting to tell Kibana if it should remove the basePath
# from requests it receives, and to prevent a deprecation warning at startup.
# This setting cannot end in a slash.
#server.basePath: ""

# Specifies whether Kibana should rewrite requests that are prefixed with
# `server.basePath` or require that they are rewritten by your reverse proxy.
# Defaults to `false`.
#server.rewriteBasePath: false

# Specifies the public URL at which Kibana is available for end users. If
# `server.basePath` is configured this URL should end with the same basePath.
#server.publicBaseUrl: ""

# The maximum payload size in bytes for incoming server requests.
#server.maxPayload: 1048576

# The Kibana server's name. This is used for display purposes.
server.name: "$nodeName"

# =================== System: Kibana Server (Optional) ===================
# Enables SSL and paths to the PEM-format SSL certificate and SSL key files, respectively.
# These settings enable SSL for outgoing requests from the Kibana server to the browser.
#server.ssl.enabled: false
server.ssl.certificate: C:\kibana-8.10.2\config\root-ca.crt
server.ssl.key: C:\kibana-8.10.2\config\root-ca.key

# =================== System: Elasticsearch ===================
# The URLs of the Elasticsearch instances to use for all your queries.
elasticsearch.hosts: ["$a"]

# If your Elasticsearch is protected with basic authentication, these settings provide
# the username and password that the Kibana server uses to perform maintenance on the Kibana
# index at startup. Your Kibana users still need to authenticate with Elasticsearch, which
# is proxied through the Kibana server.
#elasticsearch.username: "kibana_system"
#elasticsearch.password: "pass"

# Kibana can also authenticate to Elasticsearch via "service account tokens".
# Service account tokens are Bearer style tokens that replace the traditional username/password based configuration.
# Use this token instead of a username/password.
elasticsearch.serviceAccountToken: "$token"

# Time in milliseconds to wait for Elasticsearch to respond to pings. Defaults to the value of
# the elasticsearch.requestTimeout setting.
#elasticsearch.pingTimeout: 1500

# Time in milliseconds to wait for responses from the back end or Elasticsearch. This value
# must be a positive integer.
#elasticsearch.requestTimeout: 30000

# The maximum number of sockets that can be used for communications with elasticsearch.
# Defaults to `Infinity`.
#elasticsearch.maxSockets: 1024

# Specifies whether Kibana should use compression for communications with elasticsearch
# Defaults to `false`.
#elasticsearch.compression: false

# List of Kibana client-side headers to send to Elasticsearch. To send *no* client-side
# headers, set this value to [] (an empty list).
#elasticsearch.requestHeadersWhitelist: [ authorization ]

# Header names and values that are sent to Elasticsearch. Any custom headers cannot be overwritten
# by client-side headers, regardless of the elasticsearch.requestHeadersWhitelist configuration.
#elasticsearch.customHeaders: {}

# Time in milliseconds for Elasticsearch to wait for responses from shards. Set to 0 to disable.
#elasticsearch.shardTimeout: 30000

# =================== System: Elasticsearch (Optional) ===================
# These files are used to verify the identity of Kibana to Elasticsearch and are required when
# xpack.security.http.ssl.client_authentication in Elasticsearch is set to required.
#elasticsearch.ssl.certificate: /path/to/your/client.crt
#elasticsearch.ssl.key: /path/to/your/client.key

# Enables you to specify a path to the PEM file for the certificate
# authority for your Elasticsearch instance.
#elasticsearch.ssl.certificateAuthorities: [ "/path/to/your/CA.pem" ]

# To disregard the validity of SSL certificates, change this setting's value to 'none'.
elasticsearch.ssl.verificationMode: none

# =================== System: Logging ===================
# Set the value of this setting to off to suppress all logging output, or to debug to log everything. Defaults to 'info'
#logging.root.level: debug

# Enables you to specify a file where Kibana stores log output.
#logging.appenders.default:
#  type: file
#  fileName: /var/logs/kibana.log
#  layout:
#    type: json

# Logs queries sent to Elasticsearch.
#logging.loggers:
#  - name: elasticsearch.query
#    level: debug

# Logs http responses.
#logging.loggers:
#  - name: http.server.response
#    level: debug

# Logs system usage information.
#logging.loggers:
#  - name: metrics.ops
#    level: debug

# =================== System: Other ===================
# The path where Kibana stores persistent data not saved in Elasticsearch. Defaults to data
#path.data: data

# Specifies the path where Kibana creates the process ID file.
#pid.file: /run/kibana/kibana.pid

# Set the interval in milliseconds to sample system and process performance
# metrics. Minimum is 100ms. Defaults to 5000ms.
#ops.interval: 5000

# Specifies locale to be used for all localizable strings, dates and number formats.
# Supported languages are the following: English (default) "en", Chinese "zh-CN", Japanese "ja-JP", French "fr-FR".
#i18n.locale: "en"

# =================== Frequently used (Optional)===================

# =================== Saved Objects: Migrations ===================
# Saved object migrations run at startup. If you run into migration-related issues, you might need to adjust these settings.

# The number of documents migrated at a time.
# If Kibana can't start up or upgrade due to an Elasticsearch `circuit_breaking_exception`,
# use a smaller batchSize value to reduce the memory pressure. Defaults to 1000 objects per batch.
#migrations.batchSize: 1000

# The maximum payload size for indexing batches of upgraded saved objects.
# To avoid migrations failing due to a 413 Request Entity Too Large response from Elasticsearch.
# This value should be lower than or equal to your Elasticsearch cluster's `http.max_content_length`
# configuration option. Default: 100mb
#migrations.maxBatchSizeBytes: 100mb

# The number of times to retry temporary migration failures. Increase the setting
# if migrations fail frequently with a message such as `Unable to complete the [...] step after
# 15 attempts, terminating`. Defaults to 15
#migrations.retryAttempts: 15

# =================== Search Autocomplete ===================
# Time in milliseconds to wait for autocomplete suggestions from Elasticsearch.
# This value must be a whole number greater than zero. Defaults to 1000ms
#unifiedSearch.autocomplete.valueSuggestions.timeout: 1000

# Maximum number of documents loaded by each shard to generate autocomplete suggestions.
# This value must be a whole number greater than zero. Defaults to 100_000
#unifiedSearch.autocomplete.valueSuggestions.terminateAfter: 100000

"@
$foldername =  "kibana-8.10.2"
$yamlFilePath = "$ENV:SystemDrive\$foldername\config\kibana.yml"
$contentToAdd | Set-Content -Path $yamlFilePath
Write-Host "YAML file has been personalized for KIBANA."


    } # End of master option
        1 { 'Steps for data node' 
        $download = Read-Host -Prompt "Do you need to download the elasticsearch zip? yes / no"
        if ($download -eq "yes"){Get-download_Elastic}
        Write-Host "Setting Configurations DATA Node" -ForegroundColor Cyan
        write-host ""
        Write-Host "Creating ONLY ELASTICSEARCH" -ForegroundColor DarkRed
        Write-Host ""

        $clusterName = Read-Host "Enter cluster name 'Default(dev)'"
        if ([string]::IsNullOrWhiteSpace($clusterName)) {
            $clusterName = "dev"
        }
        $nodeName = Read-Host "Enter node name 'Default(Data01)'"
        if ([string]::IsNullOrWhiteSpace($nodeName)) {
            $nodeName = "Data01"
        }
        $networkHost = Read-Host "Enter network host 'Default(0.0.0.0)'"
        if ([string]::IsNullOrWhiteSpace($networkHost)) {
            $networkHost = "0.0.0.0"
        }
        $masterNode = Read-Host "Master node name 'Default(Master01)'"
        if ([string]::IsNullOrWhiteSpace($masterNode)) {
            $masterNode = "Master01"
        }
        Write-Host "Cluster Name: $clusterName"
        Write-Host "Node Name: $nodeName"
        Write-Host "Network Host: $networkHost"
        Write-Host "Master Node: $MasterNose"

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
    Get-Configuration_elasticsearch

    } # End of Data option
    }
} # End of menu function
# Calling the menu function. I do like this design.
Write-Host ""
New-Menu 
write-host ""
Get-cleanup
Invoke-Expression "services.msc"
