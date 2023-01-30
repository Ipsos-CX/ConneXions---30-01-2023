CREATE  PROCEDURE [CustomerUpdateFeeds].[uspGET_CustomerUpdate_Feed_DATA]
AS

SET NOCOUNT ON

/*

***************************************************************************
**
**  Description: Adds to AND updates to the CustomerUpdateFeeds.CustomerUpdateFeed 
**				 table.				
**
**
**	Date		Author		Ver		Desctiption
**	----		------		----	-----------
**	?			?			?		Original version
**	31-07-2012	Chris Ross	1.0		Added Source AND Customer ID columns
**	30-08-2012	Chris Ross	1.1		Update CustomerID_3 to contain Vista IDs
**  22-08-2013	Chris Ross	1.2		BUG 8969. Update output of CustomerID_3 to remove the "_VISTA" suffix.
**	04-10-2013	Chris Ross	1.3		BUG 9501. Add in bounceback flag. 
**  31-01-2014	Chris Ross	1.4		BUG 9546. Remove CustomerID_Brazil/3/4/8/9/10; Replace with General, 
**											  Vista, Roadside. Add in SMS bouncebacks.
**									Remove unused date parameters.  Reinstate clear down of tables AND 
**									de-dupe customer update feed table. 
**									Speed up population of "previous" Registration AND Addresses update.
**	25-03-2014  Chris Ross	1.41	BUG 9546. Comment out get of SMS bouncebacks AS JLR uncertain 
**												whether bounceback functionality will be released.
**	02-05-2014	Chris Ross	1.42	BUG 9546. Modified 'NEXT MOST RECENT' EmailAddress update to ensure we match 
**											  ON PartyID AS well AS AuditItemID WHEN we link back to update
**											  "Original" column values AS different parties can share the same
**											  the address (e.g. "Not Supplied" belongs to multiple Parties).
**	07-05-2014	Chris Ross	1.43	Fixed bug WHERE South Africa CustomerIDs slipping through AND being reported under "General"
**							1.44	BUG 9546. Fixed inconsistent reporting of Addresses (e.g. street number present but street missing)
**	12-05-2014	Chris Ross	1.45	Fixed issue with Live version freezing WHEN run FROM scheduled job - by removing all table variables
**	27-50-2014	Ali yuksel	1.5		BUG 1043 - Market name fixed in roadside
**  28-10-2014	Chris Ross	1.6		BUG 10924 - Added substring to concatenated address lines to ensure they don't overflow AND casue truncation errors
**	25-11-2014	Peter Doyle	1.7		BUG 11017 - Widen column CustomerIdentifier to nvarchar(50) in #PartyUniqueIDs 		
**  27-01-2014  Chris Ross	1.8		BUG 12038 - Include PreOwned Outlet function AND RoleType	
**  13-06-2016  Chris Ledger 1.9	BUG 12810 - Set market for CRC
**	17-10-2018  Ben King	 1.10	BUG 15062 - Please stop the customer update report feed for ALL SV-CRM markets
**	20/02/2019	Chris Ledger 1.11	BUG 15221 - Correct bug WHERE manufacturer SET based ON left 3 characters of VIN
**	26/09/2019	Chris Ledger 1.12	BUG 15562 - Add PAGCode
	15/01/2020	Chris Ledger 1.13	BUG 15372 - Correct incorrect cases
	01/04/2021	Eddie Thomas 1.14	Azure DevOps Task 287 : Subsitute DealerCode with Dealer10DigitCode

***************************************************************************


*/



/*
----------------------------------------------------------------------------------------------------------------------------------------
BUILD THE BASE TABLE AND GET THE CUSTOMER UPDATE FILE LOAD DATA THAT WE NEED.
----------------------------------------------------------------------------------------------------------------------------------------

*/

	-- v1.4 - Reinstated truncation of this table.  We can still get Audit information FROM underlying table
	--		  Plus the the way it was working meant that days WHEN the job failed the Audit would not be recorded anyway.
	--		  Now we will build just what we need each time (1 weeks worth of data).
	TRUNCATE TABLE [$(AuditDB)].[CustomerUpdateFeeds].AuditRowsCustomerUpdateFilesLoaded

	INSERT INTO [$(AuditDB)].[CustomerUpdateFeeds].AuditRowsCustomerUpdateFilesLoaded
	SELECT  
		AI.AuditID,
		AI.AuditItemID,
		F.[FileRowCount],
		F.ActionDate,
		F.FileTypeID,
		I.LoadSuccess
	FROM [$(AuditDB)].dbo.IncomingFiles I 
	INNER JOIN [$(AuditDB)].dbo.AuditItems AI ON AI.AuditID =I.AuditID
	INNER JOIN [$(AuditDB)].dbo.Files F ON F.AuditID =I.AuditID
	WHERE I.LoadSuccess = 1
	AND F.FileTypeID = 10
	AND F.ActionDate >= GETDATE() - 8
	AND F.ActionDate <= GETDATE()



 
	
	
/*

----------------------------------------------------------------------------------------------------------------------------------------
PRIME THE CUSTOMERUPDATEFEED TABLE WITH PartyIDS OF THE RECORDS THAT WERE LOADED VIA THE CUSTOMER UPDATE FILEs
----------------------------------------------------------------------------------------------------------------------------------------

*/
	-- v1.4 -- Reinstated truncate AS we now build just what we need each time rather 
	--		   running through everything we have previously loaded AS well.
	TRUNCATE TABLE CustomerUpdateFeeds.CustomerUpdateFeed

	INSERT INTO CustomerUpdateFeeds.CustomerUpdateFeed 
	(
		PartyID,
		CaseID,
		ActionDate
	)
	SELECT 
		CUD.PartyID,
		CUD.CaseID,
		CONVERT(DATE, ARC.ActionDate) AS ActionDate					-- v1.4 Remove time portion to remove dupes
	FROM [$(AuditDB)].CustomerUpdateFeeds.AuditRowsCustomerUpdateFilesLoaded ARC
	INNER JOIN [$(AuditDB)].Audit.EventPartyRoles AEPR ON ARC.AuditItemID = AEPR.AuditItemID
	INNER JOIN [$(AuditDB)].Audit.CustomerUpdate_Dealer CUD ON ARC.AuditItemID = CUD.AuditItemID

	UNION

	SELECT  
		CUE.PartyID,
		CUE.CaseID,
		CONVERT(DATE, ARC.ActionDate) AS ActionDate					-- v1.4 Remove time portion to remove dupes
	FROM [$(AuditDB)].CustomerUpdateFeeds.AuditRowsCustomerUpdateFilesLoaded ARC
	INNER JOIN [$(AuditDB)].Audit.EmailAddresses AE ON ARC.AuditItemID = AE.AuditItemID
	INNER JOIN [$(SampleDB)].ContactMechanism.PartyContactMechanisms APC ON AE.ContactMechanismID  = APC.ContactMechanismID
	INNER JOIN [$(AuditDB)].Audit.CustomerUpdate_EmailAddress CUE ON ARC.AuditItemID = CUE.AuditItemID
	WHERE CUE.CasePartyCombinationValid = 1

	UNION 

	SELECT 
		CUO.PartyID,
		CUO.CaseID,
		CONVERT(DATE, ARC.ActionDate) AS ActionDate					-- v1.4 Remove time portion to remove dupes
	FROM [$(AuditDB)].CustomerUpdateFeeds.AuditRowsCustomerUpdateFilesLoaded ARC
	INNER JOIN  [$(AuditDB)].Audit.Organisations AO ON ARC.AuditItemID = AO.AuditItemID
	INNER JOIN [$(AuditDB)].Audit.CustomerUpdate_Organisation CUO ON ARC.AuditItemID = CUO.AuditItemID
	WHERE CUO.CasePartyCombinationValid = 1

	UNION 

	SELECT 
		CUP.PartyID,
		CUP.CaseID,
		CONVERT(DATE, ARC.ActionDate) AS ActionDate					-- v1.4 Remove time portion to remove dupes
	FROM  [$(AuditDB)].CustomerUpdateFeeds.AuditRowsCustomerUpdateFilesLoaded ARC
	INNER JOIN [$(AuditDB)].Audit.People AP ON ARC.AuditItemID = AP.AuditItemID
	INNER JOIN  [$(AuditDB)].Audit.CustomerUpdate_Person CUP ON ARC.AuditItemID = CUP.AuditItemID
	WHERE CUP.CasePartyCombinationValid = 1

	UNION 

	SELECT  
		CUPA.PartyID,
		CUPA.CaseID,
		CONVERT(DATE, ARC.ActionDate) AS ActionDate					-- v1.4 Remove time portion to remove dupes
	FROM  [$(AuditDB)].CustomerUpdateFeeds.AuditRowsCustomerUpdateFilesLoaded ARC
	INNER JOIN [$(AuditDB)].Audit.PostalAddresses APA ON ARC.AuditItemID = APA.AuditItemID
	INNER JOIN [$(AuditDB)].Audit.PartyContactMechanisms APCM ON APA.ContactMechanismID  = APCM.ContactMechanismID
	INNER JOIN [$(AuditDB)].Audit.CustomerUpdate_PostalAddress CUPA ON ARC.AuditItemID = CUPA.AuditItemID
	WHERE CUPA.CasePartyCombinationValid = 1	

	UNION 

	SELECT  
		CURN.PartyID,
		CURN.CaseID,
		CONVERT(DATE, ARC.ActionDate) AS ActionDate					-- v1.4 Remove time portion to remove dupes
	FROM [$(AuditDB)].CustomerUpdateFeeds.AuditRowsCustomerUpdateFilesLoaded ARC
	INNER JOIN [$(AuditDB)].Audit.Registrations AR ON ARC.AuditItemID = AR.AuditItemID
	INNER JOIN [$(AuditDB)].Audit.CustomerUpdate_RegistrationNumber CURN ON ARC.AuditItemID = CURN.AuditItemID

	UNION 

	SELECT   
		CUT.PartyID,
		CUT.CaseID,
		CONVERT(DATE, ARC.ActionDate) AS ActionDate					-- v1.4 Remove time portion to remove dupes
	FROM [$(AuditDB)].CustomerUpdateFeeds.AuditRowsCustomerUpdateFilesLoaded ARC
	INNER JOIN [$(AuditDB)].Audit.TelephoneNumbers ATN ON ARC.AuditItemID = ATN.AuditItemID
	INNER JOIN [$(AuditDB)].Audit.PartyContactMechanisms APC ON ATN.ContactMechanismID  = APC.ContactMechanismID
	INNER JOIN [$(AuditDB)].Audit.CustomerUpdate_TelephoneNumber CUT ON ARC.AuditItemID = CUT.AuditItemID
	WHERE CUT.CasePartyCombinationValid = 1

	
	

