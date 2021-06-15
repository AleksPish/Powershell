Add-Type -Assembly system.windows.forms
Add-Type -Assembly system.Drawing
$main = New-Object system.windows.forms.form
$main.text ='gui'
$main.width = 600
$main.height = 600


$OKbutton = New-Object System.Windows.Forms.Button
$OKbutton.Location = New-Object System.Drawing.Point(50,50)
$OKbutton.Size = New-Object System.Drawing.Size(75,25)
$OKbutton.Text = "OK"
$OKbutton.DialogResult = [System.Windows.Forms.DialogResult]::OK
$main.AcceptButton = $OKbutton
$main.Controls.Add($OKbutton)

$main.ShowDialog()