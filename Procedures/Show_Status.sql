USE Futoshiki
GO

ALTER PROCEDURE Show_Status 
	@WithPuzzle bit = 0
AS
BEGIN
	SET NOCOUNT ON

	DECLARE @NO char(1) = '.';

	IF @WithPuzzle = 1
	BEGIN
		WITH cte_columns AS (
			SELECT
				p.rowNr,
				p.columnNr,
				r = (n.nr+1)/2,
				alpha = char(64+n.nr/2),
				[1] = CASE 
					WHEN n.nr % 2 = 1 AND p.columnNr = 1 THEN cast(answer AS CHAR)
					WHEN n.nr % 2 = 0 AND h.columnNr = 1 AND h.isHorizontal = 0 THEN h.hint 
					WHEN n.nr % 2 = 1 THEN '.'
					ELSE ' ' 
				END,
				[A] = CASE WHEN n.nr % 2 = 1 AND h.columnNr = 1 AND h.isHorizontal = 1 THEN hint ELSE ' ' END,
				[2] = CASE 
					WHEN n.nr % 2 = 1 AND p.columnNr = 2 THEN cast(answer AS CHAR)
					WHEN n.nr % 2 = 0 AND h.columnNr = 2 AND h.isHorizontal = 0 THEN h.hint 
					WHEN n.nr % 2 = 1 THEN '.'
					ELSE ' ' 
				END,
				[B] = CASE WHEN n.nr % 2 = 1 AND h.columnNr = 2 AND h.isHorizontal = 1 THEN hint ELSE ' ' END,
				[3] = CASE 
					WHEN n.nr % 2 = 1 AND p.columnNr = 3 THEN cast(answer AS CHAR)
					WHEN n.nr % 2 = 0 AND h.columnNr = 3 AND h.isHorizontal = 0 THEN h.hint 
					WHEN n.nr % 2 = 1 THEN '.'
					ELSE ' ' 
				END,
				[C] = CASE WHEN n.nr % 2 = 1 AND h.columnNr = 3 AND h.isHorizontal = 1 THEN hint ELSE ' ' END,
				[4] = CASE 
					WHEN n.nr % 2 = 1 AND p.columnNr = 4 THEN cast(answer AS CHAR)
					WHEN n.nr % 2 = 0 AND h.columnNr = 4 AND h.isHorizontal = 0 THEN h.hint 
					WHEN n.nr % 2 = 1 THEN '.'
					ELSE ' ' 
				END,
				[D] = CASE WHEN n.nr % 2 = 1 AND h.columnNr = 4 AND h.isHorizontal = 1 THEN hint ELSE ' ' END,
				[5] = CASE 
					WHEN n.nr % 2 = 1 AND p.columnNr = 5 THEN cast(answer AS CHAR)
					WHEN n.nr % 2 = 0 AND h.columnNr = 5 AND h.isHorizontal = 0 THEN h.hint 
					WHEN n.nr % 2 = 1 THEN '.'
					ELSE ' ' 
				END,
				[E] = CASE WHEN n.nr % 2 = 1 AND h.columnNr = 5 AND h.isHorizontal = 1 THEN hint ELSE ' ' END,
				[6] = CASE 
					WHEN n.nr % 2 = 1 AND p.columnNr = 6 THEN cast(answer AS CHAR)
					WHEN n.nr % 2 = 0 AND h.columnNr = 6 AND h.isHorizontal = 0 THEN h.hint 
					WHEN n.nr % 2 = 1 THEN '.'
					ELSE ' ' 
				END,
				[F] = CASE WHEN n.nr % 2 = 1 AND h.columnNr = 6 AND h.isHorizontal = 1 THEN hint ELSE ' ' END,
				[7] = CASE 
					WHEN n.nr % 2 = 1 AND p.columnNr = 7 THEN cast(answer AS CHAR)
					WHEN n.nr % 2 = 0 AND h.columnNr = 7 AND h.isHorizontal = 0 THEN h.hint 
					WHEN n.nr % 2 = 1 THEN '.'
					ELSE ' ' 
				END
			FROM Numbers n
			LEFT JOIN Puzzle p --
			ON p.rowNr = (n.nr+1)/2
			LEFT JOIN Hints h
			ON h.rowNr = (n.nr+1)/2
			WHERE nr BETWEEN 1 AND 13
		)
		SELECT
			[#] =  case when (ROW_NUMBER() over (order by rowNr, alpha))%2=0 then ' ' else cast(rowNr as char) end,
			[1] = isnull(max([1]), @NO),
			[ ] = isnull(max([A]), ' '),
			[2] = isnull(max([2]), @NO),
			[ ] = isnull(max([B]), ' '),
			[3] = isnull(max([3]), @NO),
			[ ] = isnull(max([C]), ' '),
			[4] = isnull(max([4]), @NO),
			[ ] = isnull(max([D]), ' '),
			[5] = isnull(max([5]), @NO),
			[ ] = isnull(max([E]), ' '),
			[6] = isnull(max([6]), @NO),
			[ ] = isnull(max([F]), ' '),
			[7] = isnull(max([7]), @NO)
		FROM cte_columns c
		GROUP BY rowNr,alpha
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
