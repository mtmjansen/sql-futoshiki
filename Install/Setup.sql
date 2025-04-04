USE [master]
GO

/****** Object:  Database [Futoshiki]    Script Date: 4-4-2025 21:54:41 ******/
CREATE DATABASE [Futoshiki]
GO

ALTER DATABASE [Futoshiki] SET READ_ONLY
GO

ALTER DATABASE [Futoshiki] SET COMPATIBILITY_LEVEL = 160
GO

USE [Futoshiki]
GO

/****** Object:  Table [dbo].[Numbers]    Script Date: 4-4-2025 21:54:41 ******/
CREATE TABLE [dbo].[Numbers](
	[nr] [bigint] NOT NULL,
	CONSTRAINT [PK_Numbers] PRIMARY KEY CLUSTERED 
	(
		[nr] ASC
	)
) ON [PRIMARY]
GO

/****** Object:  Table [dbo].[Cells]    Script Date: 4-4-2025 21:54:41 ******/
CREATE TABLE [dbo].[Cells](
	[id] [tinyint] NOT NULL,
	[rowNr] [tinyint] NOT NULL,
	[columnNr] [tinyint] NOT NULL,
	CONSTRAINT [PK_Cells] PRIMARY KEY CLUSTERED 
	(
		[id] ASC
	)
) ON [PRIMARY]
GO

/****** Object:  Table [dbo].[Options]    Script Date: 4-4-2025 21:54:41 ******/
CREATE TABLE [dbo].[Options](
	[id] [tinyint] NOT NULL,
	[rowNr] [tinyint] NOT NULL,
	[columnNr] [tinyint] NOT NULL,
	[answer] [tinyint] NULL
) ON [PRIMARY]
GO

/****** Object:  View [dbo].[Looks]    Script Date: 4-4-2025 21:54:41 ******/

CREATE VIEW [dbo].[Looks] AS
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

