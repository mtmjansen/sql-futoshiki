USE Futoshiki
GO

ALTER PROCEDURE Init_Futoshiki
AS
BEGIN
	SET NOCOUNT ON

	DECLARE --
		@rowDim tinyint = 7,
		@columnDim tinyint = 7;

	DECLARE --
		@maxDim tinyint = CASE WHEN @rowDim > @columnDim THEN @rowDim ELSE @columnDim END

	-- Numbers
	TRUNCATE TABLE [dbo].[Numbers]

	INSERT INTO [dbo].[Numbers]
	SELECT TOP 200 --
		nr = row_number() over (order by object_id)
	FROM sys.columns

	-- Cells
	TRUNCATE TABLE [dbo].[Cells];

	WITH cells AS (
		SELECT --
			id = cast(nr as tinyint),
			rowNr = cast(1 + (nr-1)/@rowDim as tinyint),
			columnNr = cast(1 + (nr-1) % @rowDim as tinyint)
		FROM Numbers
		WHERE nr < @rowDim * @columnDim + 1
	)
	INSERT INTO dbo.[Cells]
	SELECT --
		id,
		rowNr,
		columnNr
	FROM cells

	-- Combos
	-- TODO make dynamic to @maxDim
	TRUNCATE TABLE [dbo].[Combos];

	WITH cte_combos
	AS (
		SELECT --
			#answers = 1,
			highest = n.nr,
			look = stuff('_-_-_-_-_-_-_', n.nr * 2 - 1, 1, cast(n.nr AS CHAR(1)))
		FROM Numbers n
		WHERE n.nr BETWEEN 1 AND 7
	
		UNION ALL
	
		SELECT --
			#answers = c.#answers + 1,
			highest = n.nr,
			look = stuff(c.look, n.nr * 2 - 1, 1, cast(n.nr AS CHAR(1)))
		FROM cte_combos c
		INNER JOIN Numbers n --
		ON n.nr > c.highest
		WHERE n.nr BETWEEN 1 AND 7
			AND c.#answers < 7
	)
	INSERT INTO [dbo].[Combos]
	SELECT --
		#answers,
		look
	FROM cte_combos
	WHERE #answers > 1
	ORDER BY --
		#answers,
		look DESC

	EXEC [dbo].[Init_HintIds]
END
GO
