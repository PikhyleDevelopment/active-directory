param(
    [Parameter(Mandatory=$true)] $JSONFile,
    [switch] $ResetAD
)
#Import-Module ActiveDirectory

function Write-Good { param( $String ) Write-Host $Global:PlusLine  $String -ForegroundColor 'Green'}
function Write-Bad  { param( $String ) Write-Host $Global:ErrorLine $String -ForegroundColor 'red'  }
function Write-Info { param( $String ) Write-Host $Global:InfoLine $String -ForegroundColor 'gray' }
function CreateADGroup() {
    param (
        [Parameter(Mandatory=$true)] $groupObject 
    )

    $name = $groupObject
    Write-Info "Creating group $name"
    New-ADGroup -name $name -GroupScope Global
}

function RemoveADGroup() {
    param (
        [Parameter(Mandatory=$true)] $groupObject 
    )

    $name = $groupObject
    Write-Info "Removing group $name"
    Remove-ADGroup -Confirm:$false -Identity $name
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

    Write-Info "Creating user $username"
    # Actually create the AD User object
    New-ADUser -Name "$firstname $lastname" -GivenName $firstname -Surname $lastname -SamAccountName $samAccountName -UserPrincipalName $principalname@$Global:Domain -AccountPassword (ConvertTo-SecureString $password -AsPlainText -Force) -PassThru | Enable-ADAccount

    # Add user to its appropriate group
    foreach($group in $userObject.groups) {
        try {
            Get-ADGroup -Identity "$group"
            Add-ADGroupMember -Identity $group -Members $username
            Write-Good "$username successfully added to $group"
        }
        catch [Microsoft.ActiveDirectory.Management.ADIdentityNotFoundException]
        {
            Write-Warning "AD Group object not found: $group. User $user not added."
        }
    }

    # Add to local admin as needed
    if ( $userObject.local_admin ) {
        net localgroup administrators $Global:Domain\$username /add
    }

}

function RemoveADUser() {
    param(
        [Parameter(Mandatory=$true)] $userObject
    )

    $name = $userObject.name 
    $firstname, $lastname = $name.Split(" ")
    $username = ($firstname[0] + $lastname).ToLower()
    $samAccountName = $username
    Remove-ADUser -Identity $samAccountName -Confirm:$false
}

function WeakenPasswordPolicy() {
    secedit /export /cfg C:\Windows\Tasks\secpol.cfg
    (Get-Content C:\Windows\Tasks\secpol.cfg).replace("PasswordComplexity = 1", "PasswordComplexity = 0").replace("MinimumPasswordLength = 7", "MinimumPasswordLength = 1") | Out-File C:\Windows\Tasks\secpol.cfg
    secedit /configure /db c:\windows\security\local.sdb /cfg C:\Windows\Tasks\secpol.cfg /areas SECURITYPOLICY
    Remove-Item -force C:\Windows\Tasks\secpol.cfg -confirm:$false
}

function StrengthenPasswordPolicy() {
    secedit /export /cfg C:\Windows\Tasks\secpol.cfg
    (Get-Content C:\Windows\Tasks\secpol.cfg).replace("PasswordComplexity = 0", "PasswordComplexity = 1").replace("MinimumPasswordLength = 1", "MinimumPasswordLength = 7") | Out-File C:\Windows\Tasks\secpol.cfg
    secedit /configure /db c:\windows\security\local.sdb /cfg C:\Windows\Tasks\secpol.cfg /areas SECURITYPOLICY
    Remove-Item -force C:\Windows\Tasks\secpol.cfg -confirm:$false
}


$json = (Get-Content $JSONFile | ConvertFrom-Json)

$Global:Domain = $json.domain

if (-not $ResetAD) {    
    WeakenPasswordPolicy

    foreach ($group in $json.groups) {
        CreateADGroup $group
        
    }

    foreach ($user in $json.users) {
        CreateADUser $user
    }
}
else {
    StrengthenPasswordPolicy

    foreach ($user in $json.users) {
        RemoveADUser $user
    }

    foreach ($group in $json.groups) {
        RemoveADGroup $group
        
    }
}