. (Join-Path $PSScriptRoot XRayEntityVosDefinition.ps1) 

class RanorexXmlProcessor{
    [System.Xml.XmlDocument]$file
    [XRayTestEntityVo[]]$tests = @()
    RanorexXmlProcessor($filePath){
        [System.Xml.XmlDocument]$this.file = new-object System.Xml.XmlDocument
        $this.file.load("C:\Users\bhansm\Downloads\RanorexToXrayIntegration\Harald_SampleReports\testReport_HTML_junit\testReport\WebConsole_20171109_134715.html.data.xml")
    }

    CreateTestVos(){
        Write-Host $this.tests.Count
        $root_node = $this.file.SelectNodes("//activity[@type='root']")
    
        $dataStr = $root_node.timestamp
        $dateFormat = "M/d/yyyy h:m:ss tt"
        $startDate = [datetime]::ParseExact($dataStr, $dateFormat, $null)

        $dataStr = $root_node.endtime
        $endDate = [datetime]::ParseExact($dataStr, $dateFormat, $null)

        $startTime = $startDate.ToString('s') + "+00:00"
        $endTime = $endDate.ToString('s') + "+00:00"

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

    execute($tests){
        $thtests = $this.tests[0]
        foreach($testVo in $tests){
            $testVo.save();
            $testVo.changeWorkflowStatus(11);
        }

        $testPlan = [XrayTestPlanVo]::new($tests)
        $testPlan.create()
        $testExecution = [XrayTestExecutorVo]::new($testPlan)
        $testExecution.create()
    }
}