
CREATE PROCEDURE [dbo].[uspPopulateCustomerEventList] 
	@DaysToProcess INTEGER

/*
	Purpose:	(WIDGET027 Requirement) To populate the table CustomerEventList table for web reporting 
	
	Version		Date			Developer			Comment
	1.0			$(ReleaseDate)	Pardip Mudhar		Widget027 from the Requirement Document
	1.1			21/01/2020		Chris Ledger		BUG 15372: Fix Hard coded references to databases.
*/

AS

BEGIN 
DECLARE 
		@MinEventID	bigint,
		@RangeID	bigint,
		@MaxEventID bigint,
		@StepValue	bigint

SET NOCOUNT ON
SET XACT_ABORT ON

IF ( ( SELECT COUNT( name ) FROM sysindexes WHERE name = 'IX_NC_CustomerEventList' ) > 0 )
BEGIN
	EXEC('USE WebsiteReporting DROP INDEX dbo.CustomerEventList.IX_NC_CustomerEventList')
END

IF ( ( SELECT COUNT( name ) FROM sysindexes WHERE name = 'IX_ED_CustomerEventList' ) > 0 )
BEGIN
	EXEC('USE WebsiteReporting DROP INDEX dbo.CustomerEventList.IX_ED_CustomerEventList')
END

IF ( ( SELECT COUNT( name ) FROM sysindexes WHERE name = 'IX_ETD_CustomerEventList' ) > 0 )
BEGIN
	EXEC('USE WebsiteReporting DROP INDEX dbo.CustomerEventList.IX_ETD_CustomerEventList')
END

CREATE TABLE #EventsToProcess
(
	EventID			BIGINT,
	EventDate		DATETIME2
)

TRUNCATE TABLE dbo.CustomerEventList

INSERT INTO #EventsToProcess
(
	EventID,
	EventDate
)	
SELECT 
	epr.EventID,
	e.EventDate
FROM
		[$(SampleDB)].Event.EventPartyRoles epr
JOIN	[$(SampleDB)].Event.Events e on e.EventID = epr.EventID 
AND		( e.EventDate >= DATEADD( DAY, -@DaysToProcess, GETDATE() ) 
AND		  e.EventDate <= GETDATE() )
ORDER BY
	epr.EventID

SELECT 
	@MinEventID = MIN(EventID),
	@MaxEventID = MAX(EventID)
FROM 
	#EventsToProcess

SELECT @StepValue = 
			CASE
				WHEN ( @MaxEventID - @MinEventID ) <= 10000 THEN @MaxEventID * 15 / 100
				WHEN ( @MaxEventID - @MinEventID ) <= 100000 THEN @MaxEventID * 10 / 100
				WHEN ( @MaxEventID - @MinEventID ) <= 250000 THEN @MaxEventID * 5 / 100
				WHEN ( @MaxEventID - @MinEventID ) <= 500000 THEN @MaxEventID * 2.5 / 100
				WHEN ( @MaxEventID - @MinEventID ) <= 1000000 THEN @MaxEventID * 1.5 / 100
				else @MaxEventID * 1 / 100
			END

if ( @StepValue < 1 )
BEGIN
	SELECT @StepValue = 1
END