------------------------------------------------------------------------------------
-- Update existing rows with bounceback flag or add in new Bouncebacks rows	
------------------------------------------------------------------------------------

	-- Get all the bouncebacks first
	CREATE TABLE #Bouncebacks 
		(
			PartyID		int,
			CaseID		int,
			BouncebackActionDate datetime,
			BouncebackType	VARCHAR(20)
		)
	
	INSERT INTO #Bouncebacks 
	SELECT DISTINCT 
		CO.PartyID,
		CO.CaseID,
		CONVERT(DATE, ARC.ActionDate) AS BouncebackActionDate,
		'Email' AS BouncebackType
	FROM [$(AuditDB)].CustomerUpdateFeeds.AuditRowsCustomerUpdateFilesLoaded ARC
	INNER JOIN [$(AuditDB)].Audit.CustomerUpdate_ContactOutcome CO ON ARC.AuditItemID = CO.AuditItemID
	WHERE CasePartyEmailCombinationValid = 1

	--UNION				-- 1.41 Commented out -- possible re-instate later 

	--SELECT DISTINCT 
		--CO.PartyID,
		--CO.CaseID,
		--CONVERT(DATE, ARC.ActionDate) AS BouncebackActionDate,
		--'SMS' AS BouncebackType
	--FROM [$(AuditDB)].CustomerUpdateFeeds.AuditRowsCustomerUpdateFilesLoaded ARC
	--INNER JOIN [$(AuditDB)].Audit.CustomerUpdate_SMSBouncebacks CO ON ARC.AuditItemID = CO.AuditItemID
	--WHERE CasePartyMobileCombinationValid = 1

	-- Update WHERE a customer update already exists for the CASE/Party
	UPDATE CUF
	SET	BouncebackActionDate = BB.BouncebackActionDate,
		BouncebackType		= BB.BouncebackType,
		Bounceback			= 'Y'
	FROM #Bouncebacks BB
	INNER JOIN CustomerUpdateFeeds.CustomerUpdateFeed CUF ON CUF.PartyID = BB.PartyID
																		AND CUF.CaseID = BB.CaseID
	
	
	-- Insert bounceback row WHERE no customer update already exists for the CASE/Party
	INSERT INTO CustomerUpdateFeeds.CustomerUpdateFeed 
	(
		PartyID,
		CaseID,
		BouncebackActionDate,
		BouncebackType,
		Bounceback
	)	
	SELECT DISTINCT 
		BB.PartyID,
		BB.CaseID,
		BB.BouncebackActionDate,
		BB.BouncebackType,
		'Y' AS Bounceback
	FROM #Bouncebacks BB
	LEFT JOIN CustomerUpdateFeeds.CustomerUpdateFeed CUF ON CUF.PartyID = BB.PartyID
																		AND CUF.CaseID = BB.CaseID
	WHERE CUF.CaseID IS NULL



/*

-------------------------------------------------------------------------------------------------------------------------
INSERT THE AUDITITEM ID FOR EACH OF THE UPDATE TYPES, IN ORDER TO FIND THE STATUS PRIOR TO THE UPDATE
-------------------------------------------------------------------------------------------------------------------------

*/

/*
 Person
*/	
	UPDATE 
	CustomerUpdateFeeds.CustomerUpdateFeed
	SET CustomerUpdate_AuditItemID = CUP.AuditItemID
	FROM [$(AuditDB)].CustomerUpdateFeeds.AuditRowsCustomerUpdateFilesLoaded ARC
		INNER JOIN [$(AuditDB)].Audit.People AP ON ARC.AuditItemID = AP.AuditItemID
		INNER JOIN [$(AuditDB)].Audit.CustomerUpdate_Person CUP ON ARC.AuditItemID = CUP.AuditItemID
								AND AP.PartyID = CUP.PartyID
		INNER JOIN CustomerUpdateFeeds.CustomerUpdateFeed CUF ON CUP.PartyID = CUF.PartyID
								AND CUP.CaseID = CUF.CaseID
	
 
/*
 Organisation
*/

	UPDATE 
	CustomerUpdateFeeds.CustomerUpdateFeed
	SET OrganisationUpdate_AuditItemID = CUO.AuditItemID
	FROM [$(AuditDB)].CustomerUpdateFeeds.AuditRowsCustomerUpdateFilesLoaded ARC
	INNER JOIN [$(AuditDB)].Audit.Organisations AO ON ARC.AuditItemID = AO.AuditItemID		
	INNER JOIN [$(AuditDB)].Audit.CustomerUpdate_Organisation CUO ON ARC.AuditItemID = CUO.AuditItemID
	INNER JOIN CustomerUpdateFeeds.CustomerUpdateFeed CUF ON CUO.PartyID = CUF.PartyID 
						AND CUO.CaseID = CUF.CaseID
	
	
 
/*
 Electronic Address
*/

	UPDATE 
	CustomerUpdateFeeds.CustomerUpdateFeed
	SET EmailAddressUpdate_AuditItemID = CUE.AuditItemID
	FROM [$(AuditDB)].CustomerUpdateFeeds.AuditRowsCustomerUpdateFilesLoaded ARC
		INNER JOIN [$(AuditDB)].Audit.EmailAddresses AE ON ARC.AuditItemID = AE.AuditItemID
		INNER JOIN [$(SampleDB)].ContactMechanism.PartyContactMechanisms APC ON AE.ContactMechanismID  = APC.ContactMechanismID
		INNER JOIN [$(AuditDB)].Audit.CustomerUpdate_EmailAddress CUE ON ARC.AuditItemID = CUE.AuditItemID
		INNER JOIN CustomerUpdateFeeds.CustomerUpdateFeed CUF ON CUE.PartyID = CUF.PartyID
									AND CUE.CaseID = CUF.CaseID


 
/*
 Telecommunications Numbers
*/
	UPDATE 
	CustomerUpdateFeeds.CustomerUpdateFeed
	SET TelephoneUpdate_AuditItemID = CUT.AuditItemID
	FROM [$(AuditDB)].CustomerUpdateFeeds.AuditRowsCustomerUpdateFilesLoaded ARC
		INNER JOIN [$(AuditDB)].Audit.TelephoneNumbers ATN ON ARC.AuditItemID = ATN.AuditItemID
		INNER JOIN [$(AuditDB)].Audit.PartyContactMechanisms APC ON ATN.ContactMechanismID  = APC.ContactMechanismID
		INNER JOIN [$(AuditDB)].Audit.CustomerUpdate_TelephoneNumber CUT ON ARC.AuditItemID = CUT.AuditItemID
		INNER JOIN CustomerUpdateFeeds.CustomerUpdateFeed CUF ON CUT.PartyID = CUF.PartyID 
									AND CUT.CaseID = CUF.CaseID 
	

 
/*
 Registrations
*/

	UPDATE 
	CustomerUpdateFeeds.CustomerUpdateFeed
	SET RegistrationUpdate_AuditItemID = CURN.AuditItemID
	FROM [$(AuditDB)].CustomerUpdateFeeds.AuditRowsCustomerUpdateFilesLoaded ARC
		INNER JOIN [$(AuditDB)].Audit.Registrations AR ON ARC.AuditItemID = AR.AuditItemID
		INNER JOIN  [$(AuditDB)].Audit.CustomerUpdate_RegistrationNumber CURN ON ARC.AuditItemID = CURN.AuditItemID
		INNER JOIN CustomerUpdateFeeds.CustomerUpdateFeed CUF ON CURN.PartyID = CUF.PartyID 
									AND CURN.CaseID = CUF.CaseID 
	

 

/*
 Postal Addresses
*/

	UPDATE 
	CustomerUpdateFeeds.CustomerUpdateFeed
	SET PostalAddressUpdate_AuditItemID = CUPA.AuditItemID
	FROM [$(AuditDB)].CustomerUpdateFeeds.AuditRowsCustomerUpdateFilesLoaded ARC
		INNER JOIN [$(AuditDB)].Audit.PostalAddresses APA ON ARC.AuditItemID = APA.AuditItemID
		INNER JOIN [$(AuditDB)].Audit.PartyContactMechanisms APCM ON APA.ContactMechanismID  = APCM.ContactMechanismID
		INNER JOIN [$(AuditDB)].Audit.CustomerUpdate_PostalAddress CUPA ON ARC.AuditItemID = CUPA.AuditItemID
		INNER JOIN CustomerUpdateFeeds.CustomerUpdateFeed CUF ON CUPA.PartyID = CUF.PartyID 
									AND CUPA.CaseID = CUF.CaseID 


 

