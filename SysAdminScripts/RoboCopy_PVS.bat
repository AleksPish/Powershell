REM Robocopy from Build PVS server to Others
REM Deletes files from other server if not present on local server
Robocopy <PVS server new build is on> <Network location of other PVS servers in cluster> *.vhdx *.vhd *.avhd *.avhdx *.pvp /b /mir /r:5 /w:5 /xf *.lok /xd WriteCache /xo
PAUSE