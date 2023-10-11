
$ExportPathUserList = ‘c:\unixconfig\adusers_list.csv’

Get-ADUser -Filter * | Select-object SamAccountName | Export-Csv -NoType $ExportPathUserList


$ADUSERLIST=Get-Content $ExportPathUserList | select -Skip 1

foreach ($ADUSER in $ADUSERLIST)
{

#Write-Output "$ADUSER"

$ADUSER = [string]::join("",($ADUSER.Split("`n")))

$ADUSER = $ADUSER.Replace('"', "")

#Write-Output "$ADUSER"

$UIDNUM=Get-ADUser -Identity $ADUSER -Properties * | Out-String -Stream | Select-String uidNumber

if ($UIDNUM -eq $null) {
    # Get UID from the Linux VM 10.2.6.153
    #echo "no uid found for user $ADUSER"
    $ADUSERUID=cmd.exe /c .\plink.exe -load linuxvm1 -batch "id 'QCRIDEMO\$ADUSER' | cut -d= -f2 | cut -d\( -f1"
    #echo $ADUSER UID is $ADUSERUID
    # Set UID on the Windows Server 2022
    Set-ADUser -Identity $ADUSER -add @{uidnumber="$ADUSERUID"}
    $ADUSERPRIMARYGID=cmd.exe /c .\plink.exe -load linuxvm1 -batch "id 'QCRIDEMO\$ADUSER' | cut -d= -f3 | cut -d\( -f1"
    #echo $ADUSER Primary Group ID is $ADUSERPRIMARYGID
    Write-Host $((get-date).ToLocalTime()).ToString("yyyy-MM-dd HH:mm:ss") "New Change: Adding UID Number $ADUSERUID and User Primary GID Number $ADUSERPRIMARYGID for user  $ADUSER to AD"
    # Set GID on the Windows Server 2022
    Set-ADUser -Identity $ADUSER -add @{gidnumber="$ADUSERPRIMARYGID"}

}


}



$ExportPathGroupList = ‘c:\unixconfig\adgroup_list.csv'

Get-ADGroup -Filter * | Select-Object SamAccountName | Export-Csv -NoType $ExportPathGroupList

$ADGROUPLIST=Get-Content $ExportPathGroupList | select -Skip 1


foreach ($ADGROUP in $ADGROUPLIST)

{

$ADGROUP = [string]::join("",($ADGROUP.Split("`n")))

$ADGROUP = $ADGROUP.Replace('"', "")



$GIDNUM=Get-ADGroup -Identity $ADGROUP -Properties * | Out-String -Stream | Select-String gidNumber

#Write-Output "$ADGROUP"  $GIDNUM


if ($GIDNUM -eq $null) {


    # Get GID from the Linux VM 10.2.6.153
    #echo "no gid found for user $ADGROUP"
    $ADGROUPR1 = $ADGROUP.Replace(' ','^')
    $ADGROUPR2 = -join("'\\",$ADGROUPR1,"$'")
    $ADGROUPID=cmd.exe /c .\plink.exe -load linuxvm1 -batch "/opt/pbis/bin/enum-groups | grep -A 5 -i $ADGROUPR2 | grep -i Gid | cut -d: -f2"
    if($ADGROUPID -ne $null) {
    $ADGROUPID = $ADGROUPID.Trim()
        Write-Host  $((get-date).ToLocalTime()).ToString("yyyy-MM-dd HH:mm:ss") "New Change: Adding GID Number $ADGROUPID for Group $ADGROUP to AD"
        # Set GID on the Windows Server AD
        Set-ADGroup -Identity "$ADGROUP" -add @{gidNumber="$ADGROUPID"}
    }


}


}


