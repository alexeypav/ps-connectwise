#Make contacts in CW innactive from CSV
#Needed: CSV with firstname and last name (CSV Headers: firstName,lastName) and company ID (e.g 1456)
#AlexeyP


#Company ID who's contacts to remove
$companyID = 0000

#Path to contatcs to remove, CSV Headers: firstName,lastName
$CSVPath = "C:\Users\"

#Connectwise API Authentication keys
$pubKey = ""
$priKey = ""

#Your company name for CW Server Auth
$youCompanyName = "mycompany"

#URL for CW Server
$serverURI = "https://connectwise.company.com"

################# START ####################
$idsToRemove = @()
$removedUsers = @()
$notFound = @()
$usersToRemove = Import-Csv $CSVPath

#Construct Auth string
[string]$Authstring = "$youCompanyName+" + "$pubKey" + ":" + "$priKey"
#Convert Auth string to base64 encoding
$encodedAuth = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(($Authstring)));

#Headers for REST calls
$Headers=@{
    "Authorization"="Basic $encodedAuth";
}



#Iterate through csv and get user's contact ID
foreach($user in $usersToRemove){

    $firstName = $user.firstName
    $lastName = $user.lastName

    "Processing User: $firstName $lastName"
    

    $result = "" #In case error returned

    #COntrcut body for request to get contact ID
    $Body = @{

        "conditions" = "company/id = $companyID AND lastName = `"$lastName`" AND firstName = `"$firstName`""

        "pageSize" = "1" #only returns 1 result per user
        
        } 


    $result = Invoke-RestMethod -URI "$serverURI/v4_6_release/apis/3.0/company/contacts" -Headers $Headers -Body $Body -ContentType "application/json" -Method Get

    if($result.Count -eq 0){
        #If no user found
        $notFound += "User $firstName $lastName Not found"
    
    }else{
        #Get contact ID if found
        $id = $result.id

        $removedUsers += "User Made Inactive: $firstName $lastName ID: $id"

        $idsToRemove += $id
    }



}




#New request body construct for making Innactive

    $Body = '[{  
      op : "replace",
      path :"/inactiveFlag",
      value : "True"
  }]'


#Disable found contact IDs        

foreach($userID in $idsToRemove){

    "Making inactive: $userID..."

    $makeInactive = Invoke-RestMethod -URI "$serverURI/v4_6_release/apis/3.0/company/contacts/$userID" -Headers $Headers -Body $Body -ContentType "application/json" -Method PATCH


}


"Contacts mad inactive: "
$removedUsers

"Contacts not found: "
$notFound