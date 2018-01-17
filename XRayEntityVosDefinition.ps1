<# https://gallery.technet.microsoft.com/scriptcenter/ea40c1ef-c856-434b-b8fb-ebd7a76e8d91#content #>
$ConfigFile = Get-IniContent $PSScriptRoot"\config.ini"

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
            "summary" = $this.name + "(Created during importing ranorex result using REST at " + $([Constants]::currentDate) + ")";
            "description" = "This execution is automatically created when importing execution results from an external source";
            "version" = [Constants]::projectVersion;
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


class XrayTestPlanEntityVo{
    [XrayTestEntityVo[]]$testVos
    [XrayTestSetEntityVo[]]$testSetVos
    [string]$key

    XrayTestPlanEntityVo($testVos, $testSetVos){
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

    [XrayTestEntityVo[]] getTestVos(){
        [XrayTestEntityVo[]]$vos = @()
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
                "summary" = "Created during Ranorex-XRay Integration using REST at " + $([Constants]::currentDate);
                "description" = "Created during Ranorex-XRay Integration using REST at " + $([Constants]::currentDate);
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
                "summary" = "Created during Ranorex-XRay Integration using REST at " + $([Constants]::currentDate);
                "description" = "Created during Ranorex-XRay Integration using REST at " + $([Constants]::currentDate);
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

class XrayTestEntityVo
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
      
    XrayTestEntityVo([Fields]$fields){
        $this.fields = $fields
    }

    static [XrayTestEntityVo] getInstance()
    { 
        return [XrayTestEntityVo]::new([Fields]::new([Project]::new([Constants]::projectKey), "summary for " + ++[XrayTestEntityVo]::count + " at " + $(get-date -f MM-dd-yyyy_HH_mm_ss), "desc for " + [XrayTestEntityVo]::count + " at " + $([Constants]::currentDate), [IssueType]::new("Test"), [TestType]::new("Generic"), "generic test definition"));
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
    static [string]$projectVersion = $ConfigFile["project"]["version"];
    static [string]$reportFilePath = $ConfigFile["report"]["filepath"];
    static [string]$currentDateFormat = "dd-MMM-yyyy HH:mm:ss";
    static [string]$currentDate = $(Get-Date).ToString([Constants]::currentDateFormat);
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