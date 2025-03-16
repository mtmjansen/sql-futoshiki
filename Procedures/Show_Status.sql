USE Futoshiki
GO

ALTER PROCEDURE Show_Status 
	@WithPuzzle bit = 0
AS
BEGIN
	SET NOCOUNT ON

	DECLARE @NO char(1) = '.'

	IF @WithPuzzle = 1
	BEGIN
		WITH cte_columns AS (
			SELECT 
				rowNr = n.nr,
				[1] = CASE columnNr WHEN 1 THEN cast(answer AS CHAR) END,
				[2] = CASE columnNr WHEN 2 THEN cast(answer AS CHAR) END,
				[3] = CASE columnNr WHEN 3 THEN cast(answer AS CHAR) END,
				[4] = CASE columnNr WHEN 4 THEN cast(answer AS CHAR) END,
				[5] = CASE columnNr WHEN 5 THEN cast(answer AS CHAR) END,
				[6] = CASE columnNr WHEN 6 THEN cast(answer AS CHAR) END,
				[7] = CASE columnNr WHEN 7 THEN cast(answer AS CHAR) END
			FROM Numbers n
			LEFT JOIN Puzzle p --
			ON p.rowNr = n.nr
			WHERE nr BETWEEN 1 AND 7
		)
		SELECT 
			[1] = isnull(max([1]), @NO),
			[2] = isnull(max([2]), @NO),
			[3] = isnull(max([3]), @NO),
			[4] = isnull(max([4]), @NO),
			[5] = isnull(max([5]), @NO),
			[6] = isnull(max([6]), @NO),
			[7] = isnull(max([7]), @NO)
		FROM cte_columns c
		GROUP BY rowNr
		ORDER BY rowNr
	END
	
	DECLARE --
		@Iteration int = 0,
		@OptionsLeft int,
		@CellSolved int

	SELECT @OptionsLeft = count(*) FROM Options
	SELECT @CellSolved = count(*) FROM Puzzle

	SELECT --
		[Iteration] = CAST(@Iteration AS int),
		[#CellsSolved] = @CellSolved,
		[Target] = 49,
		[%CellsSolved] = cast(100.0 * @CellSolved / 49.0 as decimal (9,1)),
		[#OptionsLeft ] = @OptionsLeft,
		[Total] = 343,
		[%OptionsLeft] = cast(100.0 * @OptionsLeft / 343.0 as decimal (9,1))

		SET @Iteration = @Iteration + 1
END
GO