/****** Object:  Table [dbo].[Combos]    Script Date: 4-4-2025 21:54:41 ******/
CREATE TABLE [dbo].[Combos](
	[#answers] [tinyint] NOT NULL,
	[look] [char](20) NOT NULL,
	[comboId] [int] IDENTITY(1,1) NOT NULL,
	CONSTRAINT [PK_Combos] PRIMARY KEY CLUSTERED 
	(
		[comboId] ASC
	)
) ON [PRIMARY]
GO

/****** Object:  Table [dbo].[HintIds]    Script Date: 4-4-2025 21:54:41 ******/
CREATE TABLE [dbo].[HintIds](
	[posId] [smallint] NOT NULL,
	[idLesser] [tinyint] NOT NULL,
	[idGreater] [int] NULL,
	[rowNr] [tinyint] NOT NULL,
	[columnNr] [tinyint] NOT NULL,
	[isHorizontal] [bit] NOT NULL
) ON [PRIMARY]
GO

/****** Object:  Table [dbo].[Hints]    Script Date: 4-4-2025 21:54:41 ******/
CREATE TABLE [dbo].[Hints](
	[hintId] [tinyint] IDENTITY(1,1) NOT NULL,
	[idLesser] [tinyint] NOT NULL,
	[idGreater] [tinyint] NOT NULL,
	[hint] [char](1) NOT NULL,
	[rowNr] [tinyint] NOT NULL,
	[columnNr] [tinyint] NOT NULL,
	[IsHorizontal] [bit] NOT NULL,
	CONSTRAINT [PK_Hints] PRIMARY KEY CLUSTERED 
	(
		[hintId] ASC
	)
) ON [PRIMARY]
GO

/****** Object:  Table [dbo].[Puzzle]    Script Date: 4-4-2025 21:54:41 ******/
CREATE TABLE [dbo].[Puzzle](
	[id] [tinyint] NOT NULL,
	[rowNr] [tinyint] NOT NULL,
	[columnNr] [tinyint] NOT NULL,
	[answer] [tinyint] NULL,
	CONSTRAINT [PK_Puzzle] PRIMARY KEY CLUSTERED 
	(
		[id] ASC
	)
) ON [PRIMARY]
GO

/****** Object:  Table [dbo].[Puzzles]    Script Date: 4-4-2025 21:54:41 ******/
CREATE TABLE [dbo].[Puzzles](
	[puzzleId] [int] IDENTITY(1,1) NOT NULL,
	[puzzle] [char](133) NOT NULL,
	[comment] [nvarchar](50) NULL,
	[page] [int] NULL,
	[stars] [int] NULL,
	CONSTRAINT [PK_PuzzlesNew] PRIMARY KEY CLUSTERED 
	(
		[puzzleId] ASC
	)
) ON [PRIMARY]
GO

/****** Object:  StoredProcedure [dbo].[Init_Futoshiki]    Script Date: 4-4-2025 21:54:41 ******/

CREATE PROCEDURE [dbo].[Init_Futoshiki]
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

/****** Object:  StoredProcedure [dbo].[Init_HintIds]    Script Date: 4-4-2025 21:54:41 ******/

CREATE PROCEDURE [dbo].[Init_HintIds] 
AS
BEGIN
	SET NOCOUNT ON

	TRUNCATE TABLE [dbo].[HintIds];

	WITH cte_horizontal AS (
		SELECT --
			posId = nr,
			rowNr = (nr-50)/6+1,
			columnNr = (nr-50)%6+1,
			isHorizontal = 1
		FROM [dbo].[Numbers] n
		WHERE n.nr BETWEEN 50 AND 91
	), 
	cte_vertical AS (
		SELECT --
			posId = nr,
			rowNr = (nr-92)%6+1,
			columnNr = (nr-92)/6+1,
			isHorizontal = 0
		FROM [dbo].[Numbers] n
		WHERE n.nr BETWEEN 92 AND 133
	)
	INSERT INTO [dbo].[HintIds] (
		posId,
		idLesser,
		idGreater,
		rowNr,
		columnNr,
		isHorizontal
	)
	SELECT --
		posId,
		idLesser,
		idGreater,
		rowNr,
		columnNr,
		isHorizontal
	FROM (
		SELECT --
			posId,
			idLesser = c.id,
			idGreater = c.id + 1,
			c.rowNr,
			c.columnNr,
			h.isHorizontal
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
			c.columnNr,
			v.isHorizontal
		FROM cte_vertical v
		INNER JOIN dbo.Cells c --
		ON c.rowNr = v.rowNr
		AND c.columnNr = v.columnNr
	) lvl0
END
GO

/****** Object:  StoredProcedure [dbo].[Reduce_LookAlikes]    Script Date: 4-4-2025 21:54:41 ******/

CREATE PROCEDURE [dbo].[Reduce_LookAlikes]
AS
BEGIN
	SET NOCOUNT ON

	DECLARE --
		@groupType INT = 0 	-- 1 = row, 2 = column

	WHILE @groupType < 3
	BEGIN
		SET @groupType = @groupType + 1;
	
		WITH cte_options
		AS (
			SELECT --
				o.id,
				g = CASE @groupType
					WHEN 1
						THEN o.rowNr
					WHEN 2
						THEN o.columnNr
					END,
				o.answer
			FROM dbo.Options o
			),
		cte_looks
		AS (
			SELECT l.id,
				g = CASE @groupType
					WHEN 1
						THEN l.rowNr
					WHEN 2
						THEN l.columnNr
					END,
				l.look
			FROM dbo.Looks l
			),
		cte_count_todo
		AS (
			SELECT -- count the todo cells 
				o.g,
				#todo = count(DISTINCT o.id)
			FROM cte_options o
			GROUP BY o.g
			),
		cte_look_alikes
		AS (
			SELECT -- find the cells with (some of) the same values
				l.look,
				l.#answers,
				lookalike = a.id,
				a.g
			FROM dbo.Combos l
			INNER JOIN cte_looks a -- look-a-likes
				ON l.look LIKE a.look
			),
		cte_reducers
		AS (
			SELECT -- cells with enough look-alikes but less than cells to be determined
				la.g,
				la.look
			FROM cte_look_alikes la
			INNER JOIN cte_count_todo td --
				ON td.g = la.g
			GROUP BY --
				la.g,
				la.look
			HAVING count(*) = max(la.#answers)
				AND count(*) < max(td.#todo)
			)
		DELETE d -- reduce options in the cells that also contain different options
		FROM cte_reducers grp
		-- what values could be reduced
		CROSS APPLY string_split(grp.look, '-') o
		INNER JOIN options d -- all options within the group with the same value
			ON CASE @groupType
				WHEN 1
					THEN d.rowNr
				WHEN 2
					THEN d.columnNr
				END = grp.g
			AND d.answer = CAST(o.value AS TINYINT)
		LEFT JOIN cte_looks l -- attach their look
			ON l.g = grp.g
			AND l.id = d.id
		WHERE grp.look NOT LIKE l.look -- reduce from cells that also contain different options
			AND o.[value] <> '_'
	END
END
GO

/****** Object:  StoredProcedure [dbo].[Reduce_Options]    Script Date: 4-4-2025 21:54:41 ******/

CREATE PROCEDURE [dbo].[Reduce_Options]
AS
BEGIN
	; WITH cte_must_be_gt_answer AS (
		SELECT --
			h.idGreater,
			smallest = min(lesser.answer)
		FROM dbo.Hints h
		INNER JOIN dbo.Puzzle lesser --
		ON lesser.Id = h.idLesser
		GROUP BY --
			h.idLesser, 
			h.idGreater
	)
	DELETE o
	FROM Options o
	RIGHT JOIN cte_must_be_gt_answer c
	ON c.idGreater = o.id
	AND NOT c.smallest < o.answer

	; WITH cte_must_be_lt_answer AS (
		SELECT --
			h.idLesser, 
			largest = max(greater.answer)
		FROM dbo.Hints h
		INNER JOIN dbo.Puzzle greater
		ON greater.Id = h.idGreater
		GROUP BY --
			h.idLesser, 
			h.idGreater
	)
	DELETE o
	FROM Options o
	RIGHT JOIN cte_must_be_lt_answer c
	ON c.idLesser = o.id
	AND NOT c.largest > o.answer

	; WITH cte_must_be_gt AS (
		SELECT --
			h.idGreater,
			smallest = min(lesser.answer)
		FROM dbo.Hints h
		INNER JOIN dbo.Options lesser --
		ON lesser.Id = h.idLesser
		GROUP BY --
			h.idLesser, 
			h.idGreater
	)
	DELETE o
	FROM Options o
	RIGHT JOIN cte_must_be_gt c
	ON c.idGreater = o.id
	AND NOT c.smallest < o.answer

	; WITH cte_must_be_lt AS (
		SELECT --
			h.idLesser, 
			largest = max(greater.answer)
		FROM dbo.Hints h
		INNER JOIN dbo.Options greater
		ON greater.Id = h.idGreater
		GROUP BY --
			h.idLesser, 
			h.idGreater
	)
	DELETE o
	FROM Options o
	RIGHT JOIN cte_must_be_lt c
	ON c.idLesser = o.id
	AND NOT c.largest > o.answer

	; WITH cells_with_one_option AS (
		SELECT id
		FROM Options
		GROUP BY id
		HAVING count(*) = 1
	)
	INSERT INTO Puzzle
	SELECT o.*
	FROM Options o
	INNER JOIN cells_with_one_option cte
	ON cte.id = o.id

	EXEC Update_Options

	; WITH rows_with_option_on_single_column AS (
		select rowNr, answer
		from options
		group by rowNr, answer
		having count(*) = 1
	)
	INSERT INTO Puzzle
	SELECT o.*
	FROM Options o
	INNER JOIN rows_with_option_on_single_column cte
	ON cte.rowNr = o.rowNr
	AND cte.answer = o.answer

	EXEC Update_Options

	; WITH columns_with_value_on_single_row AS (
		select columnNr,answer
		from options
		group by columnNr,answer
		having count(*) = 1
	)
	INSERT INTO Puzzle
	SELECT o.*
	FROM Options o
	INNER JOIN columns_with_value_on_single_row cte
	ON cte.columnNr = o.columnNr
	AND cte.answer = o.answer

	EXEC Update_Options

	--EXEC Reduce_LookAlikes
END
GO

/****** Object:  StoredProcedure [dbo].[Reset_Options]    Script Date: 4-4-2025 21:54:41 ******/

CREATE PROCEDURE [dbo].[Reset_Options] AS
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

/****** Object:  StoredProcedure [dbo].[Save_Puzzle]    Script Date: 4-4-2025 21:54:41 ******/

CREATE PROCEDURE [dbo].[Save_Puzzle] 
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

/****** Object:  StoredProcedure [dbo].[Show_Status]    Script Date: 4-4-2025 21:54:41 ******/

CREATE PROCEDURE [dbo].[Show_Status] 
	@WithPuzzle bit = 0,
	@Iteration int = 0
AS
BEGIN
	SET NOCOUNT ON

	DECLARE @NO char(1) = '.';

	IF @WithPuzzle = 1
	BEGIN
		WITH cte_columns AS (
			SELECT
				rowNr = (n.nr+1)/2,
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
			[#] =  case when (ROW_NUMBER() over (order by rowNr, alpha))%2=0 then '  ' else concat(cast(rowNr as char(1)),'>') end,
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
		@OptionsLeft int,
		@CellSolved int

	SELECT @OptionsLeft = count(*) FROM Options
	SELECT @CellSolved = count(*) FROM Puzzle

	SELECT --
		[Iteration] = @Iteration,
		[#CellsSolved] = @CellSolved,
		[Target] = 49,
		[%CellsSolved] = cast(100.0 * @CellSolved / 49.0 as decimal (9,1)),
		[#OptionsLeft ] = @OptionsLeft,
		[Total] = 343,
		[%OptionsLeft] = cast(100.0 * @OptionsLeft / 343.0 as decimal (9,1))
END
GO

/****** Object:  StoredProcedure [dbo].[Solve_Puzzle]    Script Date: 4-4-2025 21:54:41 ******/

CREATE PROCEDURE [dbo].[Solve_Puzzle] --
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

/****** Object:  StoredProcedure [dbo].[Start_Puzzle]    Script Date: 4-4-2025 21:54:41 ******/

CREATE PROCEDURE [dbo].[Start_Puzzle] --
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

/****** Object:  StoredProcedure [dbo].[Update_Options]    Script Date: 4-4-2025 21:54:41 ******/

CREATE PROCEDURE [dbo].[Update_Options]
AS
BEGIN
	SET NOCOUNT ON

	DELETE o
	FROM Options o
	RIGHT JOIN Puzzle p
	ON p.id = o.id -- all options for this cell
	OR (p.rowNr = o.rowNr AND p.answer = o.answer) -- options in the row with same value
	OR (p.columnNr = o.columnNr AND p.answer = o.answer) -- options in the column with same value
	WHERE p.id IS NOT NULL
END
GO

USE [master]
GO

ALTER DATABASE [Futoshiki] SET  READ_WRITE 
GO

USE [Futoshiki]
GO

EXEC [dbo].Init_Futoshiki
GO
