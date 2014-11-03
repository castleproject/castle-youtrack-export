$baseUrl = "http://issues.castleproject.org/youtrack"
$userName = ""
$password = ""

# Login
$loginResponse = Invoke-RestMethod `
	-SessionVariable webSession `
	-Uri "$baseUrl/rest/user/login" `
	-Method Post `
	-Body @{
		login = $userName
		password = $password
	}
if ($loginResponse.login -ne "ok") {
	Write-Error "Login failed"
}

# Fetch issues
@("AR","CASTLE","COMP","CONTRIB","CORE","DYNPROXY","FACILITIES","MR","NVELOCITY","SAMPLES","SERVICES","IOC") | % {
	$project = $_

	Remove-Item -Recurse -ErrorAction SilentlyContinue $project
	New-Item -Type Directory $project | Out-Null

	$issuesResponse = Invoke-RestMethod `
		-WebSession $webSession `
		-Uri "$baseUrl/rest/export/$project/issues" `
		-Method Get `
		-Body @{
			max = 10000
		}
	$issuesResponse.SelectNodes("/issues/issue") | % {
		$id = $project + "-" + $_.SelectSingleNode("field[@name='numberInProject']/value").InnerText

		# Create document
		$doc = New-Object System.Xml.XmlDocument
		$rootEl = $doc.CreateElement("issues")
		$doc.AppendChild($rootEl) | Out-Null

		# Append issue element
		$issueEl = $doc.ImportNode($_, $true)
		$rootEl.AppendChild($issueEl) | Out-Null

		# Output document
		Write-Output "Writing $id"
		$writer = New-Object System.Xml.XmlTextWriter("$pwd\$project\$id.xml", [Text.Encoding]::UTF8)
		$writer.Formatting = [System.Xml.Formatting]::Indented
		$doc.Save($writer)
		$writer.Close()
	}
}