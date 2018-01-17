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
$configFilePath = "config.ini"
$configPath = Join-Path -Path $PSScriptRoot -ChildPath $configFilePath -Resolve
Write-Host "Config File Path: " $configPath
$ConfigFile = Get-IniContent $configPath

class XrayTestExecutorVo{
    [XrayTestPlanVo]$testPlanVo
    [string]$startDate
    [string]$endDate

    XrayTestExecutorVo([XrayTestPlanVo]$testPlanVo, $startDate, $endDate){
        $this.testPlanVo = $testPlanVo
        $this.startDate = $startDate
        $this.endDate = $endDate
    }

    create(){
        $url = [Constants]::url + "raven/1.0/import/execution"
        $Headers = @{
		    Authorization = [Credentials]::getEncodedValue()
	    }

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
            "summary" = "Created during importing ranorex result";
            "description" = "This execution is automatically created when importing execution results from an external source";
            "version" = "Version 2";
            "user" = "qtp";
            "revision" = "Revision Number";
            "startDate" = $this.startDate;
            "finishDate" = $this.endDate;
            "testPlanKey" = $this.testPlanVo.key;
            "testEnvironments" = @("Env1", "Env2")
          };
          "tests" = $tests
        }
        Write-Host (ConvertTo-Json $body)

        [Credentials]::setProtocols()
        Write-Host "Creating Test Execution Plan"
        $response = Invoke-WebRequest -Uri $url -Headers $Headers -Method Post -Body (ConvertTo-Json $body) -ContentType "application/json" 
	    #$responseContent = ConvertFrom-Json ($response.Content)
        Write-Host $response

    }
}


class XrayTestPlanVo{
    [XRayTestEntityVo[]]$testVos
    [XRayTestSetEntityVo[]]$testSetVos
    [string]$key

    XrayTestPlanVo($testVos, $testSetVos){
        $this.testVos = $testVos
        $this.testSetVos = $testSetVos
    }

    [string[]] getKeys(){
        [string[]]$keys = @()
        foreach($vo in $this.testVos) {
            $keys = $keys + $vo.key
        }

        foreach($vo in $this.testSetVos) {
            $keys = $keys + $vo.getTestKeys()
        }
        return $keys
    }

    [XRayTestEntityVo[]] getTestVos(){
        [XRayTestEntityVo[]]$vos = @()
        foreach($vo in $this.testVos) {
            $vos = $vos + $vo
        }

        foreach($vo in $this.testSetVos) {
            $vos = $vos + $vo.getTestVos()
        }
        return $vos
    }

    create(){
        $url = [Constants]::url + "api/2/issue"
        $Headers = @{
		    Authorization = [Credentials]::getEncodedValue()
	    }

        $body = @{
            fields = @{
                "project" = @{
                    "key" = [Constants]::projectKey
                };
                "summary" = "sumamry  at " + $(get-date -f MM-dd-yyyy_HH_mm_ss);
                "description" = "Test Plan using REST";
                "issuetype" = @{
                    "name" = "Test Plan"
                 };
                "customfield_10424" = $this.getKeys()
             }
         }
         ConvertTo-Json $body
        [Credentials]::setProtocols()
        Write-Host "Creating Test Plan...."
        $response = Invoke-WebRequest -Uri $url -Headers $Headers -Method Post -Body (ConvertTo-Json $body) -ContentType "application/json" 
	    $responseContent = ConvertFrom-Json ($response.Content)
        $this.key = $responseContent.key
        Write-Host $response
    }
}

class XRayTestSetEntityVo{
    [XRayTestEntityVo[]]$tests
    [string]$key

    XRayTestSetEntityVo([XRayTestEntityVo[]]$tests){
        $this.tests = $tests
    }

    [XRayTestEntityVo[]] getTestVos(){
        return $this.tests
    }

    create(){
        $url = [Constants]::url + "api/2/issue"
        $Headers = @{
		    Authorization = [Credentials]::getEncodedValue()
	    }
       
        $testKey = @()

        foreach ($test in $this.tests) {
            $test.save()
            $test.changeWorkflowStatus(11)
            $testKey = $testKey + $test.key;
        }

        $body = @{
            fields = @{
                "project" = @{
                    "key" = [Constants]::projectKey
                };
                "summary" = "Created at " + $(get-date -f MM-dd-yyyy_HH_mm_ss) + " during Ranorex-XRay Integration using REST";
                "description" = "Created at " + $(get-date -f MM-dd-yyyy_HH_mm_ss) + " during Ranorex-XRay Integration using REST";
                "issuetype" = @{
                    "name" = "Test Set"
                 };
                "customfield_10410" = $testKey
             }
         }
         ConvertTo-Json $body
        [Credentials]::setProtocols()
        Write-Host "Creating Test Set...."
        $response = Invoke-WebRequest -Uri $url -Headers $Headers -Method Post -Body (ConvertTo-Json $body) -ContentType "application/json" 
	    $responseContent = ConvertFrom-Json ($response.Content)
        $this.key = $responseContent.key
        Write-Host $response
    }

