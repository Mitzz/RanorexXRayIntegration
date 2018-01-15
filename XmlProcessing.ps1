function XML-Process {
	$xmlFilePath = "C:\Users\bhansm\Documents\My Received Files\powershell\Car.xml"
    #$xmlFilePath = "C:\Users\bhansm\Downloads\RanorexToXrayIntegration\Harald_SampleReports\testReport_HTML_junit\testReport\WebConsole_20171109_134715.html.data.xml"
    [xml]$xml = Get-Content $xmlFilePath
    return ConvertFrom-Xml($xml)
}

function Xml-ChildresNode-Name($node){
    foreach($childNode in $node.ChildNodes)
    {
        Write-Host "$($childNode.Name)"
        Xml-ChildresNode-Name($childNode)
    }
}

function XML-Process-using-xpath {
	$xmlFilePath = "C:\Users\bhansm\Documents\My Received Files\powershell\Car.xml"
    [xml]$xml = Get-Content $xmlFilePath
    $carsArr = @()
    foreach($carsNode in $xml.ChildNodes)
    {
        foreach($carNode in $carsNode.ChildNodes)
        {
            Write-Host "$($carNode.Name)"
            $car = [PSCustomObject]@{}

            foreach($property in $carNode | Get-Member -MemberType Properties | Select-Object Name)
            {
                $propertyName = $property.Name
                Write-Host "$($propertyName)" 
         
                $car | Add-Member -Name $property.Name -Type NoteProperty -Value $carNode.$propertyName   
            }

            $carsArr += $car
        }
    }
    return $carsArr
}

function ConvertFrom-Xml($xml) 
{
    $hash = @{}
    $hash = ConvertFrom-XmlPart($xml)
    $hash | Select-Object -Property *
    return New-Object PSObject -Property $hash
}

function ConvertFrom-XmlPart($xml)
{
    $hash = @{}
    $xml | Get-Member -MemberType Property | 
        % {
            $name = $_.Name
            if ($_.Definition.StartsWith("string ")) {
                $hash.($Name) = $xml.$($Name)
            } elseif ($_.Definition.StartsWith("System.Object[] ")) {
                $obj = $xml.$($Name)
                $hash.($Name) = $($obj | %{ $_.tag }) -join "; "
            } elseif ($_.Definition.StartsWith("System.Xml")) {
                $obj = $xml.$($Name)
                $hash.($Name) = @{}
                if ($obj.HasAttributes) {
                    $attrName = $obj.Attributes | Select-Object -First 1 | % { $_.Name }
                    if ($attrName -eq "tag") {
                        $hash.($Name) = $($obj | % { $_.tag }) -join "; "
                    } else {
                        $hash.($Name) = ConvertFrom-XmlPart $obj
                    }
                }
                if ($obj.HasChildNodes) {
                    $obj.ChildNodes | % { $hash.($Name).($_.Name) = ConvertFrom-XmlPart $($obj.$($_.Name)) }
                }
            }
        }
    return $hash
}

function my-way(){
    [System.Xml.XmlDocument]$file = new-object System.Xml.XmlDocument
    $file.load("C:\Users\bhansm\Downloads\RanorexToXrayIntegration\Harald_SampleReports\testReport_HTML_junit\testReport\WebConsole_20171109_134715.html.data")
    $test_case_nodes= $file.SelectNodes("//activity[@type='test-case']")
    foreach ($test_case_node in $test_case_nodes) {
      echo $test_case_node.GetType() $test_case_node.testcontainername $test_case_node.iteration
    }
    
}

class XRayTestVo{
    [Fields]$fields

    XRayTestVo([Fields]$fields){
        $this.fields = $fields
    }
}

class Fields{
    [string]$summary
    [int]$description

    Fields([string]$summary, [int]$description){
        $this.summary = $summary
        $this.description = $description

    }

}