/*
 Dealer Updates
*/

	UPDATE 
	CustomerUpdateFeeds.CustomerUpdateFeed
	SET DealerUpdate_AuditItemID = CUD.AuditItemID
	FROM [$(AuditDB)].CustomerUpdateFeeds.AuditRowsCustomerUpdateFilesLoaded ARC
		INNER JOIN [$(AuditDB)].Audit.EventPartyRoles AEPR ON ARC.AuditItemID = AEPR.AuditItemID
		INNER JOIN [$(AuditDB)].Audit.CustomerUpdate_Dealer CUD ON ARC.AuditItemID = CUD.AuditItemID
		INNER JOIN CustomerUpdateFeeds.CustomerUpdateFeed CUF ON CUD.PartyID = CUF.PartyID 
									AND CUD.CaseID = CUF.CaseID 
	


/*

------------------------------------------------------------------------------------------------------------------------------------------
	RUN UPDATES, TO INCLUDE ALL OF THE HEADLINE DATA, WHERE IT IS AVAILABLE.
------------------------------------------------------------------------------------------------------------------------------------------

*/
	
	UPDATE CUF
	SET
		CUF.TransactionType = 'U',
		CUF.OutletType = COALESCE(JDT.OutletFunction, JDO.OutletFunction) ,			--v1.8
		CUF.RegistrationNumber = CASE
									WHEN LEN(R.RegistrationNumber) > 2 THEN R.RegistrationNumber
									ELSE NULL
		END,
		CUF.Market = COALESCE(JDT.Market, JDO.Market),
		CUF.VIN = V.VIN,
		CUF.VehicleID = V.VehicleID,
		CUF.ClosureDate = C.ClosureDate 
	FROM CustomerUpdateFeeds.CustomerUpdateFeed CUF
	INNER JOIN [$(SampleDB)].Event.AutomotiveEventBasedInterviews AEBI ON CUF.CaseID  = AEBI.CaseID
																	AND CUF.PartyID = AEBI.PartyID
 	INNER JOIN [$(SampleDB)].Event.Cases C ON AEBI.CaseID = C.CaseID
  	INNER JOIN [$(AuditDB)].Audit.EventPartyRoles AEPR ON AEBI.EventID = AEPR.EventID
	LEFT JOIN [$(SampleDB)].dbo.DW_JLRCSPDealers JDO ON AEPR.PartyID = JDO.OutletPartyID
  													AND AEPR.RoleTypeID  = JDO.OutletFunctionID
	LEFT JOIN [$(SampleDB)].dbo.DW_JLRCSPDealers JDT ON AEPR.PartyID = JDT.TransferPartyID
  													AND AEPR.RoleTypeID  = JDT.OutletFunctionID
 	INNER JOIN [$(SampleDB)].Vehicle.Vehicles V ON AEBI.VehicleID = V.VehicleID 
 	LEFT JOIN (
		SELECT EventID, VehicleID, MAX(RegistrationID) AS RegistrationID
		FROM [$(SampleDB)].Vehicle.VehicleRegistrationEvents
		GROUP BY EventID, VehicleID
	) M
		INNER JOIN [$(SampleDB)].Vehicle.Registrations R ON R.RegistrationID = M.RegistrationID
	ON M.EventID = AEBI.EventID AND M.VehicleID = AEBI.VehicleID
	
 

/*

------------------------------------------------------------------------------------------------------------------------------------------
RUN UPDATES, TO INCLUDE THE MOST RECENT ENTRIES FOR EACH FIELD IN THE NEW FIELD SECTION
------------------------------------------------------------------------------------------------------------------------------------------

*/

/*
 Person
*/
	UPDATE CUF
	SET
		CUF.NEW_Title  = COALESCE(PNT.Title, AP.Title),
		CUF.NEW_CustomerFirstName  = COALESCE(AP.FirstName, AP.FirstNameOrig),
		CUF.NEW_CustomerSecondLastName = COALESCE(AP.SecondLastName, AP.SecondLastNameOrig),
		CUF.NEW_CustomerLastName = COALESCE(AP.LastName, AP.LastNameOrig)
	FROM [$(AuditDB)].CustomerUpdateFeeds.AuditRowsCustomerUpdateFilesLoaded ARC
	INNER JOIN [$(AuditDB)].Audit.People AP 
		LEFT JOIN [$(SampleDB)].Party.Titles PNT ON PNT.TitleID = AP.TitleID
	ON ARC.AuditItemID = AP.AuditItemID
	INNER JOIN [$(AuditDB)].Audit.CustomerUpdate_Person ACP ON ACP.AuditItemID = AP.AuditItemID
	INNER JOIN CustomerUpdateFeeds.CustomerUpdateFeed CUF ON AP.PartyID = CUF.PartyID
							AND ACP.CaseID = CUF.CaseID
	


	
 
/*
 Organisation
*/
	
	UPDATE CUF
	SET CUF.[NEW_OrganisationName] = AO.OrganisationName
	FROM [$(AuditDB)].CustomerUpdateFeeds.AuditRowsCustomerUpdateFilesLoaded ARC
	INNER JOIN [$(AuditDB)].Audit.Organisations AO ON ARC.AuditItemID = AO.AuditItemID
	INNER JOIN [$(AuditDB)].Audit.CustomerUpdate_Organisation ACO ON ACO.AuditItemID = AO.AuditItemID
	INNER JOIN CustomerUpdateFeeds.CustomerUpdateFeed CUF ON AO.AuditItemID = CUF.OrganisationUpdate_AuditItemID
							AND ACO.CaseID = CUF.CaseID
	

 
/*	
 Electronic Addresses
*/

	UPDATE CUF
	SET
		CUF.NEW_EmailAddress_ContactMechanismID = C.ContactMechanismID,
		CUF.NEW_EmailAddress = AE.EmailAddress,
		CUF.NEW_EmailAddressTYPE_Text = CMPT.ContactMechanismPurposeType,
		CUF.NEW_EmailAddressTYPE_ID = CMPT.ContactMechanismPurposeTypeID
	FROM [$(AuditDB)].CustomerUpdateFeeds.AuditRowsCustomerUpdateFilesLoaded ARC
	INNER JOIN [$(AuditDB)].Audit.EmailAddresses AE ON ARC.AuditItemID = AE.AuditItemID
	INNER JOIN [$(AuditDB)].Audit.PartyContactMechanisms APC ON AE.ContactMechanismID  = APC.ContactMechanismID
							AND APC.AuditItemID = AE.AuditItemID
	INNER JOIN [$(AuditDB)].Audit.PartyContactMechanismPurposes APCMP ON APCMP.AuditItemID = APC.AuditItemID
							AND APCMP.ContactMechanismID = APC.ContactMechanismID
	INNER JOIN [$(SampleDB)].ContactMechanism.ContactMechanismPurposeTypes CMPT ON CMPT.ContactMechanismPurposeTypeID = APCMP.ContactMechanismPurposeTypeID
	INNER JOIN [$(SampleDB)].ContactMechanism.ContactMechanisms C On APC.ContactMechanismID = C.ContactMechanismID
	INNER JOIN [$(SampleDB)].ContactMechanism.ContactMechanismTypes CMT ON C.ContactMechanismTypeID = CMT.ContactMechanismTypeID
	INNER  JOIN CustomerUpdateFeeds.CustomerUpdateFeed CUF ON APC.PartyID = CUF.PartyID
	INNER JOIN [$(AuditDB)].Audit.CustomerUpdate_EmailAddress CUE ON ARC.AuditItemID = CUE.AuditItemID
								AND CUE.CaseID = CUF.CaseID
	