    [string[]] getTestKeys(){
        $keys = @()
        foreach($vo in $this.tests) {
            $keys = $keys + $vo.key
        }
        return $keys
    }
}

class XRayTestEntityVo
{
    [Fields]$fields;
    [string]$key;
    [string]$id;
    [string]$self;
    static [int]$count;
    [string]$status;
    <#[string]$start;
    [string]$finish;#>
    [string]$comment;
      
    XRayTestEntityVo([Fields]$fields){
        $this.fields = $fields
    }

    static [XRayTestEntityVo] getInstance()
    { 
        return [XRayTestEntityVo]::new([Fields]::new([Project]::new([Constants]::projectKey), "summary for " + ++[XRayTestEntityVo]::count + " at " + $(get-date -f MM-dd-yyyy_HH_mm_ss), "desc for " + [XRayTestEntityVo]::count + " at " + $(get-date -f MM-dd-yyyy_HH_mm_ss), [IssueType]::new("Test"), [TestType]::new("Generic"), "generic test definition"));
    }

    save(){
        $url = [Constants]::url + "api/2/issue"
        $Headers = @{
		    Authorization = [Credentials]::getEncodedValue()
	    }
        [Credentials]::setProtocols()
        Write-Host "Creating Test..."
        $response = Invoke-WebRequest -Uri $url -Headers $Headers -Method Post -Body (ConvertTo-Json $this) -ContentType "application/json" 
	    $responseContent = ConvertFrom-Json ($response.Content)
        $this.id = $responseContent.id
        $this.key = $responseContent.key
        $this.self = $responseContent.self
        Write-Host $response
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
        $Headers = @{
		    Authorization = [Credentials]::getEncodedValue()
	    }
        $body = @{
            transition = @{
                id = $transitionId
            }
        }
        [Credentials]::setProtocols()
        Write-Host "Test Transition" 
        $response = Invoke-WebRequest -Uri $url -Headers $Headers -Method Post -Body (ConvertTo-Json $body) -ContentType "application/json" 
	    #$responseContent = ConvertFrom-Json ($response.Content)
        Write-Host $response
    }
}

class Fields{
    [Project]$project;
    [string]$summary;
    [string]$description;
    [IssueType]$issuetype;
    [TestType]$customfield_10400;
    [string]$customfield_10403; 

    Fields(){
    }

    Fields([Project]$project, [string]$summary, [string]$description, [IssueType]$issuetype, [TestType]$customfield_10400, [string]$customfield_10403){
        $this.project = $project
        $this.summary = $summary
        $this.description = $description
        $this.issuetype = $issuetype
        $this.customfield_10400 = $customfield_10400
        $this.customfield_10403 = $customfield_10403
    }
}

class TestType{
    [string]$value;
    
    TestType([string]$value){
        $this.value = $value;
    }
}

class IssueType{
    [string]$name;

    IssueType([string]$name){
        $this.name = $name;
    }
}

class Project{
    [string]$key;

    Project([string]$key){
        $this.key = $key;
    }
}

class Constants{
    
