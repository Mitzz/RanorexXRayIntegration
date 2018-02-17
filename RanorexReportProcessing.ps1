. (Join-Path $PSScriptRoot XRayEntityVosDefinition.ps1) 

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
        $dataStr = $root_node.timestamp
        $dateFormat = "M/d/yyyy h:m:ss"
		Write-Host $dataStr
		$this.startDate = $null
        $this.endDate = $null
    }

    [XrayTestEntityVo] handleTestCaseNode($testCaseNode){
        $testFields = [Fields]::new()
        $testFields.description = $testCaseNode.testcontainername
        $testFields.summary = $testCaseNode.testcontainername
        $testFields.issuetype = [IssueType]::new("Test")
        $testFields.project = [Project]::new([Constants]::projectKey)
        $testFields.customfield_10400 = [TestType]::new("Generic")
        $testFields.customfield_10403 = "Generic test definition"
        [XrayTestEntityVo]$testVo = [XrayTestEntityVo]::new($testFields)
        $testVo.setStatus($testCaseNode.result)
        $comment = $this.getComment($testCaseNode)
        $testVo.setComment($comment)

        return $testVo
    }

    [XrayTestEntityVo[]] handleIterationContainerNode($iterationContainerNode){
        Write-Host "Processing Iteration Container Node...."
        [XrayTestEntityVo[]]$testArr = @()
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

    [XrayTestEntityVo[]] handleSmartFolderNode($smartFolderNode){
        Write-Host "Processing Smart Folder Node...."
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
            $this.testSetVos = $this.testSetVos + [XrayTestSetEntityVo]::new($this.handleSmartFolderNode($smartFolderNode))
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
        $this.testPlanVo = [XrayTestPlanEntityVo]::new($this.testVos, $this.testSetVos)
        
    }

    SaveTestPlanVo(){
        $this.testPlanVo.create()
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