/*
 Telephone Numbers
*/
	-- NEW_ContactNumber
	UPDATE CUF
	SET 
		CUF.NEW_ContactNumber = ATN.ContactNumber,
		CUF.NEW_ContactNumberTYPE_Text = 'Telephone (Unknown Purpose)'
	FROM [$(AuditDB)].CustomerUpdateFeeds.AuditRowsCustomerUpdateFilesLoaded ARC
	INNER JOIN [$(AuditDB)].Audit.TelephoneNumbers ATN ON ARC.AuditItemID = ATN.AuditItemID
	INNER JOIN [$(AuditDB)].Audit.PartyContactMechanisms APC ON ATN.ContactMechanismID = APC.ContactMechanismID
	INNER JOIN [$(AuditDB)].Audit.PartyContactMechanismPurposes APCMP ON APCMP.AuditItemID = APC.AuditItemID
							AND APCMP.ContactMechanismID = APC.ContactMechanismID
	INNER JOIN [$(SampleDB)].ContactMechanism.vwDA_PartyContactMechanismPurposes VPCMP ON VPCMP.ContactMechanismID = APC.ContactMechanismID 
										AND VPCMP.PartyID = APC.PartyID 
										AND VPCMP.ContactMechanismPurposeTypeID = APCMP.ContactMechanismPurposeTypeID
										AND VPCMP.ContactMechanismPurposeTypeID  = 16
	INNER JOIN [$(SampleDB)].ContactMechanism.ContactMechanisms C ON ATN.ContactMechanismID = C.ContactMechanismID
	INNER JOIN [$(SampleDB)].ContactMechanism.ContactMechanismTypes CMT ON C.ContactMechanismTypeID = CMT.ContactMechanismTypeID
	INNER JOIN [$(AuditDB)].Audit.CustomerUpdate_TelephoneNumber ACT ON ACT.AuditItemID = ARC.AuditItemID
	INNER JOIN CustomerUpdateFeeds.CustomerUpdateFeed CUF ON APC.PartyID = CUF.PartyID
							AND CUF.CaseID = ACT.CaseID
	
	-- NEW_MobileContactNumber
	UPDATE CUF
	SET
		CUF.NEW_MobileContactNumber = ATN.ContactNumber,
		CUF.NEW_ContactNumberTYPE_Text = 'Mobile (Unknown Purpose)'
	FROM [$(AuditDB)].CustomerUpdateFeeds.AuditRowsCustomerUpdateFilesLoaded ARC
	INNER JOIN [$(AuditDB)].Audit.TelephoneNumbers ATN ON ARC.AuditItemID = ATN.AuditItemID
	INNER JOIN [$(AuditDB)].Audit.PartyContactMechanisms APC ON ATN.ContactMechanismID = APC.ContactMechanismID
	INNER JOIN [$(AuditDB)].Audit.PartyContactMechanismPurposes APCMP ON APCMP.AuditItemID = APC.AuditItemID
							AND APCMP.ContactMechanismID = APC.ContactMechanismID
	INNER JOIN  [$(SampleDB)].ContactMechanism.vwDA_PartyContactMechanismPurposes VPCMP ON VPCMP.ContactMechanismID  = APC.ContactMechanismID 
									AND VPCMP.PartyID  = APC.PartyID 
									AND VPCMP.ContactMechanismPurposeTypeID = APCMP.ContactMechanismPurposeTypeID
									AND VPCMP.ContactMechanismPurposeTypeID  = 17
	INNER JOIN [$(SampleDB)].ContactMechanism.ContactMechanisms C On ATN.ContactMechanismID = C.ContactMechanismID
	INNER JOIN [$(SampleDB)].ContactMechanism.ContactMechanismTypes CMT ON C.ContactMechanismTypeID = CMT.ContactMechanismTypeID
	INNER JOIN [$(AuditDB)].Audit.CustomerUpdate_TelephoneNumber ACT ON ACT.AuditItemID = ARC.AuditItemID
	INNER JOIN CustomerUpdateFeeds.CustomerUpdateFeed CUF ON APC.PartyID = CUF.PartyID
							AND CUF.CaseID = ACT.CaseID
	

	-- NEW_WorkContactNumber
	UPDATE CUF
	SET 
		CUF.NEW_WorkContactNumber = ATN.ContactNumber,
		CUF.NEW_ContactNumberTYPE_Text = 'Work Direct Dial'
	FROM [$(AuditDB)].CustomerUpdateFeeds.AuditRowsCustomerUpdateFilesLoaded ARC
	INNER JOIN [$(AuditDB)].Audit.TelephoneNumbers ATN ON ARC.AuditItemID = ATN.AuditItemID
	INNER JOIN [$(AuditDB)].Audit.PartyContactMechanisms APC ON ATN.ContactMechanismID = APC.ContactMechanismID
	INNER JOIN [$(AuditDB)].Audit.PartyContactMechanismPurposes APCMP ON APCMP.AuditItemID = APC.AuditItemID
							AND APCMP.ContactMechanismID = APC.ContactMechanismID
	INNER JOIN [$(SampleDB)].ContactMechanism.vwDA_PartyContactMechanismPurposes VPCMP ON VPCMP.ContactMechanismID = APC.ContactMechanismID 
										AND VPCMP.PartyID = APC.PartyID 
										AND VPCMP.ContactMechanismPurposeTypeID = APCMP.ContactMechanismPurposeTypeID
										AND VPCMP.ContactMechanismPurposeTypeID  = 7
	INNER JOIN [$(SampleDB)].ContactMechanism.ContactMechanisms C On ATN.ContactMechanismID = C.ContactMechanismID
	INNER JOIN [$(SampleDB)].ContactMechanism.ContactMechanismTypes CMT ON C.ContactMechanismTypeID = CMT.ContactMechanismTypeID
	INNER JOIN [$(AuditDB)].Audit.CustomerUpdate_TelephoneNumber ACT ON ACT.AuditItemID = ARC.AuditItemID
	INNER JOIN CustomerUpdateFeeds.CustomerUpdateFeed CUF ON APC.PartyID = CUF.PartyID
							AND CUF.CaseID = ACT.CaseID
	
 

/*
Registrations
*/
	UPDATE CUF
	SET CUF.[NEW_RegistrationNumber] = AR.RegistrationNumber
	FROM [$(AuditDB)].CustomerUpdateFeeds.AuditRowsCustomerUpdateFilesLoaded ARC
	INNER JOIN [$(AuditDB)].Audit.Registrations AR ON ARC.AuditItemID = AR.AuditItemID
	INNER JOIN [$(AuditDB)].Audit.CustomerUpdate_RegistrationNumber ACR ON ACR.AuditItemID = AR.AuditItemID
	INNER JOIN CustomerUpdateFeeds.CustomerUpdateFeed CUF ON ACR.PartyID = CUF.PartyID
							AND CUF.CaseID = ACR.CaseID


 

/*
 Addresses
*/

	UPDATE CUF
	SET 
		CUF.[NEW_AddressContactMechanismID] = APA.ContactMechanismID,
		CUF.[NEW_AddressLine1] = ISNULL(APA.BuildingName,''),
		CUF.[NEW_AddressLine2] = SUBSTRING(ISNULL(NULLIF(APA.SubStreetNumber , '') + ' ', '') + ISNULL(APA.SubStreet, NULL), 0, 150),	-- v1.44	-- v1.6
		CUF.[NEW_AddressLine3] = SUBSTRING(ISNULL(NULLIF(APA.StreetNumber, '') + ' ', '') + ISNULL(APA.Street, NULL), 0, 150),			-- v1.44	-- v1.6
		CUF.[NEW_AddressLine4] = ISNULL(APA.SubLocality,''),
		CUF.[NEW_AddressLine5] = ISNULL(APA.Locality,''),
		CUF.[NEW_Town] = ISNULL (APA.Town,''),
		CUF.[NEW_Region] = ISNULL(APA.Region,'') ,
		CUF.[NEW_Country]  = ISNULL(C.Country,''),
		CUF.[NEW_PostCode] = ISNULL(APA.PostCode,''),
		CUF.[NEW_AddressContactMechanismTypeID] = APCMP.ContactMechanismPurposeTypeID
	FROM [$(AuditDB)].CustomerUpdateFeeds.AuditRowsCustomerUpdateFilesLoaded ARC
	INNER JOIN [$(AuditDB)].Audit.PostalAddresses APA ON ARC.AuditItemID = APA.AuditItemID
	INNER JOIN [$(AuditDB)].Audit.PartyContactMechanisms APCM ON APA.ContactMechanismID  = APCM.ContactMechanismID
							AND APCM.AuditItemID = APA.AuditItemID
	INNER JOIN [$(AuditDB)].Audit.PartyContactMechanismPurposes APCMP ON APCMP.ContactMechanismID= APCM.ContactMechanismID
								AND APCMP.PartyID = APCM.PartyID 
								AND APCMP.AuditItemID = APCM.AuditItemID
	INNER JOIN [$(AuditDB)].Audit.CustomerUpdate_PostalAddress ACP ON ACP.AuditItemID = APA.AuditItemID
	INNER JOIN CustomerUpdateFeeds.CustomerUpdateFeed CUF ON APCM.PartyID = CUF.PartyID
							AND CUF.CaseID = ACP.CaseID
	LEFT JOIN [$(SampleDB)].ContactMechanism.Countries C ON APA.CountryID = C.CountryID
	

  

/*
 Dealer Updates
*/
	UPDATE CUF
	SET
		CUF.[NEW_DealerCode] =  ISNULL(CAST(DJD.TransferDealerCode AS NVARCHAR(100)), 'OUTSIDE OF DEALER NETWORK'),
	 	CUF.[NEW_DealerShortName] = ISNULL(DJD.TransferDealer, 'OUTSIDE OF DEALER NETWORK')
	FROM [$(AuditDB)].CustomerUpdateFeeds.AuditRowsCustomerUpdateFilesLoaded ARC
	INNER JOIN [$(AuditDB)].Audit.EventPartyRoles AEPR ON ARC.AuditItemID = AEPR.AuditItemID
	INNER JOIN [$(AuditDB)].Audit.CustomerUpdate_Dealer ACD ON ACD.AuditItemID = AEPR.AuditItemID
	INNER JOIN CustomerUpdateFeeds.CustomerUpdateFeed CUF ON AEPR.AuditItemID = CUF.DealerUpdate_AuditItemID
							AND CUF.CaseID = ACD.CaseID
	LEFT JOIN [$(SampleDB)].dbo.DW_JLRCSPDealers DJD ON AEPR.PartyID = DJD.TransferPartyID
												AND AEPR.RoleTypeID = DJD.OutletFunctionID
	WHERE AEPR.RoleTypeID In (SELECT RoleTypeID FROM [$(SampleDB)].[dbo].[vwDealerRoleTypes])			--v1.8



/*

------------------------------------------------------------------------------------------------------------------------------------------
RUN UPDATES SO THAT WE HAVE ALL OF THE MOST RECENT DATA, BARRING THOSE CORRELATING
 TO THE FIELDS UPDATED IN THE 'NEW' SECTION
------------------------------------------------------------------------------------------------------------------------------------------

*/

/*
 Person 
*/
	UPDATE CUF
	SET
		CUF.Title = ISNULL(PNT.Title, NULL),
		CUF.CustomerFirstName = ISNULL(P.FirstName, NULL),
		CUF.CustomerSecondLastName = ISNULL(P.SecondLastName, NULL),
		CUF.CustomerLastName = ISNULL(P.LastName, NULL)
	FROM CustomerUpdateFeeds.CustomerUpdateFeed CUF
	INNER JOIN [$(SampleDB)].Party.People P ON P.PartyID = CUF.PartyID
	INNER JOIN [$(SampleDB)].Party.Titles PNT ON P.TitleID = PNT.TitleID
	LEFT JOIN [$(AuditDB)].Audit.CustomerUpdate_Person CUP ON CUF.CustomerUpdate_AuditItemID = CUP.AuditItemID
	WHERE CUP.PartyID IS NULL

			
  
