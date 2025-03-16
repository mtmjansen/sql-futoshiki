USE Futoshiki
GO

ALTER PROCEDURE dbo.Init_HintIds 
AS
BEGIN
	SET NOCOUNT ON

	TRUNCATE TABLE [dbo].[HintIds];

	WITH cte_horizontal AS (
		SELECT --
			hintId = nr,
			rowNr = (nr-82)/6+1,
			columnNr = (nr-82)%6+1
		FROM [dbo].[Numbers] n
		WHERE n.nr BETWEEN 82 AND 123
	), 
	cte_vertical AS (
		SELECT --
			hintId = nr,
			rowNr = (nr-124)%6+1,
			columnNr = (nr-124)/6+1
		FROM [dbo].[Numbers] n
		WHERE n.nr BETWEEN 124 AND 165
	)
	INSERT INTO [dbo].[HintIds] (
		hintId,
		idLesser,
		idGreater
	)
	SELECT --
		hintId,
		idLesser,
		idGreater
	FROM (
		SELECT --
			hintId,
			idLesser = c.id,
			idGreater = c.id + 1
		FROM cte_horizontal h
		INNER JOIN dbo.Cells c --
		ON c.rowNr = h.rowNr
		AND c.columnNr = h.columnNr

		UNION

		SELECT --
			hintId,
			idLesser = c.id,
			idGreater = c.id + 7
		FROM cte_vertical v
		INNER JOIN dbo.Cells c --
		ON c.rowNr = v.rowNr
		AND c.columnNr = v.columnNr
	) lvl0
END
GO