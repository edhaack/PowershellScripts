#region Select-ObjectEx
function Get-TypeName
{
	begin
	{
		$List = @()
	}
	process
	{
		foreach ($i in $_.PSObject.TypeNames)
		{
			if ($List -inotcontains $i)
			{
				$List += $i
				$i
			}
		}
	}
}

function Get-FormatView
{
	foreach ($i in @(Get-FormatData -TypeName @($input | Get-TypeName)))
	{
		$i.FormatViewDefinition
	}
}

function Get-PropertyData($prop)
{
	$input | %{
		if ($_.Control.Headers -and $_.Control.Rows.Count -gt 0)
		{
			for ($i = 0; $i -lt $_.Control.Headers.count; $i++)
			{
				if ($_.Control.Headers[$i].Label -eq $prop)
				{
					$row = $_.Control.Rows[0]
					if ($row.Columns.Count -gt $i)
					{
						$val = $row.Columns[$i].DisplayEntry.Value
						if ($val)
						{
							if ($row.Columns[$i].DisplayEntry.ValueType -eq 'ScriptBlock')
							{
								$v = [ScriptBlock]::Create($val)
							}
							else
							{
								$v = [ScriptBlock]::Create("`$_.$val")
							}
							@{Name=$prop; Expression=$v}
							return
						}
					}
				}
			}
		}
	}
}

function Get-PropertiesData($props)
{
	$formatview = $input | Get-FormatView
	
	foreach ($prop in $props)
	{
		$val = $formatview | Get-PropertyData $prop
		if ($val)
		{
			$val
		}
		else
		{
			$prop
		}
	}
}

function Select-ObjectEx($Property)
{
	$propdata = @($input | Get-PropertiesData $Property)
	
	$input.Reset()
	$input | select -Property $propdata
}
#endregion

function FilterProperties($All)
{
	process
	{
		if ($All)
		{
			$_
		}
		else
		{
			$origType = $_.PSObject.TypeNames[0]
			$_ | Select-ObjectEx -Property $PGResultsDisplayedColumns | %{
				#$_.PSObject.TypeNames.Insert(0, $origType)
				$_
			}
		}
	}
}

function CanSave($File)
{
	if (Test-Path "$File")
	{
		$Yes = New-Object System.Management.Automation.Host.ChoiceDescription "&Yes", "Overwrite existing file";
		$No = New-Object System.Management.Automation.Host.ChoiceDescription "&No", "Do not overwrite existing file";
		$choices = [System.Management.Automation.Host.ChoiceDescription[]]($Yes, $No);

		if ($host.UI.PromptForChoice("File exists", "File '$File' already exists. Do you want to overwrite it?", $choices, 1) -ne 0)
		{
			$false
			return
		}
	}
	
	$true
}