/*
 Organisation 
*/	

	-- Get organisation name for Organisation parties
	UPDATE CUF
	SET CUF.OrganisationName = O.OrganisationName
	FROM CustomerUpdateFeeds.CustomerUpdateFeed CUF
	INNER JOIN [$(SampleDB)].Party.Organisations O ON O.PartyID = CUF.PartyID
	LEFT JOIN [$(AuditDB)].Audit.CustomerUpdate_Organisation CUP ON CUF.OrganisationUpdate_AuditItemID = CUP.AuditItemID
	WHERE CUP.PartyID IS NULL

	-- Get organisation name for People parties
	UPDATE CUF
	SET CUF.OrganisationName = O.OrganisationName
	FROM CustomerUpdateFeeds.CustomerUpdateFeed CUF
	INNER JOIN [$(SampleDB)].Party.People P ON P.PartyID = CUF.PartyID
	INNER JOIN [$(SampleDB)].Party.PartyRelationships PR ON PR.PartyIDFrom = P.PartyID
							AND PR.RoleTypeIDFrom = 4
							AND PR.RoleTypeIDTo = 3
	INNER JOIN [$(SampleDB)].Party.Organisations O ON O.PartyID = PR.PartyIDTo
	LEFT JOIN [$(AuditDB)].Audit.CustomerUpdate_Organisation CUP ON CUF.OrganisationUpdate_AuditItemID = CUP.AuditItemID
	WHERE CUP.PartyID IS NULL

 
/*
ElectronicAddresses	
*/
	UPDATE CUF
	SET CUF.EmailAddress = ISNULL(E.EmailAddress, NULL) 
	FROM CustomerUpdateFeeds.CustomerUpdateFeed CUF
	INNER JOIN (
		SELECT CUF.CaseID, CUF.PartyID, MAX(E.ContactMechanismID) AS MaxContactMechanismID
		FROM CustomerUpdateFeeds.CustomerUpdateFeed CUF
			INNER JOIN [$(SampleDB)].ContactMechanism.PartyContactMechanisms PC ON CUF.PartyID  = PC.PartyID
			INNER JOIN  [$(SampleDB)].ContactMechanism.EmailAddresses E ON PC.ContactMechanismID = E.ContactMechanismID
			LEFT JOIN [$(AuditDB)].Audit.CustomerUpdate_EmailAddress CUE ON CUF.EmailAddressUpdate_AuditItemID = CUE.AuditItemID
		WHERE CUE.PartyID IS NULL
		GROUP BY CUF.CaseID, CUF.PartyID
	) M ON M.CaseID = CUF.CaseID AND M.PartyID = CUF.PartyID
	INNER JOIN [$(SampleDB)].ContactMechanism.EmailAddresses E ON M.MaxContactMechanismID = E.ContactMechanismID

/*
Telephone Numbers
*/
	-- HomeContactNumber
	UPDATE CUF
	SET CUF.HomeContactNumber = ISNULL(TN.ContactNumber, NULL)
	FROM CustomerUpdateFeeds.CustomerUpdateFeed CUF
	INNER JOIN (
		SELECT CUF.CaseID, CUF.PartyID, MAX(TN.ContactMechanismID) AS MaxContactMechanismID
		FROM CustomerUpdateFeeds.CustomerUpdateFeed CUF
		INNER JOIN  [$(SampleDB)].ContactMechanism.PartyContactMechanisms PC ON  PC.PartyID = CUF.PartyID
		INNER JOIN [$(SampleDB)].ContactMechanism.TelephoneNumbers TN ON PC.ContactMechanismID = TN.ContactMechanismID	
		INNER JOIN [$(SampleDB)].ContactMechanism.ContactMechanisms C On TN.ContactMechanismID = C.ContactMechanismID
		INNER JOIN [$(SampleDB)].ContactMechanism.ContactMechanismTypes CMT ON C.ContactMechanismTypeID = CMT.ContactMechanismTypeID
									AND CMT.ContactMechanismTypeID  = 3
		LEFT JOIN [$(AuditDB)].Audit.CustomerUpdate_TelephoneNumber CUT ON CUF.TelephoneUpdate_AuditItemID = CUT.AuditItemID
		WHERE CUT.PartyID IS NULL
		GROUP BY CUF.CaseID, CUF.PartyID
	) M ON M.CaseID = CUF.CaseID AND M.PartyID = CUF.PartyID
	INNER JOIN [$(SampleDB)].ContactMechanism.TelephoneNumbers TN ON TN.ContactMechanismID = M.MaxContactMechanismID
 
	-- WorkContactNumber
	UPDATE CUF
	SET CUF.WorkContactNumber = ISNULL(TN.ContactNumber, NULL)
	FROM CustomerUpdateFeeds.CustomerUpdateFeed CUF
	INNER JOIN (
		SELECT CUF.CaseID, CUF.PartyID, MAX(TN.ContactMechanismID) AS MaxContactMechanismID
		FROM CustomerUpdateFeeds.CustomerUpdateFeed CUF
		INNER JOIN [$(SampleDB)].ContactMechanism.PartyContactMechanisms PC ON  PC.PartyID = CUF.PartyID
		INNER JOIN [$(SampleDB)].ContactMechanism.TelephoneNumbers TN ON PC.ContactMechanismID = TN.ContactMechanismID	
		INNER JOIN [$(SampleDB)].ContactMechanism.ContactMechanisms C On TN.ContactMechanismID = C.ContactMechanismID
		INNER JOIN [$(SampleDB)].ContactMechanism.ContactMechanismTypes CMT ON C.ContactMechanismTypeID = CMT.ContactMechanismTypeID
									AND CMT.ContactMechanismTypeID  = 2
		LEFT JOIN [$(AuditDB)].Audit.CustomerUpdate_TelephoneNumber CUT ON CUF.TelephoneUpdate_AuditItemID = CUT.AuditItemID
		WHERE CUT.PartyID IS NULL
		GROUP BY CUF.CaseID, CUF.PartyID
	) M ON M.CaseID = CUF.CaseID AND M.PartyID = CUF.PartyID
	INNER JOIN [$(SampleDB)].ContactMechanism.TelephoneNumbers TN ON TN.ContactMechanismID = M.MaxContactMechanismID

	-- MobileContactNumber
 	UPDATE CUF
	SET CUF.MobileContactNumber = ISNULL(TN.ContactNumber, NULL)
	FROM CustomerUpdateFeeds.CustomerUpdateFeed CUF
	INNER JOIN (
		SELECT CUF.CaseID, CUF.PartyID, MAX(TN.ContactMechanismID) AS MaxContactMechanismID
		FROM CustomerUpdateFeeds.CustomerUpdateFeed CUF
		INNER JOIN [$(SampleDB)].ContactMechanism.PartyContactMechanisms PC ON  PC.PartyID = CUF.PartyID
		INNER JOIN [$(SampleDB)].ContactMechanism.TelephoneNumbers TN ON PC.ContactMechanismID = TN.ContactMechanismID	
		INNER JOIN [$(SampleDB)].ContactMechanism.ContactMechanisms C On TN.ContactMechanismID = C.ContactMechanismID
		INNER JOIN [$(SampleDB)].ContactMechanism.ContactMechanismTypes CMT ON C.ContactMechanismTypeID = CMT.ContactMechanismTypeID
									AND CMT.ContactMechanismTypeID  = 4
		LEFT JOIN [$(AuditDB)].Audit.CustomerUpdate_TelephoneNumber CUT ON CUF.TelephoneUpdate_AuditItemID = CUT.AuditItemID
		WHERE CUT.PartyID IS NULL
		GROUP BY CUF.CaseID, CUF.PartyID
	) M ON M.CaseID = CUF.CaseID AND M.PartyID = CUF.PartyID
	INNER JOIN [$(SampleDB)].ContactMechanism.TelephoneNumbers TN ON TN.ContactMechanismID = M.MaxContactMechanismID
 



/*
 Registration Number 
*/

	UPDATE CUF
	SET CUF.RegistrationNumber = CASE
					WHEN LEN(R.RegistrationNumber) > 2 THEN R.RegistrationNumber
					ELSE NULL
	END
	FROM CustomerUpdateFeeds.CustomerUpdateFeed CUF
	INNER JOIN (
		SELECT CUF.CaseID, CUF.PartyID, MAX(R.RegistrationID) AS MaxRegistrationID
		FROM CustomerUpdateFeeds.CustomerUpdateFeed CUF
		INNER JOIN [$(SampleDB)].Vehicle.VehicleRegistrationEvents VRE ON VRE.VehicleID = CUF.VehicleID
		INNER JOIN [$(SampleDB)].Vehicle.Registrations R ON R.RegistrationID = VRE.RegistrationID
		LEFT JOIN [$(AuditDB)].Audit.CustomerUpdate_RegistrationNumber CURN ON CUF.RegistrationUpdate_AuditItemID = CURN.AuditItemID
		WHERE CURN.PartyID IS NULL
		GROUP BY CUF.CaseID, CUF.PartyID
	) M ON M.CaseID = CUF.CaseID AND M.PartyID = CUF.PartyID
	INNER JOIN [$(SampleDB)].Vehicle.Registrations R ON R.RegistrationID = M.MaxRegistrationID

 
