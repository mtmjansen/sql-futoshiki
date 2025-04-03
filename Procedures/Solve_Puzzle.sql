USE Futoshiki
GO

ALTER PROCEDURE Solve_Puzzle --
AS
BEGIN
	SET NOCOUNT ON

	DECLARE --
		@OptionsBefore int = 7*7*7,
		@OptionsAfter int = 1,
		@CellSolved int = 0,
		@Iteration int = 0

	WHILE @OptionsBefore > @OptionsAfter AND @OptionsAfter > 0
	BEGIN
		SELECT @OptionsBefore = count(*) FROM [dbo].[Options]

		SET @Iteration = @Iteration + 1

		EXEC [dbo].[Reduce_Options]

		SELECT @OptionsAfter = count(*) FROM [dbo].[Options]

		IF(@OptionsBefore <> @OptionsAfter)
		BEGIN
			EXEC [dbo].[Show_Status] 1, @Iteration
		END
	END

	IF @OptionsAfter > 0
	BEGIN
		THROW 50000, 'I give up!', 0
	END

	SELECT @CellSolved = count(*) FROM Puzzle
	IF @CellSolved < 7*7
	BEGIN
		THROW 50000, 'I failed! :-(', 0
	END 
END
GO
