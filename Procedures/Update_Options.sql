USE Futoshiki
GO

ALTER PROCEDURE Update_Options
AS
BEGIN
	SET NOCOUNT ON

	DELETE o
	FROM Options o
	RIGHT JOIN Puzzle p
	ON p.id = o.id -- all options for this cell
	OR (p.rowNr = o.rowNr AND p.answer = o.answer) -- options in the row with same value
	OR (p.columnNr = o.columnNr AND p.answer = o.answer) -- options in the column with same value
	WHERE p.id IS NOT NULL
END
GO
