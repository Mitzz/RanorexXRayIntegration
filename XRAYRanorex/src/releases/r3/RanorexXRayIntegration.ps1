Function Get-IniContent {  
    <#  
    .Synopsis  
        Gets the content of an INI file  
          
    .Description  
        Gets the content of an INI file and returns it as a hashtable  
          
    .Notes  
        Author        : Oliver Lipkau <oliver@lipkau.net>  
        Blog        : http://oliver.lipkau.net/blog/  
        Source        : https://github.com/lipkau/PsIni 
                      http://gallery.technet.microsoft.com/scriptcenter/ea40c1ef-c856-434b-b8fb-ebd7a76e8d91 
        Version        : 1.0 - 2010/03/12 - Initial release  
                      1.1 - 2014/12/11 - Typo (Thx SLDR) 
                                         Typo (Thx Dave Stiff) 
          
        #Requires -Version 2.0  
          
    .Inputs  
        System.String  
          
    .Outputs  
        System.Collections.Hashtable  
          
    .Parameter FilePath  
        Specifies the path to the input file.  
          
    .Example  
        $FileContent = Get-IniContent "C:\myinifile.ini"  
        -----------  
        Description  
        Saves the content of the c:\myinifile.ini in a hashtable called $FileContent  
      
    .Example  
        $inifilepath | $FileContent = Get-IniContent  
        -----------  
        Description  
        Gets the content of the ini file passed through the pipe into a hashtable called $FileContent  
      
    .Example  
        C:\PS>$FileContent = Get-IniContent "c:\settings.ini"  
        C:\PS>$FileContent["Section"]["Key"]  
        -----------  
        Description  
        Returns the key "Key" of the section "Section" from the C:\settings.ini file  
          
    .Link  
        Out-IniFile  
    #>  
      
    [CmdletBinding()]  
    Param(  
        [ValidateNotNullOrEmpty()]  
        [ValidateScript({(Test-Path $_) -and ((Get-Item $_).Extension -eq ".ini")})]  
        [Parameter(ValueFromPipeline=$True,Mandatory=$True)]  
        [string]$FilePath  
    )  
      
    Begin  
        {Write-Verbose "$($MyInvocation.MyCommand.Name):: Function started"}  
          
    Process  
    {  
        Write-Verbose "$($MyInvocation.MyCommand.Name):: Processing file: $Filepath"  
              
        $ini = @{}  
        switch -regex -file $FilePath  
        {  
            "^\[(.+)\]$" # Section  
            {  
                $section = $matches[1]  
                $ini[$section] = @{}  
                $CommentCount = 0  
            }  
            "^(;.*)$" # Comment  
            {  
                if (!($section))  
                {  
                    $section = "No-Section"  
                    $ini[$section] = @{}  
                }  
                $value = $matches[1]  
                $CommentCount = $CommentCount + 1  
                $name = "Comment" + $CommentCount  
                $ini[$section][$name] = $value  
            }   
            "(.+?)\s*=\s*(.*)" # Key  
            {  
                if (!($section))  
                {  
                    $section = "No-Section"  
                    $ini[$section] = @{}  
                }  
                $name,$value = $matches[1..2]  
                $ini[$section][$name] = $value  
            }  
        }  
        Write-Verbose "$($MyInvocation.MyCommand.Name):: Finished Processing file: $FilePath"  
        Return $ini  
    }  
          
    End  
        {Write-Verbose "$($MyInvocation.MyCommand.Name):: Function ended"}  
}

<# --------------------------------------------------------------------------- #>
<# https://gallery.technet.microsoft.com/scriptcenter/ea40c1ef-c856-434b-b8fb-ebd7a76e8d91#content #>
$ConfigPath = Join-Path -Path $PSScriptRoot -ChildPath "config.ini" -Resolve
Write-Host "Config File Path: " $configPath
$ConfigFile = Get-IniContent $ConfigPath

class XrayTestExecutionEntityVo{
    [string]$name
    [string]$startDate
    [string]$endDate
    [XrayTestPlanEntityVo]$testPlanVo
    

    XrayTestExecutionEntityVo($name, $startDate, $endDate, [XrayTestPlanEntityVo]$testPlanVo){
        $this.name = $name
        $this.startDate = $startDate
        $this.endDate = $endDate
        $this.testPlanVo = $testPlanVo
    }

