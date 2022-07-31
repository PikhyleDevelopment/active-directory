param(
    [Parameter(Mandatory=$true)] $OutputJSONFile,
    [int]$GroupCount = 2,
    [int]$UserCount = 8,
    [int]$LocalAdminCount
)

$groups = @()
$users = @()

$group_names = [System.Collections.ArrayList](Get-Content "data\group_names.txt")
$first_names = [System.Collections.ArrayList](Get-Content "data\first_names.txt")
$last_names = [System.Collections.ArrayList](Get-Content "data\last_names.txt")
$passwords = [System.Collections.ArrayList](Get-Content "data\passwords.txt")

# Generate $GroupCount number of groups from the group_names.txt file. 
for ( $i = 1; $i -le $GroupCount; $i++ ) {
    $new_group = Get-Random -InputObject $group_names
    $groups += "$new_group"
    $group_names.Remove( $new_group )
}

# Generate random number of local administrator accounts based on $LocalAdminCount
if ( $LocalAdminCount -ne 0 ) {
    $local_admin_indexes = @()
    while ( ( $local_admin_indexes | Measure-Object).Count -lt $LocalAdminCount ) {
        $random_index = ( Get-Random -InputObject (1..( $UserCount )) | Where-Object { $local_admin_indexes -notcontains $_ } )
        $local_admin_indexes += @( $random_index )
    }
}

# Generate $UserCount number of user accounts based on first_names.txt, last_names.txt, and passwords.txt
for ( $i = 1; $i -le $UserCount; $i++ ) {
    $first_name = Get-Random -InputObject $first_names
    $last_name = Get-Random -InputObject $last_names
    $password = Get-Random -InputObject $passwords
    $new_user = @{"name"="$first_name $last_name"
                "password"="$password"
                "groups" = @(
                    ( Get-Random -InputObject $groups )
                )
            }
    if ( $local_admin_indexes | Where-Object { $_ -eq $i } ){
        echo "user $i is localadmin"
        $new_user["local_admin"] = $true;
    }
    $users += $new_user
    $first_names.Remove($first_name)
    $last_names.Remove($last_name)
    $passwords.Remove($password)
}

# Convert user data to Json, output in $OutputJSONFile
ConvertTo-Json -InputObject @{ 
    "domain" = "pikhyle.net"
    "groups" = $groups
    "users" = $users
} | Out-File $OutputJSONFile