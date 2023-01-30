CREATE TABLE [dbo].[VehicleWarrantyClaimCount]
(
	VehicleID dbo.VehicleID NULL,
	CurrentOwner dbo.PartyID NULL,
	CustomerName dbo.FullName NULL,
	VIN dbo.VIN NULL,
	ReportingModel dbo.ModelDescription NULL,
	SalesDate DATETIME2,
	LastWarrantyVisit DATETIME2,
	DealerPartyID dbo.PartyID NULL,
	DealerVisitsLastSixMonths SMALLINT,
	AllVisitsLastSixMonths SMALLINT,
	TotalVisits SMALLINT
)
