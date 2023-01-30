CREATE FUNCTION [SelectionOutput].[udfGetWeekNumber](@CurrentDate DATETIME2(7))
RETURNS INT
AS
BEGIN

	-- THE WEEK NUMBERS START FROM WEEK COMMENCING 25/09/2006

	DECLARE @WeekNumber INT

	SET @WeekNumber = DATEDIFF(wk, '25 Sep 2006', @CurrentDate)
	
	
	--BUG 15431 -Selection output week number - request to skip week 666
	IF @WeekNumber >= 666
	BEGIN
		SET @WeekNumber = @WeekNumber + 1
	END 

	RETURN @WeekNumber

END