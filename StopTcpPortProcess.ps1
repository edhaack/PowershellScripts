$rawResult = netstat -ano | Select-String "8888"
#{  
#TCP    0.0.0.0:2002           0.0.0.0:0              LISTENING       9816,   
#TCP    127.0.0.1:2002         127.0.0.1:55256        ESTABLISHED     9816,   
#TCP    127.0.0.1:55256        127.0.0.1:2002         ESTABLISHED     8108}
if ($rawResult) { 
	$firstResult = $rawResult[0]
	#  TCP    0.0.0.0:2002           0.0.0.0:0              LISTENING       9816
	$finalResult = $firstResult -replace " "
	#TCP0.0.0.0:20020.0.0.0:0LISTENING9816
	$listening = "LISTENING"
	$listeningIndex = $finalResult.IndexOf("G") + 1
	$tcpPortToKill = $finalResult.Substring($listeningIndex)
	#9816
	Stop-Process $tcpPortToKill
} else {
	"Nothing to kill..."
}