    create(){
        $url = [Constants]::url + "raven/1.0/import/execution"
        $tests = @()
        foreach ($test in $this.testPlanVo.getTestVos()) {
            $status = $test.getStatus()
            $comment = $test.getComment()
            #Write-Host $status
            $obj = @{
                "testKey" = $test.key;
                "start" = $null;
                "finish"= $null;
                "comment" = $comment;
                "status" = $status;
            }
            
            $tests = $tests + $obj

        }

        $body = @{
            "info" = @{
            "summary" = $this.name + [Constants]::message;
            "description" = "This execution is automatically created when importing execution results from an external source";
            #"version" = [Constants]::projectVersion;
            "user" = "qtp";
            #"revision" = "Revision Number";
            "startDate" = $this.startDate;
            "finishDate" = $this.endDate;
            "testPlanKey" = $this.testPlanVo.key;
            #"testEnvironments" = @("Env1", "Env2")
          };
          "tests" = $tests
        }
        Write-Host "Test Execution Creation Started."
        $response = [RestApi]::post($url, $body)
        $responseContent = ConvertFrom-Json ($response.Content)
		Write-Host $("Test Execution created with key '" + $responseContent.testExecIssue.key + "'")

    }
}


class XrayTestPlanEntityVo{
    [XrayTestEntityVo[]]$testVos
    [XrayTestSetEntityVo[]]$testSetVos
    [string]$key

    XrayTestPlanEntityVo([XrayTestEntityVo[]]$testVos, [XrayTestSetEntityVo[]]$testSetVos){
        $this.testVos = $testVos
        $this.testSetVos = $testSetVos
    }

    XrayTestPlanEntityVo([string]$key){
        $this.key = $key
    }

    XrayTestPlanEntityVo([XrayTestEntityVo[]]$testVos){
        $this.testVos = $testVos
    }

    setTestVos([XrayTestEntityVo[]]$testVos){
        $this.testVos = $testVos
    }

    [string[]] getKeys(){
        [string[]]$keys = @()
        foreach($vo in $this.testVos) {
            $keys = $keys + $vo.key
        }

        if($this.testSetVos -ne $null){
            foreach($vo in $this.testSetVos) {
                $keys = $keys + $vo.getTestKeys()
            }
        }
        return $keys
    }

    [XrayTestEntityVo[]] getTestVos(){
        [XrayTestEntityVo[]]$vos = @()
        foreach($vo in $this.testVos) {
            $vos = $vos + $vo
        }

        if($this.testSetVos -ne $null){
            foreach($vo in $this.testSetVos) {
                $vos = $vos + $vo.getTestVos()
            }
        }
        return $vos
    }
	
	[object[]] getAssociatedTest(){
		$url = [Constants]::url + "raven/1.0/api/testplan/" + $this.key + "/test"
        $response = [RestApi]::get($url) 
    	$responseContent = ConvertFrom-Json ($response.Content)
        return $responseContent
	}

    [boolean] exist(){
        $url = [Constants]::url + "raven/1.0/api/testplan/" + $this.key + "/test"
        try { 
            $response = [RestApi]::get($url)
            Write-Host "Test Plan Key ("$this.key") exist"
            return $true
        } catch {
            $response = $_.Exception.Response.StatusCode.Value__
            return $false
        }
	}
	
	[string[]] getAssociatedTestKeys(){
		$associatedTests = $this.getAssociatedTest();
		[string[]] $keys = @();
		foreach($associatedTest in $associatedTests){
			$keys = $keys + $associatedTest.key;
		}
		return $keys;
	}

    [string[]] getRemainingKeys(){
        [string[]]$givenKeys = $this.getKeys();
        [string[]]$associatedKeys = $this.getAssociatedTestKeys();
        [string[]]$remainingKeys = @()

        foreach($givenKey in $givenKeys){
            if(-not $associatedKeys.Contains($givenKey)){
                $remainingKeys = $remainingKeys + $givenKey;
            }
        }

        return $remainingKeys;
    }

    update(){
        $newTestKeys = $this.getRemainingKeys();
        if($newTestKeys.Count -ne 0){
            Write-Host "Updating test plan"
            $url = [Constants]::url + "raven/1.0/api/testplan/" + $this.key + "/test"
            $body = @{
                "add" = $newTestKeys
            }
            [RestApi]::post($url, $body)
        }
    }

