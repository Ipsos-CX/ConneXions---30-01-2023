CREATE PROCEDURE [SelectionOutput].[uspRejectCRCCases]

AS

/*
	Purpose:	Rejects CRC CaseIDs without 
		
	Version			Date			Developer			Comment
	1.0				$(ReleaseDate)	Eddie Thomas		Created
	1.1				2018-06-11		Chris Ledger		BUG 14721: ADD India
	1.2				2020-01-21		Chris Ledger		BUG 15372: Fix Hard coded references to databases.
	1.3				2021-03-23		Chris Ledger		TASK 299: Add General Enquiry
	1.4				2021-03-26		Eddie Thomas		BUG 18152 : Using CRC Agent List lookup
*/

DECLARE @ErrorNumber INT
DECLARE @ErrorSeverity INT
DECLARE @ErrorState INT
DECLARE @ErrorLocation NVARCHAR(500)
DECLARE @ErrorLine INT
DECLARE @ErrorMessage NVARCHAR(2048)

BEGIN TRY


	
	-- 1. STORE CRC RECORDS WHO'S AGENT CODES DO NOT EXIST IN THE CRC AGENT LOOKUP TABLE
	
	--ONLINE RECORDS
	SELECT DISTINCT
		O.PartyID AS GfKPartyID,
		O.ID AS CaseID,
		O.Surname,
		O.CoName,
		O.sType AS Brand,
		O.CTRY AS Market,
		CASE
			WHEN lko.CDSID IS NOT NULL THEN lko.CDSID	-- WE'VE GOT A MATCH IN THE LOOKUP TABLE, USE IT. 
			WHEN lkf.CDSID IS NOT NULL THEN lkf.CDSID
			ELSE CRC.[Owner]                                                                                                                                                                                                                  
		END AS [Agent Code]
	--POPULATE OUR WORKING TABLE
	INTO #CasesToReject	
	FROM SelectionOutput.OnlineOutput O 
		INNER JOIN [Event].vwEventTypes ET ON ET.EventTypeID = O.etype
		INNER JOIN [Event].AutomotiveEventBasedInterviews AEBI ON AEBI.CaseID = O.ID 
		INNER JOIN	(	SELECT ODSEventID AS EventID, 
							MAX(AuditItemID) AS AuditItemID
						FROM [Sample_ETL].CRC.CRCEvents
						GROUP BY ODSEventID) RED ON RED.EventID = AEBI.EventID
		INNER JOIN [Sample_ETL].CRC.CRCEvents CRC ON CRC.AuditItemID = RED.AuditItemID

		INNER JOIN 
		(
			--REMOVED HARDCODED LIST OF MARKETS TO NOW USE COUNTRIES SPECIFIED IN THE LOOK UP
			SELECT		DISTINCT CountryID  
			FROM		Sample_ETL.Lookup.CRCAgents_GlobalList lk
			INNER JOIN	Sample.ContactMechanism.Countries cn on lk.MarketCode = cn.ISOAlpha3
		) LKC ON O.ccode = LKC.CountryID  -- v1.4

		LEFT JOIN dbo.Languages L ON L.LanguageID = CRC.PreferredLanguageID
		LEFT JOIN ContactMechanism.Countries C ON C.ISOAlpha3 = CRC.MarketCode
		LEFT JOIN Markets M ON M.CountryID = C.CountryID
		LEFT JOIN dbo.Regions R ON R.regionID = M.RegionID
		LEFT JOIN	[Sample_ETL].[Lookup].[CRCAgents_GlobalList] lko		ON LTRIM(RTRIM(CRC.[Owner])) = lko.CDSID AND crc.MarketCode = lko.MarketCode  --V1.4
		LEFT JOIN	[Sample_ETL].[Lookup].[CRCAgents_GlobalList] lkf		ON LTRIM(RTRIM(CRC.[Owner])) = lkf.FullName AND crc.MarketCode =  lkf.MarketCode  --V1.4
																													
	WHERE	(ET.EventCategory = 'CRC') AND 
			(lko.CDSID IS NULL) AND
			(lkf.CDSID IS NULL) 
			--AND (O.CTRY IN ('Australia','Austria','Belgium','Brazil','France','Germany','India','Italy','Netherlands','Portugal','Russian Federation','Spain'))
	
	UNION	
	
	--TELPEHONE CRC INVITES 
	SELECT DISTINCT
		O.PartyID AS GfKPartyID,
		O.ID AS CaseID,
		O.Surname,
		O.CoName,
		O.sType AS Brand,
		O.CTRY AS Market,
		CASE
			WHEN lko.CDSID IS NOT NULL THEN lko.CDSID	-- WE'VE GOT A MATCH IN THE LOOKUP TABLE, USE IT. 
			WHEN lkf.CDSID IS NOT NULL THEN lkf.CDSID
			ELSE CRC.[Owner]                                                                                                                                                                                                                  
		END AS [Agent Code]
	FROM SelectionOutput.OnlineOutput AS O 
		INNER JOIN SelectionOutput.CATI C ON C.CaseID = O.ID 
										  AND C.PartyID = O.PartyID
		INNER JOIN [Event].AutomotiveEventBasedInterviews AEBI ON AEBI.CaseID = O.ID 
		INNER JOIN (	SELECT ODSEventID AS EventID, 
							MAX(AuditItemID) AS AuditItemID
						FROM [Sample_ETL].CRC.CRCEvents
						GROUP BY ODSEventID) RED ON RED.EventID = AEBI.EventID
		INNER JOIN [Sample_ETL].CRC.CRCEvents CRC ON CRC.AuditItemID = RED.AuditItemID

		INNER JOIN 
		(
			--REMOVED HARDCODED LIST OF MARKETS TO NOW USE COUNTRIES SPECIFIED IN THE LOOK UP
			SELECT		DISTINCT CountryID  
			FROM		Sample_ETL.Lookup.CRCAgents_GlobalList lk
			INNER JOIN	Sample.ContactMechanism.Countries cn on lk.MarketCode = cn.ISOAlpha3
		) LKC ON O.ccode = LKC.CountryID  -- v1.4

		LEFT JOIN dbo.Languages L ON L.LanguageID = CRC.PreferredLanguageID
		LEFT JOIN	[Sample_ETL].[Lookup].[CRCAgents_GlobalList] lko		ON LTRIM(RTRIM(CRC.[Owner])) = lko.CDSID AND crc.MarketCode = lko.MarketCode  --V1.8
		LEFT JOIN	[Sample_ETL].[Lookup].[CRCAgents_GlobalList] lkf		ON LTRIM(RTRIM(CRC.[Owner])) = lkf.FullName AND crc.MarketCode =  lkf.MarketCode  --V1.8
	
	WHERE	(lko.CDSID IS NULL) AND
			(lkf.CDSID IS NULL) 
			--AND (O.CTRY IN ('Australia','Austria','Belgium','Brazil','France','Germany','India','Italy','Netherlands','Portugal','Russian Federation','Spain'))

	UNION

	--POSTAL CRC INVITES
	SELECT DISTINCT
		P.PartyID AS GfKPartyID,
		P.ID AS CaseID,
		P.Surname,
		P.CoName,
		P.sType AS Brand,
		P.CTRY AS Market,
		CASE
			WHEN lko.CDSID IS NOT NULL THEN lko.CDSID	-- WE'VE GOT A MATCH IN THE LOOKUP TABLE, USE IT. 
			WHEN lkf.CDSID IS NOT NULL THEN lkf.CDSID
			ELSE CRC.[Owner]                                                                                                                                                                                                                  
		END AS [Agent Code]
	FROM SelectionOutput.Postal P
		INNER JOIN [Event].AutomotiveEventBasedInterviews AEBI ON P.ID = AEBI.CaseID
		INNER JOIN (	SELECT ODSEventID AS EventID, 
							MAX(AuditItemID) AS AuditItemID
						FROM [Sample_ETL].CRC.CRCEvents
						GROUP BY ODSEventID) RED ON RED.EventID = AEBI.EventID
		INNER JOIN [Sample_ETL].CRC.CRCEvents CRC ON CRC.AuditItemID = RED.AuditItemID
		
		INNER JOIN 
		(
			--REMOVED HARDCODED LIST OF MARKETS TO NOW USE COUNTRIES SPECIFIED IN THE LOOK UP
			SELECT		DISTINCT CountryID  
			FROM		Sample_ETL.Lookup.CRCAgents_GlobalList lk
			INNER JOIN	Sample.ContactMechanism.Countries cn on lk.MarketCode = cn.ISOAlpha3
		) LKC ON p.ccode = LKC.CountryID  -- v1.4
		
		LEFT JOIN	[Sample_ETL].[Lookup].[CRCAgents_GlobalList] lko		ON LTRIM(RTRIM(CRC.[Owner])) = lko.CDSID AND crc.MarketCode = lko.MarketCode  --V1.8
		LEFT JOIN	[Sample_ETL].[Lookup].[CRCAgents_GlobalList] lkf		ON LTRIM(RTRIM(CRC.[Owner])) = lkf.FullName AND crc.MarketCode =  lkf.MarketCode  --V1.8

	WHERE	(lko.CDSID IS NULL) AND
			(lkf.CDSID IS NULL) 
			--AND (P.CTRY IN ('Australia','Austria','Belgium','Brazil','France','Germany','India','Italy','Netherlands','Portugal','Russian Federation','Spain'))

	UNION

	-- V1.4 CRC General Enqury Online Records
	SELECT DISTINCT
		O.PartyID AS GfKPartyID,
		O.ID AS CaseID,
		O.Surname,
		O.CoName,
		O.sType AS Brand,
		O.CTRY AS Market,
		CASE
			WHEN lko.CDSID IS NOT NULL THEN lko.CDSID	-- WE'VE GOT A MATCH IN THE LOOKUP TABLE, USE IT. 
			WHEN lkf.CDSID IS NOT NULL THEN lkf.CDSID
			ELSE GE.EmployeeResponsibleName                                                                                                                                                                                                                  
		END AS [Agent Code] 
	FROM SelectionOutput.OnlineOutput O 
		INNER JOIN [Event].vwEventTypes ET ON ET.EventTypeID = O.etype
		INNER JOIN [Event].AutomotiveEventBasedInterviews AEBI ON AEBI.CaseID = O.ID 
		INNER JOIN	(	SELECT ODSEventID AS EventID, 
							MAX(AuditItemID) AS AuditItemID
						FROM [Sample_ETL].GeneralEnquiry.GeneralEnquiryEvents
						GROUP BY ODSEventID) RED ON RED.EventID = AEBI.EventID
		INNER JOIN [Sample_ETL].GeneralEnquiry.GeneralEnquiryEvents GE ON GE.AuditItemID = RED.AuditItemID
		LEFT JOIN dbo.Languages L ON L.LanguageID = GE.PreferredLanguageID
		LEFT JOIN ContactMechanism.Countries C ON C.ISOAlpha3 = GE.MarketCode
		LEFT JOIN Markets M ON M.CountryID = C.CountryID
		LEFT JOIN dbo.Regions R ON R.regionID = M.RegionID
		LEFT JOIN	[Sample_ETL].[Lookup].[CRCAgents_GlobalList] lko		ON GE.EmployeeResponsibleName = lko.CDSID AND GE.MarketCode = lko.MarketCode  --V1.8
		LEFT JOIN	[Sample_ETL].[Lookup].[CRCAgents_GlobalList] lkf		ON GE.EmployeeResponsibleName = lkf.FullName AND GE.MarketCode =  lkf.MarketCode  --V1.8

	WHERE	ET.EventCategory = 'CRC General Enquiry' AND
			(lko.CDSID IS NULL) AND
			(lkf.CDSID IS NULL)


	-- 1. ADD NEW RECORDS TO OUR REPORTING TABLE I.E. .
	INSERT INTO [SelectionOutput].RejectedCRCCases 
	(
		PartyID,
		CaseID,
		Surname,
		CoName,
		Brand,
		Market,
		AgentCode
	)	
	SELECT NC.* 
	FROM #CasesToReject NC
		--SELECTION OUTPUT CAN PROCESS MULTIPLE SELECTION IN A RECURSIVE FASHION
		--ENSURE WE DON'T ADD THE SAME CASEID'S 
		LEFT JOIN SelectionOutput.RejectedCRCCases RJC ON NC.CaseID = RJC.CaseID 
	WHERE RJC.CaseID is NULL


	DECLARE @Cases TABLE 
	(
		ID			INT IDENTITY(1, 1),
		AuditItemID	BIGINT NULL, 
		CaseID		BIGINT,
		SelectionID	dbo.RequirementiD
	)
	 
	INSERT INTO @Cases (CaseID, SelectionID)
	SELECT DISTINCT CR.CaseID, 
		RequirementIDPartOf  
	FROM #CasesToReject CR
		INNER JOIN Requirement.SelectionCases SC ON CR.CaseID = SC.CaseID
		LEFT JOIN [Event].CaseRejections ECR ON SC.CaseID = ECR.CaseID
	WHERE ECR.CaseID IS NULL


	----------------------------------------------------------- START OF AUDITING -----------------------------------------------------------
	DECLARE @AuditID		dbo.AuditID,
			@ErrorCode		INT,
			@UserPartyRole	dbo.PartyRoleID,
			@UserPartyID	dbo.PartyID
			
			
	-- USE OWAP DETAILS FOR AUDIT
	SELECT @UserPartyRole = PR.PartyRoleID ,
		@UserPartyID = U.PartyID
	FROM OWAP.Users U
		INNER JOIN Party.PartyRoles PR ON PR.PartyID = U.PartyID
										AND PR.RoleTypeID = 51 -- OWAP
	WHERE UserName = 'OWAPAdmin';
	

	--START A TRANSACTION
	BEGIN TRAN 
		
		-- Create an Audit session and retrieve the AuditID -------------------------------------
		EXEC OWAP.uspAuditSession 'Internal Update : Automatic Case Rejection', @UserPartyRole, @AuditID OUTPUT, @ErrorCode OUTPUT;

		DECLARE	@ActionDate			DATETIME2,
				@UserRoleTypeID		dbo.RoleTypeID
				--@UserPartyRoleID	dbo.PartyRoleID

		SET @ActionDate = GETDATE()
		
		SELECT @UserPartyID = U.PartyID,
			@UserRoleTypeID	= U.RoleTypeID
			--@UserPartyRoleID = U.PartyRoleID
		FROM OWAP.vwUsers U	
		WHERE U.UserName = 'OWAPAdmin'
		
		-- GET THE MAXIMUM AuditItemID AND USE IT TO GENERATE THE NEW ONES
		DECLARE @MaxAuditItemID dbo.AuditItemID
		
		SELECT @MaxAuditItemID = ISNULL(MAX(AuditItemID), 0)
		FROM [$(AuditDB)].dbo.AuditItems
		
		UPDATE	@Cases
		SET AuditItemID = ID + @MaxAuditItemID

		-- INSERT ROWS INTO AuditItems
		INSERT INTO [$(AuditDB)].dbo.AuditItems
		(
			AuditItemID, 
			AuditID
		)
		SELECT AuditItemID, 
			@AuditID
		FROM @Cases
		ORDER BY AuditItemID
		
		-- FINALLY, INSERT THE DATA INTO THE Actions TABLE
		INSERT INTO [$(AuditDB)].OWAP.Actions
		(
			AuditItemID, 
			ActionDate, 
			UserPartyID, 
			UserRoleTypeID
		)
		SELECT
			AuditItemID, 
			@ActionDate, 
			@UserPartyID, 
			@UserRoleTypeID
		FROM @Cases
		ORDER BY AuditItemID
		----------------------------------------------------------- END OF AUDITING -----------------------------------------------------------


		-- 2. REJECT THESE CASES

		-- ADD THE CASE REJECTIONS
		INSERT INTO [Event].vwDA_CaseRejections
		(
			AuditItemID,
			CaseID,
			Rejection,
			FromDate
		)
		SELECT
			AuditItemID,
			CaseID,
			1 AS Rejection,
			@ActionDate AS FromDate
		FROM @Cases
		ORDER BY AuditItemID


		-- SET THE REJECT COUNT
		;WITH RejectedCount_CTE (CaseCount, SelectionID) AS
		(
			SELECT Count(CaseID) AS CaseCount, 
				SelectionID  
			FROM @Cases
			GROUP BY SelectionID
		)
		UPDATE SR
		SET SR.RecordsRejected = ISNULL(SR.RecordsRejected, 0) + CTE.CaseCount
		FROM Requirement.SelectionRequirements SR
			INNER JOIN RejectedCount_CTE CTE ON SR.RequirementID = CTE.SelectionID
		
		
		UPDATE CD
		SET	CD.CaseRejection = 1,
			CD.CaseStatusTypeID	= (	SELECT CaseStatusTypeID 
									FROM [Event].CaseStatusTypes 
									WHERE CaseStatusType = 'Refused by Exec')
		FROM Meta.CaseDetails CD
			INNER JOIN @Cases CS ON CD.CaseID = CS.CaseID

		
		-- 2. REMOVE THE CASES FROM THE OUTPUT TABLES
		DELETE CA	
		FROM SelectionOutput.CATI CA
			INNER JOIN @Cases CS ON CA.CaseID = CS.CaseID
		
	
		DELETE PO	
		FROM SelectionOutput.Postal	PO
			INNER JOIN @Cases CS ON PO.ID = CS.CaseID
		
		DELETE OO	
		FROM SelectionOutput.OnlineOutput OO
			INNER JOIN @Cases CS ON OO.ID = CS.CaseId
	
	COMMIT

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
	
	IF @@TRANCOUNT > 0
	BEGIN
		ROLLBACK TRAN
	END
		
	RAISERROR(@ErrorNumber, @ErrorMessage, @ErrorSeverity, @ErrorState, @ErrorLine)
		
END CATCH

