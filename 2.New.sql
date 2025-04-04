USE Futoshiki
GO

DECLARE @Puzzle varchar(200) 

SET @Puzzle = '
0260000
0005000
6000004
0402067
0040000
0000000
0000000

......
.>..>.
<.....
......
......
....>.
<..<..

.>.>..
....>.
...>..
......
>.....
..<>.>
.>..><'

EXEC Save_Puzzle @Puzzle
GO