/*
 Addresses
*/
	UPDATE CUF
	SET
		CUF.AddressLine1 = ISNULL(PA.BuildingName, NULL),
		CUF.AddressLine2 = SUBSTRING(ISNULL(NULLIF(PA.SubStreetNumber , '') + ' ', '') + ISNULL(PA.SubStreet, NULL), 0, 150),		-- v1.44 -- v1.6
		CUF.AddressLine3 = SUBSTRING(ISNULL(NULLIF(PA.StreetNumber, '') + ' ', '') + ISNULL(PA.Street, NULL), 0, 150),				-- v1.44 -- v1.6
		CUF.AddressLine4 = ISNULL(PA.SubLocality, NULL),
		CUF.AddressLine5 = ISNULL(PA.Locality, NULL),
		CUF.Town = ISNULL(PA.Town, NULL),
		CUF.Region = ISNULL(PA.Region, NULL),
		CUF.Country  = ISNULL(C.Country, NULL),
		CUF.PostCode = ISNULL(PA.PostCode, NULL)
	FROM CustomerUpdateFeeds.CustomerUpdateFeed CUF
	INNER JOIN (
		SELECT CUF.CaseID, CUF.PartyID, MAX(PA.ContactMechanismID) AS MaxContactMechanismID
		FROM CustomerUpdateFeeds.CustomerUpdateFeed CUF
		INNER JOIN [$(SampleDB)].ContactMechanism.PartyContactMechanisms PCM ON CUF.PartyID = PCM.PartyID
		INNER JOIN [$(SampleDB)].ContactMechanism.PostalAddresses PA ON PCM.ContactMechanismID = PA.ContactMechanismID
		INNER JOIN [$(SampleDB)].ContactMechanism.Countries C ON PA.CountryID = C.CountryID
		LEFT JOIN [$(AuditDB)].Audit.CustomerUpdate_PostalAddress CUP ON CUF.PostalAddressUpdate_AuditItemID = CUP.AuditItemID
		WHERE CUP.PartyID IS NULL
		GROUP BY CUF.CaseID, CUF.PartyID
	) M ON M.CaseID = CUF.CaseID AND M.PartyID = CUF.PartyID
	INNER JOIN [$(SampleDB)].ContactMechanism.PostalAddresses PA ON PA.ContactMechanismID = M.MaxContactMechanismID
	INNER JOIN [$(SampleDB)].ContactMechanism.Countries C ON PA.CountryID = C.CountryID

/*
 Dealer
*/
	UPDATE CUF
	SET
		CUF.DealerCode =  COALESCE(JDT.TransferDealerCode, JDO.OutletCode, DN.DealerCode),
 		CUF.DealerShortName = COALESCE(JDT.TransferDealer, JDO.Outlet, DN.DealerShortName),
		CUF.PAGCode = COALESCE(NULLIF(JDT.PAGCode,''),JDO.PAGCode)			-- 1.12	 
	FROM CustomerUpdateFeeds.CustomerUpdateFeed CUF 
	INNER JOIN [$(SampleDB)].Event.AutomotiveEventBasedInterviews AEBI ON CUF.CaseID  = AEBI.CaseID
									AND CUF.PartyID = AEBI.PartyID
 	INNER JOIN [$(SampleDB)].Event.EventPartyRoles EPR ON AEBI.EventID = EPR.EventID
 	LEFT JOIN [$(SampleDB)].dbo.DW_JLRCSPDealers JDT ON EPR.PartyID = JDT.TransferPartyID
  							AND EPR.RoleTypeID = JDT.OutletFunctionID
 	LEFT JOIN [$(SampleDB)].dbo.DW_JLRCSPDealers JDO ON EPR.PartyID = JDO.OutletPartyID
  							AND EPR.RoleTypeID = JDO.OutletFunctionID	
	LEFT JOIN [$(SampleDB)].Party.DealerNetworks DN ON DN.PartyIDFrom = EPR.PartyID
							AND DN.RoleTypeIDFrom = EPR.RoleTypeID
	LEFT JOIN [$(AuditDB)].Audit.CustomerUpdate_Dealer CUD ON CUD.AuditItemID = CUF.DealerUpdate_AuditItemID
	WHERE CUD.AuditItemID IS NULL


/*

----------------------------------------------------------------------------------------------------------------------------------------
RUN UPDATES SO THAT WE HAVE ALL OF THE 'NEXT MOST RECENT'  DATA, FOR THE ORIGINAL FIELD VERSION OF THOSE THAT HAVE BEEN UPDATED,
----------------------------------------------------------------------------------------------------------------------------------------

*/

/*
 Person
*/

	UPDATE
	CustomerUpdateFeeds.CustomerUpdateFeed
	SET
	Title = ISNULL (AP.Title , NULL ) ,
	CustomerFirstName  =  ISNULL (AP.FirstName , NULL ) ,
	CustomerSecondLastName =  ISNULL (AP.SecondLastName , NULL )  ,
	CustomerLastName =  ISNULL (AP.LastName ,NULL )  
	FROM 
	[$(AuditDB)].Audit.People AP 
	INNER JOIN  CustomerUpdateFeeds.CustomerUpdateFeed CUF ON AP.PartyID = CUF.PartyID
		INNER JOIN
		(
			Select
			MAX(AP.AuditItemID) AS AuditItemID
			FROM CustomerUpdateFeeds.CustomerUpdateFeed CUF 
			INNER JOIN [$(AuditDB)].Audit.People AP ON CUF.PartyID = AP.PartyID
			INNER JOIN [$(AuditDB)].dbo.AuditItems AI ON AI.AuditItemID = AP.AuditItemID
			INNER JOIN [$(AuditDB)].dbo.Files F ON AI.AuditID = F.AuditID
			AND F.FileTypeID <> 10
			AND CUF.CustomerUpdate_AuditItemID IS NOT NULL
			GROUP BY 
			AP.PartyID
		) AS M ON AP.AuditItemID = M.AuditItemID
	
 
/*
Organisation 
*/	
	-- Get organisation name for Organisation parties
	UPDATE CUF
	SET CUF.OrganisationName = ISNULL(AO.OrganisationName, NULL) 
	FROM [$(AuditDB)].Audit.Organisations AO
	INNER JOIN CustomerUpdateFeeds.CustomerUpdateFeed CUF ON AO.PartyID = CUF.PartyID
	INNER JOIN (
		SELECT MAX(AO.AuditItemID) AS AuditItemID
		FROM CustomerUpdateFeeds.CustomerUpdateFeed CUF
		INNER JOIN [$(AuditDB)].Audit.Organisations AO ON CUF.PartyID = AO.PartyID
		INNER JOIN [$(AuditDB)].dbo.AuditItems AI ON AI.AuditItemID = AO.AuditItemID
		INNER JOIN [$(AuditDB)].dbo.Files F ON AI.AuditID = F.AuditID
			AND F.FileTypeID <> 10
			AND CUF.OrganisationUpdate_AuditItemID IS NOT NULL
		GROUP BY AO.PartyID
	) AS O ON AO.AuditItemID = O.AuditItemID

	-- Get organisation name for People parties
	UPDATE CUF
	SET CUF.OrganisationName = ISNULL(AO.OrganisationName, NULL) 
	FROM [$(AuditDB)].Audit.Organisations AO
	INNER JOIN (
		SELECT
			MAX(AO.AuditItemID) AS AuditItemID
		FROM CustomerUpdateFeeds.CustomerUpdateFeed CUF
		INNER JOIN [$(SampleDB)].Party.People P ON P.PartyID = CUF.PartyID
		INNER JOIN [$(SampleDB)].Party.PartyRelationships PR ON PR.PartyIDFrom = P.PartyID
								AND PR.RoleTypeIDFrom = 4
								AND PR.RoleTypeIDTo = 3
		INNER JOIN [$(AuditDB)].Audit.Organisations AO ON PR.PartyIDTo = AO.PartyID
		INNER JOIN [$(AuditDB)].dbo.AuditItems AI ON AI.AuditItemID = AO.AuditItemID
		INNER JOIN [$(AuditDB)].dbo.Files F ON AI.AuditID = F.AuditID
			AND F.FileTypeID <> 10
			AND CUF.OrganisationUpdate_AuditItemID IS NOT NULL
		GROUP BY CUF.PartyID
	) AS O ON AO.AuditItemID = O.AuditItemID
	INNER JOIN [$(SampleDB)].Party.PartyRelationships PR ON PR.PartyIDTo = AO.PartyID
								AND PR.RoleTypeIDFrom = 4
								AND PR.RoleTypeIDTo = 3
	INNER JOIN [$(SampleDB)].Party.People P ON P.PartyID = PR.PartyIDFrom
	INNER JOIN CustomerUpdateFeeds.CustomerUpdateFeed CUF ON P.PartyID = CUF.PartyID
	



