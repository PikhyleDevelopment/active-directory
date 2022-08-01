# Active Directory Home Lab

## Randomly Generate A Domain Schema
`.\random_domain.ps1 out.json -UserCount [int] -GroupCount [int] -LocalAdminCount [int]`
## Populate Active Directory
`.\gen_ad.ps1 out.json`
## Tear Down Active Directory
`.\gen_ad.ps1 out.json -ResetAD`