function createXrayGenericTestVo(){
    $xrayGenericTestVo = createPSObject
    $fields = createPSObject
    $project = createPSObject
    $issueType = createPSObject
    $customfield_10200 = createPSObject

    addPropertyToPSObject -obj $project -propName "key" -propValue "ABC"
    addPropertyToPSObject -obj $customfield_10200 -propName "value" -propValue "Generic"
    addPropertyToPSObject -obj $issueType -propName "name" -propValue "Test"

    addPropertyToPSObject -obj $fields -propName "summary" -propValue "Sum of two number"
    addPropertyToPSObject -obj $fields -propName "description" -propValue "example of generic test"
    addPropertyToPSObject -obj $fields -propName "customfield_10203" -propValue "sum_script.sh"
    addPropertyToPSObject -obj $fields -propName "project" -propValue $project
    addPropertyToPSObject -obj $fields -propName "customfield_10200" -propValue $customfield_10200
    
    
    addPropertyToPSObject -obj $xrayGenericTestVo -propName "fields" -propValue $fields
    #$xrayGenericTestVo | ConvertTo-Json -Depth 99 | Out-File -Encoding ascii -Append "C:\Users\bhansm\Desktop\powershell.log"
    ConvertTo-Json -InputObject $xrayGenericTestVo -Depth 4
    return $xrayGenericTestVo
}

function sanity(){
    $obj1 = createPSObject
    $composedObject = createPSObject
    addPropertyToPSObject -obj $composedObject -propName "prop11" -propValue "value11"
    addPropertyToPSObject -obj $composedObject -propName "prop12" -propValue "value12"
    
    Write-Host $composedObject

    addPropertyToPSObject -obj $obj1 -propName "prop1" -propValue "value1"
    addPropertyToPSObject -obj $obj1 -propName "prop2" -propValue "value2"
    addPropertyToPSObject -obj $obj1 -propName "prop3" -propValue "value3"
    addPropertyToPSObject -obj $obj1 -propName "obj" -propValue $composedObject

    showProperty -obj $obj1 -propertyName "prop3"
    return $obj1
}

function addPropertyToPSObject($obj, $propName, $propValue){
    #Add-Member -InputObject $obj -MemberType NoteProperty -Name $("$propName") -Value $("$propValue")
    #$obj.$propName += [PSCustomObject]@{$propName=$propValue}
    $obj.Add($propName, $propValue)
}

function hashTableDemo(){
    $hash = @{};
    $hash.Add("prop1", "value")
    $hash.Add("prop2", @{"nested" = "nestedVal"})
    $hash | ConvertTo-Json
    return $hash
}

function createPSObject(){
    $obj = New-Object psobject
    return @{}
}

function showProperty($obj, $propertyName){
    Select-Object -Property $propertyName -InputObject $obj | Format-List *
}

class Wheel {
    [String]$make

    Wheel([String]$make){
        $this.make = $make
    }
}

class Car{
    [string]$name
    [Wheel]$wheel

    Car([string]$name, [Wheel]$wheel){
        $this.name = $name
        $this.wheel = $wheel
    }
}

function getXrayTestVo(){
    [System.Xml.XmlDocument]$file = new-object System.Xml.XmlDocument
    $file.load("C:\Users\bhansm\Downloads\RanorexToXrayIntegration\Harald_SampleReports\testReport_HTML_junit\testReport\WebConsole_20171109_134715.html.data")
    $test_case_nodes= $file.SelectNodes("//activity[@type='test-case']")
    foreach ($test_case_node in $test_case_nodes) {
      echo $test_case_node.GetType() $test_case_node.testcontainername $test_case_node.iteration
    }
}

function Rest-PostAPITest {
    $url = "https://reqres.in/api/users?page=2"

	$name = "morpheus"
	$job = "leader"
		
	$messageBody = @{
		name = $name
		job = $job
	}
	
	$user = 'bhansm'
	$pass = 'Mitz@#23mit'

	$pair = "$($user):$($pass)"
	Write-Host "$pair"
	#$cred = Get-Credential
	$encodedCreds = [System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($pair))
	
	$basicAuthValue = "Basic $encodedCreds"

	$Headers = @{
		Authorization = $basicAuthValue
	}
    #https://stackoverflow.com/questions/20471486/how-can-i-make-invoke-restmethod-use-the-default-web-proxy	
	$proxyUri = [Uri]$null
	$proxy = [System.Net.WebRequest]::GetSystemWebProxy()
	$proxy.Credentials = [System.Net.CredentialCache]::DefaultCredentials
	$proxyUri = $proxy.GetProxy("$url")
	
	$result = Invoke-WebRequest -Uri $url -Headers $Headers -Method Post -Body (ConvertTo-Json $messageBody) -ContentType "application/json" #-UseDefaultCredentials -Proxy $proxyUri -ProxyUseDefaultCredentials
	
	
	Write-Host $result
}