/*
Electronic Addresses
*/

	UPDATE CUF
	SET [EmailAddress] =  ISNULL(AE.EmailAddress, NULL)
	FROM [$(AuditDB)].Audit.EmailAddresses AE
	INNER JOIN [$(SampleDB)].ContactMechanism.PartyContactMechanisms APC ON AE.ContactMechanismID  = APC.ContactMechanismID
	INNER JOIN CustomerUpdateFeeds.CustomerUpdateFeed CUF ON APC.PartyID = CUF.PartyID
	INNER JOIN 
	(
		SELECT CUF.PartyID, MAX(AE.AuditItemID) AS AuditItemID			--v1.42
		FROM CustomerUpdateFeeds.CustomerUpdateFeed CUF
		INNER JOIN [$(AuditDB)].Audit.PartyContactMechanisms APC ON CUF.PartyID = APC.PartyID
								AND APC.ContactMechanismID <> ISNULL(CUF.NEW_EmailAddress_ContactMechanismID, 0)-- WE DON'T WANT TO INCLUDE ANY PREVIOUS EMAILS THAT ARE THE SAME
		INNER JOIN [$(AuditDB)].Audit.EmailAddresses AE ON APC.ContactMechanismID = AE.ContactMechanismID
							AND APC.AuditItemID = AE.AuditItemID
		INNER JOIN [$(AuditDB)].dbo.AuditItems AI ON AI.AuditItemID = AE.AuditItemID
		INNER JOIN [$(AuditDB)].dbo.Files F ON AI.AuditID = F.AuditID
		AND F.FileTypeID <> 10
		AND CUF.EmailAddressUpdate_AuditItemID IS NOT NULL
		GROUP BY CUF.PartyID
	) AS E ON AE.AuditItemID = E.AuditItemID
	      AND CUF.PartyID = E.PartyID									--v1.42


/*
  Telephone Numbers
*/

	UPDATE
 	CustomerUpdateFeeds.CustomerUpdateFeed
	SET
	[HomeContactNumber] = CASE WHEN CMT.ContactMechanismTypeID  = 3 THEN  ISNULL (ATN.ContactNumber , NULL ) 
					ELSE NULL 
	END,
	[WorkContactNumber] =  CASE WHEN CMT.ContactMechanismTypeID  = 2 THEN ISNULL (ATN.ContactNumber , NULL ) 
					ELSE NULL 
	END,
	[MobileContactNumber]  = CASE WHEN CMT.ContactMechanismTypeID  = 4 THEN ISNULL (ATN.ContactNumber , NULL ) 
					ELSE NULL 
	END
	FROM 
	[$(AuditDB)].Audit.TelephoneNumbers ATN 
	INNER JOIN  [$(AuditDB)].Audit.PartyContactMechanisms APC ON ATN.ContactMechanismID  = APC.ContactMechanismID
		INNER JOIN [$(SampleDB)].ContactMechanism.ContactMechanisms C On ATN.ContactMechanismID = C.ContactMechanismID
		INNER JOIN [$(SampleDB)].ContactMechanism.ContactMechanismTypes CMT ON C.ContactMechanismTypeID = CMT.ContactMechanismTypeID
		INNER  JOIN CustomerUpdateFeeds.CustomerUpdateFeed CUF ON APC.PartyID = CUF.PartyID
		INNER JOIN 
		(
			SELECT MAX(ATN.AuditItemID) AS AuditItemID
			FROM CustomerUpdateFeeds.CustomerUpdateFeed CUF
			INNER JOIN  [$(AuditDB)].Audit.PartyContactMechanisms APC ON CUF.PartyID  = APC.PartyID
			INNER JOIN [$(AuditDB)].Audit.ContactMechanisms CMT ON APC.ContactMechanismID = CMT.ContactMechanismID
									AND APC.AuditItemID = APC.AuditItemID
			INNER JOIN [$(SampleDB)].ContactMechanism.ContactMechanismTypes Types ON CMT.ContactMechanismTypeID = Types.ContactMechanismTypeID
			INNER JOIN [$(AuditDB)].Audit.TelephoneNumbers ATN ON APC.AuditItemID = ATN.AuditItemID
			INNER JOIN [$(AuditDB)].dbo.AuditItems AI ON AI.AuditItemID = ATN.AuditItemID
			INNER JOIN [$(AuditDB)].dbo.Files F ON AI.AuditID = F.AuditID
			AND F.FileTypeID <> 10
			AND CUF.TelephoneUpdate_AuditItemID IS NOT NULL
			GROUP BY CUF.PartyID
		) AS T ON ATN.AuditItemID = T.AuditItemID

 

/*
 REGISTRATIONS
*/

	UPDATE
	CustomerUpdateFeeds.CustomerUpdateFeed
	SET
	[RegistrationNumber] = CASE WHEN LEN(AR.RegistrationNumber) > 2 THEN  ISNULL (AR.RegistrationNumber , NULL ) 
	ELSE NULL  END
	FROM CustomerUpdateFeeds.CustomerUpdateFeed CUF
	INNER JOIN  [$(AuditDB)].Audit.VehicleRegistrationEvents AVRE ON CUF.VehicleID = AVRE.VehicleID
	INNER JOIN (	
		SELECT 
			MAX(AVRE.AuditItemID) AS AuditItemID
		FROM  CustomerUpdateFeeds.CustomerUpdateFeed CUF
		INNER JOIN [$(AuditDB)].Audit.VehicleRegistrationEvents AVRE ON AVRE.VehicleID = CUF.VehicleID
		INNER JOIN [$(AuditDB)].dbo.AuditItems AI ON AI.AuditItemID = AVRE.AuditItemID
		INNER JOIN [$(AuditDB)].dbo.Files F ON AI.AuditID = F.AuditID
		AND F.FileTypeID <> 10
		AND CUF.RegistrationUpdate_AuditItemID IS NOT NULL			--CUF.TelephoneUpdate_AuditItemID IS NOT NULL	v1.14
		GROUP BY 
		CUF.PartyID
	) AS R ON AVRE.AuditItemID = R.AuditItemID
	INNER JOIN [$(SampleDB)].Vehicle.Registrations AR ON AR.RegistrationID = AVRE.RegistrationID   -- Modified to get FROM Sample not Sample_Audit DB

 
/*
 ADRESSES					-- v1.4 Modified AS running very slowly.  Now liveable but needs fixing proprerly.  
*/

		CREATE TABLE #MaxAudit 		-- Used table var instead of CTE AS Visual Studio AND don't have time to sort --v1.4 
			(
				PartyID int,
				AuditItemID bigint
			)
		
		INSERT INTO #MaxAudit
		SELECT														
			CUF.PartyID, 
			MAX(PA.AuditItemID) AS AuditItemID
		FROM  CustomerUpdateFeeds.CustomerUpdateFeed CUF
		INNER JOIN [$(AuditDB)].Audit.PartyContactMechanisms PCM ON CUF.PartyID = PCM.PartyID
		INNER JOIN [$(AuditDB)].Audit.PostalAddresses PA ON PCM.ContactMechanismID = PA.ContactMechanismID
		INNER JOIN [$(AuditDB)].dbo.AuditItems AI ON AI.AuditItemID = PA.AuditItemID
		INNER JOIN [$(AuditDB)].dbo.Files F ON AI.AuditID = F.AuditID 
					AND F.FileTypeID <> 10
		WHERE CUF.PostalAddressUpdate_AuditItemID IS NOT NULL
		GROUP BY CUF.PartyID	

	UPDATE CustomerUpdateFeeds.CustomerUpdateFeed
	SET 
		[AddressLine1] =  ISNULL (PA.BuildingName , NULL ) ,
		[AddressLine2] = SUBSTRING(LTRIM(COALESCE(PA.SubStreetNumber, '') + ' ' + PA.SubStreet), 0, 150),	-- v1.6
		[AddressLine3] = SUBSTRING(LTRIM(COALESCE(PA.StreetNumber, '') + ' ' + PA.Street), 0, 150),			-- v1.6
		[AddressLine4] = ISNULL (PA.SubLocality , NULL )  ,
		[AddressLine5] = ISNULL (PA.Locality , NULL )  ,
		[Town] = ISNULL ( PA.Town, NULL )  ,
		[Region] = ISNULL ( PA.Region , NULL )  ,
		[Country]  = ISNULL (C.CountryShortName, NULL ),
		[PostCode] = ISNULL (PA.PostCode, NULL )  
	FROM  CustomerUpdateFeeds.CustomerUpdateFeed CUF
	INNER JOIN #MaxAudit MA ON MA.PartyID = CUF.PartyID
	INNER JOIN [$(AuditDB)].Audit.PartyContactMechanisms APCM ON APCM.AuditItemID = MA.AuditItemID
	INNER JOIN [$(AuditDB)].Audit.PostalAddresses APA ON APCM.ContactMechanismID = APCM.ContactMechanismID  
	INNER JOIN [$(SampleDB)].ContactMechanism.PostalAddresses PA ON PA.ContactMechanismID = APCM.ContactMechanismID	
	INNER JOIN [$(SampleDB)].ContactMechanism.Countries C ON PA.CountryID = C.CountryID


/*
 DEALERS	
*/

	UPDATE
	CustomerUpdateFeeds.CustomerUpdateFeed
	SET 
	--[DealerCode] =  ISNULL ( JD.TransferDealerCode , NULL ),
	[DealerCode] =  ISNULL ( JD.[Dealer10DigitCode] , NULL ),	--V1.14
 	[DealerShortName] = ISNULL (JD.TransferDealer , NULL ),
	[PAGCode] = ISNULL ( JD.PAGCode , NULL ),					-- 1.12
	[Market] = CASE
			WHEN CUF.Market IS NULL THEN JD.Market
			ELSE CUF.Market
	END
	FROM
	CustomerUpdateFeeds.CustomerUpdateFeed CUF 
		INNER  JOIN [$(SampleDB)].Event.AutomotiveEventBasedInterviews AEBI ON CUF.CaseID  = AEBI.CaseID 
										AND CUF.PartyID = AEBI.PartyID
 		INNER JOIN [$(AuditDB)].Audit.EventPartyRoles AEPR ON AEBI.EventID = AEPR.EventID
 		INNER JOIN  [$(SampleDB)].dbo.DW_JLRCSPDealers JD ON AEPR.PartyID = JD.TransferPartyID
  								AND AEPR.RoleTypeID  = JD.OutletFunctionID	
		INNER JOIN 
		(
		SELECT 
			MAX(AEPR.AuditItemID) AS AuditItemID
			FROM  CustomerUpdateFeeds.CustomerUpdateFeed CUF
			INNER  JOIN [$(SampleDB)].Event.AutomotiveEventBasedInterviews AEBI ON CUF.CaseID  = AEBI.CaseID 
	 										AND CUF.PartyID = AEBI.PartyID
	  		INNER JOIN [$(AuditDB)].Audit.EventPartyRoles AEPR ON AEBI.EventID = AEPR.EventID
	  		INNER JOIN  [$(SampleDB)].dbo.DW_JLRCSPDealers JD ON AEPR.PartyID = JD.TransferPartyID
	   								AND AEPR.RoleTypeID  = JD.OutletFunctionID	
			INNER JOIN [$(AuditDB)].dbo.AuditItems AI ON AI.AuditItemID = AEPR.AuditItemID
			INNER JOIN [$(AuditDB)].dbo.Files F ON AI.AuditID = F.AuditID
			AND F.FileTypeID <> 10
			AND CUF.DealerUpdate_AuditItemID IS NOT NULL
			GROUP BY 
			CUF.PartyID
		) AS D ON D.AuditItemID = AEPR.AuditItemID

