param([Parameter(Mandatory=$true)] $OutputJSONFile)

$groups = @()
$users = @()

$group_names = [System.Collections.ArrayList](Get-Content "data\group_names.txt")
$first_names = [System.Collections.ArrayList](Get-Content "data\first_names.txt")
$last_names = [System.Collections.ArrayList](Get-Content "data\last_names.txt")
$passwords = [System.Collections.ArrayList](Get-Content "data\passwords.txt")


$num_groups = 6
for ($i = 0; $i -lt $num_groups; $i++) {
    $new_group = Get-Random -InputObject $group_names
    #$groups += @{ "name" = $new_group}
    $groups += "$new_group"
    $group_names.Remove($new_group)
}

$num_users = 100
for ($i = 0; $i -lt $num_users; $i++) {
    $first_name = Get-Random -InputObject $first_names
    $last_name = Get-Random -InputObject $last_names
    $password = Get-Random -InputObject $passwords
    $new_user = @{"name"="$first_name $last_name"
                "password"="$password"
                "groups" = @(
                    (Get-Random -InputObject $groups)
                )
            }
    $users += $new_user
    $first_names.Remove($first_name)
    $last_names.Remove($last_name)
    $passwords.Remove($password)
}

ConvertTo-Json -InputObject @{ 
    "domain" = "pikhyle.net"
    "groups" = $groups
    "users" = $users
} | Out-File $OutputJSONFile