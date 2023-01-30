CREATE PROCEDURE [OWAPv2].[uspCreateAdhocSelection]

@SessionID [dbo].[SessionID]=null, @AuditID [dbo].[AuditID]=null, @UserPartyRoleID [dbo].[PartyRoleID]=null, @BrandID INT, @MarketIDs VARCHAR(max), @QuestionnaireID INT, @StartDate DATETIME2 (7), @EndDate DATETIME2 (7), @ModelIDs VARCHAR(max)=null, @ModelYears VARCHAR(max)=null,  @PostCode NVARCHAR(60)=null, @ErrorCode INT OUTPUT

AS
SET NOCOUNT ON

	DECLARE @ErrorNumber INT
	DECLARE @ErrorSeverity INT
	DECLARE @ErrorState INT
	DECLARE @ErrorLocation NVARCHAR(500)
	DECLARE @ErrorLine INT
	DECLARE @ErrorMessage NVARCHAR(2048)

BEGIN TRY



	BEGIN TRAN
	
		DECLARE @AuditItemID dbo.AuditItemID
		DECLARE @ActionDate DATETIME2
		DECLARE @UserPartyID dbo.PartyID
		DECLARE @UserRoleTypeID dbo.RoleTypeID
		DECLARE @DateTime DATETIME2(7)
	
	
		SET @DateTime = CONVERT(DATE,GETDATE()) 			
		SET @ActionDate = GETDATE()
	
		--
		-- if details are passed in as null use the original details to update details
		--
		IF ( @SessionID IS NULL ) SELECT @SessionID = 'NEW OWAP Create Adhoc Selection'
		

		--
		-- get basic OWAPAdmin user details of manually setting data updates
		--
		IF ( @UserPartyRoleID IS NULL)
		BEGIN
				SELECT @UserPartyRoleID = pr.PartyRoleID 
				FROM OWAP.Users U
				INNER JOIN Party.PartyRoles pr ON pr.PartyID = u.PartyID AND pr.RoleTypeID = 51 -- OWAP
				WHERE U.UserName = 'OWAPAdmin'	
		END	
		--
		-- GET THE USER DETAILS
		--
		SELECT
			@UserPartyID = PR.PartyID,
			@UserRoleTypeID = PR.RoleTypeID
		FROM Party.PartyRoles PR
		INNER JOIN OWAP.Users U ON U.PartyID = PR.PartyID AND U.RoleTypeID = PR.RoleTypeID
		WHERE PR.PartyRoleID = @UserPartyRoleID
		
		-- AUDIT THE ACTION AND GET THE RESULTANT AuditItemID
		EXEC [OWAP].[uspAuditSession] @SessionID, @userPartyRoleID, @AuditID Output, @ErrorCode Output
		EXEC OWAP.uspAuditAction @AuditID, @ActionDate, @UserPartyID, @UserRoleTypeID, @AuditItemID OUTPUT, @ErrorCode OUTPUT

	
		-- DECLARE A VARIABLE TO HOLD THE SelectionRequirementID
        DECLARE @SelectionRequirementID dbo.RequirementID,
				@SelectionName			VARCHAR(200)=''


		SET @SelectionName =	'OWAP Adhoc Selection: ' + 
								CONVERT(VARCHAR,YEAR(GETDATE())) + 	
								CASE WHEN MONTH(GETDATE()) > 9 THEN CONVERT(VARCHAR,MONTH(GETDATE())) ELSE '0' + CONVERT(VARCHAR,MONTH(GETDATE())) END +
								CASE WHEN DAY(GETDATE()) > 9 THEN CONVERT(VARCHAR,DAY(GETDATE())) ELSE '0' + CONVERT(VARCHAR,DAY(GETDATE())) END		
		
		-- GENERATE THE SelectionRequirementID AND PUT IT INTO THE VARIABLE
        INSERT  INTO Requirement.Requirements
                ( Requirement ,
                  RequirementTypeID
                )

        SELECT  @SelectionName ,
                RequirementTypeID
        FROM    Requirement.RequirementTypes
        WHERE   RequirementType = 'Selection'
			
        SET @SelectionRequirementID = @@IDENTITY
	

		--UPDATE REQUIREMENT NAME TO INCLUDE REQUIREMENTID
		UPDATE	Requirement.Requirements
		SET 	Requirement =	CASE
										WHEN @BrandID = 1 THEN Requirement + '_JAG_' + CONVERT (VARCHAR,@SelectionRequirementID)
										WHEN @BrandID = 2 THEN Requirement + '_LR_' + CONVERT (VARCHAR,@SelectionRequirementID)	
									END	
		WHERE	RequirementID =  @SelectionRequirementID
	

		-- ADD A NEW ROW TO SelectionRequirements
        INSERT  INTO Requirement.AdhocSelectionRequirements
                (	RequirementID,
					BrandID,
					QuestionnaireID,
					StartDate,
					EndDate,
					PostCode,
					SelectionDate,
					SelectionStatusTypeID ,
					SelectionTypeID ,
					ScheduledRunDate
                )

		SELECT  @SelectionRequirementID AS RequirementID ,
				@BrandID,
				@QuestionnaireID,
				@StartDate,
				@EndDate,
				@PostCode,
				@DateTime AS SelectionDate ,
				( SELECT    SelectionStatusTypeID
					FROM      Requirement.SelectionStatusTypes
					WHERE     SelectionStatusType = 'Pending'
				) AS SelectionStatusTypeID ,
				(SELECT RequirementTypeID FROM Requirement.RequirementTypes WHERE RequirementType = 'Selection') AS SelectionTypeID ,
				@DateTime AS ScheduledRunDate
				

		-- ADD THE ROLLUPS FROM THE SELECTION TO THE MARKETS
		INSERT  INTO Requirement.AdhocSelectionMarketRequirements
        ( 
            RequirementIDPartOf ,
			CountryID
        )
		SELECT	@SelectionRequirementID, CountryID
		FROM	dbo.Markets
		WHERE	MarketID IN 
				(	
					SELECT S AS MarketID 
					FROM  dbo.[fn_ParseCSVString](@MarketIDs,',')
				)



		-- ADD THE ROLLUPS FROM THE SELECTION TO THE MODEL
		INSERT  INTO Requirement.AdhocSelectionModelRequirements
        ( 
			RequirementIDMadeUpOf ,
            RequirementIDPartOf ,
            FromDate
        )
		SELECT		REQ.RequirementID, 
					@SelectionRequirementID,
					@DateTime
		FROM		Vehicle.Models MO
		INNER JOIN	Requirement.Requirements REQ ON MO.ModelDescription = REQ.Requirement
		WHERE		ModelID IN 
					(	SELECT S AS ModelID 
						FROM  dbo.[fn_ParseCSVString](@ModelIDs,',')
					)


		-- ADD THE ROLLUPS FROM THE SELECTION TO THE MODEL YEAR
		INSERT  INTO Requirement.AdhocSelectionModelYearRequirements
		(
			RequirementIDPartOf,
			ModelYear
		)
		SELECT	@SelectionRequirementID, 
				S AS ModelYear
		FROM	dbo.[fn_ParseCSVString](@ModelYears,',')


	COMMIT TRAN

END TRY
BEGIN CATCH

	IF @@TRANCOUNT > 0
	BEGIN
		ROLLBACK TRAN
	END

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
