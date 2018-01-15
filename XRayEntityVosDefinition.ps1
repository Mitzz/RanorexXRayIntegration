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
        foreach ($test in $this.testPlanVo.tests) {
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

class XRayTestSetEntityVo{
    [XRayTestEntityVo[]]$tests
    [string]$key

    XRayTestSetEntityVo([XRayTestEntityVo[]]$tests){
        $this.tests = $tests
    }

    create(){
        $url = [Constants]::url + "api/2/issue"
        $Headers = @{
		    Authorization = [Credentials]::getEncodedValue()
	    }

        $testKey = @()

        foreach ($test in $this.tests) {
            $testKey = $testKey + $test.key;
        }

        $body = @{
            fields = @{
                "project" = @{
                    "key" = [Credentials]::projectKey
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
}

class XrayTestPlanVo{
    [string[]]$keys
    [string]$key

    XrayTestPlanVo([string[]]$keys){
        $this.keys = $keys
    }

    create(){
        $url = [Constants]::url + "api/2/issue"
        $Headers = @{
		    Authorization = [Credentials]::getEncodedValue()
	    }
        $body = @{
            fields = @{
                "project" = @{
                    "key" = [Credentials]::projectKey
                };
                "summary" = "sumamry  at " + $(get-date -f MM-dd-yyyy_HH_mm_ss);
                "description" = "Test Plan using REST";
                "issuetype" = @{
                    "name" = "Test Plan"
                 };
                "customfield_10424" = $this.keys
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
        return [XRayTestEntityVo]::new([Fields]::new([Project]::new([Credentials]::projectKey), "summary for " + ++[XRayTestEntityVo]::count + " at " + $(get-date -f MM-dd-yyyy_HH_mm_ss), "desc for " + [XRayTestEntityVo]::count + " at " + $(get-date -f MM-dd-yyyy_HH_mm_ss), [IssueType]::new("Test"), [TestType]::new("Generic"), "generic test definition"));
    }

    display(){
        Write-Host "Display"
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
    static [string]$url = "https://jerry-test.wincor-nixdorf.com/rest/";
}

class Credentials{
    static [string]$user = "bhansm";
    static [string]$password = "Mitz@#23mit";
    static [string]$projectKey = "PLAYTMSW";

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

<#$testVo1 = [XRayTestEntityVo]::getInstance()
$testVo2 = [XRayTestEntityVo]::getInstance()
$testVo3 = [XRayTestEntityVo]::getInstance()

$testVos = @()
$testVos = $testVos + $testVo1;
$testVos = $testVos + $testVo2;
$testVos = $testVos + $testVo3;

foreach($testVo in $testVos){
    <$testVo.save();
    $testVo.changeWorkflowStatus(11);
}

$testPlan = [XrayTestPlanVo]::new($testVos)
$testPlan.create()
$testExecution = [XrayTestExecutorVo]::new($testPlan)#>