    persist(){
        if($this.exist()){
            $this.update()
        } else {
            $this.create()
        }
    }

    create(){
        $url = [Constants]::url + "api/2/issue"
		$body = @{
			fields = @{
				"project" = @{
					"key" = [Constants]::projectKey
				};
				"summary" = [Constants]::message;
				"description" = [Constants]::message;
				"issuetype" = @{
					"name" = "Test Plan"
					};
				"customfield_10424" = $this.getKeys()
				}
			}
		Write-Host "Test Plan Creation Started."
		$response = [RestApi]::post($url, $body)
		$responseContent = ConvertFrom-Json ($response.Content)
		$this.key = $responseContent.key
		Write-Host "Test Plan created with Key '" $this.key "'"
    }
	
	[boolean] allTestAssociated(){
		$associatedTestKeys = $this.getAssociatedTestKeys();
		return $true;
		
	}
}

class XrayTestSetEntityVo{
    [XrayTestEntityVo[]]$tests
    [string]$key

    XrayTestSetEntityVo([XrayTestEntityVo[]]$tests){
        $this.tests = $tests
    }

    [XrayTestEntityVo[]] getTestVos(){
        return $this.tests
    }

    create(){
        $url = [Constants]::url + "api/2/issue"
        $testKey = @()

        foreach ($test in $this.tests) {
            $test.save()
            $testKey = $testKey + $test.key;
        }

        $body = @{
            fields = @{
                "project" = @{
                    "key" = [Constants]::projectKey
                };
                "summary" = [Constants]::message;
                "description" = [Constants]::message;
                "issuetype" = @{
                    "name" = "Test Set"
                 };
                "customfield_10410" = $testKey
             }
         }
         
        Write-Host "Test Set Creation Started."
        $response = [RestApi]::post($url, $body)
        $responseContent = ConvertFrom-Json ($response.Content)
        $this.key = $responseContent.key
        Write-Host "Test Set Creation Done."
    }

    [string[]] getTestKeys(){
        $keys = @()
        foreach($vo in $this.tests) {
            $keys = $keys + $vo.key
        }
        return $keys
    }
}

class XrayTestEntityVo
{
    [string]$summary;
    [string]$description;
    [string]$testType;
    [string]$key;
    [string]$id;
    [string]$self;
    static [int]$count;
    [string]$status;
    <#[string]$start;
    [string]$finish;#>
    [string]$comment;
      
    XrayTestEntityVo([string]$summary, [string]$description){
        $this.summary = $summary;
        $this.description = $description;
		$this.testType = "Generic";
    }

    
    create(){
        $vo = @{
            "fields" = @{
                "project" = @{
                    "key" = [Constants]::projectKey;
                };
                "summary" = $this.summary;
                "description" = $this.description + " " + [Constants]::message;
                "issuetype" = @{
                    "name" = "Test";
                };
                "customfield_10400" = @{
                    "value" = "Generic";
                };
                "customfield_10403" = "Generic test definition";
				"customfield_11514" = $this.summary;
            };
        }

        $response = [RestApi]::post([Constants]::url + "api/2/issue", $vo)
        $responseContent = ConvertFrom-Json ($response.Content)
        $this.id = $responseContent.id
        $this.key = $responseContent.key
        $this.self = $responseContent.self
        Write-Host "Test Created with key "$this.key"." 
        $this.changeWorkflowStatus(11)
        
    }
	
