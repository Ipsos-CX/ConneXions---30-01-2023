CREATE PROC [Selection].[uspCreateSelectionRequirement]
(
	@ManufacturerPartyID dbo.PartyID,
	@QuestionnaireRequirementID dbo.RequirementID,
	@SelectionName dbo.Requirement,
	@DateTime DATETIME2,
	@SelectionTypeID dbo.SelectionTypeID,
	@UseQuotas BIT = NULL,
	@ScheduledRunDate DATETIME2 = NULL
)
AS

/*
	Purpose:	Create a selection requirement
		
	Version			Date			Developer			Comment
	1.0				$(ReleaseDate)	Simon Peacock		Created
	1.1				2017-01-11		Chris Ledger		BUG 13160 - Add optional parameter for UseQuotas
	1.2				2021-05-18		Chris Ledger		TASK 441 - Add optional parameter for ScheduledRunDate
*/

SET NOCOUNT ON

DECLARE @ErrorNumber INT
DECLARE @ErrorSeverity INT
DECLARE @ErrorState INT
DECLARE @ErrorLocation NVARCHAR(500)
DECLARE @ErrorLine INT
DECLARE @ErrorMessage NVARCHAR(2048)

BEGIN TRY

	BEGIN TRAN

		-- V1.2 SET @ScheduledRunDate
		SELECT @ScheduledRunDate = COALESCE(@ScheduledRunDate, @DateTime)
		
			
		-- CHECK IF THE SELECTION ALREADY EXISTS
		IF NOT EXISTS (
			SELECT *
			FROM Requirement.SelectionRequirements SR
				INNER JOIN Requirement.Requirements S ON S.RequirementID = SR.RequirementID
				INNER JOIN Requirement.RequirementRollups SQ ON SQ.RequirementIDMadeUpOf = S.RequirementID
			WHERE S.Requirement = @SelectionName
				AND SQ.RequirementIDPartOf = @QuestionnaireRequirementID
				AND SR.SelectionDate = @DateTime
		)
		BEGIN
		
			-- DECLARE A VARIABLE TO HOLD THE SelectionRequirementID
			DECLARE @SelectionRequirementID dbo.RequirementID

			-- GENERATE THE SelectionRequirementID AND PUT IT INTO THE VARIABLE
			INSERT INTO Requirement.Requirements (Requirement, RequirementTypeID)
			SELECT @SelectionName, 
				RequirementTypeID
			FROM Requirement.RequirementTypes
			WHERE RequirementType = 'Selection'
			
			SET @SelectionRequirementID = @@IDENTITY
			
			-- ADD A NEW ROW TO SelectionRequirements
			INSERT INTO Requirement.SelectionRequirements (RequirementID, SelectionDate, SelectionStatusTypeID, SelectionTypeID, ScheduledRunDate, UseQuotas)
			SELECT
				@SelectionRequirementID AS RequirementID,
				@DateTime AS SelectionDate,
				(SELECT SelectionStatusTypeID FROM Requirement.SelectionStatusTypes WHERE SelectionStatusType = 'Pending') AS SelectionStatusTypeID,
				@SelectionTypeID AS SelectionTypeID,
				@ScheduledRunDate AS ScheduledRunDate,
				@UseQuotas AS UseQuotas
				
			-- ADD THE ROLLUP FROM THE QUESTIONNAIRE TO THE SELECTION
			INSERT INTO Requirement.RequirementRollups (RequirementIDMadeUpOf, RequirementIDPartOf, FromDate)
			SELECT @SelectionRequirementID, 
				@QuestionnaireRequirementID, 
				@DateTime
			
			-- ADD THE ROLLUPS FROM THE SELECTION TO THE MODEL
			INSERT INTO Requirement.RequirementRollups (RequirementIDMadeUpOf, RequirementIDPartOf, FromDate)
			SELECT RequirementIDMadeUpOf, 
				@SelectionRequirementID, 
				@DateTime
			FROM Requirement.QuestionnaireModelRequirements
			WHERE RequirementIDPartOf = @QuestionnaireRequirementID
			
			-- IF WE HAVE TO ADD QUOTAS THAT SHOULD BE DONE HERE
			INSERT INTO Requirement.SelectionAllocations (RequirementIDMadeUpOf, RequirementIDPartOf)
			SELECT RequirementIDMadeUpOf, 
				RequirementIDPartOf
			FROM Requirement.RequirementRollups
			WHERE RequirementIDPartOf = @SelectionRequirementID
			
		END
		
	COMMIT TRAN

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

