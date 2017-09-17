# CHANGELOG:
# 2017-09-16 mdyzio begin of creation
# 2017-09-18 mdyzio end of creation

# This scipt is intended to check if your KMS host can now activate products.

# Using this script you can install NSClient++ and configure it this way:
#[/settings/external scripts]
#allow arguments = true
#
#[/settings/external scripts/scripts]
#check_kms = cmd /c echo scripts\check_kms.ps1 "$ARG1$"; exit($lastexitcode) | powershell.exe -command -
#
#[/settings/external scripts/alias]
#check_kms_office2010  = check_kms "bfe7a195-4f8f-4f0b-a622-cf13c7d16864"
#
# And then (from nagios server), check for Office 2010 activation status:
# $ /usr/lib/nagios/plugins/check_nrpe -H your_kms_host -c check_kms_office2010
# OK|'count'=10 'required'=10

# first and only parameter is activation ID
# examples:
# d188820a-cb63-4bad-a9a2-40b843ee23b7 - Windows 7 KMS
# bfe7a195-4f8f-4f0b-a622-cf13c7d16864 - Office 2010 KMS
# 2e28138a-847f-42bc-9752-61b03fff33cd - Office 2013 KMS
# 98ebfe73-2084-4c97-932c-c0cd1643bea7 - Office 2016 KMS
param (
	[Parameter(Mandatory=$true)][string]$id
)

# Nagios status codes
$STATE_OK = 0
$STATE_WARNING = 1
$STATE_CRITICAL = 2
$STATE_UNKNOWN = 3

# LicenseStatus -> Text
$StatusToText = @{
	0 = "Unlicensed";
	1 = "Licensed";
	2 = "Out-Of-Box Grace Period";
	3 = "Out-Of-Tolerance Grace Period";
	4 = "Non-Genuine Grace Period";
	5 = "Notification";
	6 = "Extended Grace";
}

# 0. Get information about activation from given ID
$product = Get-WmiObject SoftwareLicensingProduct -Filter "ID='$id'"

if (-Not $product) {
	"Supplied ID is not valid activation ID on this computer"
	exit $STATE_UNKNOWN
}

# 1. Check LicenseStatus
if ($StatusToText[[int]$product.LicenseStatus] -ne "Licensed") {
	"Product is not licensed on this computer. Now it's in state " + $StatusToText[[int]$product.LicenseStatus] + "."
	exit $STATE_CRITICAL
}

# 2. Check activated host count
$currentCount = [int]$product.KeyManagementServiceCurrentCount
$requiredCount = [int]$product.RequiredClientCount

if ($currentCount -ge $requiredCount) {
	"OK|count=" + $currentCount + " required=" + $requiredCount
	exit $STATE_OK
} else {
	"WARNING - activation count is less than required|count=" + $currentCount + " required=" + $requiredCount
	exit $STATE_WARNING
}


# POST SCRIPTUM (hehe: script <-> scriptum)
# ARGH!! PROGRAMMING IN POWERSHELL IS F*CKING PAIN IN THE ASS
# SADLY, IT'S THE BEST SCIPTING LANGUAGE ON THIS PLATFORM
# AND DOCUMENTATION FOR WMI SOFTWARELICENSINGPRODUCT IS ABOUT ZERO
# so I don't take responsibility if this script eats you cat or something; I hope it just works