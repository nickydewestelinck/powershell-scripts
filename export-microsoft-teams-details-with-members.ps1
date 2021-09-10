function Export-TeamsList
{  
     param (  
           $ExportPath
           )  
    process{
                Connect-PnPOnline -Scopes "Group.Read.All","User.ReadBasic.All"
                $accesstoken =Get-PnPAccessToken
                $MTeams = Invoke-RestMethod -Headers @{Authorization = "Bearer $accesstoken"} -Uri  "https://graph.microsoft.com/beta/groups?`$filter=resourceProvisioningOptions/any(c:c+eq+`'Team`')" -Method Get
                $TeamsList = @()
                $i=1
                do
                {
                    foreach($value in $MTeams.value)
                    {
       
                            Write-Progress -Activity "Get All Teams" -status "Found Team $i"                
                  
                            $id= $value.id
                            Try
                            {
                                $team = Invoke-RestMethod -Headers @{Authorization = "Bearer $accesstoken"} -Uri https://graph.microsoft.com/beta/Groups/$id/channels -Method Get
                                
                            }
                            Catch
                            {
                               
                            }                 
                
                            $Owner = Invoke-RestMethod -Headers @{Authorization = "Bearer $accesstoken"} -Uri https://graph.microsoft.com/v1.0/Groups/$id/owners -Method Get
                            $Members = Invoke-RestMethod -Headers @{Authorization = "Bearer $accesstoken"} -Uri https://graph.microsoft.com/v1.0/Groups/$id/Members -Method Get
                            $Teams = "" | Select "TeamsName","TeamType","Channelcount","ChannelName","Owners","MembersCount","Members"
                            $Teams.TeamsName = $value.displayname
                            $Teams.TeamType = $value.visibility
                            $Teams.ChannelCount = $team.value.id.count
                            $Teams.ChannelName = $team.value.displayName -join ";"
                            $Teams.Owners = $Owner.value.userPrincipalName -join ";"
                            $Teams.MembersCount = $Members.value.userPrincipalName.count
                            $Teams.Members = $Members.value.userPrincipalName -join ";"
                            $TeamsList+= $Teams
                            $teamaccesstype=$null
                            $errorMessage =$null
                            $Teams=$null
                            $team =$null
                            $i++
                    }
                    if ($MTeams.'@odata.nextLink' -eq $null )
                    {
                        break
                    }
                    else
                    {
                        $MTeams = Invoke-RestMethod -Headers @{Authorization = "Bearer $accesstoken"} -Uri $MTeams.'@odata.nextLink' -Method Get
                    }
                }while($true);
                $TeamsList.count
                $TeamsList
                $TeamsList | Export-csv $ExportPath -NoTypeInformation
            }
}
Export-TeamsList -ExportPath "C:\temp\teamswithmembers.csv"
