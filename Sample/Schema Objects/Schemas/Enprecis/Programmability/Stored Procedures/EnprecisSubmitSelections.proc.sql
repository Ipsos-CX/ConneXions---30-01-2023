CREATE PROC [Enprecis].[EnprecisSubmitSelections]
	( 
		@RunDay   int		
	)
AS

	/*
		Purpose:	Create emprecis selection requirements
		
		Version		Date			Developer			Comment
		1.0			??/??/????		Poorvi Prasad		Created
		1.1			25/07/2013		Martin Riverol		Added Jag UK 1M (UK, CHN, RUS, AUS) selections to be created
		1.2			16/08/2013		Chris Ross			Fixed incorrect Questionnaire Requirement ID's.
		1.3			02/09/2013		Chris Ross			BUG 9296: Added in new markets ESP, FRA, ITA
	*/

declare @TodaysDate datetime,
		@StartOfWeek datetime,
		@EndOfWeek datetime,
		@Today   int,
		@Rundate datetime

DECLARE @ErrorNumber INT
DECLARE @ErrorSeverity INT
DECLARE @ErrorState INT
DECLARE @ErrorLocation NVARCHAR(500)
DECLARE @ErrorLine INT
DECLARE @ErrorMessage NVARCHAR(2048)

BEGIN TRY


-- Check @MaxDaysSinceSelect paramter supplied 

If isnull(@RunDay, 0) < 1
or isnull(@RunDay, 0) > 7
BEGIN
  SET @ErrorMessage = 'Parameter @RunDay supplied incorrectly (valid values from 1 - 7; 1 = Sunday, 7 = Saturday)'
  RAISERROR (@ErrorMessage,
			 16, -- Severity
			 1  -- State 
			)	RETURN
END

-- Set RunDate for day of the week specified -----------------------------------

SET @TodaysDate = GETDATE()
SET @Today = datepart(weekday, @TodaysDate)

SET @StartOfWeek = DATEADD(wk, DATEDIFF(wk, 6, @TodaysDate), 6)
SET @EndOfWeek = DATEADD(wk, DATEDIFF(wk, 5, @TodaysDate), 5)


-- Set the RunDate based on Today's day in 
-- relation to beginning and end of week dates.
if (@RunDay <= @Today) OR (@RunDay = @Today AND @Today in (1,7))
	SET @RunDate = @EndOfWeek + @RunDay
ELSE 
	SET @RunDate = @StartOfWeek + @RunDay -1



-- Submit Selections -------------------------------------------------------------

DECLARE @RunDateText  VARCHAR(10),
		@DescJag3M_UK	  VARCHAR(100),
		@DescJag12M_UK	  VARCHAR(100),
		@DescJag24M_UK	  VARCHAR(100),
		@DescLR3M_UK	  VARCHAR(100),
		@DescLR12M_UK	  VARCHAR(100),						
		@DescLR24M_UK	  VARCHAR(100),						
		@DescLR1M_UK	  VARCHAR(100),
		@DescJag1M_UK	  VARCHAR(100)	
		
declare	@DescJag3M_AUS	  VARCHAR(100),
		@DescJag12M_AUS	  VARCHAR(100),
		@DescJag24M_AUS	  VARCHAR(100),
		@DescLR3M_AUS	  VARCHAR(100),
		@DescLR12M_AUS	  VARCHAR(100),						
		@DescLR24M_AUS	  VARCHAR(100),						
		@DescLR1M_AUS	  VARCHAR(100),
		@DescJag1M_AUS	  VARCHAR(100)
		
declare	@DescJag3M_CHN	  VARCHAR(100),
		@DescJag12M_CHN	  VARCHAR(100),
		@DescJag24M_CHN	  VARCHAR(100),
		@DescLR3M_CHN	  VARCHAR(100),
		@DescLR12M_CHN	  VARCHAR(100),						
		@DescLR24M_CHN	  VARCHAR(100),						
		@DescLR1M_CHN	  VARCHAR(100),
		@DescJag1M_CHN	  VARCHAR(100)
		
