USE [Futoshiki]
GO

ALTER PROCEDURE [dbo].[Init_HintIds] 
AS
BEGIN
	SET NOCOUNT ON

	TRUNCATE TABLE [dbo].[HintIds];

	WITH cte_horizontal AS (
		SELECT --
			posId = nr,
			rowNr = (nr-50)/6+1,
			columnNr = (nr-50)%6+1
		FROM [dbo].[Numbers] n
		WHERE n.nr BETWEEN 50 AND 91
	), 
	cte_vertical AS (
		SELECT --
			posId = nr,
			rowNr = (nr-92)%6+1,
			columnNr = (nr-92)/6+1
		FROM [dbo].[Numbers] n
		WHERE n.nr BETWEEN 92 AND 133
	)
	INSERT INTO [dbo].[HintIds] (
		posId,
		idLesser,
		idGreater,
		rowNr,
		columnNr
	)
	SELECT --
		posId,
		idLesser,
		idGreater,
		rowNr,
		columnNr
	FROM (
		SELECT --
			posId,
			idLesser = c.id,
			idGreater = c.id + 1,
			c.rowNr,
			c.columnNr
		FROM cte_horizontal h
		INNER JOIN dbo.Cells c --
		ON c.rowNr = h.rowNr
		AND c.columnNr = h.columnNr

		UNION

		SELECT --
			posId,
			idLesser = c.id,
			idGreater = c.id + 7,
			c.rowNr,
			c.columnNr
		FROM cte_vertical v
		INNER JOIN dbo.Cells c --
		ON c.rowNr = v.rowNr
		AND c.columnNr = v.columnNr
	) lvl0
END
GO
