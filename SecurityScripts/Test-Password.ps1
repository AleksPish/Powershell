function Test-Password
{
  [CmdletBinding()]
  param
  (
    [Parameter(Mandatory, Position=0)]
    [System.Security.SecureString]
    $Password
  )
  
  # take securestring and get the entered plain text password
  # we are using a securestring only to get a masked input box:
  $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($Password)
  $plain = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
    
  # hash the password:
  $bytes = [Text.Encoding]::UTF8.GetBytes($plain)
  $stream = [IO.MemoryStream]::new($bytes)
  $hash = Get-FileHash -Algorithm 'SHA1' -InputStream $stream
  $stream.Close()
  $stream.Dispose()
  
  # separate the first 5 hash characters from the rest:
  $first5hashChars,$remainingHashChars = $hash.Hash -split '(?<=^.{5})'
  
  # send the first 5 hash characters to the webservice:
  $url = "https://api.pwnedpasswords.com/range/$first5hashChars"
  [Net.ServicePointManager]::SecurityProtocol = 'Tls12'
  $response = Invoke-RestMethod -Uri $url -UseBasicParsing
  
  # split result into individual lines...
  $lines = $response -split '\r\n'
  # ...and get the line where the returned hash matches your
  # remainder of the hash that you kept private:
  $filteredLines = $lines -like "$remainingHashChars*"
  
  # return the number of compromises:
  [int]($filteredLines -split ':')[-1]
}