declare	@DescJag3M_RUS	  VARCHAR(100),
		@DescJag12M_RUS	  VARCHAR(100),
		@DescJag24M_RUS	  VARCHAR(100),
		@DescLR3M_RUS	  VARCHAR(100),
		@DescLR12M_RUS	  VARCHAR(100),						
		@DescLR24M_RUS	  VARCHAR(100),						
		@DescLR1M_RUS	  VARCHAR(100),
		@DescJag1M_RUS	  VARCHAR(100)	
		
declare	@DescJag1M_ESP	  VARCHAR(100),				-- v1.3
		@DescJag3M_ESP	  VARCHAR(100),	
		@DescLR3M_ESP	  VARCHAR(100)

declare	@DescJag1M_ITA	  VARCHAR(100),				-- v1.3
		@DescJag3M_ITA	  VARCHAR(100),	
		@DescLR3M_ITA	  VARCHAR(100)

declare	@DescJag1M_FRA	  VARCHAR(100),				-- v1.3
		@DescJag3M_FRA	  VARCHAR(100),	
		@DescLR3M_FRA	  VARCHAR(100)		
		
-- Put the date in the correct text format and create description text param's
SET @RunDateText  = replace(convert(varchar(10), @RunDate, 3), '/', '')
SET @DescJag3M_UK	= '3M Enprecis Jag UK '	+ @RunDateText
SET @DescLR3M_UK	= '3M Enprecis LR UK '		+ @RunDateText
SET @DescJag12M_UK = '12M Enprecis Jag UK '	+ @RunDateText
SET @DescLR12M_UK	= '12M Enprecis LR UK '	+ @RunDateText
SET @DescJag24M_UK = '24M Enprecis Jag UK '	+ @RunDateText						
SET @DescLR24M_UK	= '24M Enprecis LR UK '	+ @RunDateText						
SET @DescLR1M_UK	= '1M Enprecis LR UK '		+ @RunDateText					
SET @DescJag1M_UK	= '1M Enprecis Jag UK '	+ @RunDateText

SET @DescJag3M_AUS	= '3M Enprecis Jag AUS '	+ @RunDateText
SET @DescLR3M_AUS	= '3M Enprecis LR AUS '		+ @RunDateText
SET @DescJag12M_AUS = '12M Enprecis Jag AUS '	+ @RunDateText
SET @DescLR12M_AUS	= '12M Enprecis LR AUS '	+ @RunDateText
SET @DescJag24M_AUS = '24M Enprecis Jag AUS '	+ @RunDateText						
SET @DescLR24M_AUS	= '24M Enprecis LR AUS '	+ @RunDateText						
SET @DescLR1M_AUS	= '1M Enprecis LR AUS '		+ @RunDateText		
SET @DescJag1M_AUS	= '1M Enprecis Jag AUS '	+ @RunDateText

SET @DescJag3M_CHN	= '3M Enprecis Jag CHN '	+ @RunDateText
SET @DescLR3M_CHN	= '3M Enprecis LR CHN '		+ @RunDateText
SET @DescJag12M_CHN = '12M Enprecis Jag CHN '	+ @RunDateText
SET @DescLR12M_CHN	= '12M Enprecis LR CHN '	+ @RunDateText
SET @DescJag24M_CHN = '24M Enprecis Jag CHN '	+ @RunDateText						
SET @DescLR24M_CHN	= '24M Enprecis LR CHN '	+ @RunDateText						
SET @DescLR1M_CHN	= '1M Enprecis LR CHN '		+ @RunDateText
SET @DescJag1M_CHN	= '1M Enprecis Jag CHN '	+ @RunDateText		

