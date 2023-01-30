CREATE FUNCTION [SampleReport].[FiscalYear]
(
	@RunDate DATETIME
)
RETURNS INT
AS

/*
	Purpose:	Pass in a run date, return the year the fiscal year starts from
	
	Version		Date		Developer			Comment
	1.0			20140609	Martin Riverol		Created
*/

BEGIN
	DECLARE @Year AS INT
	
	IF MONTH(@RunDate) < 5
		SET @Year = YEAR(@RunDate) - 1
	ELSE 
		SET @Year = YEAR(@RunDate)	
	
	RETURN @Year 
END