param([Parameter(Mandatory=$true)] $JSONFile)
#Import-Module ActiveDirectory
function CreateADGroup() {
    param (
        [Parameter(Mandatory=$true)] $groupObject 
    )

    $name = $groupObject.name
    New-ADGroup -name $name -GroupScope Global


}

function CreateADUser() {
    param (
        [Parameter(Mandatory=$true)] $userObject
    )
    # Pull name from JSON Object
    $name = $userObject.name
    $password = $userObject.password

    # Generate "first initial, last name" username
    $firstname, $lastname = $name.Split(" ")
    $username = ($firstname[0] + $lastname).ToLower()
    $samAccountName = $username
    $principalname = $username

    # Actually create the AD User object
    New-ADUser -Name "$firstname $lastname" -GivenName $firstname -Surname $lastname -SamAccountName $samAccountName -UserPrincipalName $principalname@$Global:Domain -AccountPassword (ConvertTo-SecureString $password -AsPlainText -Force) -PassThru | Enable-ADAccount

    # Add user to its appropriate group
    foreach($group in $userObject.groups) {
        try {
            Get-ADGroup -Identity "$group"
            Add-ADGroupMember -Identity $group -Members $username
        }
        catch [Microsoft.ActiveDirectory.Management.ADIdentityNotFoundException]
        {
            Write-Warning "AD Group object not found: $group. User $user not added."
        }
    }

}

$json = (Get-Content $JSONFile | ConvertFrom-Json)

$Global:Domain = $json.domain

foreach ($group in $json.groups) {
    CreateADGroup $group
    
}

foreach ($user in $json.users) {
    CreateADUser $user
}