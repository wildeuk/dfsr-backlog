# dfsr-backlog
##### A script to grab data from the Windows Server DFS-R backlog &amp; push to a file, ready for SIEM ingestion

## Requirements
- A Windows Server environment with DFS replication enabled
- Powershell v.5 or greater (optional install on Server 2012R2, present on newer versions)
- An account with local administrator rights on both the source & destination machines (please see 'A note on accounts' below for more info)

## Usage
1. Download the files in this repository to a single directory on a server you wish to pull DFS backlog data from.
2. Edit RF_List.txt, filling out the variables to suit your environment, e.g. "UK Replication Group:UK Shared:LON-FS01:EDI-FS01".
3. (Optionally) Create a scheduled task using a task scheduler of your choice to run this on the regular. I tend to run this every 10 minutes or so, depending on the rate of change expected on the share in question.
4. Ingest the resulting ('Output.txt') file into a SIEM of your choosing. This has been testing & verified as working with Splunk & Elastic.

## A note on accounts
The underlying Powershell functionality this script leverages requires an account that is a member of the 'Administrators' group on both the source & destination machines being queried.
This is frustrating for a number of reasons, but the security risk can be (somewhat) mitigated by creating an administrative account in Active Directory, with an extremely strong password & limited logon capability (only to the machines in question).

As you'll likely be using this script to funnel data into a SIEM solution, I **strongly** suggest setting up alert rules to monitor when this specific account is logged into (or an attempt takes place).