BEGIN TRY

	WHILE ( @MinEventID <= @MaxEventID)
	BEGIN
		SELECT	@RangeID = @MinEventID
		SELECT	@MinEventID = @MinEventID + @StepValue

		BEGIN TRANSACTION
	
		INSERT INTO CustomerEventList 
		(
			TransferPartyID, 
			OutletPartyID,
			EventID,  
			OutletFunctionID,
			Market, 
			SuperNationalRegion, 
			SubNationalRegion, 
			TransferDealer,
			OutletFunction,
			Outlet
		)
		SELECT
			dw.TransferPartyID,
			dw.OutletPartyID,
			epr.EventID,
			dw.OutletFunctionID,
			dw.Market,
			dw.SuperNationalRegion, 
			dw.SubNationalRegion, 
			dw.TransferDealer + ' (' + dw.TransferDealerCode + ')',
			dw.OutletFunction,
			dw.Outlet
		FROM 
			[$(SampleDB)].Event.EventPartyRoles epr
		JOIN [$(SampleDB)].dbo.DW_JLRCSPDealers dw ON dw.OutletPartyID = epr.PartyID AND dw.OutletFunctionID = epr.RoleTypeID
		JOIN #EventsToProcess etp on etp.EventID = epr.EventID
		WHERE
			( epr.EventID >= @RangeID 
		AND	  epr.EventID < @MinEventID)

		COMMIT
		BEGIN TRANSACTION

		UPDATE	CustomerEventList
		SET		CustomerEventList.EventDate = e.EventDate,
				CustomerEventList.EventTypeID = e.EventTypeID
		FROM	[Sample].Event.Events e
		WHERE	e.EventID = CustomerEventList.EventID
		AND		( CustomerEventList.EventID >= @RangeID 
		AND		  CustomerEventList.EventID <= @MinEventID)

		COMMIT 
		BEGIN TRANSACTION
	
		UPDATE	CustomerEventList
		SET		CustomerEventList.EventTypeDesc = et.EventType
		FROM	[Sample].Event.EventTypes et
		WHERE	CustomerEventList.EventTypeID = et.EventTypeID
		AND		( CustomerEventList.EventID >= @RangeID 
		AND		  CustomerEventList.EventID <= @MinEventID)

		COMMIT
		BEGIN TRANSACTION
	
		UPDATE	CustomerEventList
		SET		CustomerEventList.VehicleID = vpre.VehicleID,
				CustomerEventList.CustomerPartyID = vpre.PartyID,
				CustomerEventList.VehicleRoleTypeID = vpre.VehicleRoleTypeID
		FROM	[Sample].vehicle.VehiclePartyRoleEvents vpre
		WHERE	vpre.EventID = CustomerEventList.EventID
		AND		( CustomerEventList.EventID >= @RangeID 
		AND		  CustomerEventList.EventID <= @MinEventID)

		COMMIT
		BEGIN TRANSACTION
	
		UPDATE	CustomerEventList
		SET		CustomerEventList.VIN = v.vin,
				CustomerEventList.ModelID = v.ModelID
		FROM	[Sample].Vehicle.Vehicles v
		WHERE	v.VehicleID = CustomerEventList.VehicleID
		AND		( CustomerEventList.EventID >= @RangeID 
		AND		  CustomerEventList.EventID <= @MinEventID)

		COMMIT
		BEGIN TRANSACTION
	
		UPDATE	CustomerEventList
		SET		CustomerEventList.RegistrationID = vre.RegistrationId
		FROM	[Sample].Vehicle.Vehicles v, 
				[Sample].vehicle.VehicleRegistrationEvents vre
		WHERE	v.VehicleID = CustomerEventList.VehicleID
		AND		v.VehicleID = vre.VehicleID
		AND		v.VIN = CustomerEventList.VIN
		AND		( CustomerEventList.EventID >= @RangeID 
		AND		  CustomerEventList.EventID <= @MinEventID)
	
		COMMIT
		BEGIN TRANSACTION
	
		UPDATE  CustomerEventList
		SET		CustomerEventList.RegNo = r.RegistrationNumber
		FROM	[Sample].vehicle.Registrations r
		WHERE	r.RegistrationID = CustomerEventList.RegistrationID
		AND		CustomerEventList.RegistrationID is not null
		AND		( CustomerEventList.EventID >= @RangeID 
		AND		  CustomerEventList.EventID <= @MinEventID)

		COMMIT
		BEGIN TRANSACTION
	
		UPDATE	CustomerEventList
		SET		CustomerEventList.Model = m.ModelDescription
		FROM	[Sample].Vehicle.Models m
		WHERE	CustomerEventList.ModelID = m.ModelID
		AND		( CustomerEventList.EventID >= @RangeID 
		AND		  CustomerEventList.EventID <= @MinEventID)
	
		COMMIT
		BEGIN TRANSACTION
		
		UPDATE	CustomerEventList
		SET		CustomerEventList.CASEID = aebi.CASEID,
				CustomerEventList.Selected = 'Y'
		FROM	[Sample].Event.AutomotiveEventBasedInterviews aebi
		JOIN	[Sample].Event.Cases C on aebi.CaseID = C.CaseID
		WHERE	aebi.VehicleID = CustomerEventList.VehicleID
		AND		( CustomerEventList.EventID >= @RangeID 
		AND		  CustomerEventList.EventID <= @MinEventID)
		AND		C.CaseStatusTypeID <> 2
		AND		CustomerEventList.EventID = AEBI.EventID
		COMMIT
		BEGIN TRANSACTION

		UPDATE	CustomerEventList
		SET		CustomerEventList.ReceivedDate = c.ClosureDate
		FROM	[Sample].Event.CASEs c
		WHERE	c.CASEID = CustomerEventList.CASEID
		AND		( CustomerEventList.EventID >= @RangeID 
		AND		  CustomerEventList.EventID <= @MinEventID)

		COMMIT
		BEGIN TRANSACTION

		UPDATE	CustomerEventList
		SET		CustomerEventList.Customer = o.OrganisationName
		FROM	[Sample].Party.Organisations o
		WHERE	o.PartyID = CustomerEventList.CustomerPartyID
		AND		( CustomerEventList.EventID >= @RangeID 
		AND		  CustomerEventList.EventID <= @MinEventID)

		COMMIT
		BEGIN TRANSACTION

		UPDATE	CustomerEventList
		SET		CustomerEventList.Customer = 
				CASE 
					WHEN len(p.FirstName) <= 0 THEN p.LastName + ', ' + t.Title
					else p.LastName + ', ' + t.Title + ' ' + p.FirstName
				END
		FROM	[Sample].Party.People p, [Sample].Party.Titles t
		WHERE	p.PartyID = CustomerEventList.CustomerPartyID
		AND		p.TitleID = t.TitleID
		AND		( CustomerEventList.EventID >= @RangeID 
		AND		  CustomerEventList.EventID <= @MinEventID)

		COMMIT
		BEGIN TRANSACTION

		UPDATE	CustomerEventList
		SET		CustomerEventList.VehicleRoleTypeDesc = vrt.VehicleRoleType
		FROM	[Sample].vehicle.VehicleRoleTypes vrt
		WHERE	vrt.vehicleRoleTypeID = CustomerEventList.VehicleRoleTypeID
		AND		( CustomerEventList.EventID >= @RangeID 
		AND		  CustomerEventList.EventID <= @MinEventID)

		COMMIT
		BEGIN TRANSACTION
	
		UPDATE	WebsiteReporting.dbo.CustomerEventList
		SET		ReceivedDate = af.actiondate
		FROM	[Sample_Audit].Audit.Events ae, [Sample_Audit].dbo.AuditItems ai, [Sample_Audit].dbo.Files af
		WHERE	WebsiteReporting.dbo.CustomerEventList.EventID = ae.EventID 
		AND		ae.EventID = WebsiteReporting.dbo.CustomerEventList.EventID 
		AND		ae.AuditItemID = ai.AuditItemID
		AND		ai.AuditID = af.AuditID 
		AND		af.ActionDate = 
		(		
				SELECT	MIN(af2.ActionDate) 
				FROM	[Sample_Audit].dbo.Files af2
				WHERE af.AuditID = af2.AuditID 
		)
		AND		( CustomerEventList.EventID >= @RangeID 
		AND		  CustomerEventList.EventID <= @MinEventID)
	
		COMMIT
	END -- While
	

	CREATE 
	CLUSTERED 
	INDEX 
		IX_NC_CustomerEventList
	ON 
		[dbo].[CustomerEventList] ( EventID, TransferPartyID, OutletPartyID )
		
	CREATE
	INDEX
		IX_ED_CustomerEventList
	ON
		[dbo].[CustomerEventList] ( EventDate )
		
	CREATE
	INDEX
		IX_ETD_CustomerEventList
	ON
		[dbo].[CustomerEventList] ( EventTypeDesc )
END TRY
BEGIN CATCH
	DECLARE @DB_ID INT
	DECLARE @DB_NAME nvarchar(128)
	DECLARE @ERRMSG nvarchar(128)
	
	SELECT @DB_ID = DB_ID()
	SELECT @DB_NAME = DB_NAME()
	SELECT @ERRMSG = 'Error when populating Customer Event Status' + ', ' + @DB_NAME
	
	RAISERROR( @ERRMSG, 16, 1)
END CATCH

END -- Stored Procedure