	[boolean]exist(){
		$jql = $("project = " + [Constants]::projectKey + " AND issuetype = 'Test' AND `"Script Name`" ~ `"" + $this.description + "`"");
        $url = [Constants]::url + "api/2/search?jql=" + $jql;
        $response = [RestApi]::get($url)
	    $responseContent = ConvertFrom-Json ($response.Content)
        foreach($issue in $responseContent.issues){
            $fields = $issue.fields;
            $scriptName = $fields.customfield_11514;
            if($scriptName -eq $this.description){
				$this.key = $issue.key;
                $this.id = $issue.id;
                return $true;   
            }
            
        }
        return $false;
    }

    [string]getComment(){
        return $this.comment;
    }

    setComment([string]$comment){
        $this.comment = $comment
    }

    setStatus([string]$status){
        $this.status = $status
    }

    [string]getStatus(){
        #$this.status = $status
        If ($this.status -eq 'Success')  {
            return 'PASS'
        } ElseIf($this.status -eq 'Ignored') {
            return 'TODO'
        } ElseIf($this.status -eq 'Failed') {
            return 'FAIL'
        }
        return $null
    }

    changeWorkflowStatus([int]$transitionId){
        $url = [Constants]::url + "api/2/issue/$($this.key)/transitions?expand=transitions.fields"
        $body = @{
            transition = @{
                id = $transitionId
            }
        }
        Write-Host "Test Transition Started." 
        $response = [RestApi]::post($url, $body) 
	    #$responseContent = ConvertFrom-Json ($response.Content)
        Write-Host "Test Transition Done."
    }
}

class RestApi{

    [object]static post($url, $body){
        return [RestApi]::rest($url, "Post", $body);
    }

    [object]static get($url){
        return [RestApi]::rest($url, "Get", $null);
    }

    [object]static rest($url, $method, $body){
        $Headers = @{
		    Authorization = [Credentials]::getEncodedValue()
	    }
        [Credentials]::setProtocols()
        $response = $null;
        <#Write-Host $url
        Write-Host $(ConvertTo-Json $body -Depth 99)
        Write-Host $method#>
        if($method -eq "Post"){
            $response = Invoke-WebRequest -Uri $url -Headers $Headers -Method $method -Body (ConvertTo-Json $body -Depth 99) -ContentType "application/json" 
        } elseif($method -eq "Get"){
            $response = Invoke-WebRequest -Uri $url -Headers $Headers -Method $method 
	    }
	    return $response;
    }

}

class Constants{
    
    static [string]$url = $ConfigFile["server"]["url"] + "/rest/";
    static [string]$projectKey = $ConfigFile["project"]["key"];
    static [string]$projectVersion = $ConfigFile["project"]["version"];
    static [string]$reportFilePath = $ConfigFile["report"]["filepath"];
    static [string]$currentDateFormat = "dd-MMM-yyyy HH:mm:ss";
    static [string]$currentDate = $(Get-Date).ToString([Constants]::currentDateFormat);
	static [string]$testPlanKey = $ConfigFile["jira"]["testplankey"];
    static [string]$testsuiteDateformat = $ConfigFile["report"]["testsuite-dateformat"];
    static [string]$message = "(Created during importing Ranorex results at " + $(Get-Date).ToString([Constants]::currentDateFormat) + ")"

    static Reload(){
        [Constants]::url = $global:ConfigFile["server"]["url"] + "/rest/";
        [Constants]::projectKey = $global:ConfigFile["project"]["key"];
        [Constants]::projectVersion = $global:ConfigFile["project"]["version"];
        [Constants]::reportFilePath = $global:ConfigFile["report"]["filepath"];
        [Constants]::testPlanKey = $global:ConfigFile["jira"]["testplankey"];
        [Constants]::testsuiteDateformat = $global:ConfigFile["report"]["testsuite-dateformat"];

    }

    static [boolean]isTestPlanGiven(){
		if([Constants]::testPlanKey -eq $null -or [Constants]::testPlanKey -eq ""){
			return $false;
		} else {
			return $true;
		}
		return $false;
	}

    static [string]getTestPlanKey(){
        return [Constants]::testPlanKey;
    }

    static [string]getProjectKey(){
        return [Constants]::projectKey;
    }
}

[Constants]::Reload()

class Credentials{
    static [string]$user = $ConfigFile["credentials"]["user"];
    static [string]$password = $ConfigFile["credentials"]["password"];
    
    static [string] getEncodedValue(){
        
        $pair = "$([Credentials]::user):$([Credentials]::password)"
        $encodedCreds = [System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($pair))
	    return "Basic $encodedCreds"
    }