SET @DescJag3M_RUS	= '3M Enprecis Jag RUS '	+ @RunDateText
SET @DescLR3M_RUS	= '3M Enprecis LR RUS '		+ @RunDateText
SET @DescJag12M_RUS = '12M Enprecis Jag RUS '	+ @RunDateText
SET @DescLR12M_RUS	= '12M Enprecis LR RUS '	+ @RunDateText
SET @DescJag24M_RUS = '24M Enprecis Jag RUS '	+ @RunDateText						
SET @DescLR24M_RUS	= '24M Enprecis LR RUS '	+ @RunDateText						
SET @DescLR1M_RUS	= '1M Enprecis LR RUS '		+ @RunDateText
SET @DescJag1M_RUS	= '1M Enprecis Jag RUS '	+ @RunDateText		

SET @DescJag1M_ESP	= '1M Enprecis Jag ESP '	+ @RunDateText		--v1.3
SET @DescJag3M_ESP	= '3M Enprecis Jag ESP '	+ @RunDateText		
SET @DescLR3M_ESP	= '3M Enprecis LR ESP '		+ @RunDateText

SET @DescJag1M_ITA	= '1M Enprecis Jag ITA '	+ @RunDateText		--v1.3
SET @DescJag3M_ITA	= '3M Enprecis Jag ITA '	+ @RunDateText		
SET @DescLR3M_ITA	= '3M Enprecis LR ITA '		+ @RunDateText

SET @DescJag1M_FRA	= '1M Enprecis Jag FRA '	+ @RunDateText		--v1.3
SET @DescJag3M_FRA	= '3M Enprecis Jag FRA '	+ @RunDateText		
SET @DescLR3M_FRA	= '3M Enprecis LR FRA '		+ @RunDateText

-- Submit the jobs 
exec Selection.uspCreateSelectionRequirement 2,27659, @DescJag3M_UK,	@RunDate, 1
exec Selection.uspCreateSelectionRequirement 3,27660, @DescLR3M_UK,		@RunDate, 1


exec Selection.uspCreateSelectionRequirement 2,27661, @DescJag12M_UK,	@RunDate, 1
exec Selection.uspCreateSelectionRequirement 3,27662, @DescLR12M_UK,	@RunDate, 1

/*NEW JOB SUBMIT COMES HERE*/																			
																									
exec Selection.uspCreateSelectionRequirement 2,29479, @DescJag24M_UK,	@RunDate, 1
exec Selection.uspCreateSelectionRequirement 3,29480, @DescLR24M_UK,	@RunDate, 1

/*NEW JOB SUBMIT COMES HERE*/																			
																									
exec Selection.uspCreateSelectionRequirement 2,30497, @DescJag1M_UK,	@RunDate, 1
exec Selection.uspCreateSelectionRequirement 3,30498, @DescLR1M_UK,		@RunDate, 1


exec Selection.uspCreateSelectionRequirement 2,32182, @DescJag3M_AUS,	@RunDate, 1
exec Selection.uspCreateSelectionRequirement 3,32183, @DescLR3M_AUS,		@RunDate, 1

exec Selection.uspCreateSelectionRequirement 2,32184, @DescJag12M_AUS,	@RunDate, 1
exec Selection.uspCreateSelectionRequirement 3,32185, @DescLR12M_AUS,	@RunDate, 1

/*NEW JOB SUBMIT COMES HERE*/																			
																									
exec Selection.uspCreateSelectionRequirement 2,32186, @DescJag24M_AUS,	@RunDate, 1
exec Selection.uspCreateSelectionRequirement 3,32187, @DescLR24M_AUS,	@RunDate, 1

/*NEW JOB SUBMIT COMES HERE*/																			
																									
exec Selection.uspCreateSelectionRequirement 2,32188, @DescJag1M_AUS,	@RunDate, 1
exec Selection.uspCreateSelectionRequirement 3,32189, @DescLR1M_AUS,	@RunDate, 1  


exec Selection.uspCreateSelectionRequirement 2,32190, @DescJag3M_CHN,	@RunDate, 1
exec Selection.uspCreateSelectionRequirement 3,32191, @DescLR3M_CHN,		@RunDate, 1

