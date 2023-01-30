CREATE PROCEDURE [RollbackSample].[uspRollbackSampleFile]
	(
		@BugNumber			INT,
		@AuditID			BIGINT,
		@Filename			VARCHAR(200),
		@OverrideSelectionOutputWarning BIT = 0
	)

AS

	--Rollback on Error
	SET XACT_ABORT On
	--Disable counts
	SET NOCOUNT ON

	DECLARE @ErrorNumber INT
	DECLARE @ErrorSeverity INT
	DECLARE @ErrorState INT
	DECLARE @ErrorLocation NVARCHAR(500)
	DECLARE @ErrorLine INT
	DECLARE @ErrorMessage NVARCHAR(2048)
	
BEGIN TRY


/*
	Purpose:	Roll back files which have been loaded in error, usually because of incorrect or corrupted data.
				It also deletes (where possible) the Cases associated with any events created.
	
	IMPORTANT:	The process does not actually "roll back" the loaded sample but invalidates it and removes 
				links to contact mechanisms, etc., so that incorrectly matched records are not linked any more 
				and future loaded records do not match incorrectly.
		
	Version			Date			Developer			Comment
	1.0				2017-11-10		Chris Ross			Bug 14196 - Original version
	1.1				2018-11-06		Chris Ledger		Bug 15056 - Add IAssistanceEvents
	1.2				2018-11-20		Chris Ross			Fixes to the mapping of suppressions (Email and Phone mapping inversely)
	1.3				2019-06-12		Chris Ross			Additional columns in CRM tables and missing columns in 
														SampleLogging table need clearing when rolling back Cases.   
	1.4				2019-11-15		Chris Ross			BUG 16755 - Remove references to ACCT_GERMAN_ONLY_NON_ACADEMIC and _CODE columns.
	1.5				2020-10-01		Chris Ledger		BUG 15372 - Fix Hard coded references to databases
*/

	---------------------------------------------------------------------------------------------------------
	-- First check all the Rollback Audit table column counts match the tables we are copying from.  This is
	-- to ensure that the Rollback Audit tables are kept in line with the tables they are auditting.
	---------------------------------------------------------------------------------------------------------
		
	IF (SELECT COUNT(COLUMN_NAME) FROM [$(AuditDB)].INFORMATION_SCHEMA.COLUMNS WHERE  TABLE_SCHEMA = 'RollbackSample' AND TABLE_NAME = 'SampleQualityAndSelectionLogging')
	<> (SELECT COUNT(COLUMN_NAME) FROM [$(WebsiteReporting)].INFORMATION_SCHEMA.COLUMNS WHERE  TABLE_SCHEMA = 'dbo' AND TABLE_NAME = 'SampleQualityAndSelectionLogging')
	RAISERROR ('ERROR (uspRollbackSampleFile) : RollbackSample.SampleQualityAndSelectionLogging out-of-sync with main Connexions table.  Please update RollbackSample table and procedure before continuing.',  16, 1) 
	
	IF (SELECT COUNT(COLUMN_NAME) FROM [$(AuditDB)].INFORMATION_SCHEMA.COLUMNS WHERE  TABLE_SCHEMA = 'RollbackSample' AND TABLE_NAME = 'Audit_Files')
	<> (SELECT COUNT(COLUMN_NAME) FROM [$(AuditDB)].INFORMATION_SCHEMA.COLUMNS WHERE  TABLE_SCHEMA = 'dbo' AND TABLE_NAME = 'Files')
	RAISERROR ('ERROR (uspRollbackSampleFile) : RollbackSample.Audit_Files out-of-sync with main Connexions tables.  Please fix in RollbackSample table and procedure before continuing.',  16, 1) 
	
	IF (SELECT COUNT(COLUMN_NAME) FROM [$(AuditDB)].INFORMATION_SCHEMA.COLUMNS WHERE  TABLE_SCHEMA = 'RollbackSample' AND TABLE_NAME = 'Audit_IncomingFiles')
	<> (SELECT COUNT(COLUMN_NAME) FROM [$(AuditDB)].INFORMATION_SCHEMA.COLUMNS WHERE  TABLE_SCHEMA = 'dbo' AND TABLE_NAME = 'IncomingFiles')
	RAISERROR ('ERROR (uspRollbackSampleFile) : RollbackSample.Audit_IncomingFiles out-of-sync with main Connexions tables.  Please fix in RollbackSample table and procedure before continuing.',  16, 1) 
	
	IF (SELECT COUNT(COLUMN_NAME) FROM [$(AuditDB)].INFORMATION_SCHEMA.COLUMNS WHERE  TABLE_SCHEMA = 'RollbackSample' AND TABLE_NAME = 'Events')-1  -- minus 1 to allow for additonal AuditID column.
	<> (SELECT COUNT(COLUMN_NAME) FROM [$(SampleDB)].INFORMATION_SCHEMA.COLUMNS WHERE  TABLE_SCHEMA = 'Event' AND TABLE_NAME = 'Events')
	RAISERROR ('ERROR (uspRollbackSampleFile) : RollbackSample.Events out-of-sync with main Connexions tables.  Please fix in RollbackSample table and procedure before continuing.',  16, 1) 
	
	IF (SELECT COUNT(COLUMN_NAME) FROM [$(AuditDB)].INFORMATION_SCHEMA.COLUMNS WHERE  TABLE_SCHEMA = 'RollbackSample' AND TABLE_NAME = 'Audit_Events')-1  -- minus 1 to allow for additonal AuditID column.
	<> (SELECT COUNT(COLUMN_NAME) FROM [$(AuditDB)].INFORMATION_SCHEMA.COLUMNS WHERE  TABLE_SCHEMA = 'Audit' AND TABLE_NAME = 'Events') 
	RAISERROR ('ERROR (uspRollbackSampleFile) : RollbackSample.Audit_Events out-of-sync with main Connexions tables.  Please fix in RollbackSample table and procedure before continuing.',  16, 1) 
	
	IF (SELECT COUNT(COLUMN_NAME) FROM [$(AuditDB)].INFORMATION_SCHEMA.COLUMNS WHERE  TABLE_SCHEMA = 'RollbackSample' AND TABLE_NAME = 'AutomotiveEventBasedInterviews')-1  -- minus 1 to allow for additonal AuditID column.
	<> (SELECT COUNT(COLUMN_NAME) FROM [$(SampleDB)].INFORMATION_SCHEMA.COLUMNS WHERE  TABLE_SCHEMA = 'Event' AND TABLE_NAME = 'AutomotiveEventBasedInterviews')
	RAISERROR ('ERROR (uspRollbackSampleFile) : RollbackSample.AutomotiveEventBasedInterviews out-of-sync with main Connexions tables.  Please fix in RollbackSample table and procedure before continuing.',  16, 1) 


	IF (SELECT COUNT(COLUMN_NAME) FROM [$(AuditDB)].INFORMATION_SCHEMA.COLUMNS WHERE  TABLE_SCHEMA = 'RollbackSample' AND TABLE_NAME = 'ContactPreferences')-1  -- minus 1 to allow for additonal AuditID column.
	<> (SELECT COUNT(COLUMN_NAME) FROM [$(SampleDB)].INFORMATION_SCHEMA.COLUMNS WHERE  TABLE_SCHEMA = 'Party' AND TABLE_NAME = 'ContactPreferences')
	RAISERROR ('ERROR (uspRollbackSampleFile) : RollbackSample.ContactPreferences out-of-sync with main Connexions tables.  Please fix in RollbackSample table and procedure before continuing.',  16, 1) 
	
	IF (SELECT COUNT(COLUMN_NAME) FROM [$(AuditDB)].INFORMATION_SCHEMA.COLUMNS WHERE  TABLE_SCHEMA = 'RollbackSample' AND TABLE_NAME = 'ContactPreferencesBysurvey')-1  -- minus 1 to allow for additonal AuditID column.
	<> (SELECT COUNT(COLUMN_NAME) FROM [$(SampleDB)].INFORMATION_SCHEMA.COLUMNS WHERE  TABLE_SCHEMA = 'Party' AND TABLE_NAME = 'ContactPreferencesBySurvey')
	RAISERROR ('ERROR (uspRollbackSampleFile) : RollbackSample.ContactPreferencesBySurvey out-of-sync with main Connexions tables.  Please fix in RollbackSample table and procedure before continuing.',  16, 1) 
	
	IF (SELECT COUNT(COLUMN_NAME) FROM [$(AuditDB)].INFORMATION_SCHEMA.COLUMNS WHERE  TABLE_SCHEMA = 'RollbackSample' AND TABLE_NAME = 'Audit_ContactPreferences')-1  -- minus 1 to allow for additonal AuditID column.
	<> (SELECT COUNT(COLUMN_NAME) FROM [$(AuditDB)].INFORMATION_SCHEMA.COLUMNS WHERE  TABLE_SCHEMA = 'Audit' AND TABLE_NAME = 'ContactPreferences')
	RAISERROR ('ERROR (uspRollbackSampleFile) : RollbackSample.Audit_ContactPreferences out-of-sync with main Connexions tables.  Please fix in RollbackSample table and procedure before continuing.',  16, 1) 

	IF (SELECT COUNT(COLUMN_NAME) FROM [$(AuditDB)].INFORMATION_SCHEMA.COLUMNS WHERE  TABLE_SCHEMA = 'RollbackSample' AND TABLE_NAME = 'Audit_ContactPreferencesBySurvey')-1  -- minus 1 to allow for additonal AuditID column.
	<> (SELECT COUNT(COLUMN_NAME) FROM [$(AuditDB)].INFORMATION_SCHEMA.COLUMNS WHERE  TABLE_SCHEMA = 'Audit' AND TABLE_NAME = 'ContactPreferencesBySurvey')
	RAISERROR ('ERROR (uspRollbackSampleFile) : RollbackSample.Audit_ContactPreferencesBySurvey out-of-sync with main Connexions tables.  Please fix in RollbackSample table and procedure before continuing.',  16, 1) 

	
	IF (SELECT COUNT(COLUMN_NAME) FROM [$(AuditDB)].INFORMATION_SCHEMA.COLUMNS WHERE  TABLE_SCHEMA = 'RollbackSample' AND TABLE_NAME = 'SelectionCases')-1  -- minus 1 to allow for additonal AuditID column.
	<> (SELECT COUNT(COLUMN_NAME) FROM [$(SampleDB)].INFORMATION_SCHEMA.COLUMNS WHERE  TABLE_SCHEMA = 'Requirement' AND TABLE_NAME = 'SelectionCases')
	RAISERROR ('ERROR (uspRollbackSampleFile) : RollbackSample.SelectionCases out-of-sync with main Connexions tables.  Please fix in RollbackSample table and procedure before continuing.',  16, 1) 
	
	IF (SELECT COUNT(COLUMN_NAME) FROM [$(AuditDB)].INFORMATION_SCHEMA.COLUMNS WHERE  TABLE_SCHEMA = 'RollbackSample' AND TABLE_NAME = 'CaseContactMechanismOutcomes')-1  -- minus 1 to allow for additonal AuditID column.
	<> (SELECT COUNT(COLUMN_NAME) FROM [$(SampleDB)].INFORMATION_SCHEMA.COLUMNS WHERE  TABLE_SCHEMA = 'Event' AND TABLE_NAME = 'CaseContactMechanismOutcomes')
	RAISERROR ('ERROR (uspRollbackSampleFile) : RollbackSample.CaseContactMechanismOutcomes out-of-sync with main Connexions tables.  Please fix in RollbackSample table and procedure before continuing.',  16, 1) 
	
	IF (SELECT COUNT(COLUMN_NAME) FROM [$(AuditDB)].INFORMATION_SCHEMA.COLUMNS WHERE  TABLE_SCHEMA = 'RollbackSample' AND TABLE_NAME = 'CaseContactMechanisms')-1  -- minus 1 to allow for additonal AuditID column.
	<> (SELECT COUNT(COLUMN_NAME) FROM [$(SampleDB)].INFORMATION_SCHEMA.COLUMNS WHERE  TABLE_SCHEMA = 'Event' AND TABLE_NAME = 'CaseContactMechanisms')
	RAISERROR ('ERROR (uspRollbackSampleFile) : RollbackSample.CaseContactMechanisms out-of-sync with main Connexions tables.  Please fix in RollbackSample table and procedure before continuing.',  16, 1) 
	
	IF (SELECT COUNT(COLUMN_NAME) FROM [$(AuditDB)].INFORMATION_SCHEMA.COLUMNS WHERE  TABLE_SCHEMA = 'RollbackSample' AND TABLE_NAME = 'CaseRejections')-1  -- minus 1 to allow for additonal AuditID column.
	<> (SELECT COUNT(COLUMN_NAME) FROM [$(SampleDB)].INFORMATION_SCHEMA.COLUMNS WHERE  TABLE_SCHEMA = 'Event' AND TABLE_NAME = 'CaseRejections')
	RAISERROR ('ERROR (uspRollbackSampleFile) : RollbackSample.CaseRejections out-of-sync with main Connexions tables.  Please fix in RollbackSample table and procedure before continuing.',  16, 1) 
	
	IF (SELECT COUNT(COLUMN_NAME) FROM [$(AuditDB)].INFORMATION_SCHEMA.COLUMNS WHERE  TABLE_SCHEMA = 'RollbackSample' AND TABLE_NAME = 'CaseOutput')-1  -- minus 1 to allow for additonal AuditID column.
	<> (SELECT COUNT(COLUMN_NAME) FROM [$(SampleDB)].INFORMATION_SCHEMA.COLUMNS WHERE  TABLE_SCHEMA = 'Event' AND TABLE_NAME = 'CaseOutput')
	RAISERROR ('ERROR (uspRollbackSampleFile) : RollbackSample.CaseOutput out-of-sync with main Connexions tables.  Please fix in RollbackSample table and procedure before continuing.',  16, 1) 
	
	IF (SELECT COUNT(COLUMN_NAME) FROM [$(AuditDB)].INFORMATION_SCHEMA.COLUMNS WHERE  TABLE_SCHEMA = 'RollbackSample' AND TABLE_NAME = 'Cases')-1  -- minus 1 to allow for additonal AuditID column.
	<> (SELECT COUNT(COLUMN_NAME) FROM [$(SampleDB)].INFORMATION_SCHEMA.COLUMNS WHERE  TABLE_SCHEMA = 'Event' AND TABLE_NAME = 'Cases')
	RAISERROR ('ERROR (uspRollbackSampleFile) : RollbackSample.Cases out-of-sync with main Connexions tables.  Please fix in RollbackSample table and procedure before continuing.',  16, 1) 
	
	IF (SELECT COUNT(COLUMN_NAME) FROM [$(AuditDB)].INFORMATION_SCHEMA.COLUMNS WHERE  TABLE_SCHEMA = 'RollbackSample' AND TABLE_NAME = 'CaseDetails')-1  -- minus 1 to allow for additonal AuditID column.
	<> (SELECT COUNT(COLUMN_NAME) FROM [$(SampleDB)].INFORMATION_SCHEMA.COLUMNS WHERE  TABLE_SCHEMA = 'Meta' AND TABLE_NAME = 'CaseDetails')
	RAISERROR ('ERROR (uspRollbackSampleFile) : RollbackSample.CaseDetails out-of-sync with main Connexions tables.  Please fix in RollbackSample table and procedure before continuing.',  16, 1) 
	
	IF (SELECT COUNT(COLUMN_NAME) FROM [$(AuditDB)].INFORMATION_SCHEMA.COLUMNS WHERE  TABLE_SCHEMA = 'RollbackSample' AND TABLE_NAME = 'Audit_CaseRejections')-1  -- minus 1 to allow for additonal AuditID column.
	<> (SELECT COUNT(COLUMN_NAME) FROM [$(AuditDB)].INFORMATION_SCHEMA.COLUMNS WHERE  TABLE_SCHEMA = 'Audit' AND TABLE_NAME = 'CaseRejections')
	RAISERROR ('ERROR (uspRollbackSampleFile) : RollbackSample.Audit_CaseRejections out-of-sync with main Connexions tables.  Please fix in RollbackSample table and procedure before continuing.',  16, 1) 
	
	IF (SELECT COUNT(COLUMN_NAME) FROM [$(AuditDB)].INFORMATION_SCHEMA.COLUMNS WHERE  TABLE_SCHEMA = 'RollbackSample' AND TABLE_NAME = 'SelectionRequirements')-1  -- minus 1 to allow for additonal AuditID column.
	<> (SELECT COUNT(COLUMN_NAME) FROM [$(SampleDB)].INFORMATION_SCHEMA.COLUMNS WHERE  TABLE_SCHEMA = 'Requirement' AND TABLE_NAME = 'SelectionRequirements')
	RAISERROR ('ERROR (uspRollbackSampleFile) : RollbackSample.SelectionRequirements out-of-sync with main Connexions tables.  Please fix in RollbackSample table and procedure before continuing.',  16, 1) 
	
	IF (SELECT COUNT(COLUMN_NAME) FROM [$(AuditDB)].INFORMATION_SCHEMA.COLUMNS WHERE  TABLE_SCHEMA = 'RollbackSample' AND TABLE_NAME = 'Requirements')-1  -- minus 1 to allow for additonal AuditID column.
	<> (SELECT COUNT(COLUMN_NAME) FROM [$(SampleDB)].INFORMATION_SCHEMA.COLUMNS WHERE  TABLE_SCHEMA = 'Requirement' AND TABLE_NAME = 'Requirements')
	RAISERROR ('ERROR (uspRollbackSampleFile) : RollbackSample.Requirements out-of-sync with main Connexions tables.  Please fix in RollbackSample table and procedure before continuing.',  16, 1) 
	
	IF (SELECT COUNT(COLUMN_NAME) FROM [$(AuditDB)].INFORMATION_SCHEMA.COLUMNS WHERE  TABLE_SCHEMA = 'RollbackSample' AND TABLE_NAME = 'VehiclePartyRoleEvents')-1  -- minus 1 to allow for additonal AuditID column.
	<> (SELECT COUNT(COLUMN_NAME) FROM [$(SampleDB)].INFORMATION_SCHEMA.COLUMNS WHERE  TABLE_SCHEMA = 'Vehicle' AND TABLE_NAME = 'VehiclePartyRoleEvents')
	RAISERROR ('ERROR (uspRollbackSampleFile) : RollbackSample.VehiclePartyRoleEvents out-of-sync with main Connexions tables.  Please fix in RollbackSample table and procedure before continuing.',  16, 1) 
	
	IF (SELECT COUNT(COLUMN_NAME) FROM [$(AuditDB)].INFORMATION_SCHEMA.COLUMNS WHERE  TABLE_SCHEMA = 'RollbackSample' AND TABLE_NAME = 'Audit_PartyContactMechanisms')-1  -- minus 1 to allow for additonal AuditID column.
	<> (SELECT COUNT(COLUMN_NAME) FROM [$(AuditDB)].INFORMATION_SCHEMA.COLUMNS WHERE  TABLE_SCHEMA = 'Audit' AND TABLE_NAME = 'PartyContactMechanisms')
	RAISERROR ('ERROR (uspRollbackSampleFile) : RollbackSample.Audit_PartyContactMechanisms out-of-sync with main Connexions tables.  Please fix in RollbackSample table and procedure before continuing.',  16, 1) 
	
	IF (SELECT COUNT(COLUMN_NAME) FROM [$(AuditDB)].INFORMATION_SCHEMA.COLUMNS WHERE  TABLE_SCHEMA = 'RollbackSample' AND TABLE_NAME = 'Audit_PartyContactMechanismPurposes')-1  -- minus 1 to allow for additonal AuditID column.
	<> (SELECT COUNT(COLUMN_NAME) FROM [$(AuditDB)].INFORMATION_SCHEMA.COLUMNS WHERE  TABLE_SCHEMA = 'Audit' AND TABLE_NAME = 'PartyContactMechanismPurposes')
	RAISERROR ('ERROR (uspRollbackSampleFile) : RollbackSample.Audit_PartyContactMechanismPurposes out-of-sync with main Connexions tables.  Please fix in RollbackSample table and procedure before continuing.',  16, 1) 
	
	IF (SELECT COUNT(COLUMN_NAME) FROM [$(AuditDB)].INFORMATION_SCHEMA.COLUMNS WHERE  TABLE_SCHEMA = 'RollbackSample' AND TABLE_NAME = 'PartyContactMechanisms')-1  -- minus 1 to allow for additonal AuditID column.
	<> (SELECT COUNT(COLUMN_NAME) FROM [$(SampleDB)].INFORMATION_SCHEMA.COLUMNS WHERE  TABLE_SCHEMA = 'ContactMechanism' AND TABLE_NAME = 'PartyContactMechanisms')
	RAISERROR ('ERROR (uspRollbackSampleFile) : RollbackSample.PartyContactMechanisms out-of-sync with main Connexions tables.  Please fix in RollbackSample table and procedure before continuing.',  16, 1) 
	
	IF (SELECT COUNT(COLUMN_NAME) FROM [$(AuditDB)].INFORMATION_SCHEMA.COLUMNS WHERE  TABLE_SCHEMA = 'RollbackSample' AND TABLE_NAME = 'PartyContactMechanismPurposes')-1  -- minus 1 to allow for additonal AuditID column.
	<> (SELECT COUNT(COLUMN_NAME) FROM [$(SampleDB)].INFORMATION_SCHEMA.COLUMNS WHERE  TABLE_SCHEMA = 'ContactMechanism' AND TABLE_NAME = 'PartyContactMechanismPurposes')
	RAISERROR ('ERROR (uspRollbackSampleFile) : RollbackSample.PartyContactMechanismPurposes out-of-sync with main Connexions tables.  Please fix in RollbackSample table and procedure before continuing.',  16, 1) 
	
	IF (SELECT COUNT(COLUMN_NAME) FROM [$(AuditDB)].INFORMATION_SCHEMA.COLUMNS WHERE  TABLE_SCHEMA = 'RollbackSample' AND TABLE_NAME = 'Audit_Organisations') 
	<> (SELECT COUNT(COLUMN_NAME) FROM [$(AuditDB)].INFORMATION_SCHEMA.COLUMNS WHERE  TABLE_SCHEMA = 'Audit' AND TABLE_NAME = 'Organisations')
	RAISERROR ('ERROR (uspRollbackSampleFile) : RollbackSample.Audit_Organisations out-of-sync with main Connexions tables.  Please fix in RollbackSample table and procedure before continuing.',  16, 1) 
	
	IF (SELECT COUNT(COLUMN_NAME) FROM [$(AuditDB)].INFORMATION_SCHEMA.COLUMNS WHERE  TABLE_SCHEMA = 'RollbackSample' AND TABLE_NAME = 'Audit_LegalOrganisations') 
	<> (SELECT COUNT(COLUMN_NAME) FROM [$(AuditDB)].INFORMATION_SCHEMA.COLUMNS WHERE  TABLE_SCHEMA = 'Audit' AND TABLE_NAME = 'LegalOrganisations')
	RAISERROR ('ERROR (uspRollbackSampleFile) : RollbackSample.Audit_LegalOrganisations out-of-sync with main Connexions tables.  Please fix in RollbackSample table and procedure before continuing.',  16, 1) 
	
	IF (SELECT COUNT(COLUMN_NAME) FROM [$(AuditDB)].INFORMATION_SCHEMA.COLUMNS WHERE  TABLE_SCHEMA = 'RollbackSample' AND TABLE_NAME = 'Organisations')
	<> (SELECT COUNT(COLUMN_NAME) FROM [$(SampleDB)].INFORMATION_SCHEMA.COLUMNS WHERE  TABLE_SCHEMA = 'Party' AND TABLE_NAME = 'Organisations')
	RAISERROR ('ERROR (uspRollbackSampleFile) : RollbackSample.Organisations out-of-sync with main Connexions tables.  Please fix in RollbackSample table and procedure before continuing.',  16, 1) 
	
	IF (SELECT COUNT(COLUMN_NAME) FROM [$(AuditDB)].INFORMATION_SCHEMA.COLUMNS WHERE  TABLE_SCHEMA = 'RollbackSample' AND TABLE_NAME = 'LegalOrganisations')
	<> (SELECT COUNT(COLUMN_NAME) FROM [$(SampleDB)].INFORMATION_SCHEMA.COLUMNS WHERE  TABLE_SCHEMA = 'Party' AND TABLE_NAME = 'LegalOrganisations')
	RAISERROR ('ERROR (uspRollbackSampleFile) : RollbackSample.LegalOrganisations out-of-sync with main Connexions tables.  Please fix in RollbackSample table and procedure before continuing.',  16, 1) 
	
	IF (SELECT COUNT(COLUMN_NAME) FROM [$(AuditDB)].INFORMATION_SCHEMA.COLUMNS WHERE  TABLE_SCHEMA = 'RollbackSample' AND TABLE_NAME = 'Audit_People')
	<> (SELECT COUNT(COLUMN_NAME) FROM [$(AuditDB)].INFORMATION_SCHEMA.COLUMNS WHERE  TABLE_SCHEMA = 'Audit' AND TABLE_NAME = 'People')
	RAISERROR ('ERROR (uspRollbackSampleFile) : RollbackSample.Audit_People out-of-sync with main Connexions tables.  Please fix in RollbackSample table and procedure before continuing.',  16, 1) 
	
	IF (SELECT COUNT(COLUMN_NAME) FROM [$(AuditDB)].INFORMATION_SCHEMA.COLUMNS WHERE  TABLE_SCHEMA = 'RollbackSample' AND TABLE_NAME = 'People')
	<> (SELECT COUNT(COLUMN_NAME) FROM [$(SampleDB)].INFORMATION_SCHEMA.COLUMNS WHERE  TABLE_SCHEMA = 'Party' AND TABLE_NAME = 'People')
	RAISERROR ('ERROR (uspRollbackSampleFile) : RollbackSample.People out-of-sync with main Connexions tables.  Please fix in RollbackSample table and procedure before continuing.',  16, 1) 
	
	IF (SELECT COUNT(COLUMN_NAME) FROM [$(AuditDB)].INFORMATION_SCHEMA.COLUMNS WHERE  TABLE_SCHEMA = 'RollbackSample' AND TABLE_NAME = 'Audit_CustomerRelationships')-1  -- minus 1 to allow for additonal AuditID column.
	<> (SELECT COUNT(COLUMN_NAME) FROM [$(AuditDB)].INFORMATION_SCHEMA.COLUMNS WHERE  TABLE_SCHEMA = 'Audit' AND TABLE_NAME = 'CustomerRelationships')
	RAISERROR ('ERROR (uspRollbackSampleFile) : RollbackSample.Audit_CustomerRelationships out-of-sync with main Connexions tables.  Please fix in RollbackSample table and procedure before continuing.',  16, 1) 
	
	IF (SELECT COUNT(COLUMN_NAME) FROM [$(AuditDB)].INFORMATION_SCHEMA.COLUMNS WHERE  TABLE_SCHEMA = 'RollbackSample' AND TABLE_NAME = 'CustomerRelationships')-1  -- minus 1 to allow for additonal AuditID column.
	<> (SELECT COUNT(COLUMN_NAME) FROM [$(SampleDB)].INFORMATION_SCHEMA.COLUMNS WHERE  TABLE_SCHEMA = 'Party' AND TABLE_NAME = 'CustomerRelationships')
	RAISERROR ('ERROR (uspRollbackSampleFile) : RollbackSample.CustomerRelationships out-of-sync with main Connexions tables.  Please fix in RollbackSample table and procedure before continuing.',  16, 1) 
	
	IF (SELECT COUNT(COLUMN_NAME) FROM [$(AuditDB)].INFORMATION_SCHEMA.COLUMNS WHERE  TABLE_SCHEMA = 'RollbackSample' AND TABLE_NAME = 'CRCEvents')
	<> (SELECT COUNT(COLUMN_NAME) FROM INFORMATION_SCHEMA.COLUMNS WHERE  TABLE_SCHEMA = 'CRC' AND TABLE_NAME = 'CRCEvents')
	RAISERROR ('ERROR (uspRollbackSampleFile) : RollbackSample.CRCEvents out-of-sync with main Connexions tables.  Please fix in RollbackSample table and procedure before continuing.',  16, 1) 
	
	IF (SELECT COUNT(COLUMN_NAME) FROM [$(AuditDB)].INFORMATION_SCHEMA.COLUMNS WHERE  TABLE_SCHEMA = 'RollbackSample' AND TABLE_NAME = 'RoadsideEvents')
	<> (SELECT COUNT(COLUMN_NAME) FROM INFORMATION_SCHEMA.COLUMNS WHERE  TABLE_SCHEMA = 'Roadside' AND TABLE_NAME = 'RoadsideEvents')
	RAISERROR ('ERROR (uspRollbackSampleFile) : RollbackSample.RoadsideEvents out-of-sync with main Connexions tables.  Please fix in RollbackSample table and procedure before continuing.',  16, 1) 
	
	IF (SELECT COUNT(COLUMN_NAME) FROM [$(AuditDB)].INFORMATION_SCHEMA.COLUMNS WHERE  TABLE_SCHEMA = 'RollbackSample' AND TABLE_NAME = 'WarrantyEvents')
	<> (SELECT COUNT(COLUMN_NAME) FROM INFORMATION_SCHEMA.COLUMNS WHERE  TABLE_SCHEMA = 'Warranty' AND TABLE_NAME = 'WarrantyEvents')
	RAISERROR ('ERROR (uspRollbackSampleFile) : RollbackSample.WarrantyEvents out-of-sync with main Connexions tables.  Please fix in RollbackSample table and procedure before continuing.',  16, 1) 
	
	IF (SELECT COUNT(COLUMN_NAME) FROM [$(AuditDB)].INFORMATION_SCHEMA.COLUMNS WHERE  TABLE_SCHEMA = 'RollbackSample' AND TABLE_NAME = 'Canada_Sales')
	<> (SELECT COUNT(COLUMN_NAME) FROM INFORMATION_SCHEMA.COLUMNS WHERE  TABLE_SCHEMA = 'Canada' AND TABLE_NAME = 'Sales')
	RAISERROR ('ERROR (uspRollbackSampleFile) : RollbackSample.Canada_Sales out-of-sync with main Connexions tables.  Please fix in RollbackSample table and procedure before continuing.',  16, 1) 

	IF (SELECT COUNT(COLUMN_NAME) FROM [$(AuditDB)].INFORMATION_SCHEMA.COLUMNS WHERE  TABLE_SCHEMA = 'RollbackSample' AND TABLE_NAME = 'Canada_Service')
	<> (SELECT COUNT(COLUMN_NAME) FROM INFORMATION_SCHEMA.COLUMNS WHERE  TABLE_SCHEMA = 'Canada' AND TABLE_NAME = 'Service')
	RAISERROR ('ERROR (uspRollbackSampleFile) : RollbackSample.Canada_Service out-of-sync with main Connexions tables.  Please fix in RollbackSample table and procedure before continuing.',  16, 1) 

	IF (SELECT COUNT(COLUMN_NAME) FROM [$(AuditDB)].INFORMATION_SCHEMA.COLUMNS WHERE  TABLE_SCHEMA = 'RollbackSample' AND TABLE_NAME = 'CRM_CRCCall_Call')
	<> (SELECT COUNT(COLUMN_NAME) FROM INFORMATION_SCHEMA.COLUMNS WHERE  TABLE_SCHEMA = 'CRM' AND TABLE_NAME = 'CRCCall_Call')
	RAISERROR ('ERROR (uspRollbackSampleFile) : RollbackSample.CRM_CRCCall_Call out-of-sync with main Connexions tables.  Please fix in RollbackSample table and procedure before continuing.',  16, 1) 
	
	IF (SELECT COUNT(COLUMN_NAME) FROM [$(AuditDB)].INFORMATION_SCHEMA.COLUMNS WHERE  TABLE_SCHEMA = 'RollbackSample' AND TABLE_NAME = 'CRM_DMS_Repair_Service')
	<> (SELECT COUNT(COLUMN_NAME) FROM INFORMATION_SCHEMA.COLUMNS WHERE  TABLE_SCHEMA = 'CRM' AND TABLE_NAME = 'DMS_Repair_Service')
	RAISERROR ('ERROR (uspRollbackSampleFile) : RollbackSample.CRM_DMS_Repair_Service out-of-sync with main Connexions tables.  Please fix in RollbackSample table and procedure before continuing.',  16, 1) 
	
	IF (SELECT COUNT(COLUMN_NAME) FROM [$(AuditDB)].INFORMATION_SCHEMA.COLUMNS WHERE  TABLE_SCHEMA = 'RollbackSample' AND TABLE_NAME = 'CRM_PreOwned')
	<> (SELECT COUNT(COLUMN_NAME) FROM INFORMATION_SCHEMA.COLUMNS WHERE  TABLE_SCHEMA = 'CRM' AND TABLE_NAME = 'PreOwned')
	RAISERROR ('ERROR (uspRollbackSampleFile) : RollbackSample.CRM_PreOwned out-of-sync with main Connexions tables.  Please fix in RollbackSample table and procedure before continuing.',  16, 1) 
	
	IF (SELECT COUNT(COLUMN_NAME) FROM [$(AuditDB)].INFORMATION_SCHEMA.COLUMNS WHERE  TABLE_SCHEMA = 'RollbackSample' AND TABLE_NAME = 'CRM_RoadsideIncident_Roadside')
	<> (SELECT COUNT(COLUMN_NAME) FROM INFORMATION_SCHEMA.COLUMNS WHERE  TABLE_SCHEMA = 'CRM' AND TABLE_NAME = 'RoadsideIncident_Roadside')
	RAISERROR ('ERROR (uspRollbackSampleFile) : RollbackSample.CRM_RoadsideIncident_Roadside out-of-sync with main Connexions tables.  Please fix in RollbackSample table and procedure before continuing.',  16, 1) 
	
	IF (SELECT COUNT(COLUMN_NAME) FROM [$(AuditDB)].INFORMATION_SCHEMA.COLUMNS WHERE  TABLE_SCHEMA = 'RollbackSample' AND TABLE_NAME = 'CRM_Vista_Contract_Sales')
	<> (SELECT COUNT(COLUMN_NAME) FROM INFORMATION_SCHEMA.COLUMNS WHERE  TABLE_SCHEMA = 'CRM' AND TABLE_NAME = 'Vista_Contract_Sales')
	RAISERROR ('ERROR (uspRollbackSampleFile) : RollbackSample.CRM_Vista_Contract_Sales out-of-sync with main Connexions tables.  Please fix in RollbackSample table and procedure before continuing.',  16, 1) 

	IF (SELECT COUNT(COLUMN_NAME) FROM [$(AuditDB)].INFORMATION_SCHEMA.COLUMNS WHERE  TABLE_SCHEMA = 'RollbackSample' AND TABLE_NAME = 'IAssistanceEvents')
	<> (SELECT COUNT(COLUMN_NAME) FROM INFORMATION_SCHEMA.COLUMNS WHERE  TABLE_SCHEMA = 'IAssistance' AND TABLE_NAME = 'IAssistanceEvents')
	RAISERROR ('ERROR (uspRollbackSampleFile) : RollbackSample.IAssistanceEvents out-of-sync with main Connexions tables.  Please fix in RollbackSample table and procedure before continuing.',  16, 1) 
	
	

	---------------------------------------------------------------------------------------------------------
	-- Check required parameters have been supplied correctly
	---------------------------------------------------------------------------------------------------------

	IF	@BugNumber		IS NULL
	RAISERROR ('ERROR (uspRollbackSampleFile) : @BugNumber parameter has not been supplied',
					16, -- Severity
					1  -- State 
				) 

	IF	@AuditID		IS NULL
	RAISERROR ('ERROR (uspRollbackSampleFile) : @AuditID parameter has not been supplied',
					16, -- Severity
					1  -- State 
				) 

	IF	@Filename		IS NULL
	RAISERROR ('ERROR (uspRollbackSampleFile) : @Filename parameter has not been supplied',
					16, -- Severity
					1  -- State 
				) 

	
	---------------------------------------------------------------------------------------------------------
	-- Check Filename and AuditID specified match.  This performs a sort of validation to ensure the user
	-- does not accidentally rollback a file when they shouldn't have.
	---------------------------------------------------------------------------------------------------------

	IF @Filename <> (SELECT [Filename] FROM [$(AuditDB)].dbo.Files f WHERE f.AuditID = @AuditID)
	RAISERROR ('ERROR (uspRollbackSampleFile) : The filename does not match the AuditID.',
					16, -- Severity
					1  -- State 
				) 

	---------------------------------------------------------------------------------------------------------
	-- Check the file is actually a "sample" file.
	---------------------------------------------------------------------------------------------------------

	IF (SELECT FileTypeID FROM [$(AuditDB)].dbo.Files f WHERE f.AuditID = @AuditID)
	  <> (SELECT FileTypeID FROM [$(AuditDB)].dbo.FileTypes WHERE FileType = 'Sample')
	RAISERROR ('ERROR (uspRollbackSampleFile) : The file is not of type "Sample".',
					16, -- Severity
					1  -- State 
				) 

	---------------------------------------------------------------------------------------------------------
	-- Check File is in Sample Logging table.  The logging goes back to April 2012 and we would not expect to
	-- be rolling back a file prior to that.
	---------------------------------------------------------------------------------------------------------

	IF 0 = (SELECT COUNT(*) FROM [$(WebsiteReporting)].dbo.SampleQualityAndSelectionLogging WHERE AuditID = @AuditID)
	RAISERROR ('ERROR (uspRollbackSampleFile) : Cannot execute. No records exist for this file in the SampleQualityAndSelectionLogging table.',
					16, -- Severity
					1  -- State 
				) 


	---------------------------------------------------------------------------------------------------------
	-- Check this file is not China Sales With Responses.
	---------------------------------------------------------------------------------------------------------

	IF 1 = (SELECT TOP 1 1 FROM China.Sales_WithResponses WHERE AuditID = @AuditID)
	RAISERROR ('ERROR (uspRollbackSampleFile) : This is a China Sales with Responses file and is not currently covered by the Rollback procedure',
					16, -- Severity
					1  -- State 
				) 


	---------------------------------------------------------------------------------------------------------
	-- Check this file is not China Service With Responses
	---------------------------------------------------------------------------------------------------------

	IF 1 = (SELECT TOP 1 1 FROM China.Service_WithResponses WHERE AuditID = @AuditID)
	RAISERROR ('ERROR (uspRollbackSampleFile) : This is a China Service with Responses file and is not currently covered by the Rollback procedure.',
					16, -- Severity
					1  -- State 
				) 


	---------------------------------------------------------------------------------------------------------
	-- Check this file has not already been "rolled back".  Error if it has.
	---------------------------------------------------------------------------------------------------------

	IF 0 < (SELECT COUNT(*) FROM RollbackSample.RollbackHeader WHERE AuditID = @AuditID)
	RAISERROR ('ERROR (uspRollbackSampleFile) : This Sample File has already been rolled back.',
					16, -- Severity
					1  -- State 
				) 


	---------------------------------------------------------------------------------------------------------
	-- Get the Events and Cases information asssociated with the file we are rolling back.
	---------------------------------------------------------------------------------------------------------

	IF OBJECT_ID('tempdb..#FileRowsInfo') IS NOT NULL
		DROP TABLE #FileRowsInfo


	CREATE TABLE #FileRowsInfo
		(
			AuditID				BIGINT, 
			FileRowCount		BIGINT, 
			AuditItemID			BIGINT, 
			EventID				BIGINT, 
			CaseID				BIGINT, 
			ClosureDate			DATETIME2, 
			RequirementID		BIGINT, 
			Requirement			VARCHAR(255), 
			SelectionStatusTypeID INT
		)

	INSERT INTO #FileRowsInfo (AuditID, FileRowCount, AuditItemID, EventID, CaseID, ClosureDate, RequirementID, Requirement, SelectionStatusTypeID)
	SELECT f.AuditID, f.FileRowCount, ai.AuditItemID, ae.EventID, c.CaseID, c.ClosureDate, r.RequirementID, r.Requirement, sr.SelectionStatusTypeID
	FROM [$(AuditDB)].dbo.Files f
	LEFT JOIN [$(AuditDB)].dbo.AuditItems ai ON ai.AuditID = f.AuditID
	LEFT JOIN [$(AuditDB)].Audit.Events ae ON ae.AuditItemID = ai.AuditItemID
	LEFT JOIN [$(SampleDB)].Event.AutomotiveEventBasedInterviews aebi ON aebi.EventID = ae.EventID
	LEFT JOIN [$(SampleDB)].Requirement.SelectionCases sc ON sc.CaseID = aebi.CaseID
	LEFT JOIN [$(SampleDB)].Requirement.SelectionRequirements sr ON sr.RequirementID = sc.RequirementIDPartOf
	LEFT JOIN [$(SampleDB)].Requirement.Requirements r ON r.RequirementID = sc.RequirementIDPartOf
	LEFT JOIN [$(SampleDB)].Event.Cases c ON c.CaseID = sc.CaseID
	WHERE f.AuditID = @AuditID



	-----------------------------------------------------------------------------------------------------------------------------
	--  Run checks to see if Cases have been output or responded to, etc
	-----------------------------------------------------------------------------------------------------------------------------

			--------------------------------------------------------------------------------------------------------------
			-- Check that we do not have any non-CLP selections associated with this file. This should never happen as 
			-- we should identify incorrectly loaded files in a timely manner.  However, we do need to check for it and 
			-- if it is has occurred then it will need to be investigated and perhaps manually adjusted or rolled back.
			--------------------------------------------------------------------------------------------------------------

			IF 0 < (SELECT COUNT(*) FROM #FileRowsInfo FRI
					WHERE FRI.CaseID IS NOT NULL
					AND NOT EXISTS (SELECT rr.RequirementIDMadeUpOf 
									FROM [$(SampleDB)].Requirement.RequirementRollups rr 
									INNER JOIN [$(SampleDB)].Requirement.RequirementRollups rr2 ON rr2.RequirementIDMadeUpOf  = rr.RequirementIDPartOf
									INNER JOIN [$(SampleDB)].dbo.Questionnaires pq ON pq.ProgramRequirementID = rr2.RequirementIDPartOf  -- Link to valid Program Requirement IDs
									WHERE rr.RequirementIDMadeUpOf = FRI.RequirementID)
					)
			RAISERROR ('ERROR (uspRollbackSampleFile) : Records in this Sample File have been selected for non-CLP Selections.  This requires investigation and may possibly require manual correction.',
						 16, -- Severity
						 1  -- State 
						) 
					
					
			--------------------------------------------------------------------------------------------------------------
			-- Check none of the Cases have Responses and there are no CRM Response records received.
			-- Error if there are.  In this instance the Cases would need to be manually removed from the website and 
			-- responses and ClosureDates reset it Connexions.  The file reversal would then work.
			--------------------------------------------------------------------------------------------------------------

			IF 0 < (SELECT COUNT(*) FROM #FileRowsInfo FRI WHERE FRI.ClosureDate IS NOT NULL)
			OR 0 < (SELECT COUNT(*) FROM #FileRowsInfo FRI
					INNER JOIN [$(SampleDB)].Event.CaseCRM CRM ON CRM.CaseID = FRI.CaseID
					WHERE FRI.CaseID IS NOT NULL)
			RAISERROR ('ERROR (uspRollbackSampleFile) : Records in the Sample File have responses.  Confirm action with exec''s and then, if required, manually remove the responses and reset the ClosureDates before proceeding.',
						 16, -- Severity
						 1  -- State 
						) 



					
			--------------------------------------------------------------------------------------------------------------
			-- Check that the Logging table rows associated with the Cases are not spread across mutiple files (AuditIDs).
			-- In other words we do not have Cases that are for events that we have received in mutiple files. If this is
			-- the case we would need to look at fixing this manually as we cannot be sure whether the CaseID is still valid
			-- once we roll back one of the files i.e. we do not know if the row we are deleting caused the Event to be valid 
			-- or not.  In some instances the Case would still be valid and can stay and, in others, not.
			--------------------------------------------------------------------------------------------------------------

					
			IF 0 < (SELECT COUNT(DISTINCT MatchedODSEventID) 
					FROM #FileRowsInfo FRI 
					inner join [$(WebsiteReporting)].dbo.SampleQualityAndSelectionLogging sq ON sq.MatchedODSEventID = FRI.EventID AND sq.AuditID <> FRI.AuditID
					WHERE FRI.CaseID IS NOT NULL)
			RAISERROR ('ERROR (uspRollbackSampleFile) : Cases in the Sample File are for events which have also been supplied in other files.  Cannot automatically determine whether to rollback cases or not.  Requires manual intervention.',
						 16, -- Severity
						 1  -- State 
						) 






			--------------------------------------------------------------------------------------------------------------
			-- Check none of the Organisations or People have been merged. 
			-- Error if they are and remind that we need to alter this procedure to handle Merge functionality 
			--------------------------------------------------------------------------------------------------------------

			IF 0 < (SELECT COUNT(*) 
					FROM #FileRowsInfo FRI 
					INNER JOIN [$(AuditDB)].Audit.Organisations ao ON ao.AuditItemID = FRI.AuditItemID
					INNER JOIN [$(SampleDB)].Party.Organisations o ON o.PartyID = ao.PartyID
					WHERE o.MergedDate IS NOT NULL)
			RAISERROR ('ERROR (uspRollbackSampleFile) : Organisation records in the Sample File have been merged. Merged records are not covered by this procedure.',
						 16, -- Severity
						 1  -- State 
						) 

			IF 0 < (SELECT COUNT(*) 
					FROM #FileRowsInfo FRI 
					INNER JOIN [$(AuditDB)].Audit.People ap ON ap.AuditItemID = FRI.AuditItemID
					INNER JOIN [$(SampleDB)].Party.People p ON p.PartyID = ap.PartyID
					WHERE p.MergedDate IS NOT NULL)
			RAISERROR ('ERROR (uspRollbackSampleFile) : People records in the Sample File have been merged. Merged records are not covered by this procedure.',
						 16, -- Severity
						 1  -- State 
						) 


			--------------------------------------------------------------------------------------------------------------
			-- 	Check none of the associated Selections have been output.
			-- 	As the selections may have been output but not actually been sent there is the possibility to override this
			-- 	by setting the OverrideSelectionOutputCheck to TRUE.
			--------------------------------------------------------------------------------------------------------------
			
			IF @OverrideSelectionOutputWarning = 0 
			AND 0 < (SELECT COUNT(*) FROM #FileRowsInfo FRI 
				  	INNER JOIN [$(AuditDB)].Audit.SelectionOutput aso ON aso.CaseID = FRI.CaseID
					WHERE FRI.CaseID IS NOT NULL )
			RAISERROR ('WARNING (uspRollbackSampleFile) : Some records in this file have been output.  Please investigate, confirm with exec''s and then use the "override" parameter, if required.',
						 16, -- Severity
						 1  -- State 
						) 




			--------------------------------------------------------------------------------------------------------------
			-- Check for selection allocations as they are not covered by this procedure.  This is because the allocations 
			-- need to be reviewed and possibly manually adjusted. But as we do not run allocations for normal CLP 
			-- selections this should not be an issue.
			--------------------------------------------------------------------------------------------------------------
			
			IF 0 < (SELECT COUNT(*) 
					FROM #FileRowsInfo FRI 
					INNER JOIN [$(SampleDB)].Requirement.SelectionAllocations sa ON sa.RequirementIDPartOf = FRI.RequirementID
					WHERE TotalActual IS NOT NULL)
			RAISERROR ('ERROR (uspRollbackSampleFile) : Associated selection allocations found.  This procedure does not cover selection allocations. They will need to be manually adjusted or the procedure modified.',
						 16, -- Severity
						 1  -- State 
						) 

			--------------------------------------------------------------------------------------------------------------
			-- Create the temporary tables required for the Contact Preferences rollback PLUS check that all the 
			-- market lookups have worked.  Error if not.
			--------------------------------------------------------------------------------------------------------------

	
			IF OBJECT_ID('tempdb..#ContactPreferencePartiesBySurvey') IS NOT NULL
				DROP TABLE #ContactPreferencePartiesBySurvey

			CREATE TABLE #ContactPreferencePartiesBySurvey
				(
					PartyID						BIGINT,
					Market						VARCHAR(200),
					MarketID					INT,
					CountryID					INT,
					ContactPreferencesPersist	BIT,
					EventCategoryID				INT
				)

			INSERT INTO #ContactPreferencePartiesBySurvey (PartyID, Market, MarketID, CountryID, ContactPreferencesPersist, EventCategoryID)
			SELECT DISTINCT acpbs.PartyID, sq.Market, m.MarketID, m.CountryID, m.ContactPreferencesPersist, acpbs.EventCategoryID
			FROM #FileRowsInfo FRI
			INNER JOIN [$(AuditDB)].Audit.ContactPreferencesBySurvey acpbs ON acpbs.AuditItemID = FRI.AuditItemID
			LEFT JOIN [$(WebsiteReporting)].dbo.SampleQualityAndSelectionLogging sq ON sq.AuditItemID = FRI.AuditItemID
			LEFT JOIN [$(SampleDB)].dbo.Markets m ON m.Market = sq.Market


			-- Now check all the Market info populated correctly
			IF 0 < (SELECT COUNT(*) 
					FROM #ContactPreferencePartiesBySurvey    
					WHERE CountryID IS NULL)
			RAISERROR ('ERROR (uspRollbackSampleFile) : Not all dbo.Market records found for Sample Logging table Market names when referenced for ContactPreference update.  Please investigate.',
						 16, -- Severity
						 1  -- State 
						) 
		
		
			-- All being well, roll up into the #ContactPreferenceParties table
			IF OBJECT_ID('tempdb..#ContactPreferenceParties') IS NOT NULL
				DROP TABLE #ContactPreferenceParties

			CREATE TABLE #ContactPreferenceParties
				(
					PartyID						BIGINT,
					Market						VARCHAR(200),
					CountryID					INT,
					ContactPreferencesPersist	BIT
				)

			INSERT INTO #ContactPreferenceParties (PartyID, Market, CountryID, ContactPreferencesPersist)
			SELECT DISTINCT PartyID, Market, CountryID, ContactPreferencesPersist
			FROM #ContactPreferencePartiesBySurvey





BEGIN TRAN 


	---------------------------------------------------------------------------------------------------------
	-- Set up rollback variables
	---------------------------------------------------------------------------------------------------------

	DECLARE @BugNumberText		VARCHAR(10),
			@SuffixText			VARCHAR(200),
			@UpdateDate			DATETIME,
			@MaxAuditID			BIGINT,
			@MaxAuditITemID		BIGINT,
			@Comments			VARCHAR(255)			
			
	SET @UpdateDate = GETDATE()

	SET @BugNumberText = CAST(@BugNumber AS VARCHAR(10))
	SET @SuffixText = '_BUG' + @BugNumberText + '_RollbackSampleProc'
	SET @Comments = 'Flagged as "rolled back" by uspRollbackSampleFile as part of BUG ' + @BugNumberText + ' on ' + CONVERT(VARCHAR(20), GETDATE(), 120)



	-----------------------------------------------------------------------------------------------------------------------------
	--  Save logging table entries here as this table is updated in more than one place below			
	-----------------------------------------------------------------------------------------------------------------------------

	-- Save File info to Rollback Audit tables
	INSERT INTO [$(AuditDB)].RollbackSample.SampleQualityAndSelectionLogging (LoadedDate, AuditID, AuditItemID, PhysicalFileRow, ManufacturerID, SampleSupplierPartyID, MatchedODSPartyID, PersonParentAuditItemID, MatchedODSPersonID, LanguageID, PartySuppression, OrganisationParentAuditItemID, MatchedODSOrganisationID, AddressParentAuditItemID, MatchedODSAddressID, CountryID, PostalSuppression, AddressChecksum, MatchedODSTelID, MatchedODSPrivTelID, MatchedODSBusTelID, MatchedODSMobileTelID, MatchedODSPrivMobileTelID, MatchedODSEmailAddressID, MatchedODSPrivEmailAddressID, EmailSuppression, VehicleParentAuditItemID, MatchedODSVehicleID, ODSRegistrationID, MatchedODSModelID, OwnershipCycle, MatchedODSEventID, ODSEventTypeID, SaleDateOrig, SaleDate, ServiceDateOrig, ServiceDate, InvoiceDateOrig, InvoiceDate, WarrantyID, SalesDealerCodeOriginatorPartyID, SalesDealerCode, SalesDealerID, ServiceDealerCodeOriginatorPartyID, ServiceDealerCode, ServiceDealerID, RoadsideNetworkOriginatorPartyID, RoadsideNetworkCode, RoadsideNetworkPartyID, RoadsideDate, CRCCentreOriginatorPartyID, CRCCentreCode, CRCCentrePartyID, CRCDate, Brand, Market, Questionnaire, QuestionnaireRequirementID, StartDays, EndDays, SuppliedName, SuppliedAddress, SuppliedPhoneNumber, SuppliedMobilePhone, SuppliedEmail, SuppliedVehicle, SuppliedRegistration, SuppliedEventDate, EventDateOutOfDate, EventNonSolicitation, PartyNonSolicitation, UnmatchedModel, UncodedDealer, EventAlreadySelected, NonLatestEvent, InvalidOwnershipCycle, RecontactPeriod, InvalidVehicleRole, CrossBorderAddress, CrossBorderDealer, ExclusionListMatch, InvalidEmailAddress, BarredEmailAddress, BarredDomain, CaseID, SampleRowProcessed, SampleRowProcessedDate, WrongEventType, MissingStreet, MissingPostcode, MissingEmail, MissingTelephone, MissingStreetAndEmail, MissingTelephoneAndEmail, InvalidModel, InvalidVariant, MissingMobilePhone, MissingMobilePhoneAndEmail, MissingPartyName, MissingLanguage, CaseIDPrevious, RelativeRecontactPeriod, InvalidManufacturer, InternalDealer, EventDateTooYoung, InvalidRoleType, InvalidSaleType, InvalidAFRLCode, SuppliedAFRLCode, DealerExclusionListMatch, PhoneSuppression, LostLeadDate, ContactPreferencesSuppression, NotInQuota, ContactPreferencesPartySuppress, ContactPreferencesEmailSuppress, ContactPreferencesPhoneSuppress, ContactPreferencesPostalSuppress, DealerPilotOutputFiltered, InvalidCRMSaleType, MissingLostLeadAgency, BodyshopEventDateOrig, BodyshopEventDate, BodyshopDealerCode, BodyshopDealerID, BodyshopDealerCodeOriginatorPartyID, PDIFlagSet, ContactPreferencesUnsubscribed, SelectionOrganisationID, SelectionPostalID, SelectionEmailID, SelectionPhoneID, SelectionLandlineID, SelectionMobileID, NonSelectableWarrantyEvent, IAssistanceCentreOriginatorPartyID, IAssistanceCentreCode, IAssistanceCentrePartyID, IAssistanceDate, InvalidDateOfLastContact)  -- v1.3
	SELECT LoadedDate, AuditID, AuditItemID, PhysicalFileRow, ManufacturerID, SampleSupplierPartyID, MatchedODSPartyID, PersonParentAuditItemID, MatchedODSPersonID, LanguageID, PartySuppression, OrganisationParentAuditItemID, MatchedODSOrganisationID, AddressParentAuditItemID, MatchedODSAddressID, CountryID, PostalSuppression, AddressChecksum, MatchedODSTelID, MatchedODSPrivTelID, MatchedODSBusTelID, MatchedODSMobileTelID, MatchedODSPrivMobileTelID, MatchedODSEmailAddressID, MatchedODSPrivEmailAddressID, EmailSuppression, VehicleParentAuditItemID, MatchedODSVehicleID, ODSRegistrationID, MatchedODSModelID, OwnershipCycle, MatchedODSEventID, ODSEventTypeID, SaleDateOrig, SaleDate, ServiceDateOrig, ServiceDate, InvoiceDateOrig, InvoiceDate, WarrantyID, SalesDealerCodeOriginatorPartyID, SalesDealerCode, SalesDealerID, ServiceDealerCodeOriginatorPartyID, ServiceDealerCode, ServiceDealerID, RoadsideNetworkOriginatorPartyID, RoadsideNetworkCode, RoadsideNetworkPartyID, RoadsideDate, CRCCentreOriginatorPartyID, CRCCentreCode, CRCCentrePartyID, CRCDate, Brand, Market, Questionnaire, QuestionnaireRequirementID, StartDays, EndDays, SuppliedName, SuppliedAddress, SuppliedPhoneNumber, SuppliedMobilePhone, SuppliedEmail, SuppliedVehicle, SuppliedRegistration, SuppliedEventDate, EventDateOutOfDate, EventNonSolicitation, PartyNonSolicitation, UnmatchedModel, UncodedDealer, EventAlreadySelected, NonLatestEvent, InvalidOwnershipCycle, RecontactPeriod, InvalidVehicleRole, CrossBorderAddress, CrossBorderDealer, ExclusionListMatch, InvalidEmailAddress, BarredEmailAddress, BarredDomain, CaseID, SampleRowProcessed, SampleRowProcessedDate, WrongEventType, MissingStreet, MissingPostcode, MissingEmail, MissingTelephone, MissingStreetAndEmail, MissingTelephoneAndEmail, InvalidModel, InvalidVariant, MissingMobilePhone, MissingMobilePhoneAndEmail, MissingPartyName, MissingLanguage, CaseIDPrevious, RelativeRecontactPeriod, InvalidManufacturer, InternalDealer, EventDateTooYoung, InvalidRoleType, InvalidSaleType, InvalidAFRLCode, SuppliedAFRLCode, DealerExclusionListMatch, PhoneSuppression, LostLeadDate, ContactPreferencesSuppression, NotInQuota, ContactPreferencesPartySuppress, ContactPreferencesEmailSuppress, ContactPreferencesPhoneSuppress, ContactPreferencesPostalSuppress, DealerPilotOutputFiltered, InvalidCRMSaleType, MissingLostLeadAgency, BodyshopEventDateOrig, BodyshopEventDate, BodyshopDealerCode, BodyshopDealerID, BodyshopDealerCodeOriginatorPartyID, PDIFlagSet, ContactPreferencesUnsubscribed, SelectionOrganisationID, SelectionPostalID, SelectionEmailID, SelectionPhoneID, SelectionLandlineID, SelectionMobileID, NonSelectableWarrantyEvent, IAssistanceCentreOriginatorPartyID, IAssistanceCentreCode, IAssistanceCentrePartyID, IAssistanceDate, InvalidDateOfLastContact  -- v1.3
	FROM [$(WebsiteReporting)].dbo.SampleQualityAndSelectionLogging sq
	WHERE sq.AuditID = @AuditID



	-----------------------------------------------------------------------------------------------------------------------------
	--  Change file details (includes load date so records do not get picked up for website or reporting)
	-----------------------------------------------------------------------------------------------------------------------------

	-- Save File info to Rollback Audit tables
	INSERT INTO [$(AuditDB)].RollbackSample.Audit_Files (AuditID, FileTypeID, FileName, FileRowCount, ActionDate)
	SELECT AuditID, FileTypeID, FileName, FileRowCount, ActionDate
	FROM [$(AuditDB)].dbo.Files f
	WHERE f.AuditID = @AuditID
	
	INSERT INTO [$(AuditDB)].RollbackSample.Audit_IncomingFiles (AuditID, FileChecksum, LoadSuccess, FileLoadFailureID)
	SELECT AuditID, FileChecksum, LoadSuccess, FileLoadFailureID
	FROM [$(AuditDB)].dbo.IncomingFiles f
	WHERE f.AuditID = @AuditID


		-- Update ActionDate in Audit.dbo.Files
	UPDATE	[$(AuditDB)].dbo.Files 
	SET		ActionDate = '1900-01-01',
			Filename = Filename + @SuffixText	
	WHERE	AuditID = @AuditID


	-- Update ActionDate in Audit.dbo.IncomingFiles
	UPDATE	[$(AuditDB)].dbo.IncomingFiles 
	SET		FileChecksum = 0
	WHERE	AuditID = @AuditID


	-- Reset LoadedDate in logging table
	UPDATE [$(WebsiteReporting)].dbo.SampleQualityAndSelectionLogging
	SET LoadedDate = '1900-01-01'
	WHERE AuditID = @AuditID



	-----------------------------------------------------------------------------------------------------------------------------
	--  Change Event Dates to '01-01-1900' to avoid selection and potential matching issues.  
	-----------------------------------------------------------------------------------------------------------------------------

			-- Save the EventIDs and Event Dates for checking 
			IF OBJECT_ID('tempdb..#Events') IS NOT NULL
				DROP TABLE #Events

			CREATE TABLE #Events
				(
					EventID					BIGINT,
					EventDate				DATETIME2
				)

			INSERT INTO #Events (EventID, EventDate)
			SELECT DISTINCT e.EventID, e.EventDate
			FROM #FileRowsInfo FRI 
			INNER JOIN [$(SampleDB)].Event.Events e ON e.EventID = FRI.EventID



			-------------------------------------------------------------------------------------------------------------------------------------
			-- Update Event Dates in Audit so we can see those records which were erroneously loaded.
			-- 
			-- If there no other unchanged records in Audit linked to that EventID we can assume it can also be safely changed in the main Connexions tables.
			------------------------------------------------------------------------------------------------------------------------------------
 
			-- Save the Audit Records prior to update
			INSERT INTO [$(AuditDB)].RollbackSample.Audit_Events (AuditID, AuditItemID, EventID, EventDate, EventTypeID, TypeOfSaleOrig, InvoiceDate, EventDateOrig)   
			SELECT DISTINCT FRI.AuditID, ae.AuditItemID, ae.EventID, ae.EventDate, ae.EventTypeID, ae.TypeOfSaleOrig, ae.InvoiceDate, ae.EventDateOrig 
			FROM #FileRowsInfo FRI 
			INNER JOIN [$(AuditDB)].Audit.Events ae ON ae.AuditItemID = FRI.AuditItemID


			-- Update the EventDate in Audit
			UPDATE ae
			SET ae.EventDate = '1900-01-01'
			FROM #FileRowsInfo FRI 
			INNER JOIN [$(AuditDB)].Audit.Events ae ON ae.AuditItemID = FRI.AuditItemID



			---------------------------------------------------------------------------------------------------------------------------------------
			-- If the original Event Date is no longer found in Audit then we can reset the value in the main connexions tables as well
			---------------------------------------------------------------------------------------------------------------------------------------
	
			-- Save to sample rollback audit table prior to update
			INSERT INTO [$(AuditDB)].RollbackSample.Events (AuditID, EventID, EventDate, EventTypeID)
			SELECT DISTINCT @AuditID, e.EventID, e.EventDate, e.EventTypeID
			FROM #Events t 
			INNER JOIN [$(SampleDB)].Event.Events e ON e.EventID = t.EventID
											  AND e.EventDate = t.EventDate 
			WHERE NOT EXISTS (SELECT ae2.EventID FROM [$(AuditDB)].Audit.Events ae2 
								WHERE ae2.EventID = t.EventID		-- where the EventID 
								AND ae2.EventDate = t.EventDate		-- AND eventDate exists in Audit
							 )


			-- Update the EventDate in the main tables
			UPDATE e
			SET e.EventDate = '1900-01-01'
			FROM [$(AuditDB)].RollbackSample.Events re 
			INNER JOIN [$(SampleDB)].Event.Events e ON e.EventID = re.EventID
			WHERE re.AuditID = @AuditID




			
	-----------------------------------------------------------------------------------------------------------------------------
	-- Non-solicitate Events 
	-- 
	-- Note: Uses the Sample.Event.Events records that were reset by the previous (EventDate reset) step
	-----------------------------------------------------------------------------------------------------------------------------

	-- create working tables 
	IF OBJECT_ID('tempdb..#EventsToNonSol') IS NOT NULL
		DROP TABLE #EventsToNonSol

	CREATE TABLE #EventsToNonSol
		(
			MatchedODSEventID			BIGINT,
			MatchedODSOrganisationID	BIGINT,
			MatchedODSPersonID			BIGINT,
			MatchedODSPartyID			BIGINT
		)

	IF OBJECT_ID('tempdb..#EventsAndID') IS NOT NULL
		DROP TABLE #EventsAndID

	CREATE TABLE #EventsAndID
		(
			ID						INT	IDENTITY(1,1) NOT NULL,
			MatchedODSEventID		BIGINT,
			PartyID					BIGINT
		)
	

	-- populate working tables 
	INSERT INTO #EventsToNonSol (MatchedODSEventID, MatchedODSOrganisationID, MatchedODSPersonID, MatchedODSPartyID)
	SELECT DISTINCT  sq.MatchedODSEventID, sq.MatchedODSOrganisationID, sq.MatchedODSPersonID, sq.MatchedODSPartyID
	FROM #FileRowsInfo	FRI
	INNER JOIN [$(WebsiteReporting)].dbo.SampleQualityAndSelectionLogging sq ON sq.AuditItemID = FRI.AuditItemID
	INNER JOIN [$(AuditDB)].RollbackSample.Events re ON re.AuditID = @AuditID AND re.EventID = sq.MatchedODSEventID -- Ensure only those recs changed by previous step

	
	INSERT INTO #EventsAndID (MatchedODSEventID, PartyID)
	SELECT 		MatchedODSEventID,
				COALESCE(NULLIF(MatchedODSPersonID, 0), NULLIF(MatchedODSOrganisationID, 0), MatchedODSPartyID) AS PartyID
	FROM #EventsToNonSol


	-- Create dbo.File record as header for associated AuditItems
	
	SELECT @MaxAuditID      = MAX(AuditID)      FROM [$(AuditDB)].dbo.Audit
	SELECT @MaxAuditItemID  = MAX(AuditItemID)  FROM [$(AuditDB)].dbo.AuditItems

	DECLARE @NonSolEventsFileAuditID		BIGINT
	SET @NonSolEventsFileAuditID = @MaxAuditID +1

	INSERT INTO [$(AuditDB)].dbo.Audit (AuditID)
	VALUES (@NonSolEventsFileAuditID)

	INSERT INTO [$(AuditDB)].dbo.AuditItems (AuditItemID, AuditID)
	SELECT (@MaxAuditItemID + ID) , 
			@NonSolEventsFileAuditID
	FROM #EventsAndID 

	INSERT INTO [$(AuditDB)].dbo.Files (AuditID, FileTypeID, FileName, FileRowCount, ActionDate)
	SELECT @NonSolEventsFileAuditID, 
				(SELECT FileTypeID FROM [$(AuditDB)].[dbo].[FileTypes]
			    WHERE FileType = 'Internal System Update') AS FileTypeID,
				('Bug ' + @BugNumberText + ' : Event Non-solicitations. Rollback AuditID: ' + CAST(@AuditID AS VARCHAR(12))) AS Filename, 
				MAX(ID) AS FileRowCount,
				@UpdateDate AS ActionDate
	FROM #EventsAndID

			   
	-- Non-solicitate the events ---- 
	DECLARE @NonSolReferenceText VARCHAR(200)
	SET @NonSolReferenceText  = 'BUG ' + @BugNumberText + ' - Rollback sample file procedure'
	
	INSERT INTO [$(SampleDB)].Event.vwDA_NonSolicitations 
	SELECT 
				(@MaxAuditItemID + ID) AS AuditItemID, 
				0 AS NonSolicitationID,
				14 AS NonSolicitationTextID,  -- Incorrectly loaded
				PartyID, 
				NULL AS RoleTypeID, 
				GETDATE() AS FROMDate, 
				NULL AS ThroughDate, 
				@NonSolReferenceText AS Notes,
				MatchedODSEventID
	FROM #EventsAndID 		








	-----------------------------------------------------------------------------------------------------------------------------
	-- Remove Cases and Update Selection Requirements
	-----------------------------------------------------------------------------------------------------------------------------

	-- Get counts of Cases selected ------------------------------------

	IF OBJECT_ID('tempdb..#SelectionCounts') IS NOT NULL
		DROP TABLE #SelectionCounts

	CREATE TABLE #SelectionCounts
		(
			RequirementID		BIGINT,
			SelectedCases		BIGINT,
			RejectedCases		BIGINT
		)

	INSERT INTO #SelectionCounts (RequirementID, SelectedCases, RejectedCases)
	SELECT	FRI.RequirementID, 
			COUNT(DISTINCT FRI.CaseID) as SelectedCases,  
			COUNT(DISTINCT cr.CaseID) as RejectedCases
	FROM #FileRowsInfo FRI
	LEFT JOIN [$(SampleDB)].Event.CaseRejections cr ON cr.CaseID = FRI.CaseID
	WHERE FRI.CaseID IS NOT NULL
	GROUP BY FRI.RequirementID



	-- Get list of Cases to update -------------------------------------
	IF OBJECT_ID('tempdb..#tmpCases') IS NOT NULL
	DROP TABLE #tmpCases

	CREATE TABLE #tmpCases 
		(
		CaseID int,
		UNIQUE(CaseID)
		)


	INSERT INTO #tmpCases
		(
		CaseID
		)
	SELECT DISTINCT CaseID
	FROM #FileRowsInfo
	WHERE CaseID IS NOT NULL


	-- SAVE related Case information prior to deletion -----------------------

	INSERT INTO [$(AuditDB)].RollbackSample.AutomotiveEventBasedInterviews (AuditID, CaseID, EventID, PartyID, VehicleRoleTypeID, VehicleID)
	SELECT @AuditID, aebi.CaseID, aebi.EventID, aebi.PartyID, aebi.VehicleRoleTypeID, aebi.VehicleID
	FROM	 [$(SampleDB)].Event.AutomotiveEventBasedInterviews aebi
	JOIN	#TmpCases c
			On aebi.CaseID = c.CaseID

	INSERT INTO [$(AuditDB)].RollbackSample.SelectionCases (AuditID, CaseID, RequirementIDMadeUpOf, RequirementIDPartOf)
	SELECT @AuditID, pd.CaseID, pd.RequirementIDMadeUpOf, pd.RequirementIDPartOf
	FROM	[$(SampleDB)].Requirement.SelectionCases pd
	JOIN	#TmpCases c
			On pd.CaseID = c.CaseID

	INSERT INTO [$(AuditDB)].RollbackSample.CaseContactMechanismOutcomes (AuditID, CaseID, OutcomeCode, OutcomeCodeTypeID, ContactMechanismID, ActionDate, ReOutputProcessed, ReOutputProcessDate, ReOutputSuccess)
	SELECT  @AuditID, 
			ccmo.CaseID, ccmo.OutcomeCode, ccmo.OutcomeCodeTypeID, ccmo.ContactMechanismID, ccmo.ActionDate, ccmo.ReOutputProcessed, ccmo.ReOutputProcessDate, ccmo.ReOutputSuccess
	FROM	[$(SampleDB)].Event.CaseContactMechanismOutcomes ccmo
	JOIN	#TmpCases c
			On ccmo.CaseID = c.CaseID

	INSERT INTO [$(AuditDB)].RollbackSample.CaseContactMechanisms (AuditID, CaseID, ContactMechanismTypeID, ContactMechanismID)
	SELECT  @AuditID, ccm.CaseID, ccm.ContactMechanismTypeID, ccm.ContactMechanismID
	FROM	[$(SampleDB)].Event.CaseContactMechanisms ccm
	JOIN	#TmpCases c
			On ccm.CaseID = c.CaseID

	INSERT INTO [$(AuditDB)].RollbackSample.CaseRejections (AuditID, CaseID, FromDate)
	SELECT @AuditID, cr.CaseID, cr.FromDate
	FROM	[$(SampleDB)].Event.CaseRejections cr
	JOIN	#TmpCases c
			On cr.CaseID = c.CaseID

	INSERT INTO [$(AuditDB)].RollbackSample.CaseOutput (AuditID, CaseID, CaseOutput_AuditID, CaseOutput_AuditItemID, CaseOutputTypeID)
	SELECT @AuditID, CO.CaseID, CO.AuditID, CO.AuditItemID, CO.CaseOutputTypeID
	FROM  [$(SampleDB)].Event.CaseOutput CO
	JOIN #TmpCases C
	ON C.CaseID = CO.CaseID

	INSERT INTO [$(AuditDB)].RollbackSample.Cases (AuditID, CaseID, CaseStatusTypeID, CreationDate, ClosureDate, OnlineExpiryDate, SelectionOutputPassword, AnonymityDealer, AnonymityManufacturer)
	SELECT @AuditID, cs.CaseID, cs.CaseStatusTypeID, cs.CreationDate, cs.ClosureDate, cs.OnlineExpiryDate, cs.SelectionOutputPassword, cs.AnonymityDealer, cs.AnonymityManufacturer
 	FROM	 [$(SampleDB)].Event.Cases cs
	JOIN	#TmpCases c
			On cs.CaseID = c.CaseID

	INSERT INTO [$(AuditDB)].RollbackSample.CaseDetails 
			(
				AuditID,
				Questionnaire,	QuestionnaireRequirementID, QuestionnaireVersion, SelectionTypeID, Selection, ModelDerivative, CaseStatusTypeID, 
				CaseID, CaseRejection, Title, FirstName, Initials, MiddleName, LastName, SecondLastName, GenderID, LanguageID, OrganisationName, 
				OrganisationPartyID, PostalAddressContactMechanismID, EmailAddressContactMechanismID, CountryID, Country, CountryISOAlpha3, 
				CountryISOAlpha2, EventTypeID, EventType, EventDate, PartyID, VehicleRoleTypeID, VehicleID, EventID, OwnershipCycle, 
				SelectionRequirementID, ModelRequirementID, RegistrationNumber, RegistrationDate, ModelDescription, VIN, VinPrefix, ChassisNumber, 
				ManufacturerPartyID, DealerPartyID, DealerCode, DealerName, RoadsideNetworkPartyID, RoadsideNetworkCode, RoadsideNetworkName, 
				SaleType, VariantID, ModelVariant		
			)
	SELECT @AuditID, 
	        cd.Questionnaire, cd.QuestionnaireRequirementID, cd.QuestionnaireVersion, cd.SelectionTypeID, cd.Selection, cd.ModelDerivative, cd.CaseStatusTypeID, 
				cd.CaseID, cd.CaseRejection, cd.Title, cd.FirstName, cd.Initials, cd.MiddleName, cd.LastName, cd.SecondLastName, cd.GenderID, cd.LanguageID, cd.OrganisationName, 
				cd.OrganisationPartyID, cd.PostalAddressContactMechanismID, cd.EmailAddressContactMechanismID, cd.CountryID, cd.Country, cd.CountryISOAlpha3, 
				cd.CountryISOAlpha2, cd.EventTypeID, cd.EventType, cd.EventDate, cd.PartyID, cd.VehicleRoleTypeID, cd.VehicleID, cd.EventID, cd.OwnershipCycle, 
				cd.SelectionRequirementID, cd.ModelRequirementID, cd.RegistrationNumber, cd.RegistrationDate, cd.ModelDescription, cd.VIN, cd.VinPrefix, cd.ChassisNumber, 
				cd.ManufacturerPartyID, cd.DealerPartyID, cd.DealerCode, cd.DealerName, cd.RoadsideNetworkPartyID, cd.RoadsideNetworkCode, cd.RoadsideNetworkName, 
				cd.SaleType, cd.VariantID, cd.ModelVariant		
	FROM	 [$(SampleDB)].Meta.CaseDetails cd
	JOIN	#TmpCases c
			On cd.CaseID = c.CaseID
			
					
	INSERT INTO [$(AuditDB)].RollbackSample.Audit_CaseRejections (AuditID, CaseRejections_AuditItemID, CaseID, Rejection, FromDate)
	SELECT @AuditID, cr.AuditItemID, cr.CaseID, cr.Rejection, cr.FromDate
	FROM	[$(AuditDB)].Audit.CaseRejections cr
	JOIN	#TmpCases c
			On cr.CaseID = c.CaseID


	-- SAVE the Selection and Requirements data before updating --------------------------------------

	INSERT INTO [$(AuditDB)].RollbackSample.SelectionRequirements (AuditID, RequirementID, SelectionDate, SelectionStatusTypeID, SelectionTypeID, DateLastRun,
				 RecordsSelected, RecordsRejected, LastViewedDate, LastViewedPartyID, LastViewedRoleTypeID, DateOutputAuthorised, AuthorisingPartyID, AuthorisingRoleTypeID, ScheduledRunDate, UseQuotas)
	SELECT @AuditID, sr.RequirementID, sr.SelectionDate, sr.SelectionStatusTypeID, sr.SelectionTypeID, sr.DateLastRun, sr.RecordsSelected, 
			sr.RecordsRejected, sr.LastViewedDate, sr.LastViewedPartyID, sr.LastViewedRoleTypeID, sr.DateOutputAuthorised, sr.AuthorisingPartyID, sr.AuthorisingRoleTypeID, sr.ScheduledRunDate, sr.UseQuotas
	FROM #SelectionCounts rc
	INNER JOIN [$(SampleDB)].Requirement.SelectionRequirements sr ON sr.RequirementID = rc.RequirementID

	INSERT INTO [$(AuditDB)].RollbackSample.Requirements (AuditID, RequirementID, RequirementTypeID, Requirement, RequirementCreationDate) 
	SELECT @AuditID, r.RequirementID, r.RequirementTypeID, r.Requirement, r.RequirementCreationDate
	FROM #SelectionCounts rc
	INNER JOIN [$(SampleDB)].Requirement.Requirements r ON r.RequirementID = rc.RequirementID
	WHERE r.Requirement NOT LIKE '%FileRollback_CasesRemoved%'

	
	-- DELETE all related Case information ---------------------------------------
	DELETE	aebi
	FROM	 [$(SampleDB)].Event.AutomotiveEventBasedInterviews aebi
	JOIN	#TmpCases c
			On aebi.CaseID = c.CaseID

	DELETE	pd
	FROM	[$(SampleDB)].Requirement.SelectionCases pd
	JOIN	#TmpCases c
			On pd.CaseID = c.CaseID
			
	DELETE	ccmo
	FROM	[$(SampleDB)].Event.CaseContactMechanismOutcomes ccmo
	JOIN	#TmpCases c
			On ccmo.CaseID = c.CaseID
	DELETE	ccm
	FROM	[$(SampleDB)].Event.CaseContactMechanisms ccm
	JOIN	#TmpCases c
			On ccm.CaseID = c.CaseID

	DELETE	cr
	FROM	[$(SampleDB)].Event.CaseRejections cr
	Join	#TmpCases c
			On cr.CaseID = c.CaseID

	DELETE CO
	FROM  [$(SampleDB)].Event.CaseOutput CO
	JOIN #TmpCases C
	ON C.CaseID = CO.CaseID

	DELETE	cs
	FROM	 [$(SampleDB)].Event.Cases cs
	JOIN	#TmpCases c
			On cs.CaseID = c.CaseID

	DELETE	cd
	FROM	 [$(SampleDB)].Meta.CaseDetails cd
	JOIN	#TmpCases c
			On cd.CaseID = c.CaseID
		
	DELETE	cr
	FROM	[$(AuditDB)].Audit.CaseRejections cr
	JOIN	#TmpCases c
			On cr.CaseID = c.CaseID

	-- Reset the logging tables 
	UPDATE SL
		SET SL.CaseID = NULL,
			SL.RecontactPeriod = 0,
			SL.RelativeRecontactPeriod = 0,
			SL.CaseIDPrevious = 0,			
			SL.EventAlreadySelected = 0,
			SL.ExclusionListMatch = 0,
			SL.EventNonSolicitation = 0,
			SL.BarredEmailAddress = 0,
			SL.WrongEventType = 0,
			SL.MissingStreet = 0,
			SL.MissingPostcode = 0,
			SL.MissingEmail = 0,
			SL.MissingTelephone = 0,
			SL.MissingStreetAndEmail = 0,
			SL.MissingTelephoneAndEmail = 0,
			SL.MissingMobilePhone = 0,
			SL.MissingMobilePhoneAndEmail = 0,
			SL.InvalidModel = 0,
			SL.InvalidVariant = 0,						-- v1.3
			SL.MissingPartyName = 0,
			SL.MissingLanguage = 0,
			SL.InternalDealer = 0,
			SL.InvalidOwnershipCycle = 0,
			SL.InvalidRoleType = 0,
			SL.InvalidSaleType = 0,
			SL.InvalidAFRLCode = 0,
			SL.SuppliedAFRLCode = 0,
			SL.DealerExclusionListMatch = 0,
			SL.InvalidCRMSaleType = 0,

			SL.[ContactPreferencesSuppression] = 0,
			SL.[ContactPreferencesPartySuppress] = 0,
			SL.[ContactPreferencesEmailSuppress] = 0,
			SL.[ContactPreferencesPhoneSuppress] = 0,
			SL.[ContactPreferencesPostalSuppress] = 0,

			SL.[MissingLostLeadAgency]			 = 0 	 ,    -- v1.3
			SL.[PDIFlagSet]						 = 0 	 ,    -- v1.3
			SL.[ContactPreferencesUnsubscribed]	 = 0 	 ,    -- v1.3
			SL.[SelectionOrganisationID]		 = NULL  ,    -- v1.3
			SL.[SelectionPostalID]				 = NULL  ,    -- v1.3
			SL.[SelectionEmailID]				 = NULL  ,    -- v1.3
			SL.[SelectionPhoneID]				 = NULL  ,    -- v1.3
			SL.[SelectionLandlineID]			 = NULL  ,    -- v1.3
			SL.[SelectionMobileID]				 = NULL  ,    -- v1.3

			SL.SampleRowProcessed = 1,
			SL.SampleRowProcessedDate = GETDATE()	 
	FROM #FileRowsInfo FRI								  
	INNER JOIN [$(WebsiteReporting)].dbo.SampleQualityAndSelectionLogging SL ON SL.AuditItemID = FRI.AuditItemID -- Link on AuditItemID as CaseID not always updated for subsequently received duplicate Events
	WHERE FRI.CaseID IS NOT NULL


	-- Update selectionrequirements details - decrease counts by number of Cases removed 
	UPDATE sr 
	SET RecordsSelected = sr.RecordsSelected - rc.SelectedCases,
		RecordsRejected = sr.RecordsRejected - rc.RejectedCases
	FROM #SelectionCounts rc
	INNER JOIN [$(SampleDB)].Requirement.SelectionRequirements sr ON sr.RequirementID = rc.RequirementID


	-- Set Selection Requirement columns to NULL if ALL records removed from selection
	UPDATE sr	 
	SET	SelectionStatusTypeid = 1,
		DateLastRun = null,
		RecordsSelected = null,
		RecordsRejected = null,
		DateOutputAuthorised = null,
		AuthorisingPartyID = null,
		AuthorisingRoleTypeID = null,
		ScheduledRunDate = null
	FROM #SelectionCounts rc
	INNER JOIN [$(SampleDB)].Requirement.SelectionRequirements sr ON sr.RequirementID = rc.RequirementID
	WHERE sr.RecordsSelected = 0


	-- Update the Selection name for ease of identification
	UPDATE r 
	SET Requirement = r.Requirement + '_FileRollback_CasesRemoved'
	FROM #SelectionCounts rc
	INNER JOIN [$(SampleDB)].Requirement.Requirements r ON r.RequirementID = rc.RequirementID
	WHERE r.Requirement NOT LIKE '%FileRollback_CasesRemoved%'





	-----------------------------------------------------------------------------------------------------------------------------
	-----------------------------------------------------------------------------------------------------------------------------
	-- Rollback and adjust contact preferences
	-----------------------------------------------------------------------------------------------------------------------------
	-----------------------------------------------------------------------------------------------------------------------------
	

	-- Save data prior to changing it 
	INSERT INTO [$(AuditDB)].RollbackSample.Audit_ContactPreferences (AuditID, AuditItemID, PartyID, OriginalPartySuppression, OriginalPostalSuppression, OriginalEmailSuppression, OriginalPhoneSuppression, OriginalPartyUnsubscribe, SuppliedPartySuppression, SuppliedPostalSuppression, SuppliedEmailSuppression, SuppliedPhoneSuppression, SuppliedPartyUnsubscribe, PartySuppression, PostalSuppression, EmailSuppression, PhoneSuppression, PartyUnsubscribe, UpdateDate, UpdateSource, ContactPreferencesPersist, EventCategoryPersistOveride, OverridePreferences, RemoveUnsubscribe, RollbackIndicator, Comments)
	SELECT DISTINCT FRI.AuditID, cp.AuditItemID, cp.PartyID, cp.OriginalPartySuppression, cp.OriginalPostalSuppression, cp.OriginalEmailSuppression, cp.OriginalPhoneSuppression, cp.OriginalPartyUnsubscribe, cp.SuppliedPartySuppression, cp.SuppliedPostalSuppression, cp.SuppliedEmailSuppression, cp.SuppliedPhoneSuppression, cp.SuppliedPartyUnsubscribe, cp.PartySuppression, cp.PostalSuppression, cp.EmailSuppression, cp.PhoneSuppression, cp.PartyUnsubscribe, cp.UpdateDate, cp.UpdateSource, cp.ContactPreferencesPersist, cp.EventCategoryPersistOveride, cp.OverridePreferences, cp.RemoveUnsubscribe, cp.RollbackIndicator, cp.Comments
	FROM #FileRowsInfo FRI 
	INNER JOIN [$(AuditDB)].Audit.ContactPreferences cp ON cp.AuditItemID = FRI.AuditItemID

	INSERT INTO [$(AuditDB)].RollbackSample.Audit_ContactPreferencesBySurvey (AuditID, AuditItemID, PartyID, EventCategoryID, OriginalPartySuppression, OriginalPostalSuppression, OriginalEmailSuppression, OriginalPhoneSuppression, SuppliedPartySuppression, SuppliedPostalSuppression, SuppliedEmailSuppression, SuppliedPhoneSuppression, SuppliedPartyUnsubscribe, PartySuppression, PostalSuppression, EmailSuppression, PhoneSuppression, UpdateDate, UpdateSource, MarketCountryID, SampleMarketID, ContactPreferencesPersist, EventCategoryPersistOveride, OverridePreferences, RemoveUnsubscribe, AdditionalAuditsCreatedByRemoveUnsub, RollbackIndicator, Comments)
	SELECT DISTINCT FRI.AuditID, cp.AuditItemID, cp.PartyID, cp.EventCategoryID, cp.OriginalPartySuppression, cp.OriginalPostalSuppression, cp.OriginalEmailSuppression, cp.OriginalPhoneSuppression, cp.SuppliedPartySuppression, cp.SuppliedPostalSuppression, cp.SuppliedEmailSuppression, cp.SuppliedPhoneSuppression, cp.SuppliedPartyUnsubscribe, cp.PartySuppression, cp.PostalSuppression, cp.EmailSuppression, cp.PhoneSuppression, cp.UpdateDate, cp.UpdateSource, cp.MarketCountryID, cp.SampleMarketID, cp.ContactPreferencesPersist, cp.EventCategoryPersistOveride, cp.OverridePreferences, cp.RemoveUnsubscribe, cp.AdditionalAuditsCreatedByRemoveUnsub, cp.RollbackIndicator, cp.Comments
	FROM #FileRowsInfo FRI 
	INNER JOIN [$(AuditDB)].Audit.ContactPreferencesBySurvey cp ON cp.AuditItemID = FRI.AuditItemID


	-- Set the rollback indictator in the audit tables.  (So we can identify rolled back records plus ignore them in the re-calc below) 
	UPDATE acp
	SET RollbackIndicator = 1 ,
		Comments = @Comments
	FROM #FileRowsInfo FRI
	INNER JOIN [$(AuditDB)].Audit.ContactPreferences acp ON acp.AuditItemID = FRI.AuditItemID
	
	UPDATE acpbs
	SET RollbackIndicator = 1 ,
		Comments = @Comments
	FROM #FileRowsInfo FRI
	INNER JOIN [$(AuditDB)].Audit.ContactPreferencesBySurvey acpbs ON acpbs.AuditItemID = FRI.AuditItemID



	------------------------------------------------------------------------------------------------------------------------
	-- Process "Persist" ContactPreferences (Global) records
	------------------------------------------------------------------------------------------------------------------------
	
	-- Find the AuditItemId of any Override records associated with the customer
	
	CREATE TABLE #MaxOverridePreferencesRecord
		(
			PartyID							BIGINT,
			MaxOverridePreferencesRecord	BIGINT	
		)

	INSERT INTO #MaxOverridePreferencesRecord (PartyID, MaxOverridePreferencesRecord)
	SELECT cpp.PartyID, MAX(AuditItemID) AS MaxOverridePreferencesRecord  -- look for an override preferences record on file.  This is fixed and we should not look further back than this record, if it exists
	FROM  #ContactPreferenceParties cpp 
	LEFT JOIN [$(AuditDB)].Audit.ContactPreferences acps ON acps.PartyId = cpp.PartyID
														AND (SuppliedPartyUnsubscribe <> 1 OR UpdateSource <> 'Customer Update')  -- Exclude Unsubscribes
														AND ISNULL(RollbackIndicator,0) = 0  -- ignore any rollback records
														AND ISNULL(OverridePreferences, 0) = 1
	WHERE  cpp.ContactPreferencesPersist = 1
	GROUP BY cpp.PartyID
	
	-- Get the latest non-persist values remaining on file for each PartyID, after we ignore the rollback and customer update records
	
	CREATE TABLE #MaxNonPersistSampleRecord
		(
			PartyID							BIGINT,
			MaxNonPersistSampleRecord		BIGINT	
		)

	INSERT INTO #MaxNonPersistSampleRecord (PartyID, MaxNonPersistSampleRecord)
	SELECT cpp.PartyID, MAX(AuditItemID) AS MaxNonPersistSampleRecord  
	FROM #ContactPreferenceParties cpp 
	INNER JOIN #MaxOverridePreferencesRecord mop ON mop.PartyID = cpp.PartyID
	LEFT JOIN [$(AuditDB)].Audit.ContactPreferences acps ON acps.PartyID = cpp.PartyID
																AND (SuppliedPartyUnsubscribe <> 1 OR UpdateSource <> 'Customer Update') -- Exclude Unsubscribes
																AND ISNULL(RollbackIndicator,0) = 0   -- ignore any rollback records
																AND (acps.AuditItemID > mop.MaxOverridePreferencesRecord OR mop.MaxOverridePreferencesRecord IS NULL)  -- We do not look further back than the last ContactPreferences override record
																AND acps.ContactPreferencesPersist = 0
	WHERE  cpp.ContactPreferencesPersist = 1
	GROUP BY cpp.PartyID
		
	
	-- Save out any required adjustments -----------------------
	
	CREATE TABLE #ContactPreferenceAdjustments
		
		(
			ID						INT IDENTITY(1,1),
			PartyID					BIGINT,
			CalcPartySuppression	INT,
			CalcPostalSuppression	INT,
			CalcEmailSuppression	INT,
			CalcPhoneSuppression	INT
		) 

	; WITH CTE_CalcSuppressionsForRollup
	AS (
		SELECT 
		  cpp.[PartyID]
		  ,CASE WHEN ISNULL(cp.PartyUnsubscribe, 0) = 1 THEN 1 WHEN UpdateSource = 'Initial Setup' THEN acps.[PartySuppression] ELSE acps.[SuppliedPartySuppression] END AS CalcPartySuppression
		  ,CASE WHEN acps.UpdateSource = 'Initial Setup' THEN acps.PostalSuppression ELSE acps.[SuppliedPostalSuppression] END AS CalcPostalSuppression
		  ,CASE WHEN acps.UpdateSource = 'Initial Setup' THEN acps.EmailSuppression ELSE acps.[SuppliedEmailSuppression] END   AS CalcEmailSuppression
		  ,CASE WHEN acps.UpdateSource = 'Initial Setup' THEN acps.PhoneSuppression ELSE acps.[SuppliedPhoneSuppression] END   AS CalcPhoneSuppression
		FROM #ContactPreferenceParties cpp 
		INNER JOIN #MaxOverridePreferencesRecord mop ON mop.PartyID = cpp.PartyID
		INNER JOIN #MaxNonPersistSampleRecord mnp ON mnp.PartyID = cpp.PartyID
		LEFT JOIN [$(SampleDB)].Party.ContactPreferences cp ON cp.PartyID = cpp.PartyID
		LEFT JOIN [$(AuditDB)].[Audit].[ContactPreferences] acps 
								ON acps.PartyID = cpp.PartyID   -- left join here so that we can still populate with zero's if there are no values here to roll up
								AND (acps.SuppliedPartyUnsubscribe <> 1 OR acps.UpdateSource <> 'Customer Update') -- Exclude Unsubscribes
								AND ISNULL(acps.RollbackIndicator,0) = 0
								AND (acps.AuditItemID >= MaxOverridePreferencesRecord OR MaxOverridePreferencesRecord IS NULL)  -- We do not look further back than the last ContactPreferences override record 
								AND (   acps.AuditItemID >= MaxNonPersistSampleRecord	-- Get all records back to and including the last non-persist record, it's values are carried forward when the market is persist.
										OR MaxNonPersistSampleRecord IS NULL
									)
		WHERE  cpp.ContactPreferencesPersist = 1		-- Persist Market
	),
	CTE_CalcSuppressionsForAdjustment
	AS ( 
		SELECT PartyID,
				MAX(ISNULL(CAST(CalcPartySuppression AS INT), 0)) AS CalcPartySuppression ,
				MAX(ISNULL(CAST(CalcPostalSuppression AS INT), 0)) AS CalcPostalSuppression,
				MAX(ISNULL(CAST(CalcEmailSuppression AS INT), 0)) AS CalcEmailSuppression ,
				MAX(ISNULL(CAST(CalcPhoneSuppression as INT), 0)) AS CalcPhoneSuppression
		FROM CTE_CalcSuppressionsForRollup		
		GROUP BY PartyID
	)
	INSERT INTO #ContactPreferenceAdjustments (
												PartyID					,
												CalcPartySuppression	,
												CalcPostalSuppression	,
												CalcEmailSuppression	,
												CalcPhoneSuppression	
											)
	SELECT	csa.PartyID, 
			csa.CalcPartySuppression ,
			csa.CalcPostalSuppression,
			csa.CalcEmailSuppression ,
			csa.CalcPhoneSuppression
	FROM CTE_CalcSuppressionsForAdjustment csa
	INNER JOIN [$(SampleDB)].Party.ContactPreferences cp ON cp.PartyID = csa.PartyID
	WHERE   ISNULL(cp.PartySuppression, 0)  <> csa.CalcPartySuppression
	     OR ISNULL(cp.PostalSuppression, 0) <> csa.CalcPostalSuppression
		 OR ISNULL(cp.PhoneSuppression, 0)  <> csa.CalcPhoneSuppression
		 OR ISNULL(cp.EmailSuppression, 0)  <> csa.CalcEmailSuppression

	
	------------------------------------------------------------------------------------------------------------------------
	-- Process "Persist" ContactPreferencesBySurvey records
	------------------------------------------------------------------------------------------------------------------------
	

	-- Find the AuditItemId of any Override records associated with the customer
	
	CREATE TABLE #MaxOverridePreferencesRecordBySurvey
		(
			PartyID							BIGINT,
			EventCategoryID					INT,
			MaxOverridePreferencesRecord	BIGINT	
		)

	INSERT INTO #MaxOverridePreferencesRecordBySurvey (PartyID, EventCategoryID, MaxOverridePreferencesRecord)
	SELECT cpp.PartyID, cpp.EventCategoryID, MAX(AuditItemID) AS MaxOverridePreferencesRecord  -- look for an override preferences record on file.  This is fixed and we should not look further back than this record, if it exists
	FROM  #ContactPreferencePartiesBySurvey cpp 
	LEFT JOIN [$(AuditDB)].Audit.ContactPreferencesBySurvey acps ON acps.PartyId = cpp.PartyID
														AND acps.EventCategoryID = cpp.EventCategoryID
														AND (SuppliedPartyUnsubscribe <> 1 OR UpdateSource <> 'Customer Update')  -- Exclude Unsubscribes
														AND ISNULL(RollbackIndicator,0) = 0  -- ignore any rollback records
														AND ISNULL(OverridePreferences, 0) = 1
	WHERE  cpp.ContactPreferencesPersist = 1
	GROUP BY cpp.PartyID, cpp.EventCategoryID
	
	-- Get the latest non-persist values remaining on file for each PartyID, after we ignore the rollback and customer update records
	
	CREATE TABLE #MaxNonPersistSampleRecordBySurvey
		(
			PartyID							BIGINT,
			EventCategoryID					INT,
			MaxNonPersistSampleRecord		BIGINT
		)

	INSERT INTO #MaxNonPersistSampleRecordBySurvey (PartyID, EventCategoryID, MaxNonPersistSampleRecord)
	SELECT cpp.PartyID, cpp.EventCategoryID, MAX(AuditItemID) AS MaxNonPersistSampleRecord  
	FROM #ContactPreferencePartiesBySurvey cpp 
	INNER JOIN #MaxOverridePreferencesRecordBySurvey mop ON mop.PartyID = cpp.PartyID AND mop.EventCategoryID = cpp.EventCategoryID
	LEFT JOIN [$(AuditDB)].Audit.ContactPreferencesBySurvey acps ON acps.PartyID = cpp.PartyID
																		AND acps.EventCategoryID = cpp.EventCategoryID
																		AND (SuppliedPartyUnsubscribe <> 1 OR UpdateSource <> 'Customer Update') -- Exclude Unsubscribes
																		AND ISNULL(RollbackIndicator,0) = 0   -- ignore any rollback records
																		AND (acps.AuditItemID > mop.MaxOverridePreferencesRecord OR mop.MaxOverridePreferencesRecord IS NULL)  -- We do not look further back than the last ContactPreferences override record
																		AND acps.ContactPreferencesPersist = 0
	WHERE  cpp.ContactPreferencesPersist = 1
	GROUP BY cpp.PartyID, cpp.EventCategoryID
		
	
	-- Save out any required adjustments -----------------------
	
	CREATE TABLE #ContactPreferenceAdjustmentsBySurvey
		
		(
			ID						INT IDENTITY(1,1),
			PartyID					BIGINT,
			EventCategoryID			INT,
			CalcPartySuppression	INT,
			CalcPostalSuppression	INT,
			CalcEmailSuppression	INT,
			CalcPhoneSuppression	INT
		) 

	; WITH CTE_CalcSuppressionsForRollup
	AS (
		SELECT 
		   cpp.PartyID
		  ,cpp.EventCategoryID
		  ,CASE WHEN ISNULL(cp.PartyUnsubscribe, 0) = 1 THEN 1 WHEN UpdateSource = 'Initial Setup' THEN acps.[PartySuppression] ELSE acps.[SuppliedPartySuppression] END AS CalcPartySuppression
		  ,CASE WHEN acps.UpdateSource = 'Initial Setup' THEN acps.PostalSuppression ELSE acps.[SuppliedPostalSuppression] END AS CalcPostalSuppression
		  ,CASE WHEN acps.UpdateSource = 'Initial Setup' THEN acps.EmailSuppression ELSE acps.[SuppliedEmailSuppression] END   AS CalcEmailSuppression
		  ,CASE WHEN acps.UpdateSource = 'Initial Setup' THEN acps.PhoneSuppression ELSE acps.[SuppliedPhoneSuppression] END   AS CalcPhoneSuppression
		FROM #ContactPreferencePartiesBySurvey cpp 
		INNER JOIN #MaxOverridePreferencesRecordBySurvey mop ON mop.PartyID = cpp.PartyID AND mop.EventCategoryID = cpp.EventCategoryID
		INNER JOIN #MaxNonPersistSampleRecordBySurvey mnp ON mnp.PartyID = cpp.PartyID AND mnp.EventCategoryID = cpp.EventCategoryID
		LEFT JOIN [$(SampleDB)].Party.ContactPreferences cp ON cp.PartyID = cpp.PartyID
		LEFT JOIN [$(AuditDB)].Audit.ContactPreferencesBySurvey acps  -- left join here so that we can still populate with zero's if there are no values here to roll up 
								ON acps.PartyID = cpp.PartyID   
								AND acps.EventCategoryID = cpp.EventCategoryID
								AND (acps.SuppliedPartyUnsubscribe <> 1 OR acps.UpdateSource <> 'Customer Update') -- Exclude Unsubscribes
								AND ISNULL(acps.RollbackIndicator,0) = 0
								AND (acps.AuditItemID >= MaxOverridePreferencesRecord OR MaxOverridePreferencesRecord IS NULL)  -- We do not look further back than the last ContactPreferences override record 
								AND (   acps.AuditItemID >= MaxNonPersistSampleRecord	-- Get all records back to and including the last non-persist record, it's values are carried forward when the market is persist.
										OR MaxNonPersistSampleRecord IS NULL
									)
		WHERE  cpp.ContactPreferencesPersist = 1   -- Persist Market
	),
	CTE_CalcSuppressionsForAdjustment
	AS ( 
		SELECT PartyID,
				EventCategoryID,
				MAX(ISNULL(CAST(CalcPartySuppression AS INT), 0)) AS CalcPartySuppression ,
				MAX(ISNULL(CAST(CalcPostalSuppression AS INT), 0)) AS CalcPostalSuppression,
				MAX(ISNULL(CAST(CalcEmailSuppression AS INT), 0)) AS CalcEmailSuppression ,
				MAX(ISNULL(CAST(CalcPhoneSuppression as INT), 0)) AS CalcPhoneSuppression
		FROM CTE_CalcSuppressionsForRollup		
		GROUP BY PartyID, EventCategoryID
	)
	INSERT INTO #ContactPreferenceAdjustmentsBySurvey (
												PartyID					,
												EventCategoryID			,
												CalcPartySuppression	,
												CalcPostalSuppression	,
												CalcEmailSuppression	,
												CalcPhoneSuppression	
											)
	SELECT	csa.PartyID, 
			csa.EventCategoryID,
			csa.CalcPartySuppression ,
			csa.CalcPostalSuppression,
			csa.CalcEmailSuppression ,
			csa.CalcPhoneSuppression
	FROM CTE_CalcSuppressionsForAdjustment csa
	INNER JOIN [$(SampleDB)].Party.ContactPreferencesBySurvey cp ON cp.PartyID = csa.PartyID AND cp.EventCategoryID = csa.EventCategoryID 
	WHERE   ISNULL(cp.PartySuppression, 0)  <> csa.CalcPartySuppression
	     OR ISNULL(cp.PostalSuppression, 0) <> csa.CalcPostalSuppression
		 OR ISNULL(cp.PhoneSuppression, 0)  <> csa.CalcPhoneSuppression
		 OR ISNULL(cp.EmailSuppression, 0)  <> csa.CalcEmailSuppression



	-------------------------------------------------------------------------------------------------------------------------------
	-- Process "NON-Persist" ContactPreference (Global) records. Just get the latest non-Unsubscribe, non-Rollback record on file.
	-------------------------------------------------------------------------------------------------------------------------------
	

	-- Save out any required adjustments -----------------------
	
	; WITH CTE_CalcSuppressions
	AS (
		SELECT 
		   cpp.[PartyID]
		 ,CASE WHEN ISNULL(cp.PartyUnsubscribe, 0) = 1 THEN 1 WHEN UpdateSource = 'Initial Setup' THEN ISNULL(acps.[PartySuppression], 0) ELSE ISNULL(acps.[SuppliedPartySuppression], 0) END AS CalcPartySuppression
		  ,CASE WHEN acps.UpdateSource = 'Initial Setup' THEN ISNULL(acps.PostalSuppression, 0) ELSE ISNULL(acps.[SuppliedPostalSuppression], 0) END AS CalcPostalSuppression
		  ,CASE WHEN acps.UpdateSource = 'Initial Setup' THEN ISNULL(acps.EmailSuppression, 0) ELSE ISNULL(acps.[SuppliedEmailSuppression], 0) END   AS CalcEmailSuppression
		  ,CASE WHEN acps.UpdateSource = 'Initial Setup' THEN ISNULL(acps.PhoneSuppression, 0) ELSE ISNULL(acps.[SuppliedPhoneSuppression], 0) END   AS CalcPhoneSuppression
		FROM #ContactPreferenceParties cpp 
		LEFT JOIN [$(SampleDB)].Party.ContactPreferences cp ON cp.PartyID = cpp.PartyID
		LEFT JOIN [$(AuditDB)].Audit.ContactPreferences acps  -- left join here so that we can still populate with zero's if there are no values here to roll up 
							ON  acps.AuditItemID = (SELECT MAX(AuditItemID)  -- get the latest value remaining on file after we ignore the rollback and customer update records
													FROM [$(AuditDB)].[Audit].[ContactPreferencesBySurvey] acps
													  WHERE acps.PartyID = cpp.PartyID 
													  AND (SuppliedPartyUnsubscribe <> 1 OR UpdateSource <> 'Customer Update')  -- Ignore Customer Update Unsubscribes
													  AND ISNULL(RollbackIndicator,0) = 0										-- Ignore records that have been flagged as roll back
													)
		WHERE  cpp.ContactPreferencesPersist = 0		-- Non-persist Markets
	)
	INSERT INTO #ContactPreferenceAdjustments (
												PartyID					,
												CalcPartySuppression	,
												CalcPostalSuppression	,
												CalcEmailSuppression	,
												CalcPhoneSuppression	
											)
	SELECT	csa.PartyID, 
			csa.CalcPartySuppression ,
			csa.CalcPostalSuppression,
			csa.CalcEmailSuppression ,
			csa.CalcPhoneSuppression
	FROM CTE_CalcSuppressions csa
	INNER JOIN [$(SampleDB)].Party.ContactPreferences cp ON cp.PartyID = csa.PartyID 
	WHERE   ISNULL(cp.PartySuppression, 0)  <> csa.CalcPartySuppression
	     OR ISNULL(cp.PostalSuppression, 0) <> csa.CalcPostalSuppression
		 OR ISNULL(cp.PhoneSuppression, 0)  <> csa.CalcPhoneSuppression
		 OR ISNULL(cp.EmailSuppression, 0)  <> csa.CalcEmailSuppression

		


	--------------------------------------------------------------------------------------------------------------------------------
	-- Process "NON-Persist" ContactPreferencesBySurvey records.  Just get the latest non-Unsubscribe, non-Rollback record on file.
	--------------------------------------------------------------------------------------------------------------------------------
	

	-- Save out any required adjustments -----------------------
	
	; WITH CTE_CalcSuppressions
	AS (
		SELECT 
		   cpp.[PartyID]
		  ,cpp.EventCategoryID
		  ,CASE WHEN ISNULL(cp.PartyUnsubscribe, 0) = 1 THEN 1 WHEN UpdateSource = 'Initial Setup' THEN ISNULL(acps.[PartySuppression], 0) ELSE ISNULL(acps.[SuppliedPartySuppression], 0) END AS CalcPartySuppression
		  ,CASE WHEN acps.UpdateSource = 'Initial Setup' THEN ISNULL(acps.PostalSuppression, 0) ELSE ISNULL(acps.[SuppliedPostalSuppression], 0) END AS CalcPostalSuppression
		  ,CASE WHEN acps.UpdateSource = 'Initial Setup' THEN ISNULL(acps.EmailSuppression, 0) ELSE ISNULL(acps.[SuppliedEmailSuppression], 0) END   AS CalcEmailSuppression
		  ,CASE WHEN acps.UpdateSource = 'Initial Setup' THEN ISNULL(acps.PhoneSuppression, 0) ELSE ISNULL(acps.[SuppliedPhoneSuppression], 0) END   AS CalcPhoneSuppression
		FROM #ContactPreferencePartiesBySurvey cpp 
		LEFT JOIN [$(SampleDB)].Party.ContactPreferences cp ON cp.PartyID = cpp.PartyID
		LEFT JOIN [$(AuditDB)].Audit.ContactPreferencesBySurvey acps  -- left join here so that we can still populate with zero's if there are no values here to roll up 
							ON  acps.AuditItemID = (SELECT MAX(AuditItemID)  -- get the latest value remaining on file after we ignore the rollback and customer update records
													FROM [$(AuditDB)].Audit.ContactPreferencesBySurvey acps
													  WHERE acps.PartyID = cpp.PartyID 
													  AND acps.EventCategoryID = cpp.EventCategoryID
													  AND (SuppliedPartyUnsubscribe <> 1 OR UpdateSource <> 'Customer Update')  -- Ignore Customer Update Unsubscribes
													  AND ISNULL(RollbackIndicator,0) = 0										-- Ignore records that have been flagged as roll back
													)
		WHERE  cpp.ContactPreferencesPersist = 0		-- Non-persist Markets
	)
	INSERT INTO #ContactPreferenceAdjustmentsBySurvey (
												PartyID					,
												EventCategoryID			, 
												CalcPartySuppression	,
												CalcPostalSuppression	,
												CalcEmailSuppression	,
												CalcPhoneSuppression	
											)
	SELECT	csa.PartyID, 
			csa.EventCategoryID,
			csa.CalcPartySuppression ,
			csa.CalcPostalSuppression,
			csa.CalcEmailSuppression ,
			csa.CalcPhoneSuppression
	FROM CTE_CalcSuppressions csa
	INNER JOIN [$(SampleDB)].Party.ContactPreferencesBySurvey cp ON cp.PartyID = csa.PartyID AND cp.EventCategoryID = csa.EventCategoryID 
	WHERE   ISNULL(cp.PartySuppression, 0)  <> csa.CalcPartySuppression
	     OR ISNULL(cp.PostalSuppression, 0) <> csa.CalcPostalSuppression
		 OR ISNULL(cp.PhoneSuppression, 0)  <> csa.CalcPhoneSuppression
		 OR ISNULL(cp.EmailSuppression, 0)  <> csa.CalcEmailSuppression

	


	--------------------------------------------------------------------------------------------------------------------------------
	-- Now apply any required adjustments to the Contact Preferences tables and audit them.
	--------------------------------------------------------------------------------------------------------------------------------

	-- Only run, if we actually have some adjustments to apply  --------------------------------------------------
	IF 0 < (SELECT COUNT(*) FROM #ContactPreferenceAdjustments)
	OR 0 < (SELECT COUNT(*) FROM #ContactPreferenceAdjustmentsBySurvey)
	BEGIN

		-- First save records to rollback audit before updating ----------------------------------
		INSERT INTO [$(AuditDB)].RollbackSample.ContactPreferences (AuditID, PartyID, PartySuppression, PostalSuppression, EmailSuppression, PhoneSuppression, PartyUnsubscribe, UpdateDate)
		SELECT @AuditID, cp.PartyID, cp.PartySuppression, cp.PostalSuppression, cp.EmailSuppression, cp.PhoneSuppression, cp.PartyUnsubscribe, cp.UpdateDate
		FROM #ContactPreferenceAdjustments cpa
		INNER JOIN [$(SampleDB)].Party.ContactPreferences cp ON cp.PartyID = cpa.PartyID

		INSERT INTO [$(AuditDB)].RollbackSample.ContactPreferencesBySurvey (AuditID, PartyID, EventCategoryID, PartySuppression, PostalSuppression, EmailSuppression, PhoneSuppression, UpdateDate)
		SELECT @AuditID, cpbs.PartyID, cpbs.EventCategoryID, cpbs.PartySuppression, cpbs.PostalSuppression, cpbs.EmailSuppression, cpbs.PhoneSuppression, cpbs.UpdateDate
		FROM #ContactPreferenceAdjustmentsBySurvey cpbsa
		INNER JOIN [$(SampleDB)].Party.ContactPreferencesBySurvey cpbs ON cpbs.PartyID = cpbsa.PartyID AND cpbs.EventCategoryID = cpbsa.EventCategoryID 

	
		-- Populate working variables ----------------------------------------------------------
		DECLARE @MaxContactPrefAdjID			INT,
				@MaxContactPrefAdjBySurveyID	INT
				
		SELECT @MaxAuditID = MAX(AuditID)			FROM [$(AuditDB)].dbo.Audit
		SELECT @MaxAuditItemID = MAX(AuditItemID)	FROM [$(AuditDB)].dbo.AuditItems
	
		SELECT @MaxContactPrefAdjID = ISNULL(MAX(ID),0)				FROM #ContactPreferenceAdjustments
		SELECT @MaxContactPrefAdjBySurveyID = ISNULL(MAX(ID), 0)	FROM #ContactPreferenceAdjustmentsBySurvey


		-- Create the Audit and dbo.File records----------------------------------------------------

		DECLARE @ContactPrefAdjFileAuditID BIGINT
		SET @ContactPrefAdjFileAuditID = @MaxAuditID +1

		INSERT INTO [$(AuditDB)].dbo.Audit (AuditID)
		SELECT @ContactPrefAdjFileAuditID
	
		INSERT INTO [$(AuditDB)].dbo.Files (AuditID, FileTypeID, FileName, FileRowCount, ActionDate)
		SELECT @ContactPrefAdjFileAuditID,
			   (SELECT FileTypeID FROM [$(AuditDB)].[dbo].[FileTypes]
			    WHERE FileType = 'Internal System Update') AS FileTypeID,
			   ('Bug ' + @BugNumberText + ' : Adjustments to Contact Preferences.  Rollback AuditID: ' + CAST(@AuditID AS VARCHAR(10))) AS Filename,
				(@MaxContactPrefAdjID + @MaxContactPrefAdjBySurveyID) AS FileRowCount,
			   @UpdateDate AS ActionDate


		-- Create the required AuditItemIDs ------------------------------------------------------
		INSERT INTO [$(AuditDB)].dbo.AuditItems (AuditID, AuditItemID)
		SELECT	@ContactPrefAdjFileAuditID,
				@MaxAuditItemID + ID
		FROM #ContactPreferenceAdjustments

		INSERT INTO [$(AuditDB)].dbo.AuditItems (AuditID, AuditItemID)
		SELECT	@ContactPrefAdjFileAuditID,
				@MaxAuditItemID + @MaxContactPrefAdjID + ID
		FROM #ContactPreferenceAdjustmentsBySurvey


		-- Update the contact preference records --------------------------------------------------
		
		UPDATE cp
		SET PartySuppression  = cpa.CalcPartySuppression,
			PostalSuppression = cpa.CalcPostalSuppression,
			PhoneSuppression  = cpa.CalcPhoneSuppression,
			EmailSuppression  = cpa.CalcEmailSuppression,
			UpdateDate = @UpdateDate
		FROM #ContactPreferenceAdjustments cpa
		INNER JOIN [$(SampleDB)].Party.ContactPreferences cp ON cp.PartyID = cpa.PartyID
		
		UPDATE cpbs
		SET PartySuppression  = cpbsa.CalcPartySuppression,
			PostalSuppression = cpbsa.CalcPostalSuppression,
			PhoneSuppression  = cpbsa.CalcPhoneSuppression,
			EmailSuppression  = cpbsa.CalcEmailSuppression,
			UpdateDate = @UpdateDate
		FROM #ContactPreferenceAdjustmentsBySurvey cpbsa
		INNER JOIN [$(SampleDB)].Party.ContactPreferencesBySurvey cpbs ON cpbs.PartyID = cpbsa.PartyID AND cpbs.EventCategoryID = cpbsa.EventCategoryID 


		-- Populate the Contact Preference Audit tables with the adjustment udpdates ------------

		INSERT INTO [$(AuditDB)].Audit.ContactPreferences (AuditItemID, 
															PartyID, 
															PartySuppression, 
															PostalSuppression, 
															EmailSuppression, 
															PhoneSuppression, 
															UpdateDate, 
															UpdateSource, 
															ContactPreferencesPersist, 
															OverridePreferences, 
															RollbackIndicator, 
															Comments)
		SELECT	@MaxAuditItemID + ID AS AuditItemID,
				PartyID, 
				CalcPartySuppression, 
				CalcPostalSuppression, 
				CalcEmailSuppression, 
				CalcPhoneSuppression, 
				@UpdateDate, 
				'SampleFileRollback Adjustment' UpdateSource, 
				0 AS ContactPreferencesPersist, 
				1 AS OverridePreferences, 
				1 AS RollbackIndicator,			-- This is set to ensure that we do not take this adjustment into account in further rollback calculations
				'Bug: ' + @BugNumberText + ' - Rollback ' + @Filename AS Comments
		FROM #ContactPreferenceAdjustments

		
		-- Populate the Contact Preference Audit tables with the adjustment udpdates ------------

		INSERT INTO [$(AuditDB)].Audit.ContactPreferencesBySurvey (AuditItemID, 
																	PartyID, 
																	EventCategoryID,
																	PartySuppression, 
																	PostalSuppression, 
																	EmailSuppression, 
																	PhoneSuppression, 
																	UpdateDate, 
																	UpdateSource,
																	MarketCountryID,
																	SampleMarketID,
																	ContactPreferencesPersist, 
																	OverridePreferences, 
																	RollbackIndicator, 
																	Comments)
		SELECT	@MaxAuditItemID + @MaxContactPrefAdjID + adj.ID AS AuditItemID,
				adj.PartyID, 
				adj.EventCategoryID,
				adj.CalcPartySuppression, 
				adj.CalcPostalSuppression, 
				adj.CalcEmailSuppression, 
				adj.CalcPhoneSuppression, 
				@UpdateDate, 
				'SampleFileRollback Adjustment' UpdateSource, 
				cpbs.CountryID,
				cpbs.MarketID,
				0 AS ContactPreferencesPersist, 
				1 AS OverridePreferences, 
				1 AS RollbackIndicator,			-- This is set to ensure that we do not take this adjustment into account in further rollback calculations
				'Bug: ' + @BugNumberText + ' - Rollback ' + @Filename AS Comments
		FROM #ContactPreferenceAdjustmentsBySurvey adj
		INNER JOIN #ContactPreferencePartiesBySurvey cpbs ON cpbs.PartyID = adj.PartyID AND cpbs.EventCategoryID = adj.EventCategoryID  -- Link to this table for the Market and Country IDs

	END -- End of conditional code - where adjustments exist -------------------------------------------------------------------------------





	-----------------------------------------------------------------------------------------------------------------------------
	-----------------------------------------------------------------------------------------------------------------------------
	--  Remove VehiclePartyRoleEvents records so that Customers are dissasociated from Events and cannot get matched via Vehicle
	--
	-- Note: Have left the Vehicle.VehiclePartyRoles out as we cannot reliably link to it as the FromDates do not exactly match up,
	--       even from Audit.  Also, this table is not used for anything (also, we do not delete in the original reverse scripts).
	-----------------------------------------------------------------------------------------------------------------------------
	-----------------------------------------------------------------------------------------------------------------------------

	-- Save records prior to removing them
	INSERT INTO [$(AuditDB)].RollbackSample.VehiclePartyRoleEvents (AuditID, VehiclePartyRoleEventID, EventID, PartyID, VehicleRoleTypeID, VehicleID, FromDate, AFRLCode)
	SELECT DISTINCT FRI.AuditID, VPRE.VehiclePartyRoleEventID, VPRE.EventID, VPRE.PartyID, VPRE.VehicleRoleTypeID, VPRE.VehicleID, VPRE.FromDate, VPRE.AFRLCode
	FROM #FileRowsInfo FRI 
	INNER JOIN [$(SampleDB)].Vehicle.VehiclePartyRoleEvents vpre ON vpre.EventID = FRI.EventID


	-- Remove records from Vehicle Party Roles events table
	DELETE vpre 
	FROM #FileRowsInfo FRI 
	INNER JOIN [$(SampleDB)].Vehicle.VehiclePartyRoleEvents vpre ON vpre.EventID = FRI.EventID




	-----------------------------------------------------------------------------------------------------------------------------
	-----------------------------------------------------------------------------------------------------------------------------
	-- Dissasociate ContactMechanisms from PartyIDs 
	-----------------------------------------------------------------------------------------------------------------------------
	-----------------------------------------------------------------------------------------------------------------------------
	
	
	-----------------------------------------------------------------------------------------------------------------------------
	-- First get the Party/ContactMechanisms associations via the PartyContactMechanisms table
	-----------------------------------------------------------------------------------------------------------------------------

	IF OBJECT_ID('tempdb..#PartyContactMechanisms') IS NOT NULL
		DROP TABLE #PartyContactMechanisms

	CREATE TABLE #PartyContactMechanisms
		(
			PartyID					BIGINT,
			ContactMechanismID		BIGINT
		)

	INSERT INTO #PartyContactMechanisms (PartyID, ContactMechanismID)
	SELECT DISTINCT pcm.PartyID, pcm.ContactMechanismID
	FROM #FileRowsInfo FRI
	INNER JOIN [$(AuditDB)].[Audit].[PartyContactMechanisms] pcm ON pcm.AuditItemID = FRI.AuditItemID


	IF OBJECT_ID('tempdb..#PartyContactMechanismPurposes') IS NOT NULL
		DROP TABLE #PartyContactMechanismPurposes

	CREATE TABLE #PartyContactMechanismPurposes 
		(
			PartyID					BIGINT,
			ContactMechanismID		BIGINT,
			ContactMechanismPurposeTypeID INT
		)

	INSERT INTO #PartyContactMechanismPurposes (PartyID, ContactMechanismID, ContactMechanismPurposeTypeID)
	SELECT DISTINCT PCM.PartyID, PCM.ContactMechanismID, PCM.ContactMechanismPurposeTypeID
	FROM #FileRowsInfo FRI
	INNER JOIN [$(AuditDB)].[Audit].PartyContactMechanismPurposes pcm ON pcm.AuditItemID = FRI.AuditItemID





	------------------------------------------------------------------------------------------------------------------------------------
	-- Now set the PartyID and ContactMechanismIDs to minus values for each Contact Mechanism in Audit.  
	-- This keeps the same IDs for references but means they can't match to anything
	------------------------------------------------------------------------------------------------------------------------------------

	-- Save the recs to rollback Audit before updating 
	INSERT INTO [$(AuditDB)].RollbackSample.Audit_PartyContactMechanisms (AuditID, AuditItemID, ContactMechanismID, PartyID, RoleTypeID, FromDate, ThroughDate)
	SELECT FRI.AuditID, pcm.AuditItemID, pcm.ContactMechanismID, pcm.PartyID, pcm.RoleTypeID, pcm.FromDate, pcm.ThroughDate
	FROM #FileRowsInfo FRI
	INNER JOIN [$(AuditDB)].[Audit].[PartyContactMechanisms] pcm ON pcm.AuditItemID = FRI.AuditItemID
															
	INSERT INTO [$(AuditDB)].RollbackSample.Audit_PartyContactMechanismPurposes (AuditID, AuditItemID, ContactMechanismID, PartyID, ContactMechanismPurposeTypeID, FromDate, ThroughDate)
	SELECT FRI.AuditID, pcm.AuditItemID, pcm.ContactMechanismID, pcm.PartyID, pcm.ContactMechanismPurposeTypeID, pcm.FromDate, pcm.ThroughDate
	FROM #FileRowsInfo FRI
	INNER JOIN [$(AuditDB)].[Audit].[PartyContactMechanismPurposes] pcm ON pcm.AuditItemID = FRI.AuditItemID
															
	-- Set the IDs to negative values
	UPDATE pcm
	SET PartyID = 0 - ABS(pcm.PartyID),
		ContactMechanismID = 0 - ABS(pcm.ContactMechanismID) 
	FROM #FileRowsInfo FRI
	INNER JOIN [$(AuditDB)].[Audit].[PartyContactMechanisms] pcm ON pcm.AuditItemID = FRI.AuditItemID

	UPDATE pcm
	SET PartyID = 0 - ABS(pcm.PartyID),
		ContactMechanismID = 0 - ABS(pcm.ContactMechanismID)  
	FROM #FileRowsInfo FRI
	INNER JOIN [$(AuditDB)].[Audit].[PartyContactMechanismPurposes] pcm ON pcm.AuditItemID = FRI.AuditItemID


	------------------------------------------------------------------------------------------------------------------------------------
	-- Now check to see if this Party Contact Mechanism combo still exists on any other Audit Records.  
	-- If not, then assume we can remove the connection in the main Sample database.  
	-- Note: this is (very slightly) potentially dodgy as other mods of the PartyContactMechnism table or Audit could have happened.
	--       However, we are working on the assumption that this is extremely unlikely as these are recently loaded files and any new loaded 
	--       records will reconstitute the connection anyway and, at worst, create a new Customer PartyID.
	------------------------------------------------------------------------------------------------------------------------------------

	-- SAVE the recs to rollback audit before updating 
	INSERT INTO [$(AuditDB)].RollbackSample.PartyContactMechanisms (AuditID, ContactMechanismID, PartyID, RoleTypeID, FromDate)
	SELECT @AuditID, pcm.ContactMechanismID, pcm.PartyID, pcm.RoleTypeID, pcm.FromDate
	FROM #PartyContactMechanisms t
	INNER JOIN [$(SampleDB)].ContactMechanism.PartyContactMechanisms pcm 
					  ON pcm.PartyID = t.PartyID 
					  AND pcm.ContactMechanismID = t.ContactMechanismID
	WHERE NOT EXISTS (SELECT apcm.PartyID FROM [$(AuditDB)].Audit.PartyContactMechanisms apcm 
					  WHERE apcm.PartyID = t.PartyID 
					  AND apcm.ContactMechanismID = t.ContactMechanismID)


	INSERT INTO [$(AuditDB)].RollbackSample.PartyContactMechanismPurposes (AuditID, ContactMechanismID, PartyID, ContactMechanismPurposeTypeID, FromDate)
	SELECT @AuditID, pcm.ContactMechanismID, pcm.PartyID, pcm.ContactMechanismPurposeTypeID, pcm.FromDate
	FROM #PartyContactMechanismPurposes t
	INNER JOIN [$(SampleDB)].ContactMechanism.[PartyContactMechanismPurposes] pcm 
					  ON pcm.PartyID = t.PartyID 
					  AND pcm.ContactMechanismID = t.ContactMechanismID
					  AND pcm.ContactMechanismPurposeTypeID = t.ContactMechanismPurposeTypeID 
	WHERE NOT EXISTS (SELECT apcm.PartyID FROM [$(AuditDB)].[Audit].[PartyContactMechanismPurposes] apcm 
					  WHERE apcm.PartyID = t.PartyID 
					  AND apcm.ContactMechanismID = t.ContactMechanismID
					  AND apcm.ContactMechanismPurposeTypeID = t.ContactMechanismPurposeTypeID)



	-- Now REMOVE the PartyContactMechanism link records where appropriate
	DELETE pcm
	FROM #PartyContactMechanisms t
	INNER JOIN [$(SampleDB)].ContactMechanism.PartyContactMechanisms pcm 
					  ON pcm.PartyID = t.PartyID 
					  AND pcm.ContactMechanismID = t.ContactMechanismID
	WHERE NOT EXISTS (SELECT apcm.PartyID FROM [$(AuditDB)].[Audit].[PartyContactMechanisms] apcm 
					  WHERE apcm.PartyID = t.PartyID 
					  AND apcm.ContactMechanismID = t.ContactMechanismID
					  )


	DELETE pcm
	FROM #PartyContactMechanismPurposes t
	INNER JOIN [$(SampleDB)].ContactMechanism.PartyContactMechanismPurposes pcm 
					  ON pcm.PartyID = t.PartyID 
					  AND pcm.ContactMechanismID = t.ContactMechanismID
					  AND pcm.ContactMechanismPurposeTypeID = t.ContactMechanismPurposeTypeID 
	WHERE NOT EXISTS (SELECT apcm.PartyID FROM [$(AuditDB)].[Audit].PartyContactMechanismPurposes apcm 
					  WHERE apcm.PartyID = t.PartyID 
					  AND apcm.ContactMechanismID = t.ContactMechanismID
					  AND apcm.ContactMechanismPurposeTypeID = t.ContactMechanismPurposeTypeID
					  )





	-----------------------------------------------------------------------------------------------------------------------------
	-----------------------------------------------------------------------------------------------------------------------------
	-- Update Organisation names 
	-----------------------------------------------------------------------------------------------------------------------------
	-----------------------------------------------------------------------------------------------------------------------------
	
	-- Save the PartyIDs and Organisation Names for updating 
	IF OBJECT_ID('tempdb..#Organisations') IS NOT NULL
		DROP TABLE #Organisations

	CREATE TABLE #Organisations
		(
			PartyID					BIGINT,
			OrganisationName		NVARCHAR(510)
		)

	INSERT INTO #Organisations (PartyID, OrganisationName)
	SELECT DISTINCT ao.PartyID, ao.OrganisationName
	FROM #FileRowsInfo FRI 
	INNER JOIN [$(AuditDB)].Audit.Organisations ao ON ao.AuditItemID = FRI.AuditItemID



	-------------------------------------------------------------------------------------------------------------------------------------
	-- Update Organisation names in Audit so we can see those records which were erroneously loaded and potentially matched.
	-- 
	-- If there no other unchanged records in Audit linked to that PartyID we can assume it can also be safely changed in the main Connexions tables.
	-- This means that any future records loaded will not be linked to any of the the erroneously loaded file data in Audit.
	------------------------------------------------------------------------------------------------------------------------------------
 
	-- Save the Audit Records prior to update
	INSERT INTO [$(AuditDB)].RollbackSample.Audit_Organisations (AuditID, AuditItemID, PartyID, FromDate, OrganisationName)
	SELECT DISTINCT FRI.AuditID, ao.AuditItemID, ao.PartyID, ao.FromDate, ao.OrganisationName
	FROM #FileRowsInfo FRI 
	INNER JOIN [$(AuditDB)].Audit.Organisations ao ON ao.AuditItemID = FRI.AuditItemID

	INSERT INTO [$(AuditDB)].RollbackSample.Audit_LegalOrganisations (AuditID, AuditItemID, PartyID, LegalName) 
	SELECT DISTINCT FRI.AuditID, lo.AuditItemID, lo.PartyID, lo.LegalName
	FROM #FileRowsInfo FRI 
	INNER JOIN [$(AuditDB)].Audit.LegalOrganisations lo ON lo.AuditItemID = FRI.AuditItemID

	
	-- Rename the organisation names in Audit
	UPDATE ao
	SET ao.OrganisationName = ao.OrganisationName + @SuffixText
	FROM #FileRowsInfo FRI 
	INNER JOIN [$(AuditDB)].Audit.Organisations ao ON ao.AuditItemID = FRI.AuditItemID

	-- Rename the org legal names in Audit
	UPDATE lo
	SET lo.LegalName = lo.LegalName + @SuffixText
	FROM #FileRowsInfo FRI 
	INNER JOIN [$(AuditDB)].Audit.LegalOrganisations lo ON lo.AuditItemID = FRI.AuditItemID



	---------------------------------------------------------------------------------------------------------------------------------------
	-- If the Party and original Organisation name is no longer found in Audit then we can rename in the main connexions tables as well
	---------------------------------------------------------------------------------------------------------------------------------------
	
	-- Save to audit prior to update
	INSERT INTO [$(AuditDB)].RollbackSample.Organisations (AuditID, PartyID, OrganisationName, MergedDate, ParentFlag, ParentFlagDate, UnMergedDate)
	SELECT @AuditID, o.PartyID, o.OrganisationName, o.MergedDate, o.ParentFlag, o.ParentFlagDate, o.UnMergedDate
	FROM #Organisations t
	INNER JOIN [$(SampleDB)].Party.Organisations o ON o.PartyID = t.PartyID
										   AND o.OrganisationName = t.OrganisationName
	WHERE NOT EXISTS (SELECT * FROM [$(AuditDB)].Audit.Organisations ao2 
						WHERE ao2.PartyID = t.PartyID						-- where the partyID 
						AND ao2.OrganisationName = t.OrganisationName		-- and OrgName exists in Audit
					 )

	INSERT INTO [$(AuditDB)].RollbackSample.LegalOrganisations (AuditID, PartyID, LegalName)
	SELECT ro.AuditID, lo.PartyID, lo.LegalName
	FROM [$(AuditDB)].RollbackSample.Organisations ro 
	INNER JOIN [$(SampleDB)].Party.LegalOrganisations lo ON lo.PartyID = ro.PartyID
	WHERE ro.AuditID = @AuditID



	-- Rename the Organisation Names
	UPDATE o
	SET o.OrganisationName = o.OrganisationName + @SuffixText
	FROM [$(AuditDB)].RollbackSample.Organisations ro 
	INNER JOIN [$(SampleDB)].Party.Organisations o ON o.PartyID = ro.PartyID
	WHERE ro.AuditID = @AuditID

	-- Rename the Legal Names
	UPDATE lo
	SET lo.LegalName = lo.LegalName + @SuffixText
	FROM [$(AuditDB)].RollbackSample.Organisations ro 
	INNER JOIN [$(SampleDB)].Party.LegalOrganisations lo ON lo.PartyID = ro.PartyID
	WHERE ro.AuditID = @AuditID




	-----------------------------------------------------------------------------------------------------------------------------
	-----------------------------------------------------------------------------------------------------------------------------
	-- Update People names 
	-----------------------------------------------------------------------------------------------------------------------------
	-----------------------------------------------------------------------------------------------------------------------------
	
	-- Save the PartyIDs and LastNames for updating 
	IF OBJECT_ID('tempdb..#People') IS NOT NULL
		DROP TABLE #People

	CREATE TABLE #People
		(
			PartyID					BIGINT,
			LastName				NVARCHAR(510)
		)

	INSERT INTO #People (PartyID, LastName)
	SELECT DISTINCT ao.PartyID, ao.LastName
	FROM #FileRowsInfo FRI 
	INNER JOIN [$(AuditDB)].Audit.People ao ON ao.AuditItemID = FRI.AuditItemID



	-------------------------------------------------------------------------------------------------------------------------------------
	-- Update People last names in Audit so we can see those records which were erroneously loaded and potentially matched.
	-- 
	-- If there no other unchanged records in Audit linked to that PartyID we can assume it can also be safely changed in the main Connexions tables.
	-- This means that any future records loaded will not be linked to any of the the erroneously loaded file data in Audit.
	------------------------------------------------------------------------------------------------------------------------------------
 
	-- Save the Audit Records prior to update
	INSERT INTO [$(AuditDB)].RollbackSample.Audit_People (AuditID, AuditItemID, PartyID, FromDate, TitleID, Title, Initials, FirstName, FirstNameOrig, 
														  MiddleName, LastName, LastNameOrig, SecondLastName, SecondLastNameOrig, GenderID, BirthDate, MonthAndYearOfBirth, PreferredMethodOfContact)
	SELECT DISTINCT FRI.AuditID, ap.AuditItemID, ap.PartyID, ap.FromDate, ap.TitleID, ap.Title, ap.Initials, ap.FirstName, ap.FirstNameOrig, 
								 ap.MiddleName, ap.LastName, ap.LastNameOrig, ap.SecondLastName, ap.SecondLastNameOrig, ap.GenderID, ap.BirthDate, ap.MonthAndYearOfBirth, ap.PreferredMethodOfContact
	FROM #FileRowsInfo FRI 
	INNER JOIN [$(AuditDB)].Audit.People ap ON ap.AuditItemID = FRI.AuditItemID

	
	-- Rename the Last Names in Audit
	UPDATE ap
	SET ap.LastName = ap.LastName + @SuffixText
	FROM #FileRowsInfo FRI 
	INNER JOIN [$(AuditDB)].Audit.People ap ON ap.AuditItemID = FRI.AuditItemID



	---------------------------------------------------------------------------------------------------------------------------------------
	-- If the Party and Original Person name is no longer found in Audit then we can rename in the main connexions table as well
	---------------------------------------------------------------------------------------------------------------------------------------
	
	-- Save to audit prior to update
	INSERT INTO [$(AuditDB)].RollbackSample.People (AuditID, PartyID, FromDate, TitleID, Initials, FirstName, MiddleName, LastName, SecondLastName, 
													GenderID, BirthDate, MonthAndYearOfBirth, PreferredMethodOfContact, 
													MergedDate, ParentFlag, ParentFlagDate, UnMergedDate)
	SELECT @AuditID, p.PartyID, p.FromDate, p.TitleID, p.Initials, p.FirstName, p.MiddleName, p.LastName, p.SecondLastName, 
					p.GenderID, p.BirthDate, p.MonthAndYearOfBirth, p.PreferredMethodOfContact, 
					p.MergedDate, p.ParentFlag, p.ParentFlagDate, p.UnMergedDate
	FROM #People t
	INNER JOIN [$(SampleDB)].Party.People p ON p.PartyID = t.PartyID
									AND p.LastName = t.LastName
	WHERE NOT EXISTS (SELECT * FROM [$(AuditDB)].Audit.People ap2 
						WHERE ap2.PartyID = t.PartyID				-- where the partyID 
						AND ap2.LastName = t.LastName				-- and LastName exists in Audit
					 )


	-- Rename the Last Names
	UPDATE p
	SET p.LastName = p.LastName + @SuffixText
	FROM [$(AuditDB)].RollbackSample.People rp 
	INNER JOIN [$(SampleDB)].Party.People p ON p.PartyID = rp.PartyID
	WHERE rp.AuditID = @AuditID




	-----------------------------------------------------------------------------------------------------------------------------
	-----------------------------------------------------------------------------------------------------------------------------
	-- Update Customer Identifiers (CustomerRelationships table)
	-----------------------------------------------------------------------------------------------------------------------------
	-----------------------------------------------------------------------------------------------------------------------------
	
	-- Save the PartyIDs and IDs for updating 
	IF OBJECT_ID('tempdb..#CustomerRelationships') IS NOT NULL
		DROP TABLE #CustomerRelationships

	CREATE TABLE #CustomerRelationships
		(
			PartyIDFrom              BIGINT			,
			PartyIDTo                BIGINT			,
			RoleTypeIDFrom           INT			,
			RoleTypeIDTo             INT			,
			CustomerIdentifier       VARCHAR(60)
		)

	INSERT INTO #CustomerRelationships (PartyIDFrom       	 ,
										PartyIDTo         	 ,
										RoleTypeIDFrom    	 ,
										RoleTypeIDTo      	 ,
										CustomerIdentifier
										)
	SELECT DISTINCT PartyIDFrom       	 ,
					PartyIDTo         	 ,
					RoleTypeIDFrom    	 ,
					RoleTypeIDTo      	 ,
					CustomerIdentifier
	FROM #FileRowsInfo FRI 
	INNER JOIN [$(AuditDB)].Audit.CustomerRelationships ao ON ao.AuditItemID = FRI.AuditItemID



	-------------------------------------------------------------------------------------------------------------------------------------
	-- Update Customer Identifiers in Audit so we can see those records which were erroneously loaded and potentially matched.
	-- 
	-- If there no other unchanged records in Audit linked to that PartyID we can assume it can also be safely changed in the main Connexions table.
	-- This means that any future records loaded will not be linked via the Customer Identifier to any of the the erroneously loaded file data in Audit.
	------------------------------------------------------------------------------------------------------------------------------------
 
	-- Save the Audit Records prior to update
	INSERT INTO [$(AuditDB)].RollbackSample.Audit_CustomerRelationships (AuditID, AuditItemID, PartyIDFrom, PartyIDTo, RoleTypeIDFrom, RoleTypeIDTo, CustomerIdentifier, CustomerIdentifierUsable)
	SELECT DISTINCT FRI.AuditID, cr.AuditItemID, cr.PartyIDFrom, cr.PartyIDTo, cr.RoleTypeIDFrom, cr.RoleTypeIDTo, cr.CustomerIdentifier, cr.CustomerIdentifierUsable
	FROM #FileRowsInfo FRI 
	INNER JOIN [$(AuditDB)].Audit.CustomerRelationships cr ON cr.AuditItemID = FRI.AuditItemID

	
	-- Rename the Customer Identifiers in Audit
	UPDATE cr
	SET cr.CustomerIdentifier = cr.CustomerIdentifier + @SuffixText
	FROM #FileRowsInfo FRI 
	INNER JOIN [$(AuditDB)].Audit.CustomerRelationships cr ON cr.AuditItemID = FRI.AuditItemID



	-------------------------------------------------------------------------------------------------------------------------------------------------------
	-- If the Parties, Roles and Original Customer Identifier combinations no longer exist in Audit then we can remove from the main connexions table 
	-------------------------------------------------------------------------------------------------------------------------------------------------------
	
	-- Save to audit prior to update
	INSERT INTO [$(AuditDB)].RollbackSample.CustomerRelationships (AuditID, PartyIDFrom, PartyIDTo, RoleTypeIDFrom, RoleTypeIDTo, CustomerIdentifier, CustomerIdentifierUsable)
	SELECT @AuditID, cr.PartyIDFrom, cr.PartyIDTo, cr.RoleTypeIDFrom, cr.RoleTypeIDTo, cr.CustomerIdentifier, cr.CustomerIdentifierUsable
	FROM #CustomerRelationships t
	INNER JOIN [$(SampleDB)].Party.CustomerRelationships cr ON	cr.PartyIDFrom       	= t.PartyIDFrom       	
														AND	cr.PartyIDTo         	= t.PartyIDTo         	
														AND	cr.RoleTypeIDFrom    	= t.RoleTypeIDFrom    	
														AND	cr.RoleTypeIDTo      	= t.RoleTypeIDTo      	
														AND	cr.CustomerIdentifier	= t.CustomerIdentifier
	WHERE NOT EXISTS (SELECT * FROM [$(AuditDB)].Audit.CustomerRelationships cr2 
						WHERE    cr2.PartyIDFrom       	= t.PartyIDFrom       	
							AND	 cr2.PartyIDTo         	= t.PartyIDTo         	
							AND	 cr2.RoleTypeIDFrom    	= t.RoleTypeIDFrom    	
							AND	 cr2.RoleTypeIDTo      	= t.RoleTypeIDTo      	
							AND	 cr2.CustomerIdentifier	= t.CustomerIdentifier
					 )


	-- Remove the entire Customer Relationship record
	DELETE cr
	FROM [$(AuditDB)].RollbackSample.CustomerRelationships rcr 
	INNER JOIN [$(SampleDB)].Party.CustomerRelationships cr ON 	cr.PartyIDFrom       	= rcr.PartyIDFrom       	
														AND	cr.PartyIDTo         	= rcr.PartyIDTo         	
														AND	cr.RoleTypeIDFrom    	= rcr.RoleTypeIDFrom    	
														AND	cr.RoleTypeIDTo      	= rcr.RoleTypeIDTo      	
														AND	cr.CustomerIdentifier	= rcr.CustomerIdentifier
	WHERE rcr.AuditID = @AuditID



	-----------------------------------------------------------------------------------------------------------------------------
	-----------------------------------------------------------------------------------------------------------------------------
	-- Remove any un-actioned Warranty, CRC or Roadside staging table entries, so that they are not accidentally loaded at 
	-- a future date.
	-----------------------------------------------------------------------------------------------------------------------------
	-----------------------------------------------------------------------------------------------------------------------------


	-----------------------------------------------------------------------------------------------------------------------------
	-- CRCEvents  (this step should be unecessary if the record is not loaded on initial load then it shouldn't load in future, 
	--				however, rather than leave any records with DateTransferredToVWT as NULL and the potential that they get 
	--				loaded later, I have decided set the DateTransferredToVWT value and ensure they can never be picked up)
	-----------------------------------------------------------------------------------------------------------------------------
	

	-- Save records prior to modifying them
	INSERT INTO [$(AuditDB)].RollbackSample.CRCEvents (AuditID, CRC_ID, AuditItemID, PhysicalRowID, ODSEventID, DateTransferredToVWT, CRCCode, MarketCode, BrandCode, RunDateofExtract, ExtractFromDate, ExtractToDate, ContactId, AssetId, CustomerLanguageCode, UniqueCustomerId, VehicleRegNumber, VIN, VehicleModel, VehicleDerivative, VehicleMileage, VehicleMonthsinService, CustomerTitle, CustomerInitial, CustomerFirstName, CustomerLastName, AddressLine1, AddressLine2, AddressLine3, AddressLine4, City, County, Country, PostalCode, PhoneMobile, PhoneHome, EmailAddress, CompanyName, RowId, CaseNumber, SRCreatedDate, SRClosedDate, Owner, ClosedBy, Type, PrimaryReasonCode, SecondaryReasonCode, ConcernAreaCode, SymptomCode, NoOfSelectedContacts, Rule1, Rule2, C05, C07, C15, T06, T08, T13, Rule5, Rule6, Rule7a, Rule7b, Rule8, ConvertedSRCreatedDate, ConvertedSRClosedDate, PreferredLanguageID, SampleTriggeredSelectionReqID, COMPLETE_SUPPRESSION, SUPPRESSION_EMAIL, SUPPRESSION_PHONE, SUPPRESSION_MAIL)
	SELECT AuditID, CRC_ID, AuditItemID, PhysicalRowID, ODSEventID, DateTransferredToVWT, CRCCode, MarketCode, BrandCode, RunDateofExtract, ExtractFromDate, ExtractToDate, ContactId, AssetId, CustomerLanguageCode, UniqueCustomerId, VehicleRegNumber, VIN, VehicleModel, VehicleDerivative, VehicleMileage, VehicleMonthsinService, CustomerTitle, CustomerInitial, CustomerFirstName, CustomerLastName, AddressLine1, AddressLine2, AddressLine3, AddressLine4, City, County, Country, PostalCode, PhoneMobile, PhoneHome, EmailAddress, CompanyName, RowId, CaseNumber, SRCreatedDate, SRClosedDate, Owner, ClosedBy, Type, PrimaryReasonCode, SecondaryReasonCode, ConcernAreaCode, SymptomCode, NoOfSelectedContacts, Rule1, Rule2, C05, C07, C15, T06, T08, T13, Rule5, Rule6, Rule7a, Rule7b, Rule8, ConvertedSRCreatedDate, ConvertedSRClosedDate, PreferredLanguageID, SampleTriggeredSelectionReqID, COMPLETE_SUPPRESSION, SUPPRESSION_EMAIL, SUPPRESSION_PHONE, SUPPRESSION_MAIL
	FROM CRC.CRCEvents crc 
	WHERE crc.AuditID = @AuditID
	AND crc.DateTransferredToVWT is NULL


	-- Invalidate any outstanding records as they have not already been loaded.
	UPDATE crc
	SET DateTransferredToVWT = '1900-01-01'
	FROM CRC.CRCEvents crc 
	WHERE AuditID = @AuditID
	AND crc.DateTransferredToVWT is NULL



	-----------------------------------------------------------------------------------------------------------------------------
	-- IAssistanceEvents  (this step should be unecessary if the record is not loaded on initial load then it shouldn't load in future, 
	--				however, rather than leave any records with DateTransferredToVWT as NULL and the potential that they get 
	--				loaded later, I have decided set the DateTransferredToVWT value and ensure they can never be picked up)
	-----------------------------------------------------------------------------------------------------------------------------

	-- Save records prior to modifying them
	INSERT INTO [$(AuditDB)].RollbackSample.IAssistanceEvents ([IAssistanceID], [AuditID], [VWTID], [AuditItemID], [PhysicalRowID], [EventID], [Manufacturer], [ManufacturerID], [CountryCode], [CountryID], [EventType], [VehiclePurchaseDateOrig], [VehicleRegistrationDateOrig], [VehicleDeliveryDateOrig], [ServiceEventDateOrig], [DealerCode], [CustomerUniqueID], [CompanyName], [Title], [FirstName], [SurnameField1], [SurnameField2], [Salutation], [Address1], [Address2], [Address3], [Address4], [Address5(City)], [Address6(County)], [Address7(Postcode/Zipcode)], [Address8(Country)], [HomeTelephoneNumber], [BusinessTelephoneNumber], [MobileTelephoneNumber], [ModelName], [ModelYear], [VIN], [RegistrationNumber], [EmailAddress1], [EmailAddress2], [PreferredLanguage], [CompleteSuppression], [Suppression-Email], [Suppression-Phone], [Suppression-Mail], [InvoiceNumber], [InvoiceValue], [ServiceEmployeeCode], [EmployeeName], [OwnershipCycleOrig], [OwnershipCycle], [Gender], [PrivateOwner], [OwningCompany], [User/ChooserDriver], [EmployerCompany], [MonthAndYearOfBirth], [PreferredMethodsOfContact], [PermissionsForContact], [DataSource], [IAssistanceProvider], [IAssistanceCallID], [IAssistanceCallStartDate], [IAssistanceCallStartDateOrig], [IAssistanceCallCloseDate], [IAssistanceCallCloseDateOrig], [IAssistanceHelpdeskAdvisorName], [IAssistanceHelpdeskAdvisorID], [IAssistanceCallMethod], [CountryCodeISOAlpha2], [PreferredLanguageID], [PerformNormalVWTLoadFlag], [MatchedODSVehicleID], [MatchedODSPersonID], [MatchedODSOrganisationID], [MatchedODSEmailAddress1ID], [MatchedODSEmailAddress2ID], [MatchedODSMobileTelephoneNumberID], [DateTransferredToVWT], [SampleTriggeredSelectionReqID])
	SELECT [IAssistanceID], [AuditID], [VWTID], [AuditItemID], [PhysicalRowID], [EventID], [Manufacturer], [ManufacturerID], [CountryCode], [CountryID], [EventType], [VehiclePurchaseDateOrig], [VehicleRegistrationDateOrig], [VehicleDeliveryDateOrig], [ServiceEventDateOrig], [DealerCode], [CustomerUniqueID], [CompanyName], [Title], [FirstName], [SurnameField1], [SurnameField2], [Salutation], [Address1], [Address2], [Address3], [Address4], [Address5(City)], [Address6(County)], [Address7(Postcode/Zipcode)], [Address8(Country)], [HomeTelephoneNumber], [BusinessTelephoneNumber], [MobileTelephoneNumber], [ModelName], [ModelYear], [VIN], [RegistrationNumber], [EmailAddress1], [EmailAddress2], [PreferredLanguage], [CompleteSuppression], [Suppression-Email], [Suppression-Phone], [Suppression-Mail], [InvoiceNumber], [InvoiceValue], [ServiceEmployeeCode], [EmployeeName], [OwnershipCycleOrig], [OwnershipCycle], [Gender], [PrivateOwner], [OwningCompany], [User/ChooserDriver], [EmployerCompany], [MonthAndYearOfBirth], [PreferredMethodsOfContact], [PermissionsForContact], [DataSource], [IAssistanceProvider], [IAssistanceCallID], [IAssistanceCallStartDate], [IAssistanceCallStartDateOrig], [IAssistanceCallCloseDate], [IAssistanceCallCloseDateOrig], [IAssistanceHelpdeskAdvisorName], [IAssistanceHelpdeskAdvisorID], [IAssistanceCallMethod], [CountryCodeISOAlpha2], [PreferredLanguageID], [PerformNormalVWTLoadFlag], [MatchedODSVehicleID], [MatchedODSPersonID], [MatchedODSOrganisationID], [MatchedODSEmailAddress1ID], [MatchedODSEmailAddress2ID], [MatchedODSMobileTelephoneNumberID], [DateTransferredToVWT], [SampleTriggeredSelectionReqID]
	FROM IAssistance.IAssistanceEvents IAE 
	WHERE IAE.AuditID = @AuditID
	AND IAE.DateTransferredToVWT is NULL


	-- Invalidate any outstanding records as they have not already been loaded.
	UPDATE IAE
	SET DateTransferredToVWT = '1900-01-01'
	FROM IAssistance.IAssistanceEvents IAE 
	WHERE AuditID = @AuditID
	AND IAE.DateTransferredToVWT is NULL
	
	
	
	-----------------------------------------------------------------------------------------------------------------------------
	-- Roadside
	-----------------------------------------------------------------------------------------------------------------------------
	

	-- Save records prior to removing them
	INSERT INTO [$(AuditDB)].RollbackSample.RoadsideEvents (AuditID, RoadsideID, VWTID, AuditItemID, PhysicalRowID, Manufacturer, ManufacturerID, CountryCode, CountryID, EventType, VehiclePurchaseDateOrig, VehicleRegistrationDateOrig, VehicleDeliveryDateOrig, ServiceEventDateOrig, DealerCode, CustomerUniqueId, CompanyName, Title, Firstname, SurnameField1, SurnameField2, Salutation, Address1, Address2, Address3, Address4, [Address5(City)], [Address6(County)], [Address7(Postcode/Zipcode)], [Address8(Country)], HomeTelephoneNumber, BusinessTelephoneNumber, MobileTelephoneNumber, ModelName, ModelYear, Vin, RegistrationNumber, EmailAddress1, EmailAddress2, PreferredLanguage, CompleteSuppression, [Suppression-Email], [Suppression-Phone], [Suppression-Mail], InvoiceNumber, InvoiceValue, ServiceEmployeeCode, EmployeeName, OwnershipCycleOrig, OwnershipCycle, Gender, PrivateOwner, OwningCompany, [User/ChooserDriver], EmployerCompany, MonthAndYearOfBirth, PreferredMethodsOfContact, PermissionsForContact, BreakdownDate, BreakdownDateOrig, BreakdownCountry, BreakdownCountryID, BreakdownCaseId, CarHireStartDate, CarHireStartDateOrig, ReasonForHire, HireGroupBranch, CarHireTicketNumber, HireJobNumber, RepairingDealer, DataSource, ReplacementVehicleMake, ReplacementVehicleModel, VehicleReplacementTime, CarHireStartTime, ConvertedCarHireStartTime, RepairingDealerCountry, RoadsideAssistanceProvider, BreakdownAttendingResource, CarHireProvider, CountryCodeISOAlpha2, BreakdownCountryISOAlpha2, PreferredLanguageID, PerformNormalVWTLoadFlag, MatchedODSVehicleID, MatchedODSPersonID, MatchedODSOrganisationID, MatchedODSEmailAddress1ID, MatchedODSEmailAddress2ID, DateTransferredToVWT, SampleTriggeredSelectionReqID, MatchedODSMobileTelephoneNumberID)
	SELECT  AuditID, RoadsideID, VWTID, AuditItemID, PhysicalRowID, Manufacturer, ManufacturerID, CountryCode, CountryID, EventType, VehiclePurchaseDateOrig, VehicleRegistrationDateOrig, VehicleDeliveryDateOrig, ServiceEventDateOrig, DealerCode, CustomerUniqueId, CompanyName, Title, Firstname, SurnameField1, SurnameField2, Salutation, Address1, Address2, Address3, Address4, [Address5(City)], [Address6(County)], [Address7(Postcode/Zipcode)], [Address8(Country)], HomeTelephoneNumber, BusinessTelephoneNumber, MobileTelephoneNumber, ModelName, ModelYear, Vin, RegistrationNumber, EmailAddress1, EmailAddress2, PreferredLanguage, CompleteSuppression, [Suppression-Email], [Suppression-Phone], [Suppression-Mail], InvoiceNumber, InvoiceValue, ServiceEmployeeCode, EmployeeName, OwnershipCycleOrig, OwnershipCycle, Gender, PrivateOwner, OwningCompany, [User/ChooserDriver], EmployerCompany, MonthAndYearOfBirth, PreferredMethodsOfContact, PermissionsForContact, BreakdownDate, BreakdownDateOrig, BreakdownCountry, BreakdownCountryID, BreakdownCaseId, CarHireStartDate, CarHireStartDateOrig, ReasonForHire, HireGroupBranch, CarHireTicketNumber, HireJobNumber, RepairingDealer, DataSource, ReplacementVehicleMake, ReplacementVehicleModel, VehicleReplacementTime, CarHireStartTime, ConvertedCarHireStartTime, RepairingDealerCountry, RoadsideAssistanceProvider, BreakdownAttendingResource, CarHireProvider, CountryCodeISOAlpha2, BreakdownCountryISOAlpha2, PreferredLanguageID, PerformNormalVWTLoadFlag, MatchedODSVehicleID, MatchedODSPersonID, MatchedODSOrganisationID, MatchedODSEmailAddress1ID, MatchedODSEmailAddress2ID, DateTransferredToVWT, SampleTriggeredSelectionReqID, MatchedODSMobileTelephoneNumberID
	FROM Roadside.RoadsideEvents re 
	WHERE re.AuditID = @AuditID	


	-- Remove records from the staging table used for lookup
	DELETE  
	FROM Roadside.RoadsideEvents 
	WHERE AuditID = @AuditID


	-----------------------------------------------------------------------------------------------------------------------------
	-- Warranty 
	-----------------------------------------------------------------------------------------------------------------------------
		

	-- Save records prior to removing them
	INSERT INTO [$(AuditDB)].RollbackSample.WarrantyEvents (AuditID, WarrantyID, SampleSupplierPartyID, ManufacturerID, CICode, ClaimNumber, OverseasDealerCode, MarketOrig, CountryID, VINPrefix, ChassisNumber, ComplaintCode, OdometerDistance, DistanceUnit, ClaimType, DateOfRepairOrig, DateOfRepair, DateOfSaleOrig, DateOfSale, VWTID, AuditItemID, PhysicalRow, ServiceDealerCodeOriginatorPartyID, MatchedODSVehicleID, MatchedODSPersonID, MatchedODSOrganisationID, DateTransferredToVWT, ISOCountryCode, RONumber, ROSeqNumber, CLAIMSTATUS, WIAA02_CLAIM_TYPE_C, COVERAGECATEGORY, PROGRAMCODE, WIAA02_TOTAL_LABOR_A)
	SELECT  AuditID, WarrantyID, SampleSupplierPartyID, ManufacturerID, CICode, ClaimNumber, OverseasDealerCode, MarketOrig, CountryID, VINPrefix, ChassisNumber, ComplaintCode, OdometerDistance, DistanceUnit, ClaimType, DateOfRepairOrig, DateOfRepair, DateOfSaleOrig, DateOfSale, VWTID, AuditItemID, PhysicalRow, ServiceDealerCodeOriginatorPartyID, MatchedODSVehicleID, MatchedODSPersonID, MatchedODSOrganisationID, DateTransferredToVWT, ISOCountryCode, RONumber, ROSeqNumber, CLAIMSTATUS, WIAA02_CLAIM_TYPE_C, COVERAGECATEGORY, PROGRAMCODE, WIAA02_TOTAL_LABOR_A
	FROM Warranty.WarrantyEvents we 
	WHERE we.AuditID = @AuditID


	-- Remove records from the staging table used for lookup
	DELETE  
	FROM Warranty.WarrantyEvents 
	WHERE AuditID = @AuditID




	-----------------------------------------------------------------------------------------------------------------------------
	-----------------------------------------------------------------------------------------------------------------------------
	-- Invalidate Canada Sales and Service permanent staging table entries so they are not accidentally loaded later.
	-----------------------------------------------------------------------------------------------------------------------------
	-----------------------------------------------------------------------------------------------------------------------------

	-----------------------------------------------------------------------------------------------------------------------------
	-- Canada.Sales
	-----------------------------------------------------------------------------------------------------------------------------
	
	-- Save records prior to modifying them
	INSERT INTO [$(AuditDB)].RollbackSample.Canada_Sales (AuditID, ID, PhysicalRowID, DateTransferredToVWT, FilteredFlag, DealerID, ContractType, SaleType, PurchaseOrderDate, ContractDate, DeliveryDate, ReversalDate, InventoryDate, DealNumber, DealStatus, DealStatusDate, VIN, TypeCode, Make, Model, ModelYear, TrimLevel, SubTrimLevel, EteriorColorDescription, BodyDescription, BodyDoorCount, TransmissionDescription, EngineDescription, Features, ModelCode, LicensePlateNumber, RegistrationAuthority, InventoryType, InvoicePrice, HoldBackAmount, PackAmount, Cost, ReconditioningCost, ListPrice, MSRP, StockNumber, IsCertifiedFlag, VehicleSalePrice, TotalSaleCreditAmount, TotalPickupPayment, TotalCashDownPayment, TotalRebateAmount, TotalTaxes, TotalAccessories, TotalFeesandAccessories, TotalTradesAllowanceAmount, TotalTradesActualCashValue, TotalTradesPayoff, TotalNetTradeAmount, TotalGrossProfit, BackEndGrossProfit, FrontEndGrossProfit, SecurityDeposit, TotalDriveOffAmount, NetCapitalizedCost, Comments, DeliveryOdometer, TotalFinanceAmount, APR, FinanceCharge, ContractTerm, MonthlyPayment, TotalofPayments, PaymentFrequency, FirstPaymentDate, ExpectedVehiclePayoffDate, BalloonPayment, FinanceCompanyCode, FinanceCompanyName, BuyRate, BaseRentalAmount, TermDepreciationValue, TotalEstimatedMiles, TotalMileageLimit, ResidualAmount, BuyerID, BuyerSalutation, BuyerFirstName, BuyerMiddleName, BuyerLastName, BuyerSuffix, BuyerFullName, BuyerBirthDate, BuyerHomeAddress, BuyerHomeAddressDistrict, BuyerHomeAddressCity, BuyerHomeAddressRegion, BuyerHomeAddressPostalCode, BuyerHomeAddressCountry, BuyerHomePhoneNumber, BuyerHomePhoneExtension, BuyerHomePhoneCountryCode, BuyerBusinessPhoneNumber, BuyerBusinessPhoneExtension, BuyerBusinessPhoneCountryCode, BuyerPersonalEmailAddress, CoBuyerID, CoBuyerSalutation, CoBuyerFirstName, CoBuyerMiddleName, CoBuyerLastName, CoBuyerSuffix, CoBuyerFullName, CoBuyerBirthDate, CoBuyerHomeAddress, CoBuyerHomeAddressDistrict, CoBuyerHomeAddressCity, CoBuyerHomeAddressRegion, CoBuyerHomeAddressPostalCode, CoBuyerHomeAddressCountry, CoBuyerHomePhoneNumber, CoBuyerHomePhoneExtension, CoBuyerHomePhoneCountryCode, CoBuyerBusinessPhoneNumber, CoBuyerBusinessPhoneExtension, CoBuyerBusinessPhoneCountryCode, CoBuyerPersonalEmailAddress, SalesManagerID, SalesManagerSalutation, SalesManagerFirstName, SalesManagerMiddleName, SalesManagerLastName, SalesManagerSuffix, SalesManagerFullName, FIManagerID, FIManagerSalutation, FIManagerFirstName, FIManagerMiddleName, FIManagerLastName, FIManagerSuffix, FIManagerFullName, SalesPeople, TradeVehicles, AccidentandHealthCost, AHReserve, AHCoverageAmount, AHPremium, AHRate, AHTerminMonths, AHProvider, CreditLifeCost, CLReserve, CLCoverageAmount, CLPremium, CLRate, CLTerminMonths, CLProvider, GapCost, GapReserve, GapCoverageAmount, GapPremium, GapRate, GapTerminMonths, GapProvider, LossofEmploymentCost, LOEReserve, LOECoverageAmount, LOEPremium, LOERate, LOETerminMonths, LOEProvider, MechanicalBreakdownInsuranceCost, MBIReserve, MBICoverageAmount, MBIPremium, MBIRate, MBITerminMonths, MBITerminMiles, MBIProvider, ServiceContractCost, ServiceContractReserve, ServiceContractCoverageAmount, ServiceContractPremium, ServiceContractRate, ServiceContractTerminMonths, ServiceContractTerminMiles, Language, Converted_PurchaseOrderDate, Converted_ContractDate, Converted_BuyerBirthDate, Extracted_CompanyName, SalesPeople_ContactID, SalesPeople_FullName, ManufacturerPartyID, SampleSupplierPartyID, CountryID, EventTypeID, LanguageID, DealerCodeOriginatorPartyID, SetNameCapitalisation, SampleTriggeredSelectionReqID, CustomerIdentifierUsable)
	SELECT  AuditID, ID, PhysicalRowID, DateTransferredToVWT, FilteredFlag, DealerID, ContractType, SaleType, PurchaseOrderDate, ContractDate, DeliveryDate, ReversalDate, InventoryDate, DealNumber, DealStatus, DealStatusDate, VIN, TypeCode, Make, Model, ModelYear, TrimLevel, SubTrimLevel, EteriorColorDescription, BodyDescription, BodyDoorCount, TransmissionDescription, EngineDescription, Features, ModelCode, LicensePlateNumber, RegistrationAuthority, InventoryType, InvoicePrice, HoldBackAmount, PackAmount, Cost, ReconditioningCost, ListPrice, MSRP, StockNumber, IsCertifiedFlag, VehicleSalePrice, TotalSaleCreditAmount, TotalPickupPayment, TotalCashDownPayment, TotalRebateAmount, TotalTaxes, TotalAccessories, TotalFeesandAccessories, TotalTradesAllowanceAmount, TotalTradesActualCashValue, TotalTradesPayoff, TotalNetTradeAmount, TotalGrossProfit, BackEndGrossProfit, FrontEndGrossProfit, SecurityDeposit, TotalDriveOffAmount, NetCapitalizedCost, Comments, DeliveryOdometer, TotalFinanceAmount, APR, FinanceCharge, ContractTerm, MonthlyPayment, TotalofPayments, PaymentFrequency, FirstPaymentDate, ExpectedVehiclePayoffDate, BalloonPayment, FinanceCompanyCode, FinanceCompanyName, BuyRate, BaseRentalAmount, TermDepreciationValue, TotalEstimatedMiles, TotalMileageLimit, ResidualAmount, BuyerID, BuyerSalutation, BuyerFirstName, BuyerMiddleName, BuyerLastName, BuyerSuffix, BuyerFullName, BuyerBirthDate, BuyerHomeAddress, BuyerHomeAddressDistrict, BuyerHomeAddressCity, BuyerHomeAddressRegion, BuyerHomeAddressPostalCode, BuyerHomeAddressCountry, BuyerHomePhoneNumber, BuyerHomePhoneExtension, BuyerHomePhoneCountryCode, BuyerBusinessPhoneNumber, BuyerBusinessPhoneExtension, BuyerBusinessPhoneCountryCode, BuyerPersonalEmailAddress, CoBuyerID, CoBuyerSalutation, CoBuyerFirstName, CoBuyerMiddleName, CoBuyerLastName, CoBuyerSuffix, CoBuyerFullName, CoBuyerBirthDate, CoBuyerHomeAddress, CoBuyerHomeAddressDistrict, CoBuyerHomeAddressCity, CoBuyerHomeAddressRegion, CoBuyerHomeAddressPostalCode, CoBuyerHomeAddressCountry, CoBuyerHomePhoneNumber, CoBuyerHomePhoneExtension, CoBuyerHomePhoneCountryCode, CoBuyerBusinessPhoneNumber, CoBuyerBusinessPhoneExtension, CoBuyerBusinessPhoneCountryCode, CoBuyerPersonalEmailAddress, SalesManagerID, SalesManagerSalutation, SalesManagerFirstName, SalesManagerMiddleName, SalesManagerLastName, SalesManagerSuffix, SalesManagerFullName, FIManagerID, FIManagerSalutation, FIManagerFirstName, FIManagerMiddleName, FIManagerLastName, FIManagerSuffix, FIManagerFullName, SalesPeople, TradeVehicles, AccidentandHealthCost, AHReserve, AHCoverageAmount, AHPremium, AHRate, AHTerminMonths, AHProvider, CreditLifeCost, CLReserve, CLCoverageAmount, CLPremium, CLRate, CLTerminMonths, CLProvider, GapCost, GapReserve, GapCoverageAmount, GapPremium, GapRate, GapTerminMonths, GapProvider, LossofEmploymentCost, LOEReserve, LOECoverageAmount, LOEPremium, LOERate, LOETerminMonths, LOEProvider, MechanicalBreakdownInsuranceCost, MBIReserve, MBICoverageAmount, MBIPremium, MBIRate, MBITerminMonths, MBITerminMiles, MBIProvider, ServiceContractCost, ServiceContractReserve, ServiceContractCoverageAmount, ServiceContractPremium, ServiceContractRate, ServiceContractTerminMonths, ServiceContractTerminMiles, Language, Converted_PurchaseOrderDate, Converted_ContractDate, Converted_BuyerBirthDate, Extracted_CompanyName, SalesPeople_ContactID, SalesPeople_FullName, ManufacturerPartyID, SampleSupplierPartyID, CountryID, EventTypeID, LanguageID, DealerCodeOriginatorPartyID, SetNameCapitalisation, SampleTriggeredSelectionReqID, CustomerIdentifierUsable
	FROM Canada.Sales cs 
	WHERE cs.AuditID = @AuditID
	AND cs.DateTransferredToVWT is NULL


	-- Invalidate any outstanding records as they have not already been loaded.
	UPDATE cs
	SET DateTransferredToVWT = '1900-01-01'
	FROM Canada.Sales cs 
	WHERE cs.AuditID = @AuditID
	AND cs.DateTransferredToVWT is NULL
	

	-----------------------------------------------------------------------------------------------------------------------------
	-- Canada.Service
	-----------------------------------------------------------------------------------------------------------------------------

	
	-- Save records prior to modifying them
	INSERT INTO [$(AuditDB)].RollbackSample.Canada_Service (AuditID, ID, PhysicalRowID, DateTransferredToVWT, FilteredFlag, DEALER_ID, RO_NUM, RO_CLOSE_DATE, RO_OPEN_DATE, CUST_CONTACT_ID, CUST_FIRST_NAME, CUST_MIDDLE_NAME, CUST_LAST_NAME, CUST_SALUTATION, CUST_SUFFIX, CUST_FULL_NAME, CUST_TITLE, CUST_BUSINESS_PERSON_FLAG, CUST_COMPANY_NAME, CUST_DEPARTMENT, CUST_ADDRESS, CUST_DISTRICT, CUST_CITY, CUST_REGION, CUST_POSTAL_CODE, CUST_COUNTRY, CUST_HOME_PH_NUMBER, CUST_HOME_PH_EXTENSION, CUST_BUS_PH_COUNTRY_CODE, CUST_BUS_PH_NUMBER, CUST_BUS_PH_EXTENSION, CUST_BUS_PH_COUNTRY_CODE2, CUST_HOME_EMAIL, CUST_BUS_EMAIL, CUST_BIRTH_DATE, CUST_ALLOW_SOLICIT, CUST_ALLOW_PHONE_SOLICIT, CUST_ALLOW_EMAIL_SOLICIT, CUST_ALLOW_MAIL_SOLICIT, ODOMETER_IN, ODOMETER_OUT, VEHICLE_PICKUP_DATE, APPOINTMENT_FLAG, DEPARTMENT, EXT_SVC_CONTRACT_NAMES, PAYMENT_METHODS, TOTAL_CUSTOMER_PARTS_PRICE, TOTAL_CUSTOMER_LABOR_PRICE, TOTAL_CUSTOMER_MISC_PRICE, TOTAL_CUSTOMER_SUBLET_PRICE, TOTAL_CUSTOMER_GOG_PRICE, TOTAL_CUSTOMER_TTL_MISC_PRICE, TOTAL_CUSTOMER_PRICE, TOTAL_CUSTOMER_PARTS_COST, TOTAL_CUSTOMER_LABOR_COST, TOTAL_CUSTOMER_MISC_COST, TOTAL_CUSTOMER_SUBLET_COST, TOTAL_CUSTOMER_GOG_COST, TOTAL_CUSTOMER_TTL_MISC_COST, TOTAL_CUSTOMER_COST, TOTAL_WARRANTY_PARTS_PRICE, TOTAL_WARRANTY_LABOR_PRICE, TOTAL_WARRANTY_MISC_PRICE, TOTAL_WARRANTY_SUBLET_PRICE, TOTAL_WARRANTY_GOG_PRICE, TOTAL_WARRANTY_TTL_MISC_PRICE, TOTAL_WARRANTY_PRICE, TOTAL_WARRANTY_PARTS_COST, TOTAL_WARRANTY_LABOR_COST, TOTAL_WARRANTY_MISC_COST, TOTAL_WARRANTY_SUBLET_COST, TOTAL_WARRANTY_GOG_COST, TOTAL_WARRANTY_TTL_MISC_COST, TOTAL_WARRANTY_COST, TOTAL_INTERNAL_PARTS_PRICE, TOTAL_INTERNAL_LABOR_PRICE, TOTAL_INTERNAL_MISC_PRICE, TOTAL_INTERNAL_SUBLET_PRICE, TOTAL_INTERNAL_GOG_PRICE, TOTAL_INTERNAL_TTL_MISC_PRICE, TOTAL_INTERNAL_PRICE, TOTAL_INTERNAL_PARTS_COST, TOTAL_INTERNAL_LABOR_COST, TOTAL_INTERNAL_MISC_COST, TOTAL_INTERNAL_SUBLET_COST, TOTAL_INTERNAL_GOG_COST, TOTAL_INTERNAL_TTL_MISC_COST, TOTAL_INTERNAL_COST, TOTAL_PARTS_PRICE, TOTAL_LABOR_PRICE, TOTAL_MISC_PRICE, TOTAL_SUBLET_PRICE, TOTAL_GOG_PRICE, TOTAL_TTL_MISC_PRICE, TOTAL_RO_PRICE, TOTAL_TAX_PRICE, TOTAL_PARTS_COST, TOTAL_LABOR_COST, TOTAL_MISC_COST, TOTAL_SUBLET_COST, TOTAL_GOG_COST, TOTAL_TTL_MISC_COST, TOTAL_RO_COST, TOTAL_ACTUAL_LABOR_HOURS, TOTAL_BILLED_LABOR_HOURS, VEH_VIN, VEH_MODEL_YEAR, VEH_MAKE, VEH_MODEL, VEH_TRANS_TYPE, VEH_EXT_COLOR_DESCRIPTION, VEH_REG_LICENSE_PLATE_NUMBER, OPERATIONS, TECH_COMMENT, CUST_COMMENT, SERVICE_ADVISOR_CONTACT_ID, SERVICE_ADVISOR_FIRST_NAME, SERVICE_ADVISOR_MIDDLE_NAME, SERVICE_ADVISOR_LAST_NAME, SERVICE_ADVISOR_SALUTATION, SERVICE_ADVISOR_SUFFIX, SERVICE_ADVISOR_FULL_NAME, LANGUAGE, TECHNICIAN_CONTACT_ID, TECHNICIAN_FULL_NAME, OPERATION_PAY_TYPE, Converted_RO_CLOSE_DATE, Converted_CUST_BIRTH_DATE, ManufacturerPartyID, SampleSupplierPartyID, CountryID, EventTypeID, LanguageID, DealerCodeOriginatorPartyID, SetNameCapitalisation, SampleTriggeredSelectionReqID, CustomerIdentifierUsable, PDI_Flag)
	SELECT  AuditID, ID, PhysicalRowID, DateTransferredToVWT, FilteredFlag, DEALER_ID, RO_NUM, RO_CLOSE_DATE, RO_OPEN_DATE, CUST_CONTACT_ID, CUST_FIRST_NAME, CUST_MIDDLE_NAME, CUST_LAST_NAME, CUST_SALUTATION, CUST_SUFFIX, CUST_FULL_NAME, CUST_TITLE, CUST_BUSINESS_PERSON_FLAG, CUST_COMPANY_NAME, CUST_DEPARTMENT, CUST_ADDRESS, CUST_DISTRICT, CUST_CITY, CUST_REGION, CUST_POSTAL_CODE, CUST_COUNTRY, CUST_HOME_PH_NUMBER, CUST_HOME_PH_EXTENSION, CUST_BUS_PH_COUNTRY_CODE, CUST_BUS_PH_NUMBER, CUST_BUS_PH_EXTENSION, CUST_BUS_PH_COUNTRY_CODE2, CUST_HOME_EMAIL, CUST_BUS_EMAIL, CUST_BIRTH_DATE, CUST_ALLOW_SOLICIT, CUST_ALLOW_PHONE_SOLICIT, CUST_ALLOW_EMAIL_SOLICIT, CUST_ALLOW_MAIL_SOLICIT, ODOMETER_IN, ODOMETER_OUT, VEHICLE_PICKUP_DATE, APPOINTMENT_FLAG, DEPARTMENT, EXT_SVC_CONTRACT_NAMES, PAYMENT_METHODS, TOTAL_CUSTOMER_PARTS_PRICE, TOTAL_CUSTOMER_LABOR_PRICE, TOTAL_CUSTOMER_MISC_PRICE, TOTAL_CUSTOMER_SUBLET_PRICE, TOTAL_CUSTOMER_GOG_PRICE, TOTAL_CUSTOMER_TTL_MISC_PRICE, TOTAL_CUSTOMER_PRICE, TOTAL_CUSTOMER_PARTS_COST, TOTAL_CUSTOMER_LABOR_COST, TOTAL_CUSTOMER_MISC_COST, TOTAL_CUSTOMER_SUBLET_COST, TOTAL_CUSTOMER_GOG_COST, TOTAL_CUSTOMER_TTL_MISC_COST, TOTAL_CUSTOMER_COST, TOTAL_WARRANTY_PARTS_PRICE, TOTAL_WARRANTY_LABOR_PRICE, TOTAL_WARRANTY_MISC_PRICE, TOTAL_WARRANTY_SUBLET_PRICE, TOTAL_WARRANTY_GOG_PRICE, TOTAL_WARRANTY_TTL_MISC_PRICE, TOTAL_WARRANTY_PRICE, TOTAL_WARRANTY_PARTS_COST, TOTAL_WARRANTY_LABOR_COST, TOTAL_WARRANTY_MISC_COST, TOTAL_WARRANTY_SUBLET_COST, TOTAL_WARRANTY_GOG_COST, TOTAL_WARRANTY_TTL_MISC_COST, TOTAL_WARRANTY_COST, TOTAL_INTERNAL_PARTS_PRICE, TOTAL_INTERNAL_LABOR_PRICE, TOTAL_INTERNAL_MISC_PRICE, TOTAL_INTERNAL_SUBLET_PRICE, TOTAL_INTERNAL_GOG_PRICE, TOTAL_INTERNAL_TTL_MISC_PRICE, TOTAL_INTERNAL_PRICE, TOTAL_INTERNAL_PARTS_COST, TOTAL_INTERNAL_LABOR_COST, TOTAL_INTERNAL_MISC_COST, TOTAL_INTERNAL_SUBLET_COST, TOTAL_INTERNAL_GOG_COST, TOTAL_INTERNAL_TTL_MISC_COST, TOTAL_INTERNAL_COST, TOTAL_PARTS_PRICE, TOTAL_LABOR_PRICE, TOTAL_MISC_PRICE, TOTAL_SUBLET_PRICE, TOTAL_GOG_PRICE, TOTAL_TTL_MISC_PRICE, TOTAL_RO_PRICE, TOTAL_TAX_PRICE, TOTAL_PARTS_COST, TOTAL_LABOR_COST, TOTAL_MISC_COST, TOTAL_SUBLET_COST, TOTAL_GOG_COST, TOTAL_TTL_MISC_COST, TOTAL_RO_COST, TOTAL_ACTUAL_LABOR_HOURS, TOTAL_BILLED_LABOR_HOURS, VEH_VIN, VEH_MODEL_YEAR, VEH_MAKE, VEH_MODEL, VEH_TRANS_TYPE, VEH_EXT_COLOR_DESCRIPTION, VEH_REG_LICENSE_PLATE_NUMBER, OPERATIONS, TECH_COMMENT, CUST_COMMENT, SERVICE_ADVISOR_CONTACT_ID, SERVICE_ADVISOR_FIRST_NAME, SERVICE_ADVISOR_MIDDLE_NAME, SERVICE_ADVISOR_LAST_NAME, SERVICE_ADVISOR_SALUTATION, SERVICE_ADVISOR_SUFFIX, SERVICE_ADVISOR_FULL_NAME, LANGUAGE, TECHNICIAN_CONTACT_ID, TECHNICIAN_FULL_NAME, OPERATION_PAY_TYPE, Converted_RO_CLOSE_DATE, Converted_CUST_BIRTH_DATE, ManufacturerPartyID, SampleSupplierPartyID, CountryID, EventTypeID, LanguageID, DealerCodeOriginatorPartyID, SetNameCapitalisation, SampleTriggeredSelectionReqID, CustomerIdentifierUsable, PDI_Flag
	FROM Canada.Service cs 
	WHERE cs.AuditID = @AuditID
	AND cs.DateTransferredToVWT is NULL


	-- Invalidate any outstanding records as they have not already been loaded.
	UPDATE cs
	SET DateTransferredToVWT = '1900-01-01'
	FROM Canada.Service cs 
	WHERE cs.AuditID = @AuditID
	AND cs.DateTransferredToVWT is NULL	



	-----------------------------------------------------------------------------------------------------------------------------
	-----------------------------------------------------------------------------------------------------------------------------
	-- Remove any CRM records from the permananent staging tables.  We are actually removing these as there have been requests
	-- for stats on these files and it is cleaner to remove.
	-----------------------------------------------------------------------------------------------------------------------------
	-----------------------------------------------------------------------------------------------------------------------------

	-----------------------------------------------------------------------------------------------------------------------------
	-- CRM.CRCCall_Call
	-----------------------------------------------------------------------------------------------------------------------------
	

	-- Save records prior to removing them
	INSERT INTO [$(AuditDB)].RollbackSample.CRM_CRCCall_Call (ID, AuditID, VWTID, AuditItemID, PhysicalRowID, Converted_ACCT_DATE_OF_BIRTH, Converted_ACCT_DATE_ADVISED_OF_DEATH, Converted_VEH_REGISTRATION_DATE, Converted_VEH_BUILD_DATE, Converted_DMS_REPAIR_ORDER_CLOSED_DATE, Converted_ROADSIDE_DATE_JOB_COMPLETED, Converted_CASE_CASE_SOLVED_DATE, Converted_VISTACONTRACT_HANDOVER_DATE, DateTransferredToVWT, SampleTriggeredSelectionReqID, ACCT_ACADEMIC_TITLE, ACCT_ACADEMIC_TITLE_CODE, ACCT_ACCT_ID, ACCT_ACCT_TYPE, ACCT_ACCT_TYPE_CODE, ACCT_ADDITIONAL_LAST_NAME, ACCT_BP_ROLE, ACCT_BUILDING, ACCT_CITY_CODE, ACCT_CITY_CODE2, ACCT_CITY_TOWN, ACCT_CITYH_CODE, ACCT_CONSENT_JAGUAR_EMAIL, ACCT_CONSENT_JAGUAR_PHONE, ACCT_CONSENT_JAGUAR_POST, ACCT_CONSENT_LAND_ROVER_EMAIL, ACCT_CONSENT_LAND_ROVER_POST, ACCT_CONSENT_LR_PHONE, ACCT_CORRESPONDENCE_LANG_CODE, ACCT_CORRESPONDENCE_LANGUAGE, ACCT_COUNTRY, ACCT_COUNTRY_CODE, ACCT_COUNTY, ACCT_COUNTY_CODE, ACCT_DATE_ADVISED_OF_DEATH, ACCT_DATE_DECL_TO_GIVE_EMAIL, ACCT_DATE_OF_BIRTH, ACCT_DEAL_FULNAME_OF_CREAT_DEA, ACCT_DISTRICT, ACCT_EMAIL_VALIDATION_STATUS, ACCT_EMPLOYER_NAME, ACCT_EXTERN_FINANC_COMP_ACCTID, ACCT_FIRST_NAME, ACCT_FLOOR, ACCT_FULL_NAME, ACCT_GENDER_FEMALE, ACCT_GENDER_MALE, ACCT_GENDER_UNKNOWN, ACCT_GENERATION, ACCT_HOME_CITY, ACCT_HOME_EMAIL_ADDR_PRIMARY, ACCT_HOME_PHONE_NUMBER, ACCT_HOUSE_NO, ACCT_HOUSE_NUM2, ACCT_HOUSE_NUM3, ACCT_INDUSTRY_SECTOR, ACCT_INDUSTRY_SECTOR_CODE, ACCT_INITIALS, ACCT_JAGUAR_IN_MARKET_DATE, ACCT_JAGUAR_LOYALTY_STATUS, ACCT_KNOWN_AS, ACCT_LAND_ROVER_LOYALTY_STATUS, ACCT_LAND_ROVER_MARKET_DATE, ACCT_LAST_NAME, ACCT_LOCATION, ACCT_MIDDLE_NAME, ACCT_MOBILE_NUMBER, ACCT_NAME_1, ACCT_NAME_2, ACCT_NAME_3, ACCT_NAME_4, ACCT_NAME_CO, ACCT_NON_ACADEMIC_TITLE, ACCT_NON_ACADEMIC_TITLE_CODE, ACCT_ORG_TYPE, ACCT_ORG_TYPE_CODE, ACCT_PCODE1_EXT, ACCT_PCODE2_EXT, ACCT_PCODE3_EXT, ACCT_PO_BOX, ACCT_PO_BOX_CTY, ACCT_PO_BOX_LOBBY, ACCT_PO_BOX_LOC, ACCT_PO_BOX_NUM, ACCT_PO_BOX_REG, ACCT_POST_CODE2, ACCT_POST_CODE3, ACCT_POSTALAREA, ACCT_POSTCODE_ZIP, ACCT_PREF_CONTACT_METHOD, ACCT_PREF_CONTACT_METHOD_CODE, ACCT_PREF_CONTACT_TIME, ACCT_PREF_LANGUAGE, ACCT_PREF_LANGUAGE_CODE, ACCT_REGION_STATE, ACCT_REGION_STATE_CODE, ACCT_ROOM_NUMBER, ACCT_STREET, ACCT_STREETABBR, ACCT_STREETCODE, ACCT_SUPPLEMENT_1, ACCT_SUPPLEMENT_2, ACCT_SUPPLEMENT_3, ACCT_TITLE, ACCT_TITLE_CODE, ACCT_TOWNSHIP, ACCT_TOWNSHIP_CODE, ACCT_VIP_FLAG, ACCT_WORK_PHONE_EXTENSION, ACCT_WORK_PHONE_PRIMARY, ACTIVITY_ID, CAMPAIGN_CAMPAIGN_CHANNEL, CAMPAIGN_CAMPAIGN_DESC, CAMPAIGN_CAMPAIGN_ID, CAMPAIGN_CATEGORY_1, CAMPAIGN_CATEGORY_2, CAMPAIGN_CATEGORY_3, CAMPAIGN_DEALERFULNAME_DEALER1, CAMPAIGN_DEALERFULNAME_DEALER2, CAMPAIGN_DEALERFULNAME_DEALER3, CAMPAIGN_DEALERFULNAME_DEALER4, CAMPAIGN_DEALERFULNAME_DEALER5, CAMPAIGN_SECDEALERCODE_DEALER1, CAMPAIGN_SECDEALERCODE_DEALER2, CAMPAIGN_SECDEALERCODE_DEALER3, CAMPAIGN_SECDEALERCODE_DEALER4, CAMPAIGN_SECDEALERCODE_DEALER5, CAMPAIGN_TARGET_GROUP_DESC, CAMPAIGN_TARGET_GROUP_ID, CASE_BRAND, CASE_BRAND_CODE, CASE_CASE_CREATION_DATE, CASE_CASE_DESC, CASE_CASE_EMPL_RESPONSIBLE_NAM, CASE_CASE_ID, CASE_CASE_SOLVED_DATE, CASE_EMPL_RESPONSIBLE_ID, CASE_GOODWILL_INDICATOR, CASE_REASON_FOR_STATUS, CASE_SECON_DEALER_CODE_OF_DEAL, CASE_VEH_REG_PLATE, CASE_VEH_VIN_NUMBER, CASE_VEHMODEL_DERIVED_FROM_VIN, CR_OBJECT_ID, CRH_DEALER_ROA_CITY_TOWN, CRH_DEALER_ROA_COUNTRY, CRH_DEALER_ROA_HOUSE_NO, CRH_DEALER_ROA_ID, CRH_DEALER_ROA_NAME_1, CRH_DEALER_ROA_NAME_2, CRH_DEALER_ROA_PO_BOX, CRH_DEALER_ROA_POSTCODE_ZIP, CRH_DEALER_ROA_PREFIX_1, CRH_DEALER_ROA_PREFIX_2, CRH_DEALER_ROA_REGION_STATE, CRH_DEALER_ROA_STREET, CRH_DEALER_ROA_SUPPLEMENT_1, CRH_DEALER_ROA_SUPPLEMENT_2, CRH_DEALER_ROA_SUPPLEMENT_3, CRH_END_DATE, CRH_START_DATE, DMS_ACTIVITY_DESC, DMS_DAYS_OPEN, DMS_EVENT_TYPE, DMS_LICENSE_PLATE_REGISTRATION, DMS_POTENTIAL_CHANGE_OF_OWNERS, DMS_REPAIR_ORDER_CLOSED_DATE, DMS_REPAIR_ORDER_NUMBER, DMS_REPAIR_ORDER_OPEN_DATE, DMS_SECON_DEALER_CODE, DMS_SERVICE_ADVISOR, DMS_SERVICE_ADVISOR_ID, DMS_TECHNICIAN_ID, DMS_TECHNICIAN, DMS_TOTAL_CUSTOMER_VISTACONTRACT_RETAIL_PRICE, DMS_USER_STATUS, DMS_USER_STATUS_CODE, DMS_VIN, LEAD_BRAND_CODE, LEAD_EMP_RESPONSIBLE_DEAL_NAME, LEAD_ENQUIRY_TYPE_CODE, LEAD_FUEL_TYPE_CODE, LEAD_IN_MARKET_DATE, LEAD_LEAD_CATEGORY_CODE, LEAD_LEAD_STATUS_CODE, LEAD_LEAD_STATUS_REASON_CODE, LEAD_MODEL_OF_INTEREST_CODE, LEAD_MODEL_YEAR, LEAD_NEW_USED_INDICATOR, LEAD_ORIGIN_CODE, LEAD_PRE_LAUNCH_MODEL, LEAD_PREF_CONTACT_METHOD, LEAD_SECON_DEALER_CODE, LEAD_VEH_SALE_TYPE_CODE, OBJECT_ID, ROADSIDE_ACTIVE_STATUS_CODE, ROADSIDE_ACTIVITY_DESC, ROADSIDE_COUNTRY_ISO_CODE, ROADSIDE_CUSTOMER_SUMMARY_INC, ROADSIDE_DATA_SOURCE, ROADSIDE_DATE_CALL_ANSWERED, ROADSIDE_DATE_CALL_RECEIVED, ROADSIDE_DATE_JOB_COMPLETED, ROADSIDE_DATE_RESOURCE_ALL, ROADSIDE_DATE_RESOURCE_ARRIVED, ROADSIDE_DATE_SECON_RES_ALL, ROADSIDE_DATE_SECON_RES_ARR, ROADSIDE_DRIVER_EMAIL, ROADSIDE_DRIVER_FIRST_NAME, ROADSIDE_DRIVER_LAST_NAME, ROADSIDE_DRIVER_MOBILE, ROADSIDE_DRIVER_TITLE, ROADSIDE_INCIDENT_CATEGORY, ROADSIDE_INCIDENT_COUNTRY, ROADSIDE_INCIDENT_DATE, ROADSIDE_INCIDENT_ID, ROADSIDE_INCIDENT_SUMMARY, ROADSIDE_INCIDENT_TIME, ROADSIDE_LICENSE_PLATE_REG_NO, ROADSIDE_PROVIDER, ROADSIDE_REPAIRING_SEC_DEAL_CD, ROADSIDE_RESOLUTION_TIME, ROADSIDE_TIME_CALL_ANSWERED, ROADSIDE_TIME_CALL_RECEIVED, ROADSIDE_TIME_JOB_COMPLETED, ROADSIDE_TIME_RESOURCE_ALL, ROADSIDE_TIME_RESOURCE_ARRIVED, ROADSIDE_TIME_SECON_RES_ALL, ROADSIDE_TIME_SECON_RES_ARR, ROADSIDE_VIN, ROADSIDE_WAIT_TIME, VEH_BRAND, VEH_BUILD_DATE, VEH_CHASSIS_NUMBER, VEH_COMMON_ORDER_NUMBER, VEH_COUNTRY_EQUIPMENT_CODE, VEH_CREATING_DEALER, VEH_CURR_PLANNED_DELIVERY_DATE, VEH_CURRENT_PLANNED_BUILD_DATE, VEH_DEA_NAME_LAST_SELLING_DEAL, VEH_DEALER_NAME_OF_SELLING_DEA, VEH_DELIVERED_DATE, VEH_DERIVATIVE, VEH_DRIVER_FULL_NAME, VEH_ENGINE_SIZE, VEH_EXTERIOR_COLOUR_CODE, VEH_EXTERIOR_COLOUR_DESC, VEH_EXTERIOR_COLOUR_SUPPL_CODE, VEH_EXTERIOR_COLOUR_SUPPL_DESC, VEH_FEATURE_CODE, VEH_FINANCE_PROD, VEH_FIRST_RETAIL_SALE, VEH_FUEL_TYPE_CODE, VEH_MODEL, VEH_MODEL_DESC, VEH_MODEL_YEAR, VEH_NUM_OF_OWNERS_RELATIONSHIP, VEH_ORIGIN, VEH_OWNERSHIP_STATUS, VEH_OWNERSHIP_STATUS_CODE, VEH_PAYMENT_TYPE, VEH_PREDICTED_REPLACEMENT_DATE, VEH_REACQUIRED_INDICATOR, VEH_REGISTRAT_LICENC_PLATE_NUM, VEH_REGISTRATION_DATE, VEH_SALE_TYPE_DESC, VEH_VIN, VEH_VISTA_CONTRACT_NUMBER, VISTACONTRACT_COMM_TY_SALE_DS, VISTACONTRACT_HANDOVER_DATE, VISTACONTRACT_PREV_VEH_BRAND, VISTACONTRACT_PREV_VEH_MODEL, VISTACONTRACT_SALES_MAN_CD_DES, VISTACONTRACT_SALES_MAN_FULNAM, VISTACONTRACT_SALESMAN_CODE, VISTACONTRACT_SECON_DEALER_CD, VISTACONTRACT_TRADE_IN_MANUFAC, VISTACONTRACT_TRADE_IN_MODEL, VISTACONTRACT_ACTIVITY_CATEGRY, VISTACONTRACT_RETAIL_PRICE, VEH_APPR_WARNTY_TYPE, VEH_APPR_WARNTY_TYPE_DESC, VISTACONTRACTNAPPRO_RETAIL_WAR, VISTACONTRACTNAPPRO_RETAIL_DES, VISTACONTRACT_EXT_WARR, VISTACONTRACT_EXT_WARR_DESC, ACCT_CONSENT_JAGUAR_FAX, ACCT_CONSENT_LAND_ROVER_FAX, ACCT_CONSENT_JAGUAR_CHAT, ACCT_CONSENT_LAND_ROVER_CHAT, ACCT_CONSENT_JAGUAR_SMS, ACCT_CONSENT_LAND_ROVER_SMS, ACCT_CONSENT_JAGUAR_SMEDIA, ACCT_CONSENT_LAND_ROVER_SMEDIA, ACCT_CONSENT_OVER_CONT_SUP_JAG, ACCT_CONSENT_OVER_CONT_SUP_LR, ACCT_CONSENT_JAGUAR_PTSMR, ACCT_CONSENT_LAND_ROVER_PTSMR, ACCT_CONSENT_JAGUAR_PTVSM, ACCT_CONSENT_LAND_ROVER_PTVSM, ACCT_CONSENT_JAGUAR_PTAM, ACCT_CONSENT_LAND_ROVER_PTAM, ACCT_CONSENT_JAGUAR_PTNAU, ACCT_CONSENT_LAND_ROVER_PTNAU, ACCT_CONSENT_JAGUAR_PEVENT, ACCT_CONSENT_LAND_ROVER_PEVENT, ACCT_CONSENT_JAGUAR_PND3P, ACCT_CONSENT_LAND_ROVER_PND3P, ACCT_CONSENT_JAGUAR_PTSDWD, ACCT_CONSENT_LAND_ROVER_PTSDWD, ACCT_CONSENT_JAGUAR_PTPA, ACCT_CONSENT_LAND_ROVER_PTPA, RESPONSE_ID, DMS_OTHER_RELATED_SERVICES, VEH_SALE_TYPE_CODE, VISTACONTRACT_COMM_TY_SALE_CD, LEAD_STATUS_REASON_LEV1_DESC, LEAD_STATUS_REASON_LEV1_COD, LEAD_STATUS_REASON_LEV2_DESC, LEAD_STATUS_REASON_LEV2_COD, LEAD_STATUS_REASON_LEV3_DESC, LEAD_STATUS_REASON_LEV3_COD, JAGDIGITALEVENTSEXP, JAGDIGITALINCONTROL, JAGDIGITALOWNERVEHCOMM, JAGDIGITALPARTNERSSPONSORS, JAGDIGITALPRODSERV, JAGDIGITALPROMOTIONSOFFERS, JAGDIGITALSURVEYSRESEARCH, JAGEMAILEVENTSEXP, JAGEMAILINCONTROL, JAGEMAILOWNERVEHCOMM, JAGEMAILPARTNERSSPONSORS, JAGEMAILPRODSERV, JAGEMAILPROMOTIONSOFFERS, JAGEMAILSURVEYSRESEARCH, JAGPHONEEVENTSEXP, JAGPHONEINCONTROL, JAGPHONEOWNERVEHCOMM, JAGPHONEPARTNERSSPONSORS, JAGPHONEPRODSERV, JAGPHONEPROMOTIONSOFFERS, JAGPHONESURVEYSRESEARCH, JAGPOSTEVENTSEXP, JAGPOSTINCONTROL, JAGPOSTOWNERVEHCOMM, JAGPOSTPARTNERSSPONSORS, JAGPOSTPRODSERV, JAGPOSTPROMOTIONSOFFERS, JAGPOSTSURVEYSRESEARCH, JAGSMSEVENTSEXP, JAGSMSINCONTROL, JAGSMSOWNERVEHCOMM, JAGSMSPARTNERSSPONSORS, JAGSMSPRODSERV, JAGSMSPROMOTIONSOFFERS, JAGSMSSURVEYSRESEARCH, LRDIGITALEVENTSEXP, LRDIGITALINCONTROL, LRDIGITALOWNERVEHCOMM, LRDIGITALPARTNERSSPONSORS, LRDIGITALPRODSERV, LRDIGITALPROMOTIONSOFFERS, LRDIGITALSURVEYSRESEARCH, LREMAILEVENTSEXP, LREMAILINCONTROL, LREMAILOWNERVEHCOMM, LREMAILPARTNERSSPONSORS, LREMAILPRODSERV, LREMAILPROMOTIONSOFFERS, LREMAILSURVEYSRESEARCH, LRPHONEEVENTSEXP, LRPHONEINCONTROL, LRPHONEOWNERVEHCOMM, LRPHONEPARTNERSSPONSORS, LRPHONEPRODSERV, LRPHONEPROMOTIONSOFFERS, LRPHONESURVEYSRESEARCH, LRPOSTEVENTSEXP, LRPOSTINCONTROL, LRPOSTOWNERVEHCOMM, LRPOSTPARTNERSSPONSORS, LRPOSTPRODSERV, LRPOSTPROMOTIONSOFFERS, LRPOSTSURVEYSRESEARCH, LRSMSEVENTSEXP, LRSMSINCONTROL, LRSMSOWNERVEHCOMM, LRSMSPARTNERSSPONSORS, LRSMSPRODSERV, LRSMSPROMOTIONSOFFERS, LRSMSSURVEYSRESEARCH, ACCT_NAME_PREFIX_CODE, ACCT_NAME_PREFIX, DMS_REPAIR_ORDER_NUMBER_UNIQUE, DMS_TOTAL_CUSTOMER_PRICE, VISTACONTRACT_COMMON_ORDER_NUM, VEH_FUEL_TYPE, CNT_ABTNR, CNT_ADDRESS, CNT_DPRTMNT, CNT_FIRST_NAME, CNT_FNCTN, CNT_LAST_NAME, CNT_PAFKT, CNT_RELTYP, CNT_TEL_NUMBER, CONTACT_PER_ID, ACCT_NAME_CREATING_DEA, CNT_MOBILE_PHONE, CNT_ACADEMIC_TITLE, CNT_ACADEMIC_TITLE_CODE, CNT_NAME_PREFIX_CODE, CNT_NAME_PREFIX, CNT_JAGDIGITALEVENTSEXP, CNT_JAGDIGITALINCONTROL, CNT_JAGDIGITALOWNERVEHCOMM, CNT_JAGDIGITALPARTNERSSPONSORS, CNT_JAGDIGITALPRODSERV, CNT_JAGDIGITALPROMOTIONSOFFERS, CNT_JAGDIGITALSURVEYSRESEARCH, CNT_JAGEMAILEVENTSEXP, CNT_JAGEMAILINCONTROL, CNT_JAGEMAILOWNERVEHCOMM, CNT_JAGEMAILPARTNERSSPONSORS, CNT_JAGEMAILPRODSERV, CNT_JAGEMAILPROMOTIONSOFFERS, CNT_JAGEMAILSURVEYSRESEARCH, CNT_JAGPHONEEVENTSEXP, CNT_JAGPHONEINCONTROL, CNT_JAGPHONEOWNERVEHCOMM, CNT_JAGPHONEPARTNERSSPONSORS, CNT_JAGPHONEPRODSERV, CNT_JAGPHONEPROMOTIONSOFFERS, CNT_JAGPHONESURVEYSRESEARCH, CNT_JAGPOSTEVENTSEXP, CNT_JAGPOSTINCONTROL, CNT_JAGPOSTOWNERVEHCOMM, CNT_JAGPOSTPARTNERSSPONSORS, CNT_JAGPOSTPRODSERV, CNT_JAGPOSTPROMOTIONSOFFERS, CNT_JAGPOSTSURVEYSRESEARCH, CNT_JAGSMSEVENTSEXP, CNT_JAGSMSINCONTROL, CNT_JAGSMSOWNERVEHCOMM, CNT_JAGSMSPARTNERSSPONSORS, CNT_JAGSMSPRODSERV, CNT_JAGSMSPROMOTIONSOFFERS, CNT_JAGSMSSURVEYSRESEARCH, CNT_LRDIGITALEVENTSEXP, CNT_LRDIGITALINCONTROL, CNT_LRDIGITALOWNERVEHCOMM, CNT_LRDIGITALPARTNERSSPONSORS, CNT_LRDIGITALPRODSERV, CNT_LRDIGITALPROMOTIONSOFFERS, CNT_LRDIGITALSURVEYSRESEARCH, CNT_LREMAILEVENTSEXP, CNT_LREMAILINCONTROL, CNT_LREMAILOWNERVEHCOMM, CNT_LREMAILPARTNERSSPONSORS, CNT_LREMAILPRODSERV, CNT_LREMAILPROMOTIONSOFFERS, CNT_LREMAILSURVEYSRESEARCH, CNT_LRPHONEEVENTSEXP, CNT_LRPHONEINCONTROL, CNT_LRPHONEOWNERVEHCOMM, CNT_LRPHONEPARTNERSSPONSORS, CNT_LRPHONEPRODSERV, CNT_LRPHONEPROMOTIONSOFFERS, CNT_LRPHONESURVEYSRESEARCH, CNT_LRPOSTEVENTSEXP, CNT_LRPOSTINCONTROL, CNT_LRPOSTOWNERVEHCOMM, CNT_LRPOSTPARTNERSSPONSORS, CNT_LRPOSTPRODSERV, CNT_LRPOSTPROMOTIONSOFFERS, CNT_LRPOSTSURVEYSRESEARCH, CNT_LRSMSEVENTSEXP, CNT_LRSMSINCONTROL, CNT_LRSMSOWNERVEHCOMM, CNT_LRSMSPARTNERSSPONSORS, CNT_LRSMSPRODSERV, CNT_LRSMSPROMOTIONSOFFERS, CNT_LRSMSSURVEYSRESEARCH, CNT_TITLE, CNT_TITLE_CODE, CNT_PREF_LANGUAGE, CNT_PREF_LANGUAGE_CODE)		-- v1.3
	SELECT ID, AuditID, VWTID, AuditItemID, PhysicalRowID, Converted_ACCT_DATE_OF_BIRTH, Converted_ACCT_DATE_ADVISED_OF_DEATH, Converted_VEH_REGISTRATION_DATE, Converted_VEH_BUILD_DATE, Converted_DMS_REPAIR_ORDER_CLOSED_DATE, Converted_ROADSIDE_DATE_JOB_COMPLETED, Converted_CASE_CASE_SOLVED_DATE, Converted_VISTACONTRACT_HANDOVER_DATE, DateTransferredToVWT, SampleTriggeredSelectionReqID, ACCT_ACADEMIC_TITLE, ACCT_ACADEMIC_TITLE_CODE, ACCT_ACCT_ID, ACCT_ACCT_TYPE, ACCT_ACCT_TYPE_CODE, ACCT_ADDITIONAL_LAST_NAME, ACCT_BP_ROLE, ACCT_BUILDING, ACCT_CITY_CODE, ACCT_CITY_CODE2, ACCT_CITY_TOWN, ACCT_CITYH_CODE, ACCT_CONSENT_JAGUAR_EMAIL, ACCT_CONSENT_JAGUAR_PHONE, ACCT_CONSENT_JAGUAR_POST, ACCT_CONSENT_LAND_ROVER_EMAIL, ACCT_CONSENT_LAND_ROVER_POST, ACCT_CONSENT_LR_PHONE, ACCT_CORRESPONDENCE_LANG_CODE, ACCT_CORRESPONDENCE_LANGUAGE, ACCT_COUNTRY, ACCT_COUNTRY_CODE, ACCT_COUNTY, ACCT_COUNTY_CODE, ACCT_DATE_ADVISED_OF_DEATH, ACCT_DATE_DECL_TO_GIVE_EMAIL, ACCT_DATE_OF_BIRTH, ACCT_DEAL_FULNAME_OF_CREAT_DEA, ACCT_DISTRICT, ACCT_EMAIL_VALIDATION_STATUS, ACCT_EMPLOYER_NAME, ACCT_EXTERN_FINANC_COMP_ACCTID, ACCT_FIRST_NAME, ACCT_FLOOR, ACCT_FULL_NAME, ACCT_GENDER_FEMALE, ACCT_GENDER_MALE, ACCT_GENDER_UNKNOWN, ACCT_GENERATION, ACCT_HOME_CITY, ACCT_HOME_EMAIL_ADDR_PRIMARY, ACCT_HOME_PHONE_NUMBER, ACCT_HOUSE_NO, ACCT_HOUSE_NUM2, ACCT_HOUSE_NUM3, ACCT_INDUSTRY_SECTOR, ACCT_INDUSTRY_SECTOR_CODE, ACCT_INITIALS, ACCT_JAGUAR_IN_MARKET_DATE, ACCT_JAGUAR_LOYALTY_STATUS, ACCT_KNOWN_AS, ACCT_LAND_ROVER_LOYALTY_STATUS, ACCT_LAND_ROVER_MARKET_DATE, ACCT_LAST_NAME, ACCT_LOCATION, ACCT_MIDDLE_NAME, ACCT_MOBILE_NUMBER, ACCT_NAME_1, ACCT_NAME_2, ACCT_NAME_3, ACCT_NAME_4, ACCT_NAME_CO, ACCT_NON_ACADEMIC_TITLE, ACCT_NON_ACADEMIC_TITLE_CODE, ACCT_ORG_TYPE, ACCT_ORG_TYPE_CODE, ACCT_PCODE1_EXT, ACCT_PCODE2_EXT, ACCT_PCODE3_EXT, ACCT_PO_BOX, ACCT_PO_BOX_CTY, ACCT_PO_BOX_LOBBY, ACCT_PO_BOX_LOC, ACCT_PO_BOX_NUM, ACCT_PO_BOX_REG, ACCT_POST_CODE2, ACCT_POST_CODE3, ACCT_POSTALAREA, ACCT_POSTCODE_ZIP, ACCT_PREF_CONTACT_METHOD, ACCT_PREF_CONTACT_METHOD_CODE, ACCT_PREF_CONTACT_TIME, ACCT_PREF_LANGUAGE, ACCT_PREF_LANGUAGE_CODE, ACCT_REGION_STATE, ACCT_REGION_STATE_CODE, ACCT_ROOM_NUMBER, ACCT_STREET, ACCT_STREETABBR, ACCT_STREETCODE, ACCT_SUPPLEMENT_1, ACCT_SUPPLEMENT_2, ACCT_SUPPLEMENT_3, ACCT_TITLE, ACCT_TITLE_CODE, ACCT_TOWNSHIP, ACCT_TOWNSHIP_CODE, ACCT_VIP_FLAG, ACCT_WORK_PHONE_EXTENSION, ACCT_WORK_PHONE_PRIMARY, ACTIVITY_ID, CAMPAIGN_CAMPAIGN_CHANNEL, CAMPAIGN_CAMPAIGN_DESC, CAMPAIGN_CAMPAIGN_ID, CAMPAIGN_CATEGORY_1, CAMPAIGN_CATEGORY_2, CAMPAIGN_CATEGORY_3, CAMPAIGN_DEALERFULNAME_DEALER1, CAMPAIGN_DEALERFULNAME_DEALER2, CAMPAIGN_DEALERFULNAME_DEALER3, CAMPAIGN_DEALERFULNAME_DEALER4, CAMPAIGN_DEALERFULNAME_DEALER5, CAMPAIGN_SECDEALERCODE_DEALER1, CAMPAIGN_SECDEALERCODE_DEALER2, CAMPAIGN_SECDEALERCODE_DEALER3, CAMPAIGN_SECDEALERCODE_DEALER4, CAMPAIGN_SECDEALERCODE_DEALER5, CAMPAIGN_TARGET_GROUP_DESC, CAMPAIGN_TARGET_GROUP_ID, CASE_BRAND, CASE_BRAND_CODE, CASE_CASE_CREATION_DATE, CASE_CASE_DESC, CASE_CASE_EMPL_RESPONSIBLE_NAM, CASE_CASE_ID, CASE_CASE_SOLVED_DATE, CASE_EMPL_RESPONSIBLE_ID, CASE_GOODWILL_INDICATOR, CASE_REASON_FOR_STATUS, CASE_SECON_DEALER_CODE_OF_DEAL, CASE_VEH_REG_PLATE, CASE_VEH_VIN_NUMBER, CASE_VEHMODEL_DERIVED_FROM_VIN, CR_OBJECT_ID, CRH_DEALER_ROA_CITY_TOWN, CRH_DEALER_ROA_COUNTRY, CRH_DEALER_ROA_HOUSE_NO, CRH_DEALER_ROA_ID, CRH_DEALER_ROA_NAME_1, CRH_DEALER_ROA_NAME_2, CRH_DEALER_ROA_PO_BOX, CRH_DEALER_ROA_POSTCODE_ZIP, CRH_DEALER_ROA_PREFIX_1, CRH_DEALER_ROA_PREFIX_2, CRH_DEALER_ROA_REGION_STATE, CRH_DEALER_ROA_STREET, CRH_DEALER_ROA_SUPPLEMENT_1, CRH_DEALER_ROA_SUPPLEMENT_2, CRH_DEALER_ROA_SUPPLEMENT_3, CRH_END_DATE, CRH_START_DATE, DMS_ACTIVITY_DESC, DMS_DAYS_OPEN, DMS_EVENT_TYPE, DMS_LICENSE_PLATE_REGISTRATION, DMS_POTENTIAL_CHANGE_OF_OWNERS, DMS_REPAIR_ORDER_CLOSED_DATE, DMS_REPAIR_ORDER_NUMBER, DMS_REPAIR_ORDER_OPEN_DATE, DMS_SECON_DEALER_CODE, DMS_SERVICE_ADVISOR, DMS_SERVICE_ADVISOR_ID, DMS_TECHNICIAN_ID, DMS_TECHNICIAN, DMS_TOTAL_CUSTOMER_VISTACONTRACT_RETAIL_PRICE, DMS_USER_STATUS, DMS_USER_STATUS_CODE, DMS_VIN, LEAD_BRAND_CODE, LEAD_EMP_RESPONSIBLE_DEAL_NAME, LEAD_ENQUIRY_TYPE_CODE, LEAD_FUEL_TYPE_CODE, LEAD_IN_MARKET_DATE, LEAD_LEAD_CATEGORY_CODE, LEAD_LEAD_STATUS_CODE, LEAD_LEAD_STATUS_REASON_CODE, LEAD_MODEL_OF_INTEREST_CODE, LEAD_MODEL_YEAR, LEAD_NEW_USED_INDICATOR, LEAD_ORIGIN_CODE, LEAD_PRE_LAUNCH_MODEL, LEAD_PREF_CONTACT_METHOD, LEAD_SECON_DEALER_CODE, LEAD_VEH_SALE_TYPE_CODE, OBJECT_ID, ROADSIDE_ACTIVE_STATUS_CODE, ROADSIDE_ACTIVITY_DESC, ROADSIDE_COUNTRY_ISO_CODE, ROADSIDE_CUSTOMER_SUMMARY_INC, ROADSIDE_DATA_SOURCE, ROADSIDE_DATE_CALL_ANSWERED, ROADSIDE_DATE_CALL_RECEIVED, ROADSIDE_DATE_JOB_COMPLETED, ROADSIDE_DATE_RESOURCE_ALL, ROADSIDE_DATE_RESOURCE_ARRIVED, ROADSIDE_DATE_SECON_RES_ALL, ROADSIDE_DATE_SECON_RES_ARR, ROADSIDE_DRIVER_EMAIL, ROADSIDE_DRIVER_FIRST_NAME, ROADSIDE_DRIVER_LAST_NAME, ROADSIDE_DRIVER_MOBILE, ROADSIDE_DRIVER_TITLE, ROADSIDE_INCIDENT_CATEGORY, ROADSIDE_INCIDENT_COUNTRY, ROADSIDE_INCIDENT_DATE, ROADSIDE_INCIDENT_ID, ROADSIDE_INCIDENT_SUMMARY, ROADSIDE_INCIDENT_TIME, ROADSIDE_LICENSE_PLATE_REG_NO, ROADSIDE_PROVIDER, ROADSIDE_REPAIRING_SEC_DEAL_CD, ROADSIDE_RESOLUTION_TIME, ROADSIDE_TIME_CALL_ANSWERED, ROADSIDE_TIME_CALL_RECEIVED, ROADSIDE_TIME_JOB_COMPLETED, ROADSIDE_TIME_RESOURCE_ALL, ROADSIDE_TIME_RESOURCE_ARRIVED, ROADSIDE_TIME_SECON_RES_ALL, ROADSIDE_TIME_SECON_RES_ARR, ROADSIDE_VIN, ROADSIDE_WAIT_TIME, VEH_BRAND, VEH_BUILD_DATE, VEH_CHASSIS_NUMBER, VEH_COMMON_ORDER_NUMBER, VEH_COUNTRY_EQUIPMENT_CODE, VEH_CREATING_DEALER, VEH_CURR_PLANNED_DELIVERY_DATE, VEH_CURRENT_PLANNED_BUILD_DATE, VEH_DEA_NAME_LAST_SELLING_DEAL, VEH_DEALER_NAME_OF_SELLING_DEA, VEH_DELIVERED_DATE, VEH_DERIVATIVE, VEH_DRIVER_FULL_NAME, VEH_ENGINE_SIZE, VEH_EXTERIOR_COLOUR_CODE, VEH_EXTERIOR_COLOUR_DESC, VEH_EXTERIOR_COLOUR_SUPPL_CODE, VEH_EXTERIOR_COLOUR_SUPPL_DESC, VEH_FEATURE_CODE, VEH_FINANCE_PROD, VEH_FIRST_RETAIL_SALE, VEH_FUEL_TYPE_CODE, VEH_MODEL, VEH_MODEL_DESC, VEH_MODEL_YEAR, VEH_NUM_OF_OWNERS_RELATIONSHIP, VEH_ORIGIN, VEH_OWNERSHIP_STATUS, VEH_OWNERSHIP_STATUS_CODE, VEH_PAYMENT_TYPE, VEH_PREDICTED_REPLACEMENT_DATE, VEH_REACQUIRED_INDICATOR, VEH_REGISTRAT_LICENC_PLATE_NUM, VEH_REGISTRATION_DATE, VEH_SALE_TYPE_DESC, VEH_VIN, VEH_VISTA_CONTRACT_NUMBER, VISTACONTRACT_COMM_TY_SALE_DS, VISTACONTRACT_HANDOVER_DATE, VISTACONTRACT_PREV_VEH_BRAND, VISTACONTRACT_PREV_VEH_MODEL, VISTACONTRACT_SALES_MAN_CD_DES, VISTACONTRACT_SALES_MAN_FULNAM, VISTACONTRACT_SALESMAN_CODE, VISTACONTRACT_SECON_DEALER_CD, VISTACONTRACT_TRADE_IN_MANUFAC, VISTACONTRACT_TRADE_IN_MODEL, VISTACONTRACT_ACTIVITY_CATEGRY, VISTACONTRACT_RETAIL_PRICE, VEH_APPR_WARNTY_TYPE, VEH_APPR_WARNTY_TYPE_DESC, VISTACONTRACTNAPPRO_RETAIL_WAR, VISTACONTRACTNAPPRO_RETAIL_DES, VISTACONTRACT_EXT_WARR, VISTACONTRACT_EXT_WARR_DESC, ACCT_CONSENT_JAGUAR_FAX, ACCT_CONSENT_LAND_ROVER_FAX, ACCT_CONSENT_JAGUAR_CHAT, ACCT_CONSENT_LAND_ROVER_CHAT, ACCT_CONSENT_JAGUAR_SMS, ACCT_CONSENT_LAND_ROVER_SMS, ACCT_CONSENT_JAGUAR_SMEDIA, ACCT_CONSENT_LAND_ROVER_SMEDIA, ACCT_CONSENT_OVER_CONT_SUP_JAG, ACCT_CONSENT_OVER_CONT_SUP_LR, ACCT_CONSENT_JAGUAR_PTSMR, ACCT_CONSENT_LAND_ROVER_PTSMR, ACCT_CONSENT_JAGUAR_PTVSM, ACCT_CONSENT_LAND_ROVER_PTVSM, ACCT_CONSENT_JAGUAR_PTAM, ACCT_CONSENT_LAND_ROVER_PTAM, ACCT_CONSENT_JAGUAR_PTNAU, ACCT_CONSENT_LAND_ROVER_PTNAU, ACCT_CONSENT_JAGUAR_PEVENT, ACCT_CONSENT_LAND_ROVER_PEVENT, ACCT_CONSENT_JAGUAR_PND3P, ACCT_CONSENT_LAND_ROVER_PND3P, ACCT_CONSENT_JAGUAR_PTSDWD, ACCT_CONSENT_LAND_ROVER_PTSDWD, ACCT_CONSENT_JAGUAR_PTPA, ACCT_CONSENT_LAND_ROVER_PTPA, RESPONSE_ID, DMS_OTHER_RELATED_SERVICES, VEH_SALE_TYPE_CODE, VISTACONTRACT_COMM_TY_SALE_CD, LEAD_STATUS_REASON_LEV1_DESC, LEAD_STATUS_REASON_LEV1_COD, LEAD_STATUS_REASON_LEV2_DESC, LEAD_STATUS_REASON_LEV2_COD, LEAD_STATUS_REASON_LEV3_DESC, LEAD_STATUS_REASON_LEV3_COD, JAGDIGITALEVENTSEXP, JAGDIGITALINCONTROL, JAGDIGITALOWNERVEHCOMM, JAGDIGITALPARTNERSSPONSORS, JAGDIGITALPRODSERV, JAGDIGITALPROMOTIONSOFFERS, JAGDIGITALSURVEYSRESEARCH, JAGEMAILEVENTSEXP, JAGEMAILINCONTROL, JAGEMAILOWNERVEHCOMM, JAGEMAILPARTNERSSPONSORS, JAGEMAILPRODSERV, JAGEMAILPROMOTIONSOFFERS, JAGEMAILSURVEYSRESEARCH, JAGPHONEEVENTSEXP, JAGPHONEINCONTROL, JAGPHONEOWNERVEHCOMM, JAGPHONEPARTNERSSPONSORS, JAGPHONEPRODSERV, JAGPHONEPROMOTIONSOFFERS, JAGPHONESURVEYSRESEARCH, JAGPOSTEVENTSEXP, JAGPOSTINCONTROL, JAGPOSTOWNERVEHCOMM, JAGPOSTPARTNERSSPONSORS, JAGPOSTPRODSERV, JAGPOSTPROMOTIONSOFFERS, JAGPOSTSURVEYSRESEARCH, JAGSMSEVENTSEXP, JAGSMSINCONTROL, JAGSMSOWNERVEHCOMM, JAGSMSPARTNERSSPONSORS, JAGSMSPRODSERV, JAGSMSPROMOTIONSOFFERS, JAGSMSSURVEYSRESEARCH, LRDIGITALEVENTSEXP, LRDIGITALINCONTROL, LRDIGITALOWNERVEHCOMM, LRDIGITALPARTNERSSPONSORS, LRDIGITALPRODSERV, LRDIGITALPROMOTIONSOFFERS, LRDIGITALSURVEYSRESEARCH, LREMAILEVENTSEXP, LREMAILINCONTROL, LREMAILOWNERVEHCOMM, LREMAILPARTNERSSPONSORS, LREMAILPRODSERV, LREMAILPROMOTIONSOFFERS, LREMAILSURVEYSRESEARCH, LRPHONEEVENTSEXP, LRPHONEINCONTROL, LRPHONEOWNERVEHCOMM, LRPHONEPARTNERSSPONSORS, LRPHONEPRODSERV, LRPHONEPROMOTIONSOFFERS, LRPHONESURVEYSRESEARCH, LRPOSTEVENTSEXP, LRPOSTINCONTROL, LRPOSTOWNERVEHCOMM, LRPOSTPARTNERSSPONSORS, LRPOSTPRODSERV, LRPOSTPROMOTIONSOFFERS, LRPOSTSURVEYSRESEARCH, LRSMSEVENTSEXP, LRSMSINCONTROL, LRSMSOWNERVEHCOMM, LRSMSPARTNERSSPONSORS, LRSMSPRODSERV, LRSMSPROMOTIONSOFFERS, LRSMSSURVEYSRESEARCH, ACCT_NAME_PREFIX_CODE, ACCT_NAME_PREFIX, DMS_REPAIR_ORDER_NUMBER_UNIQUE, DMS_TOTAL_CUSTOMER_PRICE, VISTACONTRACT_COMMON_ORDER_NUM, VEH_FUEL_TYPE, CNT_ABTNR, CNT_ADDRESS, CNT_DPRTMNT, CNT_FIRST_NAME, CNT_FNCTN, CNT_LAST_NAME, CNT_PAFKT, CNT_RELTYP, CNT_TEL_NUMBER, CONTACT_PER_ID, ACCT_NAME_CREATING_DEA, CNT_MOBILE_PHONE, CNT_ACADEMIC_TITLE, CNT_ACADEMIC_TITLE_CODE, CNT_NAME_PREFIX_CODE, CNT_NAME_PREFIX, CNT_JAGDIGITALEVENTSEXP, CNT_JAGDIGITALINCONTROL, CNT_JAGDIGITALOWNERVEHCOMM, CNT_JAGDIGITALPARTNERSSPONSORS, CNT_JAGDIGITALPRODSERV, CNT_JAGDIGITALPROMOTIONSOFFERS, CNT_JAGDIGITALSURVEYSRESEARCH, CNT_JAGEMAILEVENTSEXP, CNT_JAGEMAILINCONTROL, CNT_JAGEMAILOWNERVEHCOMM, CNT_JAGEMAILPARTNERSSPONSORS, CNT_JAGEMAILPRODSERV, CNT_JAGEMAILPROMOTIONSOFFERS, CNT_JAGEMAILSURVEYSRESEARCH, CNT_JAGPHONEEVENTSEXP, CNT_JAGPHONEINCONTROL, CNT_JAGPHONEOWNERVEHCOMM, CNT_JAGPHONEPARTNERSSPONSORS, CNT_JAGPHONEPRODSERV, CNT_JAGPHONEPROMOTIONSOFFERS, CNT_JAGPHONESURVEYSRESEARCH, CNT_JAGPOSTEVENTSEXP, CNT_JAGPOSTINCONTROL, CNT_JAGPOSTOWNERVEHCOMM, CNT_JAGPOSTPARTNERSSPONSORS, CNT_JAGPOSTPRODSERV, CNT_JAGPOSTPROMOTIONSOFFERS, CNT_JAGPOSTSURVEYSRESEARCH, CNT_JAGSMSEVENTSEXP, CNT_JAGSMSINCONTROL, CNT_JAGSMSOWNERVEHCOMM, CNT_JAGSMSPARTNERSSPONSORS, CNT_JAGSMSPRODSERV, CNT_JAGSMSPROMOTIONSOFFERS, CNT_JAGSMSSURVEYSRESEARCH, CNT_LRDIGITALEVENTSEXP, CNT_LRDIGITALINCONTROL, CNT_LRDIGITALOWNERVEHCOMM, CNT_LRDIGITALPARTNERSSPONSORS, CNT_LRDIGITALPRODSERV, CNT_LRDIGITALPROMOTIONSOFFERS, CNT_LRDIGITALSURVEYSRESEARCH, CNT_LREMAILEVENTSEXP, CNT_LREMAILINCONTROL, CNT_LREMAILOWNERVEHCOMM, CNT_LREMAILPARTNERSSPONSORS, CNT_LREMAILPRODSERV, CNT_LREMAILPROMOTIONSOFFERS, CNT_LREMAILSURVEYSRESEARCH, CNT_LRPHONEEVENTSEXP, CNT_LRPHONEINCONTROL, CNT_LRPHONEOWNERVEHCOMM, CNT_LRPHONEPARTNERSSPONSORS, CNT_LRPHONEPRODSERV, CNT_LRPHONEPROMOTIONSOFFERS, CNT_LRPHONESURVEYSRESEARCH, CNT_LRPOSTEVENTSEXP, CNT_LRPOSTINCONTROL, CNT_LRPOSTOWNERVEHCOMM, CNT_LRPOSTPARTNERSSPONSORS, CNT_LRPOSTPRODSERV, CNT_LRPOSTPROMOTIONSOFFERS, CNT_LRPOSTSURVEYSRESEARCH, CNT_LRSMSEVENTSEXP, CNT_LRSMSINCONTROL, CNT_LRSMSOWNERVEHCOMM, CNT_LRSMSPARTNERSSPONSORS, CNT_LRSMSPRODSERV, CNT_LRSMSPROMOTIONSOFFERS, CNT_LRSMSSURVEYSRESEARCH, CNT_TITLE, CNT_TITLE_CODE, CNT_PREF_LANGUAGE, CNT_PREF_LANGUAGE_CODE		-- v1.3
	FROM CRM.CRCCall_Call crm 
	WHERE crm.AuditID = @AuditID

	-- Delete the records from the CRM holding table
	DELETE
	FROM CRM.CRCCall_Call
	WHERE AuditID = @AuditID
	

	-----------------------------------------------------------------------------------------------------------------------------
	-- CRM.DMS_Repair_Service
	-----------------------------------------------------------------------------------------------------------------------------
	

	-- Save records prior to removing them
	INSERT INTO [$(AuditDB)].RollbackSample.CRM_DMS_Repair_Service (ID, AuditID, VWTID, AuditItemID, PhysicalRowID, Converted_ACCT_DATE_OF_BIRTH, Converted_ACCT_DATE_ADVISED_OF_DEATH, Converted_VEH_REGISTRATION_DATE, Converted_VEH_BUILD_DATE, Converted_DMS_REPAIR_ORDER_CLOSED_DATE, Converted_ROADSIDE_DATE_JOB_COMPLETED, Converted_CASE_CASE_SOLVED_DATE, Converted_VISTACONTRACT_HANDOVER_DATE, DateTransferredToVWT, SampleTriggeredSelectionReqID, ACCT_ACADEMIC_TITLE, ACCT_ACADEMIC_TITLE_CODE, ACCT_ACCT_ID, ACCT_ACCT_TYPE, ACCT_ACCT_TYPE_CODE, ACCT_ADDITIONAL_LAST_NAME, ACCT_BP_ROLE, ACCT_BUILDING, ACCT_CITY_CODE, ACCT_CITY_CODE2, ACCT_CITY_TOWN, ACCT_CITYH_CODE, ACCT_CONSENT_JAGUAR_EMAIL, ACCT_CONSENT_JAGUAR_PHONE, ACCT_CONSENT_JAGUAR_POST, ACCT_CONSENT_LAND_ROVER_EMAIL, ACCT_CONSENT_LAND_ROVER_POST, ACCT_CONSENT_LR_PHONE, ACCT_CORRESPONDENCE_LANG_CODE, ACCT_CORRESPONDENCE_LANGUAGE, ACCT_COUNTRY, ACCT_COUNTRY_CODE, ACCT_COUNTY, ACCT_COUNTY_CODE, ACCT_DATE_ADVISED_OF_DEATH, ACCT_DATE_DECL_TO_GIVE_EMAIL, ACCT_DATE_OF_BIRTH, ACCT_DEAL_FULNAME_OF_CREAT_DEA, ACCT_DISTRICT, ACCT_EMAIL_VALIDATION_STATUS, ACCT_EMPLOYER_NAME, ACCT_EXTERN_FINANC_COMP_ACCTID, ACCT_FIRST_NAME, ACCT_FLOOR, ACCT_FULL_NAME, ACCT_GENDER_FEMALE, ACCT_GENDER_MALE, ACCT_GENDER_UNKNOWN, ACCT_GENERATION, ACCT_HOME_CITY, ACCT_HOME_EMAIL_ADDR_PRIMARY, ACCT_HOME_PHONE_NUMBER, ACCT_HOUSE_NO, ACCT_HOUSE_NUM2, ACCT_HOUSE_NUM3, ACCT_INDUSTRY_SECTOR, ACCT_INDUSTRY_SECTOR_CODE, ACCT_INITIALS, ACCT_JAGUAR_IN_MARKET_DATE, ACCT_JAGUAR_LOYALTY_STATUS, ACCT_KNOWN_AS, ACCT_LAND_ROVER_LOYALTY_STATUS, ACCT_LAND_ROVER_MARKET_DATE, ACCT_LAST_NAME, ACCT_LOCATION, ACCT_MIDDLE_NAME, ACCT_MOBILE_NUMBER, ACCT_NAME_1, ACCT_NAME_2, ACCT_NAME_3, ACCT_NAME_4, ACCT_NAME_CO, ACCT_NON_ACADEMIC_TITLE, ACCT_NON_ACADEMIC_TITLE_CODE, ACCT_ORG_TYPE, ACCT_ORG_TYPE_CODE, ACCT_PCODE1_EXT, ACCT_PCODE2_EXT, ACCT_PCODE3_EXT, ACCT_PO_BOX, ACCT_PO_BOX_CTY, ACCT_PO_BOX_LOBBY, ACCT_PO_BOX_LOC, ACCT_PO_BOX_NUM, ACCT_PO_BOX_REG, ACCT_POST_CODE2, ACCT_POST_CODE3, ACCT_POSTALAREA, ACCT_POSTCODE_ZIP, ACCT_PREF_CONTACT_METHOD, ACCT_PREF_CONTACT_METHOD_CODE, ACCT_PREF_CONTACT_TIME, ACCT_PREF_LANGUAGE, ACCT_PREF_LANGUAGE_CODE, ACCT_REGION_STATE, ACCT_REGION_STATE_CODE, ACCT_ROOM_NUMBER, ACCT_STREET, ACCT_STREETABBR, ACCT_STREETCODE, ACCT_SUPPLEMENT_1, ACCT_SUPPLEMENT_2, ACCT_SUPPLEMENT_3, ACCT_TITLE, ACCT_TITLE_CODE, ACCT_TOWNSHIP, ACCT_TOWNSHIP_CODE, ACCT_VIP_FLAG, ACCT_WORK_PHONE_EXTENSION, ACCT_WORK_PHONE_PRIMARY, ACTIVITY_ID, CAMPAIGN_CAMPAIGN_CHANNEL, CAMPAIGN_CAMPAIGN_DESC, CAMPAIGN_CAMPAIGN_ID, CAMPAIGN_CATEGORY_1, CAMPAIGN_CATEGORY_2, CAMPAIGN_CATEGORY_3, CAMPAIGN_DEALERFULNAME_DEALER1, CAMPAIGN_DEALERFULNAME_DEALER2, CAMPAIGN_DEALERFULNAME_DEALER3, CAMPAIGN_DEALERFULNAME_DEALER4, CAMPAIGN_DEALERFULNAME_DEALER5, CAMPAIGN_SECDEALERCODE_DEALER1, CAMPAIGN_SECDEALERCODE_DEALER2, CAMPAIGN_SECDEALERCODE_DEALER3, CAMPAIGN_SECDEALERCODE_DEALER4, CAMPAIGN_SECDEALERCODE_DEALER5, CAMPAIGN_TARGET_GROUP_DESC, CAMPAIGN_TARGET_GROUP_ID, CASE_BRAND, CASE_BRAND_CODE, CASE_CASE_CREATION_DATE, CASE_CASE_DESC, CASE_CASE_EMPL_RESPONSIBLE_NAM, CASE_CASE_ID, CASE_CASE_SOLVED_DATE, CASE_EMPL_RESPONSIBLE_ID, CASE_GOODWILL_INDICATOR, CASE_REASON_FOR_STATUS, CASE_SECON_DEALER_CODE_OF_DEAL, CASE_VEH_REG_PLATE, CASE_VEH_VIN_NUMBER, CASE_VEHMODEL_DERIVED_FROM_VIN, CR_OBJECT_ID, CRH_DEALER_ROA_CITY_TOWN, CRH_DEALER_ROA_COUNTRY, CRH_DEALER_ROA_HOUSE_NO, CRH_DEALER_ROA_ID, CRH_DEALER_ROA_NAME_1, CRH_DEALER_ROA_NAME_2, CRH_DEALER_ROA_PO_BOX, CRH_DEALER_ROA_POSTCODE_ZIP, CRH_DEALER_ROA_PREFIX_1, CRH_DEALER_ROA_PREFIX_2, CRH_DEALER_ROA_REGION_STATE, CRH_DEALER_ROA_STREET, CRH_DEALER_ROA_SUPPLEMENT_1, CRH_DEALER_ROA_SUPPLEMENT_2, CRH_DEALER_ROA_SUPPLEMENT_3, CRH_END_DATE, CRH_START_DATE, DMS_ACTIVITY_DESC, DMS_DAYS_OPEN, DMS_EVENT_TYPE, DMS_LICENSE_PLATE_REGISTRATION, DMS_POTENTIAL_CHANGE_OF_OWNERS, DMS_REPAIR_ORDER_CLOSED_DATE, DMS_REPAIR_ORDER_NUMBER, DMS_REPAIR_ORDER_OPEN_DATE, DMS_SECON_DEALER_CODE, DMS_SERVICE_ADVISOR, DMS_SERVICE_ADVISOR_ID, DMS_TECHNICIAN_ID, DMS_TECHNICIAN, DMS_TOTAL_CUSTOMER_PRICE, DMS_USER_STATUS, DMS_USER_STATUS_CODE, DMS_VIN, LEAD_BRAND_CODE, LEAD_EMP_RESPONSIBLE_DEAL_NAME, LEAD_ENQUIRY_TYPE_CODE, LEAD_FUEL_TYPE_CODE, LEAD_IN_MARKET_DATE, LEAD_LEAD_CATEGORY_CODE, LEAD_LEAD_STATUS_CODE, LEAD_LEAD_STATUS_REASON_CODE, LEAD_MODEL_OF_INTEREST_CODE, LEAD_MODEL_YEAR, LEAD_NEW_USED_INDICATOR, LEAD_ORIGIN_CODE, LEAD_PRE_LAUNCH_MODEL, LEAD_PREF_CONTACT_METHOD, LEAD_SECON_DEALER_CODE, LEAD_VEH_SALE_TYPE_CODE, OBJECT_ID, ROADSIDE_ACTIVE_STATUS_CODE, ROADSIDE_ACTIVITY_DESC, ROADSIDE_COUNTRY_ISO_CODE, ROADSIDE_CUSTOMER_SUMMARY_INC, ROADSIDE_DATA_SOURCE, ROADSIDE_DATE_CALL_ANSWERED, ROADSIDE_DATE_CALL_RECEIVED, ROADSIDE_DATE_JOB_COMPLETED, ROADSIDE_DATE_RESOURCE_ALL, ROADSIDE_DATE_RESOURCE_ARRIVED, ROADSIDE_DATE_SECON_RES_ALL, ROADSIDE_DATE_SECON_RES_ARR, ROADSIDE_DRIVER_EMAIL, ROADSIDE_DRIVER_FIRST_NAME, ROADSIDE_DRIVER_LAST_NAME, ROADSIDE_DRIVER_MOBILE, ROADSIDE_DRIVER_TITLE, ROADSIDE_INCIDENT_CATEGORY, ROADSIDE_INCIDENT_COUNTRY, ROADSIDE_INCIDENT_DATE, ROADSIDE_INCIDENT_ID, ROADSIDE_INCIDENT_SUMMARY, ROADSIDE_INCIDENT_TIME, ROADSIDE_LICENSE_PLATE_REG_NO, ROADSIDE_PROVIDER, ROADSIDE_REPAIRING_SEC_DEAL_CD, ROADSIDE_RESOLUTION_TIME, ROADSIDE_TIME_CALL_ANSWERED, ROADSIDE_TIME_CALL_RECEIVED, ROADSIDE_TIME_JOB_COMPLETED, ROADSIDE_TIME_RESOURCE_ALL, ROADSIDE_TIME_RESOURCE_ARRIVED, ROADSIDE_TIME_SECON_RES_ALL, ROADSIDE_TIME_SECON_RES_ARR, ROADSIDE_VIN, ROADSIDE_WAIT_TIME, VEH_BRAND, VEH_BUILD_DATE, VEH_CHASSIS_NUMBER, VEH_COMMON_ORDER_NUMBER, VEH_COUNTRY_EQUIPMENT_CODE, VEH_CREATING_DEALER, VEH_CURR_PLANNED_DELIVERY_DATE, VEH_CURRENT_PLANNED_BUILD_DATE, VEH_DEA_NAME_LAST_SELLING_DEAL, VEH_DEALER_NAME_OF_SELLING_DEA, VEH_DELIVERED_DATE, VEH_DERIVATIVE, VEH_DRIVER_FULL_NAME, VEH_ENGINE_SIZE, VEH_EXTERIOR_COLOUR_CODE, VEH_EXTERIOR_COLOUR_DESC, VEH_EXTERIOR_COLOUR_SUPPL_CODE, VEH_EXTERIOR_COLOUR_SUPPL_DESC, VEH_FEATURE_CODE, VEH_FINANCE_PROD, VEH_FIRST_RETAIL_SALE, VEH_FUEL_TYPE_CODE, VEH_MODEL, VEH_MODEL_DESC, VEH_MODEL_YEAR, VEH_NUM_OF_OWNERS_RELATIONSHIP, VEH_ORIGIN, VEH_OWNERSHIP_STATUS, VEH_OWNERSHIP_STATUS_CODE, VEH_PAYMENT_TYPE, VEH_PREDICTED_REPLACEMENT_DATE, VEH_REACQUIRED_INDICATOR, VEH_REGISTRAT_LICENC_PLATE_NUM, VEH_REGISTRATION_DATE, VEH_SALE_TYPE_DESC, VEH_VIN, VEH_VISTA_CONTRACT_NUMBER, VISTACONTRACT_COMM_TY_SALE_DS, VISTACONTRACT_HANDOVER_DATE, VISTACONTRACT_PREV_VEH_BRAND, VISTACONTRACT_PREV_VEH_MODEL, VISTACONTRACT_SALES_MAN_CD_DES, VISTACONTRACT_SALES_MAN_FULNAM, VISTACONTRACT_SALESMAN_CODE, VISTACONTRACT_SECON_DEALER_CD, VISTACONTRACT_TRADE_IN_MANUFAC, VISTACONTRACT_TRADE_IN_MODEL, VISTACONTRACT_ACTIVITY_CATEGRY, VISTACONTRACT_RETAIL_PRICE, VEH_APPR_WARNTY_TYPE, VEH_APPR_WARNTY_TYPE_DESC, VISTACONTRACTNAPPRO_RETAIL_WAR, VISTACONTRACTNAPPRO_RETAIL_DES, VISTACONTRACT_EXT_WARR, VISTACONTRACT_EXT_WARR_DESC, ACCT_CONSENT_JAGUAR_FAX, ACCT_CONSENT_LAND_ROVER_FAX, ACCT_CONSENT_JAGUAR_CHAT, ACCT_CONSENT_LAND_ROVER_CHAT, ACCT_CONSENT_JAGUAR_SMS, ACCT_CONSENT_LAND_ROVER_SMS, ACCT_CONSENT_JAGUAR_SMEDIA, ACCT_CONSENT_LAND_ROVER_SMEDIA, ACCT_CONSENT_OVER_CONT_SUP_JAG, ACCT_CONSENT_OVER_CONT_SUP_LR, ACCT_CONSENT_JAGUAR_PTSMR, ACCT_CONSENT_LAND_ROVER_PTSMR, ACCT_CONSENT_JAGUAR_PTVSM, ACCT_CONSENT_LAND_ROVER_PTVSM, ACCT_CONSENT_JAGUAR_PTAM, ACCT_CONSENT_LAND_ROVER_PTAM, ACCT_CONSENT_JAGUAR_PTNAU, ACCT_CONSENT_LAND_ROVER_PTNAU, ACCT_CONSENT_JAGUAR_PEVENT, ACCT_CONSENT_LAND_ROVER_PEVENT, ACCT_CONSENT_JAGUAR_PND3P, ACCT_CONSENT_LAND_ROVER_PND3P, ACCT_CONSENT_JAGUAR_PTSDWD, ACCT_CONSENT_LAND_ROVER_PTSDWD, ACCT_CONSENT_JAGUAR_PTPA, ACCT_CONSENT_LAND_ROVER_PTPA, RESPONSE_ID, DMS_REPAIR_ORDER_NUMBER_UNIQUE, DMS_OTHER_RELATED_SERVICES, PDI_Flag, VEH_SALE_TYPE_CODE, VISTACONTRACT_COMM_TY_SALE_CD, LEAD_STATUS_REASON_LEV1_DESC, LEAD_STATUS_REASON_LEV1_COD, LEAD_STATUS_REASON_LEV2_DESC, LEAD_STATUS_REASON_LEV2_COD, LEAD_STATUS_REASON_LEV3_DESC, LEAD_STATUS_REASON_LEV3_COD, JAGDIGITALEVENTSEXP, JAGDIGITALINCONTROL, JAGDIGITALOWNERVEHCOMM, JAGDIGITALPARTNERSSPONSORS, JAGDIGITALPRODSERV, JAGDIGITALPROMOTIONSOFFERS, JAGDIGITALSURVEYSRESEARCH, JAGEMAILEVENTSEXP, JAGEMAILINCONTROL, JAGEMAILOWNERVEHCOMM, JAGEMAILPARTNERSSPONSORS, JAGEMAILPRODSERV, JAGEMAILPROMOTIONSOFFERS, JAGEMAILSURVEYSRESEARCH, JAGPHONEEVENTSEXP, JAGPHONEINCONTROL, JAGPHONEOWNERVEHCOMM, JAGPHONEPARTNERSSPONSORS, JAGPHONEPRODSERV, JAGPHONEPROMOTIONSOFFERS, JAGPHONESURVEYSRESEARCH, JAGPOSTEVENTSEXP, JAGPOSTINCONTROL, JAGPOSTOWNERVEHCOMM, JAGPOSTPARTNERSSPONSORS, JAGPOSTPRODSERV, JAGPOSTPROMOTIONSOFFERS, JAGPOSTSURVEYSRESEARCH, JAGSMSEVENTSEXP, JAGSMSINCONTROL, JAGSMSOWNERVEHCOMM, JAGSMSPARTNERSSPONSORS, JAGSMSPRODSERV, JAGSMSPROMOTIONSOFFERS, JAGSMSSURVEYSRESEARCH, LRDIGITALEVENTSEXP, LRDIGITALINCONTROL, LRDIGITALOWNERVEHCOMM, LRDIGITALPARTNERSSPONSORS, LRDIGITALPRODSERV, LRDIGITALPROMOTIONSOFFERS, LRDIGITALSURVEYSRESEARCH, LREMAILEVENTSEXP, LREMAILINCONTROL, LREMAILOWNERVEHCOMM, LREMAILPARTNERSSPONSORS, LREMAILPRODSERV, LREMAILPROMOTIONSOFFERS, LREMAILSURVEYSRESEARCH, LRPHONEEVENTSEXP, LRPHONEINCONTROL, LRPHONEOWNERVEHCOMM, LRPHONEPARTNERSSPONSORS, LRPHONEPRODSERV, LRPHONEPROMOTIONSOFFERS, LRPHONESURVEYSRESEARCH, LRPOSTEVENTSEXP, LRPOSTINCONTROL, LRPOSTOWNERVEHCOMM, LRPOSTPARTNERSSPONSORS, LRPOSTPRODSERV, LRPOSTPROMOTIONSOFFERS, LRPOSTSURVEYSRESEARCH, LRSMSEVENTSEXP, LRSMSINCONTROL, LRSMSOWNERVEHCOMM, LRSMSPARTNERSSPONSORS, LRSMSPRODSERV, LRSMSPROMOTIONSOFFERS, LRSMSSURVEYSRESEARCH, ACCT_NAME_PREFIX_CODE, ACCT_NAME_PREFIX, VISTACONTRACT_COMMON_ORDER_NUM, VEH_FUEL_TYPE, CNT_ABTNR, CNT_ADDRESS, CNT_DPRTMNT, CNT_FIRST_NAME, CNT_FNCTN, CNT_LAST_NAME, CNT_PAFKT, CNT_RELTYP, CNT_TEL_NUMBER, CONTACT_PER_ID, ACCT_NAME_CREATING_DEA, CNT_MOBILE_PHONE, CNT_ACADEMIC_TITLE, CNT_ACADEMIC_TITLE_CODE, CNT_NAME_PREFIX_CODE, CNT_NAME_PREFIX, CNT_JAGDIGITALEVENTSEXP, CNT_JAGDIGITALINCONTROL, CNT_JAGDIGITALOWNERVEHCOMM, CNT_JAGDIGITALPARTNERSSPONSORS, CNT_JAGDIGITALPRODSERV, CNT_JAGDIGITALPROMOTIONSOFFERS, CNT_JAGDIGITALSURVEYSRESEARCH, CNT_JAGEMAILEVENTSEXP, CNT_JAGEMAILINCONTROL, CNT_JAGEMAILOWNERVEHCOMM, CNT_JAGEMAILPARTNERSSPONSORS, CNT_JAGEMAILPRODSERV, CNT_JAGEMAILPROMOTIONSOFFERS, CNT_JAGEMAILSURVEYSRESEARCH, CNT_JAGPHONEEVENTSEXP, CNT_JAGPHONEINCONTROL, CNT_JAGPHONEOWNERVEHCOMM, CNT_JAGPHONEPARTNERSSPONSORS, CNT_JAGPHONEPRODSERV, CNT_JAGPHONEPROMOTIONSOFFERS, CNT_JAGPHONESURVEYSRESEARCH, CNT_JAGPOSTEVENTSEXP, CNT_JAGPOSTINCONTROL, CNT_JAGPOSTOWNERVEHCOMM, CNT_JAGPOSTPARTNERSSPONSORS, CNT_JAGPOSTPRODSERV, CNT_JAGPOSTPROMOTIONSOFFERS, CNT_JAGPOSTSURVEYSRESEARCH, CNT_JAGSMSEVENTSEXP, CNT_JAGSMSINCONTROL, CNT_JAGSMSOWNERVEHCOMM, CNT_JAGSMSPARTNERSSPONSORS, CNT_JAGSMSPRODSERV, CNT_JAGSMSPROMOTIONSOFFERS, CNT_JAGSMSSURVEYSRESEARCH, CNT_LRDIGITALEVENTSEXP, CNT_LRDIGITALINCONTROL, CNT_LRDIGITALOWNERVEHCOMM, CNT_LRDIGITALPARTNERSSPONSORS, CNT_LRDIGITALPRODSERV, CNT_LRDIGITALPROMOTIONSOFFERS, CNT_LRDIGITALSURVEYSRESEARCH, CNT_LREMAILEVENTSEXP, CNT_LREMAILINCONTROL, CNT_LREMAILOWNERVEHCOMM, CNT_LREMAILPARTNERSSPONSORS, CNT_LREMAILPRODSERV, CNT_LREMAILPROMOTIONSOFFERS, CNT_LREMAILSURVEYSRESEARCH, CNT_LRPHONEEVENTSEXP, CNT_LRPHONEINCONTROL, CNT_LRPHONEOWNERVEHCOMM, CNT_LRPHONEPARTNERSSPONSORS, CNT_LRPHONEPRODSERV, CNT_LRPHONEPROMOTIONSOFFERS, CNT_LRPHONESURVEYSRESEARCH, CNT_LRPOSTEVENTSEXP, CNT_LRPOSTINCONTROL, CNT_LRPOSTOWNERVEHCOMM, CNT_LRPOSTPARTNERSSPONSORS, CNT_LRPOSTPRODSERV, CNT_LRPOSTPROMOTIONSOFFERS, CNT_LRPOSTSURVEYSRESEARCH, CNT_LRSMSEVENTSEXP, CNT_LRSMSINCONTROL, CNT_LRSMSOWNERVEHCOMM, CNT_LRSMSPARTNERSSPONSORS, CNT_LRSMSPRODSERV, CNT_LRSMSPROMOTIONSOFFERS, CNT_LRSMSSURVEYSRESEARCH, CNT_TITLE, CNT_TITLE_CODE, CNT_PREF_LANGUAGE, CNT_PREF_LANGUAGE_CODE)		-- v1.3
	SELECT ID, AuditID, VWTID, AuditItemID, PhysicalRowID, Converted_ACCT_DATE_OF_BIRTH, Converted_ACCT_DATE_ADVISED_OF_DEATH, Converted_VEH_REGISTRATION_DATE, Converted_VEH_BUILD_DATE, Converted_DMS_REPAIR_ORDER_CLOSED_DATE, Converted_ROADSIDE_DATE_JOB_COMPLETED, Converted_CASE_CASE_SOLVED_DATE, Converted_VISTACONTRACT_HANDOVER_DATE, DateTransferredToVWT, SampleTriggeredSelectionReqID, ACCT_ACADEMIC_TITLE, ACCT_ACADEMIC_TITLE_CODE, ACCT_ACCT_ID, ACCT_ACCT_TYPE, ACCT_ACCT_TYPE_CODE, ACCT_ADDITIONAL_LAST_NAME, ACCT_BP_ROLE, ACCT_BUILDING, ACCT_CITY_CODE, ACCT_CITY_CODE2, ACCT_CITY_TOWN, ACCT_CITYH_CODE, ACCT_CONSENT_JAGUAR_EMAIL, ACCT_CONSENT_JAGUAR_PHONE, ACCT_CONSENT_JAGUAR_POST, ACCT_CONSENT_LAND_ROVER_EMAIL, ACCT_CONSENT_LAND_ROVER_POST, ACCT_CONSENT_LR_PHONE, ACCT_CORRESPONDENCE_LANG_CODE, ACCT_CORRESPONDENCE_LANGUAGE, ACCT_COUNTRY, ACCT_COUNTRY_CODE, ACCT_COUNTY, ACCT_COUNTY_CODE, ACCT_DATE_ADVISED_OF_DEATH, ACCT_DATE_DECL_TO_GIVE_EMAIL, ACCT_DATE_OF_BIRTH, ACCT_DEAL_FULNAME_OF_CREAT_DEA, ACCT_DISTRICT, ACCT_EMAIL_VALIDATION_STATUS, ACCT_EMPLOYER_NAME, ACCT_EXTERN_FINANC_COMP_ACCTID, ACCT_FIRST_NAME, ACCT_FLOOR, ACCT_FULL_NAME, ACCT_GENDER_FEMALE, ACCT_GENDER_MALE, ACCT_GENDER_UNKNOWN, ACCT_GENERATION, ACCT_HOME_CITY, ACCT_HOME_EMAIL_ADDR_PRIMARY, ACCT_HOME_PHONE_NUMBER, ACCT_HOUSE_NO, ACCT_HOUSE_NUM2, ACCT_HOUSE_NUM3, ACCT_INDUSTRY_SECTOR, ACCT_INDUSTRY_SECTOR_CODE, ACCT_INITIALS, ACCT_JAGUAR_IN_MARKET_DATE, ACCT_JAGUAR_LOYALTY_STATUS, ACCT_KNOWN_AS, ACCT_LAND_ROVER_LOYALTY_STATUS, ACCT_LAND_ROVER_MARKET_DATE, ACCT_LAST_NAME, ACCT_LOCATION, ACCT_MIDDLE_NAME, ACCT_MOBILE_NUMBER, ACCT_NAME_1, ACCT_NAME_2, ACCT_NAME_3, ACCT_NAME_4, ACCT_NAME_CO, ACCT_NON_ACADEMIC_TITLE, ACCT_NON_ACADEMIC_TITLE_CODE, ACCT_ORG_TYPE, ACCT_ORG_TYPE_CODE, ACCT_PCODE1_EXT, ACCT_PCODE2_EXT, ACCT_PCODE3_EXT, ACCT_PO_BOX, ACCT_PO_BOX_CTY, ACCT_PO_BOX_LOBBY, ACCT_PO_BOX_LOC, ACCT_PO_BOX_NUM, ACCT_PO_BOX_REG, ACCT_POST_CODE2, ACCT_POST_CODE3, ACCT_POSTALAREA, ACCT_POSTCODE_ZIP, ACCT_PREF_CONTACT_METHOD, ACCT_PREF_CONTACT_METHOD_CODE, ACCT_PREF_CONTACT_TIME, ACCT_PREF_LANGUAGE, ACCT_PREF_LANGUAGE_CODE, ACCT_REGION_STATE, ACCT_REGION_STATE_CODE, ACCT_ROOM_NUMBER, ACCT_STREET, ACCT_STREETABBR, ACCT_STREETCODE, ACCT_SUPPLEMENT_1, ACCT_SUPPLEMENT_2, ACCT_SUPPLEMENT_3, ACCT_TITLE, ACCT_TITLE_CODE, ACCT_TOWNSHIP, ACCT_TOWNSHIP_CODE, ACCT_VIP_FLAG, ACCT_WORK_PHONE_EXTENSION, ACCT_WORK_PHONE_PRIMARY, ACTIVITY_ID, CAMPAIGN_CAMPAIGN_CHANNEL, CAMPAIGN_CAMPAIGN_DESC, CAMPAIGN_CAMPAIGN_ID, CAMPAIGN_CATEGORY_1, CAMPAIGN_CATEGORY_2, CAMPAIGN_CATEGORY_3, CAMPAIGN_DEALERFULNAME_DEALER1, CAMPAIGN_DEALERFULNAME_DEALER2, CAMPAIGN_DEALERFULNAME_DEALER3, CAMPAIGN_DEALERFULNAME_DEALER4, CAMPAIGN_DEALERFULNAME_DEALER5, CAMPAIGN_SECDEALERCODE_DEALER1, CAMPAIGN_SECDEALERCODE_DEALER2, CAMPAIGN_SECDEALERCODE_DEALER3, CAMPAIGN_SECDEALERCODE_DEALER4, CAMPAIGN_SECDEALERCODE_DEALER5, CAMPAIGN_TARGET_GROUP_DESC, CAMPAIGN_TARGET_GROUP_ID, CASE_BRAND, CASE_BRAND_CODE, CASE_CASE_CREATION_DATE, CASE_CASE_DESC, CASE_CASE_EMPL_RESPONSIBLE_NAM, CASE_CASE_ID, CASE_CASE_SOLVED_DATE, CASE_EMPL_RESPONSIBLE_ID, CASE_GOODWILL_INDICATOR, CASE_REASON_FOR_STATUS, CASE_SECON_DEALER_CODE_OF_DEAL, CASE_VEH_REG_PLATE, CASE_VEH_VIN_NUMBER, CASE_VEHMODEL_DERIVED_FROM_VIN, CR_OBJECT_ID, CRH_DEALER_ROA_CITY_TOWN, CRH_DEALER_ROA_COUNTRY, CRH_DEALER_ROA_HOUSE_NO, CRH_DEALER_ROA_ID, CRH_DEALER_ROA_NAME_1, CRH_DEALER_ROA_NAME_2, CRH_DEALER_ROA_PO_BOX, CRH_DEALER_ROA_POSTCODE_ZIP, CRH_DEALER_ROA_PREFIX_1, CRH_DEALER_ROA_PREFIX_2, CRH_DEALER_ROA_REGION_STATE, CRH_DEALER_ROA_STREET, CRH_DEALER_ROA_SUPPLEMENT_1, CRH_DEALER_ROA_SUPPLEMENT_2, CRH_DEALER_ROA_SUPPLEMENT_3, CRH_END_DATE, CRH_START_DATE, DMS_ACTIVITY_DESC, DMS_DAYS_OPEN, DMS_EVENT_TYPE, DMS_LICENSE_PLATE_REGISTRATION, DMS_POTENTIAL_CHANGE_OF_OWNERS, DMS_REPAIR_ORDER_CLOSED_DATE, DMS_REPAIR_ORDER_NUMBER, DMS_REPAIR_ORDER_OPEN_DATE, DMS_SECON_DEALER_CODE, DMS_SERVICE_ADVISOR, DMS_SERVICE_ADVISOR_ID, DMS_TECHNICIAN_ID, DMS_TECHNICIAN, DMS_TOTAL_CUSTOMER_PRICE, DMS_USER_STATUS, DMS_USER_STATUS_CODE, DMS_VIN, LEAD_BRAND_CODE, LEAD_EMP_RESPONSIBLE_DEAL_NAME, LEAD_ENQUIRY_TYPE_CODE, LEAD_FUEL_TYPE_CODE, LEAD_IN_MARKET_DATE, LEAD_LEAD_CATEGORY_CODE, LEAD_LEAD_STATUS_CODE, LEAD_LEAD_STATUS_REASON_CODE, LEAD_MODEL_OF_INTEREST_CODE, LEAD_MODEL_YEAR, LEAD_NEW_USED_INDICATOR, LEAD_ORIGIN_CODE, LEAD_PRE_LAUNCH_MODEL, LEAD_PREF_CONTACT_METHOD, LEAD_SECON_DEALER_CODE, LEAD_VEH_SALE_TYPE_CODE, OBJECT_ID, ROADSIDE_ACTIVE_STATUS_CODE, ROADSIDE_ACTIVITY_DESC, ROADSIDE_COUNTRY_ISO_CODE, ROADSIDE_CUSTOMER_SUMMARY_INC, ROADSIDE_DATA_SOURCE, ROADSIDE_DATE_CALL_ANSWERED, ROADSIDE_DATE_CALL_RECEIVED, ROADSIDE_DATE_JOB_COMPLETED, ROADSIDE_DATE_RESOURCE_ALL, ROADSIDE_DATE_RESOURCE_ARRIVED, ROADSIDE_DATE_SECON_RES_ALL, ROADSIDE_DATE_SECON_RES_ARR, ROADSIDE_DRIVER_EMAIL, ROADSIDE_DRIVER_FIRST_NAME, ROADSIDE_DRIVER_LAST_NAME, ROADSIDE_DRIVER_MOBILE, ROADSIDE_DRIVER_TITLE, ROADSIDE_INCIDENT_CATEGORY, ROADSIDE_INCIDENT_COUNTRY, ROADSIDE_INCIDENT_DATE, ROADSIDE_INCIDENT_ID, ROADSIDE_INCIDENT_SUMMARY, ROADSIDE_INCIDENT_TIME, ROADSIDE_LICENSE_PLATE_REG_NO, ROADSIDE_PROVIDER, ROADSIDE_REPAIRING_SEC_DEAL_CD, ROADSIDE_RESOLUTION_TIME, ROADSIDE_TIME_CALL_ANSWERED, ROADSIDE_TIME_CALL_RECEIVED, ROADSIDE_TIME_JOB_COMPLETED, ROADSIDE_TIME_RESOURCE_ALL, ROADSIDE_TIME_RESOURCE_ARRIVED, ROADSIDE_TIME_SECON_RES_ALL, ROADSIDE_TIME_SECON_RES_ARR, ROADSIDE_VIN, ROADSIDE_WAIT_TIME, VEH_BRAND, VEH_BUILD_DATE, VEH_CHASSIS_NUMBER, VEH_COMMON_ORDER_NUMBER, VEH_COUNTRY_EQUIPMENT_CODE, VEH_CREATING_DEALER, VEH_CURR_PLANNED_DELIVERY_DATE, VEH_CURRENT_PLANNED_BUILD_DATE, VEH_DEA_NAME_LAST_SELLING_DEAL, VEH_DEALER_NAME_OF_SELLING_DEA, VEH_DELIVERED_DATE, VEH_DERIVATIVE, VEH_DRIVER_FULL_NAME, VEH_ENGINE_SIZE, VEH_EXTERIOR_COLOUR_CODE, VEH_EXTERIOR_COLOUR_DESC, VEH_EXTERIOR_COLOUR_SUPPL_CODE, VEH_EXTERIOR_COLOUR_SUPPL_DESC, VEH_FEATURE_CODE, VEH_FINANCE_PROD, VEH_FIRST_RETAIL_SALE, VEH_FUEL_TYPE_CODE, VEH_MODEL, VEH_MODEL_DESC, VEH_MODEL_YEAR, VEH_NUM_OF_OWNERS_RELATIONSHIP, VEH_ORIGIN, VEH_OWNERSHIP_STATUS, VEH_OWNERSHIP_STATUS_CODE, VEH_PAYMENT_TYPE, VEH_PREDICTED_REPLACEMENT_DATE, VEH_REACQUIRED_INDICATOR, VEH_REGISTRAT_LICENC_PLATE_NUM, VEH_REGISTRATION_DATE, VEH_SALE_TYPE_DESC, VEH_VIN, VEH_VISTA_CONTRACT_NUMBER, VISTACONTRACT_COMM_TY_SALE_DS, VISTACONTRACT_HANDOVER_DATE, VISTACONTRACT_PREV_VEH_BRAND, VISTACONTRACT_PREV_VEH_MODEL, VISTACONTRACT_SALES_MAN_CD_DES, VISTACONTRACT_SALES_MAN_FULNAM, VISTACONTRACT_SALESMAN_CODE, VISTACONTRACT_SECON_DEALER_CD, VISTACONTRACT_TRADE_IN_MANUFAC, VISTACONTRACT_TRADE_IN_MODEL, VISTACONTRACT_ACTIVITY_CATEGRY, VISTACONTRACT_RETAIL_PRICE, VEH_APPR_WARNTY_TYPE, VEH_APPR_WARNTY_TYPE_DESC, VISTACONTRACTNAPPRO_RETAIL_WAR, VISTACONTRACTNAPPRO_RETAIL_DES, VISTACONTRACT_EXT_WARR, VISTACONTRACT_EXT_WARR_DESC, ACCT_CONSENT_JAGUAR_FAX, ACCT_CONSENT_LAND_ROVER_FAX, ACCT_CONSENT_JAGUAR_CHAT, ACCT_CONSENT_LAND_ROVER_CHAT, ACCT_CONSENT_JAGUAR_SMS, ACCT_CONSENT_LAND_ROVER_SMS, ACCT_CONSENT_JAGUAR_SMEDIA, ACCT_CONSENT_LAND_ROVER_SMEDIA, ACCT_CONSENT_OVER_CONT_SUP_JAG, ACCT_CONSENT_OVER_CONT_SUP_LR, ACCT_CONSENT_JAGUAR_PTSMR, ACCT_CONSENT_LAND_ROVER_PTSMR, ACCT_CONSENT_JAGUAR_PTVSM, ACCT_CONSENT_LAND_ROVER_PTVSM, ACCT_CONSENT_JAGUAR_PTAM, ACCT_CONSENT_LAND_ROVER_PTAM, ACCT_CONSENT_JAGUAR_PTNAU, ACCT_CONSENT_LAND_ROVER_PTNAU, ACCT_CONSENT_JAGUAR_PEVENT, ACCT_CONSENT_LAND_ROVER_PEVENT, ACCT_CONSENT_JAGUAR_PND3P, ACCT_CONSENT_LAND_ROVER_PND3P, ACCT_CONSENT_JAGUAR_PTSDWD, ACCT_CONSENT_LAND_ROVER_PTSDWD, ACCT_CONSENT_JAGUAR_PTPA, ACCT_CONSENT_LAND_ROVER_PTPA, RESPONSE_ID, DMS_REPAIR_ORDER_NUMBER_UNIQUE, DMS_OTHER_RELATED_SERVICES, PDI_Flag, VEH_SALE_TYPE_CODE, VISTACONTRACT_COMM_TY_SALE_CD, LEAD_STATUS_REASON_LEV1_DESC, LEAD_STATUS_REASON_LEV1_COD, LEAD_STATUS_REASON_LEV2_DESC, LEAD_STATUS_REASON_LEV2_COD, LEAD_STATUS_REASON_LEV3_DESC, LEAD_STATUS_REASON_LEV3_COD, JAGDIGITALEVENTSEXP, JAGDIGITALINCONTROL, JAGDIGITALOWNERVEHCOMM, JAGDIGITALPARTNERSSPONSORS, JAGDIGITALPRODSERV, JAGDIGITALPROMOTIONSOFFERS, JAGDIGITALSURVEYSRESEARCH, JAGEMAILEVENTSEXP, JAGEMAILINCONTROL, JAGEMAILOWNERVEHCOMM, JAGEMAILPARTNERSSPONSORS, JAGEMAILPRODSERV, JAGEMAILPROMOTIONSOFFERS, JAGEMAILSURVEYSRESEARCH, JAGPHONEEVENTSEXP, JAGPHONEINCONTROL, JAGPHONEOWNERVEHCOMM, JAGPHONEPARTNERSSPONSORS, JAGPHONEPRODSERV, JAGPHONEPROMOTIONSOFFERS, JAGPHONESURVEYSRESEARCH, JAGPOSTEVENTSEXP, JAGPOSTINCONTROL, JAGPOSTOWNERVEHCOMM, JAGPOSTPARTNERSSPONSORS, JAGPOSTPRODSERV, JAGPOSTPROMOTIONSOFFERS, JAGPOSTSURVEYSRESEARCH, JAGSMSEVENTSEXP, JAGSMSINCONTROL, JAGSMSOWNERVEHCOMM, JAGSMSPARTNERSSPONSORS, JAGSMSPRODSERV, JAGSMSPROMOTIONSOFFERS, JAGSMSSURVEYSRESEARCH, LRDIGITALEVENTSEXP, LRDIGITALINCONTROL, LRDIGITALOWNERVEHCOMM, LRDIGITALPARTNERSSPONSORS, LRDIGITALPRODSERV, LRDIGITALPROMOTIONSOFFERS, LRDIGITALSURVEYSRESEARCH, LREMAILEVENTSEXP, LREMAILINCONTROL, LREMAILOWNERVEHCOMM, LREMAILPARTNERSSPONSORS, LREMAILPRODSERV, LREMAILPROMOTIONSOFFERS, LREMAILSURVEYSRESEARCH, LRPHONEEVENTSEXP, LRPHONEINCONTROL, LRPHONEOWNERVEHCOMM, LRPHONEPARTNERSSPONSORS, LRPHONEPRODSERV, LRPHONEPROMOTIONSOFFERS, LRPHONESURVEYSRESEARCH, LRPOSTEVENTSEXP, LRPOSTINCONTROL, LRPOSTOWNERVEHCOMM, LRPOSTPARTNERSSPONSORS, LRPOSTPRODSERV, LRPOSTPROMOTIONSOFFERS, LRPOSTSURVEYSRESEARCH, LRSMSEVENTSEXP, LRSMSINCONTROL, LRSMSOWNERVEHCOMM, LRSMSPARTNERSSPONSORS, LRSMSPRODSERV, LRSMSPROMOTIONSOFFERS, LRSMSSURVEYSRESEARCH, ACCT_NAME_PREFIX_CODE, ACCT_NAME_PREFIX, VISTACONTRACT_COMMON_ORDER_NUM, VEH_FUEL_TYPE, CNT_ABTNR, CNT_ADDRESS, CNT_DPRTMNT, CNT_FIRST_NAME, CNT_FNCTN, CNT_LAST_NAME, CNT_PAFKT, CNT_RELTYP, CNT_TEL_NUMBER, CONTACT_PER_ID, ACCT_NAME_CREATING_DEA, CNT_MOBILE_PHONE, CNT_ACADEMIC_TITLE, CNT_ACADEMIC_TITLE_CODE, CNT_NAME_PREFIX_CODE, CNT_NAME_PREFIX, CNT_JAGDIGITALEVENTSEXP, CNT_JAGDIGITALINCONTROL, CNT_JAGDIGITALOWNERVEHCOMM, CNT_JAGDIGITALPARTNERSSPONSORS, CNT_JAGDIGITALPRODSERV, CNT_JAGDIGITALPROMOTIONSOFFERS, CNT_JAGDIGITALSURVEYSRESEARCH, CNT_JAGEMAILEVENTSEXP, CNT_JAGEMAILINCONTROL, CNT_JAGEMAILOWNERVEHCOMM, CNT_JAGEMAILPARTNERSSPONSORS, CNT_JAGEMAILPRODSERV, CNT_JAGEMAILPROMOTIONSOFFERS, CNT_JAGEMAILSURVEYSRESEARCH, CNT_JAGPHONEEVENTSEXP, CNT_JAGPHONEINCONTROL, CNT_JAGPHONEOWNERVEHCOMM, CNT_JAGPHONEPARTNERSSPONSORS, CNT_JAGPHONEPRODSERV, CNT_JAGPHONEPROMOTIONSOFFERS, CNT_JAGPHONESURVEYSRESEARCH, CNT_JAGPOSTEVENTSEXP, CNT_JAGPOSTINCONTROL, CNT_JAGPOSTOWNERVEHCOMM, CNT_JAGPOSTPARTNERSSPONSORS, CNT_JAGPOSTPRODSERV, CNT_JAGPOSTPROMOTIONSOFFERS, CNT_JAGPOSTSURVEYSRESEARCH, CNT_JAGSMSEVENTSEXP, CNT_JAGSMSINCONTROL, CNT_JAGSMSOWNERVEHCOMM, CNT_JAGSMSPARTNERSSPONSORS, CNT_JAGSMSPRODSERV, CNT_JAGSMSPROMOTIONSOFFERS, CNT_JAGSMSSURVEYSRESEARCH, CNT_LRDIGITALEVENTSEXP, CNT_LRDIGITALINCONTROL, CNT_LRDIGITALOWNERVEHCOMM, CNT_LRDIGITALPARTNERSSPONSORS, CNT_LRDIGITALPRODSERV, CNT_LRDIGITALPROMOTIONSOFFERS, CNT_LRDIGITALSURVEYSRESEARCH, CNT_LREMAILEVENTSEXP, CNT_LREMAILINCONTROL, CNT_LREMAILOWNERVEHCOMM, CNT_LREMAILPARTNERSSPONSORS, CNT_LREMAILPRODSERV, CNT_LREMAILPROMOTIONSOFFERS, CNT_LREMAILSURVEYSRESEARCH, CNT_LRPHONEEVENTSEXP, CNT_LRPHONEINCONTROL, CNT_LRPHONEOWNERVEHCOMM, CNT_LRPHONEPARTNERSSPONSORS, CNT_LRPHONEPRODSERV, CNT_LRPHONEPROMOTIONSOFFERS, CNT_LRPHONESURVEYSRESEARCH, CNT_LRPOSTEVENTSEXP, CNT_LRPOSTINCONTROL, CNT_LRPOSTOWNERVEHCOMM, CNT_LRPOSTPARTNERSSPONSORS, CNT_LRPOSTPRODSERV, CNT_LRPOSTPROMOTIONSOFFERS, CNT_LRPOSTSURVEYSRESEARCH, CNT_LRSMSEVENTSEXP, CNT_LRSMSINCONTROL, CNT_LRSMSOWNERVEHCOMM, CNT_LRSMSPARTNERSSPONSORS, CNT_LRSMSPRODSERV, CNT_LRSMSPROMOTIONSOFFERS, CNT_LRSMSSURVEYSRESEARCH, CNT_TITLE, CNT_TITLE_CODE, CNT_PREF_LANGUAGE, CNT_PREF_LANGUAGE_CODE		-- v1.3
	FROM CRM.DMS_Repair_Service crm 
	WHERE crm.AuditID = @AuditID


	-- Delete the records from the CRM holding table
	DELETE
	FROM CRM.DMS_Repair_Service
	WHERE AuditID = @AuditID


	-----------------------------------------------------------------------------------------------------------------------------
	-- CRM.PreOwned
	-----------------------------------------------------------------------------------------------------------------------------
	

	-- Save records prior to removing them
	INSERT INTO [$(AuditDB)].RollbackSample.CRM_PreOwned (ID, AuditID, VWTID, AuditItemID, PhysicalRowID, Converted_ACCT_DATE_OF_BIRTH, Converted_ACCT_DATE_ADVISED_OF_DEATH, Converted_VEH_REGISTRATION_DATE, Converted_VEH_BUILD_DATE, Converted_DMS_REPAIR_ORDER_CLOSED_DATE, Converted_ROADSIDE_DATE_JOB_COMPLETED, Converted_CASE_CASE_SOLVED_DATE, Converted_VISTACONTRACT_HANDOVER_DATE, DateTransferredToVWT, SampleTriggeredSelectionReqID, AFRLCode, ACCT_ACADEMIC_TITLE, ACCT_ACADEMIC_TITLE_CODE, ACCT_ACCT_ID, ACCT_ACCT_TYPE, ACCT_ACCT_TYPE_CODE, ACCT_ADDITIONAL_LAST_NAME, ACCT_BP_ROLE, ACCT_BUILDING, ACCT_CITY_CODE, ACCT_CITY_CODE2, ACCT_CITY_TOWN, ACCT_CITYH_CODE, ACCT_CONSENT_JAGUAR_EMAIL, ACCT_CONSENT_JAGUAR_PHONE, ACCT_CONSENT_JAGUAR_POST, ACCT_CONSENT_LAND_ROVER_EMAIL, ACCT_CONSENT_LAND_ROVER_POST, ACCT_CONSENT_LR_PHONE, ACCT_CORRESPONDENCE_LANG_CODE, ACCT_CORRESPONDENCE_LANGUAGE, ACCT_COUNTRY, ACCT_COUNTRY_CODE, ACCT_COUNTY, ACCT_COUNTY_CODE, ACCT_DATE_ADVISED_OF_DEATH, ACCT_DATE_DECL_TO_GIVE_EMAIL, ACCT_DATE_OF_BIRTH, ACCT_DEAL_FULNAME_OF_CREAT_DEA, ACCT_DISTRICT, ACCT_EMAIL_VALIDATION_STATUS, ACCT_EMPLOYER_NAME, ACCT_EXTERN_FINANC_COMP_ACCTID, ACCT_FIRST_NAME, ACCT_FLOOR, ACCT_FULL_NAME, ACCT_GENDER_FEMALE, ACCT_GENDER_MALE, ACCT_GENDER_UNKNOWN, ACCT_GENERATION, ACCT_HOME_CITY, ACCT_HOME_EMAIL_ADDR_PRIMARY, ACCT_HOME_PHONE_NUMBER, ACCT_HOUSE_NO, ACCT_HOUSE_NUM2, ACCT_HOUSE_NUM3, ACCT_INDUSTRY_SECTOR, ACCT_INDUSTRY_SECTOR_CODE, ACCT_INITIALS, ACCT_JAGUAR_IN_MARKET_DATE, ACCT_JAGUAR_LOYALTY_STATUS, ACCT_KNOWN_AS, ACCT_LAND_ROVER_LOYALTY_STATUS, ACCT_LAND_ROVER_MARKET_DATE, ACCT_LAST_NAME, ACCT_LOCATION, ACCT_MIDDLE_NAME, ACCT_MOBILE_NUMBER, ACCT_NAME_1, ACCT_NAME_2, ACCT_NAME_3, ACCT_NAME_4, ACCT_NAME_CO, ACCT_NON_ACADEMIC_TITLE, ACCT_NON_ACADEMIC_TITLE_CODE, ACCT_ORG_TYPE, ACCT_ORG_TYPE_CODE, ACCT_PCODE1_EXT, ACCT_PCODE2_EXT, ACCT_PCODE3_EXT, ACCT_PO_BOX, ACCT_PO_BOX_CTY, ACCT_PO_BOX_LOBBY, ACCT_PO_BOX_LOC, ACCT_PO_BOX_NUM, ACCT_PO_BOX_REG, ACCT_POST_CODE2, ACCT_POST_CODE3, ACCT_POSTALAREA, ACCT_POSTCODE_ZIP, ACCT_PREF_CONTACT_METHOD, ACCT_PREF_CONTACT_METHOD_CODE, ACCT_PREF_CONTACT_TIME, ACCT_PREF_LANGUAGE, ACCT_PREF_LANGUAGE_CODE, ACCT_REGION_STATE, ACCT_REGION_STATE_CODE, ACCT_ROOM_NUMBER, ACCT_STREET, ACCT_STREETABBR, ACCT_STREETCODE, ACCT_SUPPLEMENT_1, ACCT_SUPPLEMENT_2, ACCT_SUPPLEMENT_3, ACCT_TITLE, ACCT_TITLE_CODE, ACCT_TOWNSHIP, ACCT_TOWNSHIP_CODE, ACCT_VIP_FLAG, ACCT_WORK_PHONE_EXTENSION, ACCT_WORK_PHONE_PRIMARY, ACTIVITY_ID, CAMPAIGN_CAMPAIGN_CHANNEL, CAMPAIGN_CAMPAIGN_DESC, CAMPAIGN_CAMPAIGN_ID, CAMPAIGN_CATEGORY_1, CAMPAIGN_CATEGORY_2, CAMPAIGN_CATEGORY_3, CAMPAIGN_DEALERFULNAME_DEALER1, CAMPAIGN_DEALERFULNAME_DEALER2, CAMPAIGN_DEALERFULNAME_DEALER3, CAMPAIGN_DEALERFULNAME_DEALER4, CAMPAIGN_DEALERFULNAME_DEALER5, CAMPAIGN_SECDEALERCODE_DEALER1, CAMPAIGN_SECDEALERCODE_DEALER2, CAMPAIGN_SECDEALERCODE_DEALER3, CAMPAIGN_SECDEALERCODE_DEALER4, CAMPAIGN_SECDEALERCODE_DEALER5, CAMPAIGN_TARGET_GROUP_DESC, CAMPAIGN_TARGET_GROUP_ID, CASE_BRAND, CASE_BRAND_CODE, CASE_CASE_CREATION_DATE, CASE_CASE_DESC, CASE_CASE_EMPL_RESPONSIBLE_NAM, CASE_CASE_ID, CASE_CASE_SOLVED_DATE, CASE_EMPL_RESPONSIBLE_ID, CASE_GOODWILL_INDICATOR, CASE_REASON_FOR_STATUS, CASE_SECON_DEALER_CODE_OF_DEAL, CASE_VEH_REG_PLATE, CASE_VEH_VIN_NUMBER, CASE_VEHMODEL_DERIVED_FROM_VIN, CR_OBJECT_ID, CRH_DEALER_ROA_CITY_TOWN, CRH_DEALER_ROA_COUNTRY, CRH_DEALER_ROA_HOUSE_NO, CRH_DEALER_ROA_ID, CRH_DEALER_ROA_NAME_1, CRH_DEALER_ROA_NAME_2, CRH_DEALER_ROA_PO_BOX, CRH_DEALER_ROA_POSTCODE_ZIP, CRH_DEALER_ROA_PREFIX_1, CRH_DEALER_ROA_PREFIX_2, CRH_DEALER_ROA_REGION_STATE, CRH_DEALER_ROA_STREET, CRH_DEALER_ROA_SUPPLEMENT_1, CRH_DEALER_ROA_SUPPLEMENT_2, CRH_DEALER_ROA_SUPPLEMENT_3, CRH_END_DATE, CRH_START_DATE, DMS_ACTIVITY_DESC, DMS_DAYS_OPEN, DMS_EVENT_TYPE, DMS_LICENSE_PLATE_REGISTRATION, DMS_POTENTIAL_CHANGE_OF_OWNERS, DMS_REPAIR_ORDER_CLOSED_DATE, DMS_REPAIR_ORDER_NUMBER, DMS_REPAIR_ORDER_OPEN_DATE, DMS_SECON_DEALER_CODE, DMS_SERVICE_ADVISOR, DMS_SERVICE_ADVISOR_ID, DMS_TECHNICIAN_ID, DMS_TECHNICIAN, DMS_TOTAL_CUSTOMER_PRICE, DMS_USER_STATUS, DMS_USER_STATUS_CODE, DMS_VIN, LEAD_BRAND_CODE, LEAD_EMP_RESPONSIBLE_DEAL_NAME, LEAD_ENQUIRY_TYPE_CODE, LEAD_FUEL_TYPE_CODE, LEAD_IN_MARKET_DATE, LEAD_LEAD_CATEGORY_CODE, LEAD_LEAD_STATUS_CODE, LEAD_LEAD_STATUS_REASON_CODE, LEAD_MODEL_OF_INTEREST_CODE, LEAD_MODEL_YEAR, LEAD_NEW_USED_INDICATOR, LEAD_ORIGIN_CODE, LEAD_PRE_LAUNCH_MODEL, LEAD_PREF_CONTACT_METHOD, LEAD_SECON_DEALER_CODE, LEAD_VEH_SALE_TYPE_CODE, OBJECT_ID, ROADSIDE_ACTIVE_STATUS_CODE, ROADSIDE_ACTIVITY_DESC, ROADSIDE_COUNTRY_ISO_CODE, ROADSIDE_CUSTOMER_SUMMARY_INC, ROADSIDE_DATA_SOURCE, ROADSIDE_DATE_CALL_ANSWERED, ROADSIDE_DATE_CALL_RECEIVED, ROADSIDE_DATE_JOB_COMPLETED, ROADSIDE_DATE_RESOURCE_ALL, ROADSIDE_DATE_RESOURCE_ARRIVED, ROADSIDE_DATE_SECON_RES_ALL, ROADSIDE_DATE_SECON_RES_ARR, ROADSIDE_DRIVER_EMAIL, ROADSIDE_DRIVER_FIRST_NAME, ROADSIDE_DRIVER_LAST_NAME, ROADSIDE_DRIVER_MOBILE, ROADSIDE_DRIVER_TITLE, ROADSIDE_INCIDENT_CATEGORY, ROADSIDE_INCIDENT_COUNTRY, ROADSIDE_INCIDENT_DATE, ROADSIDE_INCIDENT_ID, ROADSIDE_INCIDENT_SUMMARY, ROADSIDE_INCIDENT_TIME, ROADSIDE_LICENSE_PLATE_REG_NO, ROADSIDE_PROVIDER, ROADSIDE_REPAIRING_SEC_DEAL_CD, ROADSIDE_RESOLUTION_TIME, ROADSIDE_TIME_CALL_ANSWERED, ROADSIDE_TIME_CALL_RECEIVED, ROADSIDE_TIME_JOB_COMPLETED, ROADSIDE_TIME_RESOURCE_ALL, ROADSIDE_TIME_RESOURCE_ARRIVED, ROADSIDE_TIME_SECON_RES_ALL, ROADSIDE_TIME_SECON_RES_ARR, ROADSIDE_VIN, ROADSIDE_WAIT_TIME, VEH_BRAND, VEH_BUILD_DATE, VEH_CHASSIS_NUMBER, VEH_COMMON_ORDER_NUMBER, VEH_COUNTRY_EQUIPMENT_CODE, VEH_CREATING_DEALER, VEH_CURR_PLANNED_DELIVERY_DATE, VEH_CURRENT_PLANNED_BUILD_DATE, VEH_DEA_NAME_LAST_SELLING_DEAL, VEH_DEALER_NAME_OF_SELLING_DEA, VEH_DELIVERED_DATE, VEH_DERIVATIVE, VEH_DRIVER_FULL_NAME, VEH_ENGINE_SIZE, VEH_EXTERIOR_COLOUR_CODE, VEH_EXTERIOR_COLOUR_DESC, VEH_EXTERIOR_COLOUR_SUPPL_CODE, VEH_EXTERIOR_COLOUR_SUPPL_DESC, VEH_FEATURE_CODE, VEH_FINANCE_PROD, VEH_FIRST_RETAIL_SALE, VEH_FUEL_TYPE_CODE, VEH_MODEL, VEH_MODEL_DESC, VEH_MODEL_YEAR, VEH_NUM_OF_OWNERS_RELATIONSHIP, VEH_ORIGIN, VEH_OWNERSHIP_STATUS, VEH_OWNERSHIP_STATUS_CODE, VEH_PAYMENT_TYPE, VEH_PREDICTED_REPLACEMENT_DATE, VEH_REACQUIRED_INDICATOR, VEH_REGISTRAT_LICENC_PLATE_NUM, VEH_REGISTRATION_DATE, VEH_SALE_TYPE_DESC, VEH_VIN, VEH_VISTA_CONTRACT_NUMBER, VISTACONTRACT_COMM_TY_SALE_DS, VISTACONTRACT_HANDOVER_DATE, VISTACONTRACT_PREV_VEH_BRAND, VISTACONTRACT_PREV_VEH_MODEL, VISTACONTRACT_SALES_MAN_CD_DES, VISTACONTRACT_SALES_MAN_FULNAM, VISTACONTRACT_SALESMAN_CODE, VISTACONTRACT_SECON_DEALER_CD, VISTACONTRACT_TRADE_IN_MANUFAC, VISTACONTRACT_TRADE_IN_MODEL, VISTACONTRACT_ACTIVITY_CATEGRY, VISTACONTRACT_RETAIL_PRICE, VEH_APPR_WARNTY_TYPE, VEH_APPR_WARNTY_TYPE_DESC, VISTACONTRACTNAPPRO_RETAIL_WAR, VISTACONTRACTNAPPRO_RETAIL_DES, VISTACONTRACT_EXT_WARR, VISTACONTRACT_EXT_WARR_DESC, ACCT_CONSENT_JAGUAR_FAX, ACCT_CONSENT_LAND_ROVER_FAX, ACCT_CONSENT_JAGUAR_CHAT, ACCT_CONSENT_LAND_ROVER_CHAT, ACCT_CONSENT_JAGUAR_SMS, ACCT_CONSENT_LAND_ROVER_SMS, ACCT_CONSENT_JAGUAR_SMEDIA, ACCT_CONSENT_LAND_ROVER_SMEDIA, ACCT_CONSENT_OVER_CONT_SUP_JAG, ACCT_CONSENT_OVER_CONT_SUP_LR, ACCT_CONSENT_JAGUAR_PTSMR, ACCT_CONSENT_LAND_ROVER_PTSMR, ACCT_CONSENT_JAGUAR_PTVSM, ACCT_CONSENT_LAND_ROVER_PTVSM, ACCT_CONSENT_JAGUAR_PTAM, ACCT_CONSENT_LAND_ROVER_PTAM, ACCT_CONSENT_JAGUAR_PTNAU, ACCT_CONSENT_LAND_ROVER_PTNAU, ACCT_CONSENT_JAGUAR_PEVENT, ACCT_CONSENT_LAND_ROVER_PEVENT, ACCT_CONSENT_JAGUAR_PND3P, ACCT_CONSENT_LAND_ROVER_PND3P, ACCT_CONSENT_JAGUAR_PTSDWD, ACCT_CONSENT_LAND_ROVER_PTSDWD, ACCT_CONSENT_JAGUAR_PTPA, ACCT_CONSENT_LAND_ROVER_PTPA, RESPONSE_ID, DMS_OTHER_RELATED_SERVICES, VEH_SALE_TYPE_CODE, VISTACONTRACT_COMM_TY_SALE_CD, LEAD_STATUS_REASON_LEV1_DESC, LEAD_STATUS_REASON_LEV1_COD, LEAD_STATUS_REASON_LEV2_DESC, LEAD_STATUS_REASON_LEV2_COD, LEAD_STATUS_REASON_LEV3_DESC, LEAD_STATUS_REASON_LEV3_COD, JAGDIGITALEVENTSEXP, JAGDIGITALINCONTROL, JAGDIGITALOWNERVEHCOMM, JAGDIGITALPARTNERSSPONSORS, JAGDIGITALPRODSERV, JAGDIGITALPROMOTIONSOFFERS, JAGDIGITALSURVEYSRESEARCH, JAGEMAILEVENTSEXP, JAGEMAILINCONTROL, JAGEMAILOWNERVEHCOMM, JAGEMAILPARTNERSSPONSORS, JAGEMAILPRODSERV, JAGEMAILPROMOTIONSOFFERS, JAGEMAILSURVEYSRESEARCH, JAGPHONEEVENTSEXP, JAGPHONEINCONTROL, JAGPHONEOWNERVEHCOMM, JAGPHONEPARTNERSSPONSORS, JAGPHONEPRODSERV, JAGPHONEPROMOTIONSOFFERS, JAGPHONESURVEYSRESEARCH, JAGPOSTEVENTSEXP, JAGPOSTINCONTROL, JAGPOSTOWNERVEHCOMM, JAGPOSTPARTNERSSPONSORS, JAGPOSTPRODSERV, JAGPOSTPROMOTIONSOFFERS, JAGPOSTSURVEYSRESEARCH, JAGSMSEVENTSEXP, JAGSMSINCONTROL, JAGSMSOWNERVEHCOMM, JAGSMSPARTNERSSPONSORS, JAGSMSPRODSERV, JAGSMSPROMOTIONSOFFERS, JAGSMSSURVEYSRESEARCH, LRDIGITALEVENTSEXP, LRDIGITALINCONTROL, LRDIGITALOWNERVEHCOMM, LRDIGITALPARTNERSSPONSORS, LRDIGITALPRODSERV, LRDIGITALPROMOTIONSOFFERS, LRDIGITALSURVEYSRESEARCH, LREMAILEVENTSEXP, LREMAILINCONTROL, LREMAILOWNERVEHCOMM, LREMAILPARTNERSSPONSORS, LREMAILPRODSERV, LREMAILPROMOTIONSOFFERS, LREMAILSURVEYSRESEARCH, LRPHONEEVENTSEXP, LRPHONEINCONTROL, LRPHONEOWNERVEHCOMM, LRPHONEPARTNERSSPONSORS, LRPHONEPRODSERV, LRPHONEPROMOTIONSOFFERS, LRPHONESURVEYSRESEARCH, LRPOSTEVENTSEXP, LRPOSTINCONTROL, LRPOSTOWNERVEHCOMM, LRPOSTPARTNERSSPONSORS, LRPOSTPRODSERV, LRPOSTPROMOTIONSOFFERS, LRPOSTSURVEYSRESEARCH, LRSMSEVENTSEXP, LRSMSINCONTROL, LRSMSOWNERVEHCOMM, LRSMSPARTNERSSPONSORS, LRSMSPRODSERV, LRSMSPROMOTIONSOFFERS, LRSMSSURVEYSRESEARCH, ACCT_NAME_PREFIX_CODE, ACCT_NAME_PREFIX, DMS_REPAIR_ORDER_NUMBER_UNIQUE, VISTACONTRACT_COMMON_ORDER_NUM, VEH_FUEL_TYPE, CNT_ABTNR, CNT_ADDRESS, CNT_DPRTMNT, CNT_FIRST_NAME, CNT_FNCTN, CNT_LAST_NAME, CNT_PAFKT, CNT_RELTYP, CNT_TEL_NUMBER, CONTACT_PER_ID, ACCT_NAME_CREATING_DEA, CNT_MOBILE_PHONE, CNT_ACADEMIC_TITLE, CNT_ACADEMIC_TITLE_CODE, CNT_NAME_PREFIX_CODE, CNT_NAME_PREFIX, CNT_JAGDIGITALEVENTSEXP, CNT_JAGDIGITALINCONTROL, CNT_JAGDIGITALOWNERVEHCOMM, CNT_JAGDIGITALPARTNERSSPONSORS, CNT_JAGDIGITALPRODSERV, CNT_JAGDIGITALPROMOTIONSOFFERS, CNT_JAGDIGITALSURVEYSRESEARCH, CNT_JAGEMAILEVENTSEXP, CNT_JAGEMAILINCONTROL, CNT_JAGEMAILOWNERVEHCOMM, CNT_JAGEMAILPARTNERSSPONSORS, CNT_JAGEMAILPRODSERV, CNT_JAGEMAILPROMOTIONSOFFERS, CNT_JAGEMAILSURVEYSRESEARCH, CNT_JAGPHONEEVENTSEXP, CNT_JAGPHONEINCONTROL, CNT_JAGPHONEOWNERVEHCOMM, CNT_JAGPHONEPARTNERSSPONSORS, CNT_JAGPHONEPRODSERV, CNT_JAGPHONEPROMOTIONSOFFERS, CNT_JAGPHONESURVEYSRESEARCH, CNT_JAGPOSTEVENTSEXP, CNT_JAGPOSTINCONTROL, CNT_JAGPOSTOWNERVEHCOMM, CNT_JAGPOSTPARTNERSSPONSORS, CNT_JAGPOSTPRODSERV, CNT_JAGPOSTPROMOTIONSOFFERS, CNT_JAGPOSTSURVEYSRESEARCH, CNT_JAGSMSEVENTSEXP, CNT_JAGSMSINCONTROL, CNT_JAGSMSOWNERVEHCOMM, CNT_JAGSMSPARTNERSSPONSORS, CNT_JAGSMSPRODSERV, CNT_JAGSMSPROMOTIONSOFFERS, CNT_JAGSMSSURVEYSRESEARCH, CNT_LRDIGITALEVENTSEXP, CNT_LRDIGITALINCONTROL, CNT_LRDIGITALOWNERVEHCOMM, CNT_LRDIGITALPARTNERSSPONSORS, CNT_LRDIGITALPRODSERV, CNT_LRDIGITALPROMOTIONSOFFERS, CNT_LRDIGITALSURVEYSRESEARCH, CNT_LREMAILEVENTSEXP, CNT_LREMAILINCONTROL, CNT_LREMAILOWNERVEHCOMM, CNT_LREMAILPARTNERSSPONSORS, CNT_LREMAILPRODSERV, CNT_LREMAILPROMOTIONSOFFERS, CNT_LREMAILSURVEYSRESEARCH, CNT_LRPHONEEVENTSEXP, CNT_LRPHONEINCONTROL, CNT_LRPHONEOWNERVEHCOMM, CNT_LRPHONEPARTNERSSPONSORS, CNT_LRPHONEPRODSERV, CNT_LRPHONEPROMOTIONSOFFERS, CNT_LRPHONESURVEYSRESEARCH, CNT_LRPOSTEVENTSEXP, CNT_LRPOSTINCONTROL, CNT_LRPOSTOWNERVEHCOMM, CNT_LRPOSTPARTNERSSPONSORS, CNT_LRPOSTPRODSERV, CNT_LRPOSTPROMOTIONSOFFERS, CNT_LRPOSTSURVEYSRESEARCH, CNT_LRSMSEVENTSEXP, CNT_LRSMSINCONTROL, CNT_LRSMSOWNERVEHCOMM, CNT_LRSMSPARTNERSSPONSORS, CNT_LRSMSPRODSERV, CNT_LRSMSPROMOTIONSOFFERS, CNT_LRSMSSURVEYSRESEARCH, CNT_TITLE, CNT_TITLE_CODE, CNT_PREF_LANGUAGE, CNT_PREF_LANGUAGE_CODE)		-- v1.3
	SELECT ID, AuditID, VWTID, AuditItemID, PhysicalRowID, Converted_ACCT_DATE_OF_BIRTH, Converted_ACCT_DATE_ADVISED_OF_DEATH, Converted_VEH_REGISTRATION_DATE, Converted_VEH_BUILD_DATE, Converted_DMS_REPAIR_ORDER_CLOSED_DATE, Converted_ROADSIDE_DATE_JOB_COMPLETED, Converted_CASE_CASE_SOLVED_DATE, Converted_VISTACONTRACT_HANDOVER_DATE, DateTransferredToVWT, SampleTriggeredSelectionReqID, AFRLCode, ACCT_ACADEMIC_TITLE, ACCT_ACADEMIC_TITLE_CODE, ACCT_ACCT_ID, ACCT_ACCT_TYPE, ACCT_ACCT_TYPE_CODE, ACCT_ADDITIONAL_LAST_NAME, ACCT_BP_ROLE, ACCT_BUILDING, ACCT_CITY_CODE, ACCT_CITY_CODE2, ACCT_CITY_TOWN, ACCT_CITYH_CODE, ACCT_CONSENT_JAGUAR_EMAIL, ACCT_CONSENT_JAGUAR_PHONE, ACCT_CONSENT_JAGUAR_POST, ACCT_CONSENT_LAND_ROVER_EMAIL, ACCT_CONSENT_LAND_ROVER_POST, ACCT_CONSENT_LR_PHONE, ACCT_CORRESPONDENCE_LANG_CODE, ACCT_CORRESPONDENCE_LANGUAGE, ACCT_COUNTRY, ACCT_COUNTRY_CODE, ACCT_COUNTY, ACCT_COUNTY_CODE, ACCT_DATE_ADVISED_OF_DEATH, ACCT_DATE_DECL_TO_GIVE_EMAIL, ACCT_DATE_OF_BIRTH, ACCT_DEAL_FULNAME_OF_CREAT_DEA, ACCT_DISTRICT, ACCT_EMAIL_VALIDATION_STATUS, ACCT_EMPLOYER_NAME, ACCT_EXTERN_FINANC_COMP_ACCTID, ACCT_FIRST_NAME, ACCT_FLOOR, ACCT_FULL_NAME, ACCT_GENDER_FEMALE, ACCT_GENDER_MALE, ACCT_GENDER_UNKNOWN, ACCT_GENERATION, ACCT_HOME_CITY, ACCT_HOME_EMAIL_ADDR_PRIMARY, ACCT_HOME_PHONE_NUMBER, ACCT_HOUSE_NO, ACCT_HOUSE_NUM2, ACCT_HOUSE_NUM3, ACCT_INDUSTRY_SECTOR, ACCT_INDUSTRY_SECTOR_CODE, ACCT_INITIALS, ACCT_JAGUAR_IN_MARKET_DATE, ACCT_JAGUAR_LOYALTY_STATUS, ACCT_KNOWN_AS, ACCT_LAND_ROVER_LOYALTY_STATUS, ACCT_LAND_ROVER_MARKET_DATE, ACCT_LAST_NAME, ACCT_LOCATION, ACCT_MIDDLE_NAME, ACCT_MOBILE_NUMBER, ACCT_NAME_1, ACCT_NAME_2, ACCT_NAME_3, ACCT_NAME_4, ACCT_NAME_CO, ACCT_NON_ACADEMIC_TITLE, ACCT_NON_ACADEMIC_TITLE_CODE, ACCT_ORG_TYPE, ACCT_ORG_TYPE_CODE, ACCT_PCODE1_EXT, ACCT_PCODE2_EXT, ACCT_PCODE3_EXT, ACCT_PO_BOX, ACCT_PO_BOX_CTY, ACCT_PO_BOX_LOBBY, ACCT_PO_BOX_LOC, ACCT_PO_BOX_NUM, ACCT_PO_BOX_REG, ACCT_POST_CODE2, ACCT_POST_CODE3, ACCT_POSTALAREA, ACCT_POSTCODE_ZIP, ACCT_PREF_CONTACT_METHOD, ACCT_PREF_CONTACT_METHOD_CODE, ACCT_PREF_CONTACT_TIME, ACCT_PREF_LANGUAGE, ACCT_PREF_LANGUAGE_CODE, ACCT_REGION_STATE, ACCT_REGION_STATE_CODE, ACCT_ROOM_NUMBER, ACCT_STREET, ACCT_STREETABBR, ACCT_STREETCODE, ACCT_SUPPLEMENT_1, ACCT_SUPPLEMENT_2, ACCT_SUPPLEMENT_3, ACCT_TITLE, ACCT_TITLE_CODE, ACCT_TOWNSHIP, ACCT_TOWNSHIP_CODE, ACCT_VIP_FLAG, ACCT_WORK_PHONE_EXTENSION, ACCT_WORK_PHONE_PRIMARY, ACTIVITY_ID, CAMPAIGN_CAMPAIGN_CHANNEL, CAMPAIGN_CAMPAIGN_DESC, CAMPAIGN_CAMPAIGN_ID, CAMPAIGN_CATEGORY_1, CAMPAIGN_CATEGORY_2, CAMPAIGN_CATEGORY_3, CAMPAIGN_DEALERFULNAME_DEALER1, CAMPAIGN_DEALERFULNAME_DEALER2, CAMPAIGN_DEALERFULNAME_DEALER3, CAMPAIGN_DEALERFULNAME_DEALER4, CAMPAIGN_DEALERFULNAME_DEALER5, CAMPAIGN_SECDEALERCODE_DEALER1, CAMPAIGN_SECDEALERCODE_DEALER2, CAMPAIGN_SECDEALERCODE_DEALER3, CAMPAIGN_SECDEALERCODE_DEALER4, CAMPAIGN_SECDEALERCODE_DEALER5, CAMPAIGN_TARGET_GROUP_DESC, CAMPAIGN_TARGET_GROUP_ID, CASE_BRAND, CASE_BRAND_CODE, CASE_CASE_CREATION_DATE, CASE_CASE_DESC, CASE_CASE_EMPL_RESPONSIBLE_NAM, CASE_CASE_ID, CASE_CASE_SOLVED_DATE, CASE_EMPL_RESPONSIBLE_ID, CASE_GOODWILL_INDICATOR, CASE_REASON_FOR_STATUS, CASE_SECON_DEALER_CODE_OF_DEAL, CASE_VEH_REG_PLATE, CASE_VEH_VIN_NUMBER, CASE_VEHMODEL_DERIVED_FROM_VIN, CR_OBJECT_ID, CRH_DEALER_ROA_CITY_TOWN, CRH_DEALER_ROA_COUNTRY, CRH_DEALER_ROA_HOUSE_NO, CRH_DEALER_ROA_ID, CRH_DEALER_ROA_NAME_1, CRH_DEALER_ROA_NAME_2, CRH_DEALER_ROA_PO_BOX, CRH_DEALER_ROA_POSTCODE_ZIP, CRH_DEALER_ROA_PREFIX_1, CRH_DEALER_ROA_PREFIX_2, CRH_DEALER_ROA_REGION_STATE, CRH_DEALER_ROA_STREET, CRH_DEALER_ROA_SUPPLEMENT_1, CRH_DEALER_ROA_SUPPLEMENT_2, CRH_DEALER_ROA_SUPPLEMENT_3, CRH_END_DATE, CRH_START_DATE, DMS_ACTIVITY_DESC, DMS_DAYS_OPEN, DMS_EVENT_TYPE, DMS_LICENSE_PLATE_REGISTRATION, DMS_POTENTIAL_CHANGE_OF_OWNERS, DMS_REPAIR_ORDER_CLOSED_DATE, DMS_REPAIR_ORDER_NUMBER, DMS_REPAIR_ORDER_OPEN_DATE, DMS_SECON_DEALER_CODE, DMS_SERVICE_ADVISOR, DMS_SERVICE_ADVISOR_ID, DMS_TECHNICIAN_ID, DMS_TECHNICIAN, DMS_TOTAL_CUSTOMER_PRICE, DMS_USER_STATUS, DMS_USER_STATUS_CODE, DMS_VIN, LEAD_BRAND_CODE, LEAD_EMP_RESPONSIBLE_DEAL_NAME, LEAD_ENQUIRY_TYPE_CODE, LEAD_FUEL_TYPE_CODE, LEAD_IN_MARKET_DATE, LEAD_LEAD_CATEGORY_CODE, LEAD_LEAD_STATUS_CODE, LEAD_LEAD_STATUS_REASON_CODE, LEAD_MODEL_OF_INTEREST_CODE, LEAD_MODEL_YEAR, LEAD_NEW_USED_INDICATOR, LEAD_ORIGIN_CODE, LEAD_PRE_LAUNCH_MODEL, LEAD_PREF_CONTACT_METHOD, LEAD_SECON_DEALER_CODE, LEAD_VEH_SALE_TYPE_CODE, OBJECT_ID, ROADSIDE_ACTIVE_STATUS_CODE, ROADSIDE_ACTIVITY_DESC, ROADSIDE_COUNTRY_ISO_CODE, ROADSIDE_CUSTOMER_SUMMARY_INC, ROADSIDE_DATA_SOURCE, ROADSIDE_DATE_CALL_ANSWERED, ROADSIDE_DATE_CALL_RECEIVED, ROADSIDE_DATE_JOB_COMPLETED, ROADSIDE_DATE_RESOURCE_ALL, ROADSIDE_DATE_RESOURCE_ARRIVED, ROADSIDE_DATE_SECON_RES_ALL, ROADSIDE_DATE_SECON_RES_ARR, ROADSIDE_DRIVER_EMAIL, ROADSIDE_DRIVER_FIRST_NAME, ROADSIDE_DRIVER_LAST_NAME, ROADSIDE_DRIVER_MOBILE, ROADSIDE_DRIVER_TITLE, ROADSIDE_INCIDENT_CATEGORY, ROADSIDE_INCIDENT_COUNTRY, ROADSIDE_INCIDENT_DATE, ROADSIDE_INCIDENT_ID, ROADSIDE_INCIDENT_SUMMARY, ROADSIDE_INCIDENT_TIME, ROADSIDE_LICENSE_PLATE_REG_NO, ROADSIDE_PROVIDER, ROADSIDE_REPAIRING_SEC_DEAL_CD, ROADSIDE_RESOLUTION_TIME, ROADSIDE_TIME_CALL_ANSWERED, ROADSIDE_TIME_CALL_RECEIVED, ROADSIDE_TIME_JOB_COMPLETED, ROADSIDE_TIME_RESOURCE_ALL, ROADSIDE_TIME_RESOURCE_ARRIVED, ROADSIDE_TIME_SECON_RES_ALL, ROADSIDE_TIME_SECON_RES_ARR, ROADSIDE_VIN, ROADSIDE_WAIT_TIME, VEH_BRAND, VEH_BUILD_DATE, VEH_CHASSIS_NUMBER, VEH_COMMON_ORDER_NUMBER, VEH_COUNTRY_EQUIPMENT_CODE, VEH_CREATING_DEALER, VEH_CURR_PLANNED_DELIVERY_DATE, VEH_CURRENT_PLANNED_BUILD_DATE, VEH_DEA_NAME_LAST_SELLING_DEAL, VEH_DEALER_NAME_OF_SELLING_DEA, VEH_DELIVERED_DATE, VEH_DERIVATIVE, VEH_DRIVER_FULL_NAME, VEH_ENGINE_SIZE, VEH_EXTERIOR_COLOUR_CODE, VEH_EXTERIOR_COLOUR_DESC, VEH_EXTERIOR_COLOUR_SUPPL_CODE, VEH_EXTERIOR_COLOUR_SUPPL_DESC, VEH_FEATURE_CODE, VEH_FINANCE_PROD, VEH_FIRST_RETAIL_SALE, VEH_FUEL_TYPE_CODE, VEH_MODEL, VEH_MODEL_DESC, VEH_MODEL_YEAR, VEH_NUM_OF_OWNERS_RELATIONSHIP, VEH_ORIGIN, VEH_OWNERSHIP_STATUS, VEH_OWNERSHIP_STATUS_CODE, VEH_PAYMENT_TYPE, VEH_PREDICTED_REPLACEMENT_DATE, VEH_REACQUIRED_INDICATOR, VEH_REGISTRAT_LICENC_PLATE_NUM, VEH_REGISTRATION_DATE, VEH_SALE_TYPE_DESC, VEH_VIN, VEH_VISTA_CONTRACT_NUMBER, VISTACONTRACT_COMM_TY_SALE_DS, VISTACONTRACT_HANDOVER_DATE, VISTACONTRACT_PREV_VEH_BRAND, VISTACONTRACT_PREV_VEH_MODEL, VISTACONTRACT_SALES_MAN_CD_DES, VISTACONTRACT_SALES_MAN_FULNAM, VISTACONTRACT_SALESMAN_CODE, VISTACONTRACT_SECON_DEALER_CD, VISTACONTRACT_TRADE_IN_MANUFAC, VISTACONTRACT_TRADE_IN_MODEL, VISTACONTRACT_ACTIVITY_CATEGRY, VISTACONTRACT_RETAIL_PRICE, VEH_APPR_WARNTY_TYPE, VEH_APPR_WARNTY_TYPE_DESC, VISTACONTRACTNAPPRO_RETAIL_WAR, VISTACONTRACTNAPPRO_RETAIL_DES, VISTACONTRACT_EXT_WARR, VISTACONTRACT_EXT_WARR_DESC, ACCT_CONSENT_JAGUAR_FAX, ACCT_CONSENT_LAND_ROVER_FAX, ACCT_CONSENT_JAGUAR_CHAT, ACCT_CONSENT_LAND_ROVER_CHAT, ACCT_CONSENT_JAGUAR_SMS, ACCT_CONSENT_LAND_ROVER_SMS, ACCT_CONSENT_JAGUAR_SMEDIA, ACCT_CONSENT_LAND_ROVER_SMEDIA, ACCT_CONSENT_OVER_CONT_SUP_JAG, ACCT_CONSENT_OVER_CONT_SUP_LR, ACCT_CONSENT_JAGUAR_PTSMR, ACCT_CONSENT_LAND_ROVER_PTSMR, ACCT_CONSENT_JAGUAR_PTVSM, ACCT_CONSENT_LAND_ROVER_PTVSM, ACCT_CONSENT_JAGUAR_PTAM, ACCT_CONSENT_LAND_ROVER_PTAM, ACCT_CONSENT_JAGUAR_PTNAU, ACCT_CONSENT_LAND_ROVER_PTNAU, ACCT_CONSENT_JAGUAR_PEVENT, ACCT_CONSENT_LAND_ROVER_PEVENT, ACCT_CONSENT_JAGUAR_PND3P, ACCT_CONSENT_LAND_ROVER_PND3P, ACCT_CONSENT_JAGUAR_PTSDWD, ACCT_CONSENT_LAND_ROVER_PTSDWD, ACCT_CONSENT_JAGUAR_PTPA, ACCT_CONSENT_LAND_ROVER_PTPA, RESPONSE_ID, DMS_OTHER_RELATED_SERVICES, VEH_SALE_TYPE_CODE, VISTACONTRACT_COMM_TY_SALE_CD, LEAD_STATUS_REASON_LEV1_DESC, LEAD_STATUS_REASON_LEV1_COD, LEAD_STATUS_REASON_LEV2_DESC, LEAD_STATUS_REASON_LEV2_COD, LEAD_STATUS_REASON_LEV3_DESC, LEAD_STATUS_REASON_LEV3_COD, JAGDIGITALEVENTSEXP, JAGDIGITALINCONTROL, JAGDIGITALOWNERVEHCOMM, JAGDIGITALPARTNERSSPONSORS, JAGDIGITALPRODSERV, JAGDIGITALPROMOTIONSOFFERS, JAGDIGITALSURVEYSRESEARCH, JAGEMAILEVENTSEXP, JAGEMAILINCONTROL, JAGEMAILOWNERVEHCOMM, JAGEMAILPARTNERSSPONSORS, JAGEMAILPRODSERV, JAGEMAILPROMOTIONSOFFERS, JAGEMAILSURVEYSRESEARCH, JAGPHONEEVENTSEXP, JAGPHONEINCONTROL, JAGPHONEOWNERVEHCOMM, JAGPHONEPARTNERSSPONSORS, JAGPHONEPRODSERV, JAGPHONEPROMOTIONSOFFERS, JAGPHONESURVEYSRESEARCH, JAGPOSTEVENTSEXP, JAGPOSTINCONTROL, JAGPOSTOWNERVEHCOMM, JAGPOSTPARTNERSSPONSORS, JAGPOSTPRODSERV, JAGPOSTPROMOTIONSOFFERS, JAGPOSTSURVEYSRESEARCH, JAGSMSEVENTSEXP, JAGSMSINCONTROL, JAGSMSOWNERVEHCOMM, JAGSMSPARTNERSSPONSORS, JAGSMSPRODSERV, JAGSMSPROMOTIONSOFFERS, JAGSMSSURVEYSRESEARCH, LRDIGITALEVENTSEXP, LRDIGITALINCONTROL, LRDIGITALOWNERVEHCOMM, LRDIGITALPARTNERSSPONSORS, LRDIGITALPRODSERV, LRDIGITALPROMOTIONSOFFERS, LRDIGITALSURVEYSRESEARCH, LREMAILEVENTSEXP, LREMAILINCONTROL, LREMAILOWNERVEHCOMM, LREMAILPARTNERSSPONSORS, LREMAILPRODSERV, LREMAILPROMOTIONSOFFERS, LREMAILSURVEYSRESEARCH, LRPHONEEVENTSEXP, LRPHONEINCONTROL, LRPHONEOWNERVEHCOMM, LRPHONEPARTNERSSPONSORS, LRPHONEPRODSERV, LRPHONEPROMOTIONSOFFERS, LRPHONESURVEYSRESEARCH, LRPOSTEVENTSEXP, LRPOSTINCONTROL, LRPOSTOWNERVEHCOMM, LRPOSTPARTNERSSPONSORS, LRPOSTPRODSERV, LRPOSTPROMOTIONSOFFERS, LRPOSTSURVEYSRESEARCH, LRSMSEVENTSEXP, LRSMSINCONTROL, LRSMSOWNERVEHCOMM, LRSMSPARTNERSSPONSORS, LRSMSPRODSERV, LRSMSPROMOTIONSOFFERS, LRSMSSURVEYSRESEARCH, ACCT_NAME_PREFIX_CODE, ACCT_NAME_PREFIX, DMS_REPAIR_ORDER_NUMBER_UNIQUE, VISTACONTRACT_COMMON_ORDER_NUM, VEH_FUEL_TYPE, CNT_ABTNR, CNT_ADDRESS, CNT_DPRTMNT, CNT_FIRST_NAME, CNT_FNCTN, CNT_LAST_NAME, CNT_PAFKT, CNT_RELTYP, CNT_TEL_NUMBER, CONTACT_PER_ID, ACCT_NAME_CREATING_DEA, CNT_MOBILE_PHONE, CNT_ACADEMIC_TITLE, CNT_ACADEMIC_TITLE_CODE, CNT_NAME_PREFIX_CODE, CNT_NAME_PREFIX, CNT_JAGDIGITALEVENTSEXP, CNT_JAGDIGITALINCONTROL, CNT_JAGDIGITALOWNERVEHCOMM, CNT_JAGDIGITALPARTNERSSPONSORS, CNT_JAGDIGITALPRODSERV, CNT_JAGDIGITALPROMOTIONSOFFERS, CNT_JAGDIGITALSURVEYSRESEARCH, CNT_JAGEMAILEVENTSEXP, CNT_JAGEMAILINCONTROL, CNT_JAGEMAILOWNERVEHCOMM, CNT_JAGEMAILPARTNERSSPONSORS, CNT_JAGEMAILPRODSERV, CNT_JAGEMAILPROMOTIONSOFFERS, CNT_JAGEMAILSURVEYSRESEARCH, CNT_JAGPHONEEVENTSEXP, CNT_JAGPHONEINCONTROL, CNT_JAGPHONEOWNERVEHCOMM, CNT_JAGPHONEPARTNERSSPONSORS, CNT_JAGPHONEPRODSERV, CNT_JAGPHONEPROMOTIONSOFFERS, CNT_JAGPHONESURVEYSRESEARCH, CNT_JAGPOSTEVENTSEXP, CNT_JAGPOSTINCONTROL, CNT_JAGPOSTOWNERVEHCOMM, CNT_JAGPOSTPARTNERSSPONSORS, CNT_JAGPOSTPRODSERV, CNT_JAGPOSTPROMOTIONSOFFERS, CNT_JAGPOSTSURVEYSRESEARCH, CNT_JAGSMSEVENTSEXP, CNT_JAGSMSINCONTROL, CNT_JAGSMSOWNERVEHCOMM, CNT_JAGSMSPARTNERSSPONSORS, CNT_JAGSMSPRODSERV, CNT_JAGSMSPROMOTIONSOFFERS, CNT_JAGSMSSURVEYSRESEARCH, CNT_LRDIGITALEVENTSEXP, CNT_LRDIGITALINCONTROL, CNT_LRDIGITALOWNERVEHCOMM, CNT_LRDIGITALPARTNERSSPONSORS, CNT_LRDIGITALPRODSERV, CNT_LRDIGITALPROMOTIONSOFFERS, CNT_LRDIGITALSURVEYSRESEARCH, CNT_LREMAILEVENTSEXP, CNT_LREMAILINCONTROL, CNT_LREMAILOWNERVEHCOMM, CNT_LREMAILPARTNERSSPONSORS, CNT_LREMAILPRODSERV, CNT_LREMAILPROMOTIONSOFFERS, CNT_LREMAILSURVEYSRESEARCH, CNT_LRPHONEEVENTSEXP, CNT_LRPHONEINCONTROL, CNT_LRPHONEOWNERVEHCOMM, CNT_LRPHONEPARTNERSSPONSORS, CNT_LRPHONEPRODSERV, CNT_LRPHONEPROMOTIONSOFFERS, CNT_LRPHONESURVEYSRESEARCH, CNT_LRPOSTEVENTSEXP, CNT_LRPOSTINCONTROL, CNT_LRPOSTOWNERVEHCOMM, CNT_LRPOSTPARTNERSSPONSORS, CNT_LRPOSTPRODSERV, CNT_LRPOSTPROMOTIONSOFFERS, CNT_LRPOSTSURVEYSRESEARCH, CNT_LRSMSEVENTSEXP, CNT_LRSMSINCONTROL, CNT_LRSMSOWNERVEHCOMM, CNT_LRSMSPARTNERSSPONSORS, CNT_LRSMSPRODSERV, CNT_LRSMSPROMOTIONSOFFERS, CNT_LRSMSSURVEYSRESEARCH, CNT_TITLE, CNT_TITLE_CODE, CNT_PREF_LANGUAGE, CNT_PREF_LANGUAGE_CODE		-- v1.3
	FROM CRM.PreOwned crm 
	WHERE crm.AuditID = @AuditID


	-- Delete the records from the CRM holding table
	DELETE
	FROM CRM.PreOwned
	WHERE AuditID = @AuditID


	-----------------------------------------------------------------------------------------------------------------------------
	-- CRM.RoadsideIncident_Roadside
	-----------------------------------------------------------------------------------------------------------------------------
	

	-- Save records prior to removing them
	INSERT INTO [$(AuditDB)].RollbackSample.CRM_RoadsideIncident_Roadside (ID, AuditID, VWTID, AuditItemID, PhysicalRowID, Converted_ACCT_DATE_OF_BIRTH, Converted_ACCT_DATE_ADVISED_OF_DEATH, Converted_VEH_REGISTRATION_DATE, Converted_VEH_BUILD_DATE, Converted_DMS_REPAIR_ORDER_CLOSED_DATE, Converted_ROADSIDE_DATE_JOB_COMPLETED, Converted_ROADSIDE_INCIDENT_DATE, Converted_CASE_CASE_SOLVED_DATE, Converted_VISTACONTRACT_HANDOVER_DATE, DateTransferredToVWT, SampleTriggeredSelectionReqID, ACCT_ACADEMIC_TITLE, ACCT_ACADEMIC_TITLE_CODE, ACCT_ACCT_ID, ACCT_ACCT_TYPE, ACCT_ACCT_TYPE_CODE, ACCT_ADDITIONAL_LAST_NAME, ACCT_BP_ROLE, ACCT_BUILDING, ACCT_CITY_CODE, ACCT_CITY_CODE2, ACCT_CITY_TOWN, ACCT_CITYH_CODE, ACCT_CONSENT_JAGUAR_EMAIL, ACCT_CONSENT_JAGUAR_PHONE, ACCT_CONSENT_JAGUAR_POST, ACCT_CONSENT_LAND_ROVER_EMAIL, ACCT_CONSENT_LAND_ROVER_POST, ACCT_CONSENT_LR_PHONE, ACCT_CORRESPONDENCE_LANG_CODE, ACCT_CORRESPONDENCE_LANGUAGE, ACCT_COUNTRY, ACCT_COUNTRY_CODE, ACCT_COUNTY, ACCT_COUNTY_CODE, ACCT_DATE_ADVISED_OF_DEATH, ACCT_DATE_DECL_TO_GIVE_EMAIL, ACCT_DATE_OF_BIRTH, ACCT_DEAL_FULNAME_OF_CREAT_DEA, ACCT_DISTRICT, ACCT_EMAIL_VALIDATION_STATUS, ACCT_EMPLOYER_NAME, ACCT_EXTERN_FINANC_COMP_ACCTID, ACCT_FIRST_NAME, ACCT_FLOOR, ACCT_FULL_NAME, ACCT_GENDER_FEMALE, ACCT_GENDER_MALE, ACCT_GENDER_UNKNOWN, ACCT_GENERATION, ACCT_HOME_CITY, ACCT_HOME_EMAIL_ADDR_PRIMARY, ACCT_HOME_PHONE_NUMBER, ACCT_HOUSE_NO, ACCT_HOUSE_NUM2, ACCT_HOUSE_NUM3, ACCT_INDUSTRY_SECTOR, ACCT_INDUSTRY_SECTOR_CODE, ACCT_INITIALS, ACCT_JAGUAR_IN_MARKET_DATE, ACCT_JAGUAR_LOYALTY_STATUS, ACCT_KNOWN_AS, ACCT_LAND_ROVER_LOYALTY_STATUS, ACCT_LAND_ROVER_MARKET_DATE, ACCT_LAST_NAME, ACCT_LOCATION, ACCT_MIDDLE_NAME, ACCT_MOBILE_NUMBER, ACCT_NAME_1, ACCT_NAME_2, ACCT_NAME_3, ACCT_NAME_4, ACCT_NAME_CO, ACCT_NON_ACADEMIC_TITLE, ACCT_NON_ACADEMIC_TITLE_CODE, ACCT_ORG_TYPE, ACCT_ORG_TYPE_CODE, ACCT_PCODE1_EXT, ACCT_PCODE2_EXT, ACCT_PCODE3_EXT, ACCT_PO_BOX, ACCT_PO_BOX_CTY, ACCT_PO_BOX_LOBBY, ACCT_PO_BOX_LOC, ACCT_PO_BOX_NUM, ACCT_PO_BOX_REG, ACCT_POST_CODE2, ACCT_POST_CODE3, ACCT_POSTALAREA, ACCT_POSTCODE_ZIP, ACCT_PREF_CONTACT_METHOD, ACCT_PREF_CONTACT_METHOD_CODE, ACCT_PREF_CONTACT_TIME, ACCT_PREF_LANGUAGE, ACCT_PREF_LANGUAGE_CODE, ACCT_REGION_STATE, ACCT_REGION_STATE_CODE, ACCT_ROOM_NUMBER, ACCT_STREET, ACCT_STREETABBR, ACCT_STREETCODE, ACCT_SUPPLEMENT_1, ACCT_SUPPLEMENT_2, ACCT_SUPPLEMENT_3, ACCT_TITLE, ACCT_TITLE_CODE, ACCT_TOWNSHIP, ACCT_TOWNSHIP_CODE, ACCT_VIP_FLAG, ACCT_WORK_PHONE_EXTENSION, ACCT_WORK_PHONE_PRIMARY, ACTIVITY_ID, CAMPAIGN_CAMPAIGN_CHANNEL, CAMPAIGN_CAMPAIGN_DESC, CAMPAIGN_CAMPAIGN_ID, CAMPAIGN_CATEGORY_1, CAMPAIGN_CATEGORY_2, CAMPAIGN_CATEGORY_3, CAMPAIGN_DEALERFULNAME_DEALER1, CAMPAIGN_DEALERFULNAME_DEALER2, CAMPAIGN_DEALERFULNAME_DEALER3, CAMPAIGN_DEALERFULNAME_DEALER4, CAMPAIGN_DEALERFULNAME_DEALER5, CAMPAIGN_SECDEALERCODE_DEALER1, CAMPAIGN_SECDEALERCODE_DEALER2, CAMPAIGN_SECDEALERCODE_DEALER3, CAMPAIGN_SECDEALERCODE_DEALER4, CAMPAIGN_SECDEALERCODE_DEALER5, CAMPAIGN_TARGET_GROUP_DESC, CAMPAIGN_TARGET_GROUP_ID, CASE_BRAND, CASE_BRAND_CODE, CASE_CASE_CREATION_DATE, CASE_CASE_DESC, CASE_CASE_EMPL_RESPONSIBLE_NAM, CASE_CASE_ID, CASE_CASE_SOLVED_DATE, CASE_EMPL_RESPONSIBLE_ID, CASE_GOODWILL_INDICATOR, CASE_REASON_FOR_STATUS, CASE_SECON_DEALER_CODE_OF_DEAL, CASE_VEH_REG_PLATE, CASE_VEH_VIN_NUMBER, CASE_VEHMODEL_DERIVED_FROM_VIN, CR_OBJECT_ID, CRH_DEALER_ROA_CITY_TOWN, CRH_DEALER_ROA_COUNTRY, CRH_DEALER_ROA_HOUSE_NO, CRH_DEALER_ROA_ID, CRH_DEALER_ROA_NAME_1, CRH_DEALER_ROA_NAME_2, CRH_DEALER_ROA_PO_BOX, CRH_DEALER_ROA_POSTCODE_ZIP, CRH_DEALER_ROA_PREFIX_1, CRH_DEALER_ROA_PREFIX_2, CRH_DEALER_ROA_REGION_STATE, CRH_DEALER_ROA_STREET, CRH_DEALER_ROA_SUPPLEMENT_1, CRH_DEALER_ROA_SUPPLEMENT_2, CRH_DEALER_ROA_SUPPLEMENT_3, CRH_END_DATE, CRH_START_DATE, DMS_ACTIVITY_DESC, DMS_DAYS_OPEN, DMS_EVENT_TYPE, DMS_LICENSE_PLATE_REGISTRATION, DMS_POTENTIAL_CHANGE_OF_OWNERS, DMS_REPAIR_ORDER_CLOSED_DATE, DMS_REPAIR_ORDER_NUMBER, DMS_REPAIR_ORDER_OPEN_DATE, DMS_SECON_DEALER_CODE, DMS_SERVICE_ADVISOR, DMS_SERVICE_ADVISOR_ID, DMS_TECHNICIAN_ID, DMS_TECHNICIAN, DMS_TOTAL_CUSTOMER_PRICE, DMS_USER_STATUS, DMS_USER_STATUS_CODE, DMS_VIN, LEAD_BRAND_CODE, LEAD_EMP_RESPONSIBLE_DEAL_NAME, LEAD_ENQUIRY_TYPE_CODE, LEAD_FUEL_TYPE_CODE, LEAD_IN_MARKET_DATE, LEAD_LEAD_CATEGORY_CODE, LEAD_LEAD_STATUS_CODE, LEAD_LEAD_STATUS_REASON_CODE, LEAD_MODEL_OF_INTEREST_CODE, LEAD_MODEL_YEAR, LEAD_NEW_USED_INDICATOR, LEAD_ORIGIN_CODE, LEAD_PRE_LAUNCH_MODEL, LEAD_PREF_CONTACT_METHOD, LEAD_SECON_DEALER_CODE, LEAD_VEH_SALE_TYPE_CODE, OBJECT_ID, ROADSIDE_ACTIVE_STATUS_CODE, ROADSIDE_ACTIVITY_DESC, ROADSIDE_COUNTRY_ISO_CODE, ROADSIDE_CUSTOMER_SUMMARY_INC, ROADSIDE_DATA_SOURCE, ROADSIDE_DATE_CALL_ANSWERED, ROADSIDE_DATE_CALL_RECEIVED, ROADSIDE_DATE_JOB_COMPLETED, ROADSIDE_DATE_RESOURCE_ALL, ROADSIDE_DATE_RESOURCE_ARRIVED, ROADSIDE_DATE_SECON_RES_ALL, ROADSIDE_DATE_SECON_RES_ARR, ROADSIDE_DRIVER_EMAIL, ROADSIDE_DRIVER_FIRST_NAME, ROADSIDE_DRIVER_LAST_NAME, ROADSIDE_DRIVER_MOBILE, ROADSIDE_DRIVER_TITLE, ROADSIDE_INCIDENT_CATEGORY, ROADSIDE_INCIDENT_COUNTRY, ROADSIDE_INCIDENT_DATE, ROADSIDE_INCIDENT_ID, ROADSIDE_INCIDENT_SUMMARY, ROADSIDE_INCIDENT_TIME, ROADSIDE_LICENSE_PLATE_REG_NO, ROADSIDE_PROVIDER, ROADSIDE_REPAIRING_SEC_DEAL_CD, ROADSIDE_RESOLUTION_TIME, ROADSIDE_TIME_CALL_ANSWERED, ROADSIDE_TIME_CALL_RECEIVED, ROADSIDE_TIME_JOB_COMPLETED, ROADSIDE_TIME_RESOURCE_ALL, ROADSIDE_TIME_RESOURCE_ARRIVED, ROADSIDE_TIME_SECON_RES_ALL, ROADSIDE_TIME_SECON_RES_ARR, ROADSIDE_VIN, ROADSIDE_WAIT_TIME, VEH_BRAND, VEH_BUILD_DATE, VEH_CHASSIS_NUMBER, VEH_COMMON_ORDER_NUMBER, VEH_COUNTRY_EQUIPMENT_CODE, VEH_CREATING_DEALER, VEH_CURR_PLANNED_DELIVERY_DATE, VEH_CURRENT_PLANNED_BUILD_DATE, VEH_DEA_NAME_LAST_SELLING_DEAL, VEH_DEALER_NAME_OF_SELLING_DEA, VEH_DELIVERED_DATE, VEH_DERIVATIVE, VEH_DRIVER_FULL_NAME, VEH_ENGINE_SIZE, VEH_EXTERIOR_COLOUR_CODE, VEH_EXTERIOR_COLOUR_DESC, VEH_EXTERIOR_COLOUR_SUPPL_CODE, VEH_EXTERIOR_COLOUR_SUPPL_DESC, VEH_FEATURE_CODE, VEH_FINANCE_PROD, VEH_FIRST_RETAIL_SALE, VEH_FUEL_TYPE_CODE, VEH_MODEL, VEH_MODEL_DESC, VEH_MODEL_YEAR, VEH_NUM_OF_OWNERS_RELATIONSHIP, VEH_ORIGIN, VEH_OWNERSHIP_STATUS, VEH_OWNERSHIP_STATUS_CODE, VEH_PAYMENT_TYPE, VEH_PREDICTED_REPLACEMENT_DATE, VEH_REACQUIRED_INDICATOR, VEH_REGISTRAT_LICENC_PLATE_NUM, VEH_REGISTRATION_DATE, VEH_VIN, VEH_VISTA_CONTRACT_NUMBER, VISTACONTRACT_COMM_TY_SALE_DS, VISTACONTRACT_HANDOVER_DATE, VISTACONTRACT_PREV_VEH_BRAND, VISTACONTRACT_PREV_VEH_MODEL, VISTACONTRACT_SALES_MAN_CD_DES, VISTACONTRACT_SALES_MAN_FULNAM, VISTACONTRACT_SALESMAN_CODE, VISTACONTRACT_SECON_DEALER_CD, VISTACONTRACT_TRADE_IN_MANUFAC, VISTACONTRACT_TRADE_IN_MODEL, VISTACONTRACT_ACTIVITY_CATEGRY, VISTACONTRACT_RETAIL_PRICE, VEH_APPR_WARNTY_TYPE, VEH_APPR_WARNTY_TYPE_DESC, VISTACONTRACTNAPPRO_RETAIL_WAR, VISTACONTRACTNAPPRO_RETAIL_DES, VISTACONTRACT_EXT_WARR, VISTACONTRACT_EXT_WARR_DESC, ACCT_CONSENT_JAGUAR_FAX, ACCT_CONSENT_LAND_ROVER_FAX, ACCT_CONSENT_JAGUAR_CHAT, ACCT_CONSENT_LAND_ROVER_CHAT, ACCT_CONSENT_JAGUAR_SMS, ACCT_CONSENT_LAND_ROVER_SMS, ACCT_CONSENT_JAGUAR_SMEDIA, ACCT_CONSENT_LAND_ROVER_SMEDIA, ACCT_CONSENT_OVER_CONT_SUP_JAG, ACCT_CONSENT_OVER_CONT_SUP_LR, ACCT_CONSENT_JAGUAR_PTSMR, ACCT_CONSENT_LAND_ROVER_PTSMR, ACCT_CONSENT_JAGUAR_PTVSM, ACCT_CONSENT_LAND_ROVER_PTVSM, ACCT_CONSENT_JAGUAR_PTAM, ACCT_CONSENT_LAND_ROVER_PTAM, ACCT_CONSENT_JAGUAR_PTNAU, ACCT_CONSENT_LAND_ROVER_PTNAU, ACCT_CONSENT_JAGUAR_PEVENT, ACCT_CONSENT_LAND_ROVER_PEVENT, ACCT_CONSENT_JAGUAR_PND3P, ACCT_CONSENT_LAND_ROVER_PND3P, ACCT_CONSENT_JAGUAR_PTSDWD, ACCT_CONSENT_LAND_ROVER_PTSDWD, ACCT_CONSENT_JAGUAR_PTPA, ACCT_CONSENT_LAND_ROVER_PTPA, RESPONSE_ID, DMS_OTHER_RELATED_SERVICES, VEH_SALE_TYPE_CODE, VISTACONTRACT_COMM_TY_SALE_CD, LEAD_STATUS_REASON_LEV1_DESC, LEAD_STATUS_REASON_LEV1_COD, LEAD_STATUS_REASON_LEV2_DESC, LEAD_STATUS_REASON_LEV2_COD, LEAD_STATUS_REASON_LEV3_DESC, LEAD_STATUS_REASON_LEV3_COD, JAGDIGITALEVENTSEXP, JAGDIGITALINCONTROL, JAGDIGITALOWNERVEHCOMM, JAGDIGITALPARTNERSSPONSORS, JAGDIGITALPRODSERV, JAGDIGITALPROMOTIONSOFFERS, JAGDIGITALSURVEYSRESEARCH, JAGEMAILEVENTSEXP, JAGEMAILINCONTROL, JAGEMAILOWNERVEHCOMM, JAGEMAILPARTNERSSPONSORS, JAGEMAILPRODSERV, JAGEMAILPROMOTIONSOFFERS, JAGEMAILSURVEYSRESEARCH, JAGPHONEEVENTSEXP, JAGPHONEINCONTROL, JAGPHONEOWNERVEHCOMM, JAGPHONEPARTNERSSPONSORS, JAGPHONEPRODSERV, JAGPHONEPROMOTIONSOFFERS, JAGPHONESURVEYSRESEARCH, JAGPOSTEVENTSEXP, JAGPOSTINCONTROL, JAGPOSTOWNERVEHCOMM, JAGPOSTPARTNERSSPONSORS, JAGPOSTPRODSERV, JAGPOSTPROMOTIONSOFFERS, JAGPOSTSURVEYSRESEARCH, JAGSMSEVENTSEXP, JAGSMSINCONTROL, JAGSMSOWNERVEHCOMM, JAGSMSPARTNERSSPONSORS, JAGSMSPRODSERV, JAGSMSPROMOTIONSOFFERS, JAGSMSSURVEYSRESEARCH, LRDIGITALEVENTSEXP, LRDIGITALINCONTROL, LRDIGITALOWNERVEHCOMM, LRDIGITALPARTNERSSPONSORS, LRDIGITALPRODSERV, LRDIGITALPROMOTIONSOFFERS, LRDIGITALSURVEYSRESEARCH, LREMAILEVENTSEXP, LREMAILINCONTROL, LREMAILOWNERVEHCOMM, LREMAILPARTNERSSPONSORS, LREMAILPRODSERV, LREMAILPROMOTIONSOFFERS, LREMAILSURVEYSRESEARCH, LRPHONEEVENTSEXP, LRPHONEINCONTROL, LRPHONEOWNERVEHCOMM, LRPHONEPARTNERSSPONSORS, LRPHONEPRODSERV, LRPHONEPROMOTIONSOFFERS, LRPHONESURVEYSRESEARCH, LRPOSTEVENTSEXP, LRPOSTINCONTROL, LRPOSTOWNERVEHCOMM, LRPOSTPARTNERSSPONSORS, LRPOSTPRODSERV, LRPOSTPROMOTIONSOFFERS, LRPOSTSURVEYSRESEARCH, LRSMSEVENTSEXP, LRSMSINCONTROL, LRSMSOWNERVEHCOMM, LRSMSPARTNERSSPONSORS, LRSMSPRODSERV, LRSMSPROMOTIONSOFFERS, LRSMSSURVEYSRESEARCH, ACCT_NAME_PREFIX_CODE, ACCT_NAME_PREFIX, DMS_REPAIR_ORDER_NUMBER_UNIQUE, VEH_SALE_TYPE_DESC, VISTACONTRACT_COMMON_ORDER_NUM, VEH_FUEL_TYPE, CNT_ABTNR, CNT_ADDRESS, CNT_DPRTMNT, CNT_FIRST_NAME, CNT_FNCTN, CNT_LAST_NAME, CNT_PAFKT, CNT_RELTYP, CNT_TEL_NUMBER, CONTACT_PER_ID, ACCT_NAME_CREATING_DEA, CNT_MOBILE_PHONE, CNT_ACADEMIC_TITLE, CNT_ACADEMIC_TITLE_CODE, CNT_NAME_PREFIX_CODE, CNT_NAME_PREFIX, CNT_JAGDIGITALEVENTSEXP, CNT_JAGDIGITALINCONTROL, CNT_JAGDIGITALOWNERVEHCOMM, CNT_JAGDIGITALPARTNERSSPONSORS, CNT_JAGDIGITALPRODSERV, CNT_JAGDIGITALPROMOTIONSOFFERS, CNT_JAGDIGITALSURVEYSRESEARCH, CNT_JAGEMAILEVENTSEXP, CNT_JAGEMAILINCONTROL, CNT_JAGEMAILOWNERVEHCOMM, CNT_JAGEMAILPARTNERSSPONSORS, CNT_JAGEMAILPRODSERV, CNT_JAGEMAILPROMOTIONSOFFERS, CNT_JAGEMAILSURVEYSRESEARCH, CNT_JAGPHONEEVENTSEXP, CNT_JAGPHONEINCONTROL, CNT_JAGPHONEOWNERVEHCOMM, CNT_JAGPHONEPARTNERSSPONSORS, CNT_JAGPHONEPRODSERV, CNT_JAGPHONEPROMOTIONSOFFERS, CNT_JAGPHONESURVEYSRESEARCH, CNT_JAGPOSTEVENTSEXP, CNT_JAGPOSTINCONTROL, CNT_JAGPOSTOWNERVEHCOMM, CNT_JAGPOSTPARTNERSSPONSORS, CNT_JAGPOSTPRODSERV, CNT_JAGPOSTPROMOTIONSOFFERS, CNT_JAGPOSTSURVEYSRESEARCH, CNT_JAGSMSEVENTSEXP, CNT_JAGSMSINCONTROL, CNT_JAGSMSOWNERVEHCOMM, CNT_JAGSMSPARTNERSSPONSORS, CNT_JAGSMSPRODSERV, CNT_JAGSMSPROMOTIONSOFFERS, CNT_JAGSMSSURVEYSRESEARCH, CNT_LRDIGITALEVENTSEXP, CNT_LRDIGITALINCONTROL, CNT_LRDIGITALOWNERVEHCOMM, CNT_LRDIGITALPARTNERSSPONSORS, CNT_LRDIGITALPRODSERV, CNT_LRDIGITALPROMOTIONSOFFERS, CNT_LRDIGITALSURVEYSRESEARCH, CNT_LREMAILEVENTSEXP, CNT_LREMAILINCONTROL, CNT_LREMAILOWNERVEHCOMM, CNT_LREMAILPARTNERSSPONSORS, CNT_LREMAILPRODSERV, CNT_LREMAILPROMOTIONSOFFERS, CNT_LREMAILSURVEYSRESEARCH, CNT_LRPHONEEVENTSEXP, CNT_LRPHONEINCONTROL, CNT_LRPHONEOWNERVEHCOMM, CNT_LRPHONEPARTNERSSPONSORS, CNT_LRPHONEPRODSERV, CNT_LRPHONEPROMOTIONSOFFERS, CNT_LRPHONESURVEYSRESEARCH, CNT_LRPOSTEVENTSEXP, CNT_LRPOSTINCONTROL, CNT_LRPOSTOWNERVEHCOMM, CNT_LRPOSTPARTNERSSPONSORS, CNT_LRPOSTPRODSERV, CNT_LRPOSTPROMOTIONSOFFERS, CNT_LRPOSTSURVEYSRESEARCH, CNT_LRSMSEVENTSEXP, CNT_LRSMSINCONTROL, CNT_LRSMSOWNERVEHCOMM, CNT_LRSMSPARTNERSSPONSORS, CNT_LRSMSPRODSERV, CNT_LRSMSPROMOTIONSOFFERS, CNT_LRSMSSURVEYSRESEARCH, CNT_TITLE, CNT_TITLE_CODE, CNT_PREF_LANGUAGE, CNT_PREF_LANGUAGE_CODE)		-- v1.3
	SELECT ID, AuditID, VWTID, AuditItemID, PhysicalRowID, Converted_ACCT_DATE_OF_BIRTH, Converted_ACCT_DATE_ADVISED_OF_DEATH, Converted_VEH_REGISTRATION_DATE, Converted_VEH_BUILD_DATE, Converted_DMS_REPAIR_ORDER_CLOSED_DATE, Converted_ROADSIDE_DATE_JOB_COMPLETED, Converted_ROADSIDE_INCIDENT_DATE, Converted_CASE_CASE_SOLVED_DATE, Converted_VISTACONTRACT_HANDOVER_DATE, DateTransferredToVWT, SampleTriggeredSelectionReqID, ACCT_ACADEMIC_TITLE, ACCT_ACADEMIC_TITLE_CODE, ACCT_ACCT_ID, ACCT_ACCT_TYPE, ACCT_ACCT_TYPE_CODE, ACCT_ADDITIONAL_LAST_NAME, ACCT_BP_ROLE, ACCT_BUILDING, ACCT_CITY_CODE, ACCT_CITY_CODE2, ACCT_CITY_TOWN, ACCT_CITYH_CODE, ACCT_CONSENT_JAGUAR_EMAIL, ACCT_CONSENT_JAGUAR_PHONE, ACCT_CONSENT_JAGUAR_POST, ACCT_CONSENT_LAND_ROVER_EMAIL, ACCT_CONSENT_LAND_ROVER_POST, ACCT_CONSENT_LR_PHONE, ACCT_CORRESPONDENCE_LANG_CODE, ACCT_CORRESPONDENCE_LANGUAGE, ACCT_COUNTRY, ACCT_COUNTRY_CODE, ACCT_COUNTY, ACCT_COUNTY_CODE, ACCT_DATE_ADVISED_OF_DEATH, ACCT_DATE_DECL_TO_GIVE_EMAIL, ACCT_DATE_OF_BIRTH, ACCT_DEAL_FULNAME_OF_CREAT_DEA, ACCT_DISTRICT, ACCT_EMAIL_VALIDATION_STATUS, ACCT_EMPLOYER_NAME, ACCT_EXTERN_FINANC_COMP_ACCTID, ACCT_FIRST_NAME, ACCT_FLOOR, ACCT_FULL_NAME, ACCT_GENDER_FEMALE, ACCT_GENDER_MALE, ACCT_GENDER_UNKNOWN, ACCT_GENERATION, ACCT_HOME_CITY, ACCT_HOME_EMAIL_ADDR_PRIMARY, ACCT_HOME_PHONE_NUMBER, ACCT_HOUSE_NO, ACCT_HOUSE_NUM2, ACCT_HOUSE_NUM3, ACCT_INDUSTRY_SECTOR, ACCT_INDUSTRY_SECTOR_CODE, ACCT_INITIALS, ACCT_JAGUAR_IN_MARKET_DATE, ACCT_JAGUAR_LOYALTY_STATUS, ACCT_KNOWN_AS, ACCT_LAND_ROVER_LOYALTY_STATUS, ACCT_LAND_ROVER_MARKET_DATE, ACCT_LAST_NAME, ACCT_LOCATION, ACCT_MIDDLE_NAME, ACCT_MOBILE_NUMBER, ACCT_NAME_1, ACCT_NAME_2, ACCT_NAME_3, ACCT_NAME_4, ACCT_NAME_CO, ACCT_NON_ACADEMIC_TITLE, ACCT_NON_ACADEMIC_TITLE_CODE, ACCT_ORG_TYPE, ACCT_ORG_TYPE_CODE, ACCT_PCODE1_EXT, ACCT_PCODE2_EXT, ACCT_PCODE3_EXT, ACCT_PO_BOX, ACCT_PO_BOX_CTY, ACCT_PO_BOX_LOBBY, ACCT_PO_BOX_LOC, ACCT_PO_BOX_NUM, ACCT_PO_BOX_REG, ACCT_POST_CODE2, ACCT_POST_CODE3, ACCT_POSTALAREA, ACCT_POSTCODE_ZIP, ACCT_PREF_CONTACT_METHOD, ACCT_PREF_CONTACT_METHOD_CODE, ACCT_PREF_CONTACT_TIME, ACCT_PREF_LANGUAGE, ACCT_PREF_LANGUAGE_CODE, ACCT_REGION_STATE, ACCT_REGION_STATE_CODE, ACCT_ROOM_NUMBER, ACCT_STREET, ACCT_STREETABBR, ACCT_STREETCODE, ACCT_SUPPLEMENT_1, ACCT_SUPPLEMENT_2, ACCT_SUPPLEMENT_3, ACCT_TITLE, ACCT_TITLE_CODE, ACCT_TOWNSHIP, ACCT_TOWNSHIP_CODE, ACCT_VIP_FLAG, ACCT_WORK_PHONE_EXTENSION, ACCT_WORK_PHONE_PRIMARY, ACTIVITY_ID, CAMPAIGN_CAMPAIGN_CHANNEL, CAMPAIGN_CAMPAIGN_DESC, CAMPAIGN_CAMPAIGN_ID, CAMPAIGN_CATEGORY_1, CAMPAIGN_CATEGORY_2, CAMPAIGN_CATEGORY_3, CAMPAIGN_DEALERFULNAME_DEALER1, CAMPAIGN_DEALERFULNAME_DEALER2, CAMPAIGN_DEALERFULNAME_DEALER3, CAMPAIGN_DEALERFULNAME_DEALER4, CAMPAIGN_DEALERFULNAME_DEALER5, CAMPAIGN_SECDEALERCODE_DEALER1, CAMPAIGN_SECDEALERCODE_DEALER2, CAMPAIGN_SECDEALERCODE_DEALER3, CAMPAIGN_SECDEALERCODE_DEALER4, CAMPAIGN_SECDEALERCODE_DEALER5, CAMPAIGN_TARGET_GROUP_DESC, CAMPAIGN_TARGET_GROUP_ID, CASE_BRAND, CASE_BRAND_CODE, CASE_CASE_CREATION_DATE, CASE_CASE_DESC, CASE_CASE_EMPL_RESPONSIBLE_NAM, CASE_CASE_ID, CASE_CASE_SOLVED_DATE, CASE_EMPL_RESPONSIBLE_ID, CASE_GOODWILL_INDICATOR, CASE_REASON_FOR_STATUS, CASE_SECON_DEALER_CODE_OF_DEAL, CASE_VEH_REG_PLATE, CASE_VEH_VIN_NUMBER, CASE_VEHMODEL_DERIVED_FROM_VIN, CR_OBJECT_ID, CRH_DEALER_ROA_CITY_TOWN, CRH_DEALER_ROA_COUNTRY, CRH_DEALER_ROA_HOUSE_NO, CRH_DEALER_ROA_ID, CRH_DEALER_ROA_NAME_1, CRH_DEALER_ROA_NAME_2, CRH_DEALER_ROA_PO_BOX, CRH_DEALER_ROA_POSTCODE_ZIP, CRH_DEALER_ROA_PREFIX_1, CRH_DEALER_ROA_PREFIX_2, CRH_DEALER_ROA_REGION_STATE, CRH_DEALER_ROA_STREET, CRH_DEALER_ROA_SUPPLEMENT_1, CRH_DEALER_ROA_SUPPLEMENT_2, CRH_DEALER_ROA_SUPPLEMENT_3, CRH_END_DATE, CRH_START_DATE, DMS_ACTIVITY_DESC, DMS_DAYS_OPEN, DMS_EVENT_TYPE, DMS_LICENSE_PLATE_REGISTRATION, DMS_POTENTIAL_CHANGE_OF_OWNERS, DMS_REPAIR_ORDER_CLOSED_DATE, DMS_REPAIR_ORDER_NUMBER, DMS_REPAIR_ORDER_OPEN_DATE, DMS_SECON_DEALER_CODE, DMS_SERVICE_ADVISOR, DMS_SERVICE_ADVISOR_ID, DMS_TECHNICIAN_ID, DMS_TECHNICIAN, DMS_TOTAL_CUSTOMER_PRICE, DMS_USER_STATUS, DMS_USER_STATUS_CODE, DMS_VIN, LEAD_BRAND_CODE, LEAD_EMP_RESPONSIBLE_DEAL_NAME, LEAD_ENQUIRY_TYPE_CODE, LEAD_FUEL_TYPE_CODE, LEAD_IN_MARKET_DATE, LEAD_LEAD_CATEGORY_CODE, LEAD_LEAD_STATUS_CODE, LEAD_LEAD_STATUS_REASON_CODE, LEAD_MODEL_OF_INTEREST_CODE, LEAD_MODEL_YEAR, LEAD_NEW_USED_INDICATOR, LEAD_ORIGIN_CODE, LEAD_PRE_LAUNCH_MODEL, LEAD_PREF_CONTACT_METHOD, LEAD_SECON_DEALER_CODE, LEAD_VEH_SALE_TYPE_CODE, OBJECT_ID, ROADSIDE_ACTIVE_STATUS_CODE, ROADSIDE_ACTIVITY_DESC, ROADSIDE_COUNTRY_ISO_CODE, ROADSIDE_CUSTOMER_SUMMARY_INC, ROADSIDE_DATA_SOURCE, ROADSIDE_DATE_CALL_ANSWERED, ROADSIDE_DATE_CALL_RECEIVED, ROADSIDE_DATE_JOB_COMPLETED, ROADSIDE_DATE_RESOURCE_ALL, ROADSIDE_DATE_RESOURCE_ARRIVED, ROADSIDE_DATE_SECON_RES_ALL, ROADSIDE_DATE_SECON_RES_ARR, ROADSIDE_DRIVER_EMAIL, ROADSIDE_DRIVER_FIRST_NAME, ROADSIDE_DRIVER_LAST_NAME, ROADSIDE_DRIVER_MOBILE, ROADSIDE_DRIVER_TITLE, ROADSIDE_INCIDENT_CATEGORY, ROADSIDE_INCIDENT_COUNTRY, ROADSIDE_INCIDENT_DATE, ROADSIDE_INCIDENT_ID, ROADSIDE_INCIDENT_SUMMARY, ROADSIDE_INCIDENT_TIME, ROADSIDE_LICENSE_PLATE_REG_NO, ROADSIDE_PROVIDER, ROADSIDE_REPAIRING_SEC_DEAL_CD, ROADSIDE_RESOLUTION_TIME, ROADSIDE_TIME_CALL_ANSWERED, ROADSIDE_TIME_CALL_RECEIVED, ROADSIDE_TIME_JOB_COMPLETED, ROADSIDE_TIME_RESOURCE_ALL, ROADSIDE_TIME_RESOURCE_ARRIVED, ROADSIDE_TIME_SECON_RES_ALL, ROADSIDE_TIME_SECON_RES_ARR, ROADSIDE_VIN, ROADSIDE_WAIT_TIME, VEH_BRAND, VEH_BUILD_DATE, VEH_CHASSIS_NUMBER, VEH_COMMON_ORDER_NUMBER, VEH_COUNTRY_EQUIPMENT_CODE, VEH_CREATING_DEALER, VEH_CURR_PLANNED_DELIVERY_DATE, VEH_CURRENT_PLANNED_BUILD_DATE, VEH_DEA_NAME_LAST_SELLING_DEAL, VEH_DEALER_NAME_OF_SELLING_DEA, VEH_DELIVERED_DATE, VEH_DERIVATIVE, VEH_DRIVER_FULL_NAME, VEH_ENGINE_SIZE, VEH_EXTERIOR_COLOUR_CODE, VEH_EXTERIOR_COLOUR_DESC, VEH_EXTERIOR_COLOUR_SUPPL_CODE, VEH_EXTERIOR_COLOUR_SUPPL_DESC, VEH_FEATURE_CODE, VEH_FINANCE_PROD, VEH_FIRST_RETAIL_SALE, VEH_FUEL_TYPE_CODE, VEH_MODEL, VEH_MODEL_DESC, VEH_MODEL_YEAR, VEH_NUM_OF_OWNERS_RELATIONSHIP, VEH_ORIGIN, VEH_OWNERSHIP_STATUS, VEH_OWNERSHIP_STATUS_CODE, VEH_PAYMENT_TYPE, VEH_PREDICTED_REPLACEMENT_DATE, VEH_REACQUIRED_INDICATOR, VEH_REGISTRAT_LICENC_PLATE_NUM, VEH_REGISTRATION_DATE, VEH_VIN, VEH_VISTA_CONTRACT_NUMBER, VISTACONTRACT_COMM_TY_SALE_DS, VISTACONTRACT_HANDOVER_DATE, VISTACONTRACT_PREV_VEH_BRAND, VISTACONTRACT_PREV_VEH_MODEL, VISTACONTRACT_SALES_MAN_CD_DES, VISTACONTRACT_SALES_MAN_FULNAM, VISTACONTRACT_SALESMAN_CODE, VISTACONTRACT_SECON_DEALER_CD, VISTACONTRACT_TRADE_IN_MANUFAC, VISTACONTRACT_TRADE_IN_MODEL, VISTACONTRACT_ACTIVITY_CATEGRY, VISTACONTRACT_RETAIL_PRICE, VEH_APPR_WARNTY_TYPE, VEH_APPR_WARNTY_TYPE_DESC, VISTACONTRACTNAPPRO_RETAIL_WAR, VISTACONTRACTNAPPRO_RETAIL_DES, VISTACONTRACT_EXT_WARR, VISTACONTRACT_EXT_WARR_DESC, ACCT_CONSENT_JAGUAR_FAX, ACCT_CONSENT_LAND_ROVER_FAX, ACCT_CONSENT_JAGUAR_CHAT, ACCT_CONSENT_LAND_ROVER_CHAT, ACCT_CONSENT_JAGUAR_SMS, ACCT_CONSENT_LAND_ROVER_SMS, ACCT_CONSENT_JAGUAR_SMEDIA, ACCT_CONSENT_LAND_ROVER_SMEDIA, ACCT_CONSENT_OVER_CONT_SUP_JAG, ACCT_CONSENT_OVER_CONT_SUP_LR, ACCT_CONSENT_JAGUAR_PTSMR, ACCT_CONSENT_LAND_ROVER_PTSMR, ACCT_CONSENT_JAGUAR_PTVSM, ACCT_CONSENT_LAND_ROVER_PTVSM, ACCT_CONSENT_JAGUAR_PTAM, ACCT_CONSENT_LAND_ROVER_PTAM, ACCT_CONSENT_JAGUAR_PTNAU, ACCT_CONSENT_LAND_ROVER_PTNAU, ACCT_CONSENT_JAGUAR_PEVENT, ACCT_CONSENT_LAND_ROVER_PEVENT, ACCT_CONSENT_JAGUAR_PND3P, ACCT_CONSENT_LAND_ROVER_PND3P, ACCT_CONSENT_JAGUAR_PTSDWD, ACCT_CONSENT_LAND_ROVER_PTSDWD, ACCT_CONSENT_JAGUAR_PTPA, ACCT_CONSENT_LAND_ROVER_PTPA, RESPONSE_ID, DMS_OTHER_RELATED_SERVICES, VEH_SALE_TYPE_CODE, VISTACONTRACT_COMM_TY_SALE_CD, LEAD_STATUS_REASON_LEV1_DESC, LEAD_STATUS_REASON_LEV1_COD, LEAD_STATUS_REASON_LEV2_DESC, LEAD_STATUS_REASON_LEV2_COD, LEAD_STATUS_REASON_LEV3_DESC, LEAD_STATUS_REASON_LEV3_COD, JAGDIGITALEVENTSEXP, JAGDIGITALINCONTROL, JAGDIGITALOWNERVEHCOMM, JAGDIGITALPARTNERSSPONSORS, JAGDIGITALPRODSERV, JAGDIGITALPROMOTIONSOFFERS, JAGDIGITALSURVEYSRESEARCH, JAGEMAILEVENTSEXP, JAGEMAILINCONTROL, JAGEMAILOWNERVEHCOMM, JAGEMAILPARTNERSSPONSORS, JAGEMAILPRODSERV, JAGEMAILPROMOTIONSOFFERS, JAGEMAILSURVEYSRESEARCH, JAGPHONEEVENTSEXP, JAGPHONEINCONTROL, JAGPHONEOWNERVEHCOMM, JAGPHONEPARTNERSSPONSORS, JAGPHONEPRODSERV, JAGPHONEPROMOTIONSOFFERS, JAGPHONESURVEYSRESEARCH, JAGPOSTEVENTSEXP, JAGPOSTINCONTROL, JAGPOSTOWNERVEHCOMM, JAGPOSTPARTNERSSPONSORS, JAGPOSTPRODSERV, JAGPOSTPROMOTIONSOFFERS, JAGPOSTSURVEYSRESEARCH, JAGSMSEVENTSEXP, JAGSMSINCONTROL, JAGSMSOWNERVEHCOMM, JAGSMSPARTNERSSPONSORS, JAGSMSPRODSERV, JAGSMSPROMOTIONSOFFERS, JAGSMSSURVEYSRESEARCH, LRDIGITALEVENTSEXP, LRDIGITALINCONTROL, LRDIGITALOWNERVEHCOMM, LRDIGITALPARTNERSSPONSORS, LRDIGITALPRODSERV, LRDIGITALPROMOTIONSOFFERS, LRDIGITALSURVEYSRESEARCH, LREMAILEVENTSEXP, LREMAILINCONTROL, LREMAILOWNERVEHCOMM, LREMAILPARTNERSSPONSORS, LREMAILPRODSERV, LREMAILPROMOTIONSOFFERS, LREMAILSURVEYSRESEARCH, LRPHONEEVENTSEXP, LRPHONEINCONTROL, LRPHONEOWNERVEHCOMM, LRPHONEPARTNERSSPONSORS, LRPHONEPRODSERV, LRPHONEPROMOTIONSOFFERS, LRPHONESURVEYSRESEARCH, LRPOSTEVENTSEXP, LRPOSTINCONTROL, LRPOSTOWNERVEHCOMM, LRPOSTPARTNERSSPONSORS, LRPOSTPRODSERV, LRPOSTPROMOTIONSOFFERS, LRPOSTSURVEYSRESEARCH, LRSMSEVENTSEXP, LRSMSINCONTROL, LRSMSOWNERVEHCOMM, LRSMSPARTNERSSPONSORS, LRSMSPRODSERV, LRSMSPROMOTIONSOFFERS, LRSMSSURVEYSRESEARCH, ACCT_NAME_PREFIX_CODE, ACCT_NAME_PREFIX, DMS_REPAIR_ORDER_NUMBER_UNIQUE, VEH_SALE_TYPE_DESC, VISTACONTRACT_COMMON_ORDER_NUM, VEH_FUEL_TYPE, CNT_ABTNR, CNT_ADDRESS, CNT_DPRTMNT, CNT_FIRST_NAME, CNT_FNCTN, CNT_LAST_NAME, CNT_PAFKT, CNT_RELTYP, CNT_TEL_NUMBER, CONTACT_PER_ID, ACCT_NAME_CREATING_DEA, CNT_MOBILE_PHONE, CNT_ACADEMIC_TITLE, CNT_ACADEMIC_TITLE_CODE, CNT_NAME_PREFIX_CODE, CNT_NAME_PREFIX, CNT_JAGDIGITALEVENTSEXP, CNT_JAGDIGITALINCONTROL, CNT_JAGDIGITALOWNERVEHCOMM, CNT_JAGDIGITALPARTNERSSPONSORS, CNT_JAGDIGITALPRODSERV, CNT_JAGDIGITALPROMOTIONSOFFERS, CNT_JAGDIGITALSURVEYSRESEARCH, CNT_JAGEMAILEVENTSEXP, CNT_JAGEMAILINCONTROL, CNT_JAGEMAILOWNERVEHCOMM, CNT_JAGEMAILPARTNERSSPONSORS, CNT_JAGEMAILPRODSERV, CNT_JAGEMAILPROMOTIONSOFFERS, CNT_JAGEMAILSURVEYSRESEARCH, CNT_JAGPHONEEVENTSEXP, CNT_JAGPHONEINCONTROL, CNT_JAGPHONEOWNERVEHCOMM, CNT_JAGPHONEPARTNERSSPONSORS, CNT_JAGPHONEPRODSERV, CNT_JAGPHONEPROMOTIONSOFFERS, CNT_JAGPHONESURVEYSRESEARCH, CNT_JAGPOSTEVENTSEXP, CNT_JAGPOSTINCONTROL, CNT_JAGPOSTOWNERVEHCOMM, CNT_JAGPOSTPARTNERSSPONSORS, CNT_JAGPOSTPRODSERV, CNT_JAGPOSTPROMOTIONSOFFERS, CNT_JAGPOSTSURVEYSRESEARCH, CNT_JAGSMSEVENTSEXP, CNT_JAGSMSINCONTROL, CNT_JAGSMSOWNERVEHCOMM, CNT_JAGSMSPARTNERSSPONSORS, CNT_JAGSMSPRODSERV, CNT_JAGSMSPROMOTIONSOFFERS, CNT_JAGSMSSURVEYSRESEARCH, CNT_LRDIGITALEVENTSEXP, CNT_LRDIGITALINCONTROL, CNT_LRDIGITALOWNERVEHCOMM, CNT_LRDIGITALPARTNERSSPONSORS, CNT_LRDIGITALPRODSERV, CNT_LRDIGITALPROMOTIONSOFFERS, CNT_LRDIGITALSURVEYSRESEARCH, CNT_LREMAILEVENTSEXP, CNT_LREMAILINCONTROL, CNT_LREMAILOWNERVEHCOMM, CNT_LREMAILPARTNERSSPONSORS, CNT_LREMAILPRODSERV, CNT_LREMAILPROMOTIONSOFFERS, CNT_LREMAILSURVEYSRESEARCH, CNT_LRPHONEEVENTSEXP, CNT_LRPHONEINCONTROL, CNT_LRPHONEOWNERVEHCOMM, CNT_LRPHONEPARTNERSSPONSORS, CNT_LRPHONEPRODSERV, CNT_LRPHONEPROMOTIONSOFFERS, CNT_LRPHONESURVEYSRESEARCH, CNT_LRPOSTEVENTSEXP, CNT_LRPOSTINCONTROL, CNT_LRPOSTOWNERVEHCOMM, CNT_LRPOSTPARTNERSSPONSORS, CNT_LRPOSTPRODSERV, CNT_LRPOSTPROMOTIONSOFFERS, CNT_LRPOSTSURVEYSRESEARCH, CNT_LRSMSEVENTSEXP, CNT_LRSMSINCONTROL, CNT_LRSMSOWNERVEHCOMM, CNT_LRSMSPARTNERSSPONSORS, CNT_LRSMSPRODSERV, CNT_LRSMSPROMOTIONSOFFERS, CNT_LRSMSSURVEYSRESEARCH, CNT_TITLE, CNT_TITLE_CODE, CNT_PREF_LANGUAGE, CNT_PREF_LANGUAGE_CODE		-- v1.3
	FROM CRM.RoadsideIncident_Roadside crm 
	WHERE crm.AuditID = @AuditID


	-- Delete the records from the CRM holding table
	DELETE
	FROM CRM.RoadsideIncident_Roadside
	WHERE AuditID = @AuditID


	-----------------------------------------------------------------------------------------------------------------------------
	-- CRM.Vista_Contract_Sales
	-----------------------------------------------------------------------------------------------------------------------------
	

	-- Save records prior to removing them
	INSERT INTO [$(AuditDB)].RollbackSample.CRM_Vista_Contract_Sales (ID, AuditID, VWTID, AuditItemID, PhysicalRowID, Converted_ACCT_DATE_OF_BIRTH, Converted_ACCT_DATE_ADVISED_OF_DEATH, Converted_VEH_REGISTRATION_DATE, Converted_VEH_BUILD_DATE, Converted_DMS_REPAIR_ORDER_CLOSED_DATE, Converted_ROADSIDE_DATE_JOB_COMPLETED, Converted_CASE_CASE_SOLVED_DATE, Converted_VISTACONTRACT_HANDOVER_DATE, DateTransferredToVWT, SampleTriggeredSelectionReqID, AFRLCode, ACCT_ACADEMIC_TITLE, ACCT_ACADEMIC_TITLE_CODE, ACCT_ACCT_ID, ACCT_ACCT_TYPE, ACCT_ACCT_TYPE_CODE, ACCT_ADDITIONAL_LAST_NAME, ACCT_BP_ROLE, ACCT_BUILDING, ACCT_CITY_CODE, ACCT_CITY_CODE2, ACCT_CITY_TOWN, ACCT_CITYH_CODE, ACCT_CONSENT_JAGUAR_EMAIL, ACCT_CONSENT_JAGUAR_PHONE, ACCT_CONSENT_JAGUAR_POST, ACCT_CONSENT_LAND_ROVER_EMAIL, ACCT_CONSENT_LAND_ROVER_POST, ACCT_CONSENT_LR_PHONE, ACCT_CORRESPONDENCE_LANG_CODE, ACCT_CORRESPONDENCE_LANGUAGE, ACCT_COUNTRY, ACCT_COUNTRY_CODE, ACCT_COUNTY, ACCT_COUNTY_CODE, ACCT_DATE_ADVISED_OF_DEATH, ACCT_DATE_DECL_TO_GIVE_EMAIL, ACCT_DATE_OF_BIRTH, ACCT_DEAL_FULNAME_OF_CREAT_DEA, ACCT_DISTRICT, ACCT_EMAIL_VALIDATION_STATUS, ACCT_EMPLOYER_NAME, ACCT_EXTERN_FINANC_COMP_ACCTID, ACCT_FIRST_NAME, ACCT_FLOOR, ACCT_FULL_NAME, ACCT_GENDER_FEMALE, ACCT_GENDER_MALE, ACCT_GENDER_UNKNOWN, ACCT_GENERATION, ACCT_HOME_CITY, ACCT_HOME_EMAIL_ADDR_PRIMARY, ACCT_HOME_PHONE_NUMBER, ACCT_HOUSE_NO, ACCT_HOUSE_NUM2, ACCT_HOUSE_NUM3, ACCT_INDUSTRY_SECTOR, ACCT_INDUSTRY_SECTOR_CODE, ACCT_INITIALS, ACCT_JAGUAR_IN_MARKET_DATE, ACCT_JAGUAR_LOYALTY_STATUS, ACCT_KNOWN_AS, ACCT_LAND_ROVER_LOYALTY_STATUS, ACCT_LAND_ROVER_MARKET_DATE, ACCT_LAST_NAME, ACCT_LOCATION, ACCT_MIDDLE_NAME, ACCT_MOBILE_NUMBER, ACCT_NAME_1, ACCT_NAME_2, ACCT_NAME_3, ACCT_NAME_4, ACCT_NAME_CO, ACCT_NON_ACADEMIC_TITLE, ACCT_NON_ACADEMIC_TITLE_CODE, ACCT_ORG_TYPE, ACCT_ORG_TYPE_CODE, ACCT_PCODE1_EXT, ACCT_PCODE2_EXT, ACCT_PCODE3_EXT, ACCT_PO_BOX, ACCT_PO_BOX_CTY, ACCT_PO_BOX_LOBBY, ACCT_PO_BOX_LOC, ACCT_PO_BOX_NUM, ACCT_PO_BOX_REG, ACCT_POST_CODE2, ACCT_POST_CODE3, ACCT_POSTALAREA, ACCT_POSTCODE_ZIP, ACCT_PREF_CONTACT_METHOD, ACCT_PREF_CONTACT_METHOD_CODE, ACCT_PREF_CONTACT_TIME, ACCT_PREF_LANGUAGE, ACCT_PREF_LANGUAGE_CODE, ACCT_REGION_STATE, ACCT_REGION_STATE_CODE, ACCT_ROOM_NUMBER, ACCT_STREET, ACCT_STREETABBR, ACCT_STREETCODE, ACCT_SUPPLEMENT_1, ACCT_SUPPLEMENT_2, ACCT_SUPPLEMENT_3, ACCT_TITLE, ACCT_TITLE_CODE, ACCT_TOWNSHIP, ACCT_TOWNSHIP_CODE, ACCT_VIP_FLAG, ACCT_WORK_PHONE_EXTENSION, ACCT_WORK_PHONE_PRIMARY, ACTIVITY_ID, CAMPAIGN_CAMPAIGN_CHANNEL, CAMPAIGN_CAMPAIGN_DESC, CAMPAIGN_CAMPAIGN_ID, CAMPAIGN_CATEGORY_1, CAMPAIGN_CATEGORY_2, CAMPAIGN_CATEGORY_3, CAMPAIGN_DEALERFULNAME_DEALER1, CAMPAIGN_DEALERFULNAME_DEALER2, CAMPAIGN_DEALERFULNAME_DEALER3, CAMPAIGN_DEALERFULNAME_DEALER4, CAMPAIGN_DEALERFULNAME_DEALER5, CAMPAIGN_SECDEALERCODE_DEALER1, CAMPAIGN_SECDEALERCODE_DEALER2, CAMPAIGN_SECDEALERCODE_DEALER3, CAMPAIGN_SECDEALERCODE_DEALER4, CAMPAIGN_SECDEALERCODE_DEALER5, CAMPAIGN_TARGET_GROUP_DESC, CAMPAIGN_TARGET_GROUP_ID, CASE_BRAND, CASE_BRAND_CODE, CASE_CASE_CREATION_DATE, CASE_CASE_DESC, CASE_CASE_EMPL_RESPONSIBLE_NAM, CASE_CASE_ID, CASE_CASE_SOLVED_DATE, CASE_EMPL_RESPONSIBLE_ID, CASE_GOODWILL_INDICATOR, CASE_REASON_FOR_STATUS, CASE_SECON_DEALER_CODE_OF_DEAL, CASE_VEH_REG_PLATE, CASE_VEH_VIN_NUMBER, CASE_VEHMODEL_DERIVED_FROM_VIN, CR_OBJECT_ID, CRH_DEALER_ROA_CITY_TOWN, CRH_DEALER_ROA_COUNTRY, CRH_DEALER_ROA_HOUSE_NO, CRH_DEALER_ROA_ID, CRH_DEALER_ROA_NAME_1, CRH_DEALER_ROA_NAME_2, CRH_DEALER_ROA_PO_BOX, CRH_DEALER_ROA_POSTCODE_ZIP, CRH_DEALER_ROA_PREFIX_1, CRH_DEALER_ROA_PREFIX_2, CRH_DEALER_ROA_REGION_STATE, CRH_DEALER_ROA_STREET, CRH_DEALER_ROA_SUPPLEMENT_1, CRH_DEALER_ROA_SUPPLEMENT_2, CRH_DEALER_ROA_SUPPLEMENT_3, CRH_END_DATE, CRH_START_DATE, DMS_ACTIVITY_DESC, DMS_DAYS_OPEN, DMS_EVENT_TYPE, DMS_LICENSE_PLATE_REGISTRATION, DMS_POTENTIAL_CHANGE_OF_OWNERS, DMS_REPAIR_ORDER_CLOSED_DATE, DMS_REPAIR_ORDER_NUMBER, DMS_REPAIR_ORDER_OPEN_DATE, DMS_SECON_DEALER_CODE, DMS_SERVICE_ADVISOR, DMS_SERVICE_ADVISOR_ID, DMS_TECHNICIAN_ID, DMS_TECHNICIAN, DMS_TOTAL_CUSTOMER_PRICE, DMS_USER_STATUS, DMS_USER_STATUS_CODE, DMS_VIN, LEAD_BRAND_CODE, LEAD_EMP_RESPONSIBLE_DEAL_NAME, LEAD_ENQUIRY_TYPE_CODE, LEAD_FUEL_TYPE_CODE, LEAD_IN_MARKET_DATE, LEAD_LEAD_CATEGORY_CODE, LEAD_LEAD_STATUS_CODE, LEAD_LEAD_STATUS_REASON_CODE, LEAD_MODEL_OF_INTEREST_CODE, LEAD_MODEL_YEAR, LEAD_NEW_USED_INDICATOR, LEAD_ORIGIN_CODE, LEAD_PRE_LAUNCH_MODEL, LEAD_PREF_CONTACT_METHOD, LEAD_SECON_DEALER_CODE, LEAD_VEH_SALE_TYPE_CODE, OBJECT_ID, ROADSIDE_ACTIVE_STATUS_CODE, ROADSIDE_ACTIVITY_DESC, ROADSIDE_COUNTRY_ISO_CODE, ROADSIDE_CUSTOMER_SUMMARY_INC, ROADSIDE_DATA_SOURCE, ROADSIDE_DATE_CALL_ANSWERED, ROADSIDE_DATE_CALL_RECEIVED, ROADSIDE_DATE_JOB_COMPLETED, ROADSIDE_DATE_RESOURCE_ALL, ROADSIDE_DATE_RESOURCE_ARRIVED, ROADSIDE_DATE_SECON_RES_ALL, ROADSIDE_DATE_SECON_RES_ARR, ROADSIDE_DRIVER_EMAIL, ROADSIDE_DRIVER_FIRST_NAME, ROADSIDE_DRIVER_LAST_NAME, ROADSIDE_DRIVER_MOBILE, ROADSIDE_DRIVER_TITLE, ROADSIDE_INCIDENT_CATEGORY, ROADSIDE_INCIDENT_COUNTRY, ROADSIDE_INCIDENT_DATE, ROADSIDE_INCIDENT_ID, ROADSIDE_INCIDENT_SUMMARY, ROADSIDE_INCIDENT_TIME, ROADSIDE_LICENSE_PLATE_REG_NO, ROADSIDE_PROVIDER, ROADSIDE_REPAIRING_SEC_DEAL_CD, ROADSIDE_RESOLUTION_TIME, ROADSIDE_TIME_CALL_ANSWERED, ROADSIDE_TIME_CALL_RECEIVED, ROADSIDE_TIME_JOB_COMPLETED, ROADSIDE_TIME_RESOURCE_ALL, ROADSIDE_TIME_RESOURCE_ARRIVED, ROADSIDE_TIME_SECON_RES_ALL, ROADSIDE_TIME_SECON_RES_ARR, ROADSIDE_VIN, ROADSIDE_WAIT_TIME, VEH_BRAND, VEH_BUILD_DATE, VEH_CHASSIS_NUMBER, VEH_COMMON_ORDER_NUMBER, VEH_COUNTRY_EQUIPMENT_CODE, VEH_CREATING_DEALER, VEH_CURR_PLANNED_DELIVERY_DATE, VEH_CURRENT_PLANNED_BUILD_DATE, VEH_DEA_NAME_LAST_SELLING_DEAL, VEH_DEALER_NAME_OF_SELLING_DEA, VEH_DELIVERED_DATE, VEH_DERIVATIVE, VEH_DRIVER_FULL_NAME, VEH_ENGINE_SIZE, VEH_EXTERIOR_COLOUR_CODE, VEH_EXTERIOR_COLOUR_DESC, VEH_EXTERIOR_COLOUR_SUPPL_CODE, VEH_EXTERIOR_COLOUR_SUPPL_DESC, VEH_FEATURE_CODE, VEH_FINANCE_PROD, VEH_FIRST_RETAIL_SALE, VEH_FUEL_TYPE_CODE, VEH_MODEL, VEH_MODEL_DESC, VEH_MODEL_YEAR, VEH_NUM_OF_OWNERS_RELATIONSHIP, VEH_ORIGIN, VEH_OWNERSHIP_STATUS, VEH_OWNERSHIP_STATUS_CODE, VEH_PAYMENT_TYPE, VEH_PREDICTED_REPLACEMENT_DATE, VEH_REACQUIRED_INDICATOR, VEH_REGISTRAT_LICENC_PLATE_NUM, VEH_REGISTRATION_DATE, VEH_SALE_TYPE_DESC, VEH_VIN, VEH_VISTA_CONTRACT_NUMBER, VISTACONTRACT_COMM_TY_SALE_DS, VISTACONTRACT_HANDOVER_DATE, VISTACONTRACT_PREV_VEH_BRAND, VISTACONTRACT_PREV_VEH_MODEL, VISTACONTRACT_SALES_MAN_CD_DES, VISTACONTRACT_SALES_MAN_FULNAM, VISTACONTRACT_SALESMAN_CODE, VISTACONTRACT_SECON_DEALER_CD, VISTACONTRACT_TRADE_IN_MANUFAC, VISTACONTRACT_TRADE_IN_MODEL, VISTACONTRACT_ACTIVITY_CATEGRY, VISTACONTRACT_RETAIL_PRICE, VEH_APPR_WARNTY_TYPE, VEH_APPR_WARNTY_TYPE_DESC, VISTACONTRACTNAPPRO_RETAIL_WAR, VISTACONTRACTNAPPRO_RETAIL_DES, VISTACONTRACT_EXT_WARR, VISTACONTRACT_EXT_WARR_DESC, ACCT_CONSENT_JAGUAR_FAX, ACCT_CONSENT_LAND_ROVER_FAX, ACCT_CONSENT_JAGUAR_CHAT, ACCT_CONSENT_LAND_ROVER_CHAT, ACCT_CONSENT_JAGUAR_SMS, ACCT_CONSENT_LAND_ROVER_SMS, ACCT_CONSENT_JAGUAR_SMEDIA, ACCT_CONSENT_LAND_ROVER_SMEDIA, ACCT_CONSENT_OVER_CONT_SUP_JAG, ACCT_CONSENT_OVER_CONT_SUP_LR, ACCT_CONSENT_JAGUAR_PTSMR, ACCT_CONSENT_LAND_ROVER_PTSMR, ACCT_CONSENT_JAGUAR_PTVSM, ACCT_CONSENT_LAND_ROVER_PTVSM, ACCT_CONSENT_JAGUAR_PTAM, ACCT_CONSENT_LAND_ROVER_PTAM, ACCT_CONSENT_JAGUAR_PTNAU, ACCT_CONSENT_LAND_ROVER_PTNAU, ACCT_CONSENT_JAGUAR_PEVENT, ACCT_CONSENT_LAND_ROVER_PEVENT, ACCT_CONSENT_JAGUAR_PND3P, ACCT_CONSENT_LAND_ROVER_PND3P, ACCT_CONSENT_JAGUAR_PTSDWD, ACCT_CONSENT_LAND_ROVER_PTSDWD, ACCT_CONSENT_JAGUAR_PTPA, ACCT_CONSENT_LAND_ROVER_PTPA, RESPONSE_ID, VISTACONTRACT_COMMON_ORDER_NUM, DMS_OTHER_RELATED_SERVICES, VEH_SALE_TYPE_CODE, VISTACONTRACT_COMM_TY_SALE_CD, ISOAlpha2LanguageCode, LEAD_STATUS_REASON_LEV1_DESC, LEAD_STATUS_REASON_LEV1_COD, LEAD_STATUS_REASON_LEV2_DESC, LEAD_STATUS_REASON_LEV2_COD, LEAD_STATUS_REASON_LEV3_DESC, LEAD_STATUS_REASON_LEV3_COD, JAGDIGITALEVENTSEXP, JAGDIGITALINCONTROL, JAGDIGITALOWNERVEHCOMM, JAGDIGITALPARTNERSSPONSORS, JAGDIGITALPRODSERV, JAGDIGITALPROMOTIONSOFFERS, JAGDIGITALSURVEYSRESEARCH, JAGEMAILEVENTSEXP, JAGEMAILINCONTROL, JAGEMAILOWNERVEHCOMM, JAGEMAILPARTNERSSPONSORS, JAGEMAILPRODSERV, JAGEMAILPROMOTIONSOFFERS, JAGEMAILSURVEYSRESEARCH, JAGPHONEEVENTSEXP, JAGPHONEINCONTROL, JAGPHONEOWNERVEHCOMM, JAGPHONEPARTNERSSPONSORS, JAGPHONEPRODSERV, JAGPHONEPROMOTIONSOFFERS, JAGPHONESURVEYSRESEARCH, JAGPOSTEVENTSEXP, JAGPOSTINCONTROL, JAGPOSTOWNERVEHCOMM, JAGPOSTPARTNERSSPONSORS, JAGPOSTPRODSERV, JAGPOSTPROMOTIONSOFFERS, JAGPOSTSURVEYSRESEARCH, JAGSMSEVENTSEXP, JAGSMSINCONTROL, JAGSMSOWNERVEHCOMM, JAGSMSPARTNERSSPONSORS, JAGSMSPRODSERV, JAGSMSPROMOTIONSOFFERS, JAGSMSSURVEYSRESEARCH, LRDIGITALEVENTSEXP, LRDIGITALINCONTROL, LRDIGITALOWNERVEHCOMM, LRDIGITALPARTNERSSPONSORS, LRDIGITALPRODSERV, LRDIGITALPROMOTIONSOFFERS, LRDIGITALSURVEYSRESEARCH, LREMAILEVENTSEXP, LREMAILINCONTROL, LREMAILOWNERVEHCOMM, LREMAILPARTNERSSPONSORS, LREMAILPRODSERV, LREMAILPROMOTIONSOFFERS, LREMAILSURVEYSRESEARCH, LRPHONEEVENTSEXP, LRPHONEINCONTROL, LRPHONEOWNERVEHCOMM, LRPHONEPARTNERSSPONSORS, LRPHONEPRODSERV, LRPHONEPROMOTIONSOFFERS, LRPHONESURVEYSRESEARCH, LRPOSTEVENTSEXP, LRPOSTINCONTROL, LRPOSTOWNERVEHCOMM, LRPOSTPARTNERSSPONSORS, LRPOSTPRODSERV, LRPOSTPROMOTIONSOFFERS, LRPOSTSURVEYSRESEARCH, LRSMSEVENTSEXP, LRSMSINCONTROL, LRSMSOWNERVEHCOMM, LRSMSPARTNERSSPONSORS, LRSMSPRODSERV, LRSMSPROMOTIONSOFFERS, LRSMSSURVEYSRESEARCH, ACCT_NAME_PREFIX_CODE, ACCT_NAME_PREFIX, DMS_REPAIR_ORDER_NUMBER_UNIQUE, VEH_FUEL_TYPE, CNT_ABTNR, CNT_ADDRESS, CNT_DPRTMNT, CNT_FIRST_NAME, CNT_FNCTN, CNT_LAST_NAME, CNT_PAFKT, CNT_RELTYP, CNT_TEL_NUMBER, CONTACT_PER_ID, ACCT_NAME_CREATING_DEA, CNT_MOBILE_PHONE, CNT_ACADEMIC_TITLE, CNT_ACADEMIC_TITLE_CODE, CNT_NAME_PREFIX_CODE, CNT_NAME_PREFIX, CNT_JAGDIGITALEVENTSEXP, CNT_JAGDIGITALINCONTROL, CNT_JAGDIGITALOWNERVEHCOMM, CNT_JAGDIGITALPARTNERSSPONSORS, CNT_JAGDIGITALPRODSERV, CNT_JAGDIGITALPROMOTIONSOFFERS, CNT_JAGDIGITALSURVEYSRESEARCH, CNT_JAGEMAILEVENTSEXP, CNT_JAGEMAILINCONTROL, CNT_JAGEMAILOWNERVEHCOMM, CNT_JAGEMAILPARTNERSSPONSORS, CNT_JAGEMAILPRODSERV, CNT_JAGEMAILPROMOTIONSOFFERS, CNT_JAGEMAILSURVEYSRESEARCH, CNT_JAGPHONEEVENTSEXP, CNT_JAGPHONEINCONTROL, CNT_JAGPHONEOWNERVEHCOMM, CNT_JAGPHONEPARTNERSSPONSORS, CNT_JAGPHONEPRODSERV, CNT_JAGPHONEPROMOTIONSOFFERS, CNT_JAGPHONESURVEYSRESEARCH, CNT_JAGPOSTEVENTSEXP, CNT_JAGPOSTINCONTROL, CNT_JAGPOSTOWNERVEHCOMM, CNT_JAGPOSTPARTNERSSPONSORS, CNT_JAGPOSTPRODSERV, CNT_JAGPOSTPROMOTIONSOFFERS, CNT_JAGPOSTSURVEYSRESEARCH, CNT_JAGSMSEVENTSEXP, CNT_JAGSMSINCONTROL, CNT_JAGSMSOWNERVEHCOMM, CNT_JAGSMSPARTNERSSPONSORS, CNT_JAGSMSPRODSERV, CNT_JAGSMSPROMOTIONSOFFERS, CNT_JAGSMSSURVEYSRESEARCH, CNT_LRDIGITALEVENTSEXP, CNT_LRDIGITALINCONTROL, CNT_LRDIGITALOWNERVEHCOMM, CNT_LRDIGITALPARTNERSSPONSORS, CNT_LRDIGITALPRODSERV, CNT_LRDIGITALPROMOTIONSOFFERS, CNT_LRDIGITALSURVEYSRESEARCH, CNT_LREMAILEVENTSEXP, CNT_LREMAILINCONTROL, CNT_LREMAILOWNERVEHCOMM, CNT_LREMAILPARTNERSSPONSORS, CNT_LREMAILPRODSERV, CNT_LREMAILPROMOTIONSOFFERS, CNT_LREMAILSURVEYSRESEARCH, CNT_LRPHONEEVENTSEXP, CNT_LRPHONEINCONTROL, CNT_LRPHONEOWNERVEHCOMM, CNT_LRPHONEPARTNERSSPONSORS, CNT_LRPHONEPRODSERV, CNT_LRPHONEPROMOTIONSOFFERS, CNT_LRPHONESURVEYSRESEARCH, CNT_LRPOSTEVENTSEXP, CNT_LRPOSTINCONTROL, CNT_LRPOSTOWNERVEHCOMM, CNT_LRPOSTPARTNERSSPONSORS, CNT_LRPOSTPRODSERV, CNT_LRPOSTPROMOTIONSOFFERS, CNT_LRPOSTSURVEYSRESEARCH, CNT_LRSMSEVENTSEXP, CNT_LRSMSINCONTROL, CNT_LRSMSOWNERVEHCOMM, CNT_LRSMSPARTNERSSPONSORS, CNT_LRSMSPRODSERV, CNT_LRSMSPROMOTIONSOFFERS, CNT_LRSMSSURVEYSRESEARCH, CNT_TITLE, CNT_TITLE_CODE, CNT_PREF_LANGUAGE, CNT_PREF_LANGUAGE_CODE)		-- v1.3
	SELECT ID, AuditID, VWTID, AuditItemID, PhysicalRowID, Converted_ACCT_DATE_OF_BIRTH, Converted_ACCT_DATE_ADVISED_OF_DEATH, Converted_VEH_REGISTRATION_DATE, Converted_VEH_BUILD_DATE, Converted_DMS_REPAIR_ORDER_CLOSED_DATE, Converted_ROADSIDE_DATE_JOB_COMPLETED, Converted_CASE_CASE_SOLVED_DATE, Converted_VISTACONTRACT_HANDOVER_DATE, DateTransferredToVWT, SampleTriggeredSelectionReqID, AFRLCode, ACCT_ACADEMIC_TITLE, ACCT_ACADEMIC_TITLE_CODE, ACCT_ACCT_ID, ACCT_ACCT_TYPE, ACCT_ACCT_TYPE_CODE, ACCT_ADDITIONAL_LAST_NAME, ACCT_BP_ROLE, ACCT_BUILDING, ACCT_CITY_CODE, ACCT_CITY_CODE2, ACCT_CITY_TOWN, ACCT_CITYH_CODE, ACCT_CONSENT_JAGUAR_EMAIL, ACCT_CONSENT_JAGUAR_PHONE, ACCT_CONSENT_JAGUAR_POST, ACCT_CONSENT_LAND_ROVER_EMAIL, ACCT_CONSENT_LAND_ROVER_POST, ACCT_CONSENT_LR_PHONE, ACCT_CORRESPONDENCE_LANG_CODE, ACCT_CORRESPONDENCE_LANGUAGE, ACCT_COUNTRY, ACCT_COUNTRY_CODE, ACCT_COUNTY, ACCT_COUNTY_CODE, ACCT_DATE_ADVISED_OF_DEATH, ACCT_DATE_DECL_TO_GIVE_EMAIL, ACCT_DATE_OF_BIRTH, ACCT_DEAL_FULNAME_OF_CREAT_DEA, ACCT_DISTRICT, ACCT_EMAIL_VALIDATION_STATUS, ACCT_EMPLOYER_NAME, ACCT_EXTERN_FINANC_COMP_ACCTID, ACCT_FIRST_NAME, ACCT_FLOOR, ACCT_FULL_NAME, ACCT_GENDER_FEMALE, ACCT_GENDER_MALE, ACCT_GENDER_UNKNOWN, ACCT_GENERATION, ACCT_HOME_CITY, ACCT_HOME_EMAIL_ADDR_PRIMARY, ACCT_HOME_PHONE_NUMBER, ACCT_HOUSE_NO, ACCT_HOUSE_NUM2, ACCT_HOUSE_NUM3, ACCT_INDUSTRY_SECTOR, ACCT_INDUSTRY_SECTOR_CODE, ACCT_INITIALS, ACCT_JAGUAR_IN_MARKET_DATE, ACCT_JAGUAR_LOYALTY_STATUS, ACCT_KNOWN_AS, ACCT_LAND_ROVER_LOYALTY_STATUS, ACCT_LAND_ROVER_MARKET_DATE, ACCT_LAST_NAME, ACCT_LOCATION, ACCT_MIDDLE_NAME, ACCT_MOBILE_NUMBER, ACCT_NAME_1, ACCT_NAME_2, ACCT_NAME_3, ACCT_NAME_4, ACCT_NAME_CO, ACCT_NON_ACADEMIC_TITLE, ACCT_NON_ACADEMIC_TITLE_CODE, ACCT_ORG_TYPE, ACCT_ORG_TYPE_CODE, ACCT_PCODE1_EXT, ACCT_PCODE2_EXT, ACCT_PCODE3_EXT, ACCT_PO_BOX, ACCT_PO_BOX_CTY, ACCT_PO_BOX_LOBBY, ACCT_PO_BOX_LOC, ACCT_PO_BOX_NUM, ACCT_PO_BOX_REG, ACCT_POST_CODE2, ACCT_POST_CODE3, ACCT_POSTALAREA, ACCT_POSTCODE_ZIP, ACCT_PREF_CONTACT_METHOD, ACCT_PREF_CONTACT_METHOD_CODE, ACCT_PREF_CONTACT_TIME, ACCT_PREF_LANGUAGE, ACCT_PREF_LANGUAGE_CODE, ACCT_REGION_STATE, ACCT_REGION_STATE_CODE, ACCT_ROOM_NUMBER, ACCT_STREET, ACCT_STREETABBR, ACCT_STREETCODE, ACCT_SUPPLEMENT_1, ACCT_SUPPLEMENT_2, ACCT_SUPPLEMENT_3, ACCT_TITLE, ACCT_TITLE_CODE, ACCT_TOWNSHIP, ACCT_TOWNSHIP_CODE, ACCT_VIP_FLAG, ACCT_WORK_PHONE_EXTENSION, ACCT_WORK_PHONE_PRIMARY, ACTIVITY_ID, CAMPAIGN_CAMPAIGN_CHANNEL, CAMPAIGN_CAMPAIGN_DESC, CAMPAIGN_CAMPAIGN_ID, CAMPAIGN_CATEGORY_1, CAMPAIGN_CATEGORY_2, CAMPAIGN_CATEGORY_3, CAMPAIGN_DEALERFULNAME_DEALER1, CAMPAIGN_DEALERFULNAME_DEALER2, CAMPAIGN_DEALERFULNAME_DEALER3, CAMPAIGN_DEALERFULNAME_DEALER4, CAMPAIGN_DEALERFULNAME_DEALER5, CAMPAIGN_SECDEALERCODE_DEALER1, CAMPAIGN_SECDEALERCODE_DEALER2, CAMPAIGN_SECDEALERCODE_DEALER3, CAMPAIGN_SECDEALERCODE_DEALER4, CAMPAIGN_SECDEALERCODE_DEALER5, CAMPAIGN_TARGET_GROUP_DESC, CAMPAIGN_TARGET_GROUP_ID, CASE_BRAND, CASE_BRAND_CODE, CASE_CASE_CREATION_DATE, CASE_CASE_DESC, CASE_CASE_EMPL_RESPONSIBLE_NAM, CASE_CASE_ID, CASE_CASE_SOLVED_DATE, CASE_EMPL_RESPONSIBLE_ID, CASE_GOODWILL_INDICATOR, CASE_REASON_FOR_STATUS, CASE_SECON_DEALER_CODE_OF_DEAL, CASE_VEH_REG_PLATE, CASE_VEH_VIN_NUMBER, CASE_VEHMODEL_DERIVED_FROM_VIN, CR_OBJECT_ID, CRH_DEALER_ROA_CITY_TOWN, CRH_DEALER_ROA_COUNTRY, CRH_DEALER_ROA_HOUSE_NO, CRH_DEALER_ROA_ID, CRH_DEALER_ROA_NAME_1, CRH_DEALER_ROA_NAME_2, CRH_DEALER_ROA_PO_BOX, CRH_DEALER_ROA_POSTCODE_ZIP, CRH_DEALER_ROA_PREFIX_1, CRH_DEALER_ROA_PREFIX_2, CRH_DEALER_ROA_REGION_STATE, CRH_DEALER_ROA_STREET, CRH_DEALER_ROA_SUPPLEMENT_1, CRH_DEALER_ROA_SUPPLEMENT_2, CRH_DEALER_ROA_SUPPLEMENT_3, CRH_END_DATE, CRH_START_DATE, DMS_ACTIVITY_DESC, DMS_DAYS_OPEN, DMS_EVENT_TYPE, DMS_LICENSE_PLATE_REGISTRATION, DMS_POTENTIAL_CHANGE_OF_OWNERS, DMS_REPAIR_ORDER_CLOSED_DATE, DMS_REPAIR_ORDER_NUMBER, DMS_REPAIR_ORDER_OPEN_DATE, DMS_SECON_DEALER_CODE, DMS_SERVICE_ADVISOR, DMS_SERVICE_ADVISOR_ID, DMS_TECHNICIAN_ID, DMS_TECHNICIAN, DMS_TOTAL_CUSTOMER_PRICE, DMS_USER_STATUS, DMS_USER_STATUS_CODE, DMS_VIN, LEAD_BRAND_CODE, LEAD_EMP_RESPONSIBLE_DEAL_NAME, LEAD_ENQUIRY_TYPE_CODE, LEAD_FUEL_TYPE_CODE, LEAD_IN_MARKET_DATE, LEAD_LEAD_CATEGORY_CODE, LEAD_LEAD_STATUS_CODE, LEAD_LEAD_STATUS_REASON_CODE, LEAD_MODEL_OF_INTEREST_CODE, LEAD_MODEL_YEAR, LEAD_NEW_USED_INDICATOR, LEAD_ORIGIN_CODE, LEAD_PRE_LAUNCH_MODEL, LEAD_PREF_CONTACT_METHOD, LEAD_SECON_DEALER_CODE, LEAD_VEH_SALE_TYPE_CODE, OBJECT_ID, ROADSIDE_ACTIVE_STATUS_CODE, ROADSIDE_ACTIVITY_DESC, ROADSIDE_COUNTRY_ISO_CODE, ROADSIDE_CUSTOMER_SUMMARY_INC, ROADSIDE_DATA_SOURCE, ROADSIDE_DATE_CALL_ANSWERED, ROADSIDE_DATE_CALL_RECEIVED, ROADSIDE_DATE_JOB_COMPLETED, ROADSIDE_DATE_RESOURCE_ALL, ROADSIDE_DATE_RESOURCE_ARRIVED, ROADSIDE_DATE_SECON_RES_ALL, ROADSIDE_DATE_SECON_RES_ARR, ROADSIDE_DRIVER_EMAIL, ROADSIDE_DRIVER_FIRST_NAME, ROADSIDE_DRIVER_LAST_NAME, ROADSIDE_DRIVER_MOBILE, ROADSIDE_DRIVER_TITLE, ROADSIDE_INCIDENT_CATEGORY, ROADSIDE_INCIDENT_COUNTRY, ROADSIDE_INCIDENT_DATE, ROADSIDE_INCIDENT_ID, ROADSIDE_INCIDENT_SUMMARY, ROADSIDE_INCIDENT_TIME, ROADSIDE_LICENSE_PLATE_REG_NO, ROADSIDE_PROVIDER, ROADSIDE_REPAIRING_SEC_DEAL_CD, ROADSIDE_RESOLUTION_TIME, ROADSIDE_TIME_CALL_ANSWERED, ROADSIDE_TIME_CALL_RECEIVED, ROADSIDE_TIME_JOB_COMPLETED, ROADSIDE_TIME_RESOURCE_ALL, ROADSIDE_TIME_RESOURCE_ARRIVED, ROADSIDE_TIME_SECON_RES_ALL, ROADSIDE_TIME_SECON_RES_ARR, ROADSIDE_VIN, ROADSIDE_WAIT_TIME, VEH_BRAND, VEH_BUILD_DATE, VEH_CHASSIS_NUMBER, VEH_COMMON_ORDER_NUMBER, VEH_COUNTRY_EQUIPMENT_CODE, VEH_CREATING_DEALER, VEH_CURR_PLANNED_DELIVERY_DATE, VEH_CURRENT_PLANNED_BUILD_DATE, VEH_DEA_NAME_LAST_SELLING_DEAL, VEH_DEALER_NAME_OF_SELLING_DEA, VEH_DELIVERED_DATE, VEH_DERIVATIVE, VEH_DRIVER_FULL_NAME, VEH_ENGINE_SIZE, VEH_EXTERIOR_COLOUR_CODE, VEH_EXTERIOR_COLOUR_DESC, VEH_EXTERIOR_COLOUR_SUPPL_CODE, VEH_EXTERIOR_COLOUR_SUPPL_DESC, VEH_FEATURE_CODE, VEH_FINANCE_PROD, VEH_FIRST_RETAIL_SALE, VEH_FUEL_TYPE_CODE, VEH_MODEL, VEH_MODEL_DESC, VEH_MODEL_YEAR, VEH_NUM_OF_OWNERS_RELATIONSHIP, VEH_ORIGIN, VEH_OWNERSHIP_STATUS, VEH_OWNERSHIP_STATUS_CODE, VEH_PAYMENT_TYPE, VEH_PREDICTED_REPLACEMENT_DATE, VEH_REACQUIRED_INDICATOR, VEH_REGISTRAT_LICENC_PLATE_NUM, VEH_REGISTRATION_DATE, VEH_SALE_TYPE_DESC, VEH_VIN, VEH_VISTA_CONTRACT_NUMBER, VISTACONTRACT_COMM_TY_SALE_DS, VISTACONTRACT_HANDOVER_DATE, VISTACONTRACT_PREV_VEH_BRAND, VISTACONTRACT_PREV_VEH_MODEL, VISTACONTRACT_SALES_MAN_CD_DES, VISTACONTRACT_SALES_MAN_FULNAM, VISTACONTRACT_SALESMAN_CODE, VISTACONTRACT_SECON_DEALER_CD, VISTACONTRACT_TRADE_IN_MANUFAC, VISTACONTRACT_TRADE_IN_MODEL, VISTACONTRACT_ACTIVITY_CATEGRY, VISTACONTRACT_RETAIL_PRICE, VEH_APPR_WARNTY_TYPE, VEH_APPR_WARNTY_TYPE_DESC, VISTACONTRACTNAPPRO_RETAIL_WAR, VISTACONTRACTNAPPRO_RETAIL_DES, VISTACONTRACT_EXT_WARR, VISTACONTRACT_EXT_WARR_DESC, ACCT_CONSENT_JAGUAR_FAX, ACCT_CONSENT_LAND_ROVER_FAX, ACCT_CONSENT_JAGUAR_CHAT, ACCT_CONSENT_LAND_ROVER_CHAT, ACCT_CONSENT_JAGUAR_SMS, ACCT_CONSENT_LAND_ROVER_SMS, ACCT_CONSENT_JAGUAR_SMEDIA, ACCT_CONSENT_LAND_ROVER_SMEDIA, ACCT_CONSENT_OVER_CONT_SUP_JAG, ACCT_CONSENT_OVER_CONT_SUP_LR, ACCT_CONSENT_JAGUAR_PTSMR, ACCT_CONSENT_LAND_ROVER_PTSMR, ACCT_CONSENT_JAGUAR_PTVSM, ACCT_CONSENT_LAND_ROVER_PTVSM, ACCT_CONSENT_JAGUAR_PTAM, ACCT_CONSENT_LAND_ROVER_PTAM, ACCT_CONSENT_JAGUAR_PTNAU, ACCT_CONSENT_LAND_ROVER_PTNAU, ACCT_CONSENT_JAGUAR_PEVENT, ACCT_CONSENT_LAND_ROVER_PEVENT, ACCT_CONSENT_JAGUAR_PND3P, ACCT_CONSENT_LAND_ROVER_PND3P, ACCT_CONSENT_JAGUAR_PTSDWD, ACCT_CONSENT_LAND_ROVER_PTSDWD, ACCT_CONSENT_JAGUAR_PTPA, ACCT_CONSENT_LAND_ROVER_PTPA, RESPONSE_ID, VISTACONTRACT_COMMON_ORDER_NUM, DMS_OTHER_RELATED_SERVICES, VEH_SALE_TYPE_CODE, VISTACONTRACT_COMM_TY_SALE_CD, ISOAlpha2LanguageCode, LEAD_STATUS_REASON_LEV1_DESC, LEAD_STATUS_REASON_LEV1_COD, LEAD_STATUS_REASON_LEV2_DESC, LEAD_STATUS_REASON_LEV2_COD, LEAD_STATUS_REASON_LEV3_DESC, LEAD_STATUS_REASON_LEV3_COD, JAGDIGITALEVENTSEXP, JAGDIGITALINCONTROL, JAGDIGITALOWNERVEHCOMM, JAGDIGITALPARTNERSSPONSORS, JAGDIGITALPRODSERV, JAGDIGITALPROMOTIONSOFFERS, JAGDIGITALSURVEYSRESEARCH, JAGEMAILEVENTSEXP, JAGEMAILINCONTROL, JAGEMAILOWNERVEHCOMM, JAGEMAILPARTNERSSPONSORS, JAGEMAILPRODSERV, JAGEMAILPROMOTIONSOFFERS, JAGEMAILSURVEYSRESEARCH, JAGPHONEEVENTSEXP, JAGPHONEINCONTROL, JAGPHONEOWNERVEHCOMM, JAGPHONEPARTNERSSPONSORS, JAGPHONEPRODSERV, JAGPHONEPROMOTIONSOFFERS, JAGPHONESURVEYSRESEARCH, JAGPOSTEVENTSEXP, JAGPOSTINCONTROL, JAGPOSTOWNERVEHCOMM, JAGPOSTPARTNERSSPONSORS, JAGPOSTPRODSERV, JAGPOSTPROMOTIONSOFFERS, JAGPOSTSURVEYSRESEARCH, JAGSMSEVENTSEXP, JAGSMSINCONTROL, JAGSMSOWNERVEHCOMM, JAGSMSPARTNERSSPONSORS, JAGSMSPRODSERV, JAGSMSPROMOTIONSOFFERS, JAGSMSSURVEYSRESEARCH, LRDIGITALEVENTSEXP, LRDIGITALINCONTROL, LRDIGITALOWNERVEHCOMM, LRDIGITALPARTNERSSPONSORS, LRDIGITALPRODSERV, LRDIGITALPROMOTIONSOFFERS, LRDIGITALSURVEYSRESEARCH, LREMAILEVENTSEXP, LREMAILINCONTROL, LREMAILOWNERVEHCOMM, LREMAILPARTNERSSPONSORS, LREMAILPRODSERV, LREMAILPROMOTIONSOFFERS, LREMAILSURVEYSRESEARCH, LRPHONEEVENTSEXP, LRPHONEINCONTROL, LRPHONEOWNERVEHCOMM, LRPHONEPARTNERSSPONSORS, LRPHONEPRODSERV, LRPHONEPROMOTIONSOFFERS, LRPHONESURVEYSRESEARCH, LRPOSTEVENTSEXP, LRPOSTINCONTROL, LRPOSTOWNERVEHCOMM, LRPOSTPARTNERSSPONSORS, LRPOSTPRODSERV, LRPOSTPROMOTIONSOFFERS, LRPOSTSURVEYSRESEARCH, LRSMSEVENTSEXP, LRSMSINCONTROL, LRSMSOWNERVEHCOMM, LRSMSPARTNERSSPONSORS, LRSMSPRODSERV, LRSMSPROMOTIONSOFFERS, LRSMSSURVEYSRESEARCH, ACCT_NAME_PREFIX_CODE, ACCT_NAME_PREFIX, DMS_REPAIR_ORDER_NUMBER_UNIQUE, VEH_FUEL_TYPE, CNT_ABTNR, CNT_ADDRESS, CNT_DPRTMNT, CNT_FIRST_NAME, CNT_FNCTN, CNT_LAST_NAME, CNT_PAFKT, CNT_RELTYP, CNT_TEL_NUMBER, CONTACT_PER_ID, ACCT_NAME_CREATING_DEA, CNT_MOBILE_PHONE, CNT_ACADEMIC_TITLE, CNT_ACADEMIC_TITLE_CODE, CNT_NAME_PREFIX_CODE, CNT_NAME_PREFIX, CNT_JAGDIGITALEVENTSEXP, CNT_JAGDIGITALINCONTROL, CNT_JAGDIGITALOWNERVEHCOMM, CNT_JAGDIGITALPARTNERSSPONSORS, CNT_JAGDIGITALPRODSERV, CNT_JAGDIGITALPROMOTIONSOFFERS, CNT_JAGDIGITALSURVEYSRESEARCH, CNT_JAGEMAILEVENTSEXP, CNT_JAGEMAILINCONTROL, CNT_JAGEMAILOWNERVEHCOMM, CNT_JAGEMAILPARTNERSSPONSORS, CNT_JAGEMAILPRODSERV, CNT_JAGEMAILPROMOTIONSOFFERS, CNT_JAGEMAILSURVEYSRESEARCH, CNT_JAGPHONEEVENTSEXP, CNT_JAGPHONEINCONTROL, CNT_JAGPHONEOWNERVEHCOMM, CNT_JAGPHONEPARTNERSSPONSORS, CNT_JAGPHONEPRODSERV, CNT_JAGPHONEPROMOTIONSOFFERS, CNT_JAGPHONESURVEYSRESEARCH, CNT_JAGPOSTEVENTSEXP, CNT_JAGPOSTINCONTROL, CNT_JAGPOSTOWNERVEHCOMM, CNT_JAGPOSTPARTNERSSPONSORS, CNT_JAGPOSTPRODSERV, CNT_JAGPOSTPROMOTIONSOFFERS, CNT_JAGPOSTSURVEYSRESEARCH, CNT_JAGSMSEVENTSEXP, CNT_JAGSMSINCONTROL, CNT_JAGSMSOWNERVEHCOMM, CNT_JAGSMSPARTNERSSPONSORS, CNT_JAGSMSPRODSERV, CNT_JAGSMSPROMOTIONSOFFERS, CNT_JAGSMSSURVEYSRESEARCH, CNT_LRDIGITALEVENTSEXP, CNT_LRDIGITALINCONTROL, CNT_LRDIGITALOWNERVEHCOMM, CNT_LRDIGITALPARTNERSSPONSORS, CNT_LRDIGITALPRODSERV, CNT_LRDIGITALPROMOTIONSOFFERS, CNT_LRDIGITALSURVEYSRESEARCH, CNT_LREMAILEVENTSEXP, CNT_LREMAILINCONTROL, CNT_LREMAILOWNERVEHCOMM, CNT_LREMAILPARTNERSSPONSORS, CNT_LREMAILPRODSERV, CNT_LREMAILPROMOTIONSOFFERS, CNT_LREMAILSURVEYSRESEARCH, CNT_LRPHONEEVENTSEXP, CNT_LRPHONEINCONTROL, CNT_LRPHONEOWNERVEHCOMM, CNT_LRPHONEPARTNERSSPONSORS, CNT_LRPHONEPRODSERV, CNT_LRPHONEPROMOTIONSOFFERS, CNT_LRPHONESURVEYSRESEARCH, CNT_LRPOSTEVENTSEXP, CNT_LRPOSTINCONTROL, CNT_LRPOSTOWNERVEHCOMM, CNT_LRPOSTPARTNERSSPONSORS, CNT_LRPOSTPRODSERV, CNT_LRPOSTPROMOTIONSOFFERS, CNT_LRPOSTSURVEYSRESEARCH, CNT_LRSMSEVENTSEXP, CNT_LRSMSINCONTROL, CNT_LRSMSOWNERVEHCOMM, CNT_LRSMSPARTNERSSPONSORS, CNT_LRSMSPRODSERV, CNT_LRSMSPROMOTIONSOFFERS, CNT_LRSMSSURVEYSRESEARCH, CNT_TITLE, CNT_TITLE_CODE, CNT_PREF_LANGUAGE, CNT_PREF_LANGUAGE_CODE		-- v1.3
	FROM CRM.Vista_Contract_Sales crm 
	WHERE crm.AuditID = @AuditID


	-- Delete the records from the CRM holding table
	DELETE
	FROM CRM.Vista_Contract_Sales
	WHERE AuditID = @AuditID





	-----------------------------------------------------------------------------------------------------------------------------
	-----------------------------------------------------------------------------------------------------------------------------
	-- Write out the RollbackHeader record for reference
	-----------------------------------------------------------------------------------------------------------------------------
	-----------------------------------------------------------------------------------------------------------------------------
	
	
	;WITH CTE_Counts
	AS (
		SELECT  AuditID,
				COUNT(DISTINCT AuditItemID) AS Rows,
				COUNT(DISTINCT EventID) AS Events,
				COUNT(DISTINCT CaseID)	AS Cases			 
		FROM #FileRowsInfo FRI 
		GROUP BY AuditID
	) 
	INSERT INTO RollbackSample.RollbackHeader (AuditID, RollbackDate, TotalRows, TotalEvents, TotalCases, TotalContactPrefAdjustments, TotalContactPrefBySurveyAdjustments, NonSolicitationsAuditID, ContactPrefAdjustmentsAuditID, UserName)
	SELECT	AuditID, 
			GETDATE() AS RollbackDate,
			Rows, 
			Events, 
			Cases,
			(SELECT MAX(ID) FROM #ContactPreferenceAdjustments) AS TotalContactPrefAdjustments,
			(SELECT MAX(ID) FROM #ContactPreferenceAdjustmentsBySurvey) AS TotalContactPrefBySurveyAdjustments,
			@NonSolEventsFileAuditID,
			@ContactPrefAdjFileAuditID,
			ORIGINAL_LOGIN() As Username
	FROM CTE_Counts




COMMIT



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