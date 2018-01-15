. (Join-Path $PSScriptRoot XRayEntityVosDefinition.ps1) 

class RanorexXmlProcessor{
    [System.Xml.XmlDocument]$file
    [XRayTestEntityVo[]]$tests = @()
    [datetime]$startDate;
    [datetime]$endDate;

    RanorexXmlProcessor($filePath){
        [System.Xml.XmlDocument]$this.file = new-object System.Xml.XmlDocument
        $this.file.load("C:\Users\bhansm\Downloads\RanorexToXrayIntegration\Harald_SampleReports\testReport_HTML_junit\testReport\WebConsole_20171109_134715.html.data.xml")
    }

    StartDateEndDate(){
        $root_node = $this.file.SelectNodes("//activity[@type='root']")
    
        $dataStr = $root_node.timestamp
        $dateFormat = "M/d/yyyy h:m:ss tt"
        $this.startDate = [datetime]::ParseExact($dataStr, $dateFormat, $null)

        $dataStr = $root_node.endtime
        $this.endDate = [datetime]::ParseExact($dataStr, $dateFormat, $null)

        $this.startDate = $this.startDate.ToString('s') + "+00:00"
        $this.endDate = $this.endDate.ToString('s') + "+00:00"

    }

    CreateTestVos(){
        Write-Host $this.tests.Count
        $this.StartDateEndDate()

        $test_case_nodes= $this.file.SelectNodes("//activity[@type='test-case']")



        $testFields = [Fields]::new()
        [int]$count = 0
        foreach ($test_case_node in $test_case_nodes) {
          Write-Host $test_case_node.GetType() $test_case_node.testcontainername $test_case_node.iteration
          Write-Host "Processing " (++$count)
          $testFields = [Fields]::new()
          $testFields.description = $test_case_node.testcontainername + " at " + $(get-date -f MM-dd-yyyy_HH_mm_ss)
          $testFields.summary = $test_case_node.testcontainername + " at " + $(get-date -f MM-dd-yyyy_HH_mm_ss)
          $testFields.issuetype = [IssueType]::new("Test")
          $testFields.project = [Project]::new([Credentials]::projectKey)
          $testFields.customfield_10400 = [TestType]::new("Generic")
          $testFields.customfield_10403 = "generic test definition"
          [XRayTestEntityVo]$testVo = [XRayTestEntityVo]::new($testFields)
          $testVo.setStatus($test_case_node.result)
          $comment = $this.getComment($test_case_node)
          $testVo.setComment($comment)
          $this.tests = $this.tests + $testVo
          Write-Host $this.tests.Count
        }
        
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
        $this.tests = $this.tests[0]
        foreach($testVo in $this.tests){
            $testVo.save();
            $testVo.changeWorkflowStatus(11);
        }

        $testPlan = [XrayTestPlanVo]::new($this.tests)
        $testPlan.create()
        $testExecution = [XrayTestExecutorVo]::new($testPlan, $this.startDate, $this.endDate)
        $testExecution.create()
    }
}