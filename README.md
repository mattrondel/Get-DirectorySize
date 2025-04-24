#How to Use the Script - (One I forked didnt work)

Save the script to a file, like Analyze-DiskSpace.ps1

Run it with different parameters:

•	Basic usage (analyzes C: drive):
```
  powershell

  .\Analyze-DiskSpace.ps1
```

•	Specify a different path:

```
  powershell

  .\Analyze-DiskSpace.ps1 -Path "D:\Data"

```

•	Include files in the analysis (not just folders):
  
  ```
  powershell
  
  .\Analyze-DiskSpace.ps1 -IncludeFiles
```

•	Perform a recursive analysis (scan subfolders too):

  ```
  powershell

  .\Analyze-DiskSpace.ps1 -Recurse
```

##Features

•	Shows size in both GB and MB

•	Counts files and folders within each directory

•	Exports results to CSV for further analysis

•	Color-coded output for better readability

•	Shows drive statistics (total, used, free space)

•	Options to include files and scan recursive
