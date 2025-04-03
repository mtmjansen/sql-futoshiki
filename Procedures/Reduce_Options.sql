USE Futoshiki
GO

ALTER PROCEDURE Reduce_Options
AS
BEGIN
	; WITH cells_with_one_option AS (
		SELECT id
		FROM Options
		GROUP BY id
		HAVING count(*) = 1
	)
	INSERT INTO Puzzle
	SELECT o.*
	FROM Options o
	INNER JOIN cells_with_one_option cte
	ON cte.id = o.id

	EXEC Update_Options

	; WITH rows_with_option_on_single_column AS (
		select rowNr, answer
		from options
		group by rowNr, answer
		having count(*) = 1
	)
	INSERT INTO Puzzle
	SELECT o.*
	FROM Options o
	INNER JOIN rows_with_option_on_single_column cte
	ON cte.rowNr = o.rowNr
	AND cte.answer = o.answer

	EXEC Update_Options

	; WITH columns_with_value_on_single_row AS (
		select columnNr,answer
		from options
		group by columnNr,answer
		having count(*) = 1
	)
	INSERT INTO Puzzle
	SELECT o.*
	FROM Options o
	INNER JOIN columns_with_value_on_single_row cte
	ON cte.columnNr = o.columnNr
	AND cte.answer = o.answer

	EXEC Update_Options

	--EXEC Reduce_LookAlikes
END
GO