    static setProtocols(){
add-type @"
using System.Net;
using System.Security.Cryptography.X509Certificates;
public class TrustAllCertsPolicy1 : ICertificatePolicy {
    public bool CheckValidationResult(
        ServicePoint srvPoint, X509Certificate certificate,
        WebRequest request, int certificateProblem) {
        return true;
    }
}
"@
$AllProtocols = [System.Net.SecurityProtocolType]'Ssl3,Tls,Tls11,Tls12'
[System.Net.ServicePointManager]::SecurityProtocol = $AllProtocols
[System.Net.ServicePointManager]::CertificatePolicy = New-Object TrustAllCertsPolicy1
    }

}

<# ---------------------------------------------------------------------------------------- #>
class RanorexXmlProcessor{
    [System.Xml.XmlDocument]$file
    [XrayTestEntityVo[]]$testVos = @()
    [XrayTestSetEntityVo[]]$testSetVos = @()
    [XrayTestPlanEntityVo]$testPlanVo
    [XrayTestExecutionEntityVo]$testExecutionVo

    [string]$startDate;
    [string]$endDate;
    [string]$suiteName;

    RanorexXmlProcessor($filePath){
        [System.Xml.XmlDocument]$this.file = new-object System.Xml.XmlDocument
        $this.file.load($filePath)
        $this.init()
    }

    init(){
        $this.PopulateSuiteInfo()
    }

    PopulateSuiteInfo(){
        $this.RootNodeHandler($this.file.SelectNodes("//activity[@type='root']"))
        $suiteNode = $this.file.SelectNodes("//activity[@type='root']/activity[@type='test-suite']")
        $this.TestSuiteNodeHandler($suiteNode)
    }

    TestSuiteNodeHandler($suiteNode){
        $this.suiteName = $suiteNode.testsuitename
    }

    RootNodeHandler($root_node){
        try {
            $dataStr = $root_node.timestamp
            $dateFormat = [Constants]::testsuiteDateformat
            $start = [datetime]::ParseExact($dataStr, $dateFormat, $null)
            $dataStr = $root_node.endtime
            $end = [datetime]::ParseExact($dataStr, $dateFormat, $null)

            $this.startDate = $start.ToString('s') + "+00:00"
            $this.endDate = $end.ToString('s') + "+00:00"
        } catch {
            throw $("Date Format '" + [Constants]::testsuiteDateformat + "' in config.ini file is not matching with the report")      
        }
    }

    [XrayTestEntityVo] handleTestCaseNode($testCaseNode){
        [XrayTestEntityVo]$testVo = [XrayTestEntityVo]::new($testCaseNode.testcontainername, $testCaseNode.testcontainername)
        $testVo.setStatus($testCaseNode.result)
        $comment = $this.getComment($testCaseNode)
        $testVo.setComment($comment)

        return $testVo
    }

    [XrayTestEntityVo[]] handleIterationContainerNode($iterationContainerNode){
        #Write-Host "Processing Iteration Container Node...."
        [XrayTestEntityVo[]]$testArr = @()
        [string]$activityType = "";
        foreach ($childNodeOfIterationContainer in $iterationContainerNode.ChildNodes) {
            $activityType = $childNodeOfIterationContainer.type
            if($activityType -eq 'test-case'){
                $testArr = $testArr + $this.handleTestCaseNode($childNodeOfIterationContainer)
            }
        }
        #Write-Host "Found: " + $testArr.Count
        return $testArr
    }

    [XrayTestEntityVo[]] handleSmartFolderNode($smartFolderNode){
        #Write-Host "Processing Smart Folder Node...."
        [XrayTestEntityVo[]]$testArr = @()
        [string]$activityType = "";
        foreach ($childNodeOfsmartFolder in $smartFolderNode.ChildNodes) {
            $activityType = $childNodeOfsmartFolder.type
            if($activityType -eq 'test-case'){
                $testArr = $testArr + $this.handleTestCaseNode($childNodeOfsmartFolder)
            } elseif ($activityType -eq 'iteration-container'){
                $testArr = $testArr + $this.handleIterationContainerNode($childNodeOfsmartFolder)
            } elseif ($activityType -eq 'smart-folder'){
                $testArr = $testArr + $this.handleSmartFolderNode($childNodeOfsmartFolder)
            }
        }
        #Write-Host "Found: " $testArr.Count
        return $testArr
    }

