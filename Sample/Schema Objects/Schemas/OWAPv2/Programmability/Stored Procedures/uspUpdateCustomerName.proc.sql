CREATE PROCEDURE [OWAPv2].[uspUpdateCustomerName]
@SessionID [dbo].[SessionID]=null, @AuditID [dbo].[AuditID]=null, @UserPartyRoleID [dbo].[PartyRoleID]=null, @PartyID [dbo].[PartyID], @Title nvarchar(200)=null, @FirstName [dbo].[NameDetail]=null, @Initials [dbo].[NameDetail]=null, @MiddleName [dbo].[NameDetail]=null, @LastName [dbo].[NameDetail]=null, @SecondLastName [dbo].[NameDetail]=null, @BirthDate DATETIME2 (7)=null, @GenderID [dbo].[GenderID]=null, @LanguageID [dbo].[LanguageID]=null, @ErrorCode INT OUTPUT
AS

/*
	Purpose:	OWAP Customer Name Update

	Version		Date			Developer			Comment
	1.1			2017-03-03		Chris Ledger		BUG 13653 - Add Japan Update to CaseContactMechanismID and CaseDetails
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
	
		DECLARE @AuditItemID dbo.AuditItemID
		DECLARE @ActionDate DATETIME2
		DECLARE @UserPartyID dbo.PartyID
		DECLARE @UserRoleTypeID dbo.RoleTypeID
		DECLARE @OrigTitleID [dbo].[TitleID] 
		DECLARE @OrigFirstName [dbo].[NameDetail]
		DECLARE @OrigInitials [dbo].[NameDetail] 
		DECLARE @OrigMiddleName [dbo].[NameDetail]
		DECLARE @OrigLastName [dbo].[NameDetail]
		DECLARE @OrigSecondLastName [dbo].[NameDetail]
		DECLARE @OrigBirthDate DATETIME2 (7)
		DECLARE @OrigGenderID [dbo].[GenderID]
		
		DECLARE @TitleID  [dbo].[TitleID]

		SET @ActionDate = GETDATE()
	
		--
		-- if details are passed in as null use the original details to update details
		--
		IF ( @SessionID IS NULL ) SELECT @SessionID = 'NEW OWAP Update Customer Name'
		
		SELECT 
				@OrigTitleID = P.TitleID,
				@OrigFirstName = P.FirstName ,
				@OrigInitials = P.Initials ,
				@OrigMiddleName = P.MiddleName ,
				@OrigLastName  = P.LastName,
				@OrigSecondLastName = P.SecondLastName,
				@OrigBirthDate  = P.BirthDate,
				@OrigGenderID  = P.GenderID
		FROM
			Party.People P
		WHERE
			P.PartyID = @PartyID
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

		
		--UPDATE PARTY LANGUAGE IF REQUIRED
		BEGIN

			INSERT INTO Party.vwDA_PartyLanguages
			(
				AuditItemID, 
				PartyID, 
				LanguageID, 
				FromDate, 
				ThroughDate, 
				PreferredFlag
			)

			VALUES
			(	
				@AuditItemID, 
				@PartyID, 
				@LanguageID, 
				CURRENT_TIMESTAMP, 
				CAST(NULL AS DATETIME2), 
				CONVERT(BIT, 1) 
			)

		END

		--GET THE TITLEID FOR THE FREE TEXT TITLE 
		SELECT	@TitleID = TitleID 
		FROM	Party.Titles 
		WHERE	Title = LTRIM(RTRIM(ISNULL(@Title,N'')))

		--TITLE DOESN'T EXIST, NEED TO CREATE IT
		IF ISNULL(@TitleID,'') = ''
		BEGIN
			INSERT INTO Party.vwDA_Titles
			(
				AuditItemID, 
				TitleID, 
				Title
			)
			VALUES (
						@AuditItemID, 
						0,
						LTRIM(RTRIM(ISNULL(@Title,N'')))
					) 	


			--RETRIEVE THE NEW ID SO WE CAN USE IT
			SELECT	@TitleID = TitleID 
			FROM	Party.Titles 
			WHERE	Title = LTRIM(RTRIM(ISNULL(@Title,N'')))
			END   
		
						
		-- UPDATE THE PERSON DETAILS		
		UPDATE Party.vwDA_People
		SET
			 AuditItemID = @AuditItemID
			,TitleID = COALESCE( @TitleID, @OrigTitleID )
			,FirstName = COALESCE( @FirstName, @OrigFirstName )
			,Initials = COALESCE( @Initials, @origInitials)
			,MiddleName = COALESCE( @MiddleName, @OrigMiddleName )
			,LastName = COALESCE( @LastName, @OrigLastName )
			,SecondLastName = COALESCE( @SecondLastName, @OrigSecondLastName )
			,BirthDate = COALESCE( @BirthDate, @OrigBirthDate )
			,GenderID = COALESCE( @GenderID, @OrigGenderID )
		WHERE PartyID = @PartyID


		------------------------------------------------------------------------------------------
		-- V1.1 UPDATE JAPAN CASE CONTACT MECHANISM AND CASE DETAILS WITH LATEST ADDRESS
		------------------------------------------------------------------------------------------

		-----------------------------------------------------------------------------------------
		-- UPDATE Sample.Meta.CaseDetails TO REFERENCE UPDATED NAME
		-----------------------------------------------------------------------------------------
		;WITH	LatestCase ( PartyID, CaseID ) AS
		(
			SELECT CD.PartyID ,
				MAX(CD.CaseID) AS CaseID
			FROM Meta.CaseDetails CD 
			WHERE CD.PartyID = @PartyID
			AND CD.Country = 'Japan'
			GROUP BY CD.PartyID
		 )
		UPDATE  CD
		SET     CD.Title = T.Title ,
				CD.FirstName = P.FirstName ,
				CD.LastName = P.LastName
		--SELECT *
		FROM    Meta.CaseDetails CD
		INNER JOIN LatestCase LC ON CD.CaseID = LC.CaseID
		INNER JOIN Party.People P ON CD.PartyID = P.PartyID
		INNER JOIN Party.Titles T ON P.TitleID = T.TitleID
		WHERE CD.CaseID = LC.CaseID;					
		------------------------------------------------------------------------------------------
		



		
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