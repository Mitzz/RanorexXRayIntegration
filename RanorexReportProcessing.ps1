﻿. (Join-Path $PSScriptRoot XRayEntityVosDefinition.ps1) 

class RanorexXmlProcessor{
    [System.Xml.XmlDocument]$file
    [XRayTestEntityVo[]]$testVos = @()
    [XRayTestSetEntityVo[]]$testSetVos = @()

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
        $testFields.project = [Project]::new([Credentials]::projectKey)
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



        $testPlan = [XrayTestPlanVo]::new($this.testVos + $this.testSetVos)
        $testPlan.create()
        $testExecution = [XrayTestExecutorVo]::new($testPlan, $this.startDate, $this.endDate)
        $testExecution.create()
    }
}