-- 	GO




	-- FOR CASES WHERE WE DON'T HAVE AN EMAIL UPDATE SET THE EmailValidityFlag TO 1
	UPDATE CustomerUpdateFeeds.CustomerUpdateFeed
	SET EmailValidityFLAG = 1
	WHERE EmailAddressUpdate_AuditItemID IS NULL

	-- FOR CASES WHERE WE DO HAVE AN EMAIL UPDATE SET THE EmailValidityFlag TO 2
	UPDATE CustomerUpdateFeeds.CustomerUpdateFeed
	SET EmailValidityFLAG = 2
	WHERE EmailAddressUpdate_AuditItemID IS NOT NULL

	-- CHECK IF THE NEW EMAIL SUPPLIED IS BLACKLISTED
	UPDATE CUF
	SET CUF.EmailValidityFLAG = 3
	FROM CustomerUpdateFeeds.CustomerUpdateFeed CUF
	INNER JOIN [$(SampleDB)].ContactMechanism.BlacklistContactMechanisms B ON B.ContactMechanismID = CUF.NEW_EmailAddress_ContactMechanismID


	-- UPDATE MANUFACTURER - V1.11
	UPDATE F SET F.Manufacturer = B.Brand
	FROM CustomerUpdateFeeds.CustomerUpdateFeed F
	LEFT JOIN [$(SampleDB)].Vehicle.Vehicles V ON F.VIN = V.VIN
	LEFT JOIN [$(SampleDB)].Vehicle.Models M ON V.ModelID = M.ModelID
	LEFT JOIN [$(SampleDB)].dbo.Brands B ON M.ManufacturerPartyID = B.ManufacturerPartyID

--update model description

Update CustomerUpdateFeeds.CustomerUpdateFeed
SET ModelDescription = meta.ModelDerivative
FROM [$(SampleDB)].Meta.CaseDetails meta
WHERE CustomerUpdateFeeds.CustomerUpdateFeed.VIN COLLATE database_default = meta.VIN COLLATE database_default;


----------------------------------------------------------------------------------------------------------------------------------
--- Update the Source AND Unique Identifier columns    // Chris Ross - 31-07-2012  //
----------------------------------------------------------------------------------------------------------------------------------


CREATE TABLE #PartyUniqueIDs  (
	
		PartyID				int, 
		Source				nvarchar(50),
		CustomerIdentifier  nvarchar(60),
		AuditItemID			bigint
	)


-- Build Unique ID table first
INSERT INTO #PartyUniqueIDs  (PartyID, Source, CustomerIdentifier, AuditItemID)
SELECT	DISTINCT cuf.PartyID,
		CASE WHEN (cr.CustomerIdentifier  LIKE '%[_]___' 
							AND f.FileName NOT LIKE '%SouthAfrica%'			-- v1.43
							AND f.FileName NOT LIKE '%ZA%'					-- v1.43
					) 
				OR f.FileName LIKE '%CUPID%' THEN 'Cupid' 
		WHEN cr.CustomerIdentifier LIKE '%_VISTA' 
				OR f.FileName LIKE '%France%' 
				OR f.FileName LIKE '%Brazil%' THEN 'Vista'
		WHEN f.FileName LIKE '%Roadside%' THEN 'Roadside'
		WHEN f.FileName LIKE '%SouthAfrica%' OR f.FileName LIKE '%ZA%'		-- v1.43
						THEN 'SouthAfrica'
		ELSE 'General' END AS Source,
		cr.CustomerIdentifier,
		cr.AuditItemID
FROM CustomerUpdateFeeds.CustomerUpdateFeed cuf
INNER JOIN [$(SampleDB)].Event.AutomotiveEventBasedInterviews aebi ON aebi.CaseID = cuf.CaseID
INNER JOIN [$(AuditDB)].Audit.CustomerRelationships cr ON cr.PartyIDFrom = aebi.PartyID 
INNER JOIN [$(AuditDB)].dbo.AuditItems ai ON ai.AuditItemID = cr.AuditItemID 
INNER JOIN [$(AuditDB)].dbo.Files f ON f.AuditID = ai.AuditID




SELECT P.*
INTO #CustomerIdentifiers
FROM #PartyUniqueIDs P
INNER JOIN ( SELECT PartyID, Source, MAX(AuditItemID) AS AuditItemID
			 FROM #PartyUniqueIDs GROUP BY PartyID, Source
			) MaxAuditIDs ON MaxAuditIDs.AuditItemID = P.AuditItemID ;
			

 
 --- UPDATE ---
 update cuf
 SET Source = CASE WHEN r.Requirement LIKE '%enprecis%' then 'Enprecis'
			WHEN ec.EventCategory = 'Sales' THEN 'CLP Sales' 
			WHEN ec.EventCategory = 'Service' THEN 'CLP Service'
			ELSE ec.EventCategory END,
	CustomerID_Cupid = (SELECT MAX(CustomerIdentifier) FROM #CustomerIdentifiers 
													WHERE PartyID = cuf.PartyID 
													AND Source = 'Cupid') ,
	CustomerID_Vista = REPLACE ((SELECT MAX(CustomerIdentifier) FROM #CustomerIdentifiers 
													WHERE PartyID = cuf.PartyID 
													AND Source = 'Vista'), '_VISTA', ''),
	CustomerID_Roadside = (SELECT MAX(CustomerIdentifier) FROM #CustomerIdentifiers 
													WHERE PartyID = cuf.PartyID 
													AND Source = 'Roadside') ,
	CustomerID_General = (SELECT MAX(CustomerIdentifier) FROM #CustomerIdentifiers 
													WHERE PartyID = cuf.PartyID 
													AND Source = 'General')								
FROM CustomerUpdateFeeds.CustomerUpdateFeed cuf
INNER JOIN [$(SampleDB)].Event.AutomotiveEventBasedInterviews aebi ON aebi.CaseID = cuf.CaseID
INNER JOIN [$(SampleDB)].Event.Events e ON e.EventID = aebi.EventID 
INNER JOIN [$(SampleDB)].Event.EventTypeCategories etc ON etc.EventTypeID = e.EventTypeID 
INNER JOIN [$(SampleDB)].Event.EventCategories ec ON ec.EventCategoryID = etc.EventCategoryID 
INNER JOIN [$(SampleDB)].Requirement.SelectionCases sc ON sc.CaseID = cuf.CaseID 
INNER JOIN [$(SampleDB)].Requirement.RequirementRollups rr1 ON rr1.RequirementIDMadeUpOf = sc.RequirementIDPartOf 
INNER JOIN [$(SampleDB)].Requirement.Requirements r ON r.RequirementID = rr1.RequirementIDPartOf 


-- For Roadside/CRC SET the Market using the country code.
UPDATE CUF
SET Market =  ISNULL(NULLIF(M.DealerTableEquivMarket,''),M.Market) --v1.5
FROM [CustomerUpdateFeeds].CustomerUpdateFeed CUF
INNER JOIN [$(SampleDB)].[ContactMechanism].PartyContactMechanisms PCM ON CUF.PartyID = PCM.PartyID
INNER JOIN [$(SampleDB)].[ContactMechanism].PostalAddresses PA ON PCM.ContactMechanismID = PA.ContactMechanismID
INNER JOIN [$(SampleDB)].[dbo].Markets M ON M.CountryID = PA.CountryID
WHERE Source IN ('CRC','Roadside')

--------------------------------------------------------------------------------------------------------------------------------------
-- V1.10 EXCLUDE BRAND/MARKET/QUESTIONNAIRE COMBINATION FROM CUSTOMER UPDATE REPPORTS
--------------------------------------------------------------------------------------------------------------------------------------

DELETE CUF
FROM [CustomerUpdateFeeds].CustomerUpdateFeed CUF
INNER JOIN [$(SampleDB)].Meta.CaseDetails CD ON CD.CaseID = CUF.CaseID
INNER JOIN [$(SampleDB)].[dbo].[Brands] B ON B.ManufacturerPartyID = CD.ManufacturerPartyID
INNER JOIN [$(SampleDB)].[dbo].[Markets] M ON M.CountryID = CD.CountryID
INNER JOIN [CustomerUpdateFeeds].[ExcludeFromCustomerUpdateFeed] ECF ON ECF.Brand = B.Brand
																				      AND ECF.Market = M.Market
																					  AND ECF.Questionnaire = CD.EventType
WHERE ECF.Exclude = 1


GO