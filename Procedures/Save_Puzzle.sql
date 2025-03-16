USE Futoshiki
GO

ALTER PROCEDURE [dbo].[Save_Puzzle] 
	@PuzzleString varchar(200)
AS
BEGIN
	SET NOCOUNT ON

	IF(@PuzzleString IS NULL)
	BEGIN
		PRINT 'Validation failed. NULL not allowed.'

		RETURN
	END

	DECLARE --
		@TAB char(1) = char(9),
		@LF  char(1) = char(10),
		@CR  char(1) = char(13),
		@SPC char(1) = ' ',
		@NO  char(1) = '.',
		@validate varchar(133),
		@puzzleId int

	SET @PuzzleString = replace(@PuzzleString, @TAB, '')
	SET @PuzzleString = replace(@PuzzleString, @LF , '')
	SET @PuzzleString = replace(@PuzzleString, @CR , '')
	SET @PuzzleString = replace(@PuzzleString, @SPC, '')
	SET @PuzzleString = replace(@PuzzleString, '0', @NO)

	IF(len(@PuzzleString) <> 133)
	BEGIN
		PRINT 'Validation failed. Expected length 133 (49 + 42 + 42) after whitespace striping.'

		RETURN
	END

	SET @validate = @PuzzleString
	SET @validate = replace(@validate, '1', '')
	SET @validate = replace(@validate, '2', '')
	SET @validate = replace(@validate, '3', '')
	SET @validate = replace(@validate, '4', '')
	SET @validate = replace(@validate, '5', '')
	SET @validate = replace(@validate, '6', '')
	SET @validate = replace(@validate, '7', '')
	SET @validate = replace(@validate, '>', '')
	SET @validate = replace(@validate, '<', '')
	SET @validate = replace(@validate, @NO, '')

	IF(len(@validate) > 0)
	BEGIN
		PRINT concat('Validation failed. Found unexpected character ', left(@validate,1), '(', ascii(left(@validate,1)), ').')

		RETURN
	END

	INSERT INTO Puzzles (
			puzzle
	) VALUES (
		@PuzzleString
	)

	SET @puzzleId = SCOPE_IDENTITY()

	EXEC Start_Puzzle @puzzleId
END
GO
