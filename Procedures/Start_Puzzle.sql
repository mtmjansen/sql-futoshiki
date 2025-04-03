USE Futoshiki
GO

ALTER PROCEDURE Start_Puzzle --
	@PuzzleId int = 0 -- last
AS
BEGIN
	SET NOCOUNT ON

	DECLARE @NO char(1) = '.'

	IF(@PuzzleId = 0)
	BEGIN
		SELECT @PuzzleId = max(puzzleId) FROM [dbo].[Puzzles]
	END

	PRINT concat('Starting puzzle ', @PuzzleId)

	EXEC [dbo].[Reset_Options]

	TRUNCATE TABLE [dbo].[Puzzle]

	INSERT INTO Puzzle
	SELECT --
		c.[id],
		c.[rowNr],
		c.[columnNr],
		fact = substring(p.puzzle, c.id, 1)
	FROM Cells c
	INNER JOIN [dbo].[Puzzles] p 
	ON substring(p.puzzle, c.id, 1) <> @NO
	WHERE p.puzzleId = @PuzzleId

	TRUNCATE TABLE [dbo].[Hints]

	INSERT INTO [dbo].[Hints] (
		idLesser,
		idGreater,
		hint,
		rowNr,
		columnNr,
		isHorizontal
	)
	SELECT 
		h.idLesser,
		h.idGreater,
		case when posId < 92 
			then substring(p.puzzle, h.posId, 1)
			ELSE '^' 
		END,
		c.rowNr,
		c.columnNr,
		h.isHorizontal
	FROM [dbo].[Puzzles] p
	INNER JOIN [dbo].[HintIds] h
	ON substring(p.puzzle, h.posId, 1) = '<'
	INNER JOIN dbo.Cells c
	ON c.id = h.idLesser
	WHERE p.puzzleId = @PuzzleId

	INSERT INTO [dbo].[Hints] (
		idLesser,
		idGreater,
		hint,
		rowNr,
		columnNr,
		isHorizontal
	)
	SELECT
		-- reverse lesser & greater
		h.idGreater,
		h.idLesser,
		case when posId < 92 
			then substring(p.puzzle, h.posId, 1)
			ELSE 'v' 
		END,
		c.rowNr,
		c.columnNr,
		h.isHorizontal
	FROM [dbo].[Puzzles] p
	INNER JOIN [dbo].[HintIds] h
	ON substring(p.puzzle, h.posId, 1) = '>'
	INNER JOIN dbo.Cells c
	ON c.id = h.idLesser
	WHERE p.puzzleId = @PuzzleId

	EXEC [dbo].[Update_Options]

	EXEC [dbo].[Show_Status] 1
END
GO
