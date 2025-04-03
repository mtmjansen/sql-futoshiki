USE Futoshiki
GO

ALTER VIEW Looks AS
-- format a look that can be used with LIKE
SELECT --
	c.id,
	c.rowNr,
	c.columnNr,
	look = string_agg(isnull(cast(o.answer as char(1)), '_'),'-') WITHIN GROUP ( ORDER BY n.nr ),
	#answers = count(o.answer)
FROM dbo.Numbers n
INNER JOIN dbo.Cells c --
ON c.id IS NOT NULL -- all combinations
LEFT JOIN Options o --
ON o.id = c.id
AND o.answer = n.nr
WHERE n.nr BETWEEN 1 AND 7
GROUP BY --
	c.id,
	c.rowNr,
	c.columnNr
HAVING count(o.answer) BETWEEN 1 AND 6
GO
