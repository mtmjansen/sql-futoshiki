USE Futoshiki
GO

ALTER PROCEDURE Reset_Options AS
BEGIN
	SET NOCOUNT ON

	DECLARE @maxDim tinyint = 7

	TRUNCATE TABLE Options

	INSERT INTO Options
	SELECT 
		c.*,
		answer = CAST(nr as tinyint)
	FROM Cells c
	INNER JOIN Numbers n
	ON nr between 1 AND @maxDim
END
GO