    CreateTestSetVos(){
        $this.testSetVos = @() 
        $smartFolderNodes= $this.file.SelectNodes("//activity[@type='test-suite']/activity[@type='smart-folder']")
        [int]$count = 0
        $activtyType = ''
        foreach ($smartFolderNode in $smartFolderNodes) {
            #Write-Host "Processing Next SmartFolder"
            $this.testSetVos = $this.testSetVos + [XrayTestSetEntityVo]::new($this.handleSmartFolderNode($smartFolderNode))
            #Write-Host "Finished"
        }

        foreach($testSet in $this.testSetVos){
            $this.testVos = $this.testVos + $testSet.getTestVos()
        }
    }

    SaveTestSetVos(){
        foreach ($testSetVo in $this.testSetVos) {
            #Write-Host "Creating Test Set with " $testSetVo.tests.Count " tests..." 
            $testSetVo.create()
            #Write-Host "Created Test Set with " $testSetVo.tests.Count " tests" 
        }
    }

    CreateTestVos(){
        $this.testVos = @()
        #Write-Host $this.testVos.Count
        $testSuiteChildNodes= $this.file.SelectNodes("//activity[@type='test-suite']/child::node()")
        $activityType = ''
        [int]$count = 0
        foreach ($testSuiteChildNode in $testSuiteChildNodes) {
            $activityType = $testSuiteChildNode.type
            #Write-Host "Activity Type under test suite " $activityType
            if($activityType -eq 'test-case'){
                #Write-Host $test_case_node.GetType() $test_case_node.testcontainername $test_case_node.iteration
                $this.testVos = $this.testVos + $this.handleTestCaseNode($testSuiteChildNode);
            } elseif($activityType -eq 'iteration-container'){
                foreach($t in $this.handleIterationContainerNode($testSuiteChildNode)){
                    #Write-Host $test_case_node.GetType() $test_case_node.testcontainername $test_case_node.iteration
                    $this.testVos = $this.testVos + $t;
                }
            }  
        }
        #Write-Host "Tests Count: " +  $this.testVos.Count
        
    }

    SaveTestVos(){
        foreach ($testVo in $this.testVos) {
            if(-Not $testVo.exist()){
                $testVo.create()
            } else {
                Write-Host "Test with description "$testVo.description"("$testVo.key") exist in JIRA"
            }
        }
    }

    CreateTestPlanVo(){
        if([Constants]::isTestPlanGiven()){
            $this.testPlanVo = [XrayTestPlanEntityVo]::new([Constants]::getTestPlanKey())
            $isTestPlanExist = $this.testPlanVo.exist()
            if(-not $isTestPlanExist){
                throw $("Given Test Plan Key(" + [Constants]::getTestPlanKey() + ") doest not exist in Project(" + [Constants]::getProjectKey() + ")") 
            }
            $this.testPlanVo.setTestVos($this.testVos)
        } else {
            $this.testPlanVo = [XrayTestPlanEntityVo]::new($this.testVos)
        }
    }

    SaveTestPlanVo(){
        $this.testPlanVo.persist()
    }

    CreateTestExecutionVo(){
        $this.testExecutionVo = [XrayTestExecutionEntityVo]::new($this.suiteName, $this.startDate, $this.endDate, $this.testPlanVo)
    }

    SaveTestExecutionVo(){
        $this.testExecutionVo.create()
    }
    
    [int]getTotalTestVos(){
        $count = 0
        $count = $this.testVos.Count;

        foreach($testSet in $this.testSetVos){
            $count = $count + $testSet.tests.Count
        }
        return $count
    }

    [string] getComment($test_case_node){
          $comment = $null;
          $result = $test_case_node.result;
          if($result -eq 'Failed') {
            $errormessage = $test_case_node.activity.errormessage;
            $comment = $errormessage
          } elseif($result -eq 'Success') {
            $comment = 'Execution Successful.'
          } elseif($result -eq 'Ignored') {
            $comment = 'Test Execution Ignored.'
          } else {
            $comment = 'Test Execution Status is Unknown.'
          }
          return $comment
    }

    

    execute(){
        $this.CreateTestVos();
        $this.CreateTestSetVos();
        $this.SaveTestVos();
        #$this.SaveTestSetVos();
        $this.CreateTestPlanVo();

        $this.SaveTestPlanVo();
        $this.CreateTestExecutionVo();
        $this.SaveTestExecutionVo();

    }
}



$vo = [RanorexXmlProcessor]::new([Constants]::reportFilePath)
Write-Host "Integration Started.."
$vo.execute()
Write-Host "Integration Done Successfully."