    static [string]$url = $ConfigFile["server"]["url"] + "/rest/";
    static [string]$projectKey = $ConfigFile["project"]["key"];
    static [string]$reportFilePath = $ConfigFile["report"]["filepath"];

}

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
    [XRayTestEntityVo[]]$testVos = @()
    [XRayTestSetEntityVo[]]$testSetVos = @()
    [XrayTestPlanVo]$testPlanVo
    [XrayTestExecutorVo]$testExecutionVo

    [string]$startDate;
    [string]$endDate;

    RanorexXmlProcessor($filePath){
        [System.Xml.XmlDocument]$this.file = new-object System.Xml.XmlDocument
        $this.file.load($filePath)
        $this.init()
    }

    init(){
        $this.StartDateEndDate()
    }

    StartDateEndDate(){
        $root_node = $this.file.SelectNodes("//activity[@type='root']")
    
        $dataStr = $root_node.timestamp
        $dateFormat = "M/d/yyyy h:m:ss tt"
        $start = [datetime]::ParseExact($dataStr, $dateFormat, $null)

        $dataStr = $root_node.endtime
        $end = [datetime]::ParseExact($dataStr, $dateFormat, $null)

        $this.startDate = $start.ToString('s') + "+00:00"
        $this.endDate = $end.ToString('s') + "+00:00"

    }

    [XRayTestEntityVo] handleTestCaseNode($testCaseNode){
        $testFields = [Fields]::new()
        $testFields.description = $testCaseNode.testcontainername + " at " + $(get-date -f MM-dd-yyyy_HH_mm_ss)
        $testFields.summary = $testCaseNode.testcontainername + " at " + $(get-date -f MM-dd-yyyy_HH_mm_ss)
        $testFields.issuetype = [IssueType]::new("Test")
        $testFields.project = [Project]::new([Constants]::projectKey)
        $testFields.customfield_10400 = [TestType]::new("Generic")
        $testFields.customfield_10403 = "generic test definition"
        [XRayTestEntityVo]$testVo = [XRayTestEntityVo]::new($testFields)
        $testVo.setStatus($testCaseNode.result)
        $comment = $this.getComment($testCaseNode)
        $testVo.setComment($comment)

        return $testVo
    }

    [XRayTestEntityVo[]] handleIterationContainerNode($iterationContainerNode){
        Write-Host "Processing Iteration Container Node...."
        [XRayTestEntityVo[]]$testArr = @()
        [string]$activityType = "";
        foreach ($childNodeOfIterationContainer in $iterationContainerNode.ChildNodes) {
            $activityType = $childNodeOfIterationContainer.type
            if($activityType -eq 'test-case'){
                $testArr = $testArr + $this.handleTestCaseNode($childNodeOfIterationContainer)
            }
        }
        Write-Host "Found: " + $testArr.Count
        return $testArr
    }

    [XRayTestEntityVo[]] handleSmartFolderNode($smartFolderNode){
        Write-Host "Processing Smart Folder Node...."
        [XRayTestEntityVo[]]$testArr = @()
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
        Write-Host "Found: " $testArr.Count
        return $testArr
    }

    CreateTestSetVos(){
        $this.testSetVos = @() 
        $smartFolderNodes= $this.file.SelectNodes("//activity[@type='test-suite']/activity[@type='smart-folder']")
        [int]$count = 0
        $activtyType = ''
        foreach ($smartFolderNode in $smartFolderNodes) {
            Write-Host "Processing Next SmartFolder"
            $this.testSetVos = $this.testSetVos + [XRayTestSetEntityVo]::new($this.handleSmartFolderNode($smartFolderNode))
            Write-Host "Finished"
        }
    }

    SaveTestSetVos(){
        foreach ($testSetVo in $this.testSetVos) {
            Write-Host "Creating Test Set with " $testSetVo.tests.Count " tests..." 
            $testSetVo.create()
            Write-Host "Created Test Set with " $testSetVo.tests.Count " tests" 
        }
    }

    CreateTestVos(){
        $this.testVos = @()
        Write-Host $this.testVos.Count
        $testSuiteChildNodes= $this.file.SelectNodes("//activity[@type='test-suite']/child::node()")
        $activityType = ''
        $testFields = [Fields]::new()
        [int]$count = 0
        foreach ($testSuiteChildNode in $testSuiteChildNodes) {
            $activityType = $testSuiteChildNode.type
            Write-Host "Activity Type under test suite " $activityType
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
        Write-Host "Tests Count: " +  $this.testVos.Count
        
    }

    SaveTestVos(){
        foreach ($testVo in $this.testVos) {
            $testVo.save()
            $testVo.changeWorkflowStatus(11);
        }
    }

    CreateTestPlanVo(){
        $this.testPlanVo = [XrayTestPlanVo]::new($this.testVos, $this.testSetVos)
        
    }

    SaveTestPlanVo(){
        $this.testPlanVo.create()
    }

    CreateTestExecutionVo(){
        $this.testExecutionVo = [XrayTestExecutorVo]::new($this.testPlanVo, $this.startDate, $this.endDate)
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
        $this.CreateTestVos()
        $this.CreateTestSetVos()
        $this.SaveTestVos()
        $this.SaveTestSetVos()
        $this.CreateTestPlanVo();
        $this.SaveTestPlanVo()
        $this.CreateTestExecutionVo();
        $this.SaveTestExecutionVo()

    }
}

$vo = [RanorexXmlProcessor]::new([Constants]::reportFilePath)
