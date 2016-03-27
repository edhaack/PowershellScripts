dim csvFile
csvFile = WScript.Arguments.Item(0)


'dim desc, url
'desc = WScript.Arguments.Item(0)
'url = WScript.Arguments.Item(1)

set WshShell = WScript.CreateObject("WScript.Shell")
desktopFolder = WshShell.SpecialFolders("Desktop")
set link = WshShell.CreateShortcut(desktopFolder & "\" & desc & ".url")
link.TargetPath = url
link.Save

Function CSVArray(CSVFile)
 
  Dim comma, quote
  comma = ","
  quote = Chr(34)
 
  Dim charPos, charVal
 
  Dim cellPos, colMax, colNum
  colMax  = -1
  
  Dim cellArray(), cellComplete, cellQuoted, csvRecord
 
  Dim inCsvSys, inCsv, inRow(), rowCount
  rowCount     = -1
  Set inCsvSys = CreateObject("Scripting.FileSystemObject") 
  Set inCsv    = inCsvSys.OpenTextFile(CSVFile,"1",True)
  Do While Not inCsv.AtEndOfStream
    rowCount = rowCount + 1
    Redim Preserve inRow(rowCount)
    inRow(rowCount) = inCsv.ReadLine
  Loop
  inCsv.Close
 
  For r = 0 to rowCount
  
    csvRecord = inRow(r)
    colNum = -1
    charPos = 0
    cellComplete = True
    
    Do While charPos < Len(csvRecord)
 
      If (cellComplete = True) Then
        colNum       = colNum + 1
        cellPos      = 0
        cellQuoted   = False
        cellComplete = False
        If colNum > colMax Then
          colMax = colNum
          Redim Preserve cellArray(rowCount,colMax)
        End If              
      End If
 
      charPos = charPos + 1
      cellPos = cellPos + 1
      charVal = Mid(csvRecord, charPos, 1)
      If (charVal = quote) Then
        If (cellPos = 1) Then
          cellQuoted = True
          charVal    = ""
        Else
          Select Case Mid(csvRecord, charPos+1, 1)
          Case quote
            charPos = charPos + 1
          Case comma
            charPos = charPos + 1
            cellComplete = True 
          End Select
        End If
      ElseIf (charVal = comma) And (cellQuoted = False) Then
        cellComplete = True
      End If
      If (cellComplete = False) Then
        cellArray(r,colNum) = cellArray(r,colNum)&charVal
      End If
 
    Loop
 
  Next
  CSVArray = cellArray
End Function