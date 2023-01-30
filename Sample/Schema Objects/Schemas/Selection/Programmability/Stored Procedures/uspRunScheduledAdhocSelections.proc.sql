CREATE PROCEDURE [Selection].[uspRunScheduledAdhocSelections]

AS 
	
	--VARIABLE DECLARATIONS
	DECLARE @Max			INT = 0, 
			@Count			INT = 0,
			@CurID			INT = 0,
			@return_value	INT

	

	--TABLE TO STORE PENDING ADHOC SELECTIONS
	DECLARE @AdhocSelections Table
	( 
		ID		INT Identity (1,1),
		ReqID	INT
	)

	--POPULATE TABLE
	INSERT		@AdhocSelections (ReqID)

	SELECT		RequirementID 
	FROM		Requirement.AdhocSelectionRequirements ASR
	INNER JOIN	Requirement.SelectionStatusTypes SST ON ASR.SelectionStatusTypeID = SST.SelectionStatusTypeID 
	WHERE		SelectionStatusType = 'Pending'
	ORDER BY 1


	--SET LOOP UPPER LIMIT
	SELECT	@Max = MAX(ID) FROM @AdhocSelections

	--EXECUTE EACH SELECTIONREQUIREMENT
	WHILE (@Max >0  AND @Count <= @Max)
	BEGIN
			SET @Count = @Count +1
		
			SELECT @CurID = ReqID FROM @AdhocSelections WHERE ID = @Count
		
			EXEC	@return_value = [Sample].[Selection].[uspRunOWAPSelection]
					@SelectionRequirementID = @CurID

			--SELECT	'Return Value' = @return_value

	END
