#################################################
# DFSRBacklog.ps1                               #
# v1.0 (15/06/22)                               #
#   Extract backlog length from dfsrdiag.exe    #
#   and write to file for ingestion into SIEM   #
# Dan Kennedy (github.com/wildeuk)              #
#################################################

#Requires -Version 5

# Define stuff we're going to need

$InputFile = '.\RF_List.txt'
$OutputFile = '.\Output.txt'
$Now = Get-Date -Format FileDateTimeUniversal

# Build functions that we need and that don't already exist

# This function reads an input file, defined in the global variable $InputFile and stores the result in an array of PSObjects
Function ReadRFList
{
    [cmdletbinding()]
    Param 
    (
        [string]$InputFile
    )
    Begin
    {
        [array]$RFList = @()
    }
    Process 
    {
        $input_array = (Get-Content $InputFile) -notmatch '^#' # Read lines in from input file, ignoring commented lines
        Foreach ($line in $input_array) 
        {
            $line_split = $line | ConvertFrom-String -PropertyNames val1, val2, val3, val4 -Delimiter ":" # Split input lines at the ':' character, then store individual parts of the line in variables
            $replication_group = $line_split.val1
            $replicated_folder = $line_split.val2
            $sending_member = $line_split.val3
            $receiving_member = $line_split.val4
            $array_obj = New-Object System.Object # Create a new PSObject, then store extracted values as NoteProperty objects
            $array_obj | Add-Member -type NoteProperty -Name RGName -Value $replication_group
            $array_obj | Add-Member -type NoteProperty -Name RFName -Value $replicated_folder
            $array_obj | Add-Member -type NoteProperty -Name Sender -Value $sending_member
            $array_obj | Add-Member -type NoteProperty -Name Receiver -Value $receiving_member
            $RFList += $array_obj # Add all of our new objects into the $RFList array
        }
        Return $RFList
    }
}

# This function reads the input taken from ReadRFList's output array and outputs the result as a string
Function GetBacklog
{
    [cmdletbinding()]
    Param
    (
        [string]$ReplicationGroup,
        [string]$ReplicatedFolder,
        [string]$SendingMember,
        [string]$ReceivingMember
    )
    Process
    {
        $Backlog_Output = (Get-DfsrBacklog -GroupName "$ReplicationGroup" -FolderName "$ReplicatedFolder" -SourceComputerName "$SendingMember" -DestinationComputerName "$ReceivingMember" -Verbose 4>&1).ToString() # Define the $Backlog_Output variable and parse a line, then convert it to a string
        If ($Backlog_Output.Contains('No backlog for the replicated folder')) # If the string above contains the phrase to the left ...
        {
            $GetBacklog_Output = $Now + " : " + $ReplicationGroup + " : " + $ReplicatedFolder + " : " + $SendingMember + " : " + $ReceivingMember + " : " + "0" # Write our formatted output, with a simple '0' at the end for backlog
            Return $GetBacklog_Output
        }
        Else
        {
            $GetBacklog_Output = $Now + " : " + $ReplicationGroup + " : " + $ReplicatedFolder + " : " + $SendingMember + " : " + $ReceivingMember + " :" + (Get-DfsrBacklog -GroupName "$ReplicationGroup" -FolderName "$ReplicatedFolder" -SourceComputerName "$SendingMember" -DestinationComputerName "$ReceivingMember" -Verbose 4>&1).Message.Split(':')[2] # If the backlog is >0, return our formatted string, grabbing the backlog by splitting the output
            Return $GetBacklog_Output
        }
    }

}
$Output_RFList = ReadRFList -InputFile $InputFile # Read our input file

$WriteOut = Foreach ($line in $Output_RFList) # For each line in our output from ReadRFlist ...
{
    $Output = (GetBacklog -ReplicationGroup $line.RGName -ReplicatedFolder $line.RFName -SendingMember $line.Sender -ReceivingMember $line.Receiver) # Write the output of GetBacklog to the output variable
    Write-Output $Output
}
$WriteOut | Out-File $OutputFile # On every iteration through the loop, write the content of $WriteOut to our output file, defined in $OutputFile

#END