exec Selection.uspCreateSelectionRequirement 2,32192, @DescJag12M_CHN,	@RunDate, 1
exec Selection.uspCreateSelectionRequirement 3,32193, @DescLR12M_CHN,	@RunDate, 1

/*NEW JOB SUBMIT COMES HERE*/																			
																									
exec Selection.uspCreateSelectionRequirement 2,32194, @DescJag24M_CHN,	@RunDate, 1
exec Selection.uspCreateSelectionRequirement 3,32195, @DescLR24M_CHN,	@RunDate, 1

/*NEW JOB SUBMIT COMES HERE*/																			
																									
exec Selection.uspCreateSelectionRequirement 2,32196, @DescJag1M_CHN,	@RunDate, 1
exec Selection.uspCreateSelectionRequirement 3,32197, @DescLR1M_CHN,		@RunDate, 1



exec Selection.uspCreateSelectionRequirement 2,32198, @DescJag3M_RUS,	@RunDate, 1
exec Selection.uspCreateSelectionRequirement 3,32199, @DescLR3M_RUS,		@RunDate, 1

exec Selection.uspCreateSelectionRequirement 2,32200, @DescJag12M_RUS,	@RunDate, 1
exec Selection.uspCreateSelectionRequirement 3,32201, @DescLR12M_RUS,	@RunDate, 1

/*NEW JOB SUBMIT COMES HERE*/																			
																									
exec Selection.uspCreateSelectionRequirement 2,32202, @DescJag24M_RUS,	@RunDate, 1
exec Selection.uspCreateSelectionRequirement 3,32203, @DescLR24M_RUS,	@RunDate, 1

/*NEW JOB SUBMIT COMES HERE*/																			
																									
exec Selection.uspCreateSelectionRequirement 2,32204, @DescJag1M_RUS,	@RunDate, 1  
exec Selection.uspCreateSelectionRequirement 3,32205, @DescLR1M_RUS,		@RunDate, 1


-- ITALY SPAIN and FRANCE	---------------------------------------------	-- v1.3
exec Selection.uspCreateSelectionRequirement 2,39326, @DescJag1M_ESP,	@RunDate, 1
exec Selection.uspCreateSelectionRequirement 2,39327, @DescJag3M_ESP,	@RunDate, 1
exec Selection.uspCreateSelectionRequirement 3,39328, @DescLR3M_ESP,	@RunDate, 1

exec Selection.uspCreateSelectionRequirement 2,39329, @DescJag1M_ITA,	@RunDate, 1
exec Selection.uspCreateSelectionRequirement 2,39330, @DescJag3M_ITA,	@RunDate, 1
exec Selection.uspCreateSelectionRequirement 3,39331, @DescLR3M_ITA,	@RunDate, 1

exec Selection.uspCreateSelectionRequirement 2,39332, @DescJag1M_FRA,	@RunDate, 1
exec Selection.uspCreateSelectionRequirement 2,39333, @DescJag3M_FRA,	@RunDate, 1
exec Selection.uspCreateSelectionRequirement 3,39334, @DescLR3M_FRA,	@RunDate, 1
-------------------------------------------------------------------------

END TRY
BEGIN CATCH

	SELECT
		 @ErrorNumber = Error_Number()
		,@ErrorSeverity = Error_Severity()
		,@ErrorState = Error_State()
		,@ErrorLocation = Error_Procedure()
		,@ErrorLine = Error_Line()
		,@ErrorMessage = Error_Message()

	EXEC [$(ErrorDB)].dbo.uspLogDatabaseError
		 @ErrorNumber
		,@ErrorSeverity
		,@ErrorState
		,@ErrorLocation
		,@ErrorLine
		,@ErrorMessage
		
	RAISERROR(@ErrorNumber, @ErrorMessage, @ErrorSeverity, @ErrorState, @ErrorLine)
		
END CATCH
